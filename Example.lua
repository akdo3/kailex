--[[ ═══════════════════════════════════════════════════════════════════════════
     KALEIX UI LIBRARY — COMPLETE FEATURE REFERENCE & PROFESSIONAL GUIDE
     ═══════════════════════════════════════════════════════════════════════════
     This script demonstrates EVERY public feature of the Kailex UI library.
     Read it top-to-bottom as a tutorial, or jump to a section:

     [01] Loading the library            [14] ColorPicker
     [02] Global settings (Setting)      [15] TextInput (validator)
     [03] Sound customization (Audio)    [16] Stepper (hold-to-repeat)
     [23] Key system (optional gate)     [17] Segmented
     [04] Window creation (all opts)     [18] Vector3Input
     [05] Window API + signals           [19] Universal element API + Extra()
     [06] Tabs (icons/badges/select)     [20] Notifications (actions/queue)
     [07] Sections + column grids        [21] Confirm dialogs
     [08] Label / Paragraph / Divider    [22] Themes (custom + live signal)
     [09] Button (Confirm/Icon/Busy)     [24] Multiple windows
     [10] Toggle (Pin/Changed/attach)    [25] Mobile support
     [11] Slider (all behaviors)         [26] Unloading & visibility
     [12] Dropdown (Multi/Search/live)   [27] Cheat sheet (full API summary)
     [13] Keybind (mouse/conflicts)
     ═══════════════════════════════════════════════════════════════════════════ ]]

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--═════════════════════════════════════════════════════════════════════════════
-- [01] LOADING THE LIBRARY
--═════════════════════════════════════════════════════════════════════════════
-- The module returns the `Kailex` table. Re-executing the loader while a
-- previous copy runs auto-unloads it first (getgenv().kailex guard), so
-- hot-reloading your script never stacks duplicated UIs.

local Kailex = require(game:GetService("ReplicatedStorage"):FindFirstChild("Window"))

--═════════════════════════════════════════════════════════════════════════════
-- [02] GLOBAL SETTINGS — Kailex.Setting
--═════════════════════════════════════════════════════════════════════════════
-- Runtime configuration for the WHOLE library (applies to every window).
-- The built-in Settings tab (Window option `Settings = true`) edits these
-- interactively and persists them to disk; seeding them here overrides the
-- restored saved state for the current session.

Kailex.Setting.Theme       = "Dark-Blue"               -- "Dark-Blue" | "Light"
Kailex.Setting.Sounds      = true                      -- UI sound effects
Kailex.Setting.Effects     = true                      -- click ripple effects
Kailex.Setting.AutoSave    = true                      -- debounced disk saving
Kailex.Setting.UIScale     = 1                         -- global zoom (0.8–1.3)
Kailex.Setting.TextScale   = 1.1                       -- font zoom (0.85–1.4)
Kailex.Setting.MotionScale = 1                         -- anim speed (0.2–1; lower = faster)
Kailex.Setting.ToggleUIKey = Enum.KeyCode.RightShift   -- MASTER show/hide hotkey
-- Kailex.Setting.SaveFolder = "KailexUI"              -- save folder (read at load)

--═════════════════════════════════════════════════════════════════════════════
-- [03] SOUND CUSTOMIZATION — Kailex.Audio
--═════════════════════════════════════════════════════════════════════════════
-- Every UI event maps to a sound entry {Id, Speed, Vol}. Sounds only play
-- when Setting.Sounds is true. Master multiplies every volume. Sounds are
-- pooled & reused automatically (no leaks, no cutoffs when spamming clicks).

Kailex.Audio.Click = {
	Id    = "rbxasset://sounds/electronicpingshort.wav", -- any rbxasset/rbxassetid sound
	Speed = 1.5,   -- playback speed (also shifts pitch)
	Vol   = 0.3,   -- base volume 0–1
}
-- Available entries: Hover, Click, ToggleOn, ToggleOff, Tick, Dropdown, Error
Kailex.Audio.Master = 1    -- global volume multiplier (0–1)

--═════════════════════════════════════════════════════════════════════════════
-- [23] KEY SYSTEM (OPTIONAL) — call BEFORE creating windows
--═════════════════════════════════════════════════════════════════════════════
-- While locked, every window stays hidden until a valid key is entered.
-- Sessions are sealed (hash + expiry) and survive re-execution.
-- Flip the flag to try it with the demo keys below.

local ENABLE_KEY_SYSTEM = false

if ENABLE_KEY_SYSTEM then
	Kailex:KeySystem({
		Secret   = "MyScript-Secret-2024",  -- salt used to seal sessions
		Key      = {                        -- a string OR a table of keys:
			["VIP-FOREVER"] = 0,            --   [key] = duration in seconds;
			["VIP-24H"]     = 86400,        --   0 (or omitted) = never expires
			"FREE-1H",                      --   plain entries use `Expiry`
		},
		Expiry    = 3600,                   -- default duration (default 86400)
		Title     = "Authentication",
		SubTitle  = "Enter your key to unlock the script.",
		Link      = "https://your-key-site.com", -- "Get Key" btn (copies link)
		Whitelist = { "FriendUsername" },   -- skip the key entirely
		Blacklist = { "Scammer" },          -- hard block with an error message
		Silent    = false,                  -- true = no welcome notifications
		BindHardware = true,                -- seal sessions to HWID if available
	})
	-- Returns nil when already authorized (or no keys defined) — just proceed
	-- and build your UI normally; it will appear once unlocked.
