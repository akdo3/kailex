return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local function IsInputDown(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.Touch then
            local st = inp.UserInputState
            return st == Enum.UserInputState.Begin or st == Enum.UserInputState.Change
        end
        if t == Enum.UserInputType.MouseButton1
            or t == Enum.UserInputType.MouseButton2
            or t == Enum.UserInputType.MouseButton3 then
            return UserInputService:IsMouseButtonPressed(t)
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
        s = s:sub(1, 64)
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

    local function RemoveFrom(list, item)
        local idx = table.find(list, item)
        if idx then table.remove(list, idx) end
    end

    local function Trim(s)
        return tostring(s):match("^%s*(.-)%s*$")
    end

    local function SetBoxDisabled(boxes, state)
        local v = state == true
        for _, b in ipairs(boxes) do
            b.TextEditable = not v
            b.Active = not v
            if v then pcall(function() b:ReleaseFocus() end) end
        end
    end

    local function RGBtoHSV(c)
        return c:ToHSV()
    end

    local function IsAssetId(v)
        local raw = tostring(v)
        return tonumber(v) ~= nil
            or raw:sub(1, 10) == "rbxassetid" or raw:sub(1, 11) == "rbxasset://"
    end

    local function NormalizeOptions(list)
        local out = {}
        for _, v in ipairs(list or {}) do
            if type(v) == "table" and v.Text ~= nil then
                local val = (v.Value ~= nil) and v.Value or v.Text
                out[#out + 1] = { Text = tostring(v.Text), Value = val, Key = tostring(val) }
            else
                out[#out + 1] = { Text = tostring(v), Value = v, Key = tostring(v) }
            end
        end
        return out
    end

    local function NumSpec(opts, dMin, dMax, dStep)
        local min = tonumber(opts.Min or opts.MinVal or dMin) or dMin
        local max = tonumber(opts.Max or opts.MaxVal or dMax) or dMax
        if max <= min then max = min + 1 end
        local step = tonumber(opts.Step or opts.Increment)
        if not (step and step > 0) then
            step = dStep or ((min % 1 == 0 and max % 1 == 0) and 1 or 0.01)
        end
        local decimals = step >= 1 and 0 or math.clamp(math.ceil(-math.log10(step)), 1, 3)
        local pow = 10 ^ decimals
        local function snap(v)
            v = math.floor((v - min) / step + 0.5) * step + min
            v = math.clamp(math.floor(v * pow + 0.5) / pow, min, max)
            if decimals <= 0 then v = math.floor(v + 0.5) end
            return v
        end
        return min, max, step, decimals, snap
    end

    local function ReadClipboard()
        local ok, fn = pcall(function() return getclipboard end)
        if ok and type(fn) == "function" then
            local okRead, txt = pcall(fn)
            if okRead and type(txt) == "string" then return txt end
        end
        return nil
    end

    local function GetClipboardSetter()
        local ok, sc = pcall(function() return setclipboard or toclipboard or setrbxclipboard end)
        if ok and type(sc) == "function" then return sc end
        return nil
    end

    local function OnLongPress(obj, alive, fn)
        if I.Device.IsTouch then
            local token = nil
            obj.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Touch then return end
                local myToken = {}
                token = myToken
                task.delay(0.55, function()
                    if token ~= myToken or not alive() then return end
                    token = nil
                    if fn() ~= false then
                        obj:SetAttribute("Dragging", true)
                    end
                end)
            end)
            obj.InputEnded:Connect(function()
                token = nil
                if obj:GetAttribute("Dragging") then
                    task.defer(function() obj:SetAttribute("Dragging", nil) end)
                end
            end)
        else
            obj.MouseButton2Click:Connect(function()
                if alive() then fn() end
            end)
        end
    end

    local function TrackHot(el, row)
        if I.Device.IsTouch then return end
        el.Maid:Give(function()
            if I.HotElement == el then I.HotElement = nil end
        end)
        row.MouseEnter:Connect(function() I.HotElement = el end)
        row.MouseLeave:Connect(function()
            if I.HotElement == el then I.HotElement = nil end
        end)
    end

    I.IsInputDown = IsInputDown
    I.Once = Once
    I.SafeCall = SafeCall
    I.Sanitize = Sanitize
    I.ColorToHex = ColorToHex
    I.HexToColor = HexToColor
    I.RGBtoHSV = RGBtoHSV
    I.RemoveFrom = RemoveFrom
    I.Trim = Trim
    I.SetBoxDisabled = SetBoxDisabled
    local function XAlign()
        return I.Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    end

    local function HAlign()
        return I.Setting.RTL and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
    end

    local function MkButton(parent, props, style)
        style = style or {}
        local bgKey = style.Bg or "Element"
        local textKey = style.Text or "Text"
        props.BackgroundColor3 = I.CurrentTheme[bgKey]
        props.TextColor3 = I.CurrentTheme[textKey]
        props.BorderSizePixel = 0
        props.AutoButtonColor = false
        props.Parent = parent
        props.Children = { I.Corner(style.Corner or 8) }
        local b = I.Create("TextButton", props)
        I.Bind(b, "BackgroundColor3", bgKey)
        I.Bind(b, "TextColor3", textKey)
        I.AddHover(b, style.Hover)
        return b
    end

    local function FloatingChip(cfg)
        cfg = cfg or {}
        local chip = I.Create("TextButton", {
            AnchorPoint = cfg.Anchor or Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(0, 0),
            Position = cfg.Position,
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = cfg.ZIndex or 5,
            Parent = cfg.Parent or I.LayerPersistent,
        })
        I.Bind(chip, "BackgroundColor3", "Surface")
        I.Create("UICorner", {
            CornerRadius = cfg.Circle and UDim.new(1, 0) or UDim.new(0, cfg.Corner or 12),
            Parent = chip,
        })
        I.StrokeBind(1, "Stroke", cfg.StrokeT or 0.4).Parent = chip
        local glyph
        if cfg.Text then
            glyph = I.Create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = cfg.GlyphPos or UDim2.fromScale(0.5, 0.5),
                Size = cfg.GlyphSize or UDim2.fromScale(1, 1),
                Font = cfg.Font or Enum.Font.GothamBold,
                TextSize = cfg.TextSize or 14,
                TextColor3 = I.CurrentTheme.Text,
                Text = cfg.Text,
                Parent = chip,
            })
            I.Bind(glyph, "TextColor3", "Text")
        end
        local maid = I.Maid.new():Link(chip)
        I.MakeDraggable(chip, chip, { Clamp = true })
        I.Tween(chip, cfg.Pop or "SpringBig", { Size = UDim2.fromOffset(46, 46) })
        return chip, glyph, maid
    end

    I.IsAssetId = IsAssetId
    I.NormalizeOptions = NormalizeOptions
    I.NumSpec = NumSpec
    I.ReadClipboard = ReadClipboard
    I.GetClipboardSetter = GetClipboardSetter
    I.OnLongPress = OnLongPress
    I.TrackHot = TrackHot
    I.XAlign = XAlign
    I.HAlign = HAlign
    I.MkButton = MkButton
    I.FloatingChip = FloatingChip
end
