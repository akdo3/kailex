local isStudioModule = false
do
    local s = script
    if typeof(s) == "Instance" and s:IsA("ModuleScript") and s:FindFirstChild("Core") then
        isStudioModule = true
    end
end

local LoadOrder

if isStudioModule then
    LoadOrder = require(script:WaitForChild("LoadOrder"))
elseif Bundle ~= nil then
    LoadOrder = Bundle.__order
else
    error("Kailex: init.lua cannot run standalone - use the Rojo module or the dist bundle")
end

local function Run(loader)
    local Kailex = {
        Version = "2.1.0",
        Windows = {},
    }
    local Internal = {}
    local ctx = { Kailex = Kailex, Internal = Internal }
    if isStudioModule then
        Kailex._internal = Internal
    end
    local missing = {}
    for i = 1, #LoadOrder do
        local name = LoadOrder[i]
        local mod = loader(name)
        if mod then
            mod(ctx)
        else
            table.insert(missing, name)
        end
    end
    if #missing > 0 then
        warn("[Kailex] missing modules (" .. #missing .. "): " .. table.concat(missing, ", "))
    end
    return Kailex
end

if isStudioModule then
    return Run(function(name)
        local node = script
        for part in name:gmatch("[^/]+") do
            node = node:FindFirstChild(part)
            if not node then
                return nil
            end
        end
        return require(node)
    end)
end

return Run(function(name)
    return Bundle[name]
end)
