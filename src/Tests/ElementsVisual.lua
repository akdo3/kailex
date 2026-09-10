local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local I = F.Internal

local suite = F.Suite("Elements: Visual and Data")

local function freshTab(t)
    local win = F.NewWindow({ Title = "Visual" })
    t:Cleanup(win)
    return win, win:Tab({ Title = "T" })
end

suite:Test("ColorPicker Set and Get round trip", function(t)
    local _, tab = freshTab(t)
    local cp = tab:AddColorPicker({ Name = "C" })
    cp:Set(Color3.fromRGB(10, 20, 30))
    local got = cp:Get()
    t:Close(10, got.R * 255, 1)
    t:Close(20, got.G * 255, 1)
    t:Close(30, got.B * 255, 1)
    t:Equal(I.ColorToHex(got), cp:CopyValue())
end)

suite:Test("ColorPicker Reset restores the default", function(t)
    local _, tab = freshTab(t)
    local cp = tab:AddColorPicker({ Name = "C2", Default = Color3.fromRGB(255, 0, 0) })
    cp:Set(Color3.fromRGB(0, 255, 0))
    cp:Reset()
    t:Close(255, cp:Get().R * 255, 1)
end)

suite:Test("ColorPicker tracks recent colors", function(t)
    local _, tab = freshTab(t)
    local cp = tab:AddColorPicker({ Name = "C3" })
    cp:Set(Color3.fromRGB(255, 0, 0))
    local recents = I.SaveManager:Get("__recentColors", {})
    t:Table(recents)
    t:True(#recents > 0)
    t:Equal("#FF0000", recents[1])
end)

suite:Test("ColorPicker popup opens and closes on Escape", function(t)
    local _, tab = freshTab(t)
    local cp = tab:AddColorPicker({ Name = "C4" })
    local swatch = cp.RightContainer:FindFirstChildOfClass("TextButton")
    t:NotNil(swatch)
    Sim.Click(swatch)
    local popup = F.FindByZIndex(I.LayerOverlay, "CanvasGroup", 30)
    t:NotNil(popup)
    t:WaitFor(function() return popup.Visible end, 2)
    Sim.Key(Enum.KeyCode.Escape)
    t:WaitFor(function() return not popup.Visible end, 2)
end, "input")

suite:Test("ProgressBar animates to the requested value", function(t)
    local _, tab = freshTab(t)
    local pg = tab:AddProgressBar({ Name = "P", Max = 100, Value = 0 })
    pg:Set(50)
    t:WaitFor(function() return math.abs(pg:Get() - 50) < 1 end, 2)
end)

suite:Test("ProgressBar custom format", function(t)
    local _, tab = freshTab(t)
    local pg = tab:AddProgressBar({
        Name = "P2", Max = 100, Value = 0,
        Format = function(n) return n .. "u" end,
    })
    local label = nil
    for _, ch in ipairs(pg.RightContainer:GetChildren()) do
        if ch:IsA("TextLabel") then label = ch end
    end
    t:NotNil(label)
    pg:Set(25)
    t:Equal("25u", label.Text)
end)

suite:Test("ProgressBar indeterminate mode toggles safely", function(t)
    local _, tab = freshTab(t)
    local pg = tab:AddProgressBar({ Name = "P3", Max = 100 })
    pg:Set(true)
    pg:Set(false)
    pg:Set(10)
    t:WaitFor(function() return math.abs(pg:Get() - 10) < 1 end, 2)
end)

suite:Test("DataTable stores rows and preserves data", function(t)
    local _, tab = freshTab(t)
    local dt = tab:AddDataTable({
        Name = "DT",
        Columns = { { Name = "A" }, { Name = "B" } },
        Rows = { { 1, 2 }, { 3, 4 } },
        Height = 120,
    })
    local rows = dt:GetRows()
    t:Equal(2, #rows)
    t:Equal(1, rows[1][1])
end)

suite:Test("DataTable Sort only reorders the display", function(t)
    local _, tab = freshTab(t)
    local dt = tab:AddDataTable({
        Name = "DT2",
        Columns = { { Name = "A" }, { Name = "B" } },
        Rows = { { 3, 1 }, { 1, 2 }, { 2, 3 } },
        Height = 120,
    })
    dt:Sort(1, true)
    local rows = dt:GetRows()
    t:Equal(3, rows[1][1])
    t:Equal(1, rows[2][1])
end)

suite:Test("DataTable rows fire callbacks on click", function(t)
    local clicked = nil
    local _, tab = freshTab(t)
    local dt = tab:AddDataTable({
        Name = "DT3",
        Columns = { { Name = "A" } },
        Rows = { { "one" }, { "two" } },
        Height = 120,
        Callback = function(data, index) clicked = { data = data, index = index } end,
    })
    local canvas = dt.LeftFrame:FindFirstChildOfClass("ScrollingFrame")
    t:NotNil(canvas)
    local firstRow = nil
    for _, ch in ipairs(canvas:GetChildren()) do
        if ch:IsA("TextButton") then firstRow = ch break end
    end
    t:NotNil(firstRow)
    Sim.Click(firstRow)
    t:WaitFor(function() return clicked ~= nil end, 2)
    t:Equal(1, clicked.index)
    t:Equal("one", clicked.data[1])
end, "input")

suite:Test("Segmented selection via Set and click", function(t)
    local _, tab = freshTab(t)
    local sg = tab:AddSegmented({ Name = "SG", Options = { "x", "y" }, Default = "x" })
    t:Equal("x", sg:Get())
    sg:Set("y")
    t:Equal("y", sg:Get())
    local btnX = F.FindTextButton(sg.RightContainer, "x")
    t:NotNil(btnX)
    Sim.Click(btnX)
    t:WaitFor(function() return sg:Get() == "x" end, 2)
end, "input")

suite:Test("Segmented Reset restores the default", function(t)
    local _, tab = freshTab(t)
    local sg = tab:AddSegmented({ Name = "SG2", Options = { "x", "y" }, Default = "y" })
    sg:Set("x")
    sg:Reset()
    t:Equal("y", sg:Get())
end)

suite:Test("Vector3Input round trip", function(t)
    local _, tab = freshTab(t)
    local v = tab:AddVector3Input({ Name = "V", Default = Vector3.new(1, 2, 3) })
    t:Equal(Vector3.new(1, 2, 3), v:Get())
    v:Set(Vector3.new(4, 5, 6))
    t:Equal(Vector3.new(4, 5, 6), v:Get())
end)

suite:Test("Vector3Input boxes show formatted values", function(t)
    local _, tab = freshTab(t)
    local v = tab:AddVector3Input({ Name = "V2", Default = Vector3.new(7, 8, 9) })
    local boxes = {}
    for _, ch in ipairs(v.RightContainer:GetChildren()) do
        if ch:IsA("TextBox") then table.insert(boxes, ch) end
    end
    t:Equal(3, #boxes)
    t:Equal("7.00", boxes[1].Text)
    t:Equal("8.00", boxes[2].Text)
    t:Equal("9.00", boxes[3].Text)
end)

suite:Test("Vector3Input commits typed field values", function(t)
    local _, tab = freshTab(t)
    local v = tab:AddVector3Input({ Name = "V3", Default = Vector3.new(0, 0, 0) })
    local box = nil
    for _, ch in ipairs(v.RightContainer:GetChildren()) do
        if ch:IsA("TextBox") then box = ch break end
    end
    t:NotNil(box)
    box:CaptureFocus()
    t:Wait()
    box.Text = "9"
    box:ReleaseFocus()
    t:WaitFor(function() return v:Get().X == 9 end, 2)
end)

suite:Test("Vector3Input Reset falls back to the default", function(t)
    local _, tab = freshTab(t)
    local v = tab:AddVector3Input({ Name = "V4", Default = Vector3.new(1, 1, 1) })
    v:Set(Vector3.new(9, 9, 9))
    v:Reset()
    t:Equal(Vector3.new(1, 1, 1), v:Get())
end)

return suite
