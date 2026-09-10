local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local I = F.Internal

local suite = F.Suite("Elements: Values")

local function freshTab(t)
    local win = F.NewWindow({ Title = "Values" })
    t:Cleanup(win)
    return win, win:Tab({ Title = "T" })
end

local function findSliderTrack(el)
    for _, ch in ipairs(el.LeftFrame:GetChildren()) do
        if ch:IsA("Frame") and ch.Size.Y.Offset == 6 then return ch end
    end
    return nil
end

suite:Test("Slider Set snaps to the step grid", function(t)
    local _, tab = freshTab(t)
    local sld = tab:AddSlider({ Name = "S", Min = 0, Max = 10, Default = 0 })
    sld:Set(5.4)
    t:Equal(5, sld:Get())
    sld:Set(-20)
    t:Equal(0, sld:Get())
    sld:Set(999)
    t:Equal(10, sld:Get())
end)

suite:Test("Slider formats decimals from the increment", function(t)
    local _, tab = freshTab(t)
    local sld = tab:AddSlider({ Name = "S2", Min = 0, Max = 1, Increment = 0.05, Default = 0.5 })
    t:Equal("0.50", sld:CopyValue())
end)

suite:Test("Slider callback fires on programmatic Set", function(t)
    local _, tab = freshTab(t)
    local v = nil
    local sld = tab:AddSlider({ Name = "S3", Min = 0, Max = 10, Callback = function(x) v = x end })
    sld:Set(3)
    t:Equal(3, v)
    v = nil
    sld:Set(3, true)
    t:Nil(v)
end)

suite:Test("Slider keyboard arrows move by step", function(t)
    local _, tab = freshTab(t)
    local sld = tab:AddSlider({ Name = "S4", Min = 0, Max = 10, Default = 5, Increment = 1 })
    sld:HandleArrow(1)
    t:Equal(6, sld:Get())
    sld:HandleArrow(-1)
    t:Equal(5, sld:Get())
    sld:HandleArrow(10)
    t:Equal(10, sld:Get())
end)

suite:Test("Slider Reset restores the default", function(t)
    local _, tab = freshTab(t)
    local sld = tab:AddSlider({ Name = "S5", Min = 0, Max = 10, Default = 4 })
    sld:Set(9)
    sld:Reset()
    t:Equal(4, sld:Get())
end)

suite:Test("Slider text box commits typed values", function(t)
    local _, tab = freshTab(t)
    local sld = tab:AddSlider({ Name = "S6", Min = 0, Max = 10, Default = 0 })
    local box = sld.LeftFrame:FindFirstChildOfClass("TextBox")
    t:NotNil(box)
    box:CaptureFocus()
    t:Wait()
    box.Text = "7"
    box:ReleaseFocus()
    t:WaitFor(function() return sld:Get() == 7 end, 2)
end)

suite:Test("Slider drag updates the value live", function(t)
    local _, tab = freshTab(t)
    local calls = 0
    local sld = tab:AddSlider({
        Name = "S7", Min = 0, Max = 10, Default = 0,
        Callback = function() calls += 1 end,
    })
    local track = findSliderTrack(sld)
    t:NotNil(track)
    local center = track.AbsolutePosition + track.AbsoluteSize / 2
    Sim.DragFromTo(center.X, center.Y, center.X + 80, center.Y)
    t:WaitFor(function() return sld:Get() > 0 and calls > 0 end, 3)
end, "input")

suite:Test("Slider FireOnRelease defers the callback", function(t)
    local _, tab = freshTab(t)
    local calls = 0
    local sld = tab:AddSlider({
        Name = "S8", Min = 0, Max = 10, Default = 0,
        FireOnRelease = true, Callback = function() calls += 1 end,
    })
    local track = findSliderTrack(sld)
    t:NotNil(track)
    local center = track.AbsolutePosition + track.AbsoluteSize / 2
    Sim.DragFromTo(center.X, center.Y, center.X + 80, center.Y)
    t:Wait(0.3)
    t:Equal(1, calls)
end, "input")

suite:Test("Stepper clamps values", function(t)
    local _, tab = freshTab(t)
    local st = tab:AddStepper({ Name = "St", Min = 0, Max = 50, Step = 1, Default = 10 })
    st:Set(200)
    t:Equal(50, st:Get())
    st:Set(-5)
    t:Equal(0, st:Get())
    st:Set(12)
    t:Equal(12, st:Get())
end)

