return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    local function num(key, lo, hi, apply)
        local v = I.SaveManager:Get(key, nil)
        if type(v) == "number" then apply(math.clamp(v, lo, hi)) end
    end

    local function bool(key, apply)
        local v = I.SaveManager:Get(key, nil)
        if v ~= nil then apply(v == true) end
    end

    I.ApplyPersisted = function()
        I.LoadCustomThemes()
        local t = I.SaveManager:Get("__theme", nil)
        if t and I.Themes[t] then
            I.Setting.Theme = t
            I.ApplyTheme(I.Themes[t])
        end
        bool("__sounds", function(v) I.Setting.Sounds = v end)
        num("__volume", 0, 1, function(v)
            if Kailex.Audio then Kailex.Audio.Master = v end
        end)
        num("__scale", 0.8, 1.3, function(v)
            if v ~= I.Setting.UIScale then
                I.Setting.UIScale = v
                I.UpdateViewport()
            end
        end)
        num("__textScale", 0.85, 1.4, function(v)
            I.Setting.TextScale = v
            I.ApplyTextScale()
        end)
        num("__motion", 0.2, 1, function(v) I.Setting.MotionScale = v end)
        bool("__effects", function(v) I.Setting.Effects = v end)
        bool("__rtl", function(v) I.Setting.RTL = v end)
        bool("__async", function(v) I.Setting.AsyncCallbacks = v end)
        local tk = I.SaveManager:Get("__toggleKey", nil)
        if tk ~= nil then
            I.Setting.ToggleUIKey = I.ParseKey(tk)
        end
    end
end
