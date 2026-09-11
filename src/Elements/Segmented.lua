return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Elements = I.Elements

    Elements.Segmented = I.MakeElementClass()

    function Elements.Segmented.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Segmented)
        local saveKey = tab:GetSaveKey(opts)

        local options = I.NormalizeOptions(opts.Options)
        local itemW = opts.ItemWidth or 48
        local rightW = math.clamp(#options * (itemW + 4), 60, 200)
        local selected = nil

        local function findOpt(v)
            for _, o in ipairs(options) do
                if o.Value == v or tostring(o.Value) == tostring(v) then
                    return o
                end
            end
        end

        local _, _, right = I.MkRow(self, tab, opts, "Segmented", rightW)
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
        local indicator = I.Create("Frame", {
            Size = UDim2.fromOffset(itemW, 26),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = holder,
            Children = { I.Corner(8) },
        })
        I.Bind(indicator, "BackgroundColor3", "Accent")
        local function paint(instant)
            local idx = selected and table.find(options, selected) or nil
            for i, b in ipairs(buttons) do
                b.BackgroundTransparency = 1
                b.TextColor3 = (i == idx) and I.CurrentTheme.OnAccent or I.CurrentTheme.SubText
            end
            if idx then
                indicator.BackgroundTransparency = 0
                local target = UDim2.fromOffset((idx - 1) * (itemW + 4), 0)
                if instant then
                    indicator.Position = target
                else
                    I.Tween(indicator, "Snappy", { Position = target })
                end
            else
                indicator.BackgroundTransparency = 1
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
            I.AddHover(b, { BaseTransparency = 1, HoverTransparency = 0.8, IgnoreStroke = true })
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
            selected = findOpt((sv ~= nil) and sv or opts.Default)
        end

        paint(true)
        self.Maid:Give(Kailex.ThemeChanged:Connect(function() paint(true) end))

        function self:Set(v, silent)
            if self._destroyed then return end
            local o = findOpt(v)
            if o and selected ~= o then
                selected = o
                paint()
                I.SaveValue(saveKey, o.Value)
                if not silent then I.RunCallback(self.Callback, self.Title, o.Value) end
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
        self:_initialCallback(selected ~= nil, selected and selected.Value)

        self:RecalcWidth()
        return self
    end
end