suite:Test("Stepper buttons change the value", function(t)
    local _, tab = freshTab(t)
    local st = tab:AddStepper({ Name = "St2", Min = 0, Max = 50, Step = 1, Default = 10 })
    local plus = F.FindTextButton(st.RightContainer, "+")
    local minus = F.FindTextButton(st.RightContainer, "-")
    t:NotNil(plus)
    t:NotNil(minus)
    Sim.Click(plus)
    t:WaitFor(function() return st:Get() == 11 end, 2)
    Sim.Click(minus)
    t:WaitFor(function() return st:Get() == 10 end, 2)
end, "input")

suite:Test("Stepper Reset and custom formatting", function(t)
    local _, tab = freshTab(t)
    local st = tab:AddStepper({
        Name = "St3", Min = 0, Max = 10, Default = 3,
        Format = function(v) return "|" .. v .. "|" end,
    })
    local label = nil
    for _, ch in ipairs(st.RightContainer:GetChildren()) do
        if ch:IsA("TextLabel") then label = ch end
    end
    t:NotNil(label)
    t:Equal("|3|", label.Text)
    st:Set(5)
    t:Equal("|5|", label.Text)
    st:Reset()
    t:Equal(3, st:Get())
end)

suite:Test("Dropdown single selection round trip", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D", Options = { "a", "b", "c" } })
    t:Nil(dp:Get())
    dp:Set("b")
    t:Equal("b", dp:Get())
    t:Equal("b", dp:GetText())
    t:Equal("b", dp:CopyValue())
end)

suite:Test("Dropdown multi selection returns arrays", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D2", Options = { "a", "b", "c" }, Multi = true })
    dp:Set({ "a", "c" })
    local values = dp:Get()
    t:Table(values)
    t:Equal(2, #values)
    t:Contains(values, "a")
    t:Contains(values, "c")
    local texts = dp:GetText()
    t:Table(texts)
    t:Contains(texts, "a")
    t:Contains(texts, "c")
end)

suite:Test("Dropdown Reset restores defaults", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D3", Options = { "a", "b", "c" }, Default = "b" })
    dp:Set("a")
    dp:Reset()
    t:Equal("b", dp:Get())
end)

suite:Test("Dropdown SetOptions filters stale selections", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D4", Options = { "a", "b" } })
    dp:Set("b")
    dp:SetOptions({ 1, 2 })
    t:Nil(dp:Get())
    dp:Set(2)
    t:Equal(2, dp:Get())
end)

suite:Test("Dropdown opens and closes from the row", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D5", Options = { "a", "b" } })
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown ~= nil end, 2)
    local list = F.FindByZIndex(I.LayerOverlay, "CanvasGroup", 100)
    t:NotNil(list)
    t:True(list.Visible)
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown == nil end, 2)
end, "input")

suite:Test("Dropdown closes on Escape", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D6", Options = { "a", "b" } })
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown ~= nil end, 2)
    Sim.Key(Enum.KeyCode.Escape)
    t:WaitFor(function() return tab._openDropdown == nil end, 2)
end, "input")

suite:Test("Dropdown keyboard navigation selects options", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D7", Options = { "a", "b", "c" } })
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown ~= nil end, 2)
    Sim.Key(Enum.KeyCode.Down)
    Sim.Key(Enum.KeyCode.Return)
    t:WaitFor(function() return dp:Get() == "a" end, 2)
    t:Nil(tab._openDropdown)
end, "input")

