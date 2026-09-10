local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Window and Tabs")

local function findSearchBox(win)
    for _, ch in ipairs(win.TitleBar:GetChildren()) do
        if ch:IsA("TextBox") then return ch end
    end
    return nil
end

suite:Test("CreateWindow builds a clamped root", function(t)
    local win = F.NewWindow({ Title = "W1", Size = Vector2.new(5000, 5000) })
    t:Cleanup(win)
    t:Equal("W1", win.Title)
    t:Instance("CanvasGroup", win.Root)
    t:True(win.Root.Size.X.Offset <= I.Viewport.X / I.GetScale() - 11)
    t:True(win.Root.Size.Y.Offset <= I.Viewport.Y / I.GetScale() - 11)
    local found = false
    for _, w in ipairs(Kailex.Windows) do
        if w == win then found = true end
    end
    t:True(found)
end)

suite:Test("Window icons and custom save prefixes", function(t)
    local win = F.NewWindow({ Title = "W2", SaveKey = "CustomPrefix", Icon = "Gear" })
    t:Cleanup(win)
    t:NotNil(win.IconImg)
    t:Equal("CustomPrefix", win.SavePrefix)
end)

suite:Test("First tab is selected automatically", function(t)
    local win = F.NewWindow({ Title = "W3" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    t:Equal(tab, win.CurrentTab)
    t:True(tab.Page.Visible)
end)

suite:Test("Tab switching swaps visible pages", function(t)
    local win = F.NewWindow({ Title = "W4" })
    t:Cleanup(win)
    local t1 = win:Tab({ Title = "A" })
    local t2 = win:Tab({ Title = "B" })
    t2:Select()
    t:Equal(t2, win.CurrentTab)
    t:True(t2.Page.Visible)
    t:WaitFor(function() return not t1.Page.Visible end, 2)
end)

suite:Test("ApplyFilter hides non matching rows", function(t)
    local win = F.NewWindow({ Title = "W5" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    local alpha = tab:AddButton({ Name = "AlphaButton" })
    local beta = tab:AddButton({ Name = "BetaButton" })
    tab:Select()
    win:ApplyFilter("alpha")
    t:True(alpha.Row.Visible)
    t:False(beta.Row.Visible)
    win:ApplyFilter("")
    t:True(alpha.Row.Visible)
    t:True(beta.Row.Visible)
end)

suite:Test("Filter badges count matches in other tabs", function(t)
    local win = F.NewWindow({ Title = "W6" })
    t:Cleanup(win)
    local t1 = win:Tab({ Title = "A" })
    local t2 = win:Tab({ Title = "B" })
    t2:AddButton({ Name = "NeedleItem" })
    t1:Select()
    win:ApplyFilter("needle")
    t:Equal("1", t2.Badge.Text)
    t:True(t2.Badge.Visible)
end)

suite:Test("GetSaveKey generates unique keys for duplicates", function(t)
    local win = F.NewWindow({ Title = "W7" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    local k1 = tab:GetSaveKey({ Name = "Same" })
    local k2 = tab:GetSaveKey({ Name = "Same" })
    t:NotEqual(k1, k2)
    t:Equal(" #2", k2:sub(-3))
end)

suite:Test("Minimize collapses to a pill and restores", function(t)
    local win = F.NewWindow({ Title = "W8" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    tab:AddButton({ Name = "X" })
    local fullH = win.Root.Size.Y.Offset
    win:SetMinimized(true)
    t:True(win.Minimized)
    t:False(win.Body.Visible)
    t:WaitFor(function() return win.Root.Size.Y.Offset < 60 end, 2)
    win:SetMinimized(false)
    t:WaitFor(function() return win.Body.Visible and not win.Minimized end, 2)
    t:Close(fullH, win.Root.Size.Y.Offset, 2)
end)

suite:Test("Maximize fills the viewport and restores", function(t)
    local win = F.NewWindow({ Title = "W9", Size = Vector2.new(400, 320) })
    t:Cleanup(win)
    local original = win.Root.Size.X.Offset
    win:SetMaximized(true)
    t:WaitFor(function()
        return win.Root.Size.X.Offset >= I.Viewport.X / I.GetScale() - 20
    end, 2)
    win:SetMaximized(false)
    t:WaitFor(function() return math.abs(win.Root.Size.X.Offset - original) < 2 end, 2)
end)

suite:Test("ToggleHidden hides and reveals the root", function(t)
    local win = F.NewWindow({ Title = "W10" })
    t:Cleanup(win)
    win:ToggleHidden()
    t:False(win.Root.Visible)
    win:ToggleHidden()
    t:True(win.Root.Visible)
end)

suite:Test("Destroy removes the window from the registry", function(t)
    local win = F.NewWindow({ Title = "W11" })
    win:Destroy()
    t:WaitFor(function() return win.Root.Parent == nil end, 2)
    local found = false
    for _, w in ipairs(Kailex.Windows) do
        if w == win then found = true end
    end
    t:False(found)
end)

suite:Test("Always on top pins the window above others", function(t)
    local w1 = F.NewWindow({ Title = "W12" })
    local w2 = F.NewWindow({ Title = "W13" })
    t:Cleanup(w2)
    t:Cleanup(w1)
    w2._focus()
    t:True(w2.Root.ZIndex > w1.Root.ZIndex)
    local z = w2.Root.ZIndex
    w2._focus()
    t:Equal(z, w2.Root.ZIndex)
    w2._alwaysTop = true
    w2._focus()
    t:Equal(100, w2.Root.ZIndex)
    w2._alwaysTop = false
    w2._focus()
    t:True(w2.Root.ZIndex <= 99)
end)

suite:Test("Sidebar width is clamped to the layout", function(t)
    local win = F.NewWindow({ Title = "W14", Size = Vector2.new(560, 380) })
    t:Cleanup(win)
    win:SetSidebarWidth(9999)
    t:Equal(320, win._sidebarWidth)
    win:SetSidebarWidth(5)
    t:Equal(110, win._sidebarWidth)
end)

suite:Test("Narrow windows switch to a horizontal tab bar", function(t)
    local win = F.NewWindow({ Title = "W15", Size = Vector2.new(420, 360) })
    t:Cleanup(win)
    win:Tab({ Title = "One" })
    win:Tab({ Title = "Two" })
    t:WaitFor(function()
        return win.Sidebar.Visible and win.Sidebar.Size.Y.Offset == 44
    end, 3)
end)

suite:Test("Clicking a window raises it above others", function(t)
    local w1 = F.NewWindow({ Title = "W16" })
    local w2 = F.NewWindow({ Title = "W17" })
    t:Cleanup(w2)
    t:Cleanup(w1)
    Sim.Click(w2.Root)
    t:WaitFor(function() return w2.Root.ZIndex > w1.Root.ZIndex end, 2)
    t:Equal(w2, Kailex._lastActive)
end, "input")

suite:Test("Ctrl+F focuses the search of the active window", function(t)
    local win = F.NewWindow({ Title = "W18" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    local btn = tab:AddButton({ Name = "Searchable" })
    Sim.Click(btn.Row)
    t:WaitFor(function() return Kailex._lastActive == win end, 2)
    Sim.Key(Enum.KeyCode.F, true)
    local search = findSearchBox(win)
    t:NotNil(search)
    t:WaitFor(function() return search.Visible end, 2)
    Sim.Key(Enum.KeyCode.Escape)
    t:WaitFor(function() return not search.Visible end, 2)
end, "input")

suite:Test("Search filters elements through the debounce", function(t)
    local win = F.NewWindow({ Title = "W19" })
    t:Cleanup(win)
    local tab = win:Tab({ Title = "A" })
    local a = tab:AddButton({ Name = "FindMe" })
    local b = tab:AddButton({ Name = "Hidden" })
    tab:Select()
    win:_setSearch(true)
    local search = findSearchBox(win)
    t:NotNil(search)
    search.Text = "find"
    t:WaitFor(function() return a.Row.Visible and not b.Row.Visible end, 2)
    win:_setSearch(false)
    t:WaitFor(function() return a.Row.Visible and b.Row.Visible end, 2)
end)

return suite
