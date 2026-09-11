return function(ctx)
    local I = ctx.Internal

    local ModalManager = { Stack = {} }
    I.ModalManager = ModalManager

    function ModalManager.Push(owner, closer)
        local entry = { Owner = owner, Close = closer }
        table.insert(ModalManager.Stack, entry)
        return entry
    end

    function ModalManager.Remove(entry)
        local idx = table.find(ModalManager.Stack, entry)
        if idx then table.remove(ModalManager.Stack, idx) end
    end

    function ModalManager.CloseAll(owner)
        for i = #ModalManager.Stack, 1, -1 do
            local e = ModalManager.Stack[i]
            if owner == nil or e.Owner == nil or e.Owner == owner then
                table.remove(ModalManager.Stack, i)
                pcall(e.Close)
            end
        end
    end

    function ModalManager.CloseTop()
        local top = ModalManager.Stack[#ModalManager.Stack]
        if not top then return false end
        table.remove(ModalManager.Stack, #ModalManager.Stack)
        pcall(top.Close)
        return true
    end
end
