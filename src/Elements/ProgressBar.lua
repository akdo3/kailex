return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting

    Elements.ProgressBar = I.MakeElementClass()

    function Elements.ProgressBar.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.ProgressBar)
        local barW = 150
        local showText = opts.ShowText ~= false
        local rightW = barW + (showText and 36 or 0)
        local maxValue = tonumber(opts.Max) or 1

        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Progress", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self:_initRow(title, right, left, rightW)
        self.Callback = opts.Callback or nil

        local track = I.Create("Frame", {
            Size = UDim2.fromOffset(barW, 8),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Parent = right,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        I.Bind(track, "BackgroundColor3", "SurfaceLight")
        local fill = I.Create("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = track,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        I.Bind(fill, "BackgroundColor3", "Accent")
        local textLabel
        if showText then
            textLabel = I.Create("TextLabel", {
                Size = UDim2.fromOffset(32, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
                Text = "0%",
                LayoutOrder = 2,
                Parent = right,
            })
            I.Bind(textLabel, "TextColor3", "SubText")
        end

        local _value = 0

        function self:Set(val)
            if self._destroyed then return end
            local n = tonumber(val)
            if n == nil then return end
            _value = math.clamp(n, 0, maxValue)
            local frac = math.clamp(n / maxValue, 0, 1)
            I.Tween(fill, "Normal", { Size = UDim2.fromScale(frac, 1) })
            if textLabel then
                if type(opts.Format) == "function" then
                    textLabel.Text = tostring(opts.Format(n))
                else
                    textLabel.Text = tostring(math.floor(frac * 100 + 0.5)) .. "%"
                end
            end
            if self.Callback then I.RunCallback(self.Callback, self.Title, n) end
        end
        function self:Get() return _value end
        function self:CopyValue() return tostring(math.floor(self:Get() + 0.5)) end

        if opts.Value ~= nil then
            self:Set(opts.Value)
        end

        self:RecalcWidth()
        return self
    end
end
