return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService

    Elements.Keybind = I.MakeElementClass()

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
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW

        self.Callback = opts.Callback or function() end

        local binding = I.ToBinding(I.SaveManager:Get(saveKey, nil)) or I.ToBinding(opts.Default)
        local listening = false
        local suppressClear = false
        local listenToken = 0

        table.insert(I.KeybindRegistry, { el = self })
        self.Maid:Give(function()
            for i, rec in ipairs(I.KeybindRegistry) do
                if rec.el == self then table.remove(I.KeybindRegistry, i) break end
            end
            if I.ActiveKeybindListener == self then I.ActiveKeybindListener = nil end
        end)

        local bindBtn = I.Create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
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
                    listenToken += 1
                    setListening(false)
                    if input.KeyCode == Enum.KeyCode.Escape then
                        return
                    end
                    setBinding({
                        Kind = "Key",
                        Code = input.KeyCode,
                        Name = tostring(input.KeyCode):match("%.(.+)$") or tostring(input.KeyCode),
                    })
                    I.PlaySound("Click")
                elseif opts.MouseButtons
                    and (input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3) then
                    listenToken += 1
                    setListening(false)
                    suppressClear = true
                    task.defer(function() suppressClear = false end)
                    setBinding({
                        Kind = "Mouse",
                        Code = input.UserInputType,
                        Name = tostring(input.UserInputType):match("%.(.+)$") or tostring(input.UserInputType),
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
            if binding.Kind == "Key" and input.KeyCode == binding.Code then
                I.RunCallback(self.Callback, self.Title, binding.Code)
            elseif binding.Kind == "Mouse" and input.UserInputType == binding.Code
                and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                I.RunCallback(self.Callback, self.Title, binding.Code)
            end
        end

        local hook = I.AddInputHook(function() return not self._destroyed end, self._handleInput)
        self.Maid:Give(function()
            I.RemoveInputHook(hook)
            if listening then
                listening = false
                if I.ActiveKeybindListener == self then I.ActiveKeybindListener = nil end
            end
        end)

        self.Maid:Give(bindBtn.MouseButton1Click:Connect(function()
            if self._disabled then return end
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

        self.Maid:Give(bindBtn.MouseButton2Click:Connect(function()
            if suppressClear or listening then return end
            setBinding(nil)
        end))

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
        function self:CopyValue() return self:GetName() end

        self:_bindSaveReload(saveKey, function(v)
            local b = I.ToBinding(v)
            if b then setBinding(b) end
        end)
        self.Maid:Give(Kailex.ThemeChanged:Connect(refresh))
        refresh()

        self:RecalcWidth()
        return self
    end
end
