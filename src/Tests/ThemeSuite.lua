local F = require(script.Parent.Framework)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Themes")

suite:Test("Every built-in theme defines every key", function(t)
    t:Equal(16, #I.ThemeKeys)
    local count = 0
    for name, theme in pairs(I.Themes) do
        count += 1
        for _, key in ipairs(I.ThemeKeys) do
            t:TypeOf("Color3", theme[key], name .. "." .. key)
        end
    end
    t:True(count >= 6, "expected at least 6 built-in themes")
end)

suite:Test("GetThemes returns a sorted list with new themes", function(t)
    local list = Kailex:GetThemes()
    t:Contains(list, "Nocturne")
    t:Contains(list, "Aurora")
    t:Contains(list, "Sakura")
    t:Contains(list, "Daylight")
    t:Contains(list, "Obsidian")
    t:Contains(list, "Ember")
    for i = 2, #list do
        t:True(list[i - 1] <= list[i], "theme list is not sorted")
    end
end)

suite:Test("SetTheme applies and fires ThemeChanged", function(t)
    local fired = nil
    local conn = Kailex.ThemeChanged:Connect(function(theme) fired = theme end)
    t:Cleanup(conn)
    Kailex:SetTheme("Aurora")
    t:WaitFor(function() return fired == I.Themes.Aurora end, 1)
    t:Equal(I.Themes.Aurora, I.CurrentTheme)
    Kailex:SetTheme("Nocturne")
    t:WaitFor(function() return I.CurrentTheme == I.Themes.Nocturne end, 1)
end)

suite:Test("SetTheme ignores unknown names", function(t)
    local current = I.CurrentTheme
    Kailex:SetTheme("DoesNotExist")
    t:WaitFor(function() return I.CurrentTheme == current end, 1)
end)

suite:Test("Bind tracks theme properties", function(t)
    local frame = I.Create("Frame", { Parent = I.LayerOverlay })
    t:Cleanup(frame)
    I.Bind(frame, "BackgroundColor3", "Accent")
    t:Equal(I.CurrentTheme.Accent, frame.BackgroundColor3)
    Kailex:SetTheme("Daylight")
    t:WaitFor(function() return frame.BackgroundColor3 == I.Themes.Daylight.Accent end, 1)
    Kailex:SetTheme("Nocturne")
    t:WaitFor(function() return frame.BackgroundColor3 == I.Themes.Nocturne.Accent end, 1)
end)

suite:Test("RegisterTheme accepts colors and hex strings", function(t)
    local theme = Kailex:RegisterTheme("TestCustom123", { Accent = "#FF0000" })
    t:NotNil(theme)
    t:Equal(Color3.fromRGB(255, 0, 0), theme.Accent)
    t:Contains(Kailex:GetThemes(), "TestCustom123")
    t:Nil(Kailex:RegisterTheme("", {}))
    Kailex:RemoveTheme("TestCustom123")
    t:Nil(I.Themes.TestCustom123)
end)

suite:Test("RemoveTheme falls back to Nocturne when active", function(t)
    Kailex:RegisterTheme("TempActive", {})
    Kailex:SetTheme("TempActive")
    I.Setting.Theme = "TempActive"
    t:WaitFor(function() return I.CurrentTheme == I.Themes.TempActive end, 1)
    Kailex:RemoveTheme("TempActive")
    t:Nil(I.Themes.TempActive)
    t:Equal("Nocturne", I.Setting.Theme)
    t:WaitFor(function() return I.CurrentTheme == I.Themes.Nocturne end, 1)
end)

suite:Test("Custom themes persist through the store", function(t)
    Kailex:RegisterTheme("StoredCustom", { Accent = "#00FF00" })
    Kailex:SaveCustomThemes()
    local saved = I.SaveManager:Get("__customThemes", {})
    t:NotNil(saved.StoredCustom)
    Kailex:RemoveTheme("StoredCustom")
    t:Nil(I.Themes.StoredCustom)
    I.LoadCustomThemes()
    t:NotNil(I.Themes.StoredCustom)
    t:Equal(Color3.fromRGB(0, 255, 0), I.Themes.StoredCustom.Accent)
    Kailex:RemoveTheme("StoredCustom")
end)

return suite
