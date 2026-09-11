return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting
    local SoundService = I.SoundService

    local Audio = {
        Hover    = { Id = "rbxasset://sounds/electronicpingshort.wav", Speed = 1.85, Vol = 0.05 },
        Click    = { Id = "rbxasset://sounds/snap.mp3",                Speed = 1.25, Vol = 0.45 },
        ToggleOn = { Id = "rbxasset://sounds/electronicpingshort.wav", Speed = 1.15, Vol = 0.35 },
        ToggleOff= { Id = "rbxasset://sounds/electronicpingshort.wav", Speed = 0.82, Vol = 0.32 },
        Slider   = { Id = "rbxasset://sounds/snap.mp3",                Speed = 1.55, Vol = 0.25 },
        Error    = { Id = "rbxasset://sounds/snap.mp3",                Speed = 0.55, Vol = 0.55 },
        Master   = 1,
    }
    Kailex.Audio = Audio

    local SoundPool = {}
    local SoundInstances = {}

    local LastPlayed = {}
    local THROTTLE = 0.08
    local KindThrottle = { Slider = 0.06, Click = 0.05 }

    local function PlaySound(kind, scale)
        if not Setting.Sounds then return end
        local a = Audio[kind]
        if type(a) ~= "table" or a.Id == "" then return end
        local gap = KindThrottle[kind]
            or ((a.Vol or 0.4) <= 0.08 and THROTTLE or 0)

        if gap > 0 then
            local now = os.clock()
            if LastPlayed[kind] and now - LastPlayed[kind] < gap then return end
            LastPlayed[kind] = now
        end

        pcall(function()
            local pool = SoundPool[a.Id]
            if not pool then pool = {} SoundPool[a.Id] = pool end
            local s
            for i = 1, #pool do
                local c = pool[i]
                if not c.IsPlaying then s = table.remove(pool, i) break end
            end
            if not s then
                s = Instance.new("Sound")
                s.Parent = SoundService
                table.insert(SoundInstances, s)
                s.Ended:Connect(function()
                    task.defer(function()
                        if s.Parent ~= SoundService then return end
                        if #pool < 8 then
                            if not table.find(pool, s) then table.insert(pool, s) end
                        else
                            s:Destroy()
                            local idx = table.find(SoundInstances, s)
                            if idx then table.remove(SoundInstances, idx) end
                        end
                    end)
                end)
            end
            s.SoundId = a.Id
            s.PlaybackSpeed = a.Speed or 1
            s.Volume = math.clamp((a.Vol or 0.4) * (scale or 1) * (Audio.Master or 1), 0, 1)
            s.TimePosition = 0
            s:Play()
        end)
    end

    I.LibMaid:Give(function()
        for _, s in ipairs(SoundInstances) do
            pcall(function() s:Destroy() end)
        end
        table.clear(SoundInstances)
        for k in pairs(SoundPool) do SoundPool[k] = nil end
    end)

    I.Audio = Audio
    I.PlaySound = PlaySound
    I.SoundInstances = SoundInstances
    I.SoundPool = SoundPool
end