end

--═════════════════════════════════════════════════════════════════════════════
-- [04] CREATING A WINDOW — every option explained
--═════════════════════════════════════════════════════════════════════════════

local Window = Kailex:Window({
	-- Identity --------------------------------------------------------------
	Title    = "Kailex Demo",                 -- main title (alias: Name)
	SubTitle = "every feature, documented",   -- small grey line under title

	-- Persistence ------------------------------------------------------------
	SaveKey  = "KailexDemo",   -- prefix for all element save keys in this window.
	-- Elements auto-save as "SaveKey/TabTitle/ElementName".
	-- Windows sharing a SaveKey share saved values.
	RememberPosition = true,  -- restore size/position across sessions (default true)

	-- Behavior -----------------------------------------------------------------
	ToggleKey = Enum.KeyCode.RightControl, -- this window's PRIVATE show/hide key
	-- (the global ToggleUIKey hides EVERYTHING)
	QuickMode = true,  -- desktop: auto-attaches a mini keybind to every Toggle
	-- mobile : auto-enables Pin on every Toggle
	Settings  = true,  -- appends a built-in "Settings" tab containing:
	--   • theme dropdown + UI/Text/Motion scale sliders
	--   • 4 live base-color pickers (Background/Surface/Text/Accent)
	--   • sound & ripple toggles + show/hide keybind
	--   • profile manager (Save/Load/Export/Import/Delete)
	--   • device info + full settings reset (with Undo!)

	-- Appearance ----------------------------------------------------------------
	Theme = "Dark-Blue", -- built-in name (see Kailex:GetThemes()) OR a custom
	-- table {Background, Surface, Text, Accent} — see [22].
	-- NOTE: themes are GLOBAL; they restyle every window.
})

--═════════════════════════════════════════════════════════════════════════════
-- [05] WINDOW API — signals & runtime methods
--═════════════════════════════════════════════════════════════════════════════

-- Fired when the window is closed/destroyed — clean up your loops here.
Window.Closed:Connect(function()
	print("[Demo] Main window closed")
end)

-- Fired whenever minimize state changes (full window <-> pill).
Window.MinimizedChanged:Connect(function(minimized)
	print("[Demo] Minimized:", minimized)
end)

-- Runtime methods (wired to buttons in the API tab below):
--   Window:SetTitle("text")       Window:SetMinimized(bool)   Window:SetMaximized(bool)
--   Window:SetSidebarWidth(px)    Window:UpdateLayout()        Window:ApplyFilter("q")
--   Window:ToggleHidden()         Window:SavePlacement()       Window:Close(skipConfirm?)
--   Window:Destroy()
-- Useful properties: Window.Tabs, Window.CurrentTab, Window.Title,
--                     Window.Minimized, Window.Maximized, Window.SavePrefix
--
-- FREE built-in interactions (zero code needed):
--   • drag by the title bar          • resize via the bottom-right grip
--   • double-click title = maximize  • drag the sidebar splitter (110–320px)
--   • search button filters elements & badges other tabs with match counts
--   • windows auto-raise on click    • Esc closes the search bar

--═════════════════════════════════════════════════════════════════════════════
-- [06] TABS
--═════════════════════════════════════════════════════════════════════════════
-- Icon accepts: numeric asset id, "rbxassetid://...", "rbxasset://...",
-- or a built-in vector icon: "Minimize" "Close" "Chevron" "Search"
--                           "Grip" "Gear" "Check" "Reset" "Pin"

local HomeTab   = Window:Tab({ Title = "Home",    Icon = "Gear"   })
local PlayerTab = Window:Tab({ Title = "Player",  Icon = "Check"  })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "Pin"    })
local UtilTab   = Window:Tab({ Title = "Utility", Icon = "Search" })
local ApiTab    = Window:Tab({ Title = "API",     Icon = 6031280882 }) -- asset id

-- Programmatic tab control (demos in the API tab):
--   HomeTab:Select()           -- switch tabs from code (2nd arg = instant)
--   HomeTab:SetFilterBadge("3")-- the little number bubble on the tab button
--   HomeTab:ApplyFilter("x")   -- filter this tab, returns match count
--   HomeTab:CountMatches("x")  -- count matches without filtering

--═════════════════════════════════════════════════════════════════════════════
-- [07]+[08] HOME TAB — sections, static elements, notifications, confirms
--═════════════════════════════════════════════════════════════════════════════

-- Paragraph: a titled, auto-sizing wrapped text card.
HomeTab:Paragraph({
	Title = "Welcome",
	Text  = "This script is the complete Kailex reference. Right-click ANY "
		.. "element row for a context menu (copy value / reset / disable). "
		.. "Hover elements for tooltips; on mobile, long-press instead.",
})

