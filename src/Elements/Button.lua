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

        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Button", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self:_initRow(title, right, left, rightW, 0)
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
            local raw = tostring(opts.Icon)
            local isAsset = I.IsAssetId(opts.Icon)
            if isAsset then
                local img = I.Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Image = tonumber(opts.Icon) and ("rbxassetid://" .. opts.Icon) or opts.Icon,
                    ImageColor3 = I.CurrentTheme.SubText,
                    Parent = iconBtn,
                })
                I.Bind(img, "ImageColor3", "SubText")
                self.Maid:Give(iconBtn.MouseEnter:Connect(function() I.Tween(img, "Fast", { ImageColor3 = I.CurrentTheme.Text }) end))
                self.Maid:Give(iconBtn.MouseLeave:Connect(function() I.Tween(img, "Fast", { ImageColor3 = I.CurrentTheme.SubText }) end))
                else
                    I.Icon(iconBtn, raw, "SubText", 16)
                end
            self.Maid:Give(iconBtn.MouseButton1Click:Connect(fire))
        end

        self:RecalcWidth()
        return self
    end

    function Elements.Button:SetCallback(cb) self.Callback = cb or function() end end
    function Elements.Button:CopyValue() return self.Title end
end
