return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Players = I.Players

    local Logic = {}

    function Logic.parse(options)
        options = options or {}
        local lp = Players.LocalPlayer
        local lpName = lp and lp.Name or ""
        local K = { options = options, lpName = lpName, lpLower = lpName:lower() }

        local customVerify
        if type(options.Verify) == "function" then customVerify = options.Verify
        elseif type(options.CustomVerify) == "function" then customVerify = options.CustomVerify
        elseif type(options.CheckKey) == "function" then customVerify = options.CheckKey end
        K.customVerify = customVerify

        local keySet = {}
        if options.Key ~= nil then keySet[tostring(options.Key)] = true end
        if type(options.Keys) == "table" then
            for _, k in ipairs(options.Keys) do keySet[tostring(k)] = true end
        end
        K.keySet = keySet

        local onComplete = options.OnComplete or options.Callback
        if type(onComplete) ~= "function" then onComplete = function() end end
        K.onComplete = onComplete
        K.onDecline = (type(options.OnDecline) == "function" and options.OnDecline)
            or (type(options.OnCancel) == "function" and options.OnCancel) or nil
        K.onWrong = (type(options.OnWrong) == "function") and options.OnWrong or nil
        K.onBlacklisted = (type(options.OnBlacklisted) == "function") and options.OnBlacklisted or nil

        K.remember = options.Remember ~= false
        K.declineMode = options.DeclineAction or options.DeclineMode
            or (K.onDecline and "none") or "hide"
        return K
    end

    function Logic.validateKey(K, key)
        key = tostring(key or "")
        if K.customVerify then
            local ok, res = pcall(K.customVerify, key)
            return ok and res == true
        end
        return K.keySet[key] == true
    end

    function Logic.inList(K, list, fn)
        if type(list) == "table" then
            for _, n in ipairs(list) do
                if tostring(n):lower() == K.lpLower then return true end
            end
        end
        if type(fn) == "function" then
            local ok, res = pcall(fn, K.lpName)
            if ok and res == true then return true end
        end
        return false
    end

    function Logic.handleDecline(K)
        if K.onDecline then I.SafeCall(K.onDecline) end
        if K.declineMode == "unload" then
            task.defer(function() Kailex:Unload() end)
        elseif K.declineMode == "hide" then
            Kailex:SetVisible(false)
        end
    end

    I.KeySystemLogic = Logic
end