-- Divider: thin separator line. Pass Text for a labeled divider.
HomeTab:Divider()
HomeTab:Divider({ Text = "Notifications" })

-- Label: a plain auto-wrapping text line, updatable at runtime with :Set().
local statusLabel = HomeTab:Label({ Text = "Status: idle" })

--─────────────────────────────────────────────────────────────────────────────
-- [20] NOTIFICATIONS
--─────────────────────────────────────────────────────────────────────────────
-- Types: "info" (default) | "success" | "warning" | "error" — any casing.
-- Behavior you get for free: hover PAUSES the countdown, click dismisses,
-- excess notifications queue automatically (5 visible on PC, 3 on mobile).

HomeTab:Button({
	Name = "Notify: all types",
	Description = "info / success / warning / error",
	SaveKey = false,                       -- demo-only, skip persistence
	Callback = function()
		Kailex:Notify("Plain strings become the body text.")
		Kailex:Notify({ Title = "Saved",   Text = "Config written to disk.",  Type = "success" })
		Kailex:Notify({ Title = "Careful", Text = "This action is permanent.", Type = "warning", Duration = 6 })
		Kailex:Notify({ Title = "Failed",  Text = "Could not reach server.",  Type = "error",   Duration = 6 })
	end,
})

HomeTab:Button({
	Name = "Notify: action buttons",
	Description = "Up to 3 buttons per notification",
	SaveKey = false,
	Callback = function()
		Kailex:Notify({
			Title    = "Delete config?",
			Text     = "default.json will be removed.",
			Type     = "warning",
			Duration = 8,
			Actions  = {                                   -- max 3 actions
				{ Text = "Delete", Callback = function()
					Kailex:Notify({ Title = "Deleted", Text = "default.json removed.", Type = "success" })
				end },
				{ Text = "Keep", Callback = function()
					statusLabel:Set("Status: file kept")
				end },
			},
		})
	end,
})

HomeTab:Button({
	Name = "Notify: queue stress test",
	Description = "Shows stacking + the overflow queue",
	SaveKey = false,
	Callback = function()
		for i = 1, 8 do
			Kailex:Notify({ Title = "Queued #" .. i, Text = "Only 5 fit on screen; the rest wait.", Duration = 1.5 })
		end
	end,
})

--─────────────────────────────────────────────────────────────────────────────
-- [21] CONFIRM DIALOGS
--─────────────────────────────────────────────────────────────────────────────
-- Modal with two buttons. Keyboard: Enter = accept, Esc = decline.
-- Clicking the dimmed background declines. Only one can be open at a time.

HomeTab:Button({
	Name = "Confirm: full options",
	SaveKey = false,
	Callback = function()
		Kailex:Confirm({
			Title       = "Teleport to spawn?",
			Text        = "You will be moved instantly.",   -- alias: Description
			AcceptText  = "Go",     -- alias: ConfirmText (default "Confirm")
			DeclineText = "Stay",   -- alias: CancelText   (default "Cancel")
			OnAccept    = function()
				local char = LocalPlayer.Character
				if char and char.PrimaryPart then
					char:PivotTo(CFrame.new(0, 50, 0))
				end
			end,
			OnDecline   = function()
				statusLabel:Set("Status: teleport cancelled")
			end,
		})
	end,
})

-- Short form — message + accept handler:
HomeTab:Button({
	Name = "Confirm: short form",
	SaveKey = false,
	Callback = function()
		Kailex:Confirm("Say hello?", function()
			Kailex:Notify({ Title = "Hi!", Text = "Hello from Kailex.", Type = "success" })
		end)
	end,
})

--─────────────────────────────────────────────────────────────────────────────
-- [09] BUTTONS — Confirm option, Icon, SetBusy, SetCallback, SetTitle
--─────────────────────────────────────────────────────────────────────────────

HomeTab:Divider({ Text = "Buttons" })

-- opts.Confirm wraps the callback in a confirm dialog automatically:
HomeTab:Button({
	Name = "Button-level Confirm",
	Description = "opts.Confirm shows a dialog before running the callback",
	Confirm = "This will respawn your character. Continue?",
	Callback = function()
		LocalPlayer:LoadCharacter()
	end,
})

-- opts.Icon: numeric asset id or "rbxassetid://..." — clickable, sits right.
HomeTab:Button({
	Name = "Button with Icon",
	Icon = 6034684930,
	Callback = function()
		Kailex:Notify({ Title = "Icon", Text = "Icon button pressed.", Type = "info" })
	end,
})

-- SetBusy(true): shows a spinner, greys the label and BLOCKS re-clicks.
-- Perfect for async work (HTTP, waits) to prevent double-fires.
local busyBtn = HomeTab:Button({
	Name = "Async work (SetBusy)",
	Description = "Spinner + click-blocking while busy",
	Callback = function()
		busyBtn:SetBusy(true)
		task.delay(2, function()
			busyBtn:SetBusy(false)
			Kailex:Notify({ Title = "Async", Text = "Work complete.", Type = "success" })
		end)
	end,
})

