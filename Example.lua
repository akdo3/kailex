local Kailex = require(game:GetService("ReplicatedStorage"):FindFirstChild("Window"))

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local USE_KEY_SYSTEM = false

Kailex.Setting.SaveFolder = "KailexDemo"
Kailex.Setting.Sounds = true
Kailex.Setting.Effects = true
Kailex.Setting.AutoSave = true
Kailex.Setting.UIScale = 1
Kailex.Setting.TextScale = 1.1
Kailex.Setting.MotionScale = 1
Kailex.Setting.ToggleUIKey = Enum.KeyCode.RightShift

Kailex.Audio.Master = 0.8
Kailex.Audio.Click.Vol = 0.5
Kailex.Audio.Hover.Vol = 0.06

Kailex.ThemeChanged:Connect(function(theme)
	print("[Kailex] theme applied, accent:", theme.Accent)
end)

Kailex.ThemeChanged:Once(function()
	print("[Kailex] first theme change captured via Once")
end)

if USE_KEY_SYSTEM then
	Kailex:KeySystem({
		Title = "Premium Access",
		SubTitle = "Enter your key to use this script.",
		Secret = "KailexDemoSecret",
		Key = {
			["FREE-2024"] = 3600,
			["VIP-FOREVER"] = 86400,
		},
		Link = "https://example.com/getkey",
		Expiry = 3600,
		Whitelist = { "BestFriend" },
		Blacklist = { "Scammer123" },
		Silent = false,
		BindHardware = true,
	})
end

local win = Kailex:Window({
	Title = "Kailex Demo",
	SubTitle = "every feature in one script",
	SaveKey = "DemoScript",
	ToggleKey = Enum.KeyCode.F,
	RememberPosition = true,
	Settings = true,
})

win.MinimizedChanged:Connect(function(minimized)
	print("[Window] minimized:", minimized)
end)

win.Closed:Connect(function()
	print("[Window] closed:", win.Title)
end)

local tabBasic = win:Tab({ Title = "Basic", Icon = "Gear" })

tabBasic:Section("Buttons")

tabBasic:Button({
	Name = "Simple button",
	Description = "Right-click me for the context menu (Copy / Reset / Disable)",
	Callback = function()
		Kailex:Notify({ Title = "Clicked", Text = "Simple button was pressed.", Type = "Info", Duration = 3 })
	end,
})

tabBasic:Button({
	Name = "Confirmation button",
	Description = "Asks before running (Confirm option)",
	Confirm = "This will teleport you high up. Continue?",
	Callback = function()
		local char = Player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = CFrame.new(0, 80, 0)
		end
	end,
})

local iconBtn = tabBasic:Button({
	Name = "Icon button",
	Icon = "rbxassetid://6031280882",
	Callback = function()
		print("icon button clicked")
	end,
})

iconBtn:SetCallback(function()
	print("callback replaced with SetCallback")
end)

busyBtn = tabBasic:Button({
	Name = "Async button (SetBusy)",
	Description = "Shows a spinner for 3 seconds",
	Callback = function()
		busyBtn:SetBusy(true)
		task.delay(3, function()
			busyBtn:SetBusy(false)
			Kailex:Notify({ Title = "Done", Text = "Async work finished.", Type = "Success" })
		end)
	end,
})

tabBasic:Section("Toggles")

local flyToggle = tabBasic:Toggle({
	Name = "Fly",
	Description = "Pin = keeps a floating quick-widget on screen",
	Default = false,
	Pin = true,
	Callback = function(state)
		print("Fly:", state)
	end,
})

flyToggle.Changed:Connect(function(state)
	print("Fly changed (signal):", state)
end)

tabBasic:Toggle({
	Name = "Square style",
	Description = "Toggle with Style = true",
	Style = true,
	Default = true,
	Callback = function(state)
		print("Square:", state)
	end,
})

local savedToggle = tabBasic:Toggle({
	Name = "Saved toggle",
	Description = "Uses a custom SaveKey, persists between sessions",
	SaveKey = "DemoScript/Extras/SavedToggle",
	Default = false,
	Callback = function(state)
		print("Saved:", state)
	end,
})

tabBasic:Button({
	Name = "Force saved toggle on",
	Callback = function()
		savedToggle:Set(true)
		print("Get:", savedToggle:Get())
	end,
})

tabBasic:Section("Sliders")

