return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService

    local InputHooks = {}
    I.InputHooks = InputHooks

    local function RemoveInputHook(rec)
        rec._removed = true
        local idx = table.find(InputHooks, rec)
        if idx then table.remove(InputHooks, idx) end
    end

    local function AddInputHook(alive, fn)
        local rec = { alive = alive, fn = fn }
        function rec:Destroy()
            RemoveInputHook(rec)
        end
        table.insert(InputHooks, rec)
        return rec
    end

    I.LibMaid:Give(UserInputService.InputBegan:Connect(function(input, gp)
        local n = #InputHooks
        if n == 0 then return end
        local snapshot = table.clone(InputHooks)
        for i = 1, #snapshot do
            local h = snapshot[i]
            if h and not h._removed then
                local okAlive, alive = pcall(h.alive)
                if okAlive and alive then
                    local ok, err = pcall(h.fn, input, gp)
                    if not ok then warn("[Kailex] " .. tostring(err)) end
                end
            end
        end
        if #InputHooks > 96 then
            local keep = table.create(8)
            for i = 1, #InputHooks do
                local h = InputHooks[i]
                local okAlive, alive = pcall(h.alive)
                if okAlive and alive then keep[#keep + 1] = h end
            end
            I.InputHooks = keep
            InputHooks = keep
        end
    end))

    local KeybindRegistry = {}
    I.KeybindRegistry = KeybindRegistry
    I.ActiveKeybindListener = nil
    I.HotElement = nil

    local function ToBinding(v)
        if typeof(v) == "EnumItem" then
            if v.EnumType == Enum.KeyCode then
                return { Kind = "Key", Code = v, Name = v.Name }
            end
            if v.EnumType == Enum.UserInputType then
                return { Kind = "Mouse", Code = v, Name = v.Name }
            end
            return nil
        end
        if type(v) == "string" then
            local kind, name = v:match("^(%a+):(.+)$")
            if kind then
                local k = kind:sub(1, 1):upper() .. kind:sub(2):lower()
                if k == "Key" then
                    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
                    if ok and kc ~= nil then
                        return { Kind = "Key", Code = kc, Name = name }
                    end
                elseif k == "Mouse" then
                    local ok, it = pcall(function() return Enum.UserInputType[name] end)
                    if ok and it ~= nil then
                        return { Kind = "Mouse", Code = it, Name = name }
                    end
                end
                return nil
            end
            local ok, kc = pcall(function() return Enum.KeyCode[v] end)
            if ok and kc ~= nil then
                return { Kind = "Key", Code = kc, Name = v }
            end
        end
        return nil
    end

    local function ParseKey(v)
        local b = ToBinding(v)
        if b and b.Kind == "Key" then return b.Code end
    end

    local function NotifyKeybindConflict(self, b)
        for _, rec in ipairs(KeybindRegistry) do
            local el = rec.el
            if el ~= self and not el._destroyed then
                local ob = el._getBinding and el:_getBinding()
                if ob and ob.Kind == b.Kind and ob.Code == b.Code then
                    Kailex:Notify({
                        Title = "Keybind conflict",
                        Text = "\"" .. b.Name .. "\" is also bound in \"" .. el.Title .. "\".",
                        Type = "Warning", Duration = 5,
                    })
                    return
                end
            end
        end
    end

    I.AddInputHook = AddInputHook
    I.RemoveInputHook = RemoveInputHook
    I.ParseKey = ParseKey
    I.ToBinding = ToBinding
    I.NotifyKeybindConflict = NotifyKeybindConflict
end
