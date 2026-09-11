return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local View = {}

    function View.initRow(S)
        local opts, tab = S.opts, S.tab
        local baseRowH = I.Device.IsTouch and 62 or 56
        local fullH = baseRowH + (opts.Description and 16 or 0)
        S.fullH = fullH

        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Slider", Height = fullH, RightWidth = 0, Width = opts.Width,
            Description = opts.Description,
        })
        S.row, S.title, S.right, S.left = row, title, right, left

        if opts.Description then
            title.Position = UDim2.new(0, 0, 0, 2)
            title.Size = UDim2.new(1, -84, 0, 15)
        else
            title.Position = UDim2.new(0, 0, 0, 5)
            title.Size = UDim2.new(1, -84, 0, 16)
        end

        S.box = I.Create("TextBox", {
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
        I.Bind(S.box, "TextColor3", "Text")

        S.track = I.Create("Frame", {
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
        I.Bind(S.track, "BackgroundColor3", "SurfaceLight")

        S.fill = I.Create("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = S.track,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        I.Bind(S.fill, "BackgroundColor3", "Accent")

        S.knob = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = S.track,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.Create("UIStroke", {
                    Thickness = 2, Color = I.CurrentTheme.Accent, Transparency = 0.35,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            },
        })
        S.knobStroke = S.knob:FindFirstChildOfClass("UIStroke")
        I.Bind(S.knobStroke, "Color", "Accent")

        S.bubble = I.Create("TextLabel", {
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
        I.Bind(S.bubble, "BackgroundColor3", "SurfaceLight")
        I.Bind(S.bubble, "TextColor3", "Text")
        S.bubbleScale = I.Create("UIScale", { Scale = 1, Parent = S.bubble })

        S.hit = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -4),
            Size = UDim2.new(1, 0, 0, I.Device.IsTouch and 34 or 24),
            ZIndex = 1,
            Parent = left,
        })

        S.resetBtn = I.Create("TextButton", {
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0),
            Position = Setting.RTL and UDim2.new(0, 58, 0, 4) or UDim2.new(1, -72, 0, 4),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Visible = false,
            Parent = left,
        })
        I.Icon(S.resetBtn, "Reset", "SubText", 13)
        I.AddTooltip(S.resetBtn, { Text = "Reset to default (or right-click the slider)" })
        S.resetScale = I.Create("UIScale", { Scale = 1, Parent = S.resetBtn })
        S.resetShown = false
    end

    function View.applyVisuals(S, instant)
        local frac = (S.value - S.min) / (S.max - S.min)
        if instant then
            S.fill.Size = UDim2.fromScale(frac, 1)
        else
            I.Tween(S.fill, "Fast", { Size = UDim2.fromScale(frac, 1) })
        end
        S.knob.Position = UDim2.new(frac, 0, 0.5, 0)
        local trackW = S.track.AbsoluteSize.X
        local bx = frac
        if trackW > 48 then
            bx = math.clamp(frac * trackW, 24, trackW - 24) / trackW
        end
        S.bubble.Position = UDim2.new(bx, 0, 0, S.fullH - 26)
        S.bubble.Text = S.fmt(S.value)
        if not S.box:IsFocused() then
            S.box.Text = string.format("%." .. S.decimals .. "f", S.value)
        end
    end

    I.SliderView = View
end