local speedSlider = tabBasic:Slider({
	Name = "WalkSpeed",
	Description = "Drag / type / arrow keys (Shift = fine step)",
	Min = 16,
	Max = 100,
	Default = 16,
	Suffix = " st/s",
	Callback = function(value)
		local char = Player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = value
		end
	end,
})

tabBasic:Slider({
	Name = "Float slider",
	Min = 0,
	Max = 1,
	Increment = 0.05,
	Default = 0.5,
	Prefix = "x",
	Callback = function(value)
		print("Float:", value)
	end,
})

tabBasic:Slider({
	Name = "Fire on release",
	Description = "Callback runs only when you release (FireOnRelease)",
	Min = 0,
	Max = 10,
	Default = 5,
	FireOnRelease = true,
	Callback = function(value)
		print("Released at:", value)
	end,
})

tabBasic:Divider({ Text = "Text elements" })

local infoLabel = tabBasic:Label({ Text = "A simple label" })

task.delay(5, function()
	infoLabel:Set("Label text updated after 5 seconds")
end)

local aboutPara = tabBasic:Paragraph({
	Title = "About",
	Text = "Kailex is a compact Roblox UI library. This paragraph element wraps long body text automatically.",
})

tabBasic:Button({
	Name = "Update paragraph",
	Callback = function()
		aboutPara:Set("Paragraph body replaced with Set() at " .. os.date("%X"))
	end,
})

local tabInputs = win:Tab({ Title = "Inputs" })

tabInputs:Section("Dropdowns")

local weaponDrop = tabInputs:Dropdown({
	Name = "Weapon",
	Description = "Single select with Text/Value options",
	Options = {
		{ Text = "Sword", Value = "sword" },
		{ Text = "Bow", Value = "bow" },
		{ Text = "Staff", Value = "staff" },
	},
	Default = "sword",
	Callback = function(value)
		print("Weapon:", value)
	end,
})

local multiDrop = tabInputs:Dropdown({
	Name = "Targets",
	Description = "Multi select with All / None and search box",
	Multi = true,
	Options = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
	Defaults = { "Head", "Torso" },
	Searchable = true,
	Callback = function(values)
		print("Targets:", table.concat(values, ", "))
	end,
})

local weaponSets = {
	{ "Pistol", "Rifle", "Sniper" },
	{ "Knife", "Axe", "Machete" },
	{ "Fire", "Ice", "Lightning" },
}
local setIndex = 1

tabInputs:Button({
	Name = "Swap weapon options",
	Callback = function()
		setIndex = setIndex % #weaponSets + 1
		local set = weaponSets[setIndex]
		weaponDrop:SetOptions(set)
		weaponDrop:Set(set[1], true)
	end,
})

tabInputs:Button({
	Name = "Select only Head",
	Callback = function()
		multiDrop:Set({ "Head" })
	end,
})

tabInputs:Button({
	Name = "Print current selections",
	Callback = function()
		print("Weapon:", weaponDrop:Get(), "/", weaponDrop:GetText())
		print("Targets:", table.concat(multiDrop:Get(), ", "))
		print("Target texts:", table.concat(multiDrop:GetText(), ", "))
	end,
})

tabInputs:Section("Text & numbers")

local nameInput = tabInputs:TextInput({
	Name = "Player name",
	Placeholder = "type a username...",
	Default = Player.Name,
	Callback = function(text)
		print("Name:", text)
	end,
})

tabInputs:TextInput({
	Name = "Numbers only",
	Description = "Validator rejects anything that is not digits",
	Placeholder = "0-999",
	Validator = function(text)
		return text:match("^%d*$") ~= nil
	end,
	Callback = function(text)
		print("Number:", text)
	end,
})

tabInputs:Button({
	Name = "Fill name input",
	Callback = function()
		nameInput:Set("Player" .. math.random(1000))
		print("Name now:", nameInput:Get())
	end,
})

local stepA = tabInputs:Stepper({
	Name = "Stepper",
	Description = "Hold a button to keep stepping",
	Min = 0,
	Max = 50,
	Step = 5,
	Default = 25,
	Suffix = " pcs",
	Callback = function(value)
		print("Stepper:", value)
	end,
})

tabInputs:Stepper({
	Name = "Stepper (Format)",
	Min = 1,
	Max = 10,
	Step = 1,
	Default = 3,
	Format = function(value)
		return "#" .. value
	end,
	Callback = function(value)
		print("Formatted stepper:", value)
	end,
})

