return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService

    Elements.Keybind = I.MakeElementClass()

    local dispatcher = nil
    local function ensureDispatcher()
        if dispatcher then return end
        dispatcher = I.AddInputHook(function() return #I.KeybindRegistry > 0 end, function(input, gp)
            local regs = table.clone(I.KeybindRegistry)
            for i = 1, #regs do
                local el = regs[i] and regs[i].el
                if el and not el._destroyed and el._handleInput then
                    local ok, err = pcall(el._handleInput, input, gp)
                    if not ok then warn("[Kailex] " .. tostring(err)) end
                end
            end
        end)
        I.LibMaid:Give(function() I.RemoveInputHook(dispatcher) end)
    end

    function Elements.Keybind.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Keybind)
        local saveKey = tab:GetSaveKey(opts)
        local rightW = 96
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Keybind", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self:_initRow(title, right, left, rightW)

        self.Callback = opts.Callback or function() end

        local mode = string.lower(tostring(opts.Mode or "press"))
        if mode ~= "toggle" and mode ~= "hold" then mode = "press" end
        self.Mode = mode
        local toggleState = false

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
        local listening = false
        local listenToken = 0

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
            if listening then
                bindBtn.BackgroundColor3 = I.CurrentTheme.Accent
                bindBtn.TextColor3 = I.CurrentTheme.OnAccent
                bindBtn.Text = "Press a key..."
            else
                bindBtn.BackgroundColor3 = I.CurrentTheme.SurfaceLight
                bindBtn.TextColor3 = I.CurrentTheme.Text
                bindBtn.Text = binding and binding.Name or "None"
            end
        end

        local function setListening(on)
            if listening == on then return end
            listening = on
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

        local function setBinding(b)
            binding = b
            I.SaveValue(saveKey, b and (b.Kind .. ":" .. b.Name) or "__none")
            if b then I.NotifyKeybindConflict(self, b) end
            refresh()
        end

        self._getBinding = function() return binding end

        self._handleInput = function(input, gp)
            if self._destroyed then return end
            if listening then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    if gp then return end
                    listenToken += 1
                    setListening(false)
                    if input.KeyCode == Enum.KeyCode.Escape then
                        return
                    end
                    setBinding({
                        Kind = "Key",
                        Code = input.KeyCode,
                        Name = input.KeyCode.Name,
                    })
                    I.PlaySound("Click")
                elseif opts.MouseButtons
                    and (input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3) then
                    listenToken += 1
                    setListening(false)
                    setBinding({
                        Kind = "Mouse",
                        Code = input.UserInputType,
                        Name = input.UserInputType.Name,
                    })
                    I.PlaySound("Click")
                end
                return
            end
            if I.ActiveKeybindListener ~= nil then return end
            if gp then return end
            if self._disabled then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            if not binding then return end
            local matched = false
            if binding.Kind == "Key" and input.KeyCode == binding.Code then
                matched = true
            elseif binding.Kind == "Mouse" and input.UserInputType == binding.Code
                and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                matched = true
            end
            if not matched then return end
            if mode == "toggle" then
                toggleState = not toggleState
                self._toggleState = toggleState
                I.RunCallback(self.Callback, self.Title, binding.Code, toggleState)
            elseif mode == "hold" then
                self._holding = true
                I.RunCallback(self.Callback, self.Title, binding.Code, true)
            else
                I.RunCallback(self.Callback, self.Title, binding.Code)
            end
        end

        ensureDispatcher()

        self.Maid:Give(function()
            if listening then
                listening = false
                if I.ActiveKeybindListener == self then I.ActiveKeybindListener = nil end
            end
        end)

        if mode == "hold" then
            self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
                if self._destroyed or self._holding ~= true then return end
                if not binding then return end
                local matched = false
                if binding.Kind == "Key" and input.KeyCode == binding.Code then
                    matched = true
                elseif binding.Kind == "Mouse" and input.UserInputType == binding.Code then
                    matched = true
                end
                if matched then
                    self._holding = false
                    I.RunCallback(self.Callback, self.Title, binding.Code, false)
                end
            end))
        end

        self.Maid:Give(bindBtn.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if bindBtn:GetAttribute("Dragging") then return end
            I.ApplyRipple(bindBtn)
            I.PlaySound("Click", 0.6)
            if listening then
                listenToken += 1
                setListening(false)
            else
                setListening(true)
                listenToken += 1
                local myToken = listenToken
                task.delay(6, function()
                    if listening and listenToken == myToken then
                        setListening(false)
                    end
                end)
            end
        end))

        function self:_contextItems()
            local items = {}
            if binding then
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

        local function showMenu()
            if self._destroyed or listening then return end
            local items = self:_contextItems()
            if #items == 0 then return end
            local m = UserInputService:GetMouseLocation()
            I.ContextMenu.Show(items, m.X, m.Y)
        end

        I.OnLongPress(bindBtn, function()
            return not listening and not self._destroyed
        end, showMenu)

        function self:Set(v, silent)
            local b = I.ToBinding(v)
            if not b then return end
            setBinding(b)
            if not silent then I.RunCallback(self.Callback, self.Title, b.Code) end
        end
        function self:Get()
            return binding and binding.Code or nil
        end
        function self:GetName()
            return binding and binding.Name or "None"
        end
        function self:GetState()
            if mode == "toggle" then return toggleState end
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
