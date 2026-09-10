local F = require(script.Parent.Framework)
local I = F.Internal

local suite = F.Suite("Core Primitives")

suite:Test("Signal Connect fires with arguments", function(t)
    local s = I.Signal.new()
    local a, b
    s:Connect(function(x, y) a, b = x, y end)
    s:Fire(1, "two")
    t:Equal(1, a)
    t:Equal("two", b)
end)

suite:Test("Signal fires every handler", function(t)
    local s = I.Signal.new()
    local count = 0
    s:Connect(function() count += 1 end)
    s:Connect(function() count += 10 end)
    s:Fire()
    t:Equal(11, count)
end)

suite:Test("Signal Disconnect stops a handler", function(t)
    local s = I.Signal.new()
    local count = 0
    local conn = s:Connect(function() count += 1 end)
    s:Fire()
    conn:Disconnect()
    s:Fire()
    t:Equal(1, count)
end)

suite:Test("Signal Once fires a single time", function(t)
    local s = I.Signal.new()
    local count = 0
    s:Once(function() count += 1 end)
    s:Fire()
    s:Fire()
    t:Equal(1, count)
end)

suite:Test("Signal Wait resumes with values", function(t)
    local s = I.Signal.new()
    local result
    task.spawn(function() result = s:Wait() end)
    task.wait()
    s:Fire(42)
    task.wait()
    t:Equal(42, result)
end)

suite:Test("Signal Destroy disconnects everything", function(t)
    local s = I.Signal.new()
    local conn = s:Connect(function() end)
    s:Destroy()
    t:False(conn.Connected)
    local count = 0
    s:Connect(function() count += 1 end)
    s:Fire()
    t:Equal(0, count)
end)

suite:Test("Signal handler errors do not stop other handlers", function(t)
    local s = I.Signal.new()
    local ok = false
    s:Connect(function() error("handler failure") end)
    s:Connect(function() ok = true end)
    s:Fire()
    t:True(ok)
end)

suite:Test("Signal disconnect during Fire is safe", function(t)
    local s = I.Signal.new()
    local count = 0
    local conn
    conn = s:Connect(function()
        conn:Disconnect()
        count += 1
    end)
    s:Connect(function() count += 1 end)
    s:Fire()
    s:Fire()
    t:Equal(3, count)
end)

suite:Test("Signal Connect rejects non functions", function(t)
    local s = I.Signal.new()
    t:Error(function() s:Connect(5) end)
end)

suite:Test("Maid Clean destroys instances", function(t)
    local frame = Instance.new("Frame")
    local maid = I.Maid.new()
    maid:Give(frame)
    maid:Clean()
    t:Nil(frame.Parent)
end)

suite:Test("Maid Clean disconnects connections", function(t)
    local s = I.Signal.new()
    local conn = s:Connect(function() end)
    local maid = I.Maid.new()
    maid:Give(conn)
    maid:Clean()
    t:False(conn.Connected)
end)

suite:Test("Maid Clean calls functions", function(t)
    local called = false
    local maid = I.Maid.new()
    maid:Give(function() called = true end)
    maid:Clean()
    t:True(called)
end)

suite:Test("Maid Clean cancels threads", function(t)
    local thread = task.spawn(function() task.wait(30) end)
    local maid = I.Maid.new()
    maid:Give(thread)
    maid:Clean()
    t:Equal("dead", coroutine.status(thread))
end)

suite:Test("Maid Clean destroys table objects", function(t)
    local destroyed = false
    local obj = { Destroy = function() destroyed = true end }
    local maid = I.Maid.new()
    maid:Give(obj)
    maid:Clean()
    t:True(destroyed)
end)

suite:Test("Maid Link cleans up on instance destroy", function(t)
    local frame = Instance.new("Frame")
    frame.Parent = workspace
    local maid = I.Maid.new()
    maid:Link(frame)
    local called = false
    maid:Give(function() called = true end)
    frame:Destroy()
    t:WaitFor(function() return called end, 2)
end)

suite:Test("Maid ignores tasks given after death", function(t)
    local maid = I.Maid.new()
    maid:Destroy()
    local called = false
    maid:Give(function() called = true end)
    maid:Clean()
    t:False(called)
end)

suite:Test("SafeCall runs valid functions", function(t)
    local value = 0
    I.SafeCall(function() value = 7 end)
    t:Equal(7, value)
end)

suite:Test("SafeCall swallows errors", function(t)
    t:NoError(function() I.SafeCall(function() error("boom") end) end)
end)

suite:Test("Sanitize strips reserved characters", function(t)
    t:Equal("abcdefghij", I.Sanitize('a/b\\c:d"e<f>g|h*i?j'))
end)

suite:Test("Sanitize trims and defaults", function(t)
    t:Equal("kept", I.Sanitize("  kept  "))
    t:Equal("Untitled", I.Sanitize(""))
    t:Equal("Untitled", I.Sanitize(nil))
    t:Equal("123", I.Sanitize(123))
end)

suite:Test("ColorToHex formats exactly", function(t)
    t:Equal("#FF0000", I.ColorToHex(Color3.fromRGB(255, 0, 0)))
    t:Equal("#0080FF", I.ColorToHex(Color3.fromRGB(0, 128, 255)))
    t:Equal("#808080", I.ColorToHex(Color3.new(0.5, 0.5, 0.5)))
end)

suite:Test("HexToColor parses six digit values", function(t)
    local c = I.HexToColor("#0080FF")
    t:NotNil(c)
    t:Close(0, c.R, 1 / 255)
    t:Close(128 / 255, c.G, 1 / 255)
    t:Close(1, c.B, 1 / 255)
end)

suite:Test("HexToColor expands three digit values", function(t)
    local c = I.HexToColor("#F00")
    t:NotNil(c)
    t:Equal(1, c.R)
    t:Equal(0, c.G)
    t:Equal(0, c.B)
end)

suite:Test("HexToColor rejects invalid input", function(t)
    t:Nil(I.HexToColor("GGGGGG"))
    t:Nil(I.HexToColor("12345"))
    t:Nil(I.HexToColor(123))
    t:Nil(I.HexToColor(nil))
end)

suite:Test("RGBtoHSV computes known colors", function(t)
    local h, s, v = I.RGBtoHSV(Color3.fromRGB(255, 0, 0))
    t:Close(0, h, 1e-4)
    t:Close(1, s, 1e-4)
    t:Close(1, v, 1e-4)
    h, s, v = I.RGBtoHSV(Color3.fromRGB(0, 255, 0))
    t:Close(1 / 3, h, 1e-4)
    t:Close(1, s, 1e-4)
    h, s, v = I.RGBtoHSV(Color3.fromRGB(128, 128, 128))
    t:Close(0, s, 1e-4)
    t:Close(128 / 255, v, 1e-4)
    h, s, v = I.RGBtoHSV(Color3.new(0, 0, 0))
    t:Close(0, s, 1e-4)
    t:Close(0, v, 1e-4)
end)

suite:Test("HSV conversion round trips", function(t)
    for _, c in ipairs({
        Color3.fromRGB(12, 200, 77),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(50, 50, 50),
    }) do
        local h, s, v = I.RGBtoHSV(c)
        local back = Color3.fromHSV(h, s, v)
        t:Close(c.R, back.R, 1 / 255)
        t:Close(c.G, back.G, 1 / 255)
        t:Close(c.B, back.B, 1 / 255)
    end
end)

return suite
