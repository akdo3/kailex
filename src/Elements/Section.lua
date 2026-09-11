return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Section = I.MakeElementClass()

    function Elements.Section.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Section)
        local row = I.BareRow(tab.Content, opts.Width, 26)

        local hit = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            Parent = row,
        })

        local bar = I.Create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(3, 13),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = row,
            Children = { I.Corner(2) },
        })
        I.Bind(bar, "BackgroundColor3", "Accent")

        local chevron = I.Icon(row, "Chevron", "SubText")
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -2, 0.5, 0)
        chevron.Size = UDim2.fromOffset(10, 10)

        local label = I.Create("TextLabel", {
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = string.upper(tostring(opts.Name or "Section")),
            Parent = row,
        })
        I.Bind(label, "TextColor3", "SubText")

        self:_init(row, { Name = opts.Name, Width = opts.Width }, nil)
        self.Header = row
        self.TitleLabel = label
        self.Chevron = chevron
        local startCollapsed = opts.Collapsed
        if startCollapsed == nil then
            if opts.Open ~= nil then startCollapsed = not (opts.Open == true)
            elseif opts.Expanded ~= nil then startCollapsed = not (opts.Expanded == true) end
        end
        self.Collapsed = startCollapsed == true
        self.Elements = {}

        if self.Collapsed then
            chevron.Rotation = -90
        end

        self.Maid:Give(hit.MouseButton1Click:Connect(function()
            self:SetCollapsed(not self.Collapsed)
        end))

        return self
    end

    function Elements.Section:_applyVisibility(collapsed)
        for _, el in ipairs(self.Elements) do
            if not el._destroyed then
                if collapsed then
                    el.Row.Visible = false
                else
                    el.Row.Visible = el._manualVisible ~= false
                end
            end
        end
    end

    function Elements.Section:SetCollapsed(collapsed)
        if self.Collapsed == collapsed then return end
        self.Collapsed = collapsed
        if self.Chevron then
            I.Tween(self.Chevron, "PopSoft", { Rotation = collapsed and -90 or 0 })
        end
        if self._filterExpanded then return end
        self:_applyVisibility(collapsed)
    end
end
