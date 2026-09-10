local Kailex = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USER/kailex/main/dist/Kailex.lua"
))()

Kailex:Notify({
    Title = "Welcome!",
    Text = "Click, drag, and interact with everything. Right-click any element for options.",
    Type = "Success",
    Duration = 6,
})

local win = Kailex:CreateWindow({
    Title = "Kailex Playground",
    SubTitle = "Interactive documentation",
    Size = Vector2.new(680, 480),
})

local output = ""

local function show(text)
    output = text
    Kailex:Notify({ Title = "Result", Text = text, Type = "Info", Duration = 3 })
end

local T1 = win:Tab({ Title = "Basics" })
local T2 = win:Tab({ Title = "Buttons" })
local T3 = win:Tab({ Title = "Sliders" })
local T4 = win:Tab({ Title = "Selectors" })
local T5 = win:Tab({ Title = "Inputs" })
local T6 = win:Tab({ Title = "Display" })
local T7 = win:Tab({ Title = "Dialogs" })
local T8 = win:Tab({ Title = "Layout" })
local T9 = win:Tab({ Title = "System" })

T1:AddParagraph({
    Title = "How this works",
    Text = "Every element here is real and interactive. Try them! " ..
        "Hover elements for tooltips. Right-click for context menu. " ..
        "Drag the title bar to move. Double-click it to maximize. " ..
        "Drag the corner to resize. Press RightShift to hide/show.",
})

T1:AddSection({ Name = "Sections" })

T1:AddParagraph({
    Title = "This is a Section",
    Text = "Sections group elements. Click the header to collapse/expand. " ..
        "Set Columns = 2 to place elements side by side.",
})

T1:AddDivider({ Text = "Try it" })

T1:AddButton({
    Name = "Show Notification",
    Description = "Demonstrates Kailex:Notify()",
    Callback = function()
        Kailex:Notify({
            Title = "Hello!",
            Text = "This notification was triggered by a button click.",
            Type = "Success",
            Duration = 4,
            Actions = {
                { Text = "Again", Callback = function()
                    Kailex:Notify({ Title = "Again!", Text = "You clicked an action button.", Type = "Info" })
                end },
            },
        })
    end,
})

T1:AddToggle({
    Name = "Enable Sounds",
    Description = "Turn on UI sounds, then click things",
    Default = false,
    Pin = true,
    Callback = function(v)
        Kailex.Setting.Sounds = v
        show("Sounds: " .. tostring(v))
    end,
})

T2:AddSection({ Name = "Buttons" })

T2:AddButton({
    Name = "Simple Button",
    Description = "Callback fires on click",
    Callback = function() show("Button clicked!") end,
})

T2:AddButton({
    Name = "Confirm Button",
    Description = "Shows dialog before callback",
    Confirm = "This action requires confirmation. Continue?",
    Callback = function() show("Confirmed and executed!") end,
})

T2:AddButton({
    Name = "Button with Icon",
    Description = "Icon asset id option",
    Icon = "rbxassetid://6031082533",
    Callback = function() show("Icon button clicked!") end,
})

T2:AddSection({ Name = "Toggle + Button Combo" })

local comboBtn = T2:AddButton({
    Name = "Feature Button",
    Description = "Has an attached toggle on the right",
    Callback = function()
        show("Feature is " .. (comboBtn:IsEnabled() and "ON" or "OFF"))
    end,
})
comboBtn:AddToggle({ Default = true })

T2:AddDivider()

T2:AddParagraph({
    Title = "Busy State",
    Text = "Click this button to see the loading spinner, then click again to stop.",
})

local busyBtn
busyBtn = T2:AddButton({
    Name = "Toggle Busy State",
    Callback = function()
        busyBtn:SetBusy(not busyBtn._busy)
    end,
})

T3:AddSection({ Name = "Sliders" })

local sliderLabel = T3:AddLabel({ Text = "Value: 50" })

T3:AddSlider({
    Name = "Integer Slider",
    Description = "Min=0, Max=100, Default=50",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(v)
        sliderLabel:Set("Value: " .. math.floor(v))
    end,
})

