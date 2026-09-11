return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local lastErrMsg, lastErrAt = nil, 0
    local function ReportError(ctxName, err)
        local msg, now = tostring(err), os.clock()
        warn("[Kailex] " .. msg)
        if msg == lastErrMsg and (now - lastErrAt) < 1 then return end
        lastErrMsg, lastErrAt = msg, now
        Kailex:Notify({
            Title = "Callback error" .. (ctxName and (" - " .. ctxName) or ""),
            Text = msg, Type = "Error", Duration = 6,
        })
    end

    local function RunCallback(fn, ctxName, ...)
        if type(fn) ~= "function" then return end
        if Setting.AsyncCallbacks then
            local args = table.pack(...)
            task.spawn(function()
                local ok, err = pcall(fn, table.unpack(args, 1, args.n))
                if not ok then ReportError(ctxName, err) end
            end)
        else
            local ok, err = pcall(fn, ...)
            if not ok then ReportError(ctxName, err) end
        end
    end

    local function CopyToClipboard(text)
        local setc = I.GetClipboardSetter()
        if setc then
            pcall(setc, tostring(text))
            Kailex:Notify({ Title = "Copied", Text = tostring(text), Type = "Success", Duration = 2 })
        else
            Kailex:Notify({ Title = "Copy", Text = tostring(text), Duration = 6 })
        end
    end

    I.RunCallback = RunCallback
    I.CopyToClipboard = CopyToClipboard
end
