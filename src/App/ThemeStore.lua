return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    local function SerializeTheme(t)
        local out = {}
        for _, k in ipairs(I.ThemeKeys) do out[k] = I.ColorToHex(t[k]) end
        return out
    end

    function Kailex:RegisterTheme(name, colors)
        name = tostring(name or "")
        if name == "" then return nil end
        local t = table.clone(I.Themes[name] or I.Themes.Nocturne)
        for _, k in ipairs(I.ThemeKeys) do
            local c = colors and colors[k]
            if typeof(c) == "Color3" then
                t[k] = c
            elseif type(c) == "string" then
                local h = I.HexToColor(c)
                if h then t[k] = h end
            end
        end
        I.Themes[name] = t
        return t
    end

    function Kailex:RemoveTheme(name)
        name = tostring(name)
        if I.Themes[name] then
            I.Themes[name] = nil
            if I.Setting.Theme == name then
                I.Setting.Theme = "Nocturne"
                I.ApplyTheme(I.Themes.Nocturne)
            end
        end
    end

    function Kailex:SaveCustomThemes()
        local store = {}
        local Builtin = {
            Nocturne = true, Aurora = true, Sakura = true,
            Daylight = true, Obsidian = true, Ember = true,
        }
        for name, t in pairs(I.Themes) do
            if not Builtin[name] then store[name] = SerializeTheme(t) end
        end
        I.SaveManager:Set("__customThemes", store)
    end

    I.LoadCustomThemes = function()
        local store = I.SaveManager:Get("__customThemes", nil)
        if type(store) ~= "table" then return end
        for name, cols in pairs(store) do
            if type(cols) == "table" then Kailex:RegisterTheme(name, cols) end
        end
    end
end
