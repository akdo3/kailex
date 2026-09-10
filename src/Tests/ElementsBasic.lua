local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Elements: Basic")

local function freshTab(t)
    local win = F.NewWindow({ Title = "Basic" })
    t:Cleanup(win)
    return win, win:Tab({ Title = "T" })
end

suite:Test("Label stores and updates text", function(t)
    local _, tab = freshTab(t)
    local label = tab:AddLabel({ Text = "First" })
    t:Equal("First", label.TextLabel.Text)
    label:Set("Second")
    t:Equal("Second", label.TextLabel.Text)
    t:Equal("Second", label.Title)
end)

suite:Test("Paragraph renders title and body separately", function(t)
    local _, tab = freshTab(t)
    local par = tab:AddParagraph({ Title = "Head", Text = "Body" })
    t:Equal("Head", par.TitleLabel.Text)
    t:Equal("Body", par.BodyLabel.Text)
    par:Set("NewBody")
    t:Equal("NewBody", par.BodyLabel.Text)
    t:Equal("Head", par.TitleLabel.Text)
end)

suite:Test("Divider supports optional text", function(t)
    local _, tab = freshTab(t)
    local d1 = tab:AddDivider({ Text = "Split" })
    local labels = 0
    for _, ch in ipairs(d1.Row:GetChildren()) do
        if ch:IsA("TextLabel") then labels += 1 end
    end
    t:Equal(1, labels)
    local d2 = tab:AddDivider()
    labels = 0
    for _, ch in ipairs(d2.Row:GetChildren()) do
        if ch:IsA("TextLabel") then labels += 1 end
    end
    t:Equal(0, labels)
end)

suite:Test("Divider respects width fractions", function(t)
    local _, tab = freshTab(t)
    local d = tab:AddDivider({ Width = 0.5 })
    t:Close(0.5, d.Row.Size.X.Scale, 0.001)
end)

