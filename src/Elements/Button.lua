return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Button = I.MakeElementClass()

    function Elements.Button.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Button)

        local hasIcon = opts.Icon ~= nil
        local rightW = 0
        if hasIcon then rightW += 26 end

        local row, _, right = I.MkRow(self, tab, opts, "Button", rightW, nil, 0)
        self.Callback = opts.Callback or function() end

        local overlay = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
            Parent = row,
        })

        local function fire()
            if self._disabled then return end
            I.ApplyRipple(overlay)
            I.PlaySound("Click")
            I.RunCallback(self.Callback, self.Title)
        end

        self.Maid:Give(overlay.MouseButton1Click:Connect(function()
            if overlay:GetAttribute("Dragging") then return end
            fire()
        end))
        I.HookContextMenu(self, overlay)

        if hasIcon and right then
            local iconBtn = I.Create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.fromOffset(22, 22),
                AutoButtonColor = false,
                LayoutOrder = 1,
                Parent = right,
            })
            local img = I.MkIcon(iconBtn, opts.Icon, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(16, 16),
            })
            if img:IsA("ImageLabel") then
                self.Maid:Give(iconBtn.MouseEnter:Connect(function() I.Tween(img, "Fast", { ImageColor3 = I.CurrentTheme.Text }) end))
                self.Maid:Give(iconBtn.MouseLeave:Connect(function() I.Tween(img, "Fast", { ImageColor3 = I.CurrentTheme.SubText }) end))
            end
            self.Maid:Give(iconBtn.MouseButton1Click:Connect(fire))
        end

        self:RecalcWidth()
        return self
    end

    function Elements.Button:SetCallback(cb) self.Callback = cb or function() end end
    function Elements.Button:CopyValue() return self.Title end
end