tabInputs:Button({
	Name = "Step up + HandleArrow",
	Callback = function()
		stepA:Set(stepA:Get() + 5)
		stepA:HandleArrow(1)
		print("Stepper value:", stepA:Get())
	end,
})

local diffSeg = tabInputs:Segmented({
	Name = "Difficulty",
	Options = { "Easy", "Normal", "Hard", "Insane" },
	ItemWidth = 62,
	Default = "Normal",
	Callback = function(value)
		print("Difficulty:", value)
	end,
})

tabInputs:Button({
	Name = "Select Hard",
	Callback = function()
		diffSeg:Set("Hard")
		print("Segmented Get:", diffSeg:Get())
	end,
})

local tpVec = tabInputs:Vector3Input({
	Name = "Teleport offset",
	Default = Vector3.new(0, 10, 0),
	Callback = function(vec)
		print("Offset:", vec)
	end,
})

tabInputs:Button({
	Name = "Set offset to (0, 25, 0)",
	Callback = function()
		tpVec:Set(Vector3.new(0, 25, 0))
		print("Vector Get:", tpVec:Get())
	end,
})

tabInputs:Section("Binds & colors")

local healBind = tabInputs:Keybind({
	Name = "Heal keybind",
	Description = "Right-click the key button to clear it",
	Default = Enum.KeyCode.H,
	MouseButtons = true,
	Callback = function(code)
		local char = Player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = math.min(hum.MaxHealth, hum.Health + 25)
			Kailex:Notify({ Title = "Healed", Text = "+25 HP via " .. code.Name, Type = "Success", Duration = 2 })
		end
	end,
})

tabInputs:Button({
	Name = "Rebind to G",
	Callback = function()
		healBind:Set(Enum.KeyCode.G)
		print("Now bound to:", healBind:GetName(), "/", healBind:Get())
	end,
})

local auraColor = tabInputs:ColorPicker({
	Name = "Aura color",
	Description = "Full picker: SV square, hue bar, hex box, copy, reset",
	Default = Color3.fromRGB(120, 80, 255),
	Callback = function(color)
		print("Color:", color)
	end,
})

tabInputs:Button({
	Name = "Random color",
	Callback = function()
		auraColor:Set(Color3.fromHSV(math.random(), 1, 1))
		print("Color Get:", auraColor:Get())
	end,
})

local tabAdv = win:Tab({ Title = "Advanced" })

tabAdv:Section({ Name = "Grid 3 columns", Columns = 3 })

tabAdv:Button({ Name = "Span 1", Span = 1, Callback = function() print("A") end })
tabAdv:Button({ Name = "Span 2", Span = 2, Callback = function() print("B") end })
tabAdv:Toggle({ Name = "Span 1", Span = 1, Default = true, Callback = function(v) print("C", v) end })
tabAdv:Button({ Name = "Span 3 (full row)", Span = 3, Callback = function() print("D") end })

tabAdv:Section({ Name = "Two columns", Columns = 2 })

tabAdv:Stepper({ Name = "Left", Span = 1, Min = 0, Max = 9, Callback = function(v) print("L", v) end })
tabAdv:Stepper({ Name = "Right", Span = 1, Min = 0, Max = 9, Callback = function(v) print("R", v) end })
tabAdv:Button({ Name = "Wide (Span 2)", Span = 2, Callback = function() print("wide") end })

tabAdv:Section("Half width (Width option)")

tabAdv:Button({ Name = "Left half", Width = 0.5, Callback = function() print("left") end })
tabAdv:Button({ Name = "Right half", Width = 0.5, Callback = function() print("right") end })

tabAdv:Section({ Name = "Collapsible section", Collapsed = true })

tabAdv:Label({ Text = "Hidden until you expand the section" })
tabAdv:Toggle({ Name = "Inside collapsible", Default = false, Callback = function(v) print(v) end })

tabAdv:Section("Element control")

local demoSlider = tabAdv:Slider({
	Name = "Demo slider",
	Min = 0,
	Max = 100,
	Default = 42,
	Callback = function(value)
		print("Demo slider:", value)
	end,
})

tabAdv:Button({
	Name = "Rename demo slider",
	Callback = function()
		demoSlider:SetTitle("Renamed " .. tostring(math.floor(os.clock())))
	end,
})

