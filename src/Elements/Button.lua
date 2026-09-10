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
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self.Callback = opts.Callback or function() end
        self._width = 0
        self._busy = false

        local overlay = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
            Parent = row,
        })

        local spinner
        local spinTween
        local function setSpinner(on)
            if on then
                if not spinner then
                    spinner = I.Create("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(14, 14),
                        BackgroundTransparency = 1,
                        ZIndex = 5,
                        Parent = row,
                        Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
                    })
                    I.Bind(I.Create("UIStroke", { Thickness = 2, Parent = spinner }), "Color", "Accent")
                end
                spinner.Visible = true
                spinTween = I.Tween(spinner, TweenInfo.new(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
                if title then I.Tween(title, "Fast", { TextTransparency = 0.55 }) end
            else
                if spinner then spinner.Visible = false end
                if spinTween then pcall(function() spinTween:Cancel() end) spinTween = nil end
                if title and not self._disabled then I.Tween(title, "Fast", { TextTransparency = 0 }) end
            end
        end

        function self:SetBusy(busy)
            if self._destroyed or self._busy == (busy == true) then return end
            self._busy = busy == true
            setSpinner(self._busy)
        end

        local function fire()
            if self._busy or self._disabled then return end
            I.ApplyRipple(overlay)
            I.PlaySound("Click")
            if opts.Confirm then
                ctx.Kailex:Confirm({ Title = "Confirm", Text = tostring(opts.Confirm) }, function()
                    I.RunCallback(self.Callback, self.Title)
                end)
                return
            end
            I.RunCallback(self.Callback, self.Title)
        end

        self.Maid:Give(overlay.MouseButton1Click:Connect(fire))
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
            self.Maid:Give(iconBtn.MouseButton1Click:Connect(fire))
        end

        self:RecalcWidth()
        return self
    end

    function Elements.Button:SetCallback(cb) self.Callback = cb or function() end end
    function Elements.Button:CopyValue() return self.Title end
end
