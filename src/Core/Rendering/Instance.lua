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

    local function AddHover(obj, opts)
        if I.Device.IsTouch then return end
        opts = opts or {}
        local baseT = opts.BaseTransparency
        if baseT == nil then baseT = obj.BackgroundTransparency end
        local hoverT = opts.HoverTransparency
        if hoverT == nil then hoverT = baseT end
        local hoverKey = opts.HoverKey or "ElementHover"
        local baseKey = opts.BaseKey or "Element"
        local stroke = obj:FindFirstChildOfClass("UIStroke")

        obj.MouseEnter:Connect(function()
            if obj:GetAttribute("NoHoverFX") or obj:GetAttribute("Disabled") then return end
            I.PlaySound("Hover", 0.12)
            I.Tween(obj, "HoverIn", { BackgroundColor3 = I.CurrentTheme[hoverKey], BackgroundTransparency = hoverT })
            if stroke and not opts.IgnoreStroke then
                I.Tween(stroke, "HoverIn", { Color = I.CurrentTheme.StrokeBright, Transparency = 0.25 })
            end
        end)

        obj.MouseLeave:Connect(function()
            I.Tween(obj, "HoverOut", { BackgroundColor3 = I.CurrentTheme[baseKey], BackgroundTransparency = baseT })
            if stroke and not opts.IgnoreStroke then
                I.Tween(stroke, "HoverOut", { Color = I.CurrentTheme.Stroke, Transparency = opts.StrokeTransparency or 0.6 })
            end
        end)
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
        local defs = { { 2, 0.92 }, { 5, 0.945 }, { 9, 0.962 }, { 14, 0.978 } }
        local layers = {}
        for i, def in ipairs(defs) do
            local s, base = def[1], def[2]
            local f = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, s * 2, 1, s * 2),
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
    I.AddHover = AddHover
    I.DropShadow = DropShadow
end
