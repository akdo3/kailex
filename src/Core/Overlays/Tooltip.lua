return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting
    local UserInputService = I.UserInputService

    local Tooltip = {}
    I.Tooltip = Tooltip

    do
        local frame = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(0, 26),
            Visible = false,
            ZIndex = 100,
            Parent = I.LayerTooltip,
            Children = { I.Corner(6), I.StrokeBind(1, "Stroke", 0.35) },
        })
        I.Bind(frame, "BackgroundColor3", "SurfaceLight")
        local label = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
        I.Bind(label, "TextColor3", "Text")
        local tipScale = I.Create("UIScale", { Scale = 1, Parent = frame })
        local maid = I.Maid.new()
        local hideToken = 0
        local tipW, tipH = 0, 26

        local function position()
            local m = UserInputService:GetMouseLocation()
            local s = I.GetScale()
            local x, y = m.X + 14, m.Y + 18
            if x + tipW > I.Viewport.X - 8 then x = m.X - tipW - 14 end
            if y + tipH > I.Viewport.Y - 8 then y = m.Y - tipH - 16 end
            if x < 8 then x = 8 end
            if y < 8 then y = 8 end
            frame.Position = UDim2.fromOffset(x / s, y / s)
        end

        function Tooltip.Show(text)
            if not text or text == "" then return end
            hideToken += 1
            label.Text = text
            local bounds = I.TextService:GetTextSize(text, I.TS(12), Enum.Font.Gotham, Vector2.new(340, 1000))
            tipW = math.min(bounds.X + 18, 358)
            tipH = math.clamp(bounds.Y + 10, 24, 92)
            frame.Size = UDim2.fromOffset(tipW, tipH)
            frame.Visible = true
            frame.BackgroundTransparency = 1
            label.TextTransparency = 1
            tipScale.Scale = 0.93
            position()
            maid:Clean()
            maid:Give(UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then position() end
            end))
            I.Tween(frame, "Fast", { BackgroundTransparency = 0.06 })
            I.Tween(label, "Fast", { TextTransparency = 0 })
            I.Tween(tipScale, "PopSoft", { Scale = 1 })
        end

        function Tooltip.Hide()
            if not frame.Visible then return end
            hideToken += 1
            local tk = hideToken
            I.Tween(tipScale, "Vanish", { Scale = 0.95 })
            I.Tween(frame, "Vanish", { BackgroundTransparency = 1 })
            I.Tween(label, "Vanish", { TextTransparency = 1 })
            task.delay(0.16, function()
                if hideToken == tk then frame.Visible = false end
            end)
            maid:Clean()
        end
    end

    local function AddTooltip(obj, ref)
        local function getText()
            return type(ref) == "table" and ref.Text or ref
        end
        if I.Device.IsTouch then
            obj.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Touch then return end
                local text = getText()
                if not text or text == "" then return end
                local token = {}
                Tooltip._touchToken = token
                task.delay(0.55, function()
                    if Tooltip._touchToken == token then Tooltip.Show(getText()) end
                end)
            end)
            obj.InputEnded:Connect(function()
                Tooltip._touchToken = nil
                Tooltip.Hide()
            end)
        else
            obj.MouseEnter:Connect(function()
                local text = getText()
                if not text or text == "" then return end
                Tooltip.Show(text)
            end)
            obj.MouseLeave:Connect(Tooltip.Hide)
        end
        obj.Destroying:Connect(Tooltip.Hide)
    end
    I.AddTooltip = AddTooltip
end
