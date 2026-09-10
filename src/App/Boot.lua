return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService

    function Kailex:Unload()
        I.ModalManager.CloseAll()
        pcall(function() I.ContextMenu.Hide() end)
        for el in pairs(I.QuickWidgets.Active) do I.QuickWidgets.Destroy(el) end
        for i = #Kailex.Windows, 1, -1 do
            local w = Kailex.Windows[i]
            if w and w.Destroy then pcall(w.Destroy, w) end
        end
        I.Tooltip.Hide()
        I.HotElement = nil
        I.ActiveKeybindListener = nil
        I.LibMaid:Destroy()
        for _, s in ipairs(I.SoundInstances) do
            pcall(function() s:Destroy() end)
        end
        table.clear(I.SoundInstances)
        for k in pairs(I.SoundPool) do I.SoundPool[k] = nil end
        for _, r in ipairs(I.RipplePool) do
            pcall(function() r:Destroy() end)
        end
        for i = #I.RipplePool, 1, -1 do table.remove(I.RipplePool, i) end
        pcall(function() I.ScreenGui:Destroy() end)
        local genv = I.Getgenv()
        if genv and genv.kailex == Kailex then genv.kailex = nil end
    end

    I.ApplyPersisted()
    if I.Device.IsConsole then
        I.Setting.UIScale = math.max(tonumber(I.Setting.UIScale) or 1, 1.15)
    end
    I.UpdateViewport()

    local bootHook = I.AddInputHook(function() return true end, function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local top = I.ModalManager.Stack[#I.ModalManager.Stack]
            if not (top and top.Owner == nil) then
                local m = input.Position
                if m then
                    local best, bestZ = nil, -1
                    for _, w in ipairs(Kailex.Windows) do
                        if not w._destroyed and w.Root and w.Root.Visible and not w._hidden then
                            local ap, as = w.Root.AbsolutePosition, w.Root.AbsoluteSize
                            if m.X >= ap.X and m.X <= ap.X + as.X
                                and m.Y >= ap.Y and m.Y <= ap.Y + as.Y then
                                if w.Root.ZIndex > bestZ then
                                    best, bestZ = w, w.Root.ZIndex
                                end
                            end
                        end
                    end
                    if best and best._focus then I.SafeCall(best._focus) end
                end
            end
        end

        if input.KeyCode == Enum.KeyCode.Escape then
            if I.ActiveKeybindListener == nil and I.ModalManager.CloseTop() then
                return
            end
        end

        if gp then return end
        local code = input.KeyCode
        if code == Enum.KeyCode.Unknown then return end
        if I.ActiveKeybindListener ~= nil then return end
        if UserInputService:GetFocusedTextBox() ~= nil then return end

        if code == Enum.KeyCode.F
            and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            local w = Kailex._lastActive
            if w and not w._destroyed and not w._hidden
                and not w.Minimized and w._setSearch then
                w:_setSearch(true)
            end
            return
        end

        local key = I.Setting.ToggleUIKey
        if key ~= nil and code == key then
            Kailex:SetVisible(not Kailex:IsVisible())
            return
        end
        for _, w in ipairs(Kailex.Windows) do
            if not w._destroyed and w.ToggleKey == code then
                w:ToggleHidden()
                return
            end
        end

        local el = I.HotElement
        if el and not el._destroyed and not el._disabled and el.HandleArrow then
            local dir
            if code == Enum.KeyCode.Left or code == Enum.KeyCode.Down then dir = -1
            elseif code == Enum.KeyCode.Right or code == Enum.KeyCode.Up then dir = 1 end
            if dir then el:HandleArrow(dir) end
        end
    end)
    I.LibMaid:Give(function() I.RemoveInputHook(bootHook) end)

    I.LibMaid:Give(I.SaveManager.DataChanged:Connect(function()
        I.ApplyPersisted()
    end))

    if I.Device.IsTouch then
        Kailex:CreateMobileButton()
    end

    I.LibMaid:Give(I.ScreenGui.Destroying:Connect(function()
        I.LibMaid:Destroy()
    end))

    local genv = I.Getgenv()
    if genv then genv.kailex = Kailex end
end
