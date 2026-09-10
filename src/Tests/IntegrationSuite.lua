local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Integration")

suite:Test("Every element type can be created together", function(t)
    local win = F.NewWindow({ Title = "All" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "Everything" })
    local els = {
        tab:AddLabel({ Text = "l" }),
        tab:AddParagraph({ Title = "p", Text = "b" }),
        tab:AddDivider(),
        tab:AddSection("s"),
        tab:AddButton({ Name = "b" }),
        tab:AddToggle({ Name = "t" }),
        tab:AddSlider({ Name = "sl", Min = 0, Max = 1 }),
        tab:AddKeybind({ Name = "kb" }),
        tab:AddDropdown({ Name = "dp", Options = { "1", "2" } }),
        tab:AddTextInput({ Name = "ti" }),
        tab:AddColorPicker({ Name = "cp" }),
        tab:AddProgressBar({ Name = "pg" }),
        tab:AddStepper({ Name = "st" }),
        tab:AddSegmented({ Name = "sg", Options = { "a", "b" } }),
        tab:AddVector3Input({ Name = "v3" }),
        tab:AddDataTable({ Name = "dt", Columns = { { Name = "C" } }, Rows = { { 1 } }, Height = 100 }),
    }
    for i, el in ipairs(els) do
        t:NotNil(el, "element " .. i .. " is nil")
        t:NotNil(el.Row, "element " .. i .. " has no row")
    end
    local grid = tab:AddRow(2)
    local g1 = grid:AddButton({ Name = "g1" })
    t:Equal(grid.Frame, g1.Row.Parent)
    local settings = Kailex:CreateSettingsTab(win)
    t:NotNil(settings)
    t:Wait(0.2)
end)

suite:Test("SaveReloadRegistry applies external data changes", function(t)
    local win = F.NewWindow({ Title = "Reload" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "T" })
    local before = {}
    for k in pairs(I.SaveReloadRegistry) do before[k] = true end
    local tgl = tab:AddToggle({ Name = "ReloadMe", Default = false })
    local newKey = nil
    for k in pairs(I.SaveReloadRegistry) do
        if not before[k] then newKey = k end
    end
    t:NotNil(newKey)
    tgl:Set(true)
    t:True(tgl:Get())
    I.SaveManager.Data[newKey] = false
    I.SaveManager.DataChanged:Fire()
    t:False(tgl:Get())
end)

suite:Test("Theme changes recolor live interfaces", function(t)
    local win = F.NewWindow({ Title = "ThemeLive" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "T" })
    local btn = tab:AddButton({ Name = "B" })
    local before = btn.Row.BackgroundColor3
    Kailex:SetTheme("Sakura")
    t:WaitFor(function()
        return btn.Row.BackgroundColor3 == I.Themes.Sakura.Element
    end, 1)
    t:NotEqual(before, I.Themes.Sakura.Element)
    Kailex:SetTheme("Nocturne")
    t:WaitFor(function()
        return btn.Row.BackgroundColor3 == I.Themes.Nocturne.Element
    end, 1)
end)

suite:Test("KeySystem completes without keys or verification", function(t)
    local done = false
    local card = Kailex:KeySystem({ OnComplete = function() done = true end })
    t:Nil(card)
    t:True(done)
end)

suite:Test("KeySystem whitelisting bypasses the prompt", function(t)
    local result = nil
    Kailex:KeySystem({
        Silent = true,
        CheckWhitelist = function() return true end,
        OnComplete = function(key) result = key end,
    })
    t:Equal("WHITELISTED", result)
end)

suite:Test("KeySystem rejects wrong keys and accepts valid ones", function(t)
    local declined = false
    local granted = nil
    local card = Kailex:KeySystem({
        Title = "Gate",
        Key = "open123",
        Remember = false,
        MaxAttempts = 1,
        OnDecline = function() declined = true end,
        OnComplete = function(key) granted = key end,
    })
    t:Instance("CanvasGroup", card)
    local box = nil
    for _, ch in ipairs(card:GetDescendants()) do
        if ch:IsA("TextBox") then box = ch break end
    end
    t:NotNil(box)
    local verify = F.FindTextButton(card, "Verify")
    t:NotNil(verify)
    box.Text = "wrong"
    Sim.Click(verify)
    t:WaitFor(function() return declined end, 4)
    local card2 = Kailex:KeySystem({
        Title = "Gate2",
        Key = "open123",
        Remember = false,
        OnComplete = function(key) granted = key end,
    })
    t:NotNil(card2)
    local box2 = nil
    for _, ch in ipairs(card2:GetDescendants()) do
        if ch:IsA("TextBox") then box2 = ch break end
    end
    t:NotNil(box2)
    box2.Text = "open123"
    Sim.Click(F.FindTextButton(card2, "Verify"))
    t:WaitFor(function() return granted == "open123" end, 4)
end, "input")

suite:Test("The UI toggle key hides and shows everything", function(t)
    t:True(Kailex:IsVisible())
    Sim.Key(Enum.KeyCode.RightShift)
    t:WaitFor(function() return not Kailex:IsVisible() end, 2)
    Sim.Key(Enum.KeyCode.RightShift)
    t:WaitFor(function() return Kailex:IsVisible() end, 2)
end, "input")

suite:Test("Unload tears the library down cleanly", function(t)
    local gui = I.ScreenGui
    t:NotNil(gui)
    Kailex:Unload()
    t:WaitFor(function() return gui.Parent == nil end, 3)
    t:Equal(0, #Kailex.Windows)
    t:Equal(0, #I.ModalManager.Stack)
    t:Equal(0, #I.SoundInstances)
    t:WaitFor(function() return #I.InputHooks == 0 end, 3)
end)

return suite