tabAdv:Button({
	Name = "Change demo slider tooltip",
	Callback = function()
		demoSlider:SetTooltip("Tooltip updated at " .. os.date("%X"))
	end,
})

tabAdv:Button({
	Name = "Disable / enable demo slider",
	Callback = function()
		demoSlider:SetDisabled(not demoSlider:IsDisabled())
	end,
})

tabAdv:Button({
	Name = "Hide / show demo slider",
	Callback = function()
		demoSlider:Visible()
	end,
})

tabAdv:Button({
	Name = "Random slider value",
	Callback = function()
		demoSlider:Set(math.random(0, 100))
		print("Slider Get:", demoSlider:Get())
	end,
})

tabAdv:Button({
	Name = "Reset demo slider",
	Callback = function()
		demoSlider:Reset()
	end,
})

local doomed = tabAdv:Label({ Text = "This label gets destroyed" })

tabAdv:Button({
	Name = "Destroy the label",
	Callback = function()
		doomed:Destroy()
	end,
})

tabAdv:Section("Attached toggle & Extra")

local featureSlider = tabAdv:Slider({
	Name = "Feature with enable",
	Min = 0,
	Max = 100,
	Default = 50,
	Callback = function(value)
		print("Feature value:", value)
	end,
})

featureSlider:Toggle({ Default = true })

featureSlider.Enabled:Connect(function(on)
	print("Feature enabled:", on)
end)

tabAdv:Button({
	Name = "Disable feature toggle",
	Callback = function()
		featureSlider:SetEnabled(false)
		print("IsEnabled:", featureSlider:IsEnabled())
	end,
})

local modeInput = tabAdv:TextInput({
	Name = "With Extra element",
	Placeholder = "text...",
})

modeInput:Extra("Segmented", {
	Options = { "One", "Two", "Three" },
	Callback = function(value)
		print("Extra segmented:", value)
	end,
})

tabAdv:Section("Search aliases")

tabAdv:Button({
	Name = "Secret alias",
	Search = "hidden alias easter egg",
	Tooltip = "Try searching 'easter' in the window search bar",
	Callback = function()
		Kailex:Notify({ Title = "Easter egg", Text = "You found the aliased button!", Type = "Success" })
	end,
})

local tabSys = win:Tab({ Title = "System" })

tabSys:Section("Notifications")

tabSys:Button({
	Name = "All notification types",
	Callback = function()
		Kailex:Notify("Plain string notification")
		task.delay(0.3, function()
			Kailex:Notify({ Title = "Info", Text = "Information type.", Type = "Info", Duration = 4 })
		end)
		task.delay(0.6, function()
			Kailex:Notify({ Title = "Success", Text = "Success type.", Type = "Success", Duration = 4 })
		end)
		task.delay(0.9, function()
			Kailex:Notify({ Title = "Warning", Text = "Warning type.", Type = "Warning", Duration = 4 })
		end)
		task.delay(1.2, function()
			Kailex:Notify({ Title = "Error", Text = "Error type.", Type = "Error", Duration = 4 })
		end)
	end,
})

tabSys:Button({
	Name = "Notification with actions",
	Callback = function()
		Kailex:Notify({
			Title = "Update available",
			Text = "Version 2.0 is out. Restart now?",
			Type = "Info",
			Duration = 10,
			Actions = {
				{ Text = "Restart", Callback = function() print("restart pressed") end },
				{ Text = "Later", Callback = function() print("later pressed") end },
			},
		})
	end,
})

tabSys:Section("Confirm dialogs")

tabSys:Button({
	Name = "Simple confirm",
	Callback = function()
		Kailex:Confirm("Are you sure you want to do this?", function(accepted)
			print("Simple confirm:", accepted)
		end)
	end,
})

tabSys:Button({
	Name = "Customized confirm",
	Callback = function()
		Kailex:Confirm({
			Title = "Delete file?",
			Text = "config.json will be permanently removed.",
			AcceptText = "Delete",
			DeclineText = "Keep",
			OnAccept = function(accepted)
				Kailex:Notify({ Title = "Deleted", Text = "config.json removed.", Type = "Success" })
			end,
			OnDecline = function(accepted)
				Kailex:Notify({ Title = "Cancelled", Text = "Nothing was deleted." })
			end,
		})
	end,
})

tabSys:Section("Window control")