suite:Test("Dropdown multi select All and None", function(t)
    local _, tab = freshTab(t)
    local dp = tab:AddDropdown({ Name = "D8", Options = { "a", "b" }, Multi = true })
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown ~= nil end, 2)
    local list = F.FindByZIndex(I.LayerOverlay, "CanvasGroup", 100)
    local allBtn = F.FindTextButton(list, "All")
    t:NotNil(allBtn)
    Sim.Click(allBtn)
    t:WaitFor(function() return #dp:Get() == 2 end, 2)
    local noneBtn = F.FindTextButton(list, "None")
    t:NotNil(noneBtn)
    Sim.Click(noneBtn)
    t:WaitFor(function() return #dp:Get() == 0 end, 2)
end, "input")

suite:Test("Dropdown search narrows the option list", function(t)
    local _, tab = freshTab(t)
    local options = {}
    for i = 1, 15 do
        table.insert(options, "opt" .. i)
    end
    table.insert(options, "uniquezzz")
    local dp = tab:AddDropdown({ Name = "D9", Options = options })
    Sim.Click(dp.Row)
    t:WaitFor(function() return tab._openDropdown ~= nil end, 2)
    local list = F.FindByZIndex(I.LayerOverlay, "CanvasGroup", 100)
    local search = nil
    for _, ch in ipairs(list:GetDescendants()) do
        if ch:IsA("TextBox") then search = ch break end
    end
    t:NotNil(search)
    search.Text = "uniquezzz"
    t:WaitFor(function()
        local count = 0
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("ScrollingFrame") then
                for _, c2 in ipairs(ch:GetChildren()) do
                    if c2:IsA("TextButton") then count += 1 end
                end
            end
        end
        return count == 1
    end, 2)
    dp:Set("uniquezzz")
    t:Equal("uniquezzz", dp:Get())
end, "input")

suite:Test("TextInput Set and Get", function(t)
    local _, tab = freshTab(t)
    local inp = tab:AddTextInput({ Name = "TI" })
    inp:Set("hello")
    t:Equal("hello", inp:Get())
    t:Equal("hello", inp:CopyValue())
end)

suite:Test("TextInput validator rejects bad input", function(t)
    local _, tab = freshTab(t)
    local inp = tab:AddTextInput({
        Name = "V",
        Validator = function(text) return #text <= 3 end,
    })
    inp:Set("ab")
    local box = inp.RightContainer:FindFirstChildOfClass("TextBox")
    t:NotNil(box)
    box:CaptureFocus()
    t:Wait()
    box.Text = "toolong"
    box:ReleaseFocus()
    t:Wait()
    t:Equal("ab", inp:Get())
    t:Equal("ab", box.Text)
end)

suite:Test("TextInput Reset and disabled state", function(t)
    local _, tab = freshTab(t)
    local inp = tab:AddTextInput({ Name = "R", Default = "start" })
    inp:Set("changed")
    inp:Reset()
    t:Equal("start", inp:Get())
    inp:SetDisabled(true)
    local box = inp.RightContainer:FindFirstChildOfClass("TextBox")
    t:False(box.TextEditable)
    inp:SetDisabled(false)
    t:True(box.TextEditable)
end)

suite:Test("Keybind loads defaults and Set updates", function(t)
    local _, tab = freshTab(t)
    local kb = tab:AddKeybind({ Name = "K", Default = Enum.KeyCode.F })
    t:Equal(Enum.KeyCode.F, kb:Get())
    t:Equal("F", kb:GetName())
    kb:Set(Enum.KeyCode.G)
    t:Equal(Enum.KeyCode.G, kb:Get())
    t:Equal("G", kb:CopyValue())
    kb:Reset()
    t:Equal(Enum.KeyCode.F, kb:Get())
end)

suite:Test("Keybind context menu can clear the binding", function(t)
    local _, tab = freshTab(t)
    local kb = tab:AddKeybind({ Name = "K2", Default = Enum.KeyCode.F })
    local clear = nil
    for _, item in ipairs(kb:_contextItems()) do
        if item.Text == "Clear keybind" then clear = item end
    end
    t:NotNil(clear)
    clear.Callback()
    t:Nil(kb:Get())
end)

suite:Test("Keybind press mode fires on key down", function(t)
    local _, tab = freshTab(t)
    local code = nil
    local kb = tab:AddKeybind({ Name = "K3", Callback = function(c) code = c end })
    kb:Set(Enum.KeyCode.H)
    Sim.Key(Enum.KeyCode.H)
    t:WaitFor(function() return code == Enum.KeyCode.H end, 2)
end, "input")

suite:Test("Keybind toggle mode alternates state", function(t)
    local _, tab = freshTab(t)
    local state = nil
    local kb = tab:AddKeybind({
        Name = "K4", Mode = "Toggle",
        Callback = function(_, on) state = on end,
    })
    kb:Set(Enum.KeyCode.H)
    Sim.Key(Enum.KeyCode.H)
    t:WaitFor(function() return state == true end, 2)
    Sim.Key(Enum.KeyCode.H)
    t:WaitFor(function() return state == false end, 2)
    t:False(kb:GetState())
end, "input")

suite:Test("Keybind hold mode fires on press and release", function(t)
    local _, tab = freshTab(t)
    local states = {}
    local kb = tab:AddKeybind({
        Name = "K5", Mode = "Hold",
        Callback = function(_, on) table.insert(states, on) end,
    })
    kb:Set(Enum.KeyCode.H)
    Sim.KeyDown(Enum.KeyCode.H)
    Sim.KeyUp(Enum.KeyCode.H)
    t:WaitFor(function() return #states >= 2 end, 2)
    t:True(states[1])
    t:False(states[#states])
end, "input")

suite:Test("Keybind listening captures the next key", function(t)
    local _, tab = freshTab(t)
    local kb = tab:AddKeybind({ Name = "K6" })
    local btn = kb.RightContainer:FindFirstChildOfClass("TextButton")
    t:NotNil(btn)
    Sim.Click(btn)
    t:WaitFor(function() return I.ActiveKeybindListener == kb end, 2)
    Sim.Key(Enum.KeyCode.J)
    t:WaitFor(function() return kb:Get() == Enum.KeyCode.J end, 2)
end, "input")

return suite
