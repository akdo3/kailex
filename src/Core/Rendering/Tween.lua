return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting
    local TweenService = I.TweenService

    local E, ED = Enum.EasingStyle, Enum.EasingDirection
    local Tweens = {
        Instant  = TweenInfo.new(0.05, E.Quad , ED.Out),
        Fast     = TweenInfo.new(0.12, E.Quint, ED.Out),
        Snappy   = TweenInfo.new(0.16, E.Quart, ED.Out),
        Normal   = TweenInfo.new(0.24, E.Quint, ED.Out),
        Smooth   = TweenInfo.new(0.35, E.Quart, ED.Out),
        Reveal   = TweenInfo.new(0.30, E.Quint, ED.Out),
        HoverIn  = TweenInfo.new(0.14, E.Quint, ED.Out),
        HoverOut = TweenInfo.new(0.20, E.Sine , ED.Out),
        Spring   = TweenInfo.new(0.34, E.Back , ED.Out),
        SpringBig= TweenInfo.new(0.45, E.Back , ED.Out),
        Collapse = TweenInfo.new(0.28, E.Back , ED.In ),
        Ripple   = TweenInfo.new(0.45, E.Quint, ED.Out),
        Pop      = TweenInfo.new(0.26, E.Back , ED.Out),
        PopSoft  = TweenInfo.new(0.20, E.Back , ED.Out),
        Vanish   = TweenInfo.new(0.15, E.Quad , ED.In ),
    }
    setmetatable(Tweens, { __index = function() return Tweens.Normal end })

    local ActiveTweens = setmetatable({}, { __mode = "k" })

    local function ScaledInfo(info)
        local m = tonumber(Setting.MotionScale) or 1
        if m == 1 then return info end
        local t = info.Time * m
        if t < 0.02 then t = 0.02 end
        return TweenInfo.new(t, info.EasingStyle, info.EasingDirection, info.RepeatCount, info.Reverses, info.DelayTime)
    end

    local function Tween(inst, preset, props, done)
        if not inst or not inst.Parent then return nil end
        if type(props) ~= "table" then return nil end
        local info = Tweens[preset]
        if typeof(preset) == "TweenInfo" then info = preset end
        info = ScaledInfo(info)

        local book = ActiveTweens[inst]
        if not book then book = {} ActiveTweens[inst] = book end
        for prop in pairs(props) do
            local prev = book[prop]
            if prev then pcall(prev.Cancel, prev) book[prop] = nil end
        end

        local ok, tween = pcall(TweenService.Create, TweenService, inst, info, props)
        if not ok then
            warn("[Kailex] tween failed: " .. tostring(inst))
            return nil
        end
        for prop in pairs(props) do book[prop] = tween end

        if done then
            I.Once(tween.Completed, function(state)
                if state == Enum.PlaybackState.Completed then I.SafeCall(done) end
            end)
        end
        I.Once(tween.Completed, function()
            local b = ActiveTweens[inst]
            if b then
                for prop in pairs(props) do
                    if b[prop] == tween then b[prop] = nil end
                end
            end
        end)

        tween:Play()
        return tween
    end

    I.Tween = Tween
    I.Tweens = Tweens
end
