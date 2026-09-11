return function(ctx)
    local I = ctx.Internal

    local function Corner(radius)
        return I.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
    end

    local function StrokeBind(thickness, key, transparency)
        local s = I.Create("UIStroke", {
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
        local holder = I.Create("Frame", {
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
            local f = I.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, s * 2, 1, s * 2),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = base,
                BorderSizePixel = 0,
                Parent = holder,
                Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, radius + s) }) },
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
        maid:Give(target.AncestryChanged:Connect(function()
            if target.Parent then
                holder.Parent = target.Parent
                sync()
            end
        end))
        maid:Give(function() holder:Destroy() end)
        maid:Give(target.Destroying:Connect(function() maid:Destroy() end))
        ctrl.Maid = maid
        sync()
        return ctrl
    end

    local function ShadowIn(shadow, alive, delay)
        if not shadow then return end
        shadow.SetFade(1)
        task.delay(delay or 0.1, function()
            if alive() and shadow then shadow.SetFade(0) end
        end)
    end

    I.Corner = Corner
    I.StrokeBind = StrokeBind
    I.AddHover = AddHover
    I.DropShadow = DropShadow
    I.ShadowIn = ShadowIn
end
