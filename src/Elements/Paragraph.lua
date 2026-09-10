return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting

    Elements.Paragraph = I.MakeElementClass()

    function Elements.Paragraph.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Paragraph)
        local row = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.Element,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Size = UDim2.new((opts.Width or 1), -3, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = tab.Content,
            Children = {
                I.Corner(8), I.StrokeBind(1, "Stroke", 0.65),
                I.Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
                }),
                I.Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
            },
        })
        I.Bind(row, "BackgroundColor3", "Element")
        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = opts.Title or opts.Name or "",
            Parent = row,
        })
        I.Bind(title, "TextColor3", "Text")
        local body = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextWrapped = true,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            Text = tostring(opts.Text or ""),
            Parent = row,
        })
        I.Bind(body, "TextColor3", "SubText")
        self:_init(row, { Name = opts.Title or opts.Name, Tooltip = opts.Tooltip, Width = opts.Width }, tab)
        self.TitleLabel = title
        self.BodyLabel = body
        return self
    end

    function Elements.Paragraph:Set(text)
        if self._destroyed then return end
        self.BodyLabel.Text = tostring(text or "")
    end
end