T3:AddSlider({
    Name = "Decimal Slider",
    Description = "Increment=0.05, drag it slowly",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Increment = 0.05,
    Callback = function(v) show("Opacity: " .. string.format("%.2f", v)) end,
})

T3:AddSlider({
    Name = "Slider with Prefix/Suffix",
    Description = "Suffix = ' studs', Prefix = 'Speed'",
    Min = 16,
    Max = 200,
    Default = 16,
    Prefix = "Speed ",
    Suffix = " studs",
    Callback = function(v) end,
})

T3:AddSlider({
    Name = "FireOnRelease Slider",
    Description = "Callback only fires when you release, not while dragging",
    Min = 0,
    Max = 100,
    Default = 0,
    FireOnRelease = true,
    Callback = function(v) show("Released at: " .. math.floor(v)) end,
})

T3:AddParagraph({
    Title = "Keyboard Control",
    Text = "Hover any slider row, then use Left/Right arrow keys. " ..
        "Hold Shift for fine adjustment (20% of step).",
})

T3:AddSection({ Name = "Stepper" })

local stepper = T3:AddStepper({
    Name = "Stepper (+/- buttons)",
    Description = "Hold buttons to auto-repeat",
    Min = 0,
    Max = 50,
    Step = 1,
    Default = 10,
    Callback = function(v) show("Stepper: " .. v) end,
})

T4:AddSection({ Name = "Dropdowns" })

T4:AddDropdown({
    Name = "Single Selection",
    Description = "Returns the Value, not the text",
    Options = {
        { Text = "Speed 16",  Value = 16 },
        { Text = "Speed 32",  Value = 32 },
        { Text = "Speed 50",  Value = 50 },
        { Text = "Speed 100", Value = 100 },
    },
    Default = 16,
    Callback = function(v) show("Selected value: " .. v) end,
})

T4:AddDropdown({
    Name = "Multi Selection",
    Description = "Click multiple options, returns array",
    Options = { "Apple", "Banana", "Cherry", "Date", "Elderberry" },
    Multi = true,
    Callback = function(v) show("Selected: " .. table.concat(v, ", ")) end,
})

T4:AddDropdown({
    Name = "Searchable Dropdown",
    Description = "12+ options auto-show search box",
    Options = { "Alpha","Bravo","Charlie","Delta","Echo","Foxtrot",
        "Golf","Hotel","India","Juliet","Kilo","Lima","Mike","November",
        "Oscar","Papa","Quebec","Romeo","Sierra","Tango" },
    Callback = function(v) show("Selected: " .. tostring(v)) end,
})

T4:AddSection({ Name = "Segmented Control" })

T4:AddSegmented({
    Name = "Mode Selector",
    Description = "Exclusive choice, compact buttons",
    Options = { "Off", "Low", "Medium", "High" },
    Default = "Off",
    Callback = function(v) show("Mode: " .. v) end,
})

T4:AddSection({ Name = "Color Picker" })

local colorPreview = T4:AddLabel({ Text = "Click the swatch to open" })

T4:AddColorPicker({
    Name = "Pick a Color",
    Description = "Opens HSV square + hue bar + hex input",
    Default = Color3.fromRGB(122, 162, 247),
    Callback = function(c)
        colorPreview:Set(string.format("RGB: %d, %d, %d",
            c.R * 255, c.G * 255, c.B * 255))
    end,
})

T4:AddSection({ Name = "Keybind" })

T4:AddKeybind({
    Name = "Press this key",
    Description = "Click button, then press any key",
    Default = Enum.KeyCode.F,
    Callback = function(key) show("Key pressed: " .. tostring(key)) end,
})

T4:AddKeybind({
    Name = "Mouse Button Bind",
    Description = "MouseButtons=true allows right/middle click",
    MouseButtons = true,
    Callback = function(key) show("Mouse: " .. tostring(key)) end,
})

T5:AddSection({ Name = "Text Input" })

T5:AddTextInput({
    Name = "Basic Input",
    Placeholder = "Type something...",
    Callback = function(text) show("You typed: " .. text) end,
})

