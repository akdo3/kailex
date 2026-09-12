return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Logic = I.KeySystemLogic
    local View = I.KeySystemView

    function Kailex:KeySystem(options)
        local K = Logic.parse(options)
        local opts = K.options

        if Logic.inList(K, opts.Blacklist, opts.CheckBlacklist) then
            I.Note("Access Denied",
                tostring(opts.BlacklistMessage or "You are not allowed to use this script."), "Error", 7)
            if K.onBlacklisted then I.SafeCall(K.onBlacklisted, K.lpName) end
            Logic.handleDecline(K)
            return nil
        end

        if Logic.inList(K, opts.Whitelist, opts.CheckWhitelist) then
            if opts.Silent ~= true then
                I.Note("Key System", "Welcome, " .. K.lpName .. " - you are whitelisted.", "Success")
            end
            I.SafeCall(K.onComplete, "WHITELISTED")
            return nil
        end

        if K.remember then
            local savedKey = I.SaveManager:Get("__keySystemKey", nil)
            if type(savedKey) == "string" and savedKey ~= ""
                and Logic.validateKey(K, savedKey) then
                if opts.Silent ~= true then
                    I.Note("Key System", "Saved key accepted - welcome back.", "Success")
                end
                I.SafeCall(K.onComplete, savedKey)
                return nil
            end
        end

        if next(K.keySet) == nil and not K.customVerify then
            I.SafeCall(K.onComplete)
            return nil
        end

        K.title = tostring(opts.Title or "Key System")
        K.desc = tostring(opts.Description or opts.SubTitle or "Enter your key to continue.")
        K.link = opts.Link or opts.GetKeyLink
        K.alive = true

        local function declineNow()
            if not K.alive then return end
            K.alive = false
            I.PlaySound("Click", 0.5)
            View.fadeOut(K)
            Logic.handleDecline(K)
        end
        K.declineNow = declineNow

        local descH = 15
        do
            local measured = I.TextService:GetTextSize(K.desc, I.TS(12), Enum.Font.Gotham, Vector2.new(324, 60))
            descH = math.clamp(measured.Y, 15, 60)
        end
        K._descSpace = descH
        K.cardSize = UDim2.fromOffset(360, descH + 179)
        View.build(K)

        local function grantAccess(key)
            if not K.alive then return end
            K.alive = false
            I.PlaySound("ToggleOn")
            if K.remember and type(key) == "string" and key ~= "" then
                I.SaveManager:Set("__keySystemKey", key)
            end
            I.Tween(K.inputStroke, "Fast", { Color = I.CurrentTheme.Success, Transparency = 0 })
            View.setStatus(K, "Access granted - welcome!", "Success")
            I.Tween(K.ksScale, "PopSoft", { Scale = 1.02 })
            task.delay(0.42, function()
                View.fadeOut(K)
                task.delay(0.12, function()
                    I.SafeCall(K.onComplete, key)
                end)
            end)
        end

        local function wrongKey()
            I.PlaySound("Error")
            I.FX.Shake(K.card, 9)
            I.Tween(K.inputStroke, "Fast", { Color = I.CurrentTheme.Error, Transparency = 0 })
            View.setStatus(K, "Wrong key - try again.", "Error")
            task.delay(1.2, function()
                if K.alive then
                    I.Tween(K.inputStroke, "Smooth", { Color = I.CurrentTheme.Stroke, Transparency = 0.5 })
                end
            end)
            if K.onWrong then
                I.SafeCall(K.onWrong, K.inputBox.Text)
            end
        end

        local function verify()
            if not K.alive then return end
            local val = I.Trim(K.inputBox.Text)
            if val ~= "" and Logic.validateKey(K, val) then
                grantAccess(val)
            else
                wrongKey()
            end
        end

        K.maid:Give(K.verifyBtn.MouseButton1Click:Connect(function()
            I.ApplyRipple(K.verifyBtn)
            verify()
        end))
        K.maid:Give(K.declineBtn.MouseButton1Click:Connect(function()
            I.ApplyRipple(K.declineBtn)
            declineNow()
        end))
        K.maid:Give(K.inputBox.FocusLost:Connect(function(enter)
            if enter and K.alive then verify() end
        end))

        if K.linkBtn then
            K.maid:Give(K.linkBtn.MouseButton1Click:Connect(function()
                if not K.alive then return end
                I.ApplyRipple(K.linkBtn)
                I.PlaySound("Click", 0.5)
                local setc = I.GetClipboardSetter()
                if setc then
                    if pcall(setc, tostring(K.link)) then
                        View.setStatus(K, "Link copied to clipboard - get your key, then paste it.", "Success")
                    else
                        I.Note(K.title, tostring(K.link), nil, 10)
                        View.setStatus(K, "Could not copy - the link is shown in the notifications.", "Error")
                    end
                else
                    I.Note(K.title, tostring(K.link), nil, 10)
                    View.setStatus(K, "Link is shown in the notifications.")
                end
            end))
        end

        View.enter(K)
        return K.card
    end
end
