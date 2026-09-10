return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local TextRegistry = setmetatable({}, { __mode = "k" })
    local TextBaseSize = setmetatable({}, { __mode = "k" })

    local function TS(n)
        return math.floor(n * (tonumber(Setting.TextScale) or 1) + 0.5)
    end

    local TextScaleQueued = false
    local function ApplyTextScale()
        if TextScaleQueued then return end
        TextScaleQueued = true
        task.defer(function()
            TextScaleQueued = false
            for inst in pairs(TextRegistry) do
                local base = TextBaseSize[inst]
                if base then
                    pcall(function() inst.TextSize = TS(base) end)
                end
            end
        end)
    end

    local function SetProps(inst, props)
        for prop, value in pairs(props) do
            inst[prop] = value
        end
    end

    local function Create(className, props)
        props = props or {}
        local inst = Instance.new(className)
        local parent = props.Parent
        local children = props.Children
        if parent then props.Parent = nil end
        if children then props.Children = nil end
        if (className == "TextLabel" or className == "TextButton" or className == "TextBox")
            and type(props.TextSize) == "number" then
            TextBaseSize[inst] = props.TextSize
            TextRegistry[inst] = true
            props.TextSize = TS(props.TextSize)
        end
        local ok, err = pcall(SetProps, inst, props)
        if not ok then
            warn("[Kailex] property error (" .. className .. "): " .. tostring(err))
            for prop, value in pairs(props) do
                pcall(function() inst[prop] = value end)
            end
        end
        if children then
            for _, child in ipairs(children) do child.Parent = inst end
        end
        if parent then inst.Parent = parent end
        return inst
    end

    local function Corner(radius)
        return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
    end

    local function StrokeBind(thickness, key, transparency)
        local s = Create("UIStroke", {
            Thickness = thickness or 1,
            Transparency = transparency or 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        I.Bind(s, "Color", key or "Stroke")
        return s
    end

    local function Icon(parent, kind, colorKey)
        colorKey = colorKey or "SubText"
        local holder = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(14, 14),
            Parent = parent,
        })
        local function bar(w, h, x, y, rot)
            local f = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(w, h),
                Position = UDim2.fromScale(x, y),
                Rotation = rot or 0,
                BackgroundColor3 = I.CurrentTheme[colorKey],
                BorderSizePixel = 0,
                Parent = holder,
            })
            I.Bind(f, "BackgroundColor3", colorKey)
        end
        if kind == "Minimize" then
            bar(10, 2, 0.5, 0.5)
        elseif kind == "Close" then
            bar(11, 2, 0.5, 0.5, 45)
            bar(11, 2, 0.5, 0.5, -45)
        elseif kind == "Chevron" then
            bar(7, 2, 0.32, 0.55, 45)
            bar(7, 2, 0.68, 0.55, -45)
        elseif kind == "Search" then
            local ring = Create("Frame", {
                Size = UDim2.fromOffset(8, 8),
                Position = UDim2.fromOffset(1, 1),
                BackgroundTransparency = 1,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
            })
            I.Bind(Create("UIStroke", { Thickness = 1.6, Parent = ring }), "Color", colorKey)
            bar(6, 2, 0.72, 0.72, 45)
        elseif kind == "Grip" then
            bar(2, 5, 0.30, 0.72, 45)
            bar(2, 7, 0.52, 0.52, 45)
            bar(2, 9, 0.74, 0.32, 45)
        elseif kind == "Gear" then
            local ring = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(6, 6),
                BackgroundTransparency = 1,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
            })
            I.Bind(Create("UIStroke", { Thickness = 1.6, Parent = ring }), "Color", colorKey)
            for i = 0, 7 do
                local ang = i * 45
                local f = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, math.cos(math.rad(ang)) * 5, 0.5, math.sin(math.rad(ang)) * 5),
                    Size = UDim2.fromOffset(3, 2),
                    Rotation = ang,
                    BackgroundColor3 = I.CurrentTheme[colorKey],
                    BorderSizePixel = 0,
                    Parent = holder,
                })
                I.Bind(f, "BackgroundColor3", colorKey)
            end
        elseif kind == "Check" then
            bar(6, 2, 0.34, 0.60, 45)
            bar(9, 2, 0.64, 0.42, -45)
        elseif kind == "Reset" then
            local ring = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(9, 9),
                BackgroundTransparency = 1,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
            })
            I.Bind(Create("UIStroke", { Thickness = 1.6, Parent = ring }), "Color", colorKey)
            bar(4, 2, 0.82, 0.16, 0)
            bar(3, 2, 0.68, 0.22, 90)
        elseif kind == "ResizeH" then
            bar(6, 2, 0.24, 0.40, -45)
            bar(6, 2, 0.24, 0.60, 45)
            bar(11, 2, 0.5, 0.5, 0)
            bar(6, 2, 0.76, 0.40, 45)
            bar(6, 2, 0.76, 0.60, -45)
        elseif kind == "Pin" then
            local ring = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.34),
                Size = UDim2.fromOffset(7, 7),
                BackgroundColor3 = I.CurrentTheme[colorKey],
                BorderSizePixel = 0,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
            })
            I.Bind(ring, "BackgroundColor3", colorKey)
            bar(2, 6, 0.5, 0.76)
        elseif kind == "Maximize" then
            local sq = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(9, 9),
                BackgroundTransparency = 1,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) },
            })
            I.Bind(Create("UIStroke", { Thickness = 1.6, Parent = sq }), "Color", colorKey)
        elseif kind == "Restore" then
            local back = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, -2, 0.5, -2),
                Size = UDim2.fromOffset(7, 7),
                BackgroundTransparency = 1,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(0, 1) }) },
            })
            I.Bind(Create("UIStroke", { Thickness = 1.4, Parent = back }), "Color", colorKey)
            local front = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 2, 0.5, 2),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = I.CurrentTheme[colorKey],
                BorderSizePixel = 0,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(0, 1) }) },
            })
            I.Bind(front, "BackgroundColor3", colorKey)
        elseif kind == "Alert" then
            bar(2, 6, 0.5, 0.40)
            bar(2, 2, 0.5, 0.76)
        elseif kind == "Info" then
            bar(2, 2, 0.5, 0.24)
            bar(2, 6, 0.5, 0.55)
        end
        return holder
    end

    local function AddHover(obj, opts)
        if I.Device.IsTouch then return end
        opts = opts or {}
        local baseT = opts.BaseTransparency
        if baseT == nil then baseT = obj.BackgroundTransparency end
        local hoverT = opts.HoverTransparency
        if hoverT == nil then hoverT = baseT end
        local hoverKey = opts.HoverKey or "ElementHover"
        local baseKey  = opts.BaseKey or "Element"

        obj.MouseEnter:Connect(function()
            if obj:GetAttribute("NoHoverFX") or obj:GetAttribute("Disabled") then return end
            I.PlaySound("Hover", 0.12)
            I.Tween(obj, "HoverIn", { BackgroundColor3 = I.CurrentTheme[hoverKey], BackgroundTransparency = hoverT })
            local stroke = obj:FindFirstChildOfClass("UIStroke")
            if stroke and not opts.IgnoreStroke then
                I.Tween(stroke, "HoverIn", { Color = I.CurrentTheme.StrokeBright, Transparency = 0.25 })
            end
        end)

        obj.MouseLeave:Connect(function()
            I.Tween(obj, "HoverOut", { BackgroundColor3 = I.CurrentTheme[baseKey], BackgroundTransparency = baseT })
            local stroke = obj:FindFirstChildOfClass("UIStroke")
            if stroke and not opts.IgnoreStroke then
                I.Tween(stroke, "HoverOut", { Color = I.CurrentTheme.Stroke, Transparency = opts.StrokeTransparency or 0.6 })
            end
        end)
    end

    local function AddPress(hit, target)
        target = target or hit
        if not hit or not target then return nil end
        if target:FindFirstChildOfClass("UIScale") then return nil end
        local scale = Create("UIScale", { Scale = 1, Parent = target })
        local down = false
        local function release()
            if not down then return end
            down = false
            I.Tween(scale, "PopSoft", { Scale = 1 })
        end
        hit.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if target:GetAttribute("Disabled") then return end
            down = true
            scale.Scale = 0.97
        end)
        hit.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                release()
            end
        end)
        hit.MouseLeave:Connect(release)
        return scale
    end

    local function DropShadow(target, opts)
        opts = opts or {}
        if not target or not target.Parent then return nil end
        local parent = target.Parent
        local holder = Create("Frame", {
            Name = "__KailexShadow",
            BackgroundTransparency = 1,
            AnchorPoint = target.AnchorPoint,
            ZIndex = math.max(0, (target.ZIndex or 1) - 1),
            Visible = target.Visible,
            Parent = parent,
        })
        local radius = opts.Radius or 12
        local spreads = opts.Spreads or { 2, 5, 9 }
        local dropY = opts.DropY or 3
        local layers = {}
        for i = 1, #spreads do
            local s = spreads[i]
            local base = ({ 0.92, 0.945, 0.965 })[i] or 0.965
            local f = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, dropY),
                Size = UDim2.new(1, s * 2, 1, s * 2 + dropY),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = base,
                BorderSizePixel = 0,
                Parent = holder,
                Children = { Create("UICorner", { CornerRadius = UDim.new(0, radius + s) }) },
            })
            layers[i] = { Frame = f, Base = base }
        end

        local ctrl = {}
        local function sync()
            if not target.Parent then return end
            holder.Position = target.Position
            holder.Size = target.Size
            holder.ZIndex = math.max(0, (target.ZIndex or 1) - 1)
        end
        function ctrl.SetFade(a)
            a = a or 0
            for _, l in ipairs(layers) do
                l.Frame.BackgroundTransparency = math.min(1, l.Base + (1 - l.Base) * a)
            end
        end
        function ctrl.FadeOut()
            for _, l in ipairs(layers) do
                I.Tween(l.Frame, "Vanish", { BackgroundTransparency = 1 })
            end
        end
        function ctrl.Destroy()
            holder:Destroy()
        end
        ctrl.Holder = holder

        local maid = I.Maid.new()
        maid:Give(target:GetPropertyChangedSignal("Position"):Connect(sync))
        maid:Give(target:GetPropertyChangedSignal("Size"):Connect(sync))
        maid:Give(target:GetPropertyChangedSignal("ZIndex"):Connect(sync))
        maid:Give(target:GetPropertyChangedSignal("Visible"):Connect(function()
            holder.Visible = target.Visible
        end))
        maid:Give(target:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
            holder.AnchorPoint = target.AnchorPoint
            sync()
        end))
        maid:Give(function() holder:Destroy() end)
        maid:Give(target.Destroying:Connect(function() maid:Destroy() end))
        ctrl.Maid = maid
        sync()
        return ctrl
    end

    I.TS = TS
    I.ApplyTextScale = ApplyTextScale
    I.Create = Create
    I.Corner = Corner
    I.StrokeBind = StrokeBind
    I.Icon = Icon
    I.AddHover = AddHover
    I.AddPress = AddPress
    I.DropShadow = DropShadow
end