suite:Test("Sections register and track their elements", function(t)
    local _, tab = freshTab(t)
    local section = tab:AddSection("Group")
    t:Equal(section, tab.CurrentSection)
    local found = false
    for _, s in ipairs(tab.Sections) do
        if s == section then found = true end
    end
    t:True(found)
    local btn = tab:AddButton({ Name = "Inside" })
    t:Equal(section, btn.Section)
    t:Equal(1, #section.Elements)
end)

suite:Test("Section collapse hides and reveals rows", function(t)
    local _, tab = freshTab(t)
    local section = tab:AddSection("Collapse")
    local tgl = tab:AddToggle({ Name = "Member" })
    section:SetCollapsed(true)
    t:False(tgl.Row.Visible)
    section:SetCollapsed(false)
    t:True(tgl.Row.Visible)
    tgl:Visible(false)
    section:SetCollapsed(true)
    section:SetCollapsed(false)
    t:False(tgl.Row.Visible)
end)

suite:Test("Section destroy detaches from the tab", function(t)
    local _, tab = freshTab(t)
    local section = tab:AddSection("Temp")
    section:Destroy()
    local found = false
    for _, s in ipairs(tab.Sections) do
        if s == section then found = true end
    end
    t:False(found)
    t:Nil(tab.CurrentSection)
end)

suite:Test("Section titles are uppercased", function(t)
    local _, tab = freshTab(t)
    local section = tab:AddSection({ Name = "lower" })
    t:Equal("LOWER", section.TitleLabel.Text)
end)

suite:Test("Button fires its callback on click", function(t)
    local _, tab = freshTab(t)
    local fired = 0
    local btn = tab:AddButton({ Name = "Click", Callback = function() fired += 1 end })
    Sim.Click(btn.Row)
    t:WaitFor(function() return fired == 1 end, 2)
end, "input")

suite:Test("Button SetCallback replaces the handler", function(t)
    local _, tab = freshTab(t)
    local a, b = false, false
    local btn = tab:AddButton({ Name = "Swap", Callback = function() a = true end })
    btn:SetCallback(function() b = true end)
    btn.Callback()
    t:True(b)
    t:False(a)
end)

suite:Test("Button busy state toggles the spinner", function(t)
    local _, tab = freshTab(t)
    local btn = tab:AddButton({ Name = "Busy" })
    btn:SetBusy(true)
    t:True(btn._busy)
    btn:SetBusy(false)
    t:False(btn._busy)
end)

suite:Test("Button HandleAsync wraps tasks with busy state", function(t)
    local _, tab = freshTab(t)
    local done = false
    local btn = tab:AddButton({ Name = "Async" })
    btn:HandleAsync(function()
        task.wait(0.05)
        done = true
    end)
    t:True(btn._busy)
    t:WaitFor(function() return done and not btn._busy end, 2)
end)

suite:Test("Button HandleAsync reports task errors", function(t)
    local _, tab = freshTab(t)
    local btn = tab:AddButton({ Name = "Err" })
    btn:HandleAsync(function()
        error("boom")
    end)
    t:WaitFor(function()
        local log = Kailex:GetNotificationLog()
        return #log > 0 and log[#log].Title == "Task error"
    end, 2)
    t:WaitFor(function() return not btn._busy end, 2)
end)

suite:Test("Button confirm path requires acceptance", function(t)
    local _, tab = freshTab(t)
    local fired = false
    local btn = tab:AddButton({
        Name = "ConfirmMe",
        Confirm = "are you sure",
        Callback = function() fired = true end,
    })
    Sim.Click(btn.Row)
    t:WaitFor(function() return #I.ModalManager.Stack > 0 end, 2)
    I.ModalManager.CloseTop()
    t:False(fired)
end, "input")

suite:Test("Button confirm path fires after Enter", function(t)
    local _, tab = freshTab(t)
    local fired = false
    local btn = tab:AddButton({
        Name = "ConfirmEnter",
        Confirm = "are you sure",
        Callback = function() fired = true end,
    })
    Sim.Click(btn.Row)
    t:WaitFor(function() return #I.ModalManager.Stack > 0 end, 2)
    Sim.Key(Enum.KeyCode.Return)
    t:WaitFor(function() return fired end, 2)
end, "input")

suite:Test("Button supports built-in icon names", function(t)
    local _, tab = freshTab(t)
    local btn = tab:AddButton({ Name = "Iconed", Icon = "Check" })
    local holder = btn.RightContainer:FindFirstChildOfClass("TextButton")
    t:NotNil(holder)
    t:True(#holder:GetChildren() > 0)
end)

suite:Test("Button AddToggle attaches an enabling toggle", function(t)
    local _, tab = freshTab(t)
    local btn = tab:AddButton({ Name = "Combo" })
    local tgl = btn:AddToggle({ Default = true })
    t:NotNil(tgl)
    t:True(btn:IsEnabled())
    btn:SetEnabled(false, true)
    t:False(btn:IsEnabled())
    t:NotNil(btn.Enabled)
end)

suite:Test("Toggle Set and Get round trip", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "T", Default = false })
    t:False(tgl:Get())
    tgl:Set(true)
    t:True(tgl:Get())
    tgl:Set(true)
    t:True(tgl:Get())
end)

suite:Test("Toggle fires callback and signal with silent support", function(t)
    local _, tab = freshTab(t)
    local calls, signals = 0, 0
    local tgl = tab:AddToggle({ Name = "T2", Callback = function() calls += 1 end })
    tgl.Changed:Connect(function() signals += 1 end)
    tgl:Set(true)
    tgl:Set(false, true)
    t:Equal(1, calls)
    t:Equal(2, signals)
end)

suite:Test("Toggle Reset restores the default", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "T3", Default = true })
    tgl:Set(false, true)
    tgl:Reset()
    t:True(tgl:Get())
end)

suite:Test("Toggle toggles on click", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "T4" })
    Sim.Click(tgl.Row)
    t:WaitFor(function() return tgl:Get() == true end, 2)
end, "input")

suite:Test("Toggle ignores clicks while disabled", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "T5" })
    tgl:SetDisabled(true)
    t:True(tgl:IsDisabled())
    Sim.Click(tgl.Row)
    t:Wait(0.15)
    t:False(tgl:Get())
    tgl:SetDisabled(false)
    t:False(tgl:IsDisabled())
end, "input")

suite:Test("Toggle pin creates and destroys a quick widget", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "Pinned", Pin = true })
    local pinBtn = nil
    for _, ch in ipairs(tgl.RightContainer:GetChildren()) do
        if ch:IsA("TextButton") then pinBtn = ch end
    end
    t:NotNil(pinBtn)
    I.QuickWidgets.Toggle(tgl)
    t:NotNil(I.QuickWidgets.Active[tgl])
    tgl:Destroy()
    t:Nil(I.QuickWidgets.Active[tgl])
end)

suite:Test("Element context menus expose copy, reset and disable", function(t)
    local _, tab = freshTab(t)
    local tgl = tab:AddToggle({ Name = "Ctx" })
    local texts = {}
    for _, item in ipairs(tgl:_contextItems()) do
        table.insert(texts, item.Text)
    end
    t:Contains(texts, "Copy value")
    t:Contains(texts, "Reset to default")
    t:Contains(texts, "Disable")
end)

suite:Test("Element Destroy removes it from the tab", function(t)
    local _, tab = freshTab(t)
    local btn = tab:AddButton({ Name = "Doomed" })
    local n0 = #tab.Elements
    btn:Destroy()
    t:Equal(n0 - 1, #tab.Elements)
    t:Nil(btn.Row)
end)

return suite
