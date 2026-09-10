return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local function IsInputDown(inputType)
        if inputType == Enum.UserInputType.Touch then
            local ok, touches = pcall(UserInputService.GetTouches, UserInputService)
            return ok and #touches > 0 or false
        end
        if inputType == Enum.UserInputType.MouseButton1
            or inputType == Enum.UserInputType.MouseButton2
            or inputType == Enum.UserInputType.MouseButton3 then
            return UserInputService:IsMouseButtonPressed(inputType)
        end
        return true
    end

    local function Once(signal, fn)
        if not signal then return end
        if signal.Once then return signal:Once(fn) end
        local conn
        conn = signal:Connect(function(...)
            if conn.Connected then conn:Disconnect() end
            fn(...)
        end)
        return conn
    end

    local function SafeCall(fn, ...)
        if type(fn) ~= "function" then return end
        local ok, err = pcall(fn, ...)
        if not ok then warn("[Kailex] " .. tostring(err)) end
    end

    local function Sanitize(text)
        local s = tostring(text or "")
        s = s:gsub('[%c/\\:"<>|*?]', "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then s = "Untitled" end
        return s
    end

    local function ColorToHex(c)
        return string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end

    local function HexToColor(hex)
        if type(hex) ~= "string" then return nil end
        local h = hex:gsub("#", "")
        if #h == 3 then
            h = h:sub(1,1):rep(2) .. h:sub(2,2):rep(2) .. h:sub(3,3):rep(2)
        end
        if #h ~= 6 then return nil end
        local r, g, b = tonumber(h:sub(1,2), 16), tonumber(h:sub(3,4), 16), tonumber(h:sub(5,6), 16)
        if r and g and b then return Color3.fromRGB(r, g, b) end
        return nil
    end

    local function RGBtoHSV(c)
        local r, g, b = c.R, c.G, c.B
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local v, d = max, max - min
        local s = (max == 0) and 0 or d / max
        local h
        if d == 0 then h = 0
        elseif max == r then h = ((g - b) / d) % 6
        elseif max == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        return h / 6, s, v
    end

    I.IsInputDown = IsInputDown
    I.Once = Once
    I.SafeCall = SafeCall
    I.Sanitize = Sanitize
    I.ColorToHex = ColorToHex
    I.HexToColor = HexToColor
    I.RGBtoHSV = RGBtoHSV
end