T5:AddTextInput({
    Name = "Validated Input",
    Description = "Rejects input longer than 10 characters",
    Placeholder = "Max 10 chars",
    Validator = function(text)
        return #text <= 10
    end,
    Callback = function(text) show("Valid: " .. text) end,
})

T5:AddSection({ Name = "Vector3 Input" })

T5:AddVector3Input({
    Name = "Position",
    Description = "Three numeric fields: X, Y, Z",
    Default = Vector3.new(0, 50, 0),
    Callback = function(v) show("Position: " .. tostring(v)) end,
})

T6:AddSection({ Name = "Display Elements" })

T6:AddLabel({ Text = "This is a Label - simple text display" })

T6:AddParagraph({
    Title = "This is a Paragraph",
    Text = "Paragraphs display long text that wraps automatically. " ..
        "Use Set() to change the text after creation.",
})

T6:AddDivider({ Text = "Divider with text" })

T6:AddDivider()

T6:AddSection({ Name = "Progress Bars" })

local progress = T6:AddProgressBar({
    Name = "Download Progress",
    BarWidth = 200,
    Max = 100,
    Value = 0,
})

local progressValue = 0
T6:AddButton({
    Name = "Add 20% Progress",
    Callback = function()
        progressValue = math.min(100, progressValue + 20)
        progress:Set(progressValue)
    end,
})

T6:AddButton({
    Name = "Start Indeterminate",
    Description = "Animated loading bar",
    Callback = function() progress:Set(true) end,
})

T6:AddButton({
    Name = "Stop Indeterminate",
    Callback = function() progress:Set(false) end,
})

T6:AddSection({ Name = "Data Table" })

T6:AddDataTable({
    Name = "Player List",
    Description = "Click headers to sort, click rows to select",
    Columns = {
        { Name = "Player", Width = 120 },
        { Name = "Kills",  Width = 70 },
        { Name = "Deaths", Width = 70 },
    },
    Rows = {
        { "Alice", 25, 3 },
        { "Bob", 18, 7 },
        { "Charlie", 32, 1 },
        { "Dave", 5, 12 },
    },
    Height = 140,
    Callback = function(data, index)
        show("Clicked row " .. index .. ": " .. tostring(data[1]))
    end,
})

T7:AddSection({ Name = "Notifications" })

T7:AddParagraph({
    Title = "4 Types",
    Text = "Each type has a different colored dot. Hover to pause the timer.",
})

for _, type in ipairs({ "Info", "Success", "Warning", "Error" }) do
    T7:AddButton({
        Name = type .. " Notification",
        Callback = function()
            Kailex:Notify({
                Title = type,
                Text = "This is a " .. string.lower(type) .. " notification.",
                Type = type,
            })
        end,
    })
end

T7:AddButton({
    Name = "With Action Buttons",
    Description = "Up to 3 buttons per notification",
    Callback = function()
        Kailex:Notify({
            Title = "File Deleted",
            Text = "config.json has been removed.",
            Type = "Warning",
            Duration = 8,
            Actions = {
                { Text = "Undo", Callback = function()
                    Kailex:Notify({ Title = "Restored", Text = "File recovered.", Type = "Success" })
                end },
                { Text = "Dismiss", Callback = function() end },
            },
        })
    end,
})

T7:AddSection({ Name = "Confirm Dialog" })

T7:AddButton({
    Name = "Show Confirm Dialog",
    Description = "Enter = accept, Escape = decline",
    Callback = function()
        Kailex:Confirm({
            Title = "Reset everything?",
            Text = "All settings will be cleared.",
            AcceptText = "Reset",
            DeclineText = "Cancel",
        }, function()
            show("Confirmed!")
        end)
    end,
})

T7:AddSection({ Name = "Key System Demo" })

T7:AddButton({
    Name = "Show Key System",
    Description = "Password is: demo123",
    Callback = function()
        Kailex:KeySystem({
            Title = "Demo Key System",
            Description = "The key is 'demo123'. Try wrong keys first.",
            Key = "demo123",
            MaxAttempts = 5,
            OnComplete = function(key)
                Kailex:Notify({ Title = "Access Granted", Text = "Key accepted: " .. key, Type = "Success" })
            end,
        })
    end,
})

