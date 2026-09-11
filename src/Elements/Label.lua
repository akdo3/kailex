return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Label = I.MakeElementClass()

    function Elements.Label.new(tab, opts)
        if type(opts) == "string" then opts = { Text = opts } end
        opts = opts or {}
        local self = setmetatable({}, Elements.Label)
        local row = I.BareRow(tab.Content, opts.Width, 20)
        local label = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = opts.Text or opts.Name or "Label",
            Parent = row,
        })
        I.Bind(label, "TextColor3", "SubText")
        self:_init(row, { Name = opts.Text or opts.Name, Width = opts.Width }, tab)
        self.TextLabel = label
        return self
    end

    function Elements.Label:Set(text)
        if self._destroyed then return end
        self.TextLabel.Text = tostring(text or "")
        self:SetTitle(self.TextLabel.Text)
    end
end
