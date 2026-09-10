local RunService = game:GetService("RunService")
local Sim = require(script.Parent.Sim)

local Framework = {}

Framework.Suites = {}
Framework.Kailex = nil
Framework.Internal = nil

local trackedWindows = {}

local layoutChecked = false
local layoutOk = false
local function layoutReady()
    if layoutChecked then return layoutOk end
    layoutChecked = true
    local I = Framework.Internal
    if not I then return false end
    local probe = I.Create("Frame", { Size = UDim2.fromOffset(10, 10), Parent = I.LayerOverlay })
    task.wait(0.1)
    layoutOk = probe.AbsoluteSize.X > 0
    probe:Destroy()
    return layoutOk
end
Framework.LayoutReady = layoutReady

local function fmt(v)
    local kind = typeof(v)
    if v == nil then return "nil" end
    if kind == "string" then return "\"" .. v .. "\"" end
    if kind == "number" then
        if v ~= v then return "NaN" end
        return string.format("%.6g", v)
    end
    if kind == "Vector3" then
        return string.format("(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
    end
    if kind == "Color3" then
        return string.format("RGB(%d, %d, %d)",
            math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
    end
    if kind == "Instance" then return v:GetFullName() end
    return tostring(v)
end
Framework.fmt = fmt

local function fail(msg)
    error(msg, 3)
end

local Assert = {}

function Assert.True(_, v, msg)
    if v ~= true then fail((msg or "expected true") .. ", got " .. fmt(v)) end
end

function Assert.False(_, v, msg)
    if v ~= false then fail((msg or "expected false") .. ", got " .. fmt(v)) end
end

function Assert.Nil(_, v, msg)
    if v ~= nil then fail((msg or "expected nil") .. ", got " .. fmt(v)) end
end

function Assert.NotNil(_, v, msg)
    if v == nil then fail(msg or "expected a non-nil value") end
end

function Assert.Equal(_, expected, actual, msg)
    if expected ~= actual then
        fail((msg or "equality") .. ": expected " .. fmt(expected) .. ", got " .. fmt(actual))
    end
end

function Assert.NotEqual(_, a, b, msg)
    if a == b then fail((msg or "inequality") .. ": both values are " .. fmt(a)) end
end

function Assert.TypeOf(_, typeName, v, msg)
    if typeof(v) ~= typeName then
        fail((msg or "type") .. ": expected " .. typeName .. ", got " .. typeof(v))
    end
end

function Assert.Number(_, v, msg)
    if type(v) ~= "number" or v ~= v then fail((msg or "expected a number") .. ", got " .. fmt(v)) end
end

function Assert.String(_, v, msg)
    if type(v) ~= "string" then fail((msg or "expected a string") .. ", got " .. fmt(v)) end
end

function Assert.Boolean(_, v, msg)
    if type(v) ~= "boolean" then fail((msg or "expected a boolean") .. ", got " .. fmt(v)) end
end

function Assert.Table(_, v, msg)
    if type(v) ~= "table" then fail((msg or "expected a table") .. ", got " .. fmt(v)) end
end

function Assert.Instance(_, className, v, msg)
    if typeof(v) ~= "Instance" or v.ClassName ~= className then
        fail((msg or "instance") .. ": expected " .. className .. ", got " .. fmt(v))
    end
end

function Assert.Close(_, expected, actual, eps, msg)
    eps = eps or 1e-6
    if type(expected) ~= "number" or type(actual) ~= "number" or math.abs(expected - actual) > eps then
        fail((msg or "closeness") .. ": expected " .. fmt(expected) .. ", got " .. fmt(actual))
    end
end

function Assert.Greater(_, a, b, msg)
    if not (type(a) == "number" and type(b) == "number" and a > b) then
        fail((msg or "comparison") .. ": expected " .. fmt(a) .. " > " .. fmt(b))
    end
end

function Assert.Less(_, a, b, msg)
    if not (type(a) == "number" and type(b) == "number" and a < b) then
        fail((msg or "comparison") .. ": expected " .. fmt(a) .. " < " .. fmt(b))
    end
end

function Assert.Contains(_, list, value, msg)
    for _, v in ipairs(list) do
        if v == value then return end
    end
    fail((msg or "list") .. ": expected to contain " .. fmt(value))
end

function Assert.ContainsKey(_, tbl, key, msg)
    if tbl[key] == nil then fail((msg or "table") .. ": expected key " .. fmt(key)) end
end

function Assert.Length(_, tbl, n, msg)
    if #tbl ~= n then fail((msg or "length") .. ": expected " .. n .. ", got " .. #tbl) end
end

function Assert.Empty(_, tbl, msg)
    if #tbl ~= 0 then fail((msg or "emptiness") .. ": got " .. #tbl .. " items") end
end

function Assert.Error(_, fn, msg)
    local ok = pcall(fn)
    if ok then fail(msg or "expected the function to raise an error") end
end

function Assert.NoError(_, fn, msg)
    local ok, err = pcall(fn)
    if not ok then fail((msg or "expected no error") .. ", got " .. tostring(err)) end
end

Framework.Assert = Assert

function Framework.Suite(name)
    local suite = { Name = name, Tests = {} }
    function suite:Test(testName, fn, needs)
        table.insert(self.Tests, { Name = testName, Fn = fn, Needs = needs })
    end
    table.insert(Framework.Suites, suite)
    return suite
end

local windowCounter = 0
function Framework.NewWindow(cfg)
    cfg = cfg or {}
    windowCounter += 1
    if cfg.SaveKey == nil then
        cfg.SaveKey = "TestWindow" .. windowCounter
    end
    local win = Framework.Kailex:CreateWindow(cfg)
    table.insert(trackedWindows, win)
    return win
end

function Framework.FindByZIndex(parent, className, z)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA(className) and ch.ZIndex == z then return ch end
    end
    return nil
end

function Framework.FindTextButton(root, text)
    for _, ch in ipairs(root:GetDescendants()) do
        if ch:IsA("TextButton") and ch.Text == text then return ch end
    end
    return nil
end

function Framework.Run()
    local results = { Total = 0, Passed = 0, Failed = 0, Skipped = 0, Failures = {} }
    print("[Kailex Tests] " .. string.rep("=", 64))
    print("[Kailex Tests] Kailex UI " .. tostring(Framework.Kailex and Framework.Kailex.Version))
    print("[Kailex Tests] client: " .. tostring(RunService:IsClient())
        .. " | running: " .. tostring(RunService:IsRunning())
        .. " | input sim: " .. tostring(Sim.Available())
        .. " | layout: " .. tostring(layoutReady()))
    print("[Kailex Tests] " .. string.rep("=", 64))

    for _, suite in ipairs(Framework.Suites) do
        local sPassed, sFailed, sSkipped = 0, 0, 0
        for _, test in ipairs(suite.Tests) do
            results.Total += 1
            if test.Needs == "input" and not Sim.Available() then
                results.Skipped += 1
                sSkipped += 1
                print("[Kailex Tests] SKIP  " .. suite.Name .. " > " .. test.Name)
            elseif test.Needs == "layout" and not layoutReady() then
                results.Skipped += 1
                sSkipped += 1
                print("[Kailex Tests] SKIP  " .. suite.Name .. " > " .. test.Name)
            else
                local cleanups = {}
                local defers = {}
                local ctx = setmetatable({}, { __index = Assert })
                function ctx:Wait(n) task.wait(n or 0.03) end
                function ctx:WaitFor(fn, timeout, interval)
                    timeout = timeout or 2
                    interval = interval or 0.05
                    local start = os.clock()
                    while os.clock() - start < timeout do
                        local ok, res = pcall(fn)
                        if ok and res then return end
                        task.wait(interval)
                    end
                    error("timed out waiting for a condition", 2)
                end
                function ctx:Cleanup(obj)
                    table.insert(cleanups, obj)
                end
                function ctx:Defer(fn)
                    table.insert(defers, fn)
                end
                local ok, err = pcall(test.Fn, ctx)
                for i = #defers, 1, -1 do
                    pcall(defers[i])
                end
                for i = #cleanups, 1, -1 do
                    pcall(function() cleanups[i]:Destroy() end)
                end
                if ok then
                    results.Passed += 1
                    sPassed += 1
                else
                    results.Failed += 1
                    sFailed += 1
                    table.insert(results.Failures, {
                        Suite = suite.Name, Test = test.Name, Error = tostring(err),
                    })
                    print("[Kailex Tests] FAIL  " .. suite.Name .. " > " .. test.Name)
                    print("[Kailex Tests]        " .. tostring(err))
                end
            end
        end
        local status = (sFailed == 0) and "OK  " or "FAIL"
        print(string.format("[Kailex Tests] %s | %s: %d passed, %d failed, %d skipped",
            status, suite.Name, sPassed, sFailed, sSkipped))
        for i = #trackedWindows, 1, -1 do
            pcall(function() trackedWindows[i]:Destroy() end)
            trackedWindows[i] = nil
        end
        pcall(function() Framework.Internal.SaveManager:Clear() end)
        task.wait(0.25)
    end

    print("[Kailex Tests] " .. string.rep("=", 64))
    local verdict = (results.Failed == 0) and "ALL PASSED" or "FAILURES DETECTED"
    print(string.format("[Kailex Tests] %s | %d/%d passed, %d failed, %d skipped",
        verdict, results.Passed, results.Total, results.Failed, results.Skipped))
    for _, f in ipairs(results.Failures) do
        print(string.format("[Kailex Tests]   - %s > %s: %s", f.Suite, f.Test, f.Error))
    end
    print("[Kailex Tests] " .. string.rep("=", 64))
    return results
end

return Framework
