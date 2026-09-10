local RunService = game:GetService("RunService")

local VIM = nil
pcall(function()
    VIM = game:GetService("VirtualInputManager")
end)

local Sim = {}

local probed = false
local probeOk = false

function Sim.Available()
    if not probed then
        probed = true
        probeOk = false
        if VIM ~= nil and RunService:IsRunning() and RunService:IsClient() then
            probeOk = pcall(function()
                VIM:SendMouseMoveEvent(1, 1, game)
            end)
        end
    end
    return probeOk
end

function Sim.ClickAt(x, y, button)
    VIM:SendMouseButtonEvent(x, y, button or 0, true, game, 0)
    task.wait()
    VIM:SendMouseButtonEvent(x, y, button or 0, false, game, 0)
    task.wait()
end

function Sim.Click(gui, button)
    local pos = gui.AbsolutePosition + gui.AbsoluteSize / 2
    Sim.ClickAt(pos.X, pos.Y, button)
end

function Sim.MoveTo(x, y)
    VIM:SendMouseMoveEvent(x, y, game)
    task.wait()
end

function Sim.MoveToGui(gui)
    local pos = gui.AbsolutePosition + gui.AbsoluteSize / 2
    Sim.MoveTo(pos.X, pos.Y)
end

function Sim.KeyDown(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait()
end

function Sim.KeyUp(key)
    VIM:SendKeyEvent(false, key, false, game)
    task.wait()
end

function Sim.Key(key, ctrl)
    if ctrl then
        Sim.KeyDown(Enum.KeyCode.LeftControl)
    end
    Sim.KeyDown(key)
    Sim.KeyUp(key)
    if ctrl then
        Sim.KeyUp(Enum.KeyCode.LeftControl)
    end
end

function Sim.DragFromTo(x1, y1, x2, y2)
    VIM:SendMouseButtonEvent(x1, y1, 0, true, game, 0)
    task.wait()
    local steps = 10
    for i = 1, steps do
        local x = x1 + (x2 - x1) * (i / steps)
        local y = y1 + (y2 - y1) * (i / steps)
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait()
    end
    VIM:SendMouseButtonEvent(x2, y2, 0, false, game, 0)
    task.wait()
end

function Sim.DragGuiTo(gui, x, y)
    local pos = gui.AbsolutePosition + gui.AbsoluteSize / 2
    Sim.DragFromTo(pos.X, pos.Y, x, y)
end

return Sim
