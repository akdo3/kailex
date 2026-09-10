return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting
    local Players = I.Players

    function Kailex:KeySystem(options)
        options = options or {}

        local lp = Players.LocalPlayer
        local lpName = lp and lp.Name or ""
        local lpLower = lpName:lower()

        local customVerify
        if type(options.Verify) == "function" then customVerify = options.Verify
        elseif type(options.CustomVerify) == "function" then customVerify = options.CustomVerify
        elseif type(options.CheckKey) == "function" then customVerify = options.CheckKey end

        local keySet = {}
        if options.Key ~= nil then keySet[tostring(options.Key)] = true end
        if type(options.Keys) == "table" then
            for _, k in ipairs(options.Keys) do keySet[tostring(k)] = true end
        end

        local onComplete = options.OnComplete or options.Callback
        if type(onComplete) ~= "function" then onComplete = function() end end
        local onDecline = (type(options.OnDecline) == "function" and options.OnDecline)
            or (type(options.OnCancel) == "function" and options.OnCancel) or nil
        local onWrong = (type(options.OnWrong) == "function") and options.OnWrong or nil
        local onBlacklisted = (type(options.OnBlacklisted) == "function") and options.OnBlacklisted or nil

        local remember = options.Remember ~= false
        local declineMode = options.DeclineAction or options.DeclineMode
            or (onDecline and "none") or "hide"

        local function handleDecline()
            if onDecline then I.SafeCall(onDecline) end
            if declineMode == "unload" then
                task.defer(function() Kailex:Unload() end)
            elseif declineMode == "hide" then
                Kailex:SetVisible(false)
            end
        end

        local function validateKey(key)
            key = tostring(key or "")
            if customVerify then
                local ok, res = pcall(customVerify, key)
                return ok and res == true
            end
            return keySet[key] == true
        end

        local function inList(list, fn)
            if type(list) == "table" then
                for _, n in ipairs(list) do
                    if tostring(n):lower() == lpLower then return true end
                end
            end
            if type(fn) == "function" then
                local ok, res = pcall(fn, lpName)
                if ok and res == true then return true end
            end
            return false
        end

        if inList(options.Blacklist, options.CheckBlacklist) then
            Kailex:Notify({
                Title = "Access Denied",
                Text = tostring(options.BlacklistMessage or "You are not allowed to use this script."),
                Type = "Error", Duration = 7,
            })
            if onBlacklisted then I.SafeCall(onBlacklisted, lpName) end
            handleDecline()
            return nil
        end

        if inList(options.Whitelist, options.CheckWhitelist) then
            if options.Silent ~= true then
                Kailex:Notify({ Title = "Key System", Text = "Welcome, " .. lpName .. " - you are whitelisted.", Type = "Success" })
            end
            I.SafeCall(onComplete, "WHITELISTED")
            return nil
        end

        if remember then
            local savedKey = I.SaveManager:Get("__keySystemKey", nil)
            if type(savedKey) == "string" and savedKey ~= "" and validateKey(savedKey) then
                if options.Silent ~= true then
                    Kailex:Notify({ Title = "Key System", Text = "Saved key accepted - welcome back.", Type = "Success" })
                end
                I.SafeCall(onComplete, savedKey)
                return nil
            end
        end

        if next(keySet) == nil and not customVerify then
            I.SafeCall(onComplete)
            return nil
        end

        local title = tostring(options.Title or "Key System")
        local desc = tostring(options.Description or options.SubTitle or "Enter your key to continue.")
        local link = options.Link or options.GetKeyLink
        local maxAttempts = math.max(0, math.floor(tonumber(options.MaxAttempts or options.Attempts) or 0))
        local attempts = 0
        local alive = true

        local maid = I.Maid.new()
        local dimmer = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 40,
            Parent = I.LayerOverlay,
        })
        local card = I.Create("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(360, 246),
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            ZIndex = 41,
            Parent = I.LayerOverlay,
        })
        I.Bind(card, "BackgroundColor3", "Surface")
        I.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = card })
        local cardStroke = I.Create("UIStroke", {
            Thickness = 1, Transparency = 0.35,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card,
        })
        I.Bind(cardStroke, "Color", "Stroke")
        local ksScale = I.Create("UIScale", { Scale = 0.94, Parent = card })

        I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 16),
            Size = UDim2.new(1, -36, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = title, ZIndex = 42, Parent = card,
        })
        I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 38),
            Size = UDim2.new(1, -36, 0, 30),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Text = desc, ZIndex = 42, Parent = card,
        })

        local statusLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 122),
            Size = UDim2.new(1, -36, 0, 15),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = maxAttempts > 0 and ("Attempts: 0 / " .. maxAttempts) or "",
            ZIndex = 42, Parent = card,
        })
        I.Bind(statusLabel, "TextColor3", "SubText")
        local function setStatus(text, colorKey)
            statusLabel.Text = tostring(text or "")
            statusLabel.TextColor3 = I.CurrentTheme[colorKey] or I.CurrentTheme.SubText
        end

        local hasPaste = false
        local okPaste, gc = pcall(function() return getclipboard end)
        if okPaste and type(gc) == "function" then hasPaste = true end

        local inputBox = I.Create("TextBox", {
            Position = UDim2.fromOffset(18, 76),
            Size = UDim2.new(1, -36, 0, 38),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            PlaceholderText = "Enter your key...",
            PlaceholderColor3 = I.CurrentTheme.SubText,
            ClearTextOnFocus = false, Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 42, Parent = card,
            Children = { I.Corner(8) },
        })
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, hasPaste and 66 or 10),
            Parent = inputBox,
        })
        I.Bind(inputBox, "BackgroundColor3", "SurfaceLight")
        I.Bind(inputBox, "TextColor3", "Text")
        I.Bind(inputBox, "PlaceholderColor3", "SubText")
        local inputStroke = I.Create("UIStroke", {
            Thickness = 1, Transparency = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inputBox,
        })
        I.Bind(inputStroke, "Color", "Stroke")

        if hasPaste then
            local pasteBtn = I.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(56, 26),
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = "Paste",
                Font = Enum.Font.GothamBold, TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                AutoButtonColor = false, ZIndex = 43, Parent = inputBox,
                Children = { I.Corner(6) },
            })
            I.Bind(pasteBtn, "BackgroundColor3", "Element")
            I.Bind(pasteBtn, "TextColor3", "SubText")
            I.AddHover(pasteBtn)
            maid:Give(pasteBtn.MouseButton1Click:Connect(function()
                if not alive then return end
                local ok, txt = pcall(gc)
                if ok and type(txt) == "string" and txt:match("%S") then
                    inputBox.Text = txt:match("^%s*(.-)%s*$")
                    I.PlaySound("Click", 0.5)
                    setStatus("Key pasted from clipboard - press Verify.")
                end
            end))
        end

        local function mkBtn(text, accent, xPos, w)
            local b = I.Create("TextButton", {
                Position = UDim2.fromOffset(xPos, 176),
                Size = UDim2.fromOffset(w, 40),
                BackgroundColor3 = accent and I.CurrentTheme.Accent or I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.GothamBold, TextSize = 12,
                TextColor3 = accent and I.CurrentTheme.OnAccent or I.CurrentTheme.Text,
                AutoButtonColor = false,
                ZIndex = 42, Parent = card,
                Children = { I.Corner(8) },
            })
            if accent then
                I.Bind(b, "BackgroundColor3", "Accent")
                I.Bind(b, "TextColor3", "OnAccent")
                I.AddHover(b, { HoverKey = "AccentHover", BaseKey = "Accent" })
            else
                I.Bind(b, "BackgroundColor3", "Element")
                I.Bind(b, "TextColor3", "Text")
                I.AddHover(b)
            end
            return b
        end

        local verifyBtn, linkBtn, declineBtn
        if link then
            verifyBtn  = mkBtn("Verify", true, 226, 116)
            declineBtn = mkBtn(options.DeclineText or "Decline", false, 122, 96)
            linkBtn    = mkBtn(options.LinkText or "Get Key", false, 18, 96)
        else
            verifyBtn  = mkBtn("Verify", true, 126, 216)
            declineBtn = mkBtn(options.DeclineText or "Decline", false, 18, 100)
        end

        local function fadeOutCard()
            I.Tween(ksScale, "Vanish", { Scale = 0.95 })
            I.Tween(card, "Vanish", { GroupTransparency = 1 }, function()
                maid:Destroy()
                card:Destroy()
            end)
            I.Tween(dimmer, "Smooth", { BackgroundTransparency = 1 }, function()
                if dimmer.Parent then dimmer:Destroy() end
            end)
        end

        local function grantAccess(key)
            if not alive then return end
            alive = false
            I.PlaySound("ToggleOn")
            if remember and type(key) == "string" and key ~= "" then
                I.SaveManager:Set("__keySystemKey", key)
            end
            I.Tween(inputStroke, "Fast", { Color = I.CurrentTheme.Success, Transparency = 0 })
            setStatus("Access granted - welcome!", "Success")
            I.Tween(ksScale, "PopSoft", { Scale = 1.02 })
            task.delay(0.42, function()
                fadeOutCard()
                task.delay(0.12, function()
                    I.SafeCall(onComplete, key)
                end)
            end)
        end

        local function wrongKey()
            attempts += 1
            I.PlaySound("Error")
            I.FX.Shake(card, 9)
            I.Tween(inputStroke, "Fast", { Color = I.CurrentTheme.Error, Transparency = 0 })
            if maxAttempts > 0 then
                local left = maxAttempts - attempts
                if left <= 0 then
                    setStatus("Wrong key - no attempts left.", "Error")
                    if onWrong then I.SafeCall(onWrong, inputBox.Text, 0) end
                    task.delay(0.7, function()
                        if alive then
                            alive = false
                            fadeOutCard()
                            handleDecline()
                        end
                    end)
                    return
                end
                setStatus("Wrong key - attempts: " .. attempts .. " / " .. maxAttempts .. " (" .. left .. " left)", "Error")
            else
                setStatus("Wrong key - try again.", "Error")
            end
            task.delay(1.2, function()
                if alive then
                    I.Tween(inputStroke, "Smooth", { Color = I.CurrentTheme.Stroke, Transparency = 0.5 })
                end
            end)
            if onWrong then I.SafeCall(onWrong, inputBox.Text, math.max(0, maxAttempts - attempts)) end
        end

        local function verify()
            if not alive then return end
            local val = inputBox.Text:match("^%s*(.-)%s*$")
            if val ~= "" and validateKey(val) then
                grantAccess(val)
            else
                wrongKey()
            end
        end

        local function declineNow()
            if not alive then return end
            alive = false
            I.PlaySound("Click", 0.5)
            fadeOutCard()
            handleDecline()
        end

        maid:Give(verifyBtn.MouseButton1Click:Connect(function()
            I.ApplyRipple(verifyBtn)
            verify()
        end))
        maid:Give(declineBtn.MouseButton1Click:Connect(function()
            I.ApplyRipple(declineBtn)
            declineNow()
        end))
        maid:Give(inputBox.FocusLost:Connect(function(enter)
            if enter and alive then verify() end
        end))
        local escHook = I.AddInputHook(function() return alive end, function(input)
            if input.KeyCode == Enum.KeyCode.Escape then
                declineNow()
            end
        end)
        maid:Give(function() I.RemoveInputHook(escHook) end)
        if linkBtn then
            maid:Give(linkBtn.MouseButton1Click:Connect(function()
                if not alive then return end
                I.ApplyRipple(linkBtn)
                I.PlaySound("Click", 0.5)
                local setc
                local ok, sc = pcall(function() return setclipboard or toclipboard or setrbxclipboard end)
                if ok then setc = sc end
                if type(setc) == "function" then
                    pcall(setc, tostring(link))
                    setStatus("Link copied to clipboard - get your key, then paste it.", "Success")
                else
                    Kailex:Notify({ Title = title, Text = tostring(link), Duration = 10 })
                    setStatus("Link is shown in the notifications.")
                end
            end))
        end

        I.Tween(dimmer, "Normal", { BackgroundTransparency = 0.5 })
        card.GroupTransparency = 1
        I.Tween(card, "Snappy", { GroupTransparency = 0 })
        I.Tween(ksScale, "Pop", { Scale = 1 })
        task.defer(function() inputBox:CaptureFocus() end)
        return card
    end
end
