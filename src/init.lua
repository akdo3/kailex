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
    local requiredInternal = {
        "Maid", "Signal", "Setting", "LibMaid",
        "Bind", "ApplyTheme", "Themes", "CurrentTheme",
        "Create", "TS", "Icon", "AddHover", "DropShadow",
        "Tween", "FX",
        "SaveManager", "Configs", "SaveReloadRegistry",
        "PlaySound",
        "ScreenGui", "LayerWindows", "LayerOverlay", "LayerNotify", "LayerTooltip",
        "GetScale", "UpdateViewport", "ViewportHooks",
        "AddInputHook", "RemoveInputHook", "ModalManager", "ParseKey", "KeybindRegistry",
        "BeginDrag", "MakeDraggable", "DragManager",
        "ApplyRipple", "IsInputDown", "Once", "SafeCall",
        "RunCallback", "CopyToClipboard",
        "Tooltip", "AddTooltip", "QuickWidgets", "ContextMenu", "ModalCard",
        "Element", "Elements", "CreateRow", "MakeElementClass",
        "WindowClass", "TabClass", "GridRow",
        "ApplyPersisted",
    }
    local requiredKailex = { "CreateWindow", "Notify", "Confirm", "Unload" }
    local absent = {}
    for _, key in ipairs(requiredInternal) do
        if Internal[key] == nil then absent[#absent + 1] = "I." .. key end
    end
    for _, key in ipairs(requiredKailex) do
        if type(Kailex[key]) ~= "function" then absent[#absent + 1] = "Kailex." .. key end
    end
    if #absent > 0 then
        error("[Kailex] load order broken - missing: " .. table.concat(absent, ", "), 0)
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
