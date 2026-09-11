return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local View = I.DropdownView
    local Actions = I.DropdownActions

    Elements.Dropdown = I.MakeElementClass()

    function Elements.Dropdown.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Dropdown)

        local S = {
            self = self,
            tab = tab,
            opts = opts,
            saveKey = tab:GetSaveKey(opts),
            multi = opts.Multi == true,
        }

        View.initOptions(S)
        View.initSelection(S)
        View.initRow(S)

        self:_init(S.row, opts, tab)
        self:_initRow(S.title, S.right, S.left, S.rightW)
        self.Callback = opts.Callback or function() end

        Actions.init(S)

        local overlay = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.new(1, 0, 0, S.baseH),
            ZIndex = 1,
            Parent = S.row,
        })
        self.Maid:Give(overlay.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if overlay:GetAttribute("Dragging") then return end
            I.ApplyRipple(overlay)
            I.PlaySound("Click", 0.7)
            S.setExpanded(not S.expanded)
        end))
        I.HookContextMenu(self, overlay)

        function self:Set(v, silent)
            if self._destroyed then return end
            View.setSelection(S, (S.multi and type(v) == "table") and v or { v })
            View.saveSelection(S)
            View.refreshOptions(S)
            View.refreshLabel(S)
            if not silent then I.RunCallback(self.Callback, self.Title, self:Get()) end
        end

        function self:Get()
            if S.multi then return View.valuesOf(View.selectedOpts(S)) end
            local sel = View.selectedOpts(S)
            return sel[1] and sel[1].Value or nil
        end

        function self:GetText()
            if S.multi then
                local out = {}
                for _, o in ipairs(View.selectedOpts(S)) do out[#out + 1] = o.Text end
                return out
            end
            local sel = View.selectedOpts(S)
            return sel[1] and sel[1].Text or nil
        end

        function self:CopyValue()
            local t = self:GetText()
            if type(t) == "table" then
                return table.concat(t, ", ")
            end
            return tostring(t or "")
        end

        function self:Reset()
            if self._destroyed then return end
            local defaults
            if S.multi then
                defaults = type(opts.Defaults) == "table" and opts.Defaults or {}
            else
                defaults = (opts.Default ~= nil) and { opts.Default } or {}
            end
            View.setSelection(S, defaults)
            View.saveSelection(S)
            View.refreshOptions(S)
            View.refreshLabel(S)
            I.RunCallback(self.Callback, self.Title, self:Get())
        end

        function self:SetOptions(newOptions)
            if self._destroyed then return end
            View.setOptions(S, newOptions)
            local newW = View.measureWidth(S)
            if newW ~= S.rightW then
                S.rightW = newW
                self._baseRightW = newW
                self._width = newW
                S.valueLabel.Size = UDim2.new(0, newW - 26, 1, 0)
                self:RecalcWidth()
            end
            View.buildOptions(S)
            View.refreshLabel(S)
        end

        self:_bindSaveReload(S.saveKey, function(v)
            self:Set(v, true)
        end)
        self.Maid:Give(ctx.Kailex.ThemeChanged:Connect(function()
            View.refreshLabel(S)
            if S.expanded then View.refreshOptions(S) end
        end))

        View.refreshLabel(S)
        self:_initialCallback(next(S.selSet) ~= nil, self:Get())

        self:RecalcWidth()
        return self
    end
end
