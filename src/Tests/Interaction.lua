local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Interaction and Rendering")

suite:Test("ModalManager push and remove", function(t)
    local n0 = #I.ModalManager.Stack
    local e1 = I.ModalManager.Push(nil, function() end)
    t:Equal(n0 + 1, #I.ModalManager.Stack)
    I.ModalManager.Remove(e1)
    t:Equal(n0, #I.ModalManager.Stack)
    I.ModalManager.Remove(e1)
    t:Equal(n0, #I.ModalManager.Stack)
end)

suite:Test("ModalManager CloseAll respects owners", function(t)
    local ownerA, ownerB = {}, {}
    local closed = {}
    I.ModalManager.Push(ownerA, function() closed.a = true end)
    I.ModalManager.Push(ownerB, function() closed.b = true end)
    I.ModalManager.Push(nil, function() closed.c = true end)
    I.ModalManager.CloseAll(ownerA)
    t:True(closed.a)
    t:True(closed.c)
    t:Nil(closed.b)
    I.ModalManager.CloseAll()
    t:True(closed.b)
    t:Equal(0, #I.ModalManager.Stack)
end)

suite:Test("ModalManager CloseTop closes the newest entry", function(t)
    local order = {}
    I.ModalManager.Push(nil, function() table.insert(order, 1) end)
    I.ModalManager.Push(nil, function() table.insert(order, 2) end)
    t:True(I.ModalManager.CloseTop())
    t:Equal(1, #order)
    t:Equal(2, order[1])
    I.ModalManager.CloseAll()
    t:False(I.ModalManager.CloseTop())
    t:Equal(0, #I.ModalManager.Stack)
end)

suite:Test("ParseKey accepts keys and rejects non keys", function(t)
    t:Equal(Enum.KeyCode.F, I.ParseKey(Enum.KeyCode.F))
    t:Nil(I.ParseKey(Enum.UserInputType.MouseButton1))
    t:Equal(Enum.KeyCode.F, I.ParseKey("F"))
    t:Equal(Enum.KeyCode.F, I.ParseKey("Key:F"))
    t:Nil(I.ParseKey("Mouse:MouseButton1"))
    t:Nil(I.ParseKey("__none"))
    t:Nil(I.ParseKey(42))
end)

suite:Test("ToBinding resolves every binding format", function(t)
    local b1 = I.ToBinding(Enum.KeyCode.G)
    t:NotNil(b1)
    t:Equal("Key", b1.Kind)
    t:Equal(Enum.KeyCode.G, b1.Code)
    t:Equal("G", b1.Name)
    local b2 = I.ToBinding(Enum.UserInputType.MouseButton2)
    t:Equal("Mouse", b2.Kind)
    t:Equal("MouseButton2", b2.Name)
    local b3 = I.ToBinding("Key:H")
    t:Equal(Enum.KeyCode.H, b3.Code)
    local b4 = I.ToBinding("Mouse:MouseButton1")
    t:Equal(Enum.UserInputType.MouseButton1, b4.Code)
    local b5 = I.ToBinding("H")
    t:Equal(Enum.KeyCode.H, b5.Code)
    local b6 = I.ToBinding("key:H")
    t:Equal(Enum.KeyCode.H, b6.Code)
    t:Nil(I.ToBinding("Key:NotARealKey"))
    t:Nil(I.ToBinding(42))
end)

suite:Test("ClampToScreen pulls frames back on screen", function(t)
    local frame = I.Create("Frame", {
        Size = UDim2.fromOffset(120, 90),
        Position = UDim2.fromOffset(99999, 99999),
        Parent = I.LayerOverlay,
    })
    t:Cleanup(frame)
    I.ClampWindowToScreen(frame)
    t:True(frame.AbsolutePosition.X <= I.Viewport.X - 8)
    t:True(frame.AbsolutePosition.Y <= I.Viewport.Y - 8)
    t:True(frame.AbsolutePosition.X >= 8)
    t:Equal(I.ClampFloat, I.ClampWindowToScreen)
end, "layout")

suite:Test("BeginDrag rejects non pointer input", function(t)
    t:Nil(I.DragManager.Active)
    local fake = { UserInputType = Enum.UserInputType.Keyboard }
    t:Nil(I.BeginDrag(fake, I.LayerOverlay, {}))
    t:Nil(I.DragManager.Active)
end)

suite:Test("Ripple creates and cleans up after itself", function(t)
    local old = I.Setting.Effects
    I.Setting.Effects = true
    t:Defer(function() I.Setting.Effects = old end)
    local frame = I.Create("Frame", {
        Size = UDim2.fromOffset(80, 40),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = I.LayerOverlay,
    })
    t:Cleanup(frame)
    I.ApplyRipple(frame)
    t:NotNil(frame:GetAttribute("__rpl"))
    t:True(frame.ClipsDescendants)
    t:WaitFor(function() return frame:GetAttribute("__rpl") == nil end, 3)
    t:False(frame.ClipsDescendants)
end)

suite:Test("Icon builds every known glyph", function(t)
    local kinds = {
        "Minimize", "Close", "Chevron", "Search", "Grip", "Gear",
        "Check", "Reset", "ResizeH", "Pin", "Maximize", "Restore", "Alert", "Info",
    }
    local holder = I.Create("Frame", { BackgroundTransparency = 1, Parent = I.LayerOverlay })
    t:Cleanup(holder)
    for _, kind in ipairs(kinds) do
        local icon = I.Icon(holder, kind, "SubText")
        t:Instance("Frame", icon)
        t:True(#icon:GetChildren() > 0, kind .. " produced no children")
        icon:Destroy()
    end
    local unknown = I.Icon(holder, "DoesNotExist")
    t:Equal(0, #unknown:GetChildren())
    unknown:Destroy()
end)

suite:Test("DropShadow tracks position, visibility and lifetime", function(t)
    local frame = I.Create("Frame", {
        Size = UDim2.fromOffset(100, 100),
        Position = UDim2.fromOffset(60, 60),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = I.LayerOverlay,
    })
    t:Cleanup(frame)
    local shadow = I.DropShadow(frame, { Radius = 8 })
    t:NotNil(shadow)
    local holder = shadow.Holder
    t:Instance("Frame", holder)
    t:Equal(frame.Position, holder.Position)
    t:Equal(frame.Size, holder.Size)
    frame.Position = UDim2.fromOffset(120, 80)
    t:WaitFor(function() return holder.Position == frame.Position end, 2)
    shadow.SetFade(1)
    for _, ch in ipairs(holder:GetChildren()) do
        t:Equal(1, ch.BackgroundTransparency)
    end
    shadow.SetFade(0)
    for _, ch in ipairs(holder:GetChildren()) do
        t:True(ch.BackgroundTransparency < 1)
    end
    frame.Visible = false
    t:WaitFor(function() return not holder.Visible end, 2)
    frame.Visible = true
    t:WaitFor(function() return holder.Visible end, 2)
    frame:Destroy()
    t:WaitFor(function() return holder.Parent == nil end, 2)
end)

suite:Test("Tween plays and fires completion", function(t)
    local frame = I.Create("Frame", { BackgroundTransparency = 1, Parent = I.LayerOverlay })
    t:Cleanup(frame)
    local done = false
    local tween = I.Tween(frame, "Instant", { BackgroundTransparency = 0.5 }, function()
        done = true
    end)
    t:NotNil(tween)
    t:WaitFor(function() return done end, 2)
    t:Close(0.5, frame.BackgroundTransparency, 0.01)
    t:Nil(I.Tween(nil, "Fast", { BackgroundTransparency = 0.5 }))
end)

suite:Test("Tween respects MotionScale", function(t)
    local frame = I.Create("Frame", { BackgroundTransparency = 1, Parent = I.LayerOverlay })
    t:Cleanup(frame)
    local old = I.Setting.MotionScale
    I.Setting.MotionScale = 0.5
    t:Defer(function() I.Setting.MotionScale = old end)
    local done = false
    I.Tween(frame, "Instant", { BackgroundTransparency = 0.2 }, function() done = true end)
    local start = os.clock()
    t:WaitFor(function() return done end, 2)
    local elapsed = os.clock() - start
    t:True(elapsed < 0.09, "scaled tween took too long: " .. tostring(elapsed))
end)

suite:Test("FX.Shake returns to the original position", function(t)
    local frame = I.Create("Frame", { Size = UDim2.fromOffset(20, 20), Parent = I.LayerOverlay })
    t:Cleanup(frame)
    local original = frame.Position
    I.FX.Shake(frame, 6)
    t:WaitFor(function()
        return math.abs(frame.Position.X.Offset - original.X.Offset) < 0.5
            and math.abs(frame.Position.Y.Offset - original.Y.Offset) < 0.5
    end, 3)
end)

suite:Test("RunCallback fires synchronously by default", function(t)
    local value = 0
    I.RunCallback(function() value = 5 end)
    t:Equal(5, value)
end)

suite:Test("RunCallback swallows callback errors", function(t)
    t:NoError(function() I.RunCallback(function() error("callback failure") end) end)
end)

suite:Test("RunCallback supports async mode", function(t)
    local old = I.Setting.AsyncCallbacks
    I.Setting.AsyncCallbacks = true
    t:Defer(function() I.Setting.AsyncCallbacks = old end)
    local flag = false
    I.RunCallback(function() flag = true end)
    t:WaitFor(function() return flag end, 1)
end)

suite:Test("CopyToClipboard notifies when clipboard is unavailable", function(t)
    I.CopyToClipboard("ABC123")
    local log = Kailex:GetNotificationLog()
    t:True(#log > 0)
    t:Contains({ "Copy", "Copied" }, log[#log].Title)
    t:True(log[#log].Text:find("ABC123", 1, true) ~= nil)
end)

suite:Test("Input hooks register and remove cleanly", function(t)
    local n0 = #I.InputHooks
    local rec = I.AddInputHook(function() return false end, function() end)
    t:Equal(n0 + 1, #I.InputHooks)
    I.RemoveInputHook(rec)
    t:Equal(n0, #I.InputHooks)
    I.RemoveInputHook(rec)
    t:Equal(n0, #I.InputHooks)
end)

return suite
