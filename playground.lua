local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kailex
do
    local node = ReplicatedStorage:FindFirstChild("Kailex")
    if not node then
        local parent = script.Parent
        if parent and parent:IsA("ModuleScript") and parent.Name == "Kailex" then
            node = parent
        end
    end
    assert(node, "KailexUI: Kailex module not found in ReplicatedStorage")
    Kailex = require(node)
end

local log = {}
local logTable, valuesTable, notifyTable
local trackers = {}

local function fmt(v)
    if v == nil then return "nil" end
    if type(v) == "table" then
        local parts = {}
        for _, x in ipairs(v) do parts[#parts + 1] = tostring(x) end
        return "{ " .. table.concat(parts, ", ") .. " }"
    end
    return tostring(v)
end

local function packArgs(...)
    local n = select("#", ...)
    if n == 0 then return "" end
    local parts = {}
    for i = 1, n do parts[i] = fmt(select(i, ...)) end
    return table.concat(parts, " | ")
end

local function logEvent(source, event, payload)
    table.insert(log, 1, { Cells = { os.date("%X"), source, event, payload or "" } })
    if #log > 60 then table.remove(log) end
    if logTable then logTable:SetRows(log, true) end
end

local function track(name, getter, note)
    trackers[#trackers + 1] = { Name = name, Get = getter, Note = note or "" }
end

local function refreshValues()
    if not valuesTable then return end
    local rows = {}
    for _, t in ipairs(trackers) do
        local ok, v = pcall(t.Get)
        rows[#rows + 1] = { Cells = { t.Name, ok and fmt(v) or "error", t.Note } }
    end
    valuesTable:SetRows(rows, true)
end

local function CB(name)
    return function(...)
        logEvent(name, "Callback", packArgs(...))
        refreshValues()
    end
end

local function CBN(name, fn)
    return function(...)
        logEvent(name, "Callback", packArgs(...))
        refreshValues()
        if fn then fn(...) end
    end
end

local win = Kailex:CreateWindow({
    Title = "Kailex Playground",
    SubTitle = "Live demo of every feature - " .. Kailex.Version,
    MinSize = Vector2.new(440, 320),
    Icon = "Gear",
})

win.MinimizedChanged:Connect(function(min)
    logEvent("Window", "MinimizedChanged", tostring(min))
end)

local tEl = win:Tab({ Title = "Elements", Icon = "Check" })

local btnPlain
local togPlain, togPin
local labDemo, paraDemo
local sliderFull, sliderDecimal, stepFmt, segMain, pcolMain
local dropSingle, dropMulti, dropSearch, dropVirtual
local kbPress, kbToggle, kbHold
local textValid, textPlain, vecInput
local pbarMain, dtabDemo

tEl:AddSection("Button")

btnPlain = tEl:AddButton({
    Name = "Plain button",
    Description = "Callback + Ripple + click sound",
    Tooltip = "The simplest element in the library",
    Search = "basic click simple",
    Callback = CB("Button/plain"),
})

tEl:AddButton({
    Name = "Vector icon",
    Description = "Icon = built-in icon name",
    Icon = "Search",
    Callback = CBN("Button/vector", function()
        Kailex:Notify({ Title = "Button", Text = "Icon button clicked", Type = "info", Duration = 2 })
    end),
})

tEl:AddButton({
    Name = "Asset icon (string)",
    Description = "Icon = rbxasset://...",
    Icon = "rbxasset://textures/face.png",
    Callback = CB("Button/asset-string"),
})

tEl:AddButton({
    Name = "Asset icon (number)",
    Description = "Icon = numeric asset id",
    Icon = 4466585890,
    Callback = CB("Button/asset-id"),
})

tEl:AddButton({
    Name = "Button with Confirm",
    Description = "Call Kailex:Confirm inside the Callback",
    Callback = CBN("Button/Confirm", function()
        Kailex:Confirm({ Title = "Run this action?", Text = "Are you sure?" }, function()
            Kailex:Notify({ Text = "Executed after confirmation", Type = "success", Duration = 2 })
        end)
    end),
})

tEl:AddButton({
    Name = "SetCallback on the plain button",
    Callback = function()
        btnPlain:SetCallback(CBN("Button/plain (modified)", function()
            Kailex:Notify({ Text = "Replaced callback", Duration = 2 })
        end))
    end,
})

tEl:AddSection("Toggle")

togPlain = tEl:AddToggle({
    Name = "Plain toggle",
    Description = "Default=true + Changed signal",
    Default = true,
    Tooltip = "Click to toggle",
    Callback = CB("Toggle/plain"),
})
togPlain.Changed:Connect(function(v)
    logEvent("Toggle/plain", "Changed", tostring(v))
    refreshValues()
end)

togPin = tEl:AddToggle({
    Name = "Pinned toggle (Pin)",
    Description = "Pin=true draggable floating widget - Style=true square corners",
    Pin = true,
    Callback = CB("Toggle/Pin"),
})

tEl:AddSection("Text and display")

labDemo = tEl:AddLabel("Label - a light text row")

paraDemo = tEl:AddParagraph({
    Title = "Paragraph",
    Text = "A text card with a title and a wrapping body. Update the text with Set.",
    Tooltip = "An explanatory paragraph",
})

tEl:AddButton({
    Name = "Label:Set + Paragraph:Set",
    Callback = function()
        labDemo:Set("Updated text " .. os.date("%X"))
        paraDemo:Set("Updated at " .. os.date("%X"))
    end,
})

tEl:AddDivider({ Text = "Divider with text" })

tEl:AddSection({ Name = "Section grid (Columns=2)", Columns = 2 })

tEl:AddSlider({
    Name = "Slider",
    Min = 0, Max = 100, Default = 50,
    Suffix = "%",
    Callback = CB("Slider/grid"),
})

stepFmt = tEl:AddStepper({
    Name = "Stepper",
    Min = -5, Max = 5, Step = 0.5, Default = 0,
    Prefix = "X=",
    Suffix = " pts",
    Callback = CB("Stepper/grid"),
})

segMain = tEl:AddSegmented({
    Name = "Segmented",
    Options = { "Easy", "Medium", "Hard" },
    Default = "Medium",
    ItemWidth = 64,
    Callback = CB("Segmented"),
})

pcolMain = tEl:AddColorPicker({
    Name = "ColorPicker",
    Default = "#f2a63b",
    Callback = CB("ColorPicker"),
})

tEl:AddButton({
    Name = "Wide button (Span=2)",
    Span = 2,
    Callback = CB("Button/Span"),
})

tEl:AddSection("Sliders")

sliderFull = tEl:AddSlider({
    Name = "Slider, full options",
    Description = "Right-click the track = Reset - arrow keys while hovering it",
    Min = 0, Max = 1000, Step = 10, Default = 250,
    Prefix = "$ ",
    Suffix = " USD",
    FireOnRelease = true,
    SaveKey = "DemoSliderKey",
    Callback = CB("Slider/full"),
})

sliderDecimal = tEl:AddSlider({
    Name = "Decimal slider (Value=0.5)",
    Min = 0, Max = 1,
    Value = 0.5,
    Suffix = "x",
    Callback = CB("Slider/decimal"),
})

tEl:AddStepper({
    Name = "Stepper with Format",
    Min = -10, Max = 10, Step = 0.5, Default = 0,
    Format = function(v)
        return string.format("Value %.1f", v)
    end,
    Callback = CB("Stepper/Format"),
})

tEl:AddColorPicker({
    Name = "ColorPicker (Color=Color3)",
    Color = Color3.fromRGB(120, 80, 200),
    Callback = CB("ColorPicker/Alias"),
})

tEl:AddSection({ Name = "Collapsed section by default", Collapsed = true })

tEl:AddToggle({
    Name = "Element inside the collapsed section",
    defaultVal = false,
    Callback = CB("Toggle/collapsed"),
})

tEl:AddButton({
    Name = "Button inside the collapsed section",
    Callback = CB("Button/collapsed"),
})

tEl:AddSection("Dropdowns")

dropSingle = tEl:AddDropdown({
    Name = "Single",
    Description = "Plain strings and composite {Text, Value} options",
    Options = { "First", { Text = "Second (Value=2)", Value = 2 }, "Third", { Text = "Fourth (Value=four)", Value = "four" } },
    Default = "First",
    Callback = CB("Dropdown/single"),
})

dropMulti = tEl:AddDropdown({
    Name = "Multi select",
    Multi = true,
    Items = { "Apple", "Banana", "Orange", "Grape", "Mango" },
    Defaults = { "Apple", "Banana" },
    Callback = CB("Dropdown/Multi"),
})

dropSearch = tEl:AddDropdown({
    Name = "Searchable",
    Searchable = true,
    Options = (function()
        local o = {}
        for i = 1, 30 do o[i] = "Option number " .. i end
        return o
    end)(),
    Default = "Option number 7",
    Callback = CB("Dropdown/search"),
})

dropVirtual = tEl:AddDropdown({
    Name = "Virtualized (>60 options)",
    Description = "Only visible options get built",
    Multi = true,
    Options = (function()
        local o = {}
        for i = 1, 80 do o[i] = "Item " .. i end
        return o
    end)(),
    Callback = CB("Dropdown/virtual"),
})

tEl:AddButton({
    Name = "SetOptions + silent Set",
    Callback = function()
        dropSingle:SetOptions({ "New A", "New B", "New C" })
        dropSingle:Set("New B", true)
    end,
})

tEl:AddSection("Keybinds and text input")

kbPress = tEl:AddKeybind({
    Name = "Keybind (press)",
    Default = Enum.KeyCode.B,
    Callback = CB("Keybind/press"),
})

kbToggle = tEl:AddKeybind({
    Name = "Keybind (toggle)",
    Mode = "toggle",
    Default = "Key:T",
    Callback = CB("Keybind/toggle"),
})

kbHold = tEl:AddKeybind({
    Name = "Keybind (hold + mouse)",
    Mode = "hold",
    MouseButtons = true,
    Callback = CB("Keybind/hold"),
})

textValid = tEl:AddTextInput({
    Name = "TextInput with Validator",
    Description = "Digits only - try an invalid value",
    Default = "42",
    Placeholder = "Digits only...",
    Validator = function(text)
        return text:match("^%d*$") ~= nil
    end,
    Callback = CB("TextInput/Validator"),
})

local togAttach = textValid:AddToggle({ Default = true })
togAttach.Changed:Connect(function(v)
    textValid:SetDisabled(not v)
    logEvent("TextInput", "AddToggle", "enabled=" .. tostring(v))
end)

textPlain = tEl:AddTextInput({
    Name = "Plain TextInput",
    Placeholder = "Type something then press Enter...",
    Callback = CB("TextInput/plain"),
})

vecInput = tEl:AddVector3Input({
    Name = "Vector3Input",
    Default = Vector3.new(10, 5, 0),
    Callback = CB("Vector3"),
})

tEl:AddSection("Progress and tables")

pbarMain = tEl:AddProgressBar({
    Name = "ProgressBar",
    Max = 100,
    Value = 30,
    Format = function(v)
        return string.format("%.0f / 100", v)
    end,
    Callback = CB("ProgressBar"),
})

tEl:AddButton({ Name = "Set(75)", Width = 0.33, Callback = function() pbarMain:Set(75) end })
tEl:AddButton({ Name = "Set(0)", Width = 0.33, Callback = function() pbarMain:Set(0) end })
tEl:AddButton({ Name = "Animate", Width = 0.33, Callback = function()
    task.spawn(function()
        for i = 0, 20 do
            pbarMain:Set(i * 5)
            task.wait(0.05)
        end
    end)
end })

dtabDemo = tEl:AddDataTable({
    Name = "DataTable",
    Description = "Click a column header to sort - click a row to fire the Callback",
    Columns = {
        { Name = "ID", Width = 50 },
        { Name = "Name", Width = 130 },
        { Name = "Value", Width = 90 },
    },
    Rows = {
        { Cells = { "1", "First", "100" }, Data = { id = 1, name = "First" } },
        { Cells = { "2", "Second", "250" }, Data = { id = 2, name = "Second" } },
        { Cells = { "3", "Third", "75" }, Data = { id = 3, name = "Third" } },
    },
    Height = 150,
    Callback = CBN("DataTable", function(data, index)
        Kailex:Notify({
            Title = "DataTable",
            Text = "Row #" .. tostring(index) .. " - Data.id=" .. tostring(data and data.id),
            Duration = 3,
        })
    end),
})

tEl:AddButton({
    Name = "Sort(column 3, descending)",
    Callback = function()
        dtabDemo:Sort(3, false)
    end,
})

tEl:AddSection("Live element programming")

tEl:AddButton({
    Name = "SetTitle / SetTooltip / SetDescription",
    Callback = function()
        btnPlain:SetTitle("Updated title " .. os.date("%X"))
        btnPlain:SetTooltip("Updated tooltip")
        btnPlain:SetDescription("Updated description")
    end,
})

tEl:AddButton({
    Name = "Visible() toggle on the plain toggle",
    Callback = function()
        togPlain:Visible()
    end,
})

tEl:AddToggle({
    Name = "SetDisabled on other elements",
    Description = "Disables the Slider, Dropdown and TextInput",
    Default = false,
    Callback = CBN("Toggle/disable", function(v)
        sliderFull:SetDisabled(v)
        dropSingle:SetDisabled(v)
        textValid:SetDisabled(v)
    end),
})

local tempEl = tEl:AddButton({
    Name = "Temporary element - will be destroyed",
    Callback = CB("Button/temp"),
})

tEl:AddButton({
    Name = "Element:Destroy()",
    Callback = function()
        tempEl:Destroy()
        Kailex:Notify({ Text = "Temporary element destroyed", Type = "info", Duration = 2 })
    end,
})

track("Toggle/plain", function() return togPlain:Get() end, "Changed + Callback")
track("Toggle/Pin", function() return togPin:Get() end, "floating widget")
track("Slider/full", function() return sliderFull:Get() end, "FireOnRelease")
track("Slider/decimal", function() return sliderDecimal:Get() end, "")
track("Stepper/grid", function() return stepFmt:Get() end, "")
track("Segmented", function() return segMain:Get() end, "")
track("ColorPicker", function() return pcolMain:Get() end, "Color3")
track("ColorPicker/Hex", function() return pcolMain:CopyValue() end, "#RRGGBB")
track("Dropdown/single", function() return dropSingle:Get() end, "")
track("Dropdown/Multi", function() return dropMulti:Get() end, "value list")
track("Dropdown/search", function() return dropSearch:Get() end, "")
track("Dropdown/virtual", function() return dropVirtual:Get() end, "80 options")
track("Keybind/press", function() return kbPress:GetName() end, "GetName")
track("Keybind/toggle", function() return kbToggle:GetState() end, "GetState")
track("Keybind/hold", function() return kbHold:GetState() end, "GetState")
track("TextInput/Validator", function() return textValid:Get() end, "")
track("TextInput/plain", function() return textPlain:Get() end, "")
track("Vector3", function() return vecInput:Get() end, "")
track("ProgressBar", function() return pbarMain:Get() end, "")
track("#Kailex.Windows", function() return #Kailex.Windows end, "open windows")
track("Kailex:IsVisible()", function() return Kailex:IsVisible() end, "global visibility")

local tGrid = win:Tab({ Title = "Grid", Icon = "Grip" })

tGrid:AddParagraph({
    Title = "AddRow + Span",
    Text = "AddRow(cols) creates a manual grid row. Add elements through row:Add* with Span. Or use the automatic grid via Width below 0.95.",
})

local row3 = tGrid:AddRow(3)
row3:AddButton({ Name = "A", Callback = CB("Grid/A") })
row3:AddButton({ Name = "B", Callback = CB("Grid/B") })
row3:AddButton({ Name = "C", Callback = CB("Grid/C") })
row3:AddButton({ Name = "D (Span=2)", Span = 2, Callback = CB("Grid/D") })
row3:AddButton({ Name = "E", Callback = CB("Grid/E") })
row3:AddSlider({ Name = "Slider (Span=3)", Span = 3, Min = 0, Max = 10, Default = 5, Callback = CB("Grid/Slider") })

local row2 = tGrid:AddRow(2)
row2:AddDropdown({ Name = "Pick", Options = { "X", "Y" }, Default = "X", Callback = CB("Grid/Dropdown") })
row2:AddToggle({ Name = "Switch", Default = true, Callback = CB("Grid/Toggle") })

tGrid:AddDivider({ Text = "Automatic grid via Width" })
tGrid:AddButton({ Name = "Half width", Width = 0.5, Callback = CB("AutoGrid/1") })
tGrid:AddButton({ Name = "Half width", Width = 0.5, Callback = CB("AutoGrid/2") })
tGrid:AddButton({ Name = "Third", Width = 0.33, Callback = CB("AutoGrid/3") })
tGrid:AddButton({ Name = "Third", Width = 0.33, Callback = CB("AutoGrid/4") })
tGrid:AddButton({ Name = "Third", Width = 0.33, Callback = CB("AutoGrid/5") })

local tOv = win:Tab({ Title = "Overlays", Icon = "Alert" })

tOv:AddSection("Notify")

tOv:AddButton({ Name = "Info", Width = 0.25, Callback = function()
    Kailex:Notify({ Title = "Title", Text = "Type info - the default", Type = "info" })
end })
tOv:AddButton({ Name = "Success", Width = 0.25, Callback = function()
    Kailex:Notify({ Title = "Done", Text = "Type success", Type = "success" })
end })
tOv:AddButton({ Name = "Warning", Width = 0.25, Callback = function()
    Kailex:Notify({ Title = "Warning", Text = "Type warning", Type = "warning" })
end })
tOv:AddButton({ Name = "Error", Width = 0.25, Callback = function()
    Kailex:Notify({ Title = "Error", Text = "Type error", Type = "error" })
end })

tOv:AddButton({
    Name = "Custom duration (10s) + long text",
    Callback = function()
        Kailex:Notify({
            Title = "Long notification",
            Text = "Duration=10 - hover the card to pause the timer",
            Duration = 10,
        })
    end,
})

tOv:AddButton({
    Name = "With Actions (up to 3)",
    Callback = function()
        Kailex:Notify({
            Title = "Notification with buttons",
            Text = "Hovering the buttons pauses the timer",
            Type = "warning",
            Duration = 9,
            Actions = {
                { Text = "OK", Callback = function() logEvent("Notify", "Action", "OK") end },
                { Text = "Details", Callback = function() logEvent("Notify", "Action", "Details") end },
                { Text = "Close", Callback = function() logEvent("Notify", "Action", "Close") end },
            },
        })
    end,
})

notifyTable = tOv:AddDataTable({
    Name = "Notification log (GetNotificationLog)",
    Columns = { { Name = "Time", Width = 70 }, { Name = "Type", Width = 70 }, { Name = "Title", Width = 130 } },
    Height = 130,
})

local function refreshNotifyLog()
    local src = Kailex:GetNotificationLog()
    local rows = {}
    for i = #src, 1, -1 do
        local e = src[i]
        rows[#rows + 1] = { Cells = { os.date("%X", e.Time), e.Type, e.Title } }
    end
    notifyTable:SetRows(rows, true)
end

tOv:AddButton({ Name = "Refresh log", Callback = refreshNotifyLog })
refreshNotifyLog()

tOv:AddSection("Confirm")

tOv:AddButton({
    Name = "Plain Confirm",
    Callback = function()
        Kailex:Confirm({ Title = "Confirm", Text = "Do you agree?" }, function()
            Kailex:Notify({ Text = "Accepted", Type = "success", Duration = 2 })
        end)
    end,
})

tOv:AddButton({
    Name = "Danger Confirm + OnDecline",
    Callback = function()
        Kailex:Confirm({
            Danger = true,
            Title = "Delete?",
            Text = "This cannot be undone.",
            AcceptText = "Delete",
            DeclineText = "Keep",
            OnDecline = function() logEvent("Confirm", "OnDecline", "danger") end,
        }, function()
            Kailex:Notify({ Text = "Deleted (pretend)", Type = "error", Duration = 2 })
        end)
    end,
})

tOv:AddButton({
    Name = "Info Confirm (Type=info)",
    Callback = function()
        Kailex:Confirm({ Type = "info", Title = "Information", Text = "Enter accepts - Escape declines - backdrop click declines" }, function()
            logEvent("Confirm", "Accept", "info")
        end)
    end,
})

tOv:AddButton({
    Name = "Confirm queue (3 in a row)",
    Callback = function()
        for i = 1, 3 do
            Kailex:Confirm({ Title = "Confirm #" .. i, Text = "They take turns from the queue automatically" }, function()
                Kailex:Notify({ Text = "Executed #" .. i, Type = "success", Duration = 2 })
            end)
        end
    end,
})

tOv:AddSection("KeySystem")

tOv:AddParagraph({ Title = "Demo key", Text = "KAILEX-DEMO - Remember=false - the Get Key button copies the link" })

tOv:AddButton({
    Name = "Launch KeySystem",
    Callback = function()
        Kailex:KeySystem({
            Title = "Key System (demo)",
            Description = "The correct key is: KAILEX-DEMO",
            Key = "KAILEX-DEMO",
            Remember = false,
            Link = "https://example.com/get-key",
            OnComplete = function(key) logEvent("KeySystem", "OnComplete", tostring(key)) end,
            OnWrong = function(key) logEvent("KeySystem", "OnWrong", tostring(key)) end,
            OnDecline = function() logEvent("KeySystem", "OnDecline", "") end,
        })
    end,
})

tOv:AddSection("Windows")

local secondWin

tOv:AddButton({
    Name = "Second window (ToggleKey=J)",
    Description = "Size={520,340} - ConfirmClose - RememberPosition=false",
    Callback = function()
        if secondWin and not secondWin._destroyed then
            Kailex:Notify({ Text = "The second window is open - press J to toggle it", Type = "info" })
            return
        end
        secondWin = Kailex:CreateWindow({
            Title = "Second window",
            SubTitle = "String asset icon",
            MinSize = Vector2.new(300, 220),
            Icon = "rbxasset://textures/face.png",
            ToggleKey = "Key:J",
            RememberPosition = false,
            ConfirmClose = "Close the second window?",
        })
        secondWin:Tab({ Title = "Button", Icon = "Pin" }):AddButton({
            Name = "Click me",
            Callback = CB("SecondWin/Button"),
        })
        secondWin.Closed:Connect(function()
            logEvent("Window2", "Closed", "")
            secondWin = nil
        end)
    end,
})

tOv:AddSection("Main window control")

local titleInput = tOv:AddTextInput({ Name = "New title", Placeholder = "Type a title..." })

tOv:AddButton({ Name = "SetTitle", Callback = function()
    local t = titleInput:Get()
    if t ~= "" then win:SetTitle(t) end
end })

tOv:AddSection("Themes")

tOv:AddButton({
    Name = "RegisterTheme + SetTheme",
    Callback = function()
        Kailex:RegisterTheme("Demo Teal", {
            Accent = Color3.fromRGB(94, 210, 190),
            AccentHover = Color3.fromRGB(124, 224, 206),
            Background = Color3.fromRGB(12, 16, 17),
            Surface = Color3.fromRGB(17, 23, 24),
        })
        Kailex:SaveCustomThemes()
        Kailex:SetTheme("Demo Teal")
        Kailex:Notify({ Title = "Themes", Text = "Registered and applied Demo Teal (merged over Nocturne)", Type = "success" })
    end,
})

tOv:AddButton({
    Name = "RemoveTheme",
    Callback = function()
        Kailex:RemoveTheme("Demo Teal")
        Kailex:Notify({ Text = "Removed - falls back if it was active" })
    end,
})

tOv:AddButton({
    Name = "GetThemes",
    Callback = function()
        Kailex:Notify({ Title = "Available themes", Text = table.concat(Kailex:GetThemes(), ", "), Duration = 8 })
    end,
})

tOv:AddSection("Global")

tOv:AddButton({
    Name = "SetVisible(false) - RightShift to restore",
    Callback = function()
        Kailex:Confirm({
            Title = "Hide the interface?",
            Text = "Press RightShift (or the mobile button) to show it again.",
            AcceptText = "Hide",
        }, function()
            Kailex:SetVisible(false)
        end)
    end,
})

tOv:AddButton({
    Name = "Unload (full teardown)",
    Callback = function()
        Kailex:Confirm({ Danger = true, Title = "Unload?", Text = "Everything will be destroyed permanently." }, function()
            Kailex:Unload()
        end)
    end,
})

local tVal = win:Tab({ Title = "Values", Icon = "Info" })

tVal:AddParagraph({
    Title = "Live values",
    Text = "Updated automatically on every event - or manually. Shows the current Get() of every element in the Playground window.",
})

valuesTable = tVal:AddDataTable({
    Name = "Get() of every element",
    Columns = { { Name = "Element", Width = 140 }, { Name = "Get()", Width = 160 }, { Name = "Note", Width = 150 } },
    Height = 250,
})

tVal:AddButton({ Name = "Refresh now", Callback = refreshValues })
refreshValues()

tVal:AddDivider({ Text = "Event log" })

logTable = tVal:AddDataTable({
    Name = "Events (callbacks + signals)",
    Columns = { { Name = "Time", Width = 64 }, { Name = "Source", Width = 120 }, { Name = "Event", Width = 96 }, { Name = "Payload", Width = 170 } },
    Height = 210,
})
logTable:SetRows(log, true)

Kailex:CreateSettingsTab(win)

local docs = Kailex:CreateWindow({
    Title = "Kailex Guide",
    SubTitle = "Every element's options + examples + API",
})

local REQ = { r = "recommended", o = "optional" }

local DOC_COLS = {
    { Name = "Option", Width = 84 },
    { Name = "Type", Width = 70 },
    { Name = "Required", Width = 90 },
    { Name = "Default", Width = 92 },
    { Name = "Description", Width = 210 },
}

local API_COLS = {
    { Name = "Function", Width = 130 },
    { Name = "Signature / value", Width = 170 },
    { Name = "Description", Width = 210 },
}

local function addDocTable(tab, name, rows)
    local mapped = {}
    for _, r in ipairs(rows) do
        mapped[#mapped + 1] = { Cells = { r[1], r[2], REQ[r[3]], r[4], r[5] } }
    end
    return tab:AddDataTable({
        Name = name,
        Columns = DOC_COLS,
        Rows = mapped,
        Height = math.min(44 + #rows * 28, 300),
    })
end

local function addApiTable(tab, name, rows)
    local mapped = {}
    for _, r in ipairs(rows) do
        mapped[#mapped + 1] = { Cells = { r[1], r[2], r[3] } }
    end
    return tab:AddDataTable({
        Name = name,
        Columns = API_COLS,
        Rows = mapped,
        Height = math.min(44 + #rows * 28, 300),
    })
end

local function addExample(tab, text)
    tab:AddParagraph({ Title = "Example", Text = text })
end

local COMMON_ROWS = {
    { "Name", "string", "o", "depends", "Displayed name (alias: Title)" },
    { "Description", "string", "o", '""', "Gray description line under the name" },
    { "Tooltip", "string", "o", "none", "Hover tooltip - its text feeds search" },
    { "Search", "string", "o", "none", "Extra hidden search keywords" },
    { "Width", "number", "o", "1", "Width ratio 0-1; below 0.95 enables the automatic grid" },
    { "SaveKey", "string", "o", "auto", "Save key: SavePrefix/Tab/Name" },
    { "Span", "number", "o", "1", "Grid column span 1..Columns" },
}

local ELEMENT_DOCS = {
    {
        title = "Button",
        rows = {
            { "Callback", "function", "o", "function() end", "Fired on click" },
            { "Icon", "string|number", "o", "none", "Vector icon name (Gear/Check/Alert...) or asset id/url" },
        },
        note = "Methods: SetCallback(cb) - for a confirmation use Kailex:Confirm inside the Callback",
        example = [[local b = tab:AddButton({
    Name = "My button",
    Icon = "Gear",
    Confirm = "Are you sure?",
    Callback = function() print("clicked") end,
})
b:HandleAsync(function()
    task.wait(2)
end)]],
    },
    {
        title = "Toggle",
        rows = {
            { "Default", "bool", "o", "false", "Alias: defaultVal" },
            { "Callback", "function", "o", "none", "(state)" },
            { "Pin", "bool", "o", "false", "Draggable floating widget" },
        },
        note = "The Changed(state) signal - the only element with one. On any element: el:AddToggle()",
        example = [[local t = tab:AddToggle({
    Name = "Feature",
    Default = true,
    Pin = true,
    Callback = function(v) print(v) end,
})
t.Changed:Connect(function(v) end)]],
    },
    {
        title = "Slider",
        rows = {
            { "Min", "number", "o", "0", "Alias: MinVal" },
            { "Max", "number", "o", "100", "Alias: MaxVal" },
            { "Step", "number", "o", "auto", "Alias: Increment - 1 or 0.01" },
            { "Default", "number", "o", "Min", "Alias: Value" },
            { "Prefix", "string", "o", "none", "Before the number" },
            { "Suffix", "string", "o", "none", "After the number" },
            { "FireOnRelease", "bool", "o", "false", "Callback only on release" },
        },
        note = "Right-click the track = Reset - arrow keys while hovering = one step",
        example = [[local s = tab:AddSlider({
    Name = "Speed",
    Min = 0, Max = 100, Step = 5, Default = 50,
    Suffix = "%", FireOnRelease = true,
    Callback = function(v) print(v) end,
})]],
    },
    {
        title = "Dropdown",
        rows = {
            { "Options", "array", "r", "{}", "Alias: Items - strings or {Text, Value}" },
            { "Default", "any", "o", "none", "With Multi: Defaults (list)" },
            { "Multi", "bool", "o", "false", "Multi select + All/None buttons" },
            { "Searchable", "bool", "o", "auto", "Turns on automatically above 12 options" },
            { "Callback", "function", "o", "none", "(value) or (values) with Multi" },
        },
        note = "Methods: Set/Get/GetText/CopyValue/Reset/SetOptions - above 60 options: automatic virtualization - arrows + Enter inside the list",
        example = [[local d = tab:AddDropdown({
    Name = "Choice",
    Options = { "A", { Text = "B", Value = 2 } },
    Default = "A",
    Callback = function(v) print(v) end,
})
d:SetOptions({ "Fresh" })]],
    },
    {
        title = "Keybind",
        rows = {
            { "Default", "KeyCode|string", "o", "none", "Enum.KeyCode.B or Key:F or Mouse:MouseButton2" },
            { "Mode", "string", "o", "press", "press | toggle | hold" },
            { "MouseButtons", "bool", "o", "false", "Allow capturing mouse buttons 2/3" },
            { "Callback", "function", "o", "none", "(code, state?)" },
        },
        note = "Automatic conflict detection - listen timeout 6s - Escape while listening = cancel - Methods: Set/Get/GetName/GetState/Reset",
        example = [[local k = tab:AddKeybind({
    Name = "Hotkey",
    Default = Enum.KeyCode.B,
    Mode = "toggle",
    MouseButtons = true,
    Callback = function(code, state) print(code, state) end,
})]],
    },
    {
        title = "TextInput",
        rows = {
            { "Default", "string", "o", '""', "" },
            { "Placeholder", "string", "o", '""', "" },
            { "Validator", "function", "o", "none", "(text) -> bool - rejection: shake + red stroke" },
            { "Callback", "function", "o", "none", "(text) - Enter fires even without changes" },
        },
        example = [[local i = tab:AddTextInput({
    Name = "Player name",
    Placeholder = "Type here...",
    Validator = function(t) return #t < 20 end,
    Callback = function(t) print(t) end,
})]],
    },
    {
        title = "ColorPicker",
        rows = {
            { "Default", "Color3|string", "o", "(122,162,247)", "Alias: Color - accepts #RRGGBB" },
            { "Callback", "function", "o", "none", "(color)" },
        },
        note = "Drag the square/hue bar - hex box and Copy button - shared Recent palette (8)",
        example = [[local c = tab:AddColorPicker({
    Name = "Color",
    Default = "#ff0055",
    Callback = function(color) print(color) end,
})]],
    },
    {
        title = "ProgressBar",
        rows = {
            { "Max", "number", "o", "1", "" },
            { "Value", "number", "o", "0", "" },
            { "ShowText", "bool", "o", "true", "" },
            { "Format", "function", "o", "none", "(v) -> string" },
            { "Callback", "function", "o", "none", "(v)" },
        },
        note = "Set accepts numbers only",
        example = [[local p = tab:AddProgressBar({
    Name = "Loading",
    Max = 100, Value = 0,
    Format = function(v) return v .. "%" end,
})
p:Set(50)]],
    },
    {
        title = "Stepper",
        rows = {
            { "Min", "number", "o", "0", "" },
            { "Max", "number", "o", "10", "" },
            { "Step", "number", "o", "1", "Alias: Increment" },
            { "Default", "number", "o", "Min", "" },
            { "Prefix", "string", "o", "none", "" },
            { "Suffix", "string", "o", "none", "" },
            { "Format", "function", "o", "none", "(v) -> string - overrides Prefix/Suffix" },
            { "Callback", "function", "o", "none", "(v)" },
        },
        note = "Press and hold to repeat - arrow keys while hovering",
        example = [[local st = tab:AddStepper({
    Name = "Count",
    Min = 0, Max = 10, Step = 1,
    Prefix = "x",
    Callback = function(v) end,
})]],
    },
    {
        title = "Segmented",
        rows = {
            { "Options", "array", "r", "{}", "Strings or {Text, Value}" },
            { "Default", "any", "o", "none", "" },
            { "ItemWidth", "number", "o", "56", "" },
            { "Callback", "function", "o", "none", "(value)" },
        },
        example = [[local sg = tab:AddSegmented({
    Name = "Mode",
    Options = { "Attack", "Defense" },
    Default = "Attack",
    Callback = function(v) end,
})]],
    },
    {
        title = "Vector3Input",
        rows = {
            { "Default", "Vector3", "o", "(0,0,0)", "" },
            { "Callback", "function", "o", "none", "(Vector3)" },
        },
        example = [[local v = tab:AddVector3Input({
    Name = "Position",
    Default = Vector3.new(0, 10, 0),
    Callback = function(vec) print(vec) end,
})]],
    },
    {
        title = "DataTable",
        rows = {
            { "Columns", "array", "o", "{}", "Strings or {Name, Width}" },
            { "Rows", "array", "o", "{}", "{Cells={...}, Data=...} or a plain list" },
            { "Height", "number", "o", "200", "" },
            { "Callback", "function", "o", "none", "(Data, Index) on row click" },
        },
        note = "Click a column header = sort - Methods: SetRows(rows, keepSort) / GetRows() / Sort(col, asc)",
        example = [[local dt = tab:AddDataTable({
    Name = "List",
    Columns = { "ID", "Name" },
    Rows = { { Cells = { "1", "Alex" }, Data = 1 } },
    Callback = function(data, index) end,
})]],
    },
    {
        title = "Label",
        rows = {
            { "Text", "string", "o", "Label", "Alias: Name" },
        },
        note = "Accepts a plain string directly: tab:AddLabel(\"some text\")",
        note = "Method: Set(text) - keeps search in sync",
        example = [[local l = tab:AddLabel({ Text = "Important note" })
l:Set("New text")]],
    },
    {
        title = "Paragraph",
        rows = {
            { "Title", "string", "o", '""', "Alias: Name" },
            { "Text", "string", "o", '""', "" },
        },
        note = "Method: Set(text)",
        example = [[local p = tab:AddParagraph({ Title = "Title", Text = "Long explanation..." })
p:Set("New text")]],
    },
    {
        title = "Divider",
        rows = {
            { "Text", "string", "o", "none", "Text inside the line" },
        },
        example = [[tab:AddDivider({ Text = "Advanced settings" })]],
    },
}

local dE = docs:Tab({ Title = "Elements", Icon = "Check" })

dE:AddParagraph({
    Title = "Common options for every element",
    Text = "No option is strictly required; recommended = the element is useless without it. Quoted values are literals.",
})

addDocTable(dE, "Common options", COMMON_ROWS)

for _, d in ipairs(ELEMENT_DOCS) do
    dE:AddSection(d.title)
    addDocTable(dE, d.title .. " options", d.rows)
    if d.note then dE:AddLabel({ Text = d.note }) end
    if d.example then addExample(dE, d.example) end
end

local dW = docs:Tab({ Title = "Window & Overlays", Icon = "Search" })

dW:AddSection("CreateWindow")

addDocTable(dW, "Window options", {
    { "Title", "string", "o", "Kailex", "Alias: Name" },
    { "SubTitle", "string", "o", "none", "Secondary line under the title" },
    { "MinSize", "Vector2", "o", "(380,280)", "" },
    { "Icon", "string|number", "o", "none", "Vector or asset" },
    { "ToggleKey", "KeyCode|string", "o", "none", "Show/hide this window only" },
    { "RememberPosition", "bool", "o", "true", "Persist position and size" },
    { "ConfirmClose", "string|true", "o", "none", "Confirm before closing" },
})

addExample(dW, [[local win = Kailex:CreateWindow({
    Title = "My window",
    SubTitle = "Secondary line",
    MinSize = Vector2.new(380, 280),
    Icon = "Gear",
    ToggleKey = "Key:J",
    RememberPosition = true,
    ConfirmClose = "Close this window?",
})
win:SetSize(720, 520)]])

dW:AddSection("Tab")

addDocTable(dW, "Tab options", {
    { "Title", "string", "o", "Tab", "Alias: Name" },
    { "Icon", "string|number", "o", "none", "" },
})

addExample(dW, [[local tab = win:Tab({ Title = "Main", Icon = "Check" })
tab:AddSection({ Name = "General", Columns = 2 })
tab:AddToggle({ Name = "Feature", Default = true, Callback = function(v) end })]])

dW:AddLabel({ Text = "Every element added after AddSection lands inside that section until the next one." })

dW:AddSection("Section")

addDocTable(dW, "Section options", {
    { "Name", "string", "o", "Section", "" },
    { "Columns", "number", "o", "1", "1-6 - section elements in a grid" },
    { "Collapsed", "bool", "o", "none", "Start collapsed - aliases: Open / Expanded (inverted)" },
})

dW:AddSection("GridRow and the grid")

dW:AddParagraph({
    Title = "Grid rows",
    Text = "AddRow(cols) creates a manual row: add elements through row:Add* with Span. Or automatically: any element with Width below 0.95.",
})

addExample(dW, [[local row = tab:AddRow(3)
row:AddButton({ Name = "A", Callback = function() end })
row:AddButton({ Name = "B (Span=2)", Span = 2, Callback = function() end })
tab:AddButton({ Name = "Half", Width = 0.5, Callback = function() end })]])

dW:AddSection("Notify")

addDocTable(dW, "Notification options", {
    { "Title", "string", "o", "Notice", "" },
    { "Text", "string", "o", '""', "Alias: Description" },
    { "Type", "string", "o", "info", "info | success | warning | error" },
    { "Duration", "number", "o", "4", "Seconds - minimum 0.5" },
    { "Actions", "array", "o", "none", "{{Text, Callback}} - up to 3 buttons" },
})

addExample(dW, [[Kailex:Notify({
    Title = "Saved",
    Text = "The file was saved successfully",
    Type = "success",
    Duration = 5,
    Actions = {
        { Text = "Open", Callback = function() end },
    },
})]])

dW:AddSection("Confirm")

addDocTable(dW, "Confirm options", {
    { "Title", "string", "o", "Are you sure?", "" },
    { "Text", "string", "o", '""', "Alias: Description" },
    { "Type", "string", "o", "none", "danger or info" },
    { "Danger", "bool", "o", "false", "Danger style (alias for Type)" },
    { "AcceptText", "string", "o", "Confirm", "Alias: ConfirmText" },
    { "DeclineText", "string", "o", "Cancel", "Alias: CancelText" },
    { "OnDecline", "function", "o", "none", "On decline (Escape/backdrop/button)" },
})

dW:AddLabel({ Text = "Second argument = onAccept - Enter accepts - Escape declines - simultaneous calls queue up" })

addExample(dW, [[Kailex:Confirm({
    Title = "Delete the item?",
    Text = "This cannot be undone",
    Danger = true,
    AcceptText = "Delete",
    DeclineText = "Keep",
    OnDecline = function() end,
}, function()
    print("accepted")
end)]])

dW:AddSection("KeySystem")

addDocTable(dW, "Key system options", {
    { "Key", "any", "o", "none", "A single key (any type)" },
    { "Keys", "array", "o", "none", "A list of keys" },
    { "Verify", "function", "o", "none", "(key)->bool - aliases: CustomVerify / CheckKey" },
    { "OnComplete", "function", "r", "none", "(key) - aliases: Callback" },
    { "OnDecline", "function", "o", "none", "Aliases: OnCancel" },
    { "OnWrong", "function", "o", "none", "(key)" },
    { "OnBlacklisted", "function", "o", "none", "(name)" },
    { "Whitelist", "array", "o", "none", "Names - or CheckWhitelist(name)->bool" },
    { "Blacklist", "array", "o", "none", "Names - or CheckBlacklist(name)->bool" },
    { "BlacklistMessage", "string", "o", "You are not allowed...", "Rejection text" },
    { "Title", "string", "o", "Key System", "" },
    { "Description", "string", "o", "Enter your key to continue.", "Alias: SubTitle" },
    { "Link", "string", "o", "none", "Get-key link - alias: GetKeyLink" },
    { "Remember", "bool", "o", "true", "Persist the key" },
    { "DeclineAction", "string", "o", "hide", "Alias: DeclineMode - hide | unload | none" },
    { "DeclineText", "string", "o", "Decline", "" },
    { "LinkText", "string", "o", "Get Key", "" },
    { "Silent", "bool", "o", "false", "Mute the welcome notifications" },
})

addExample(dW, [[Kailex:KeySystem({
    Key = "MY-KEY-123",
    Link = "https://site.com/key",
    OnComplete = function(key) print("welcome", key) end,
    OnDecline = function() print("declined") end,
})]])

local dA = docs:Tab({ Title = "API", Icon = "Info" })

dA:AddSection("Kailex - global")

addApiTable(dA, "Global functions", {
    { "Kailex:CreateWindow(cfg)", "Window", "Create a window" },
    { "Kailex:Notify(data)", "-", "Send a notification" },
    { "Kailex:Confirm(data, onAccept)", "-", "Confirmation dialog" },
    { "Kailex:KeySystem(opts)", "card|nil", "Key gate" },
    { "Kailex:CreateSettingsTab(win)", "Tab", "Ready-made settings tab: theme/scale/sounds/profiles" },
    { "Kailex:SetVisible(bool) / IsVisible()", "-", "Show/hide the whole interface" },
    { "Kailex:GetNotificationLog()", "{Title,Text,Type,Time}", "Last 50 notifications" },
    { "Kailex:GetThemes() / SetTheme(name)", "-", "Themes" },
    { "Kailex:RegisterTheme / RemoveTheme / SaveCustomThemes", "-", "Custom themes" },
    { "Kailex:Unload()", "-", "Full clean teardown" },
    { "Kailex.Version / .Audio / .Windows / .Setting", "-", "Public fields" },
})

dA:AddSection("Window - functions")

addApiTable(dA, "Window functions", {
    { "win:Tab({Title, Icon})", "Tab", "New tab" },
    { "win:SetTitle(t)", "-", "Update the title" },
    { "win:Close([true]) / Destroy()", "-", "Close - true skips the confirmation" },
    { "win.MinimizedChanged / win.Closed", "Signal", "Window signals" },
    { "Right-click the title bar", "-", "Menu: minimize/always on top/close" },
})

dA:AddSection("Element - common")

addApiTable(dA, "Functions on every element", {
    { "el:SetTitle(t) / SetTooltip(t) / SetDescription(t)", "-", "Live text updates" },
    { "el:Visible(bool | nil)", "-", "nil = toggle" },
    { "el:SetDisabled(bool) / IsDisabled()", "-", "Interactive disable" },
    { "el:AddToggle(opts)", "Toggle", "Attached enable switch - adds SetEnabled/IsEnabled/Enabled" },
    { "el:Destroy()", "-", "Clean destroy" },
    { "Right-click / long-press an element", "-", "Context menu: Copy value / Reset / Disable" },
})

dA:AddSection("Built-in interactions")

dA:AddParagraph({
    Title = "No code needed",
    Text = "Ctrl+F: search the current tab - Escape: close the topmost overlay - RightShift: show/hide the interface (changeable in settings) - arrow keys move Slider/Stepper while hovering - drag the title bar to move - bottom grip to resize - splitter for sidebar width - on mobile: floating button toggles visibility.",
})

logEvent("Playground", "Loaded", Kailex.Version)
print("Kailex Playground loaded - Version:", Kailex.Version)

Kailex:Notify({
    Title = "Kailex Playground",
    Text = "Every feature is live - explore the Playground tabs and the Guide window",
    Type = "success",
    Duration = 6,
})
