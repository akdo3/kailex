return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting

    Elements.ProgressBar = I.MakeElementClass()

    function Elements.ProgressBar.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.ProgressBar)
        local barW = opts.BarWidth or 150
        local showText = opts.ShowText ~= false
        local rightW = barW + (showText and 36 or 0)
        local maxValue = tonumber(opts.Max) or 1

        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Progress", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
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

        local indeterminate = false
        local indTween

        local function setIndeterminate(on)
            indeterminate = on
            if indTween then pcall(function() indTween:Cancel() end) indTween = nil end
            if on then
                fill.Size = UDim2.fromScale(0.35, 1)
                indTween = I.Tween(fill, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromScale(0.05, 1) })
                if textLabel then textLabel.Text = "..." end
            else
                fill.Position = UDim2.fromScale(0, 0)
            end
        end

        function self:Set(val)
            if self._destroyed then return end
            if val == true or val == "indeterminate" then
                setIndeterminate(true)
                return
            elseif val == false then
                setIndeterminate(false)
                return
            end
            setIndeterminate(false)
            local n = tonumber(val) or 0
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
        function self:Get() return fill.Size.X.Scale * maxValue end
        function self:CopyValue() return tostring(math.floor(self:Get() + 0.5)) end

        if opts.Indeterminate then
            setIndeterminate(true)
        elseif opts.Value ~= nil then
            self:Set(opts.Value)
        end

        self:RecalcWidth()
        return self
    end
end