-- SetCallback swaps the callback at runtime; SetTitle renames any element.
local clicks = 0
local counterBtn = HomeTab:Button({
	Name = "Callback counter",
	Callback = function() end,
})
counterBtn:SetCallback(function()
	clicks += 1
	counterBtn:SetTitle("Clicked " .. clicks .. "x")
end)

-- `Search` adds hidden keywords — try searching "banana" in the title bar:
HomeTab:Button({
	Name = "Fruit Salad",
	Description = "Also found via hidden keywords (search 'banana')",
	Search = "banana apple orange keywords",
	SaveKey = false,
	Callback = function()
		Kailex:Notify({ Title = "Fruit Salad", Text = "Found via hidden keywords!", Type = "success" })
	end,
})

--═════════════════════════════════════════════════════════════════════════════
-- [07] PLAYER TAB — sections, column grids, toggles, sliders
--═════════════════════════════════════════════════════════════════════════════

-- Section options: Name | Collapsed (aliases Open/Expanded, inverted)
--                  | Columns (1–6 grid). Shorthand: tab:Section("Name").
-- IMPORTANT: elements are always created on the TAB; everything created
-- AFTER a Section call lands inside that section (until the next Section).
local combat = PlayerTab:Section({ Name = "Combat", Columns = 2 })
-- combat:SetCollapsed(true)     -- collapse/expand programmatically
-- combat.Collapsed              -- read current state

--─────────────────────────────────────────────────────────────────────────────
-- [10] TOGGLE
--─────────────────────────────────────────────────────────────────────────────
-- Options: Default (bool, alias defaultVal) | Pin (adds a pin button that
-- detaches the toggle into a draggable floating on/off bubble — great for
-- features you need while the window is hidden; QuickMode auto-pins on mobile).

PlayerTab:Toggle({
	Name        = "Aimbot",
	Description = "Snap your aim onto the nearest target",
	Default     = false,
	Span        = 2,          -- full width across BOTH grid columns
	Callback    = function(on)
		print("Aimbot:", on)
	end,
})

-- In a Columns=2 section, elements default to Span=1 (half width each):
PlayerTab:Dropdown({
	Name    = "Target Part",
	Options = { "Head", "Torso", "Left Arm", "Right Arm" },
	Default = "Head",
	Callback = function(part)
		print("Targeting:", part)
	end,
})
PlayerTab:Toggle({
	Name    = "Team Check",
	Default = true,
	Callback = function(v) end,
})

PlayerTab:Section({ Name = "Movement" })

--─────────────────────────────────────────────────────────────────────────────
-- [11] SLIDER
--─────────────────────────────────────────────────────────────────────────────
-- Free behaviors: type a number into the value box (prefix/suffix stripped),
-- hover + Arrow keys to nudge (hold Shift for 1/5 fine steps), right-click
-- (or the ↺ button) to reset to Default, live value bubble while dragging.

local speedSlider = PlayerTab:Slider({
	Name        = "Walk Speed",
	Description = "Humanoid.WalkSpeed",
	Min         = 16,
	Max         = 500,
	Increment   = 1,      -- decimals supported: 0.05 → 2 decimal places
	Default     = 16,
	Suffix      = " sp",  -- text after the number  (Prefix = text before)
	Callback    = function(value)
		local char = LocalPlayer.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = value end
	end,
})

-- Professional pattern: re-apply the saved value after respawn via Get():
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then hum.WalkSpeed = speedSlider:Get() end
end)

PlayerTab:Slider({
	Name           = "Field of View",
	Min            = 30, Max = 120, Default = 70,
	FireOnRelease  = true,   -- callback fires ONCE on release instead of
	-- continuously — use for HTTP calls, remotes,
	-- expensive updates, etc.
	Callback       = function(v)
		print("FOV released at", v)
	end,
})

local noclipToggle = PlayerTab:Toggle({
	Name        = "Noclip",
	Description = "Walk through walls — Pin keeps a floating bubble on screen",
	Default     = false,
	Pin         = true,
	-- Callback: fires on user clicks and NON-silent :Set() calls.
	Callback    = function(on)
		print("[callback] noclip toggled:", on)
	end,
})

-- .Changed is a SIGNAL that fires on EVERY change, regardless of source:
-- user clicks, silent Set(), quick-widget bubbles, saved-value reloads.
-- Put your real logic here so the UI can never desync from your state.
noclipToggle.Changed:Connect(function(on)
	statusLabel:Set("Noclip: " .. (on and "ON" or "OFF"))
end)

-- Real feature logic driven purely by element state:
RunService.Stepped:Connect(function()
	if noclipToggle:Get() then
		local char = LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end
end)

--═════════════════════════════════════════════════════════════════════════════
-- [14]+[17]+[16] VISUALS TAB — color pickers, segmented, stepper, attached toggle
--═════════════════════════════════════════════════════════════════════════════

VisualTab:Section({ Name = "Appearance", Columns = 2 })

