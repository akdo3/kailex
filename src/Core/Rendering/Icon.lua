return function(ctx)
    local I = ctx.Internal

    local Bars = {
        Minimize = { {10, 2, 0.5, 0.5} },
        Close    = { {11, 2, 0.5, 0.5, 45}, {11, 2, 0.5, 0.5, -45} },
        Chevron  = { {7, 2, 0.32, 0.55, 45}, {7, 2, 0.68, 0.55, -45} },
        Grip     = { {2, 5, 0.30, 0.72, 45}, {2, 7, 0.52, 0.52, 45}, {2, 9, 0.74, 0.32, 45} },
        Check    = { {6, 2, 0.34, 0.60, 45}, {9, 2, 0.64, 0.42, -45} },
        Alert    = { {2, 6, 0.5, 0.40}, {2, 2, 0.5, 0.76} },
        Info     = { {2, 2, 0.5, 0.24}, {2, 6, 0.5, 0.55} },
        Pin      = { {2, 6, 0.5, 0.76} },
        Search   = { {6, 2, 0.72, 0.72, 45} },
        Reset    = { {4, 2, 0.82, 0.16}, {3, 2, 0.68, 0.22, 90} },
    }

    local function part(holder, colorKey, w, h, pos, rot)
        local f = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(w, h),
            Position = pos,
            Rotation = rot or 0,
            BackgroundColor3 = I.CurrentTheme[colorKey],
            BorderSizePixel = 0,
            Parent = holder,
        })
        I.Bind(f, "BackgroundColor3", colorKey)
        return f
    end

    local function ring(holder, colorKey, sz, pos, corner, thick, filled, anchor)
        local f = I.Create("Frame", {
            AnchorPoint = anchor or Vector2.new(0.5, 0.5),
            Position = pos,
            Size = sz,
            BackgroundTransparency = filled and 0 or 1,
            BackgroundColor3 = filled and I.CurrentTheme[colorKey] or nil,
            BorderSizePixel = 0,
            Parent = holder,
            Children = { I.Create("UICorner", { CornerRadius = corner }) },
        })
        if filled then
            I.Bind(f, "BackgroundColor3", colorKey)
        else
            I.Bind(I.Create("UIStroke", { Thickness = thick or 1.6, Parent = f }), "Color", colorKey)
        end
        return f
    end

    local function IconRaw(kind, colorKey)
        colorKey = colorKey or "SubText"
        local holder = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(14, 14),
        })
        for _, b in ipairs(Bars[kind] or {}) do
            part(holder, colorKey, b[1], b[2], UDim2.fromScale(b[3], b[4]), b[5])
        end
        if kind == "Search" then
            ring(holder, colorKey, UDim2.fromOffset(8, 8), UDim2.fromOffset(1, 1), UDim.new(1, 0), 1.6, false, Vector2.zero)
        elseif kind == "Gear" then
            ring(holder, colorKey, UDim2.fromOffset(6, 6), UDim2.fromScale(0.5, 0.5), UDim.new(1, 0))
            for i = 0, 7 do
                local ang = i * 45
                part(holder, colorKey, 3, 2,
                    UDim2.new(0.5, math.cos(math.rad(ang)) * 5, 0.5, math.sin(math.rad(ang)) * 5), ang)
            end
        elseif kind == "Reset" then
            ring(holder, colorKey, UDim2.fromOffset(9, 9), UDim2.fromScale(0.5, 0.5), UDim.new(1, 0))
        elseif kind == "Pin" then
            ring(holder, colorKey, UDim2.fromOffset(7, 7), UDim2.new(0.5, 0, 0.34, 0), UDim.new(1, 0), nil, true)
        end
        return holder
    end

    local IconCache = {}

    local function Icon(parent, kind, colorKey, size)
        colorKey = colorKey or "SubText"
        local key = kind .. "\0" .. colorKey
        local proto = IconCache[key]
        if not proto then
            proto = IconRaw(kind, colorKey)
            IconCache[key] = proto
        end
        local holder = proto:Clone()
        holder.Parent = parent
        if size then
            holder.AnchorPoint = Vector2.new(0.5, 0.5)
            holder.Position = UDim2.fromScale(0.5, 0.5)
            holder.Size = UDim2.fromOffset(size, size)
        end
        for _, f in ipairs(holder:GetDescendants()) do
            if f:IsA("Frame") then
                I.Bind(f, "BackgroundColor3", colorKey)
            elseif f:IsA("UIStroke") then
                I.Bind(f, "Color", colorKey)
            end
        end
        return holder
    end

    I.Icon = Icon
end
