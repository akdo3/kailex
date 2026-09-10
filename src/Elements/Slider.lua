return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting
    local UserInputService = I.UserInputService

    Elements.Slider = I.MakeElementClass()

    function Elements.Slider.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Slider)
        local saveKey = tab:GetSaveKey(opts)
        local min = tonumber(opts.Min or opts.MinVal or 0) or 0
        local max = tonumber(opts.Max or opts.MaxVal or 100) or 100
        if max <= min then max = min + 1 end
        local increment = tonumber(opts.Increment)
        local default = tonumber(opts.Default or opts.Value or min) or min
        local value = I.SaveManager:Get(saveKey, default)
        if type(value) ~= "number" then value = default end
        value = math.clamp(value, min, max)

        local prefix = opts.Prefix and tostring(opts.Prefix) or nil
        local suffix = opts.Suffix and tostring(opts.Suffix) or nil
        local onRelease = opts.FireOnRelease == true

        local baseRowH = I.Device.IsTouch and 62 or 56
        local fullH = baseRowH + (opts.Description and 16 or 0)
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Slider", Height = fullH, RightWidth = 0, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = 0
        self._width = 0

        self.Callback = opts.Callback or function() end
        title.Size = UDim2.new(1, -84, 0, 16)
        title.Position = UDim2.new(0, 0, 0, 5)

        local box = I.Create("TextBox", {
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0),
            Position = Setting.RTL and UDim2.new(0, 0, 0, 3) or UDim2.new(1, 0, 0, 3),
            Size = UDim2.fromOffset(52, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            Text = "",
            ClearTextOnFocus = false,
            Parent = left,
        })
        I.Bind(box, "TextColor3", "Text")

        local track = I.Create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -9),
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Parent = left,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.StrokeBind(1, "Stroke", 0.7),
            },
        })
        I.Bind(track, "BackgroundColor3", "SurfaceLight")
        local fill = I.Create("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = track,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        I.Bind(fill, "BackgroundColor3", "Accent")
        local knob = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = track,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.Create("UIStroke", { Thickness = 2, Color = I.CurrentTheme.Accent, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            },
        })
        local knobStroke = knob:FindFirstChildOfClass("UIStroke")

        local bubble = I.Create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0, fullH - 26),
            Size = UDim2.fromOffset(44, 16),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 20,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.Text,
            Text = "",
            Parent = left,
            Children = { I.Corner(6), I.StrokeBind(1, "Stroke", 0.3) },
        })
        I.Bind(bubble, "BackgroundColor3", "SurfaceLight")
        I.Bind(bubble, "TextColor3", "Text")

        local bubbleScale = I.Create("UIScale", { Scale = 1, Parent = bubble })

        local step = (increment and increment > 0) and increment
            or ((min % 1 == 0 and max % 1 == 0) and 1 or 0.01)
        local decimals = step >= 1 and 0 or math.clamp(math.ceil(-math.log10(step)), 1, 3)
        local pow = 10 ^ decimals
        local function RoundStep(v)
            return math.floor(v * pow + 0.5) / pow
        end
        local defaultValue = math.clamp(RoundStep(math.floor((default - min) / step + 0.5) * step + min), min, max)

        local function fmt(val)
            local s
            if decimals <= 0 then
                s = tostring(math.floor(val + 0.5))
            else
                s = string.format("%." .. decimals .. "f", val)
            end
            return (prefix or "") .. s .. (suffix or "")
        end

        local updateResetVisibility

        local function apply(newValue, instant)
            value = math.clamp(newValue, min, max)
            local frac = (value - min) / (max - min)
            if instant then
                fill.Size = UDim2.fromScale(frac, 1)
            else
                I.Tween(fill, "Fast", { Size = UDim2.fromScale(frac, 1) })
            end
            knob.Position = UDim2.new(frac, 0, 0.5, 0)
            local trackW = track.AbsoluteSize.X
            local bx = frac
            if trackW > 48 then
                bx = math.clamp(frac * trackW, 24, trackW - 24) / trackW
            end
            bubble.Position = UDim2.new(bx, 0, 0, fullH - 26)
            bubble.Text = fmt(value)
            if not box:IsFocused() then box.Text = string.format("%." .. decimals .. "f", value) end
            if updateResetVisibility then updateResetVisibility() end
        end

        local dragging = false
        local dragMaid = nil
        local function snap(f)
            local v = min + (max - min) * f
            if step > 0 then
                v = math.floor((v - min) / step + 0.5) * step + min
            end
            return math.clamp(RoundStep(v), min, max)
        end

        local hit = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -4),
            Size = UDim2.new(1, 0, 0, I.Device.IsTouch and 34 or 24),
            ZIndex = 1,
            Parent = left,
        })

        local resetBtn = I.Create("TextButton", {
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0),
            Position = Setting.RTL and UDim2.new(0, 58, 0, 4) or UDim2.new(1, -72, 0, 4),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Visible = false,
            Parent = left,
        })
        local resetIcon = I.Icon(resetBtn, "Reset", "SubText")
        resetIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        resetIcon.Position = UDim2.fromScale(0.5, 0.5)
        resetIcon.Size = UDim2.fromOffset(13, 13)
        I.AddTooltip(resetBtn, { Text = "Reset to default (or right-click the slider)" })
        local resetScale = I.Create("UIScale", { Scale = 1, Parent = resetBtn })
        local resetShown = false

        updateResetVisibility = function()
            local show = math.abs(value - defaultValue) > 1e-4
            if show == resetShown then return end
            resetShown = show
            if show then
                resetBtn.Visible = true
                resetScale.Scale = 0.4
                I.Tween(resetScale, "PopSoft", { Scale = 1 })
            else
                I.Tween(resetScale, "Vanish", { Scale = 0.4 }, function()
                    if not resetShown then resetBtn.Visible = false end
                end)
            end
        end

        local function resetToDefault()
            if self._destroyed then return end
            if math.abs(value - defaultValue) > 1e-6 then
                I.ApplyRipple(resetBtn)
                I.PlaySound("ToggleOn", 0.5)
                self:Set(defaultValue)
                bubble.Visible = true
                bubble.Text = fmt(value)
                bubbleScale.Scale = 0.7
                I.Tween(bubbleScale, "PopSoft", { Scale = 1 })
                task.delay(0.55, function()
                    if not dragging and not self._destroyed then
                        I.Tween(bubbleScale, "Vanish", { Scale = 0.7 }, function()
                            if not dragging and not self._destroyed then bubble.Visible = false end
                        end)
                    end
                end)
            end
        end
        self.Maid:Give(resetBtn.MouseButton1Click:Connect(resetToDefault))
        self.Maid:Give(hit.MouseButton2Click:Connect(resetToDefault))
        function self:Reset() resetToDefault() end

        hit.InputBegan:Connect(function(input)
            if dragging or I.DragManager.Active then return end
            if self._disabled then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            I.DragManager.Active = track
            I.PlaySound("Slider")
            I.Tween(knob, "Spring", { Size = UDim2.fromOffset(18, 18) })
            I.Tween(knobStroke, "Fast", { Transparency = 0 })
            bubble.Visible = true
            bubbleScale.Scale = 0.7
            I.Tween(bubbleScale, "PopSoft", { Scale = 1 })

            local function finish()
                if not dragging then return end
                dragging = false
                if I.DragManager.Active == track then I.DragManager.Active = nil end
                if dragMaid then dragMaid:Destroy() dragMaid = nil end
                I.Tween(knob, "Spring", { Size = UDim2.fromOffset(14, 14) })
                I.Tween(knobStroke, "Fast", { Transparency = 0.35 })
                I.Tween(bubbleScale, "Vanish", { Scale = 0.7 }, function()
                    if not dragging and not self._destroyed then bubble.Visible = false end
                end)
                I.SaveValue(saveKey, value)
                if onRelease then
                    I.RunCallback(self.Callback, self.Title, value)
                end
            end

            dragMaid = I.Maid.new()
            dragMaid:Give(UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                    finish()
                end
            end))
            dragMaid:Give(hit.Destroying:Connect(finish))
            dragMaid:Give(row.Destroying:Connect(finish))
            dragMaid:Give(I.RunService.Heartbeat:Connect(function()
                if not I.IsInputDown(input.UserInputType) then finish() end
            end))

            local function update(x)
                local ap, as = track.AbsolutePosition, track.AbsoluteSize
                if as.X <= 1 then return end
                local frac = math.clamp((x - ap.X) / as.X, 0, 1)
                local v = snap(frac)
                if v ~= value then
                    apply(v)
                    if not onRelease then
                        I.RunCallback(self.Callback, self.Title, value)
                    end
                end
            end

            update(input.Position.X)
            dragMaid:Give(UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch then
                    update(inp.Position.X)
                end
            end))
        end)

        track.MouseEnter:Connect(function()
            if not dragging then I.Tween(knob, "Fast", { Size = UDim2.fromOffset(16, 16) }) end
        end)
        track.MouseLeave:Connect(function()
            if not dragging then I.Tween(knob, "Fast", { Size = UDim2.fromOffset(14, 14) }) end
        end)

        I.Bind(knobStroke, "Color", "Accent")

        self.Maid:Give(box.FocusLost:Connect(function()
            local t = tostring(box.Text or "")
            if prefix and t:sub(1, #prefix) == prefix then t = t:sub(#prefix + 1) end
            if suffix and #suffix > 0 and t:sub(-#suffix) == suffix then t = t:sub(1, -#suffix - 1) end
            local num = tonumber(t:gsub(",", "."):gsub("%s", ""))
            if num then
                self:Set(num)
            else
                box.Text = string.format("%." .. decimals .. "f", value)
            end
        end))

        function self:Set(newValue, silent)
            if self._destroyed then return end
            local nv = tonumber(newValue)
            if nv == nil then return end
            nv = math.clamp(RoundStep(math.floor((nv - min) / step + 0.5) * step + min), min, max)
            if decimals <= 0 then nv = math.floor(nv + 0.5) end
            apply(nv)
            I.SaveValue(saveKey, value)
            if not silent then I.RunCallback(self.Callback, self.Title, value) end
        end
        function self:Get() return value end
        function self:CopyValue() return string.format("%." .. math.max(decimals, 0) .. "f", value) end

        function self:HandleArrow(dir)
            if self._destroyed or self._disabled then return end
            local fine = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
            local d = step * (fine and 0.2 or 1) * dir
            self:Set(value + d)
        end

        self.Maid:Give(function()
            if I.HotElement == self then I.HotElement = nil end
        end)
        if not I.Device.IsTouch then
            row.MouseEnter:Connect(function() I.HotElement = self end)
            row.MouseLeave:Connect(function()
                if I.HotElement == self then I.HotElement = nil end
            end)
        end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "number" then self:Set(v, true) end
        end)

        apply(value, true)
        if opts.Default ~= nil or I.SaveManager:Get(saveKey, nil) ~= nil then
            task.defer(function()
                if not self._destroyed then I.RunCallback(self.Callback, self.Title, value) end
            end)
        end

        self:RecalcWidth()
        return self
    end
end
