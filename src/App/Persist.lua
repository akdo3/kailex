return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    I.ApplyPersisted = function()
        I.LoadCustomThemes()
        local t = I.SaveManager:Get("__theme", nil)
        if t and I.Themes[t] then
            I.Setting.Theme = t
            I.ApplyTheme(I.Themes[t])
        end
        local snd = I.SaveManager:Get("__sounds", nil)
        if snd ~= nil then I.Setting.Sounds = (snd == true) end
        local sc = I.SaveManager:Get("__scale", nil)
        if type(sc) == "number" then
            local ns = math.clamp(sc, 0.75, 1.5)
            if ns ~= I.Setting.UIScale then
                I.Setting.UIScale = ns
                I.UpdateViewport()
            end
        end
        local txs = I.SaveManager:Get("__textScale", nil)
        if type(txs) == "number" then
            I.Setting.TextScale = math.clamp(txs, 0.75, 1.6)
            I.ApplyTextScale()
        end
        local mot = I.SaveManager:Get("__motion", nil)
        if type(mot) == "number" then
            I.Setting.MotionScale = math.clamp(mot, 0.1, 1)
        end
        local eff = I.SaveManager:Get("__effects", nil)
        if eff ~= nil then I.Setting.Effects = (eff == true) end
        local rtl = I.SaveManager:Get("__rtl", nil)
        if rtl ~= nil then I.Setting.RTL = (rtl == true) end
        local asc = I.SaveManager:Get("__async", nil)
        if asc ~= nil then I.Setting.AsyncCallbacks = (asc == true) end
        local tk = I.SaveManager:Get("__toggleKey", nil)
        if tk ~= nil then
            I.Setting.ToggleUIKey = I.ParseKey(tk)
        end
    end
end