-- ColorPicker: click the swatch to open the popup — drag the square
-- (saturation/value), drag the rainbow bar (hue), type hex, or press Copy.
-- The ↺ button restores Default. The callback fires LIVE while dragging.
local espColor = VisualTab:ColorPicker({
	Name    = "ESP Color",
	Default = Color3.fromRGB(122, 162, 247),  -- alias: Color =
	Callback = function(color)
		-- runs on every drag movement — perfect for ESP/chams/auras
	end,
})
-- Runtime API:
--   espColor:Get()                   -> Color3
--   espColor:Set(Color3.new(1,0,0))  -> set programmatically (silent 2nd arg)
--   espColor:SetDefault(c)           -> change what reset restores
--   espColor:CopyValue()             -> "#RRGGBB" (used by the context menu)

VisualTab:ColorPicker({
	Name    = "Outline",
	Default = Color3.fromRGB(13, 15, 20),
	Callback = function(c) end,
})

-- Segmented: compact one-choice switcher. Options = strings or {Text, Value}.
VisualTab:Segmented({
	Name       = "Highlight Mode",
	Options    = {
		{ Text = "Box",  Value = "box"  },
		{ Text = "Glow", Value = "glow" },
		{ Text = "Both", Value = "both" },
	},
	Default    = "glow",
	ItemWidth  = 58,          -- pixel width of each segment
	Callback   = function(mode)
		print("Highlight mode:", mode)
	end,
})

-- Stepper: − / + buttons with hold-to-repeat. Ideal for small ranges.
VisualTab:Stepper({
	Name    = "Outline Thickness",
	Min     = 1, Max = 10, Step = 1, Default = 2,
	-- Prefix = "w",  Suffix = "px",              -- simple formatting
	-- Format = function(v) return v .. "px" end, -- OR fully custom label
	Callback = function(v)
		print("Thickness:", v)
	end,
})

VisualTab:Section({ Name = "Fine Tuning" })

-- Decimal slider (Increment < 1 automatically formats decimals):
VisualTab:Slider({
	Name      = "Aim Smoothness",
	Min       = 0, Max = 1, Increment = 0.05, Default = 0.35,
	Callback  = function(v) end,
})

--─────────────────────────────────────────────────────────────────────────────
-- [10b] ATTACHED TOGGLES — Element:Toggle()
--─────────────────────────────────────────────────────────────────────────────
-- Any element can host a master on/off switch (a mini toggle appears inside
-- its right side). The PARENT element then gains:
--   parent.Enabled          -> Signal (fires on every change)
--   parent.IsEnabled()      -> bool
--   parent:SetEnabled(bool) -> programmatic switch
--   parent.AttachedToggle   -> the toggle element itself

local opacitySlider = VisualTab:Slider({
	Name     = "ESP Opacity",
	Min      = 0, Max = 1, Increment = 0.05, Default = 1,
	Callback = function(v)
		print("Opacity:", v)
	end,
})

opacitySlider:Toggle({
	Default  = false,
	Callback = function(on)
		print("ESP master switch:", on)
	end,
})

opacitySlider.Enabled:Connect(function(on)
	-- fires even when changed via SetEnabled() or saved reloads
	print("[signal] ESP enabled:", on)
end)

--─────────────────────────────────────────────────────────────────────────────
-- [19b] MINI ELEMENTS — Element:Extra()
--─────────────────────────────────────────────────────────────────────────────
-- Attach ANY element type as a compact widget inside another element's row:
--   parent:Extra("ClassName", opts, { Width = px, Height = px })
-- (This is exactly what QuickMode uses to put keybinds inside toggles.)

local quickRow = VisualTab:Button({
	Name = "Quick Action",
	Callback = function()
		Kailex:Notify({ Title = "Quick", Text = "Main button pressed.", Type = "info" })
	end,
})
quickRow:Extra("ColorPicker", {
	Name = "Tint", Default = Color3.new(1, 0, 0),
	Callback = function(c) print("Tint:", c) end,
}, { Width = 38, Height = 22 })
quickRow:Extra("Keybind", {
	Name = "Tint Key", Default = Enum.KeyCode.T, SaveKey = false,
	Callback = function() print("Tint hotkey pressed") end,
}, { Width = 54, Height = 26 })

--═════════════════════════════════════════════════════════════════════════════
-- [13]+[15]+[18]+[12] UTILITY TAB — keybinds, inputs, dropdowns
--═════════════════════════════════════════════════════════════════════════════

UtilTab:Section("Keybinds")

-- Keybind: Default accepts Enum.KeyCode.F | "F" | "Key:F" | "Mouse:MouseButton2".
-- Click the pill → press any key (Esc cancels; auto-times-out after 6s).
-- RIGHT-CLICK the pill to clear the binding.
-- Binding a key that's already used elsewhere triggers an automatic
-- conflict warning notification.

UtilTab:Keybind({
	Name    = "Toggle Noclip",
	Default = Enum.KeyCode.N,
	Callback = function()
		-- Receives the bound key. Use silent Set() to avoid double-firing
		-- the toggle's Callback — .Changed still fires, so logic stays synced:
		noclipToggle:Set(not noclipToggle:Get(), true)
	end,
})

