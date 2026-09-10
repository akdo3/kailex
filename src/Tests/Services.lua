local F = require(script.Parent.Framework)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Services")

suite:Test("Device profile is resolved", function(t)
    t:Boolean(I.Device.IsTouch)
    t:Boolean(I.Device.IsDesktop)
    t:Boolean(I.Device.IsConsole)
    t:Number(I.ROW_H)
    t:True(I.ROW_H == 32 or I.ROW_H == 40)
end)

suite:Test("Env exposes services and helpers", function(t)
    t:Instance("Players", I.Players)
    t:Instance("TweenService", I.TweenService)
    t:Instance("UserInputService", I.UserInputService)
    t:True(type(I.Getgenv) == "function")
    t:Boolean(I.HasFileSystem)
end)

suite:Test("SaveManager Get returns defaults for missing keys", function(t)
    t:Equal("fallback", I.SaveManager:Get("MissingKey", "fallback"))
    t:Nil(I.SaveManager:Get("MissingKey", nil))
end)

suite:Test("SaveManager Get validates types", function(t)
    I.SaveManager:Set("TypeCheck", "text")
    t:Equal(5, I.SaveManager:Get("TypeCheck", 5))
    I.SaveManager:Set("TypeCheck", true)
    t:True(I.SaveManager:Get("TypeCheck", false))
end)

suite:Test("SaveManager Set stores and reads values", function(t)
    I.SaveManager:Set("Stored", 99)
    t:Equal(99, I.SaveManager:Get("Stored", nil))
    I.SaveManager:Set("Stored", "changed")
    t:Equal("changed", I.SaveManager:Get("Stored", nil))
end)

suite:Test("SaveManager Clear empties data and fires DataChanged", function(t)
    local fired = false
    local conn = I.SaveManager.DataChanged:Connect(function() fired = true end)
    t:Cleanup(conn)
    I.SaveManager:Set("ClearMe", 1)
    I.SaveManager:Clear()
    t:True(fired)
    t:Nil(I.SaveManager:Get("ClearMe", nil))
end)

suite:Test("SaveValue writes through SaveManager", function(t)
    I.SaveValue("Through", "value")
    t:Equal("value", I.SaveManager:Get("Through", nil))
    I.SaveValue(nil, "ignored")
end)

suite:Test("Internal keys are filtered", function(t)
    t:True(I.IsInternalKey("__theme"))
    t:True(I.IsInternalKey("__win:Title"))
    t:False(I.IsInternalKey("theme"))
end)

suite:Test("Configs paths are sanitized", function(t)
    local p = I.Configs:Path('bad/name*:"x')
    t:True(p:find("badname", 1, true) ~= nil)
    t:True(p:find("%.json$") ~= nil)
end)

suite:Test("Configs degrade gracefully without a filesystem", function(t)
    t:Boolean(I.Configs:Save("profile"))
    t:Boolean(I.Configs:Load("profile"))
    t:Boolean(I.Configs:Delete("profile"))
    t:Table(I.Configs:List())
end)

suite:Test("Kailex exposes Configs publicly", function(t)
    t:Table(Kailex.Configs)
    t:Equal(I.Configs, Kailex.Configs)
end)

suite:Test("Audio presets are complete", function(t)
    for _, kind in ipairs({ "Hover", "Click", "ToggleOn", "ToggleOff", "Slider", "Error" }) do
        t:NotNil(Kailex.Audio[kind], "missing audio: " .. kind)
        t:String(Kailex.Audio[kind].Id)
    end
    t:Number(Kailex.Audio.Master)
end)

suite:Test("PlaySound is safe in both modes", function(t)
    local old = I.Setting.Sounds
    I.Setting.Sounds = false
    t:Defer(function() I.Setting.Sounds = old end)
    I.PlaySound("Click")
    I.Setting.Sounds = true
    I.PlaySound("Click")
    I.PlaySound("NotAKnownKind")
    t:True(true)
end)

suite:Test("Setting table is shared state", function(t)
    t:Equal(Kailex.Setting, I.Setting)
    t:String(Kailex.Setting.Theme)
    t:Boolean(Kailex.Setting.Sounds)
end)

return suite
