return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local RGB = function(r, g, b) return Color3.fromRGB(r, g, b) end

    local Themes = {
        Nocturne = {
            Background = RGB(13,15,20),   Surface = RGB(19,22,30),    SurfaceLight = RGB(26,30,40),
            Element = RGB(28,32,43),      ElementHover = RGB(36,41,55),
            Stroke = RGB(43,49,66),       StrokeBright = RGB(64,73,97),
            Text = RGB(232,236,246),      SubText = RGB(142,152,175),
            Accent = RGB(122,162,247),    AccentHover = RGB(150,183,250), OnAccent = RGB(10,14,24),
            Success = RGB(158,206,106),   Warning = RGB(224,175,104), Error = RGB(247,118,142),
            TabBar = RGB(17,19,26),
        },
        Aurora = {
            Background = RGB(12,16,17),   Surface = RGB(17,23,24),    SurfaceLight = RGB(23,31,32),
            Element = RGB(25,34,35),      ElementHover = RGB(33,44,46),
            Stroke = RGB(38,52,54),       StrokeBright = RGB(58,78,81),
            Text = RGB(230,240,238),      SubText = RGB(138,158,155),
            Accent = RGB(94,210,190),     AccentHover = RGB(124,224,206), OnAccent = RGB(8,20,18),
            Success = RGB(158,206,106),   Warning = RGB(224,175,104), Error = RGB(247,118,142),
            TabBar = RGB(14,19,20),
        },
        Sakura = {
            Background = RGB(18,14,18),   Surface = RGB(25,19,24),    SurfaceLight = RGB(33,25,31),
            Element = RGB(36,27,34),      ElementHover = RGB(46,35,43),
            Stroke = RGB(54,41,50),       StrokeBright = RGB(80,61,74),
            Text = RGB(244,236,242),      SubText = RGB(168,150,162),
            Accent = RGB(240,146,196),    AccentHover = RGB(246,169,211), OnAccent = RGB(26,12,20),
            Success = RGB(158,206,106),   Warning = RGB(224,175,104), Error = RGB(247,118,142),
            TabBar = RGB(21,16,20),
        },
        Daylight = {
            Background = RGB(244,246,250), Surface = RGB(255,255,255), SurfaceLight = RGB(236,240,247),
            Element = RGB(239,243,249),    ElementHover = RGB(226,233,244),
            Stroke = RGB(210,218,232),     StrokeBright = RGB(178,190,212),
            Text = RGB(28,34,48),          SubText = RGB(106,116,138),
            Accent = RGB(66,113,244),      AccentHover = RGB(90,132,247), OnAccent = RGB(255,255,255),
            Success = RGB(72,163,87),      Warning = RGB(196,142,30),  Error = RGB(219,68,94),
            TabBar = RGB(240,242,247),
        },
        Obsidian = {
            Background = RGB(8,8,10),     Surface = RGB(12,12,15),    SurfaceLight = RGB(17,17,21),
            Element = RGB(20,20,25),      ElementHover = RGB(27,27,34),
            Stroke = RGB(32,32,40),       StrokeBright = RGB(50,50,62),
            Text = RGB(228,230,238),      SubText = RGB(136,140,158),
            Accent = RGB(124,170,255),    AccentHover = RGB(152,190,255), OnAccent = RGB(8,10,16),
            Success = RGB(158,206,106),   Warning = RGB(224,175,104), Error = RGB(247,118,142),
            TabBar = RGB(10,10,12),
        },
        Ember = {
            Background = RGB(20,14,11),   Surface = RGB(27,19,15),    SurfaceLight = RGB(36,25,19),
            Element = RGB(42,29,22),      ElementHover = RGB(54,38,29),
            Stroke = RGB(62,44,33),       StrokeBright = RGB(94,67,50),
            Text = RGB(245,236,229),      SubText = RGB(171,150,136),
            Accent = RGB(255,149,94),     AccentHover = RGB(255,168,117), OnAccent = RGB(28,13,6),
            Success = RGB(158,206,106),   Warning = RGB(235,187,120), Error = RGB(247,118,142),
            TabBar = RGB(23,16,13),
        },
    }

    local ThemeKeys = {
        "Background","Surface","SurfaceLight","Element","ElementHover","Stroke","StrokeBright",
        "Text","SubText","Accent","AccentHover","OnAccent","Success","Warning","Error","TabBar",
    }

    I.CurrentTheme = Themes.Nocturne
    local ThemeBindings = setmetatable({}, { __mode = "k" })

    local function Bind(inst, prop, key)
        if not inst then return inst end
        local b = ThemeBindings[inst]
        if not b then b = {} ThemeBindings[inst] = b end
        b[prop] = key
        local v = I.CurrentTheme[key]
        if v ~= nil then inst[prop] = v end
        return inst
    end

    local PendingTheme, ThemeQueued = nil, false
    local function ApplyTheme(theme)
        if type(theme) == "string" then theme = Themes[theme] or I.CurrentTheme end
        PendingTheme = theme
        if ThemeQueued then return end
        ThemeQueued = true
        task.defer(function()
            ThemeQueued = false
            local t = PendingTheme
            if t then
                I.CurrentTheme = t
                for inst, binds in pairs(ThemeBindings) do
                    for prop, key in pairs(binds) do
                        local v = t[key]
                        if v ~= nil then inst[prop] = v end
                    end
                end
                Kailex.ThemeChanged:Fire(t)
            end
        end)
    end

    function Kailex:GetThemes()
        local t = {}
        for k in pairs(Themes) do table.insert(t, k) end
        table.sort(t)
        return t
    end

    function Kailex:SetTheme(theme)
        ApplyTheme(theme)
    end

    I.Themes = Themes
    I.ThemeKeys = ThemeKeys
    I.Bind = Bind
    I.ApplyTheme = ApplyTheme
end
