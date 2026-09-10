return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local function RunCallback(fn, ctxName, ...)
        if type(fn) ~= "function" then return end
        if Setting.AsyncCallbacks then
            local args = table.pack(...)
            task.spawn(function()
                local ok, err = pcall(fn, table.unpack(args, 1, args.n))
                if not ok then
                    warn("[Kailex] " .. tostring(err))
                    Kailex:Notify({
                        Title = "Callback error" .. (ctxName and (" - " .. ctxName) or ""),
                        Text = tostring(err), Type = "Error", Duration = 6,
                    })
                end
            end)
        else
            I.SafeCall(fn, ...)
        end
    end

    local function CopyToClipboard(text)
        local setc
        local ok, sc = pcall(function() return setclipboard or toclipboard or setrbxclipboard end)
        if ok then setc = sc end
        if type(setc) == "function" then
            pcall(setc, tostring(text))
            Kailex:Notify({ Title = "Copied", Text = tostring(text), Type = "Success", Duration = 2 })
        else
            Kailex:Notify({ Title = "Copy", Text = tostring(text), Duration = 6 })
        end
    end

    I.RunCallback = RunCallback
    I.CopyToClipboard = CopyToClipboard
end