T8:AddSection({ Name = "Grid Layout", Columns = 3 })

T8:AddParagraph({
    Title = "3-Column Grid",
    Text = "Elements flow into columns automatically. " ..
        "Use Tab:AddRow(3) for manual rows, or Section Columns for automatic.",
    Width = 1,
})

T8:AddButton({ Name = "Col 1" })
T8:AddToggle({ Name = "Col 2" })
T8:AddSlider({ Name = "Col 3", Min = 0, Max = 10 })
T8:AddButton({ Name = "Row 2 Col 1" })
T8:AddToggle({ Name = "Row 2 Col 2" })

T8:AddSection({ Name = "Manual Grid Row" })

local row = T8:AddRow(2)
row:AddButton({
    Name = "Half Width A",
    Callback = function() show("Button A") end,
})
row:AddButton({
    Name = "Half Width B",
    Callback = function() show("Button B") end,
})

T8:AddSection({ Name = "Element Methods" })

local demoTgl
demoTgl = T8:AddToggle({ Name = "Demo Toggle", Default = true })

T8:AddButton({
    Name = "Disable/Enable Toggle",
    Callback = function()
        demoTgl:SetDisabled(not demoTgl:IsDisabled())
    end,
})

T8:AddButton({
    Name = "Hide/Show Toggle",
    Callback = function()
        demoTgl:Visible(not demoTgl.Row.Visible)
    end,
})

T8:AddButton({
    Name = "Rename Toggle",
    Callback = function()
        demoTgl:SetTitle("Renamed " .. os.clock())
    end,
})

T8:AddButton({
    Name = "Destroy Toggle",
    Description = "Removes the element permanently",
    Callback = function()
        demoTgl:Destroy()
    end,
})

T9:AddSection({ Name = "Themes" })

T9:AddDropdown({
    Name = "Switch Theme",
    Description = "Changes colors instantly",
    Options = Kailex:GetThemes(),
    Default = Kailex.Setting.Theme,
    Callback = function(name)
        Kailex:SetTheme(name)
    end,
})

T9:AddSection({ Name = "Save System" })

T9:AddParagraph({
    Title = "Auto-Save",
    Text = "Every toggle, slider, dropdown, keybind, text input, and color picker " ..
        "saves its value automatically. Values persist between sessions " ..
        "(per PlaceId, requires executor filesystem).",
})

T9:AddButton({
    Name = "Save Profile",
    Callback = function()
        if Kailex.Configs:Save("demo") then
            show("Profile 'demo' saved")
        else
            show("Filesystem not available")
        end
    end,
})

T9:AddButton({
    Name = "Load Profile",
    Callback = function()
        if Kailex.Configs:Load("demo") then
            show("Profile 'demo' loaded")
        else
            show("Profile not found")
        end
    end,
})

T9:AddSection({ Name = "Window Features" })

T9:AddParagraph({
    Title = "Built-in Features",
    Text = "Search: Click the magnifying glass icon in the title bar. " ..
        "Minimize: Click the minus icon. " ..
        "Maximize: Double-click the title bar. " ..
        "Resize: Drag the bottom-right corner. " ..
        "Sidebar: Drag its edge to resize. " ..
        "Hide/Show: Press RightShift. " ..
        "Context Menu: Right-click any element.",
})

T9:AddDivider({ Text = "Library Info" })

T9:AddLabel({ Text = "Version: " .. Kailex.Version })
T9:AddLabel({ Text = "Windows open: " .. #Kailex.Windows })

T9:AddButton({
    Name = "Unload Everything",
    Description = "Destroys the entire UI",
    Callback = function()
        Kailex:Confirm({
            Title = "Unload?",
            Text = "This removes the UI completely.",
        }, function()
            Kailex:Unload()
        end)
    end,
})

Kailex:CreateSettingsTab(win)

print("Kailex Playground loaded - Version:", Kailex.Version)
