return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Segmented = I.MakeElementClass()

    function Elements.Segmented.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Segmented)
        local saveKey = tab:GetSaveKey(opts)

        local options = {}
        for _, v in ipairs(opts.Options or {}) do
            if type(v) == "table" and v.Text ~= nil then
                options[#options + 1] = { Text = tostring(v.Text), Value = (v.Value ~= nil) and v.Value or v.Text }
            else
                options[#options + 1] = { Text = tostring(v), Value = v }
            end
        end
        local itemW = opts.ItemWidth or 56
        local rightW = math.clamp(#options * (itemW + 4), 60, 280)
        local selected = nil

        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Segmented", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
        self.Callback = opts.Callback or function() end

        local holder = I.Create("Frame", {
            Size = UDim2.new(1, 0, 1, -4),
            BackgroundTransparency = 1,
            Parent = right,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })

        local buttons = {}
        local function paint()
            for i, b in ipairs(buttons) do
                local sel = options[i] == selected
                b.BackgroundColor3 = sel and I.CurrentTheme.Accent or I.CurrentTheme.Element
                b.TextColor3 = sel and I.CurrentTheme.OnAccent or I.CurrentTheme.SubText
            end
        end

        for i, opt in ipairs(options) do
            local b = I.Create("TextButton", {
                Size = UDim2.fromOffset(itemW, 26),
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = opt.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = holder,
                Children = { I.Corner(8) },
            })
            I.Bind(b, "BackgroundColor3", "Element")
            I.Bind(b, "TextColor3", "SubText")
            I.AddHover(b)
            I.AddPress(b)
            buttons[i] = b
            b.MouseButton1Click:Connect(function()
                if self._disabled then return end
                I.ApplyRipple(b)
                I.PlaySound("Click", 0.7)
                if selected ~= opt then
                    selected = opt
                    paint()
                    I.SaveValue(saveKey, opt.Value)
                    I.RunCallback(self.Callback, self.Title, opt.Value)
                end
            end)
        end

        do
            local sv = I.SaveManager:Get(saveKey, nil)
            local d = (sv ~= nil) and sv or opts.Default
            if d ~= nil then
                for _, o in ipairs(options) do
                    if o.Value == d or tostring(o.Value) == tostring(d) then
                        selected = o
                        break
                    end
                end
            end
        end
        paint()

        function self:Set(v, silent)
            if self._destroyed then return end
            for _, o in ipairs(options) do
                if o.Value == v or tostring(o.Value) == tostring(v) then
                    if selected ~= o then
                        selected = o
                        paint()
                        I.SaveValue(saveKey, o.Value)
                        if not silent then I.RunCallback(self.Callback, self.Title, o.Value) end
                    end
                    return
                end
            end
        end
        function self:Get() return selected and selected.Value or nil end
        function self:CopyValue() return selected and tostring(selected.Value) or nil end
        function self:Reset()
            if self._destroyed then return end
            if opts.Default ~= nil then
                self:Set(opts.Default, false)
            elseif selected then
                selected = nil
                paint()
                I.SaveValue(saveKey, nil)
                I.RunCallback(self.Callback, self.Title, nil)
            end
        end

        self:_bindSaveReload(saveKey, function(v)
            self:Set(v, true)
        end)
        if selected then
            task.defer(function()
                if not self._destroyed then I.RunCallback(self.Callback, self.Title, selected.Value) end
            end)
        end

        self:RecalcWidth()
        return self
    end
end
