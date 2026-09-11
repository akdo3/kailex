return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local function Note(title, text, typ, dur)
        Kailex:Notify({ Title = title, Text = text, Type = typ, Duration = dur })
    end

    local lastErrMsg, lastErrAt = nil, 0
    local function ReportError(ctxName, err)
        local msg, now = tostring(err), os.clock()
        warn("[Kailex] " .. msg)
        if msg == lastErrMsg and (now - lastErrAt) < 1 then return end
        lastErrMsg, lastErrAt = msg, now
        Note("Callback error" .. (ctxName and (" - " .. ctxName) or ""), msg, "Error", 6)
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
            if pcall(setc, tostring(text)) then
                Note("Copied", tostring(text), "Success", 2)
            else
                Note("Copy failed", tostring(text))
            end
        else
            Note("Copy", tostring(text))
        end
    end

    I.RunCallback = RunCallback
    I.CopyToClipboard = CopyToClipboard
    I.Note = Note
end