UtilTab:Keybind({
	Name         = "Bind Mouse Buttons",
	Description  = "MouseButtons = true allows Mouse2 / Mouse3 bindings",
	MouseButtons = true,
	Default      = "Mouse:MouseButton2",
	Callback     = function(code)
		print("Pressed:", code.Name)
	end,
})

UtilTab:Section("Input Fields")

-- TextInput: callback fires on Enter, or on focus-loss with a changed value.
-- Validator must return true to accept — invalid input shakes the row,
-- plays an error sound and reverts to the previous value.
local webhookInput = UtilTab:TextInput({
	Name        = "Webhook URL",
	Placeholder = "https://discord.com/api/webhooks/...",
	Default     = "",
	Validator   = function(text)
		return text == "" or text:sub(1, 8) == "https://"
	end,
	Callback    = function(text)
		print("Webhook set:", text)
	end,
})
-- webhookInput:Get()  -> current accepted text
-- webhookInput:Set(t) -> programmatic set

-- Vector3Input: three XYZ boxes; invalid entries revert automatically.
local tpPos = UtilTab:Vector3Input({
	Name    = "Teleport Position",
	Default = Vector3.new(0, 50, 0),
	Callback = function(vec)
		print("Target position:", vec)
	end,
})
UtilTab:Button({
	Name = "Teleport",
	Callback = function()
		local char = LocalPlayer.Character
		if char and char.PrimaryPart then
			char:PivotTo(CFrame.new(tpPos:Get()))
		end
	end,
})

UtilTab:Section("Dropdowns")

-- Dropdown: Options = array of strings OR {Text = label, Value = anything}.
-- Free behaviors: search box appears automatically past 12 options,
-- rendering is virtualized past 60 (huge lists stay smooth), the popup
-- flips above the row when there's no room below, and only one dropdown
-- per tab can be open at a time.

-- Single-select with LIVE data — refreshed via SetOptions (valid
-- selections are preserved across refreshes):
local targetDrop = UtilTab:Dropdown({
	Name       = "Target Player",
	Searchable = true,          -- force the search box always on
	Options    = {},
	Callback   = function(playerName)
		print("Selected target:", playerName)
	end,
})

local function refreshTargetList()
	local opts = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(opts, { Text = p.DisplayName .. " (@" .. p.Name .. ")", Value = p.Name })
		end
	end
	targetDrop:SetOptions(opts)
end
refreshTargetList()
Players.PlayerAdded:Connect(refreshTargetList)
Players.PlayerRemoving:Connect(function()
	task.defer(refreshTargetList)
end)

-- Multi-select: Multi = true, Defaults = { ... }. Callback receives an ARRAY.
-- Multi lists also get "All" / "None" shortcut buttons in the header.
UtilTab:Dropdown({
	Name     = "Multi Select",
	Multi    = true,
	Defaults = { "Apples", "Cherries" },
	Options  = { "Apples", "Bananas", "Cherries", "Dates", "Elderberry" },
	Callback = function(values)
		print("Selected:", table.concat(values, ", "))
	end,
})

-- Huge list — 80 options, virtualized + searchable, zero lag:
local bigOpts = {}
for i = 1, 80 do
	table.insert(bigOpts, "Option #" .. i)
end
UtilTab:Dropdown({
	Name     = "Huge List (virtualized)",
	Options  = bigOpts,
	Callback = function(v) end,
})

-- Dropdown runtime API:
--   drop:Get()            -> value, or array of values when Multi
--   drop:GetText()        -> display text(s)
--   drop:Set(v, silent?)  -> select by value (array allowed when Multi)
--   drop:SetOptions(list) -> replace options, keeping valid selections

--═════════════════════════════════════════════════════════════════════════════
-- [19] API TAB — universal element API + window API, all live
--═════════════════════════════════════════════════════════════════════════════

ApiTab:Section("Element API (works on EVERY element)")

local demoToggle = ApiTab:Toggle({
	Name        = "Demo Toggle",
	Description = "Target of the API buttons below",
	Default     = false,
	SaveKey     = "Demo/APIToggle",   -- custom save key; false = never save
	Callback    = function(v) end,
})

-- Width (0–1 fraction) packs elements side-by-side WITHOUT a section grid:
ApiTab:Button({
	Name = "SetTitle", Width = 0.5, SaveKey = false,
	Callback = function()
		demoToggle:SetTitle("Renamed @ " .. os.clock())  -- also updates search text
	end,
})
ApiTab:Button({
	Name = "SetTooltip", Width = 0.5, SaveKey = false,
	Callback = function()
		demoToggle:SetTooltip("Tooltip changed at runtime")
	end,
})
ApiTab:Button({
	Name = "Hide / Show", Width = 0.5, SaveKey = false,
	Callback = function()
		demoToggle:Visible()           -- no argument = TOGGLE visibility
	end,
})
ApiTab:Button({
	Name = "Disable / Enable", Width = 0.5, SaveKey = false,
	Callback = function()
		demoToggle:SetDisabled(not demoToggle:IsDisabled())
	end,
})
ApiTab:Button({
	Name = "Set silently", Width = 0.5, SaveKey = false,
	Callback = function()
		demoToggle:Set(not demoToggle:Get(), true)  -- silent=true skips Callback
	end,                                          -- (.Changed still fires)
})
ApiTab:Button({
	Name = "Destroy", Width = 0.5, SaveKey = false,
	Callback = function()
		Kailex:Confirm("Remove the demo toggle permanently?", function()
			demoToggle:Destroy()   -- removes the row, cleans connections,
		end)                       -- unregisters its save key
	end,
})

