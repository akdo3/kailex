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

    I.TS = TS
    I.ApplyTextScale = ApplyTextScale
    I.Create = Create
end
