return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Divider = I.MakeElementClass()

    function Elements.Divider.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Divider)
        local row = I.BareRow(tab.Content, opts.Width, 13)
        local line = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = I.CurrentTheme.Stroke,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = row,
        })
        I.Bind(line, "BackgroundColor3", "Stroke")
        if opts.Text then
            local label = I.Create("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = I.CurrentTheme.Background,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                Text = " " .. tostring(opts.Text) .. " ",
                Parent = row,
            })
            I.Bind(label, "BackgroundColor3", "Background")
            I.Bind(label, "TextColor3", "SubText")
            self.TitleLabel = label
            function self:SetTitle(text)
                I.Element.SetTitle(self, text)
                if self.TitleLabel and self.TitleLabel.Parent then
                    self.TitleLabel.Text = " " .. tostring(text or "") .. " "
                end
            end
        end
        self:_init(row, { Name = opts.Text, Width = opts.Width }, tab)
        return self
    end
end