ApiTab:Section("Window & Tab API")

ApiTab:Button({
	Name = "Minimize to pill", Width = 0.5, SaveKey = false,
	Callback = function() Window:SetMinimized(true) end,
})
ApiTab:Button({
	Name = "Maximize toggle", Width = 0.5, SaveKey = false,
	Callback = function() Window:SetMaximized(not Window.Maximized) end,
})
ApiTab:Button({
	Name = "Rename window", Width = 0.5, SaveKey = false,
	Callback = function() Window:SetTitle("Renamed " .. os.time()) end,
})
ApiTab:Button({
	Name = "Wide sidebar", Width = 0.5, SaveKey = false,
	Callback = function() Window:SetSidebarWidth(220) end,
})
ApiTab:Button({
	Name = "Filter tabs: 'speed'", Width = 0.5, SaveKey = false,
	Callback = function() Window:ApplyFilter("speed") end,  -- badges other tabs
})
ApiTab:Button({
	Name = "Clear filter", Width = 0.5, SaveKey = false,
	Callback = function() Window:ApplyFilter("") end,
})
ApiTab:Button({
	Name = "Go to Home tab", Width = 0.5, SaveKey = false,
	Callback = function() HomeTab:Select() end,
})
ApiTab:Button({
	Name = "Badge the Home tab", Width = 0.5, SaveKey = false,
	Callback = function() HomeTab:SetFilterBadge("★") end,
})
ApiTab:Button({
	Name = "Collapse 'Combat' section", Width = 0.5, SaveKey = false,
	Callback = function() combat:SetCollapsed(not combat.Collapsed) end,
})
ApiTab:Button({
	Name = "Hide window (ToggleKey)", Width = 0.5, SaveKey = false,
	Callback = function() Window:ToggleHidden() end,  -- same as RightControl here
})

--─────────────────────────────────────────────────────────────────────────────
-- [22] THEMES
--─────────────────────────────────────────────────────────────────────────────
-- Built-ins: "Dark-Blue", "Light" — enumerate at runtime with GetThemes().
-- Runtime switching & 4-color live editing: handled by the Settings tab.
-- Custom table themes are passed at window creation (all colors — strokes,
-- hovers, status colors — are DERIVED automatically from just these four):

-- Kailex:Window({
--     Theme = {
--         Background = "#0D0F14",  -- hex strings OR Color3 values
--         Surface    = "#13161E",
--         Text       = "#E8ECF6",
--         Accent     = "#7AA2F7",
--     },
-- })

ApiTab:Paragraph({
	Title = "Theme notes",
	Text  = "Kailex:GetThemes() lists built-ins. The Settings tab lets users "
		.. "switch themes and edit all 4 base colors live. Subscribe to "
		.. "Kailex.ThemeChanged to react — e.g. repaint your own drawings "
		.. "with theme.Accent / theme.Background.",
})

-- Fires with the full derived theme table whenever the theme changes:
Kailex.ThemeChanged:Connect(function(theme)
	-- Available keys: Background, Surface, Text, Accent, SurfaceLight, Element,
	-- ElementHover, Stroke, StrokeBright, TabBar, SubText, AccentHover, OnAccent,
	-- Knob, KnobStroke, Ripple, Success, Warning, Error
	-- print("Accent is now:", theme.Accent)
end)

--═════════════════════════════════════════════════════════════════════════════
-- [24] MULTIPLE WINDOWS
--═════════════════════════════════════════════════════════════════════════════
-- Every window is fully independent: own tabs, drag, resize, maximize,
-- minimize-pill, z-order (click to raise), toggle key, save prefix, and
-- Close signal. They all share one protected ScreenGui.

local Mini = Kailex:Window({
	Title     = "Quick Stats",
	SubTitle  = "second window demo",
	SaveKey   = "KailexDemoMini",
	ToggleKey = Enum.KeyCode.J,   -- J hides/shows ONLY this window
})

local miniTab = Mini:Tab({ Title = "Stats" })
miniTab:Label({ Text = "Put FPS / Ping counters here." })

miniTab:Button({
	Name = "Minimize to pill",
	Callback = function() Mini:SetMinimized(true) end,
})

Mini.Closed:Connect(function()
	Kailex:Notify({ Title = "Mini window", Text = "Closed.", Duration = 3 })
end)

--═════════════════════════════════════════════════════════════════════════════
-- [25] MOBILE SUPPORT
--═════════════════════════════════════════════════════════════════════════════
-- On touch devices the library AUTOMATICALLY:
--   • enlarges rows/sliders for fingers        • caps notifications to 3
--   • creates a draggable floating "K" button that toggles the whole UI
--   • shows tooltips via 0.5s long-press instead of hover
--   • QuickMode auto-pins toggles as floating bubbles
-- Create the floating button manually (idempotent) if you need it sooner:
-- Kailex:MobileButton()

