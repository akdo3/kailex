return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Kailex = ctx.Kailex
    local Wire = I.WireKeybind

    Elements.Keybind = I.MakeElementClass()

    function Elements.Keybind.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Keybind)
        local saveKey = tab:GetSaveKey(opts)
        local rightW = 96
        local _, _, right = I.MkRow(self, tab, opts, "Keybind", rightW)

        self.Callback = opts.Callback or function() end

        local mode = string.lower(tostring(opts.Mode or "press"))
        if mode ~= "toggle" and mode ~= "hold" then mode = "press" end
        self.Mode = mode

        local savedBinding = I.SaveManager:Get(saveKey, nil)
        local binding
        if savedBinding == "__none" then
            binding = nil
        else
            binding = I.ToBinding(savedBinding)
            if binding == nil then
                binding = I.ToBinding(opts.Default)
            end
        end

        local S = {
            self = self, opts = opts, mode = mode, binding = binding,
            listening = false, listenToken = 0, toggleState = false,
        }

        table.insert(I.KeybindRegistry, { el = self })
        self.Maid:Give(function()
            for i, rec in ipairs(I.KeybindRegistry) do
                if rec.el == self then table.remove(I.KeybindRegistry, i) break end
            end
            if I.ActiveKeybindListener == self then I.ActiveKeybindListener = nil end
        end)

        local bindBtn = I.Create("TextButton", {
            Size = UDim2.new(1, 0, 0, I.Device.IsTouch and 30 or 26),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Text = "None",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.Text,
            AutoButtonColor = false,
            Parent = right,
            Children = { I.Corner(6), I.StrokeBind(1, "Stroke", 0.5) },
        })

        local function refresh()
            if S.listening then
                bindBtn.BackgroundColor3 = I.CurrentTheme.Accent
                bindBtn.TextColor3 = I.CurrentTheme.OnAccent
                bindBtn.Text = "Press a key..."
            else
                bindBtn.BackgroundColor3 = I.CurrentTheme.SurfaceLight
                bindBtn.TextColor3 = I.CurrentTheme.Text
                bindBtn.Text = S.binding and S.binding.Name or "None"
            end
        end

        local function setListening(on)
            if S.listening == on then return end
            S.listening = on
            if on then
                if I.ActiveKeybindListener and I.ActiveKeybindListener ~= self
                    and not I.ActiveKeybindListener._destroyed
                    and I.ActiveKeybindListener._cancelListen then
                    I.ActiveKeybindListener._cancelListen()
                end
                I.ActiveKeybindListener = self
            elseif I.ActiveKeybindListener == self then
                I.ActiveKeybindListener = nil
            end
            refresh()
        end
        self._cancelListen = function() setListening(false) end
        S.setListening = setListening

        local function setBinding(b)
            S.binding = b
            I.SaveValue(saveKey, b and (b.Kind .. ":" .. b.Name) or "__none")
            if b then I.NotifyKeybindConflict(self, b) end
            refresh()
        end
        S.setBinding = setBinding

        self._getBinding = function() return S.binding end

        Wire(S)

        self.Maid:Give(function()
            if S.listening then
                S.listening = false
                if I.ActiveKeybindListener == self then I.ActiveKeybindListener = nil end
            end
        end)

        self.Maid:Give(bindBtn.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if bindBtn:GetAttribute("Dragging") then return end
            I.ApplyRipple(bindBtn)
            I.PlaySound("Click", 0.6)
            if S.listening then
                S.listenToken += 1
                setListening(false)
            else
                setListening(true)
                S.listenToken += 1
                local myToken = S.listenToken
                task.delay(6, function()
                    if S.listening and S.listenToken == myToken then
                        setListening(false)
                    end
                end)
            end
        end))

        I.HookContextMenu(self, bindBtn, function()
            return not S.listening and not self._destroyed
        end)

        function self:_contextItems()
            local items = {}
            if S.binding then
                table.insert(items, {
                    Text = "Clear keybind",
                    Callback = function()
                        setBinding(nil)
                    end,
                })
            end
            for _, it in ipairs(I.Element._contextItems(self)) do
                table.insert(items, it)
            end
            return items
        end

        function self:Set(v, silent)
            local b = I.ToBinding(v)
            if not b then return end
            setBinding(b)
            if not silent then I.RunCallback(self.Callback, self.Title, b.Code) end
        end
        function self:Get()
            return S.binding and S.binding.Code or nil
        end
        function self:GetName()
            return S.binding and S.binding.Name or "None"
        end
        function self:GetState()
            if mode == "toggle" then return S.toggleState end
            if mode == "hold" then return self._holding == true end
            return nil
        end
        function self:CopyValue() return self:GetName() end
        function self:Reset()
            if self._destroyed then return end
            local b = I.ToBinding(opts.Default)
            if b then
                setBinding(b)
            else
                setBinding(nil)
            end
        end

        self:_bindSaveReload(saveKey, function(v)
            if v == "__none" then
                setBinding(nil)
                return
            end
            local b = I.ToBinding(v)
            if b then setBinding(b) end
        end)
        self.Maid:Give(Kailex.ThemeChanged:Connect(refresh))
        refresh()

        self:RecalcWidth()
        return self
    end
end
