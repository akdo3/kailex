return function(ctx)
    local I = ctx.Internal

    local Maid = {}
    Maid.__index = Maid

    function Maid.new()
        return setmetatable({ _tasks = {}, _link = nil, _dead = false }, Maid)
    end

    function Maid:Give(item)
        if item == nil or self._dead then return item end
        table.insert(self._tasks, item)
        return item
    end

    function Maid:Link(inst)
        if typeof(inst) == "Instance" and not self._dead and not self._link then
            self._link = inst.Destroying:Connect(function() self:Destroy() end)
        end
        return self
    end

    function Maid:Clean()
        local tasks = self._tasks
        self._tasks = {}
        for i = #tasks, 1, -1 do
            local t = tasks[i]
            tasks[i] = nil
            pcall(function()
                local tt = typeof(t)
                if tt == "Instance" then t:Destroy()
                elseif tt == "RBXScriptConnection" then t:Disconnect()
                elseif tt == "function" then t()
                elseif tt == "thread" then task.cancel(t)
                elseif tt == "table" and type(t.Destroy) == "function" then t:Destroy() end
            end)
        end
    end

    function Maid:Destroy()
        if self._dead then return end
        self._dead = true
        if self._link then pcall(function() self._link:Disconnect() end) self._link = nil end
        self:Clean()
    end

    I.Maid = Maid
end
