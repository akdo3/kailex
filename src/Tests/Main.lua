local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kailex = require(ReplicatedStorage:WaitForChild("Kailex"))

local TEST_MODULES = {
    "Primitives",
    "Services",
    "ThemeSuite",
    "Interaction",
    "Overlays",
    "ElementsBasic",
    "ElementsValue",
    "ElementsVisual",
    "WindowSuite",
    "IntegrationSuite",
}

local function requireSibling(name)
    local node = script.Parent:WaitForChild(name, 10)
    if not node then
        local found = {}
        for _, ch in ipairs(script.Parent:GetChildren()) do
            table.insert(found, ch.Name .. " (" .. ch.ClassName .. ")")
        end
        error(
            "Kailex Tests: \"" .. name .. "\" is missing under "
            .. script.Parent:GetFullName()
            .. ". Present: " .. (#found > 0 and table.concat(found, ", ") or "none"),
            0
        )
    end
    local ok, result = pcall(require, node)
    if not ok then
        error("Kailex Tests: module \"" .. name .. "\" failed to load: " .. tostring(result), 0)
    end
    return result
end

local F = requireSibling("Framework")
F.Kailex = Kailex
F.Internal = Kailex._internal

if not F.Internal then
    error("Kailex tests require the Studio module build (Kailex._internal is missing)", 0)
end

table.clear(F.Suites)

for _, name in ipairs(TEST_MODULES) do
    requireSibling(name)
end

return F.Run()
