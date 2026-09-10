return function(ctx)
    local I = ctx.Internal

    local Signal = {}
    Signal.__index = Signal

    function Signal.new()
        return setmetatable({ _conns = {}, _lock = 0, _dirty = false, _dead = false }, Signal)
    end

    function Signal:Connect(fn)
        if type(fn) ~= "function" then error("Signal:Connect expects a function", 2) end
        if self._dead then
            local c = { Connected = false }
            function c:Disconnect() end
            c.Destroy = c.Disconnect
            return c
        end
        local conn = { Connected = true, _fn = fn, _sig = self }
        function conn:Disconnect()
            if not self.Connected then return end
            self.Connected = false
            local sig = self._sig
            if sig._lock > 0 then
                sig._dirty = true
            else
                local list = sig._conns
                for i, c in ipairs(list) do
                    if c == self then table.remove(list, i) break end
                end
            end
        end
        conn.Destroy = conn.Disconnect
        table.insert(self._conns, conn)
        return conn
    end

    function Signal:Once(fn)
        local conn
        conn = self:Connect(function(...)
            conn:Disconnect()
            fn(...)
        end)
        return conn
    end

    function Signal:Wait()
        local thread = coroutine.running()
        local conn
        conn = self:Connect(function(...)
            conn:Disconnect()
            task.spawn(thread, ...)
        end)
        return coroutine.yield()
    end

    function Signal:Fire(...)
        local conns = self._conns
        local n = #conns
        if n == 0 then return end
        self._lock += 1
        for i = 1, n do
            local c = conns[i]
            if c.Connected then
                local ok, err = pcall(c._fn, ...)
                if not ok then warn("[Kailex] " .. tostring(err)) end
            end
        end
        self._lock -= 1
        if self._lock == 0 and self._dirty then
            self._dirty = false
            local keep = table.create(n)
            for i = 1, #conns do
                local c = conns[i]
                if c.Connected then keep[#keep + 1] = c end
            end
            self._conns = keep
        end
    end

    function Signal:Destroy()
        for _, c in ipairs(self._conns) do c.Connected = false end
        self._conns = {}
        self._dead = true
    end

    I.Signal = Signal
end
