return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local UserInputService = I.UserInputService

    Elements.Stepper = I.MakeElementClass()

    function Elements.Stepper.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Stepper)
        local saveKey = tab:GetSaveKey(opts)
        local min = tonumber(opts.Min) or 0
        local max = tonumber(opts.Max) or 10
        if max <= min then max = min + 1 end
        local step = tonumber(opts.Step) or 1
        if step <= 0 then step = 1 end
        local default = tonumber(opts.Default or min) or min
        local value = I.SaveManager:Get(saveKey, default)
        if type(value) ~= "number" then value = default end
        value = math.clamp(value, min, max)

        local decimals = step >= 1 and 0 or math.clamp(math.ceil(-math.log10(step)), 1, 3)
        local fmt = opts.Format
        if type(fmt) ~= "function" then
            local prefix = opts.Prefix or ""
            local suffix = opts.Suffix or ""
            fmt = function(v)
                return prefix .. string.format("%." .. decimals .. "f", v) .. suffix
            end
        end

        local rightW = 118
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Stepper", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
        self.Callback = opts.Callback or function() end

        local function mkStepBtn(text, order)
            local b = I.Create("TextButton", {
                Size = UDim2.fromOffset(26, 26),
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = I.CurrentTheme.Text,
                AutoButtonColor = false,
                LayoutOrder = order,
                Parent = right,
                Children = { I.Corner(8) },
            })
            I.Bind(b, "BackgroundColor3", "Element")
            I.Bind(b, "TextColor3", "Text")
            I.AddHover(b)
            I.AddPress(b)
            return b
        end

        local minus = mkStepBtn("-", 1)
        local valLabel = I.Create("TextLabel", {
            Size = UDim2.fromOffset(56, 26),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 2,
            Parent = right,
        })
        I.Bind(valLabel, "TextColor3", "Text")
        local plus = mkStepBtn("+", 3)

        local function refreshLabel()
            valLabel.Text = fmt(value)
        end
        refreshLabel()

        function self:Set(v, silent)
            if self._destroyed then return end
            local n = tonumber(v)
            if n == nil then return end
            n = math.clamp(n, min, max)
            if n == value then return end
            value = n
            refreshLabel()
            I.SaveValue(saveKey, value)
            if not silent then I.RunCallback(self.Callback, self.Title, value) end
        end
        function self:Get() return value end
        function self:CopyValue() return string.format("%." .. decimals .. "f", value) end
        function self:Reset()
            if self._destroyed then return end
            self:Set(default)
        end

        local function bindHold(btn, dir)
            btn.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if self._disabled then return end
                I.ApplyRipple(btn)
                self:Set(value + dir * step)
                local holding = true
                local hMaid = I.Maid.new()
                local function stop()
                    if not holding then return end
                    holding = false
                    hMaid:Destroy()
                end
                hMaid:Give(UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                        or inp.UserInputType == Enum.UserInputType.Touch then stop() end
                end))
                hMaid:Give(btn.Destroying:Connect(stop))
                hMaid:Give(I.RunService.Heartbeat:Connect(function()
                    if not I.IsInputDown(input.UserInputType) then stop() end
                end))
                task.delay(0.45, function()
                    if not holding then return end
                    while holding do
                        self:Set(value + dir * step)
                        task.wait(0.09)
                    end
                end)
            end)
        end
        bindHold(minus, -1)
        bindHold(plus, 1)

        function self:HandleArrow(dir)
            if self._destroyed or self._disabled then return end
            self:Set(value + dir * step)
        end

        if not I.Device.IsTouch then
            row.MouseEnter:Connect(function() I.HotElement = self end)
            row.MouseLeave:Connect(function()
                if I.HotElement == self then I.HotElement = nil end
            end)
            self.Maid:Give(function()
                if I.HotElement == self then I.HotElement = nil end
            end)
        end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "number" then self:Set(v, true) end
        end)

        if opts.Default ~= nil or I.SaveManager:Get(saveKey, nil) ~= nil then
            task.defer(function()
                if not self._destroyed then I.RunCallback(self.Callback, self.Title, value) end
            end)
        end

        self:RecalcWidth()
        return self
    end
end
