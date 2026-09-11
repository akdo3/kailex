return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    function Kailex:CreateMobileButton()
        if self._mobileButton then return self._mobileButton end
        local s = I.GetScale()
        local btn, _, mmaid = I.FloatingChip({
            Circle = true,
            StrokeT = 0.35,
            Font = Enum.Font.GothamBlack,
            TextSize = 18,
            Text = "K",
            Pop = "Pop",
            Position = UDim2.fromOffset((I.Viewport.X - 42) / s, (I.Viewport.Y - 42) / s),
        })
        mmaid:Give(btn.MouseButton1Click:Connect(function()
            if btn:GetAttribute("Dragging") then return end
            I.ApplyRipple(btn)
            Kailex:SetVisible(not Kailex:IsVisible())
        end))
        self._mobileButton = btn
        return btn
    end
end