--═════════════════════════════════════════════════════════════════════════════
-- [26] UNLOADING & GLOBAL VISIBILITY
--═════════════════════════════════════════════════════════════════════════════

HomeTab:Divider({ Text = "Shutdown" })
HomeTab:Button({
	Name = "Unload everything",
	Description = "Kailex:Unload() destroys all windows, sounds & connections",
	Confirm = "This removes the entire UI. Continue?",
	Callback = function()
		task.delay(0.25, function()   -- let the confirm fade out first
			Kailex:Unload()
		end)
	end,
})

-- Kailex:SetVisible(false)  -- hide EVERYTHING (same as the ToggleUIKey)
-- Kailex:IsVisible()        -- -> bool
-- Unload also runs automatically if the ScreenGui is removed, or when the
-- loader is re-executed (safe hot-reload).

--[[ ═══════════════════════════════════════════════════════════════════════════
 [27] CHEAT SHEET — the entire API at a glance
 ═════════════════════════════════════════════════════════════════════════════

 WINDOW
   Kailex:Window{ Title, SubTitle, SaveKey, ToggleKey, Theme, QuickMode,
                  RememberPosition, Settings }
   win:Tab{Title,Icon}        win:SetTitle(t)         win:SetMinimized(b)
   win:SetMaximized(b)        win:SetSidebarWidth(px) win:ApplyFilter(q)
   win:ToggleHidden()         win:Close(skipConfirm?) win:Destroy()
   win:SavePlacement()         win:UpdateLayout()
   Signals: win.Closed, win.MinimizedChanged
   Props:   win.Tabs, win.CurrentTab, win.Title, win.Minimized, win.Maximized

 TAB
   tab:Section{Name?, Collapsed?, Columns?}   (or tab:Section("Name"))
   tab:Button / Toggle / Slider / Dropdown / Keybind / ColorPicker /
       TextInput / Label / Paragraph / Divider / Stepper / Segmented /
       Vector3Input  {opts}
   tab:Select()   tab:SetFilterBadge(text)   tab:ApplyFilter(q)
   tab:CountMatches(q)

 COMMON ELEMENT OPTIONS
   Name, Description, Tooltip, Search (hidden keywords), Callback, Default,
   SaveKey (string | false), Width (0–1 side-by-side), Span (grid columns)

 UNIVERSAL ELEMENT METHODS
   el:SetTitle(t)  el:SetTooltip(t)  el:Visible(bool?)  el:SetDisabled(b)
   el:IsDisabled() el:Destroy()      el:Extra(class,opts,{Width,Height})
   el:Toggle(opts) -> parent gains .Enabled / :IsEnabled() / :SetEnabled()

 PER-ELEMENT
   btn:  SetBusy(b)   SetCallback(fn)                  opts: Confirm, Icon
   tog:  Get()  Set(v,silent?)  .Changed(signal)       opts: Pin
   sld:  Get()  Set(v,silent?)  Reset()                opts: Min,Max,Increment,
          Prefix,Suffix,FireOnRelease                     Default
   drop: Get()  GetText()  Set(v,silent?)  SetOptions() opts: Options/Items,
                                                          Multi,Defaults,
                                                          Default,Searchable
   key:  Get()  GetName()  Set(v,silent?)               opts: Default,
                                                          MouseButtons
   col:  Get()  Set(c,silent?)  SetDefault(c)           opts: Default/Color
   txt:  Get()  Set(t,silent?)                           opts: Placeholder,
                                                          Validator
   stp:  Get()  Set(v,silent?)                           opts: Min,Max,Step,
                                                          Format,Prefix,Suffix
   seg:  Get()  Set(v,silent?)                           opts: Options,Default,
                                                          ItemWidth
   vec:  Get()  Set(v,silent?)                           opts: Default(Vector3)
   lbl:  Set(text)                                       opts: Text/Name
   para: Set(text)                                       opts: Title,Text
   div:  (static)                                        opts: Text (optional)

 GLOBALS
   Kailex:Notify{Title,Text,Type,Duration,Actions}
   Kailex:Confirm(data, onAccept?)
   Kailex:KeySystem{Secret,Key,Expiry,Title,SubTitle,Link,Whitelist,
                    Blacklist,Silent,BindHardware}
   Kailex:GetThemes()      Kailex:SetVisible(b)     Kailex:IsVisible()
   Kailex:MobileButton()   Kailex:Unload()
   Kailex.Setting   Kailex.Audio   Kailex.Windows
   Kailex.ThemeChanged (signal)

 FREEBIES (zero code required)
   Drag / resize / maximize (double-click title) / minimize-pill / sidebar
   splitter / search with per-tab match badges / tooltips / right-click
   context menus (copy value, reset, disable) / hover ripples & sounds /
   keybind conflict detection / auto-save with .bak backup / window position
   memory / staggered intro animations / queued hover-pausing notifications
 ═════════════════════════════════════════════════════════════════════════════ ]]
