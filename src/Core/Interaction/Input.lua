return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local InputHooks = {}
    I.InputHooks = InputHooks

    local function RemoveInputHook(rec)
        rec._removed = true
        I.RemoveFrom(InputHooks, rec)
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

    local function enumOf(enum, name)
        local ok, v = pcall(function() return enum[name] end)
        if ok and v ~= nil then return v end
    end

    local ENUMS = { Key = Enum.KeyCode, Mouse = Enum.UserInputType }

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
                local e = ENUMS[k]
                local c = e and enumOf(e, name)
                if c then return { Kind = k, Code = c, Name = name } end
                return nil
            end
            local kc = enumOf(Enum.KeyCode, v)
            if kc then return { Kind = "Key", Code = kc, Name = v } end
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
                    I.Note("Keybind conflict",
                        "\"" .. b.Name .. "\" is also bound in \"" .. el.Title .. "\".", "Warning", 5)
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
