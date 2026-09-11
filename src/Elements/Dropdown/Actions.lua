return function(ctx)
    local I = ctx.Internal
    local View = I.DropdownView

    local Actions = {}

    function Actions.selectOption(S, opt, rippleTarget)
        local self = S.self
        if not opt then return end
        if self._disabled then return end
        I.PlaySound("Click", 0.7)
        if rippleTarget then I.ApplyRipple(rippleTarget) end
        if S.multi then
            if S.selSet[opt.Key] then
                S.selSet[opt.Key] = nil
            else
                S.selSet[opt.Key] = true
            end
            S.commitSel()
            I.RunCallback(self.Callback, self.Title, self:Get())
        else
            S.selSet = { [opt.Key] = true }
            S.commitSel()
            Actions.setExpanded(S, false)
            I.RunCallback(self.Callback, self.Title, self:Get())
        end
    end

    function Actions.setExpanded(S, state)
        if S.expanded == state then return end
        S.expanded = state
        I.Tween(S.chevHolder, "PopSoft", { Rotation = state and 180 or 0 })

        if state then
            View.buildUI(S)
            local tab = S.tab
            if tab._openDropdown and tab._openDropdown ~= S.closeFn then
                tab._openDropdown()
            end
            tab._openDropdown = S.closeFn
            if not S.keyHook then
                S.keyHook = I.AddInputHook(function() return not S.self._destroyed end, S.keyHandler)
            end
            I.HotElement = nil

            S.hl = nil
            if not S.multi then
                for i, o in ipairs(S.display) do
                    if S.selSet[o.Key] == true then S.hl = i break end
                end
            end

            View.buildOptions(S)

            local sc = I.GetScale()
            local ap, asz = S.row.AbsolutePosition, S.row.AbsoluteSize
            local rowX, rowY = ap.X / sc, ap.Y / sc
            local rowW, rowH = asz.X / sc, asz.Y / sc
            local vw, vh = I.Viewport.X / sc, I.Viewport.Y / sc
            local pw = math.max(140, rowW)
            local totalH = S.headerH + S.innerList
            local below = vh - (rowY + rowH) - 10
            local above = rowY - 10
            if below < totalH and above < totalH then
                totalH = S.headerH + math.max(S.optH + 14, math.min(S.innerList, math.max(below, above)))
            end
            local y, slideFrom
            if below >= totalH then
                y, slideFrom = rowY + rowH - 2, -6
            elseif above >= totalH then
                y, slideFrom = rowY - totalH + 2, 6
            else
                y = math.clamp(rowY + rowH + 4, 8, math.max(8, vh - totalH - 8))
                slideFrom = -6
            end
            local x = math.clamp(rowX, 8, math.max(8, vw - pw - 8))

            local list, listCanvas = S.list, S.listCanvas
            listCanvas.CanvasPosition = Vector2.new(0, 0)
            listCanvas.Position = UDim2.new(0, 0, 0, S.headerH)
            listCanvas.Size = UDim2.new(1, 0, 1, -S.headerH)
            list.Size = UDim2.new(0, pw, 0, 0)
            list.Position = UDim2.fromOffset(x, y + slideFrom)
            S.mc.Show()
            I.Tween(list, "Snappy", { Size = UDim2.new(0, pw, 0, totalH) })
            I.Tween(list, "Smooth", { Position = UDim2.fromOffset(x, y) })

            if S.virtual then
                View.updateVirtualWindow(S)
            else
                View.refreshOptions(S)
                for _, rec in ipairs(S.optionButtons) do
                    rec.Button.TextTransparency = 1
                    rec.Button.BackgroundTransparency = 1
                end
                task.spawn(function()
                    for i, opt in ipairs(S.display) do
                        if not S.expanded then return end
                        local rec = S.optionButtons[i]
                        if rec then
                            local isSel = S.selSet[opt.Key] == true
                            I.Tween(rec.Button, "Fast", {
                                TextTransparency = 0,
                                BackgroundTransparency = isSel and 0.75 or 1,
                            })
                        end
                        task.wait(0.02)
                    end
                end)
            end
        else
            S.hl = nil
            local tab = S.tab
            if tab._openDropdown == S.closeFn then tab._openDropdown = nil end
            if S.keyHook then
                I.RemoveInputHook(S.keyHook)
                S.keyHook = nil
            end
            S.mc.Hide()
            I.Tween(S.list, "Fast", { Size = UDim2.new(0, S.list.AbsoluteSize.X / I.GetScale(), 0, 0) })
        end
    end

    function Actions.init(S)
        local self = S.self
        S.selectOption = function(opt, rippleTarget)
            Actions.selectOption(S, opt, rippleTarget)
        end
        S.setExpanded = function(state)
            Actions.setExpanded(S, state)
        end
        S.closeFn = function() Actions.setExpanded(S, false) end

        S.commitSel = function()
            View.saveSelection(S)
            View.refreshOptions(S)
            View.refreshLabel(S)
        end

        S.keyHandler = function(input, gp)
            if not S.expanded then return end
            if gp then
                local kc = input.KeyCode
                if kc ~= Enum.KeyCode.Up and kc ~= Enum.KeyCode.Down
                    and kc ~= Enum.KeyCode.Return and kc ~= Enum.KeyCode.KeypadEnter then
                    return
                end
                if not S.searchBox or I.UserInputService:GetFocusedTextBox() ~= S.searchBox then return end
            end
            if input.KeyCode == Enum.KeyCode.Up then
                View.moveHl(S, -1)
            elseif input.KeyCode == Enum.KeyCode.Down then
                View.moveHl(S, 1)
            elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                if S.hl ~= nil and S.display[S.hl] then
                    local rec = View.recAt(S, S.hl)
                    Actions.selectOption(S, S.display[S.hl], rec and rec.Button or nil)
                end
            end
        end

        self.Maid:Give(function()
            if S.keyHook then I.RemoveInputHook(S.keyHook) end
            if S.tab._openDropdown == S.closeFn then S.tab._openDropdown = nil end
            if S.mc then S.mc.Maid:Destroy() end
        end)
    end

    I.DropdownActions = Actions
end