tabSys:Button({
	Name = "Rename window",
	Callback = function()
		win:SetTitle("Kailex Demo [" .. os.date("%X") .. "]")
	end,
})

tabSys:Button({
	Name = "Toggle minimized",
	Callback = function()
		win:SetMinimized(not win.Minimized)
	end,
})

tabSys:Button({
	Name = "Toggle maximized",
	Description = "You can also double-click the title bar",
	Callback = function()
		win:SetMaximized(not win.Maximized)
	end,
})

tabSys:Button({
	Name = "Toggle hidden (or press F)",
	Callback = function()
		win:ToggleHidden()
	end,
})

tabSys:Slider({
	Name = "Sidebar width",
	Min = 110,
	Max = 320,
	Default = 152,
	Callback = function(value)
		win:SetSidebarWidth(value)
	end,
})

tabSys:TextInput({
	Name = "Apply filter",
	Placeholder = "filter all elements...",
	Callback = function(text)
		win:ApplyFilter(text)
	end,
})

tabSys:Button({
	Name = "Clear filter",
	Callback = function()
		win:ApplyFilter("")
	end,
})

tabSys:Button({
	Name = "Save placement",
	Callback = function()
		win:SavePlacement()
		Kailex:Notify({ Title = "Saved", Text = "Window position stored.", Type = "Success", Duration = 2 })
	end,
})

tabSys:Button({
	Name = "Refresh layout",
	Callback = function()
		win:UpdateLayout()
	end,
})

tabSys:Section("Library control")

tabSys:Button({
	Name = "Toggle UI visibility",
	Description = "Or press RightShift",
	Callback = function()
		Kailex:SetVisible(not Kailex:IsVisible())
	end,
})

tabSys:Button({
	Name = "Show mobile button",
	Callback = function()
		Kailex:MobileButton()
	end,
})

tabSys:Button({
	Name = "List open windows",
	Callback = function()
		local names = {}
		for i, w in ipairs(Kailex.Windows) do
			names[#names + 1] = i .. ":" .. w.Title
		end
		Kailex:Notify({
			Title = "Windows (" .. #Kailex.Windows .. ")",
			Text = #names > 0 and table.concat(names, ", ") or "none",
			Duration = 6,
		})
	end,
})

tabSys:Button({
	Name = "Count 'button' matches in Basic tab",
	Callback = function()
		print("Matches:", tabBasic:CountMatches("button"))
		tabBasic:SetFilterBadge("!")
	end,
})

tabSys:Button({
	Name = "Go to Basic tab",
	Callback = function()
		tabBasic:Select()
	end,
})

tabSys:Button({
	Name = "Close window (with confirm)",
	Callback = function()
		win:Close()
	end,
})

tabSys:Button({
	Name = "Close window (force)",
	Callback = function()
		win:Close(true)
	end,
})

tabSys:Button({
	Name = "Destroy second window",
	Callback = function()
		win2:Destroy()
	end,
})

tabSys:Button({
	Name = "Unload library",
	Callback = function()
		Kailex:Confirm("Unload Kailex and destroy the UI?", function()
			Kailex:Unload()
		end)
	end,
})

tabSys:Section("Shortcuts")

tabSys:Paragraph({
	Title = "Hotkeys & gestures",
	Text = "RightShift: toggle UI | F: toggle this window | Double-click title bar: maximize | "
		.. "Arrow keys on sliders/steppers (Shift = fine) | Right-click any element: context menu "
		.. "(copy value / reset / disable) | Magnifier in title bar: live search",
})

local win2 = Kailex:Window({
	Title = "Second window",
	SubTitle = "multi-window support",
	SaveKey = "DemoSecond",
	RememberPosition = false,
})

local w2tab = win2:Tab({ Title = "Mini" })

w2tab:Label({ Text = "A second independent window." })

w2tab:Button({
	Name = "Follow first window",
	Callback = function()
		if win.Root and win2.Root then
			win2.Root.Position = win.Root.Position + UDim2.fromOffset(30, 30)
		end
	end,
})

w2tab:Toggle({
	Name = "Independent toggle",
	Default = false,
	Callback = function(state)
		print("Second window toggle:", state)
	end,
})

Kailex:Notify({
	Title = "Welcome",
	Text = "Demo loaded. RightShift toggles the UI, F toggles the window.",
	Type = "Success",
	Duration = 5,
})
