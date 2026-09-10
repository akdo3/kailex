return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    function Kailex:CreateMobileButton()
        if self._mobileButton then return self._mobileButton end
        local s = I.GetScale()
        local btn = I.Create("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(46, 46),
            Position = UDim2.fromOffset((I.Viewport.X - 42) / s, (I.Viewport.Y - 42) / s),
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 5,
            Parent = I.LayerNotify,
        })
        I.Bind(btn, "BackgroundColor3", "Surface")
        I.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
        I.StrokeBind(1, "Stroke", 0.35).Parent = btn
        local glyph = I.Create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 18,
            TextColor3 = I.CurrentTheme.Text,
            Text = "K",
            Parent = btn,
        })
        I.Bind(glyph, "TextColor3", "Text")
        local mmaid = I.Maid.new():Link(btn)
        I.MakeDraggable(btn, btn, { Clamp = true })
        btn.Size = UDim2.fromOffset(0, 0)
        I.Tween(btn, "Pop", { Size = UDim2.fromOffset(46, 46) })
        mmaid:Give(btn.MouseButton1Click:Connect(function()
            if btn:GetAttribute("Dragging") then return end
            I.ApplyRipple(btn)
            Kailex:SetVisible(not Kailex:IsVisible())
        end))
        self._mobileButton = btn
        return btn
    end
end
