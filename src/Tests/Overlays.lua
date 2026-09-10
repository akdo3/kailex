local F = require(script.Parent.Framework)
local Sim = require(script.Parent.Sim)
local Kailex = F.Kailex
local I = F.Internal

local suite = F.Suite("Overlays")

local function findMenuFrame()
    return F.FindByZIndex(I.LayerOverlay, "Frame", 320)
end

suite:Test("Notify logs entries with normalized fields", function(t)
    Kailex:Notify({ Title = "T1", Text = "B1", Type = "Success", Duration = 0.5 })
    local log = Kailex:GetNotificationLog()
    t:True(#log > 0)
    local last = log[#log]
    t:Equal("T1", last.Title)
    t:Equal("B1", last.Text)
    t:Equal("success", last.Type)
    t:Number(last.Time)
end)

suite:Test("Notify normalizes invalid types and default titles", function(t)
    Kailex:Notify({ Text = "B2", Duration = 0.5 })
    local log = Kailex:GetNotificationLog()
    t:Equal("info", log[#log].Type)
    t:Equal("Notice", log[#log].Title)
end)

suite:Test("Notify accepts plain strings", function(t)
    Kailex:Notify("plain text")
    local log = Kailex:GetNotificationLog()
    t:Equal("plain text", log[#log].Text)
    t:Equal("Notice", log[#log].Title)
end)

suite:Test("Notify filters malformed actions without errors", function(t)
    Kailex:Notify({
        Text = "actions",
        Duration = 0.5,
        Actions = {
            { Text = "A", Callback = function() end },
            5,
            nil,
            { Callback = function() end },
        },
    })
    t:Equal("actions", Kailex:GetNotificationLog()[#Kailex:GetNotificationLog()].Text)
end)

suite:Test("Notification log is capped at 50 entries", function(t)
    for i = 1, 55 do
        Kailex:Notify({ Title = "N" .. i, Text = "", Duration = 0.5 })
    end
    t:Equal(50, #Kailex:GetNotificationLog())
end)

suite:Test("GetNotificationLog returns fresh copies", function(t)
    local a = Kailex:GetNotificationLog()
    local b = Kailex:GetNotificationLog()
    t:NotEqual(a, b)
    t:Equal(#a, #b)
end)

suite:Test("Confirm opens a modal card and declines through the stack", function(t)
    local accepted, declined = false, false
    local card = Kailex:Confirm({
        Title = "Q",
        Text = "body",
        OnAccept = function() accepted = true end,
        OnDecline = function() declined = true end,
    })
    t:Instance("CanvasGroup", card)
    t:True(#I.ModalManager.Stack > 0)
    I.ModalManager.CloseTop()
    t:True(declined)
    t:False(accepted)
    t:WaitFor(function() return #I.ModalManager.Stack == 0 end, 1)
    t:Wait(0.25)
end)

suite:Test("Confirm accepts string payloads", function(t)
    local ok = false
    local card = Kailex:Confirm("just checking", function() ok = true end)
    t:Instance("CanvasGroup", card)
    I.ModalManager.CloseTop()
    t:False(ok)
    t:Wait(0.25)
end)

suite:Test("Confirm releases the modal lock after closing", function(t)
    local first = Kailex:Confirm({ Text = "one" })
    t:NotNil(first)
    I.ModalManager.CloseTop()
    t:Wait(0.3)
    local second = Kailex:Confirm({ Text = "two" })
    t:NotNil(second)
    I.ModalManager.CloseTop()
    t:Wait(0.3)
end)

suite:Test("Confirm supports the danger style", function(t)
    local card = Kailex:Confirm({ Text = "danger", Type = "Danger", OnDecline = function() end })
    t:Instance("CanvasGroup", card)
    I.ModalManager.CloseTop()
    t:Wait(0.25)
end)

suite:Test("Confirm accepts through the Enter key", function(t)
    local accepted = false
    Kailex:Confirm({ Text = "enter", OnAccept = function() accepted = true end })
    Sim.Key(Enum.KeyCode.Return)
    t:WaitFor(function() return accepted end, 2)
end, "input")

suite:Test("ContextMenu shows and hides", function(t)
    I.ContextMenu.Show({
        { Text = "Alpha", Callback = function() end },
        { Separator = true },
        { Text = "Beta", Danger = true, Callback = function() end },
    }, 120, 120)
    local frame = findMenuFrame()
    t:NotNil(frame)
    t:True(frame.Visible)
    t:NotNil(F.FindTextButton(frame, "Alpha"))
    local beta = F.FindTextButton(frame, "Beta")
    t:NotNil(beta)
    t:Equal(I.CurrentTheme.Error, beta.TextColor3)
    I.ContextMenu.Hide()
    t:False(frame.Visible)
    t:Equal(0, #I.ModalManager.Stack)
end)

suite:Test("ContextMenu ignores empty item lists", function(t)
    I.ContextMenu.Show({}, 100, 100)
    local frame = findMenuFrame()
    if frame then
        t:False(frame.Visible)
    end
end)

suite:Test("ContextMenu closes on Escape", function(t)
    I.ContextMenu.Show({ { Text = "Item", Callback = function() end } }, 100, 100)
    local frame = findMenuFrame()
    t:True(frame.Visible)
    Sim.Key(Enum.KeyCode.Escape)
    t:WaitFor(function() return not frame.Visible end, 2)
end, "input")

suite:Test("Tooltip shows and hides", function(t)
    I.Tooltip.Show("tip text")
    local frame = F.FindByZIndex(I.LayerTooltip, "Frame", 100)
    t:NotNil(frame)
    t:True(frame.Visible)
    t:Equal("tip text", frame:FindFirstChildOfClass("TextLabel").Text)
    I.Tooltip.Hide()
    t:WaitFor(function() return not frame.Visible end, 1)
end)

suite:Test("AddTooltip shows on hover and hides on leave", function(t)
    local frame = I.Create("Frame", {
        Size = UDim2.fromOffset(60, 30),
        Position = UDim2.fromOffset(200, 200),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = I.LayerOverlay,
    })
    t:Cleanup(frame)
    I.AddTooltip(frame, { Text = "hover tip" })
    Sim.MoveToGui(frame)
    local tip = F.FindByZIndex(I.LayerTooltip, "Frame", 100)
    t:NotNil(tip)
    t:WaitFor(function()
        return tip.Visible and tip:FindFirstChildOfClass("TextLabel").Text == "hover tip"
    end, 2)
    Sim.MoveTo(10, 10)
    t:WaitFor(function() return not tip.Visible end, 2)
end, "input")

return suite
