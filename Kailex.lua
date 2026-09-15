local Kailex = { Windows = {} }

pcall(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
end)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local V2 = Vector2.new
local UO = UDim2.fromOffset
local US = UDim2.fromScale
local UN = UDim2.new
local UD = UDim.new
local EF = Enum.Font
local CN = Color3.new
local RGB = Color3.fromRGB
local EUT = Enum.UserInputType
local EKC = Enum.KeyCode
local TTA = Enum.TextTruncate.AtEnd
local AS = Enum.AutomaticSize
local SB = Enum.ApplyStrokeMode.Border
local ETA = Enum.TextXAlignment
local ETY = Enum.TextYAlignment
local EFd = Enum.FillDirection
local ESD = Enum.ScrollingDirection
local EVA = Enum.VerticalAlignment
local E = Enum.EasingStyle
local ED = Enum.EasingDirection
local clamp = math.clamp
local floor = math.floor

local Device = {}

do
	Device.IsTouch = UIS.TouchEnabled and not UIS.MouseEnabled
	Device.IsConsole = false
	pcall(function()
		Device.IsConsole = GuiService:IsTenFootInterface()
	end)
end

local ROW_H = Device.IsTouch and 40 or 32
local PILL = UD(1, 0)

local function RemoveValue(t, v)
	for i, x in ipairs(t) do
		if x == v then
			table.remove(t, i)
			return true
		end
	end
	return false
end

local function ClampEdge(v, size, view, m)
	return clamp(v, m, math.max(m, view - size - m))
end

local function DecimalsOf(step)
	return step >= 1 and 0 or clamp(math.ceil(-math.log10(step)), 1, 3)
end

local function Getgenv()
	local ok, g = pcall(function()
		return getgenv
	end)
	if ok and type(g) == "function" then
		local ok2, res = pcall(g)
		if ok2 and type(res) == "table" then
			return res
		end
	end
	return nil
end

local genv = Getgenv()

if genv and genv.kailex then
	pcall(function()
		genv.kailex:Unload()
	end)
	genv.kailex = nil
end

local HasFileSystem = type(isfile) == "function" and type(writefile) == "function"

local fs = {
	makefolder = makefolder or function() end,
	writefile = writefile or function() end,
	readfile = readfile or function() return "{}" end,
	isfile = isfile or function() return false end,
	delfile = delfile or removefile or function() end,
	listfiles = listfiles or function() return {} end,
}

local SafeParent = (function()
	local ok, ui = pcall(function()
		return (gethui and gethui())
	end)
	if ok and ui then
		return ui
	end

	local ok2, cg = pcall(function()
		return CoreGui
	end)
	if ok2 and cg then
		local test = Instance.new("Frame")
		local okSet = pcall(function()
			test.Parent = cg
		end)
		test:Destroy()
		if okSet then
			return cg
		end
	end

	if LocalPlayer then
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then
			return pg
		end
	end
	return game
end)()

local protect_gui = function() end

do
	local ok, pg = pcall(function()
		return protectgui
	end)
	if ok and type(pg) == "function" then
		protect_gui = pg
	else
		local ok2, syn = pcall(function()
			return syn
		end)
		if ok2 and type(syn) == "table" and type(syn.protect_gui) == "function" then
			protect_gui = syn.protect_gui
		end
	end
end

local function Once(signal, fn)
	local conn
	conn = signal:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

local function ReportError(title, err)
	warn("[Kailex] " .. tostring(err))
	Kailex:Notify({
		Title = title,
		Text = tostring(err),
		Type = "Error",
		Duration = 6,
	})
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _conns = {}, _lock = 0, _dirty = false, _dead = false }, Signal)
end

function Signal:Connect(fn)
	if type(fn) ~= "function" then
		error("Signal:Connect expects a function", 2)
	end
	if self._dead then
		local c = { Connected = false }
		function c:Disconnect() end
		c.Destroy = c.Disconnect
		return c
	end

	local conn = { Connected = true, _fn = fn, _sig = self }

	function conn:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local sig = self._sig
		if sig._lock > 0 then
			sig._dirty = true
		else
			RemoveValue(sig._conns, self)
		end
	end
	conn.Destroy = conn.Disconnect

	table.insert(self._conns, conn)
	return conn
end

function Signal:Once(fn)
	return Once(self, fn)
end

function Signal:Fire(...)
	local conns = self._conns
	local n = #conns
	if n == 0 then return end

	self._lock += 1
	for i = 1, n do
		local c = conns[i]
		if c.Connected then
			local ok, err = pcall(c._fn, ...)
			if not ok then
				ReportError("Callback error", err)
			end
		end
	end
	self._lock -= 1

	if self._lock == 0 and self._dirty then
		self._dirty = false
		local keep = table.create(n)
		for i = 1, #conns do
			local c = conns[i]
			if c.Connected then
				keep[#keep + 1] = c
			end
		end
		self._conns = keep
	end
end

function Signal:Destroy()
	for _, c in ipairs(self._conns) do
		c.Connected = false
	end
	self._conns = {}
	self._dead = true
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {}, _link = nil, _dead = false }, Maid)
end

function Maid:Give(item)
	if item == nil or self._dead then return item end
	table.insert(self._tasks, item)
	return item
end

function Maid:Link(inst)
	if typeof(inst) == "Instance" and not self._dead and not self._link then
		self._link = inst.Destroying:Connect(function()
			self:Destroy()
		end)
	end
	return self
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		local t = tasks[i]
		tasks[i] = nil
		pcall(function()
			local tt = typeof(t)
			if tt == "Instance" then
				t:Destroy()
			elseif tt == "RBXScriptConnection" then
				t:Disconnect()
			elseif tt == "function" then
				t()
			elseif tt == "thread" then
				task.cancel(t)
			elseif tt == "table" and type(t.Destroy) == "function" then
				t:Destroy()
			end
		end)
	end
end

function Maid:Destroy()
	if self._dead then return end
	self._dead = true
	if self._link then
		pcall(function()
			self._link:Disconnect()
		end)
		self._link = nil
	end
	self:Clean()
end

Kailex.Setting = {
	Theme = "Dark-Blue",
	Sounds = false,
	AutoSave = true,
	UIScale = 1,
	TextScale = 1.1,
	ToggleUIKey = EKC.RightShift,
	SaveFolder = "KailexUI",
	Effects = true,
	MotionScale = 1,
}

Kailex.ThemeChanged = Signal.new()

local Setting = Kailex.Setting
local LibMaid = Maid.new()

local function IsInputDown(inputType)
	if inputType == EUT.Touch then
		local ok, touches = pcall(UIS.GetTouches, UIS)
		return ok and #touches > 0 or false
	end
	if inputType == EUT.MouseButton1
		or inputType == EUT.MouseButton2
		or inputType == EUT.MouseButton3 then
		return UIS:IsMouseButtonPressed(inputType)
	end
	return true
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		ReportError("Script error", err)
	end
end

local function Sanitize(text)
	local s = tostring(text or "")
	s = s:gsub('[%c/\\:"<>|*?]', "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if s == "" then
		s = "Untitled"
	end
	return s
end

local function ColorToHex(c)
	return string.format(
		"#%02X%02X%02X",
		floor(c.R * 255 + 0.5),
		floor(c.G * 255 + 0.5),
		floor(c.B * 255 + 0.5)
	)
end

local function HexToColor(hex)
	if type(hex) ~= "string" then return nil end
	local h = hex:gsub("#", "")
	if #h == 3 then
		h = h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2)
	end
	if #h ~= 6 then return nil end
	local r = tonumber(h:sub(1, 2), 16)
	local g = tonumber(h:sub(3, 4), 16)
	local b = tonumber(h:sub(5, 6), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

local function RGBtoHSV(c)
	local r, g, b = c.R, c.G, c.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local v, d = max, max - min
	local s = (max == 0) and 0 or d / max
	local h
	if d == 0 then
		h = 0
	elseif max == r then
		h = ((g - b) / d) % 6
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	return h / 6, s, v
end

local InputHooks = {}

local function AddInputHook(alive, fn)
	local rec = { alive = alive, fn = fn }
	table.insert(InputHooks, rec)
	return rec
end

local function RemoveInputHook(rec)
	RemoveValue(InputHooks, rec)
end

LibMaid:Give(UIS.InputBegan:Connect(function(input, gp)
	local n = #InputHooks
	if n == 0 then return end
	for i = 1, n do
		local h = InputHooks[i]
		if h and h.alive() then
			local ok, err = pcall(h.fn, input, gp)
			if not ok then
				ReportError("Input error", err)
			end
		end
	end
	if #InputHooks > 96 then
		local keep = table.create(8)
		for i = 1, #InputHooks do
			local h = InputHooks[i]
			if h.alive() then
				keep[#keep + 1] = h
			end
		end
		InputHooks = keep
	end
end))

local KeybindRegistry = {}

local function ParseKey(v)
	if typeof(v) == "EnumItem" then
		if v.EnumType == EKC then return v end
		return nil
	end
	if type(v) == "string" then
		local kind, name = v:match("^(%a+):(.+)$")
		if kind and kind:lower() ~= "key" then return nil end
		return EKC[name or v]
	end
	return nil
end

local function ToBinding(v)
	if typeof(v) == "EnumItem" then
		local name = v.Name
		if v.EnumType == EKC then
			return { Kind = "Key", Code = v, Name = name }
		end
		if v.EnumType == Enum.UserInputType then
			return { Kind = "Mouse", Code = v, Name = name }
		end
	elseif type(v) == "string" then
		local kind, name = v:match("^(%a+):(.+)$")
		if kind then
			local k = kind:sub(1, 1):upper() .. kind:sub(2):lower()
			if k == "Key" then
				local kc = EKC[name]
				if kc then
					return { Kind = "Key", Code = kc, Name = name }
				end
			elseif k == "Mouse" then
				local it = Enum.UserInputType[name]
				if it then
					return { Kind = "Mouse", Code = it, Name = name }
				end
			end
			return nil
		end
		local kc = EKC[v]
		if kc then
			return { Kind = "Key", Code = kc, Name = v }
		end
	end
	return nil
end

local function NotifyKeybindConflict(self, b)
	for _, rec in ipairs(KeybindRegistry) do
		local el = rec.el
		if el ~= self and not el._destroyed then
			local ob = el._getBinding and el:_getBinding()
			if ob and ob.Kind == b.Kind and ob.Code == b.Code then
				Kailex:Notify({
					Title = "Keybind conflict",
					Text = "\"" .. b.Name .. "\" is also bound in \"" .. el.Title .. "\".",
					Type = "Warning",
					Duration = 5,
				})
				return
			end
		end
	end
end

local function TI(t, s, d)
	return TweenInfo.new(t, s, d)
end

local Tween

do
	local Tweens = {
		Instant = TI(0.05, E.Quad, ED.Out),
		Fast = TI(0.12, E.Quint, ED.Out),
		Snappy = TI(0.16, E.Quart, ED.Out),
		Normal = TI(0.24, E.Quint, ED.Out),
		Smooth = TI(0.35, E.Quart, ED.Out),
		Reveal = TI(0.30, E.Quint, ED.Out),
		HoverIn = TI(0.14, E.Quint, ED.Out),
		HoverOut = TI(0.20, E.Sine, ED.Out),
		Spring = TI(0.34, E.Back, ED.Out),
		SpringBig = TI(0.45, E.Back, ED.Out),
		Collapse = TI(0.28, E.Back, ED.In),
		Ripple = TI(0.45, E.Quint, ED.Out),
		Pop = TI(0.26, E.Back, ED.Out),
		PopSoft = TI(0.20, E.Back, ED.Out),
		Vanish = TI(0.15, E.Quad, ED.In),
	}
	setmetatable(Tweens, { __index = function()
		return Tweens.Normal
	end })

	local ActiveTweens = setmetatable({}, { __mode = "k" })

	function Tween(inst, preset, props, done, delay)
		if not inst or not inst.Parent then return nil end
		if type(props) ~= "table" then return nil end

		local info = typeof(preset) == "TweenInfo" and preset or Tweens[preset]
		local m = tonumber(Setting.MotionScale) or 1
		local dl = (tonumber(delay) or 0) * m
		if m ~= 1 or dl > 0 then
			local t = math.max(info.Time * m, 0.02)
			info = TweenInfo.new(t, info.EasingStyle, info.EasingDirection, info.RepeatCount, info.Reverses, dl)
		end

		local book = ActiveTweens[inst]
		if not book then
			book = {}
			ActiveTweens[inst] = book
		end
		for prop in pairs(props) do
			local prev = book[prop]
			if prev then
				pcall(prev.Cancel, prev)
				book[prop] = nil
			end
		end

		local ok, tween = pcall(TweenService.Create, TweenService, inst, info, props)
		if not ok then
			warn("[Kailex] tween failed: " .. tostring(inst))
			return nil
		end
		for prop in pairs(props) do
			book[prop] = tween
		end

		Once(tween.Completed, function(state)
			local b = ActiveTweens[inst]
			if b then
				for prop in pairs(props) do
					if b[prop] == tween then
						b[prop] = nil
					end
				end
			end
			if done and state == Enum.PlaybackState.Completed then
				SafeCall(done)
			end
		end)

		tween:Play()
		return tween
	end
end

local WHITE, BLACK = CN(1, 1, 1), CN(0, 0, 0)
local CurrentTheme = nil

local function Mix(a, b, t)
	return CN(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function Luma(c)
	return c.R * 0.299 + c.G * 0.587 + c.B * 0.114
end

local function ToColor(v, fallback)
	if typeof(v) == "Color3" then
		return v
	end
	if type(v) == "string" then
		return HexToColor(v) or fallback
	end
	return fallback
end

local function DeriveTheme(base)
	local cur = CurrentTheme
	base = type(base) == "table" and base or {}
	local cb = cur and cur.Base
	local bg = ToColor(base.Background, cb and cb.Background or RGB(13, 15, 20))
	local surface = ToColor(base.Surface, cb and cb.Surface or Mix(bg, WHITE, 0.03))
	local text = ToColor(base.Text, cb and cb.Text or RGB(232, 236, 246))
	local accent = ToColor(base.Accent, cb and cb.Accent or RGB(122, 162, 247))
	local light = Luma(bg) > 0.5
	local dir = light and BLACK or WHITE
	local element = Mix(surface, dir, 0.05)

	return {
		Base = { Background = bg, Surface = surface, Text = text, Accent = accent },
		Background = bg,
		Surface = surface,
		Text = text,
		Accent = accent,
		SurfaceLight = Mix(surface, dir, light and 0.07 or 0.035),
		Element = element,
		ElementHover = Mix(element, dir, 0.05),
		Stroke = Mix(surface, dir, light and 0.17 or 0.11),
		StrokeBright = Mix(surface, dir, light and 0.32 or 0.23),
		TabBar = Mix(bg, dir, 0.015),
		SubText = Mix(text, bg, 0.4),
		AccentHover = Mix(accent, dir, 0.1),
		OnAccent = Luma(accent) > 0.55 and Mix(accent, BLACK, 0.88) or Mix(accent, WHITE, 0.94),
		Knob = light and Mix(text, bg, 0.1) or WHITE,
		KnobStroke = light and Mix(bg, text, 0.35) or BLACK,
		Ripple = light and BLACK or WHITE,
		Success = light and RGB(72, 163, 87) or RGB(158, 206, 106),
		Warning = light and RGB(196, 142, 30) or RGB(224, 175, 104),
		Error = light and RGB(219, 68, 94) or RGB(247, 118, 142),
	}
end

local Themes = {}

Themes["Dark-Blue"] = DeriveTheme({
	Background = RGB(13, 15, 20), Surface = RGB(19, 22, 30),
	Text = RGB(232, 236, 246), Accent = RGB(122, 162, 247),
})
Themes["Light"] = DeriveTheme({
	Background = RGB(244, 246, 250), Surface = RGB(255, 255, 255),
	Text = RGB(28, 34, 48), Accent = RGB(66, 113, 244),
})

CurrentTheme = Themes["Dark-Blue"]

local CustomBase = nil

local function BaseColors()
	if CustomBase then
		return CustomBase
	end
	return (Themes[Setting.Theme] or Themes["Dark-Blue"]).Base
end

local function SameTheme(a, b)
	if a == b then return true end
	local x, y = a and a.Base, b and b.Base
	if not (x and y) then return false end
	return x.Background == y.Background and x.Surface == y.Surface
		and x.Text == y.Text and x.Accent == y.Accent
end

local ThemeBindings = setmetatable({}, { __mode = "k" })

local function Bind(inst, prop, key)
	if not inst then return inst end
	local b = ThemeBindings[inst]
	if not b then
		b = {}
		ThemeBindings[inst] = b
	end
	b[prop] = key
	local v = CurrentTheme[key]
	if v ~= nil then
		inst[prop] = v
	end
	return inst
end

local PendingTheme, ThemeQueued = nil, false

local function ApplyTheme(theme)
	if type(theme) == "string" then
		theme = Themes[theme] or CurrentTheme
	end
	PendingTheme = theme
	if ThemeQueued then return end
	ThemeQueued = true
	task.defer(function()
		ThemeQueued = false
		local t = PendingTheme
		if t then
			CurrentTheme = t
			for inst, binds in pairs(ThemeBindings) do
				for prop, key in pairs(binds) do
					local v = t[key]
					if v ~= nil then
						inst[prop] = v
					end
				end
			end
			Kailex.ThemeChanged:Fire(t)
		end
	end)
end

function Kailex:GetThemes()
	local t = {}
	for k in pairs(Themes) do
		table.insert(t, k)
	end
	table.sort(t)
	return t
end

local TextRegistry = setmetatable({}, { __mode = "k" })
local TextBaseSize = setmetatable({}, { __mode = "k" })

local function TS(n)
	return floor(n * (tonumber(Setting.TextScale) or 1) + 0.5)
end

local TextScaleQueued = false

local function ApplyTextScale()
	if TextScaleQueued then return end
	TextScaleQueued = true
	task.defer(function()
		TextScaleQueued = false
		for inst in pairs(TextRegistry) do
			local base = TextBaseSize[inst]
			if base then
				pcall(function()
					inst.TextSize = TS(base)
				end)
			end
		end
	end)
end

local Create

do
	local ColorProps = {
		BackgroundColor3 = true,
		TextColor3 = true,
		ImageColor3 = true,
		PlaceholderColor3 = true,
		ScrollBarImageColor3 = true,
		Color = true,
	}

	local function SetProps(inst, props)
		for prop, value in pairs(props) do
			if ColorProps[prop] and type(value) == "string" then
				Bind(inst, prop, value)
			else
				inst[prop] = value
			end
		end
	end

	function Create(className, props)
		props = props or {}
		local inst = Instance.new(className)
		local parent = props.Parent
		local children = props.Children
		if parent then props.Parent = nil end
		if children then props.Children = nil end

		if (className == "TextLabel" or className == "TextButton" or className == "TextBox")
			and type(props.TextSize) == "number" then
			TextBaseSize[inst] = props.TextSize
			TextRegistry[inst] = true
			props.TextSize = TS(props.TextSize)
		end

		local ok, err = pcall(SetProps, inst, props)
		if not ok then
			warn("[Kailex] property error (" .. className .. "): " .. tostring(err))
			for prop, value in pairs(props) do
				pcall(function()
					if ColorProps[prop] and type(value) == "string" then
						inst[prop] = CurrentTheme[value]
					else
						inst[prop] = value
					end
				end)
			end
		end

		if children then
			for _, child in ipairs(children) do
				child.Parent = inst
			end
		end
		if parent then
			inst.Parent = parent
		end
		return inst
	end
end

local function Mk(class, base)
	return function(p)
		p = p or {}
		for k, v in pairs(base) do
			if p[k] == nil then
				p[k] = v
			end
		end
		return Create(class, p)
	end
end

local Frm = Mk("Frame", { BorderSizePixel = 0 })
local Lbl = Mk("TextLabel", { BackgroundTransparency = 1 })
local Hit = Mk("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0 })
local Btn = Mk("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0 })
local TBox = Mk("TextBox", { ClearTextOnFocus = false, PlaceholderColor3 = "SubText" })
local Grp = Mk("CanvasGroup", { BorderSizePixel = 0 })
local Scr = Mk("ScrollingFrame", {
	BackgroundTransparency = 1,
	CanvasSize = UN(),
	AutomaticCanvasSize = AS.Y,
	ScrollingDirection = ESD.Y,
	ScrollBarThickness = 3,
	BorderSizePixel = 0,
})

local function UISC(parent, scale)
	return Create("UIScale", { Scale = scale or 1, Parent = parent })
end

local function Corner(radius, parent)
	return Create("UICorner", {
		CornerRadius = typeof(radius) == "UDim" and radius or UD(0, radius or 8),
		Parent = parent,
	})
end

local function StrokeBind(thickness, key, transparency, parent)
	local s = Create("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0.6,
		ApplyStrokeMode = SB,
		Parent = parent,
	})
	Bind(s, "Color", key or "Stroke")
	return s
end

local function Pad(l, r, t, b, parent)
	return Create("UIPadding", {
		PaddingLeft = UD(0, l or 0),
		PaddingRight = UD(0, r or 0),
		PaddingTop = UD(0, t or 0),
		PaddingBottom = UD(0, b or 0),
		Parent = parent,
	})
end

local function List(pad, extra)
	local p = { Padding = UD(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder }
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	return Create("UIListLayout", p)
end

local U = {}

function U.HL(pad, ha, va)
	local ex = { FillDirection = EFd.Horizontal }
	if ha then
		ex.HorizontalAlignment = ha
	end
	if va then
		ex.VerticalAlignment = va
	end
	return List(pad, ex)
end

local Icon

do
	local IconDefs = {
		Minimize = { { "b", 10, 2, .5, .5, 0 } },
		Close = { { "b", 11, 2, .5, .5, 45 }, { "b", 11, 2, .5, .5, -45 } },
		Chevron = { { "b", 7, 2, .32, .55, 45 }, { "b", 7, 2, .68, .55, -45 } },
		Search = { { "R", 8, 8, 1, 1, 1.6 }, { "b", 6, 2, .72, .72, 45 } },
		Grip = { { "b", 2, 5, .30, .72, 45 }, { "b", 2, 7, .52, .52, 45 }, { "b", 2, 9, .74, .32, 45 } },
		Gear = { { "r", 6, 6, .5, .5, 1.6 }, { "g" } },
		Check = { { "b", 6, 2, .34, .60, 45 }, { "b", 9, 2, .64, .42, -45 } },
		Reset = { { "r", 9, 9, .5, .5, 1.6 }, { "b", 4, 2, .82, .16, 0 }, { "b", 3, 2, .68, .22, 90 } },
		Pin = { { "f", 7, 7, .5, .34 }, { "b", 2, 6, .5, .76, 0 } },
	}

	function Icon(parent, kind, colorKey, size)
		colorKey = colorKey or "SubText"
		local holder = Frm({
			BackgroundTransparency = 1,
			Size = UO(14, 14),
			Parent = parent,
		})
		for _, op in ipairs(IconDefs[kind] or {}) do
			local t = op[1]
			if t == "b" or t == "f" then
				Frm({
					AnchorPoint = V2(0.5, 0.5),
					Size = UO(op[2], op[3]),
					Position = US(op[4], op[5]),
					Rotation = op[6] or 0,
					BackgroundColor3 = colorKey,
					Parent = holder,
					Children = t == "f" and { Corner(PILL) } or nil,
				})
			elseif t == "r" or t == "R" then
				local ring = Frm({
					BackgroundTransparency = 1,
					Size = UO(op[2], op[3]),
					Parent = holder,
					Children = { Corner(PILL) },
				})
				if t == "r" then
					ring.AnchorPoint = V2(0.5, 0.5)
					ring.Position = US(op[4], op[5])
				else
					ring.Position = UO(op[4], op[5])
				end
				Bind(Create("UIStroke", { Thickness = op[6] or 1.6, Parent = ring }), "Color", colorKey)
			elseif t == "g" then
				for i = 0, 7 do
					local ang = i * 45
					Frm({
						AnchorPoint = V2(0.5, 0.5),
						Position = UN(0.5, math.cos(math.rad(ang)) * 5, 0.5, math.sin(math.rad(ang)) * 5),
						Size = UO(3, 2),
						Rotation = ang,
						BackgroundColor3 = colorKey,
						Parent = holder,
					})
				end
			end
		end
		if size then
			holder.AnchorPoint = V2(0.5, 0.5)
			holder.Position = US(0.5, 0.5)
			holder.Size = UO(size, size)
		end
		return holder
	end
end

local Audio = {
	Hover = { Id = "rbxasset://sounds/electronicpingshort.wav", Speed = 1.85, Vol = 0.05 },
	Click = { Id = "rbxasset://sounds/snap.mp3", Speed = 1.25, Vol = 0.45 },
	ToggleOn = { Id = "rbxasset://sounds/electronicpingshort.wav", Speed = 1.15, Vol = 0.35 },
	Slider = { Id = "rbxasset://sounds/snap.mp3", Speed = 1.55, Vol = 0.25 },
	Error = { Id = "rbxasset://sounds/snap.mp3", Speed = 0.55, Vol = 0.55 },
	Master = 1,
}
Kailex.Audio = Audio

local SoundPool = {}
local SoundInstances = {}

local function PlaySound(kind, scale)
	if not Setting.Sounds then return end
	local a = Audio[kind]
	if type(a) ~= "table" or a.Id == "" then return end
	pcall(function()
		local pool = SoundPool[a.Id]
		if not pool then
			pool = {}
			SoundPool[a.Id] = pool
		end

		local s
		for i = 1, #pool do
			local c = pool[i]
			if not c.IsPlaying then
				s = table.remove(pool, i)
				break
			end
		end
		if not s then
			s = Instance.new("Sound")
			s.Parent = SoundService
			table.insert(SoundInstances, s)
			s.Ended:Connect(function()
				task.defer(function()
					if s.Parent ~= SoundService then return end
					if #pool < 8 then
						if not table.find(pool, s) then
							table.insert(pool, s)
						end
					else
						s:Destroy()
						RemoveValue(SoundInstances, s)
					end
				end)
			end)
		end

		s.SoundId = a.Id
		s.PlaybackSpeed = a.Speed or 1
		s.Volume = clamp((a.Vol or 0.4) * (scale or 1) * (Audio.Master or 1), 0, 1)
		s.TimePosition = 0
		s:Play()
	end)
end

local function AddHover(obj, opts)
	if Device.IsTouch then return end
	opts = opts or {}
	local baseT = opts.BaseTransparency
	if baseT == nil then
		baseT = obj.BackgroundTransparency
	end
	local hoverT = opts.HoverTransparency
	if hoverT == nil then
		hoverT = baseT
	end
	local hoverKey = opts.HoverKey or "ElementHover"
	local baseKey = opts.BaseKey or "Element"

	obj.MouseEnter:Connect(function()
		if obj:GetAttribute("NoHoverFX") or obj:GetAttribute("Disabled") then return end
		PlaySound("Hover", 0.12)
		Tween(obj, "HoverIn", { BackgroundColor3 = CurrentTheme[hoverKey], BackgroundTransparency = hoverT })
		local stroke = obj:FindFirstChildOfClass("UIStroke")
		if stroke and not opts.IgnoreStroke then
			Tween(stroke, "HoverIn", { Color = CurrentTheme.StrokeBright, Transparency = 0.25 })
		end
	end)
	obj.MouseLeave:Connect(function()
		Tween(obj, "HoverOut", { BackgroundColor3 = CurrentTheme[baseKey], BackgroundTransparency = baseT })
		local stroke = obj:FindFirstChildOfClass("UIStroke")
		if stroke and not opts.IgnoreStroke then
			Tween(stroke, "HoverOut", { Color = CurrentTheme.Stroke, Transparency = opts.StrokeTransparency or 0.6 })
		end
	end)
end

function U.MkBtn(parent, p)
	local b = Btn({
		Position = p.Pos,
		AnchorPoint = p.Ap,
		Size = p.Size,
		BackgroundColor3 = p.BgC or (p.Accent and "Accent" or "Element"),
		BackgroundTransparency = p.Trans,
		Text = p.Text,
		Font = p.Font or EF.GothamBold,
		TextSize = p.Ts,
		TextColor3 = p.Color or (p.Accent and "OnAccent" or "Text"),
		TextTruncate = p.Trunc and TTA or nil,
		TextXAlignment = p.Align,
		LayoutOrder = p.Order,
		ZIndex = p.Z,
		Parent = parent,
		Children = { Corner(p.R or 6) },
	})
	if p.Hover ~= false then
		AddHover(b, p.Accent and { HoverKey = "AccentHover", BaseKey = "Accent" } or p.Hover)
	end
	return b
end

function U.Txt(parent, p)
	return Lbl({
		Position = p.Pos,
		AnchorPoint = p.Ap,
		Size = p.Size,
		AutomaticSize = p.Auto,
		BackgroundTransparency = p.Bg,
		BackgroundColor3 = p.BgC,
		Font = p.Font or EF.Gotham,
		TextSize = p.Ts,
		TextColor3 = p.Color or "Text",
		TextTransparency = p.Trans,
		TextWrapped = p.Wrap,
		TextXAlignment = p.Align,
		TextYAlignment = p.Val,
		TextTruncate = p.Trunc and TTA or nil,
		Text = p.Text,
		LayoutOrder = p.Order,
		ZIndex = p.Z,
		Visible = p.Visible,
		Parent = parent,
		Children = p.Kids,
	})
end

function U.TxB(parent, p)
	return TBox({
		Position = p.Pos,
		AnchorPoint = p.Ap,
		Size = p.Size,
		BackgroundColor3 = p.BgC or "SurfaceLight",
		BackgroundTransparency = p.Trans,
		Visible = p.Visible,
		Text = p.Text or "",
		PlaceholderText = p.Ph,
		Font = p.Font or EF.Gotham,
		TextSize = p.Ts,
		TextColor3 = "Text",
		TextXAlignment = p.Align,
		LayoutOrder = p.Order,
		ZIndex = p.Z,
		Parent = parent,
		Children = p.Kids,
	})
end

function U.Overlay(parent, z, vis, bg)
	return Hit({
		Size = US(1, 1),
		ZIndex = z,
		Visible = vis,
		BackgroundColor3 = bg,
		Parent = parent,
	})
end

function U.ModalCard(parent, z, w, h, radius, strokeT)
	return Grp({
		AnchorPoint = V2(0.5, 0.5),
		Position = US(0.5, 0.5),
		Size = UO(w, h),
		BackgroundColor3 = "Surface",
		GroupTransparency = 1,
		ZIndex = z,
		Parent = parent,
		Children = { Corner(radius), StrokeBind(1, "Stroke", strokeT) },
	})
end

local SaveManager = {
	Folder = Setting.SaveFolder,
	File = tostring(game.PlaceId) .. ".json",
	Data = {},
	Delay = 1,
}
SaveManager.DataChanged = Signal.new()

do
	if HasFileSystem then
		pcall(fs.makefolder, SaveManager.Folder)
		local path = SaveManager.Folder .. "/" .. SaveManager.File
		if fs.isfile(path) then
			local ok, res = pcall(function()
				return HttpService:JSONDecode(fs.readfile(path))
			end)
			if ok and type(res) == "table" then
				SaveManager.Data = res
			else
				local ok2, res2 = pcall(function()
					return HttpService:JSONDecode(fs.readfile(path .. ".bak"))
				end)
				if ok2 and type(res2) == "table" then
					SaveManager.Data = res2
				end
			end
		end
	end
end

local function IsInternalKey(key)
	return type(key) == "string" and key:sub(1, 2) == "__"
end

function SaveManager:Set(key, value)
	if key == nil then return end
	if self.Data[key] == value then return end
	self.Data[key] = value
	if not Setting.AutoSave then return end
	if self._pending then return end
	self._pending = true
	task.delay(self.Delay, function()
		self._pending = false
		self:Flush()
	end)
end

function SaveManager:Flush()
	if not HasFileSystem then return end
	local ok, err = pcall(function()
		local path = self.Folder .. "/" .. self.File
		if fs.isfile(path) then
			pcall(function()
				fs.writefile(path .. ".bak", fs.readfile(path))
			end)
		end
		fs.writefile(path, HttpService:JSONEncode(self.Data))
	end)
	if not ok then
		warn("[Kailex] save failed: " .. tostring(err))
	end
end

function SaveManager:Get(key, default)
	if key == nil then return default end
	local v = self.Data[key]
	if v == nil then return default end
	if default ~= nil and typeof(v) ~= typeof(default) then return default end
	return v
end

function SaveManager:Clear()
	self.Data = {}
	self:Flush()
	self.DataChanged:Fire()
end

local function SaveValue(key, value)
	if key then
		SaveManager:Set(key, value)
	end
end

function U.LoadNum(saveKey, default)
	local v = SaveManager:Get(saveKey, default)
	if type(v) == "number" then
		return v
	end
	return default
end

local Configs = { Folder = SaveManager.Folder .. "/Profiles" }

function Configs:Path(name)
	return self.Folder .. "/" .. Sanitize(name) .. ".json"
end

function Configs:List()
	if not HasFileSystem then return {} end
	local names = {}
	local ok, files = pcall(fs.listfiles, self.Folder)
	if ok and type(files) == "table" then
		for _, f in ipairs(files) do
			local name = tostring(f):match("([^/\\]+)%.json$")
			if name then
				table.insert(names, name)
			end
		end
	end
	table.sort(names)
	return names
end

function Configs:Save(name)
	if not HasFileSystem or not name or name == "" then return false end
	pcall(fs.makefolder, self.Folder)
	return pcall(function()
		local export = {}
		for k, v in pairs(SaveManager.Data) do
			if not IsInternalKey(k) then
				export[k] = v
			end
		end
		fs.writefile(self:Path(name), HttpService:JSONEncode(export))
	end)
end

function Configs:Load(name)
	if not HasFileSystem or not name then return false end
	local ok, res = pcall(function()
		return HttpService:JSONDecode(fs.readfile(self:Path(name)))
	end)
	if ok and type(res) == "table" then
		local merged = {}
		for k, v in pairs(res) do
			merged[k] = v
		end
		for k, v in pairs(SaveManager.Data) do
			if IsInternalKey(k) then
				merged[k] = v
			end
		end
		SaveManager.Data = merged
		SaveManager:Flush()
		SaveManager.DataChanged:Fire()
		return true
	end
	return false
end

function Configs:Delete(name)
	if not HasFileSystem or not name then return false end
	return pcall(fs.delfile, self:Path(name))
end

local SaveReloadRegistry = {}

LibMaid:Give(SaveManager.DataChanged:Connect(function()
	for key, fns in pairs(SaveReloadRegistry) do
		local n = #fns
		if n > 0 then
			local v = SaveManager:Get(key, nil)
			if v ~= nil then
				for i = 1, n do
					SafeCall(fns[i], v)
				end
			end
		end
	end
end))

local ScreenGui = Create("ScreenGui", {
	Name = "KailexUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
})
pcall(protect_gui, ScreenGui)
ScreenGui.Parent = SafeParent

local Root = Frm({
	Name = "Root",
	BackgroundTransparency = 1,
	Size = US(1, 1),
	Parent = ScreenGui,
})
local RootScale = UISC(Root)

local function Layer(name)
	return Frm({ Name = name, BackgroundTransparency = 1, Size = US(1, 1), Parent = Root })
end

local LayerWindows = Layer("Windows")
local LayerOverlay = Layer("Overlay")
local LayerNotify = Layer("Notify")
local LayerTooltip = Layer("Tooltip")

local Camera = Workspace.CurrentCamera
local Viewport = V2(1920, 1080)
local ViewportHooks = {}

local function GetScale()
	return RootScale and RootScale.Scale or 1
end

local function ClampToScreen(inst)
	local s = GetScale()
	local w, h = inst.AbsoluteSize.X, inst.AbsoluteSize.Y
	if w < 1 or h < 1 then return end
	local x, y = inst.AbsolutePosition.X, inst.AbsolutePosition.Y
	local nx = ClampEdge(x, w, Viewport.X, 8)
	local ny = ClampEdge(y, h, Viewport.Y, 8)
	if nx ~= x or ny ~= y then
		local ap = inst.AnchorPoint
		inst.Position = UO((nx + ap.X * w) / s, (ny + ap.Y * h) / s)
	end
end

local function UpdateViewport()
	if not Camera then return end
	Viewport = Camera.ViewportSize
	local short = math.min(Viewport.X, Viewport.Y)
	local s = clamp(short / 880, 0.85, 1.1)
	if Device.IsTouch then
		s = math.max(s, 1)
	end
	s = s * (tonumber(Setting.UIScale) or 1)
	RootScale.Scale = s
	Root.Size = US(1 / s, 1 / s)
	for _, win in ipairs(Kailex.Windows) do
		if not win._destroyed then
			pcall(function()
				win:OnViewport()
			end)
		end
	end
	for _, fn in ipairs(ViewportHooks) do
		pcall(fn)
	end
end

local CameraConn = nil

local function BindCamera(cam)
	if cam == Camera then return end
	if CameraConn then
		CameraConn:Disconnect()
		CameraConn = nil
	end
	Camera = cam
	if cam then
		CameraConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateViewport)
	end
end

BindCamera(Workspace.CurrentCamera)

LibMaid:Give(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	BindCamera(Workspace.CurrentCamera)
end))

LibMaid:Give(function()
	if CameraConn then
		CameraConn:Disconnect()
	end
end)

local ModalManager = { Stack = {} }

function ModalManager.Push(owner, closer)
	local entry = { Owner = owner, Close = closer }
	table.insert(ModalManager.Stack, entry)
	return entry
end

function ModalManager.Remove(entry)
	if not entry then return end
	RemoveValue(ModalManager.Stack, entry)
end

function ModalManager.CloseAll(owner)
	for i = #ModalManager.Stack, 1, -1 do
		local e = ModalManager.Stack[i]
		if owner == nil or e.Owner == nil or e.Owner == owner then
			table.remove(ModalManager.Stack, i)
			pcall(e.Close)
		end
	end
end

local DragManager = { Active = nil }

local function TrackInput(handle, cfg)
	handle.InputBegan:Connect(function(input)
		if DragManager.Active then return end
		if input.UserInputType ~= EUT.MouseButton1
			and input.UserInputType ~= EUT.Touch then return end
		if cfg.Guard and not cfg.Guard(input) then return end

		local active = cfg.Active or handle
		DragManager.Active = active
		local m = Maid.new()
		local state = { Input = input, Alive = true }

		local function finish()
			if not state.Alive then return end
			state.Alive = false
			if DragManager.Active == active then
				DragManager.Active = nil
			end
			m:Destroy()
			if cfg.End then
				SafeCall(cfg.End, state)
			end
		end

		m:Give(UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == EUT.MouseButton1
				or inp.UserInputType == EUT.Touch then
				finish()
			end
		end))
		m:Give(handle.Destroying:Connect(finish))
		m:Give(RunService.Heartbeat:Connect(function()
			if not IsInputDown(input.UserInputType) then
				finish()
			end
		end))

		if cfg.Move then
			m:Give(UIS.InputChanged:Connect(function(inp)
				if state.Alive and (inp.UserInputType == EUT.MouseMovement
					or inp.UserInputType == EUT.Touch) then
					SafeCall(cfg.Move, inp.Position, state)
				end
			end))
		end
		if cfg.Step then
			m:Give(RunService.RenderStepped:Connect(function()
				if state.Alive then
					SafeCall(cfg.Step, state)
				end
			end))
		end

		if cfg.Start then SafeCall(cfg.Start, state) end
		if cfg.Move and cfg.MoveNow then
			SafeCall(cfg.Move, input.Position, state)
		end
	end)
	return handle
end

local function MakeDraggable(handle, target, opts)
	opts = opts or {}
	local threshold = opts.Threshold or 6
	TrackInput(handle, {
		Active = target,
		Start = function(state)
			if target.AnchorPoint.X ~= 0 or target.AnchorPoint.Y ~= 0 then
				local s = GetScale()
				target.AnchorPoint = V2(0, 0)
				target.Position = UO(target.AbsolutePosition.X / s, target.AbsolutePosition.Y / s)
			end
			state.StartPos = target.Position
			state.StartMouse = UIS:GetMouseLocation()
			state.Moved = false
		end,
		Step = function(state)
			local mouse = UIS:GetMouseLocation()
			if not state.Moved then
				local dx = mouse.X - state.StartMouse.X
				local dy = mouse.Y - state.StartMouse.Y
				if math.abs(dx) + math.abs(dy) > threshold then
					state.Moved = true
					handle:SetAttribute("Dragging", true)
					if opts.OnDragStart then
						SafeCall(opts.OnDragStart, target)
					end
					state.StartPos = target.Position
					state.StartMouse = mouse
				end
			end
			if state.Moved then
				local s = GetScale()
				local dx = mouse.X - state.StartMouse.X
				local dy = mouse.Y - state.StartMouse.Y
				target.Position = UO(state.StartPos.X.Offset + dx / s, state.StartPos.Y.Offset + dy / s)
				if opts.Clamp then
					ClampToScreen(target)
				end
			end
		end,
		End = function(state)
			handle:SetAttribute("Dragging", nil)
			if state.Moved and opts.OnEnd then
				SafeCall(opts.OnEnd)
			end
		end,
	})
end

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == EUT.MouseButton1
		or input.UserInputType == EUT.Touch then
		task.defer(function()
			local anyDown = false
			local ok, btns = pcall(UIS.GetMouseButtonsPressed, UIS)
			if ok and type(btns) == "table" then
				anyDown = #btns > 0
			end
			if not anyDown then
				DragManager.Active = nil
			end
		end)
	end
end)

local RipplePool = {}

local function newRipple()
	local r = Frm({
		BackgroundColor3 = WHITE,
		Visible = false,
		AnchorPoint = V2(0.5, 0.5),
		ZIndex = 50,
		Children = { Corner(PILL) },
	})
	Once(r.Destroying, function()
		RemoveValue(RipplePool, r)
	end)
	table.insert(RipplePool, r)
	return r
end

local function ApplyRipple(target, inputPos)
	if not Setting.Effects then return end
	if not target or not target.Parent or Device.IsConsole then return end

	local count = target:GetAttribute("__rpl")
	if not count then
		target:SetAttribute("__rplPrev", target.ClipsDescendants)
	end
	target.ClipsDescendants = true
	count = (count or 0) + 1
	target:SetAttribute("__rpl", count)

	local mouse = inputPos or UIS:GetMouseLocation()
	local s = GetScale()
	local relX = (mouse.X - target.AbsolutePosition.X) / s
	local relY = (mouse.Y - target.AbsolutePosition.Y) / s

	local rpl
	for _, r in ipairs(RipplePool) do
		if not r.Visible and not r.Parent then
			rpl = r
			break
		end
	end
	if not rpl then
		rpl = newRipple()
	end
	if not pcall(function()
			rpl.Parent = target
		end) then
		RemoveValue(RipplePool, rpl)
		rpl = newRipple()
		rpl.Parent = target
	end

	rpl.Position = UO(relX, relY)
	rpl.Size = UO(0, 0)
	rpl.BackgroundColor3 = CurrentTheme.Ripple
	rpl.BackgroundTransparency = 0.68
	rpl.Visible = true

	local size = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * 1.2
	local t = Tween(rpl, "Ripple", {
		Size = UO(size / s, size / s),
		BackgroundTransparency = 1,
	})
	Once(t.Completed, function()
		if rpl.Visible then
			rpl.Visible = false
			rpl.Parent = nil
		end
		local c = (target:GetAttribute("__rpl") or 1) - 1
		if c > 0 then
			target:SetAttribute("__rpl", c)
		else
			target:SetAttribute("__rpl", nil)
			target.ClipsDescendants = target:GetAttribute("__rplPrev") == true
			target:SetAttribute("__rplPrev", nil)
		end
	end)
end

local function Tap(inst, kind, scale)
	ApplyRipple(inst)
	PlaySound(kind or "Click", scale)
end

local function Click(maid, btn, fn)
	maid:Give(btn.MouseButton1Click:Connect(fn))
end

local FX = {}

function FX.Shake(inst, dist)
	if not inst then return end
	local orig = inst.Position
	local d = dist or 8
	Tween(inst, "Fast", { Position = orig + UO(d, 0) }, function()
		Tween(inst, "Fast", { Position = orig + UO(-d * 0.7, 0) }, function()
			Tween(inst, "Fast", { Position = orig + UO(d * 0.35, 0) }, function()
				Tween(inst, "Snappy", { Position = orig })
			end)
		end)
	end)
end

local Tooltip = {}

do
	local frame = Frm({
		BackgroundColor3 = "SurfaceLight",
		Size = UO(0, 26),
		Visible = false,
		ZIndex = 100,
		Parent = LayerTooltip,
		Children = { Corner(6), StrokeBind(1, "Stroke", 0.35) },
	})
	local label = U.Txt(frame, {
		Size = UN(1, -16, 1, 0),
		Pos = UO(8, 0),
		Ts = 12,
		Wrap = true,
		Align = ETA.Left,
	})
	local tipScale = UISC(frame)
	local maid = Maid.new()
	local hideToken = 0
	local tipW, tipH = 0, 26

	local function position()
		local m = UIS:GetMouseLocation()
		local s = GetScale()
		local x, y = m.X + 14, m.Y + 18
		if x + tipW > Viewport.X - 8 then x = m.X - tipW - 14 end
		if y + tipH > Viewport.Y - 8 then y = m.Y - tipH - 16 end
		if x < 8 then x = 8 end
		if y < 8 then y = 8 end
		frame.Position = UO(x / s, y / s)
	end

	function Tooltip.Show(text)
		if not text or text == "" then return end
		hideToken += 1
		label.Text = text
		local bounds = TextService:GetTextSize(text, TS(12), EF.Gotham, V2(340, 1000))
		tipW = math.min(bounds.X + 18, 358)
		tipH = clamp(bounds.Y + 10, 24, 92)
		frame.Size = UO(tipW, tipH)
		frame.Visible = true
		frame.BackgroundTransparency = 1
		label.TextTransparency = 1
		tipScale.Scale = 0.93
		position()
		maid:Clean()
		maid:Give(UIS.InputChanged:Connect(function(input)
			if input.UserInputType == EUT.MouseMovement or input.UserInputType == EUT.Touch then
				position()
			end
		end))
		Tween(frame, "Fast", { BackgroundTransparency = 0.06 })
		Tween(label, "Fast", { TextTransparency = 0 })
		Tween(tipScale, "PopSoft", { Scale = 1 })
	end

	function Tooltip.Hide()
		if not frame.Visible then return end
		hideToken += 1
		local tk = hideToken
		Tween(tipScale, "Vanish", { Scale = 0.95 })
		Tween(frame, "Vanish", { BackgroundTransparency = 1 })
		Tween(label, "Vanish", { TextTransparency = 1 })
		task.delay(0.16, function()
			if hideToken == tk then
				frame.Visible = false
			end
		end)
		maid:Clean()
	end

	if Device.IsTouch then
		local bound = setmetatable({}, { __mode = "k" })

		function Tooltip.BindTouch(obj, getText)
			bound[obj] = getText
		end

		LibMaid:Give(UIS.TouchEnded:Connect(Tooltip.Hide))

		LibMaid:Give(AddInputHook(function()
			return true
		end, function(input)
			if input.UserInputType ~= EUT.Touch then return end
			task.delay(0.5, function()
				if not IsInputDown(EUT.Touch) then return end
				local m = UIS:GetMouseLocation()
				for obj, getText in pairs(bound) do
					local ap, as = obj.AbsolutePosition, obj.AbsoluteSize
					if m.X >= ap.X and m.Y >= ap.Y and m.X <= ap.X + as.X and m.Y <= ap.Y + as.Y then
						local text = getText()
						if text and text ~= "" then
							Tooltip.Show(text)
						end
						return
					end
				end
			end)
		end))
	end
end

local function AddTooltip(obj, ref)
	local function getText()
		return type(ref) == "table" and ref.Text or ref
	end
	if Device.IsTouch then
		Tooltip.BindTouch(obj, getText)
	else
		obj.MouseEnter:Connect(function()
			local text = getText()
			if not text or text == "" then return end
			Tooltip.Show(text)
		end)
		obj.MouseLeave:Connect(Tooltip.Hide)
	end
	obj.Destroying:Connect(Tooltip.Hide)
end

local MAX_ACTIVE = Device.IsTouch and 3 or 5
local POOL_CAP = MAX_ACTIVE + 3
local TypeColors = { info = "Accent", success = "Success", warning = "Warning", error = "Error" }
local queue = {}
local active = 0
local pool = {}

local container = Frm({
	BackgroundTransparency = 1,
	AnchorPoint = V2(1, 1),
	Position = UN(1, -14, 1, -14),
	Size = UN(0, 320, 1, -28),
	Parent = LayerNotify,
	Children = { List(8, { VerticalAlignment = EVA.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) },
})

local process

function U.ClearActions(actionsFrame)
	for _, b in ipairs(actionsFrame:GetChildren()) do
		if b:IsA("TextButton") then
			b:Destroy()
		end
	end
end

local function newCard()
	local card = Frm({
		BackgroundColor3 = "Surface",
		BackgroundTransparency = 1,
		Size = UN(1, 0, 0, 0),
		Visible = false,
		Parent = container,
		Children = { Corner(10) },
	})
	local stroke = StrokeBind(1, "Stroke", 0.5, card)
	local dot = Frm({
		Size = UO(7, 7),
		Position = UO(12, 11),
		BackgroundColor3 = CurrentTheme.Accent,
		ZIndex = 2,
		Parent = card,
		Children = { Corner(PILL) },
	})
	local title = U.Txt(card, {
		Pos = UO(26, 8),
		Size = UN(1, -38, 0, 16),
		Font = EF.GothamBold,
		Ts = 13,
		Align = ETA.Left,
		Trunc = true,
		Z = 2,
	})
	local body = U.Txt(card, {
		Pos = UO(12, 26),
		Size = UN(1, -24, 0, 0),
		Ts = 12,
		Color = "SubText",
		Wrap = true,
		Align = ETA.Left,
		Val = ETY.Top,
		Z = 2,
	})
	local actions = Frm({
		BackgroundTransparency = 1,
		Position = UN(0, 12, 1, -32),
		Size = UN(1, -24, 0, 26),
		ZIndex = 2,
		Parent = card,
		Children = { U.HL(6, Enum.HorizontalAlignment.Right) },
	})
	local progress = Frm({
		AnchorPoint = V2(0, 1),
		Position = UN(0, 12, 1, -5),
		Size = UN(1, -24, 0, 2),
		BackgroundColor3 = CurrentTheme.Accent,
		ZIndex = 1,
		Parent = card,
		Children = { Corner(PILL) },
	})
	local hit = U.Overlay(card, 3)
	local cardScale = UISC(card)
	local dotScale = UISC(dot)
	local meta = {
		Card = card, Stroke = stroke, Dot = dot, Title = title,
		Body = body, Actions = actions, Progress = progress, Hit = hit, InUse = false,
		CardScale = cardScale, DotScale = dotScale, ThemeKey = "Accent",
	}
	table.insert(pool, meta)
	return meta
end

local function getFreeCard()
	for _, m in ipairs(pool) do
		if not m.InUse and not m.Card.Visible then
			return m
		end
	end
	if #pool < POOL_CAP then
		return newCard()
	end
	return nil
end

local function dismiss(meta)
	if not meta.InUse then return end
	meta.InUse = false
	active = math.max(0, active - 1)
	if meta.DelayThread then
		pcall(task.cancel, meta.DelayThread)
		meta.DelayThread = nil
	end
	if meta.ProgressTween then
		pcall(function()
			meta.ProgressTween:Cancel()
		end)
		meta.ProgressTween = nil
	end
	if meta.Maid then
		meta.Maid:Destroy()
		meta.Maid = nil
	end

	Tween(meta.Card, "Fast", { BackgroundTransparency = 1 })
	Tween(meta.Stroke, "Fast", { Transparency = 1 })
	Tween(meta.Title, "Fast", { TextTransparency = 1 })
	Tween(meta.Body, "Fast", { TextTransparency = 1 })
	Tween(meta.Progress, "Fast", { BackgroundTransparency = 1 })
	U.ClearActions(meta.Actions)
	if meta.CardScale then
		Tween(meta.CardScale, "Vanish", { Scale = 0.88 })
	end
	Tween(meta.Card, "Snappy", { Size = UN(1, 0, 0, 0) }, function()
		if not meta.InUse then
			meta.Card.Visible = false
		end
		process()
	end)
	process()
end

process = function()
	while active < MAX_ACTIVE and #queue > 0 do
		local item = table.remove(queue, 1)
		local meta = getFreeCard()
		if not meta then
			table.insert(queue, 1, item)
			break
		end
		active += 1
		meta.InUse = true

		local themeKey = TypeColors[item.Type] or "Accent"
		meta.ThemeKey = themeKey
		meta.Card.Visible = true
		meta.Card.BackgroundColor3 = CurrentTheme.Surface
		meta.Stroke.Color = CurrentTheme.Stroke
		meta.Dot.BackgroundColor3 = CurrentTheme[themeKey]
		meta.Progress.BackgroundColor3 = CurrentTheme[themeKey]
		meta.Title.TextColor3 = CurrentTheme.Text
		meta.Body.TextColor3 = CurrentTheme.SubText
		meta.Title.Text = item.Title
		meta.Body.Text = item.Text

		local textH = 0
		if item.Text ~= "" then
			local b = TextService:GetTextSize(item.Text, TS(12), EF.Gotham, V2(296, 400))
			textH = math.min(b.Y, 120)
			meta.Body.Size = UN(1, -24, 0, textH)
			meta.Body.Visible = true
		else
			meta.Body.Visible = false
		end

		local actCount = 0
		U.ClearActions(meta.Actions)
		if type(item.Actions) == "table" then
			local cardMaid = Maid.new()
			meta.Maid = cardMaid
			for i = 1, math.min(#item.Actions, 3) do
				local a = item.Actions[i]
				local b = U.MkBtn(meta.Actions, {
					Size = UO(64, 24),
					Text = tostring(a.Text or "OK"),
					Ts = 11,
					Order = i,
					Z = 3,
				})
				actCount += 1
				cardMaid:Give(b.MouseButton1Click:Connect(function()
					if not meta.InUse then return end
					dismiss(meta)
					if type(a.Callback) == "function" then
						SafeCall(a.Callback)
					end
				end))
			end
		end

		local cardH = 38 + textH + (actCount > 0 and 30 or 0)
		meta.Card.BackgroundTransparency = 1
		meta.Stroke.Transparency = 1
		meta.Title.TextTransparency = 1
		meta.Body.TextTransparency = 1
		meta.Progress.BackgroundTransparency = 1
		meta.Progress.Size = UN(1, -24, 0, 2)
		meta.Card.Size = UN(1, 0, 0, 0)
		if meta.CardScale then meta.CardScale.Scale = 0.9 end
		if meta.DotScale then meta.DotScale.Scale = 0 end
		if not meta.Maid then meta.Maid = Maid.new() end

		Tween(meta.Card, "Snappy", { Size = UN(1, 0, 0, cardH) })
		Tween(meta.Card, "Snappy", { BackgroundTransparency = 0.04 })
		Tween(meta.Stroke, "Snappy", { Transparency = 0.5 })
		Tween(meta.Title, "Snappy", { TextTransparency = 0 })
		if textH > 0 then
			Tween(meta.Body, "Snappy", { TextTransparency = 0 })
		end
		Tween(meta.Progress, "Snappy", { BackgroundTransparency = 0 })
		if meta.CardScale then
			Tween(meta.CardScale, "PopSoft", { Scale = 1 })
		end
		if meta.DotScale then
			Tween(meta.DotScale, "Pop", { Scale = 1 })
		end

		local duration = math.max(0.5, tonumber(item.Duration) or 4)
		local remaining = duration
		local startedAt = os.clock()
		meta.DelayThread = task.delay(duration, function()
			meta.DelayThread = nil
			dismiss(meta)
		end)
		meta.ProgressTween = Tween(meta.Progress,
			TweenInfo.new(duration, E.Linear),
			{ Size = UN(0, 0, 0, 2) })

		meta.Maid:Give(meta.Hit.MouseEnter:Connect(function()
			if not meta.InUse then return end
			if meta.ProgressTween then
				pcall(function()
					meta.ProgressTween:Pause()
				end)
			end
			if meta.DelayThread then
				pcall(task.cancel, meta.DelayThread)
				remaining = math.max(0.05, remaining - (os.clock() - startedAt))
				meta.DelayThread = nil
			end
		end))
		meta.Maid:Give(meta.Hit.MouseLeave:Connect(function()
			if not meta.InUse then return end
			startedAt = os.clock()
			if meta.ProgressTween then
				pcall(function()
					meta.ProgressTween:Cancel()
				end)
				meta.ProgressTween = Tween(meta.Progress,
					TweenInfo.new(math.max(0.05, remaining), E.Linear),
					{ Size = UN(0, 0, 0, 2) })
			end
			meta.DelayThread = task.delay(remaining, function()
				meta.DelayThread = nil
				dismiss(meta)
			end)
		end))
		meta.Maid:Give(meta.Hit.MouseButton1Click:Connect(function()
			dismiss(meta)
		end))
	end
end

LibMaid:Give(Kailex.ThemeChanged:Connect(function()
	for _, m in ipairs(pool) do
		if m.InUse then
			local c = CurrentTheme[m.ThemeKey or "Accent"]
			m.Dot.BackgroundColor3 = c
			m.Progress.BackgroundColor3 = c
			m.Card.BackgroundColor3 = CurrentTheme.Surface
			m.Stroke.Color = CurrentTheme.Stroke
			m.Title.TextColor3 = CurrentTheme.Text
			m.Body.TextColor3 = CurrentTheme.SubText
		end
	end
end))

function Kailex:Notify(data)
	if type(data) == "string" then
		data = { Text = data }
	end
	data = data or {}
	local t = string.lower(tostring(data.Type or "info"))
	if not TypeColors[t] then
		t = "info"
	end

	local actions
	if type(data.Actions) == "table" then
		actions = {}
		for i, a in ipairs(data.Actions) do
			if type(a) == "table" and a.Text then
				actions[#actions + 1] = { Text = a.Text, Callback = a.Callback }
			end
		end
	end

	local entry = {
		Title = data.Title or (t == "info" and "Notice" or (t:sub(1, 1):upper() .. t:sub(2))),
		Text = tostring(data.Text or data.Description or ""),
		Duration = data.Duration,
		Type = t,
		Actions = actions,
	}
	table.insert(queue, entry)
	process()
end

local function RunCallback(fn, ctxName, ...)
	if type(fn) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			ReportError("Callback error" .. (ctxName and (" - " .. ctxName) or ""), err)
		end
	end)
end

local function GetClipboardFn()
	local ok, sc = pcall(function()
		return setclipboard or toclipboard or setrbxclipboard
	end)
	if ok and type(sc) == "function" then
		return sc
	end
	return nil
end

local function CopyToClipboard(text)
	local setc = GetClipboardFn()
	if setc then
		pcall(setc, tostring(text))
		Kailex:Notify({ Title = "Copied", Text = tostring(text), Type = "Success", Duration = 2 })
	else
		Kailex:Notify({ Title = "Copy", Text = tostring(text), Duration = 6 })
	end
end

local ModalActive = false

function Kailex:Confirm(data, onAccept)
	if ModalActive then return nil end
	if type(data) == "string" then
		data = { Text = data }
	end
	data = data or {}
	if type(onAccept) == "function" then
		data.OnAccept = onAccept
	end

	for _, w in ipairs(Kailex.Windows) do
		if not w._destroyed and w._closeDropdowns then
			w:_closeDropdowns()
		end
	end

	ModalActive = true
	local maid = Maid.new()
	maid:Give(function()
		ModalActive = false
	end)

	local dimmer = U.Overlay(LayerOverlay, 300, nil, CN(0, 0, 0))
	maid:Give(dimmer)
	maid:Link(dimmer)

	local card = U.ModalCard(LayerOverlay, 301, 360, 200, 12, 0.4)
	Pad(18, 18, 16, 16, card)
	maid:Give(card)

	U.Txt(card, {
		Size = UN(1, 0, 0, 18),
		Font = EF.GothamBold,
		Ts = 15,
		Align = ETA.Left,
		Trunc = true,
		Text = data.Title or "Are you sure?",
	})

	local bodyText = tostring(data.Text or data.Description or "")
	local b = TextService:GetTextSize(bodyText, TS(13), EF.Gotham, V2(324, 300))
	local bodyH = math.min(b.Y, 140)
	U.Txt(card, {
		Pos = UO(0, 24),
		Size = UN(1, 0, 0, bodyH),
		Ts = 13,
		Color = "SubText",
		Wrap = true,
		Align = ETA.Left,
		Val = ETY.Top,
		Text = bodyText,
	})

	local btnRow = Frm({
		BackgroundTransparency = 1,
		AnchorPoint = V2(0, 1),
		Position = UN(0, 0, 1, 0),
		Size = UN(1, 0, 0, 34),
		Parent = card,
	})

	local decline = U.MkBtn(btnRow, {
		Pos = UN(0, 0, 0, 0),
		Size = UN(0.48, -4, 1, 0),
		Text = data.DeclineText or data.CancelText or "Cancel",
		Ts = 13,
	})
	local accept = U.MkBtn(btnRow, {
		Pos = UN(0.52, 0, 0, 0),
		Size = UN(0.48, -4, 1, 0),
		Text = data.AcceptText or data.ConfirmText or "Confirm",
		Ts = 13,
		Accent = true,
	})

	card.Size = UO(360, 16 + 18 + 6 + bodyH + 14 + 34 + 16)
	local scale = UISC(card, 0.88)

	local closed = false
	local modalEntry

	local function close(accepted)
		if closed then return end
		closed = true
		ModalManager.Remove(modalEntry)
		Tween(dimmer, "Fast", { BackgroundTransparency = 1 })
		Tween(scale, "Vanish", { Scale = 0.92 })
		Tween(card, "Fast", { GroupTransparency = 1 })
		if accepted and data.OnAccept then
			SafeCall(data.OnAccept, true)
		end
		if not accepted and data.OnDecline then
			SafeCall(data.OnDecline, false)
		end
		task.delay(0.2, function()
			maid:Destroy()
		end)
	end

	modalEntry = ModalManager.Push(nil, function()
		close(false)
	end)

	Click(maid, accept, function()
		close(true)
		Tap(accept)
	end)
	Click(maid, decline, function()
		close(false)
		Tap(decline)
	end)
	Click(maid, dimmer, function()
		close(false)
	end)

	local hook = AddInputHook(function()
		return not closed
	end, function(input, gp)
		if gp then return end
		if input.KeyCode == EKC.Return or input.KeyCode == EKC.KeypadEnter then
			close(true)
		elseif input.KeyCode == EKC.Escape then
			close(false)
		end
	end)
	maid:Give(function()
		RemoveInputHook(hook)
	end)

	Tween(dimmer, "Normal", { BackgroundTransparency = 0.5 })
	Tween(card, "Snappy", { GroupTransparency = 0 })
	Tween(scale, "Pop", { Scale = 1 })
	return card
end

local QuickWidgets = { Active = {} }

function QuickWidgets.Destroy(el)
	local w = QuickWidgets.Active[el]
	if not w then return end
	QuickWidgets.Active[el] = nil
	Tween(w.Frame, "Collapse", { Size = UO(0, 0) }, function()
		w.Maid:Destroy()
		w.Frame:Destroy()
	end)
end

function QuickWidgets.Toggle(element)
	if QuickWidgets.Active[element] then
		QuickWidgets.Destroy(element)
		return
	end

	local count = 0
	for _ in pairs(QuickWidgets.Active) do
		count += 1
	end

	local name = element.Title
	local s = GetScale()
	local widget = Frm({
		Size = UO(0, 0),
		Position = UO((Viewport.X - 70) / s, (Viewport.Y * 0.35 + count * 56) / s),
		BackgroundColor3 = "Surface",
		ZIndex = 20,
		Parent = LayerWindows,
		Children = { Corner(12), StrokeBind(1, "Stroke", 0.4) },
	})
	local wMaid = Maid.new()
	wMaid:Link(widget)
	QuickWidgets.Active[element] = { Frame = widget, Maid = wMaid }

	local state = element:Get() == true
	local hit = U.Overlay(widget)
	local letter = U.Txt(widget, {
		Ap = V2(0.5, 0.5),
		Pos = US(0.5, 0.42),
		Size = UO(20, 20),
		Font = EF.GothamBold,
		Ts = 14,
		Text = name:sub(1, 1):upper(),
	})
	local dot = Frm({
		AnchorPoint = V2(0.5, 1),
		Position = UN(0.5, 0, 1, -8),
		Size = UO(6, 6),
		BackgroundColor3 = CurrentTheme.Accent,
		Parent = widget,
		Children = { Corner(PILL) },
	})
	local closeB = Hit({
		AnchorPoint = V2(1, 0),
		Position = UN(1, -2, 0, 2),
		Size = UO(14, 14),
		Text = "x",
		Font = EF.GothamBold,
		TextSize = 12,
		TextColor3 = "SubText",
		Parent = widget,
	})

	local function refresh()
		dot.BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Stroke
	end
	refresh()

	MakeDraggable(hit, widget, { Clamp = true })
	Click(wMaid, hit, function()
		if hit:GetAttribute("Dragging") then return end
		ApplyRipple(hit)
		state = not state
		element:Set(state)
		refresh()
	end)
	Click(wMaid, closeB, function()
		QuickWidgets.Destroy(element)
	end)
	wMaid:Give(element.Changed:Connect(function(v)
		state = v == true
		refresh()
	end))
	wMaid:Give(Kailex.ThemeChanged:Connect(refresh))

	local letterScale = UISC(letter)
	letterScale.Scale = 0.2
	Tween(letterScale, "Pop", { Scale = 1 })
	Tween(widget, "SpringBig", { Size = UO(46, 46) })
end

table.insert(ViewportHooks, function()
	for _, w in pairs(QuickWidgets.Active) do
		ClampToScreen(w.Frame)
	end
	if Kailex._mobileButton then
		ClampToScreen(Kailex._mobileButton)
	end
end)

local ContextMenu = {}
local ctxFrame, ctxCatcher
local ctxEntry = nil
local ctxToken = 0

local function buildCtx()
	ctxFrame = Frm({
		BackgroundColor3 = "SurfaceLight",
		Visible = false,
		ZIndex = 320,
		Parent = LayerOverlay,
		Children = {
			Corner(10), StrokeBind(1, "Stroke", 0.25), List(2), Pad(6, 6, 6, 6),
		},
	})
	ctxCatcher = U.Overlay(LayerOverlay, 310, false)
	ctxCatcher.MouseButton1Click:Connect(function()
		ContextMenu.Hide()
	end)
end

function ContextMenu.Show(items, x, y)
	if not items or #items == 0 then return end
	if not ctxFrame then buildCtx() end
	ctxToken += 1

	for _, ch in ipairs(ctxFrame:GetChildren()) do
		if ch:IsA("TextButton") or (ch:IsA("Frame") and ch.Name == "__sep") then
			ch:Destroy()
		end
	end

	local width = 140
	local totalH = 12
	for i, item in ipairs(items) do
		if item.Separator then
			Frm({
				Name = "__sep",
				BackgroundColor3 = "Stroke",
				BackgroundTransparency = 0.4,
				Size = UN(1, 0, 0, 1),
				LayoutOrder = i,
				Parent = ctxFrame,
			})
			totalH += 3
		else
			local text = tostring(item.Text or "")
			local b = TextService:GetTextSize(text, TS(12), EF.Gotham, V2(400, 20))
			if b.X + 26 > width then
				width = b.X + 26
			end
			local btn = U.MkBtn(ctxFrame, {
				Size = UN(1, 0, 0, 26),
				Trans = 1,
				Text = text,
				Font = EF.Gotham,
				Ts = 12,
				Color = item.Danger and "Error" or "Text",
				Align = ETA.Left,
				Order = i,
			})
			btn.MouseButton1Click:Connect(function()
				ContextMenu.Hide()
				if type(item.Callback) == "function" then
					task.defer(function()
						SafeCall(item.Callback)
					end)
				end
			end)
			totalH += 28
		end
	end

	ctxFrame.Size = UO(width, totalH)
	local s = GetScale()
	local px = ClampEdge(x, width * s, Viewport.X, 8) / s
	local py = ClampEdge(y, totalH * s, Viewport.Y, 8) / s
	ctxFrame.Position = UO(px, py)
	ctxFrame.Visible = true
	ctxCatcher.Visible = true

	ModalManager.Remove(ctxEntry)
	local tk = ctxToken
	ctxEntry = ModalManager.Push(nil, function()
		if ctxToken == tk then
			ContextMenu.Hide()
		end
	end)
end

function ContextMenu.Hide()
	if ctxFrame and ctxFrame.Visible then
		ctxToken += 1
		ctxFrame.Visible = false
		ctxCatcher.Visible = false
	end
	ModalManager.Remove(ctxEntry)
	ctxEntry = nil
end

LibMaid:Give(function()
	ContextMenu.Hide()
end)

local ActiveKeybindListener = nil
local HotElement = nil

function U.TrackHot(self, row)
	if Device.IsTouch then return end
	row.MouseEnter:Connect(function()
		HotElement = self
	end)
	row.MouseLeave:Connect(function()
		if HotElement == self then
			HotElement = nil
		end
	end)
	self.Maid:Give(function()
		if HotElement == self then
			HotElement = nil
		end
	end)
end

local function CreateRow(parent, opts)
	opts = opts or {}
	local desc = opts.Description and tostring(opts.Description) or nil
	local height = opts.Height or (desc and (ROW_H + 18) or ROW_H)
	local rowProps = {
		Size = UN((opts.Width or 1), -3, 0, height),
		BackgroundColor3 = "Element",
		BackgroundTransparency = 0.25,
		Parent = parent,
		Children = { Corner(8), StrokeBind(1, "Stroke", 0.65), Pad(12, 12, 2, 2) },
	}
	if type(opts.Order) == "number" then
		rowProps.LayoutOrder = opts.Order
	end
	local row = Frm(rowProps)

	local rightW = opts.RightWidth or 0
	local leftFrame = Frm({
		BackgroundTransparency = 1,
		Size = UN(1, -rightW, 1, 0),
		Parent = row,
	})
	local title = U.Txt(leftFrame, {
		Size = desc and UN(1, -4, 0, 15) or UN(1, -4, 1, 0),
		Pos = desc and UN(0, 0, 0, 4) or UO(0, 0),
		Font = EF.GothamMedium,
		Ts = 13,
		Align = ETA.Left,
		Trunc = true,
		Text = opts.Name or "",
	})

	local descLabel
	if desc then
		descLabel = U.Txt(leftFrame, {
			Size = UN(1, -4, 0, 13),
			Pos = UN(0, 0, 0, 22),
			Ts = 11,
			Color = "SubText",
			Trans = 0.35,
			Align = ETA.Left,
			Trunc = true,
			Text = desc,
		})
	end

	local right = Frm({
		BackgroundTransparency = 1,
		AnchorPoint = V2(1, 0.5),
		Position = UN(1, 0, 0.5, 0),
		Size = UN(0, rightW, 1, -4),
		Parent = row,
		Children = { U.HL(8, Enum.HorizontalAlignment.Right, EVA.Center) },
	})

	if not opts.NoHover then
		AddHover(row, { StrokeTransparency = 0.65 })
	end
	return row, title, right, leftFrame, descLabel
end

local Elements = {}
local Element = {}
Element.__index = Element

function Element:_init(row, opts, tab)
	opts = opts or {}
	self._opts = opts
	self.Row = row
	self.Maid = Maid.new()
	self.Maid:Link(row)
	self.Tab = tab
	self.Title = tostring(opts.Name or opts.Title or "Element")
	self._searchExtra = tostring(opts.Search or opts.Tooltip or opts.Description or "")
	self.SearchText = (self.Title .. " " .. self._searchExtra):lower()
	self._destroyed = false
	self._extras = {}
	self._manualVisible = true
	self._disabled = false
	self._tooltip = { Text = opts.Tooltip }
	if opts.Tooltip then
		AddTooltip(row, self._tooltip)
	end

	if tab then
		table.insert(tab.Elements, self)
		if tab.CurrentSection then
			table.insert(tab.CurrentSection.Elements, self)
			self.Section = tab.CurrentSection
			if tab.CurrentSection.Collapsed then
				row.Visible = false
			end
		end
	end
	return self
end

function Element:_row(tab, opts, rowOpts)
	local row, title, right, left, descLabel = CreateRow(tab.Content, rowOpts)
	self:_init(row, opts, tab)
	self.TitleLabel = title
	self.LeftFrame = left
	self.RightContainer = right
	self.DescLabel = descLabel
	self._baseRightW = rowOpts.RightWidth or 0
	self._width = rowOpts.RightWidth or 0
	self.Callback = opts.Callback or function() end
	return row
end

function Element:_bindSave(saveKey, fn)
	if not saveKey then return end
	local list = SaveReloadRegistry[saveKey]
	if not list then
		list = {}
		SaveReloadRegistry[saveKey] = list
	end
	table.insert(list, fn)
	self.Maid:Give(function()
		RemoveValue(list, fn)
	end)
end

function Element:_saveAs(saveKey, t)
	self:_bindSave(saveKey, function(v)
		if type(v) == t then
			self:Set(v, true)
		end
	end)
end

function Element:_deferInit(cond, value)
	if not cond then return end
	task.defer(function()
		if not self._destroyed then
			RunCallback(self.Callback, self.Title, value)
		end
	end)
end

function Element:SetTitle(text)
	if self._destroyed then return end
	self.Title = tostring(text or "")
	self.SearchText = (self.Title .. " " .. self._searchExtra):lower()
	if self.TitleLabel and self.TitleLabel.Parent then
		self.TitleLabel.Text = self.Title
	end
end

function Element:SetTooltip(text)
	if self._destroyed then return end
	self._tooltip.Text = tostring(text or "")
end

function Element:Visible(state)
	if self._destroyed then return end
	if state == nil then
		self.Row.Visible = not self.Row.Visible
	else
		self.Row.Visible = state and true or false
	end
	self._manualVisible = self.Row.Visible
	if self.Section and self.Section.Collapsed then
		self.Row.Visible = false
	end
end

function Element:SetDisabled(state)
	if self._destroyed then return end
	local v = state == true
	if v == self._disabled then return end
	self._disabled = v
	if self.Row then
		self.Row:SetAttribute("Disabled", v)
	end
	if self.TitleLabel then
		Tween(self.TitleLabel, "Fast", { TextTransparency = v and 0.55 or 0 })
	end
	local st = self.Row and self.Row:FindFirstChildOfClass("UIStroke")
	if st then
		Tween(st, "Fast", { Transparency = v and 0.9 or 0.65 })
	end
end

function Element:IsDisabled()
	return self._disabled == true
end

function Element:RecalcWidth()
	if not self.RightContainer then return end
	local w = (self._baseRightW or 0) + (self._extraW or 0)
	self.RightContainer.Size = UN(0, w, 1, -4)
	if self.LeftFrame then
		self.LeftFrame.Size = UN(1, -w, 1, 0)
	end
end

function Element:Extra(className, opts)
	if self._destroyed then return nil end
	local elClass = Elements[className]
	if not elClass then return nil end
	opts = opts or {}
	local el = elClass.new(self.Tab, opts)

	local row = el.Row
	local pad = row:FindFirstChildOfClass("UIPadding")
	if pad then
		pad:Destroy()
	end
	row.BackgroundTransparency = 1
	row:SetAttribute("NoHoverFX", true)
	local rowStroke = row:FindFirstChildOfClass("UIStroke")
	if rowStroke then
		rowStroke.Transparency = 1
	end
	if el.LeftFrame then
		el.LeftFrame.Size = UN(0, 0, 1, 0)
	end
	if el.TitleLabel and el.TitleLabel:IsA("TextLabel") then
		el.TitleLabel.Visible = false
	end
	if el.RightContainer then
		el.RightContainer.AnchorPoint = V2(0, 0.5)
		el.RightContainer.Position = UN(0, 0, 0.5, 0)
		el.RightContainer.Size = UN(1, 0, 1, 0)
	end

	row.Parent = self.RightContainer
	row.LayoutOrder = (#self._extras + 1) + 10
	row.Size = UN(0, el._width or 0, 0, el._extraH or ROW_H)

	RemoveValue(self.Tab.Elements, el)
	if el.Section then
		RemoveValue(el.Section.Elements, el)
		el.Section = nil
	end

	self.Tab.Window:_introElement(el)

	table.insert(self._extras, el)
	self._extraW = (self._extraW or 0) + (el._width or 0)
	self:RecalcWidth()

	el.Maid:Give(function()
		if self._destroyed then return end
		RemoveValue(self._extras, el)
		self._extraW = math.max(0, (self._extraW or 0) - (el._width or 0))
		self:RecalcWidth()
	end)

	return el
end

function Element:Toggle(opts)
	if self._destroyed then return nil end
	if self.AttachedToggle then return self.AttachedToggle end
	opts = opts or {}
	local tg = self:Extra("Toggle", opts)
	if not tg then return nil end
	self.AttachedToggle = tg
	self.Enabled = tg.Changed
	function self:IsEnabled()
		return tg:Get() == true
	end
	function self:SetEnabled(v, silent)
		tg:Set(v == true, silent)
	end
	return tg
end

function Element:_contextItems()
	local items = {}
	if self.CopyValue then
		table.insert(items, {
			Text = "Copy value",
			Callback = function()
				local v = self:CopyValue()
				if v ~= nil then
					CopyToClipboard(v)
				end
			end,
		})
	end
	if self.Reset then
		table.insert(items, {
			Text = "Reset to default",
			Callback = function()
				self:Reset()
			end,
		})
	end
	table.insert(items, {
		Text = self._disabled and "Enable" or "Disable",
		Callback = function()
			self:SetDisabled(not self._disabled)
		end,
	})
	return items
end

local function HookContextMenu(el, overlay)
	overlay.MouseButton2Click:Connect(function()
		if el._destroyed then return end
		local items = el:_contextItems()
		if #items == 0 then return end
		local m = UIS:GetMouseLocation()
		ContextMenu.Show(items, m.X, m.Y)
	end)
end

function Element:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if HotElement == self then
		HotElement = nil
	end
	local tab = self.Tab
	if tab then
		RemoveValue(tab.Elements, self)
		if self.IsSection then
			RemoveValue(tab.Sections, self)
			if tab.CurrentSection == self then
				tab.CurrentSection = nil
			end
			for _, el in ipairs(self.Elements) do
				if not el._destroyed then
					el.Section = nil
				end
			end
		end
		if self.Section then
			RemoveValue(self.Section.Elements, self)
		end
	end
	for _, ex in ipairs(self._extras) do
		if not ex._destroyed then
			ex:Destroy()
		end
	end
	if self.Changed then
		self.Changed:Destroy()
	end
	if self.Maid then
		self.Maid:Destroy()
	end
	if self.Row then
		self.Row:Destroy()
	end
	self.Row, self.Maid, self.Tab, self.Section = nil, nil, nil, nil
end

local function MakeElementClass()
	local class = {}
	class.__index = class
	setmetatable(class, { __index = Element })
	return class
end

local function ENew(cls, tab, opts, rowOpts)
	opts = opts or {}
	rowOpts.Width = rowOpts.Width or opts.Width
	rowOpts.Description = rowOpts.Description or opts.Description
	local self = setmetatable({}, cls)
	self:_row(tab, opts, rowOpts)
	return self
end

local function INew(cls, row, opts, tab)
	local self = setmetatable({}, cls)
	self:_init(row, opts or {}, tab)
	return self
end

Elements.Label = MakeElementClass()

function Elements.Label.new(tab, opts)
	opts = opts or {}
	local row = Frm({
		BackgroundTransparency = 1,
		Size = UN((opts.Width or 1), -3, 0, 20),
		Parent = tab.Content,
		Children = { Pad(0, 0, 0, 0) },
	})
	local label = U.Txt(row, {
		Size = UN(1, 0, 1, 0),
		Font = EF.GothamMedium,
		Ts = 13,
		Color = "SubText",
		Align = ETA.Left,
		Trunc = true,
		Text = opts.Text or opts.Name or "Label",
	})
	local self = INew(Elements.Label, row, { Name = opts.Text or opts.Name, Width = opts.Width }, tab)
	self.TextLabel = label
	return self
end

function Elements.Label:Set(text)
	if self._destroyed then return end
	self.TextLabel.Text = tostring(text or "")
	self:SetTitle(self.TextLabel.Text)
end

Elements.Paragraph = MakeElementClass()

function Elements.Paragraph.new(tab, opts)
	opts = opts or {}
	local row = Frm({
		BackgroundColor3 = "Element",
		BackgroundTransparency = 0.25,
		Size = UN((opts.Width or 1), -3, 0, 0),
		AutomaticSize = AS.Y,
		Parent = tab.Content,
		Children = {
			Corner(8), StrokeBind(1, "Stroke", 0.65), Pad(12, 12, 8, 8), List(6),
		},
	})
	local title = U.Txt(row, {
		Size = UN(1, 0, 0, 16),
		Font = EF.GothamBold,
		Ts = 13,
		Align = ETA.Left,
		Trunc = true,
		Text = opts.Title or opts.Name or "",
	})
	local body = U.Txt(row, {
		Size = UN(1, 0, 0, 0),
		Auto = AS.Y,
		Ts = 12,
		Color = "SubText",
		Wrap = true,
		Align = ETA.Left,
		Text = tostring(opts.Text or ""),
	})
	local self = INew(Elements.Paragraph, row, {
		Name = opts.Title or opts.Name,
		Tooltip = opts.Tooltip,
		Width = opts.Width,
	}, tab)
	self.TitleLabel = title
	self.BodyLabel = body
	return self
end

function Elements.Paragraph:Set(text)
	if self._destroyed then return end
	self.BodyLabel.Text = tostring(text or "")
end

Elements.Divider = MakeElementClass()

function Elements.Divider.new(tab, opts)
	opts = opts or {}
	local row = Frm({
		BackgroundTransparency = 1,
		Size = UN((opts.Width or 1), -3, 0, 13),
		Parent = tab.Content,
		Children = { Pad(0, 0, 0, 0) },
	})
	Frm({
		AnchorPoint = V2(0.5, 0.5),
		Position = US(0.5, 0.5),
		Size = UN(1, 0, 0, 1),
		BackgroundColor3 = "Stroke",
		BackgroundTransparency = 0.35,
		Parent = row,
	})
	if opts.Text then
		U.Txt(row, {
			Ap = V2(0.5, 0.5),
			Pos = US(0.5, 0.5),
			Auto = AS.X,
			Bg = 0,
			BgC = "Background",
			Ts = 11,
			Color = "SubText",
			Text = " " .. tostring(opts.Text) .. " ",
		})
	end
	return INew(Elements.Divider, row, { Name = opts.Text, Width = opts.Width }, tab)
end

Elements.Section = MakeElementClass()

function Elements.Section.new(tab, opts)
	opts = opts or {}
	local row = Frm({
		BackgroundTransparency = 1,
		Size = UN((opts.Width or 1), -3, 0, 26),
		Parent = tab.Content,
		Children = { Pad(0, 0, 0, 0) },
	})

	local hit = U.Overlay(row)

	Frm({
		AnchorPoint = V2(0, 0.5),
		Position = UN(0, 2, 0.5, 0),
		Size = UO(3, 13),
		BackgroundColor3 = "Accent",
		Parent = row,
		Children = { Corner(2) },
	})

	local chevron = Icon(row, "Chevron", "SubText")
	chevron.AnchorPoint = V2(1, 0.5)
	chevron.Position = UN(1, -2, 0.5, 0)
	chevron.Size = UO(10, 10)

	local label = U.Txt(row, {
		Pos = UO(12, 0),
		Size = UN(1, -24, 1, 0),
		Font = EF.GothamBold,
		Ts = 12,
		Color = "SubText",
		Align = ETA.Left,
		Trunc = true,
		Text = string.upper(tostring(opts.Name or "Section")),
	})

	local self = INew(Elements.Section, row, { Name = opts.Name, Width = opts.Width }, nil)
	self.Header = row
	self.TitleLabel = label
	self.Chevron = chevron

	local startCollapsed = opts.Collapsed
	if startCollapsed == nil then
		if opts.Open ~= nil then
			startCollapsed = not (opts.Open == true)
		elseif opts.Expanded ~= nil then
			startCollapsed = not (opts.Expanded == true)
		end
	end
	self.Collapsed = startCollapsed == true
	self.Elements = {}

	if self.Collapsed then
		chevron.Rotation = -90
	end

	self.Maid:Give(hit.MouseButton1Click:Connect(function()
		self:SetCollapsed(not self.Collapsed)
	end))

	return self
end

function Elements.Section:SetCollapsed(collapsed)
	if self.Collapsed == collapsed then return end
	self.Collapsed = collapsed
	if self.Chevron then
		Tween(self.Chevron, "PopSoft", { Rotation = collapsed and -90 or 0 })
	end
	for _, el in ipairs(self.Elements) do
		if not el._destroyed then
			if collapsed then
				el.Row.Visible = false
			else
				el.Row.Visible = el._manualVisible ~= false
			end
		end
	end
end

Elements.Button = MakeElementClass()

function Elements.Button.new(tab, opts)
	opts = opts or {}
	local self = ENew(Elements.Button, tab, opts, {
		Name = opts.Name or "Button",
		RightWidth = opts.Icon ~= nil and 26 or 0,
	})
	self._width = 0
	self._busy = false

	local title, row = self.TitleLabel, self.Row
	local overlay = U.Overlay(row, 0)

	local spinner, spinTween
	local function setSpinner(on)
		if on then
			if not spinner then
				spinner = Frm({
					AnchorPoint = V2(0.5, 0.5),
					Position = US(0.5, 0.5),
					Size = UO(14, 14),
					BackgroundTransparency = 1,
					ZIndex = 5,
					Parent = row,
					Children = { Corner(PILL) },
				})
				Bind(Create("UIStroke", { Thickness = 2, Parent = spinner }), "Color", "Accent")
			end
			spinner.Visible = true
			spinTween = Tween(spinner, TweenInfo.new(0.7, E.Linear, ED.In, -1), { Rotation = 360 })
			if title then
				Tween(title, "Fast", { TextTransparency = 0.55 })
			end
		else
			if spinner then
				spinner.Visible = false
			end
			if spinTween then
				pcall(function()
					spinTween:Cancel()
				end)
				spinTween = nil
			end
			if title and not self._disabled then
				Tween(title, "Fast", { TextTransparency = 0 })
			end
		end
	end

	function self:SetBusy(busy)
		if self._destroyed or self._busy == (busy == true) then return end
		self._busy = busy == true
		setSpinner(self._busy)
	end

	local function fire()
		if self._busy or self._disabled then return end
		Tap(overlay)
		if opts.Confirm then
			Kailex:Confirm({ Title = "Confirm", Text = tostring(opts.Confirm) }, function()
				RunCallback(self.Callback, self.Title)
			end)
			return
		end
		RunCallback(self.Callback, self.Title)
	end

	Click(self.Maid, overlay, fire)
	HookContextMenu(self, overlay)

	if opts.Icon and self.RightContainer then
		local iconBtn = Hit({ Size = UO(22, 22), LayoutOrder = 1, Parent = self.RightContainer })
		local img = Create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = V2(0.5, 0.5),
			Position = US(0.5, 0.5),
			Size = UO(16, 16),
			Image = tonumber(opts.Icon) and ("rbxassetid://" .. opts.Icon) or opts.Icon,
			ImageColor3 = "SubText",
			Parent = iconBtn,
		})
		self.Maid:Give(iconBtn.MouseEnter:Connect(function()
			Tween(img, "Fast", { ImageColor3 = CurrentTheme.Text })
		end))
		self.Maid:Give(iconBtn.MouseLeave:Connect(function()
			Tween(img, "Fast", { ImageColor3 = CurrentTheme.SubText })
		end))
		Click(self.Maid, iconBtn, fire)
	end

	return self
end

function Elements.Button:SetCallback(cb)
	self.Callback = cb or function() end
end

function Elements.Button:CopyValue()
	return self.Title
end

Elements.Toggle = MakeElementClass()

function Elements.Toggle.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local hadSaved = SaveManager:Get(saveKey, nil) ~= nil
	local default = SaveManager:Get(saveKey, opts.Default or opts.defaultVal or false) == true

	local switchW = Device.IsTouch and 50 or 42
	local switchH = Device.IsTouch and 26 or 22
	local usePin = opts.Pin == true
	local rightW = switchW + (usePin and 30 or 0)

	local self = ENew(Elements.Toggle, tab, opts, {
		Name = opts.Name or "Toggle",
		RightWidth = rightW,
	})
	self._extraH = switchH
	self.State = default
	self.Changed = Signal.new()
	local right, row = self.RightContainer, self.Row

	local switch = Frm({
		Size = UO(switchW, switchH),
		BackgroundColor3 = "SurfaceLight",
		LayoutOrder = 20,
		Parent = right,
		Children = { Corner(PILL) },
	})
	local stroke = Create("UIStroke", {
		Thickness = 1, Transparency = 0.5, ApplyStrokeMode = SB, Parent = switch,
	})
	local knob = Frm({
		AnchorPoint = V2(0, 0.5),
		Size = UO(16, 16),
		BackgroundColor3 = "Knob",
		Parent = switch,
		Children = {
			Corner(PILL),
			Create("UIStroke", { Thickness = 1, Color = "KnobStroke", Transparency = 0.5, ApplyStrokeMode = SB }),
		},
	})

	local function applyVisuals(animated)
		local on, dis = self.State, self._disabled
		local knobX = on and (switchW - 19) or 3
		if animated then
			Tween(switch, "Reveal", {
				BackgroundColor3 = on and CurrentTheme.Accent or CurrentTheme.SurfaceLight,
			})
			Tween(stroke, "Reveal", {
				Color = on and CurrentTheme.Accent or CurrentTheme.Stroke,
				Transparency = (on and not dis) and 0 or 0.5,
			})
			Tween(knob, "Fast", {
				Size = UO(20, 12),
				Position = UN(0, on and (switchW - 23) or 1, 0.5, 0),
			}, function()
				Tween(knob, "Pop", {
					Size = UO(16, 16),
					Position = UN(0, knobX, 0.5, 0),
				})
			end)
		else
			knob.Size = UO(16, 16)
			knob.Position = UN(0, knobX, 0.5, 0)
			switch.BackgroundColor3 = on and CurrentTheme.Accent or CurrentTheme.SurfaceLight
			stroke.Color = on and CurrentTheme.Accent or CurrentTheme.Stroke
			stroke.Transparency = (on and not dis) and 0 or 0.5
		end
	end

	self._applyVisuals = applyVisuals
	self.Maid:Give(Kailex.ThemeChanged:Connect(function()
		applyVisuals(false)
	end))
	applyVisuals(false)

	local overlay = U.Overlay(row, 0)
	Click(self.Maid, overlay, function()
		if self._disabled then return end
		if overlay:GetAttribute("Dragging") then return end
		ApplyRipple(overlay)
		self:Set(not self.State)
	end)
	HookContextMenu(self, overlay)

	if usePin then
		local pinBtn = Hit({ Size = UO(22, 22), LayoutOrder = 10, Parent = right })
		Icon(pinBtn, "Pin", "SubText", 14)
		Click(self.Maid, pinBtn, function()
			Tap(pinBtn, "Click", 0.5)
			QuickWidgets.Toggle(self)
		end)
	end

	self.Maid:Give(function()
		QuickWidgets.Destroy(self)
	end)

	function self:Set(state, silent)
		state = state == true
		if state == self.State then return end
		self.State = state
		applyVisuals(true)
		SaveValue(saveKey, state)
		self.Changed:Fire(state)
		if not silent then
			RunCallback(self.Callback, self.Title, state)
		end
	end

	function self:Get() return self.State end
	function self:CopyValue() return tostring(self.State) end

	self:_saveAs(saveKey, "boolean")
	self:_deferInit(opts.Default ~= nil or hadSaved, self.State)
	return self
end

function Elements.Toggle:SetDisabled(state)
	Element.SetDisabled(self, state)
	if self._applyVisuals then
		self._applyVisuals(false)
	end
end

Elements.Slider = MakeElementClass()

function Elements.Slider.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local min = tonumber(opts.Min or opts.MinVal or 0) or 0
	local max = tonumber(opts.Max or opts.MaxVal or 100) or 100
	if max <= min then
		max = min + 1
	end
	local increment = tonumber(opts.Increment)
	local default = tonumber(opts.Default or opts.Value or min) or min
	local value = clamp(U.LoadNum(saveKey, default), min, max)

	local prefix = opts.Prefix and tostring(opts.Prefix) or nil
	local suffix = opts.Suffix and tostring(opts.Suffix) or nil
	local onRelease = opts.FireOnRelease == true

	local baseRowH = Device.IsTouch and 62 or 56
	local fullH = baseRowH + (opts.Description and 16 or 0)
	local self = ENew(Elements.Slider, tab, opts, {
		Name = opts.Name or "Slider",
		Height = fullH,
		RightWidth = 0,
	})

	local row, left, title = self.Row, self.LeftFrame, self.TitleLabel
	title.Size = UN(1, -84, 0, 15)
	title.Position = UN(0, 0, 0, 4)

	local box = U.TxB(left, {
		Ap = V2(1, 0),
		Pos = UN(1, 0, 0, 3),
		Size = UO(52, 18),
		Trans = 1,
		Font = EF.GothamBold,
		Ts = 12,
		Align = ETA.Right,
	})

	local track = Frm({
		AnchorPoint = V2(0, 1),
		Position = UN(0, 0, 1, -9),
		Size = UN(1, 0, 0, 6),
		BackgroundColor3 = "SurfaceLight",
		Parent = left,
		Children = { Corner(PILL), StrokeBind(1, "Stroke", 0.7) },
	})
	local fill = Frm({
		Size = US(0, 1),
		BackgroundColor3 = "Accent",
		Parent = track,
		Children = { Corner(PILL) },
	})
	local knob = Frm({
		AnchorPoint = V2(0.5, 0.5),
		Size = UO(14, 14),
		Position = US(0, 0.5),
		BackgroundColor3 = "Knob",
		ZIndex = 2,
		Parent = track,
		Children = {
			Corner(PILL),
			Create("UIStroke", { Thickness = 2, Color = "Accent", Transparency = 0.35, ApplyStrokeMode = SB }),
		},
	})
	local knobStroke = knob:FindFirstChildOfClass("UIStroke")

	local bubble = U.Txt(left, {
		Ap = V2(0.5, 1),
		Pos = UN(0.5, 0, 0, fullH - 26),
		Size = UO(44, 16),
		Bg = 0,
		BgC = "SurfaceLight",
		Visible = false,
		Z = 20,
		Font = EF.GothamBold,
		Ts = 11,
		Text = "",
		Kids = { Corner(6), StrokeBind(1, "Stroke", 0.3) },
	})
	local bubbleScale = UISC(bubble)

	local step = (increment and increment > 0) and increment
		or ((min % 1 == 0 and max % 1 == 0) and 1 or 0.01)
	local decimals = DecimalsOf(step)
	local pow = 10 ^ decimals

	local function RoundStep(v)
		return floor(v * pow + 0.5) / pow
	end
	local defaultValue = clamp(RoundStep(floor((default - min) / step + 0.5) * step + min), min, max)

	local function fmt(val)
		local s
		if decimals <= 0 then
			s = tostring(floor(val + 0.5))
		else
			s = string.format("%." .. decimals .. "f", val)
		end
		return (prefix or "") .. s .. (suffix or "")
	end

	local updateResetVisibility

	local function apply(newValue, instant)
		value = clamp(newValue, min, max)
		local frac = (value - min) / (max - min)
		if instant then
			fill.Size = US(frac, 1)
		else
			Tween(fill, "Fast", { Size = US(frac, 1) })
		end
		knob.Position = UN(frac, 0, 0.5, 0)
		local trackW = track.AbsoluteSize.X
		local bx = frac
		if trackW > 48 then
			bx = clamp(frac * trackW, 24, trackW - 24) / trackW
		end
		bubble.Position = UN(bx, 0, 0, fullH - 26)
		bubble.Text = fmt(value)
		if not box:IsFocused() then
			box.Text = string.format("%." .. decimals .. "f", value)
		end
		if updateResetVisibility then
			updateResetVisibility()
		end
	end

	local dragging = false
	local function snap(f)
		local v = min + (max - min) * f
		if step > 0 then
			v = floor((v - min) / step + 0.5) * step + min
		end
		return clamp(RoundStep(v), min, max)
	end

	local hit = Hit({
		AnchorPoint = V2(0, 1),
		Position = UN(0, 0, 1, -4),
		Size = UN(1, 0, 0, Device.IsTouch and 34 or 24),
		ZIndex = 1,
		Parent = left,
	})

	local resetBtn = Hit({
		AnchorPoint = V2(1, 0),
		Position = UN(1, -72, 0, 4),
		Size = UO(16, 16),
		Visible = false,
		Parent = left,
	})
	Icon(resetBtn, "Reset", "SubText", 13)
	AddTooltip(resetBtn, { Text = "Reset to default (or right-click the slider)" })
	local resetScale = UISC(resetBtn)
	local resetShown = false

	updateResetVisibility = function()
		local show = math.abs(value - defaultValue) > 1e-4
		if show == resetShown then return end
		resetShown = show
		if show then
			resetBtn.Visible = true
			resetScale.Scale = 0.4
			Tween(resetScale, "PopSoft", { Scale = 1 })
		else
			Tween(resetScale, "Vanish", { Scale = 0.4 }, function()
				if not resetShown then
					resetBtn.Visible = false
				end
			end)
		end
	end

	local function resetToDefault()
		if self._destroyed then return end
		if math.abs(value - defaultValue) > 1e-6 then
			Tap(resetBtn, "ToggleOn", 0.5)
			self:Set(defaultValue)
			bubble.Visible = true
			bubble.Text = fmt(value)
			bubbleScale.Scale = 0.7
			Tween(bubbleScale, "PopSoft", { Scale = 1 })
			task.delay(0.55, function()
				if not dragging and not self._destroyed then
					Tween(bubbleScale, "Vanish", { Scale = 0.7 }, function()
						if not dragging and not self._destroyed then
							bubble.Visible = false
						end
					end)
				end
			end)
		end
	end
	Click(self.Maid, resetBtn, resetToDefault)
	self.Maid:Give(hit.MouseButton2Click:Connect(resetToDefault))
	function self:Reset()
		resetToDefault()
	end

	TrackInput(hit, {
		Guard = function()
			return not dragging and not self._disabled
		end,
		Active = track,
		Start = function()
			dragging = true
			PlaySound("Slider")
			Tween(knob, "Spring", { Size = UO(18, 18) })
			Tween(knobStroke, "Fast", { Transparency = 0 })
			bubble.Visible = true
			bubbleScale.Scale = 0.7
			Tween(bubbleScale, "PopSoft", { Scale = 1 })
		end,
		MoveNow = true,
		Move = function(pos)
			local ap, as = track.AbsolutePosition, track.AbsoluteSize
			if as.X <= 1 then return end
			local frac = clamp((pos.X - ap.X) / as.X, 0, 1)
			local v = snap(frac)
			if v ~= value then
				apply(v)
				if not onRelease then
					RunCallback(self.Callback, self.Title, value)
				end
			end
		end,
		End = function()
			dragging = false
			Tween(knob, "Spring", { Size = UO(14, 14) })
			Tween(knobStroke, "Fast", { Transparency = 0.35 })
			Tween(bubbleScale, "Vanish", { Scale = 0.7 }, function()
				if not dragging and not self._destroyed then
					bubble.Visible = false
				end
			end)
			SaveValue(saveKey, value)
			if onRelease then
				RunCallback(self.Callback, self.Title, value)
			end
		end,
	})

	track.MouseEnter:Connect(function()
		if not dragging then
			Tween(knob, "Fast", { Size = UO(16, 16) })
		end
	end)
	track.MouseLeave:Connect(function()
		if not dragging then
			Tween(knob, "Fast", { Size = UO(14, 14) })
		end
	end)

	self.Maid:Give(box.FocusLost:Connect(function()
		local t = tostring(box.Text or "")
		if prefix and t:sub(1, #prefix) == prefix then
			t = t:sub(#prefix + 1)
		end
		if suffix and #suffix > 0 and t:sub(-#suffix) == suffix then
			t = t:sub(1, -#suffix - 1)
		end
		local num = tonumber(t:gsub(",", "."):gsub("%s", ""))
		if num then
			self:Set(num)
		else
			box.Text = string.format("%." .. decimals .. "f", value)
		end
	end))

	function self:Set(newValue, silent)
		if self._destroyed then return end
		local nv = tonumber(newValue)
		if nv == nil then return end
		nv = clamp(RoundStep(floor((nv - min) / step + 0.5) * step + min), min, max)
		if decimals <= 0 then
			nv = floor(nv + 0.5)
		end
		apply(nv)
		SaveValue(saveKey, value)
		if not silent then
			RunCallback(self.Callback, self.Title, value)
		end
	end

	function self:Get() return value end
	function self:CopyValue()
		return string.format("%." .. math.max(decimals, 0) .. "f", value)
	end

	function self:HandleArrow(dir)
		if self._destroyed or self._disabled then return end
		local fine = UIS:IsKeyDown(EKC.LeftShift) or UIS:IsKeyDown(EKC.RightShift)
		self:Set(value + step * (fine and 0.2 or 1) * dir)
	end

	U.TrackHot(self, row)
	self:_saveAs(saveKey, "number")
	apply(value, true)
	self:_deferInit(opts.Default ~= nil or SaveManager:Get(saveKey, nil) ~= nil, value)
	return self
end

Elements.Keybind = MakeElementClass()

function Elements.Keybind.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local self = ENew(Elements.Keybind, tab, opts, {
		Name = opts.Name or "Keybind",
		RightWidth = 96,
	})

	local binding = ToBinding(SaveManager:Get(saveKey, nil)) or ToBinding(opts.Default)
	local listening = false
	local suppressClear = false
	local listenToken = 0

	local kRec = { el = self }
	table.insert(KeybindRegistry, kRec)
	self.Maid:Give(function()
		RemoveValue(KeybindRegistry, kRec)
		if ActiveKeybindListener == self then
			ActiveKeybindListener = nil
		end
	end)

	local bindBtn = U.MkBtn(self.RightContainer, {
		Size = UN(1, 0, 1, 0),
		BgC = "SurfaceLight",
		Text = "None",
		Ts = 11,
		Hover = false,
	})
	StrokeBind(1, "Stroke", 0.5, bindBtn)

	local function refresh()
		if listening then
			bindBtn.BackgroundColor3 = CurrentTheme.Accent
			bindBtn.TextColor3 = CurrentTheme.OnAccent
			bindBtn.Text = "Press a key..."
		else
			bindBtn.BackgroundColor3 = CurrentTheme.SurfaceLight
			bindBtn.TextColor3 = CurrentTheme.Text
			bindBtn.Text = binding and binding.Name or "None"
		end
	end

	local function setListening(on)
		if listening == on then return end
		listening = on
		if on then
			if ActiveKeybindListener and ActiveKeybindListener ~= self
				and not ActiveKeybindListener._destroyed
				and ActiveKeybindListener._cancelListen then
				ActiveKeybindListener._cancelListen()
			end
			ActiveKeybindListener = self
		elseif ActiveKeybindListener == self then
			ActiveKeybindListener = nil
		end
		refresh()
	end
	self._cancelListen = function()
		setListening(false)
	end

	local function setBinding(b)
		binding = b
		SaveValue(saveKey, b and (b.Kind .. ":" .. b.Name) or "__none")
		if b then
			NotifyKeybindConflict(self, b)
		end
		refresh()
	end

	self._getBinding = function()
		return binding
	end

	self._handleInput = function(input, gp)
		if self._destroyed then return end
		if listening then
			if input.KeyCode ~= EKC.Unknown then
				listenToken += 1
				setListening(false)
				if input.KeyCode == EKC.Escape then
					return
				end
				setBinding({
					Kind = "Key",
					Code = input.KeyCode,
					Name = input.KeyCode.Name,
				})
				PlaySound("Click")
			elseif opts.MouseButtons
				and (input.UserInputType == EUT.MouseButton2
					or input.UserInputType == EUT.MouseButton3) then
				listenToken += 1
				setListening(false)
				suppressClear = true
				task.defer(function()
					suppressClear = false
				end)
				setBinding({
					Kind = "Mouse",
					Code = input.UserInputType,
					Name = input.UserInputType.Name,
				})
				PlaySound("Click")
			end
			return
		end
		if ActiveKeybindListener ~= nil then return end
		if gp then return end
		if self._disabled then return end
		if UIS:GetFocusedTextBox() ~= nil then return end
		if not binding then return end
		if binding.Kind == "Key" and input.KeyCode == binding.Code then
			RunCallback(self.Callback, self.Title, binding.Code)
		elseif binding.Kind == "Mouse" and input.UserInputType == binding.Code
			and input.UserInputType ~= EUT.MouseButton1 then
			RunCallback(self.Callback, self.Title, binding.Code)
		end
	end

	local hook = AddInputHook(function()
		return not self._destroyed
	end, self._handleInput)
	self.Maid:Give(function()
		RemoveInputHook(hook)
		if listening then
			listening = false
			if ActiveKeybindListener == self then
				ActiveKeybindListener = nil
			end
		end
	end)

	Click(self.Maid, bindBtn, function()
		if self._disabled then return end
		Tap(bindBtn, "Click", 0.6)
		if listening then
			listenToken += 1
			setListening(false)
		else
			setListening(true)
			listenToken += 1
			local myToken = listenToken
			task.delay(6, function()
				if listening and listenToken == myToken then
					setListening(false)
				end
			end)
		end
	end)

	self.Maid:Give(bindBtn.MouseButton2Click:Connect(function()
		if suppressClear or listening then return end
		setBinding(nil)
	end))

	function self:Set(v, silent)
		local b = ToBinding(v)
		if not b then return end
		setBinding(b)
		if not silent then
			RunCallback(self.Callback, self.Title, b.Code)
		end
	end

	function self:Get()
		return binding and binding.Code or nil
	end

	function self:GetName()
		return binding and binding.Name or "None"
	end

	function self:CopyValue()
		return self:GetName()
	end

	self:_bindSave(saveKey, function(v)
		local b = ToBinding(v)
		if b then
			setBinding(b)
		end
	end)
	self.Maid:Give(Kailex.ThemeChanged:Connect(refresh))
	refresh()

	return self
end

local DROP_VIRTUALIZE = 60
local DROP_SEARCH_AT = 12

Elements.Dropdown = MakeElementClass()

function Elements.Dropdown.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local multi = opts.Multi == true

	local function normalize(list)
		local out = {}
		for _, v in ipairs(list or {}) do
			if type(v) == "table" and v.Text ~= nil then
				local val = (v.Value ~= nil) and v.Value or v.Text
				out[#out + 1] = { Text = tostring(v.Text), Value = val, Key = tostring(val) }
			else
				out[#out + 1] = { Text = tostring(v), Value = v, Key = tostring(v) }
			end
		end
		return out
	end
	local options = normalize(opts.Options or opts.Items)

	local function findOpt(key)
		for _, o in ipairs(options) do
			if o.Key == key then
				return o
			end
		end
		return nil
	end

	local selSet = {}
	do
		local defaults
		if multi then
			local sv = SaveManager:Get(saveKey, nil)
			if sv ~= nil and type(sv) == "table" then
				defaults = sv
			elseif type(opts.Defaults) == "table" then
				defaults = opts.Defaults
			end
		else
			local d
			local sv = SaveManager:Get(saveKey, nil)
			if sv ~= nil and type(sv) ~= "table" then
				d = sv
			elseif opts.Default ~= nil then
				d = opts.Default
			end
			if d ~= nil then
				defaults = { d }
			end
		end
		if defaults then
			for _, d in ipairs(defaults) do
				local o = findOpt(tostring(d))
				if o then
					selSet[o.Key] = true
				end
			end
		end
	end

	local function selectedOpts()
		local out = {}
		for _, o in ipairs(options) do
			if selSet[o.Key] then
				out[#out + 1] = o
			end
		end
		return out
	end

	local function valuesOf(list)
		local out = {}
		for _, o in ipairs(list) do
			out[#out + 1] = o.Value
		end
		return out
	end

	local function measureWidth()
		local w = 96
		local cap = math.min(#options, 400)
		for i = 1, cap do
			local text = options[i].Text
			if #text > 64 then
				text = text:sub(1, 64)
			end
			local b = TextService:GetTextSize(text, TS(12), EF.Gotham, V2(2000, 20))
			if b.X > w then
				w = b.X
			end
		end
		return clamp(w + 30, 122, 280)
	end

	local baseH = ROW_H + (opts.Description and 16 or 0)
	local rightW = measureWidth()
	local self = ENew(Elements.Dropdown, tab, opts, {
		Name = opts.Name or "Dropdown",
		RightWidth = rightW,
		Height = baseH,
	})
	local right, row = self.RightContainer, self.Row

	local valueLabel = U.Txt(right, {
		Size = UN(0, rightW - 26, 1, 0),
		Ts = 12,
		Color = "SubText",
		Align = ETA.Right,
		Trunc = true,
		Order = 1,
	})
	local chevHolder = Icon(right, "Chevron", "SubText")
	chevHolder.LayoutOrder = 2

	local list = Grp({
		Size = UO(120, 0),
		BackgroundColor3 = "SurfaceLight",
		BackgroundTransparency = 0.05,
		Visible = false,
		GroupTransparency = 1,
		ZIndex = 100,
		Parent = LayerOverlay,
		Children = { Corner(10), StrokeBind(1, "Stroke", 0.2) },
	})

	local header = Frm({
		BackgroundTransparency = 1,
		Size = UN(1, 0, 0, 0),
		Parent = list,
		Children = { U.HL(4, Enum.HorizontalAlignment.Left) },
	})

	local listCanvas = Scr({
		Size = UN(1, 0, 1, 0),
		Parent = list,
	})
	Bind(listCanvas, "ScrollBarImageColor3", "Stroke")

	local catcher = U.Overlay(LayerOverlay, 99, false)

	local searchShown = (#options > DROP_SEARCH_AT) or opts.Searchable == true
	local searchBox
	if searchShown then
		searchBox = U.TxB(header, {
			Size = UN(1, multi and -60 or -8, 1, -6),
			BgC = "Surface",
			Ts = 11,
			Ph = "Search...",
			Align = ETA.Left,
			Order = 1,
			Kids = { Corner(6), Pad(6, 6), StrokeBind(1, "Stroke", 0.5) },
		})
	end

	local allBtn, noneBtn
	if multi then
		local function mkMini(text, order)
			return U.MkBtn(header, {
				Size = UO(26, 20),
				Text = text,
				Ts = 9,
				Color = "SubText",
				Order = order,
				R = 5,
			})
		end
		allBtn = mkMini("All", 2)
		noneBtn = mkMini("None", 3)
	end

	local headerH = (searchShown or multi) and 28 or 0

	local emptyLabel = U.Txt(listCanvas, {
		Size = UN(1, 0, 0, 20),
		Ts = 11,
		Color = "SubText",
		Text = "No options",
		Visible = false,
	})

	local display = options
	local optionButtons = {}
	local innerList = 26
	local optH = Device.IsTouch and 38 or 30
	local pad = 4
	local virtual = false
	local virtualButtons = {}
	local virtualPool = {}
	local expanded = false
	local modalEntry
	local selectOption
	local closeFn
	local setExpanded
	local buildOptions
	local refreshOptions
	local refreshLabel

	local function paintRec(rec, opt)
		local isSel = opt ~= nil and selSet[opt.Key] == true
		local btn = rec.Button
		btn.Text = opt and (multi and ("    " .. opt.Text) or ("  " .. opt.Text)) or ""
		btn.BackgroundColor3 = isSel and CurrentTheme.Accent or CurrentTheme.Element
		btn.BackgroundTransparency = isSel and 0.75 or 1
		btn.TextColor3 = isSel and CurrentTheme.Accent or CurrentTheme.Text
		if multi and rec.Box then
			rec.Box.BackgroundColor3 = isSel and CurrentTheme.Accent or CurrentTheme.SurfaceLight
			rec.BoxStroke.Color = isSel and CurrentTheme.Accent or CurrentTheme.Stroke
			rec.BoxStroke.Transparency = isSel and 0 or 0.4
			rec.Fill.BackgroundColor3 = CurrentTheme.Accent
			rec.Fill.Visible = isSel
			rec.Fill.Size = isSel and UO(8, 8) or UO(0, 0)
		elseif rec.Check then
			rec.Check.Visible = isSel
			if isSel and rec.Check.Rotation < -10 then
				rec.Check.Rotation = -80
			end
		end
	end

	refreshOptions = function()
		if virtual then
			for idx, rec in pairs(virtualButtons) do
				paintRec(rec, display[idx])
			end
		else
			for i, opt in ipairs(display) do
				local rec = optionButtons[i]
				if rec then
					paintRec(rec, opt)
					if rec.Check and rec.Check.Visible then
						Tween(rec.Check, "Spring", { Rotation = 0 })
					end
				end
			end
		end
	end

	refreshLabel = function()
		local text
		local sel = selectedOpts()
		if multi then
			if #sel == 0 then
				text = "-"
			elseif #sel == 1 then
				text = sel[1].Text
			else
				text = #sel .. " selected"
			end
		else
			text = (#sel > 0) and sel[1].Text or "-"
		end
		valueLabel.Text = text
		local has = next(selSet) ~= nil
		valueLabel.TextColor3 = has and CurrentTheme.Text or CurrentTheme.SubText
	end

	local function newRec()
		local btn = U.MkBtn(listCanvas, {
			Size = UN(1, 0, 0, optH),
			Trans = 1,
			Font = EF.Gotham,
			Ts = 12,
			Align = ETA.Left,
			Trunc = true,
			Hover = false,
		})
		local rec = { Button = btn, _idx = nil }
		if multi then
			local box = Frm({
				AnchorPoint = V2(0, 0.5),
				Position = UN(0, 8, 0.5, 0),
				Size = UO(16, 16),
				BackgroundColor3 = "SurfaceLight",
				Parent = btn,
				Children = { Corner(5) },
			})
			rec.BoxStroke = Create("UIStroke", {
				Thickness = 1, Transparency = 0.4,
				ApplyStrokeMode = SB,
				Color = CurrentTheme.Stroke, Parent = box,
			})
			rec.Fill = Frm({
				AnchorPoint = V2(0.5, 0.5),
				Position = US(0.5, 0.5),
				Size = UO(0, 0),
				BackgroundColor3 = CurrentTheme.Accent,
				Visible = false,
				Parent = box,
				Children = { Corner(2) },
			})
			Bind(rec.Fill, "BackgroundColor3", "Accent")
		else
			local chk = Icon(btn, "Check", "Accent")
			chk.AnchorPoint = V2(1, 0.5)
			chk.Position = UN(1, -8, 0.5, 0)
			chk.Size = UO(11, 11)
			chk.Visible = false
			rec.Check = chk
		end
		btn.MouseEnter:Connect(function()
			if Device.IsTouch or not expanded or not rec._idx then return end
			PlaySound("Hover", 0.1)
			local opt = display[rec._idx]
			local isSel = opt ~= nil and selSet[opt.Key] == true
			Tween(btn, "HoverIn", {
				BackgroundColor3 = isSel and CurrentTheme.AccentHover or CurrentTheme.ElementHover,
				BackgroundTransparency = isSel and 0.6 or 0.35,
			})
		end)
		btn.MouseLeave:Connect(function()
			if not rec._idx then return end
			local opt = display[rec._idx]
			local isSel = opt ~= nil and selSet[opt.Key] == true
			Tween(btn, "HoverOut", {
				BackgroundColor3 = isSel and CurrentTheme.Accent or CurrentTheme.Element,
				BackgroundTransparency = isSel and 0.75 or 1,
			})
		end)
		btn.MouseButton1Click:Connect(function()
			local idx = rec._idx
			if not idx then return end
			selectOption(display[idx], btn)
		end)
		return rec
	end

	local function releaseRec(rec)
		rec._idx = nil
		rec.Button.Visible = false
		table.insert(virtualPool, rec)
	end

	local function acquireRec()
		local rec = table.remove(virtualPool)
		if rec then
			rec.Button.Visible = true
			return rec
		end
		return newRec()
	end

	local function updateVirtualWindow()
		if not virtual or not expanded then return end
		local viewH = listCanvas.AbsoluteSize.Y
		local top = listCanvas.CanvasPosition.Y
		local rowStep = optH + pad
		local first = math.max(1, floor(top / rowStep) - 2)
		local count = math.ceil(viewH / rowStep) + 5
		local last = math.min(#display, first + count)
		for idx, rec in pairs(virtualButtons) do
			if idx < first or idx > last then
				virtualButtons[idx] = nil
				releaseRec(rec)
			end
		end
		for idx = first, last do
			if not virtualButtons[idx] then
				local rec = acquireRec()
				virtualButtons[idx] = rec
				rec._idx = idx
				rec.Button.Position = UO(0, (idx - 1) * rowStep)
				paintRec(rec, display[idx])
			end
		end
	end

	local function commitMulti()
		refreshOptions()
		refreshLabel()
		SaveValue(saveKey, valuesOf(selectedOpts()))
		RunCallback(self.Callback, self.Title, self:Get())
	end

	setExpanded = function(state)
		if expanded == state then return end
		expanded = state
		Tween(chevHolder, "PopSoft", { Rotation = state and 180 or 0 })

		if state then
			if tab._openDropdown and tab._openDropdown ~= closeFn then
				tab._openDropdown()
			end
			tab._openDropdown = closeFn

			local sc = GetScale()
			local ap, asz = row.AbsolutePosition, row.AbsoluteSize
			local rowX, rowY = ap.X / sc, ap.Y / sc
			local rowW, rowH2 = asz.X / sc, asz.Y / sc
			local vw, vh = Viewport.X / sc, Viewport.Y / sc
			local pw = math.max(140, rowW)
			local totalH = headerH + innerList
			local below = vh - (rowY + rowH2) - 10
			local above = rowY - 10
			if below < totalH and above < totalH then
				totalH = headerH + math.max(optH + 14, math.min(innerList, math.max(below, above)))
			end
			local y, slideFrom
			if below >= totalH then
				y, slideFrom = rowY + rowH2 - 2, -6
			elseif above >= totalH then
				y, slideFrom = rowY - totalH + 2, 6
			else
				y = ClampEdge(rowY + rowH2 + 4, totalH, vh, 8)
				slideFrom = -6
			end
			local x = ClampEdge(rowX, pw, vw, 8)

			listCanvas.CanvasPosition = V2(0, 0)
			listCanvas.Position = UN(0, 0, 0, headerH)
			listCanvas.Size = UN(1, 0, 1, -headerH)
			list.Size = UN(0, pw, 0, 0)
			list.Position = UO(x, y + slideFrom)
			list.Visible = true
			catcher.Visible = true
			list.GroupTransparency = 1
			Tween(list, "Snappy", { Size = UN(0, pw, 0, totalH), GroupTransparency = 0 })
			Tween(list, "Smooth", { Position = UO(x, y) })

			ModalManager.Remove(modalEntry)
			modalEntry = ModalManager.Push(tab.Window, closeFn)

			if virtual then
				updateVirtualWindow()
			else
				refreshOptions()
				for i, opt in ipairs(display) do
					local rec = optionButtons[i]
					if rec then
						local btn = rec.Button
						local isSel = selSet[opt.Key] == true
						btn.TextTransparency = 1
						btn.BackgroundTransparency = 1
						task.delay(math.min(i * 0.02, 0.16), function()
							if not expanded then return end
							Tween(btn, "Fast", { TextTransparency = 0, BackgroundTransparency = isSel and 0.75 or 1 })
						end)
					end
				end
			end
		else
			if tab._openDropdown == closeFn then
				tab._openDropdown = nil
			end
			ModalManager.Remove(modalEntry)
			modalEntry = nil
			catcher.Visible = false
			Tween(list, "Fast", { Size = UN(0, list.AbsoluteSize.X / GetScale(), 0, 0) })
			Tween(list, "Fast", { GroupTransparency = 1 }, function()
				if not expanded then
					list.Visible = false
				end
			end)
		end
	end

	closeFn = function()
		setExpanded(false)
	end

	selectOption = function(opt, rippleTarget)
		if not opt then return end
		if self._disabled then return end
		Tap(rippleTarget, "Click", 0.7)
		if multi then
			if selSet[opt.Key] then
				selSet[opt.Key] = nil
			else
				selSet[opt.Key] = true
			end
			commitMulti()
		else
			selSet = { [opt.Key] = true }
			refreshOptions()
			refreshLabel()
			SaveValue(saveKey, opt.Value)
			setExpanded(false)
			RunCallback(self.Callback, self.Title, self:Get())
		end
	end

	local function clearButtons()
		for _, rec in ipairs(optionButtons) do
			if rec.Button then
				rec.Button:Destroy()
			end
		end
		table.clear(optionButtons)
		for _, rec in pairs(virtualButtons) do
			rec.Button:Destroy()
		end
		table.clear(virtualButtons)
		for _, rec in ipairs(virtualPool) do
			rec.Button:Destroy()
		end
		table.clear(virtualPool)
	end

	buildOptions = function()
		clearButtons()
		local count = #display
		virtual = count > DROP_VIRTUALIZE
		emptyLabel.Visible = count == 0

		local layout = listCanvas:FindFirstChildOfClass("UIListLayout")
		if not virtual and not layout then
			List(pad).Parent = listCanvas
		elseif virtual and layout then
			layout:Destroy()
		end

		if virtual then
			listCanvas.AutomaticCanvasSize = AS.None
			listCanvas.CanvasSize = UN(0, 0, 0, count * (optH + pad) + 8)
			innerList = math.min(count, 6) * optH + math.min(count, 5) * pad + 12
			updateVirtualWindow()
		else
			listCanvas.AutomaticCanvasSize = AS.Y
			listCanvas.CanvasSize = UN()
			local rows = clamp(count, 1, 6)
			innerList = count > 0 and (rows * optH + (rows - 1) * pad + 12) or 26
			for i, opt in ipairs(display) do
				local rec = newRec()
				rec._idx = i
				rec.Button.LayoutOrder = i
				optionButtons[i] = rec
				paintRec(rec, opt)
			end
		end

		header.Size = UN(1, 0, 0, headerH)
		listCanvas.Position = UN(0, 0, 0, headerH)
		listCanvas.Size = UN(1, 0, 1, -headerH)
		refreshOptions()
		if expanded then
			local sc = GetScale()
			list.Size = UN(0, row.AbsoluteSize.X / sc, 0, headerH + innerList)
		end
	end

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower()
			if query == "" then
				display = options
			else
				local out = {}
				for _, o in ipairs(options) do
					if o.Text:lower():find(query, 1, true) then
						out[#out + 1] = o
					end
				end
				display = out
			end
			listCanvas.CanvasPosition = V2(0, 0)
			buildOptions()
			refreshOptions()
			if expanded then
				list.Size = UN(0, row.AbsoluteSize.X / GetScale(), 0, headerH + innerList)
			end
		end)
	end

	if allBtn then
		allBtn.MouseButton1Click:Connect(function()
			for _, o in ipairs(options) do
				selSet[o.Key] = true
			end
			commitMulti()
		end)
	end
	if noneBtn then
		noneBtn.MouseButton1Click:Connect(function()
			selSet = {}
			commitMulti()
		end)
	end

	listCanvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if virtual and expanded then
			updateVirtualWindow()
		end
	end)
	listCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if virtual and expanded then
			updateVirtualWindow()
		end
	end)

	catcher.MouseButton1Click:Connect(function()
		if expanded then
			setExpanded(false)
		end
	end)

	local overlay = Hit({
		Size = UN(1, 0, 0, baseH),
		ZIndex = 1,
		Parent = row,
	})
	Click(self.Maid, overlay, function()
		if self._disabled then return end
		Tap(overlay, "Click", 0.7)
		setExpanded(not expanded)
	end)
	HookContextMenu(self, overlay)

	self.Maid:Give(function()
		if tab._openDropdown == closeFn then
			tab._openDropdown = nil
		end
		ModalManager.Remove(modalEntry)
		if list and list.Parent then
			list:Destroy()
		end
		if catcher and catcher.Parent then
			catcher:Destroy()
		end
	end)

	function self:Set(v, silent)
		if self._destroyed then return end
		local items = (multi and type(v) == "table") and v or { v }
		local ns = {}
		for _, x in ipairs(items) do
			if x ~= nil then
				local o = findOpt(tostring(x))
				if o then
					ns[o.Key] = true
				end
			end
		end
		selSet = ns
		SaveValue(saveKey, multi and valuesOf(selectedOpts()) or (selectedOpts()[1] and selectedOpts()[1].Value or nil))
		refreshOptions()
		refreshLabel()
		if not silent then
			RunCallback(self.Callback, self.Title, self:Get())
		end
	end

	function self:Get()
		if multi then
			return valuesOf(selectedOpts())
		end
		local sel = selectedOpts()
		return sel[1] and sel[1].Value or nil
	end

	function self:GetText()
		if multi then
			local out = {}
			for _, o in ipairs(selectedOpts()) do
				out[#out + 1] = o.Text
			end
			return out
		end
		local sel = selectedOpts()
		return sel[1] and sel[1].Text or nil
	end

	function self:CopyValue()
		return table.concat(self:GetText() or {}, ", ")
	end

	function self:SetOptions(newOptions)
		if self._destroyed then return end
		options = normalize(newOptions)
		local valid = {}
		for _, opt in ipairs(options) do
			valid[opt.Key] = true
		end
		local ns = {}
		for k in pairs(selSet) do
			if valid[k] then
				ns[k] = true
			end
		end
		selSet = ns
		local newW = measureWidth()
		if newW ~= rightW then
			rightW = newW
			self._baseRightW = rightW
			self._width = rightW
			valueLabel.Size = UN(0, rightW - 26, 1, 0)
			self:RecalcWidth()
		end
		buildOptions()
		refreshLabel()
	end

	self:_bindSave(saveKey, function(v)
		self:Set(v, true)
	end)
	self.Maid:Give(Kailex.ThemeChanged:Connect(function()
		refreshLabel()
		refreshOptions()
	end))

	buildOptions()
	refreshLabel()
	self:_deferInit(next(selSet) ~= nil, self:Get())

	return self
end

Elements.TextInput = MakeElementClass()

function Elements.TextInput.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local self = ENew(Elements.TextInput, tab, opts, {
		Name = opts.Name or "Input",
		RightWidth = 170,
	})

	local value = SaveManager:Get(saveKey, opts.Default or "")
	if type(value) ~= "string" then
		value = tostring(opts.Default or "")
	end
	local lastFired = value
	local validator = type(opts.Validator) == "function" and opts.Validator or nil

	local box = U.TxB(self.RightContainer, {
		Size = UN(1, 0, 1, 0),
		Text = value,
		Ph = opts.Placeholder or "",
		Ts = 12,
		Align = ETA.Left,
		Kids = { Corner(6), Pad(8, 8), StrokeBind(1, "Stroke", 0.5) },
	})
	local boxStroke = box:FindFirstChildOfClass("UIStroke")
	local row = self.Row

	self.Maid:Give(box.Focused:Connect(function()
		Tween(boxStroke, "Fast", { Color = CurrentTheme.Accent, Transparency = 0 })
	end))
	self.Maid:Give(box.FocusLost:Connect(function(enter)
		Tween(boxStroke, "Fast", { Color = CurrentTheme.Stroke, Transparency = 0.5 })
		local text = box.Text
		if validator then
			local ok = validator(text)
			if ok ~= true then
				text = value
				box.Text = text
				PlaySound("Error")
				FX.Shake(row, 6)
				Tween(boxStroke, "Fast", { Color = CurrentTheme.Error, Transparency = 0 })
				task.delay(1, function()
					if not self._destroyed then
						Tween(boxStroke, "Smooth", { Color = CurrentTheme.Stroke, Transparency = 0.5 })
					end
				end)
				return
			end
		end
		if text ~= value then
			value = text
			SaveValue(saveKey, value)
		end
		if value ~= lastFired or enter then
			lastFired = value
			RunCallback(self.Callback, self.Title, value)
		end
	end))
	self.Maid:Give(Kailex.ThemeChanged:Connect(function()
		if box:IsFocused() then
			boxStroke.Color = CurrentTheme.Accent
		end
	end))

	function self:Set(text, silent)
		if self._destroyed then return end
		value = tostring(text or "")
		lastFired = value
		box.Text = value
		SaveValue(saveKey, value)
		if not silent then
			RunCallback(self.Callback, self.Title, value)
		end
	end

	function self:Get() return value end
	function self:CopyValue() return value end

	self:_saveAs(saveKey, "string")

	return self
end

Elements.ColorPicker = MakeElementClass()

function Elements.ColorPicker.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local default = opts.Default or opts.Color or CurrentTheme.Accent
	if typeof(default) ~= "Color3" then
		default = CurrentTheme.Accent
	end

	local function loadColor()
		local sv = SaveManager:Get(saveKey, nil)
		if type(sv) == "string" then
			local c = HexToColor(sv)
			if c then
				return c
			end
		end
		return default
	end

	local color = loadColor()
	local hadSaved = SaveManager:Get(saveKey, nil) ~= nil
	local h, s, v = RGBtoHSV(color)

	local self = ENew(Elements.ColorPicker, tab, opts, {
		Name = opts.Name or "Color",
		RightWidth = 44,
	})

	local swatchBtn = U.MkBtn(self.RightContainer, {
		Size = UO(38, 22),
		BgC = color,
		Hover = false,
		Order = 1,
	})
	StrokeBind(1, "Knob", 0.55, swatchBtn)

	local popup, catcher, square, svKnob, hueBar, hueKnob, hexBox
	local pickerScale
	local closePopup
	local open = false
	local modalEntry

	local function apply(nh, ns, nv, notify)
		h, s, v = nh, ns, nv
		color = Color3.fromHSV(h, s, v)
		swatchBtn.BackgroundColor3 = color
		if popup and open then
			square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svKnob.Position = UN(s, 0, 1 - v, 0)
			hueKnob.Position = UN(h, 0, 0.5, 0)
			hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			if not hexBox:IsFocused() then
				hexBox.Text = ColorToHex(color)
			end
		end
		if notify then
			RunCallback(self.Callback, self.Title, color)
		end
	end

	local function build()
		popup = Grp({
			Size = UO(240, 250),
			BackgroundColor3 = "Surface",
			Visible = false,
			ZIndex = 30,
			Parent = LayerOverlay,
			Children = { Corner(12), StrokeBind(1, "Stroke", 0.35) },
		})
		pickerScale = UISC(popup)

		catcher = U.Overlay(LayerOverlay, 29, false)
		catcher.MouseButton1Click:Connect(function()
			closePopup()
		end)

		U.Txt(popup, {
			Pos = UO(12, 10),
			Size = UN(1, -56, 0, 16),
			Font = EF.GothamBold,
			Ts = 12,
			Align = ETA.Left,
			Trunc = true,
			Text = self.Title,
			Z = 31,
		})

		local resetBtn = Hit({
			AnchorPoint = V2(1, 0),
			Position = UN(1, -10, 0, 8),
			Size = UO(20, 20),
			ZIndex = 31,
			Parent = popup,
		})
		Icon(resetBtn, "Reset", "SubText", 13)
		AddTooltip(resetBtn, { Text = "Reset" })
		resetBtn.MouseButton1Click:Connect(function()
			Tap(resetBtn, "Click", 0.6)
			local rh, rs, rv = RGBtoHSV(default)
			apply(rh, rs, rv, true)
			SaveValue(saveKey, ColorToHex(color))
		end)

		square = Frm({
			Position = UO(12, 32),
			Size = UO(216, 120),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			ZIndex = 31,
			Parent = popup,
			Children = { Corner(8) },
		})
		Frm({
			Size = US(1, 1),
			BackgroundColor3 = CN(1, 1, 1),
			ZIndex = 31,
			Parent = square,
			Children = {
				Corner(8),
				Create("UIGradient", {
					Color = ColorSequence.new(CN(1, 1, 1), CN(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			},
		})
		Frm({
			Size = US(1, 1),
			BackgroundColor3 = CN(0, 0, 0),
			ZIndex = 32,
			Parent = square,
			Children = {
				Corner(8),
				Create("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(CN(0, 0, 0), CN(0, 0, 0)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					}),
				}),
			},
		})
		svKnob = Frm({
			AnchorPoint = V2(0.5, 0.5),
			Size = UO(12, 12),
			BackgroundColor3 = CN(1, 1, 1),
			ZIndex = 33,
			Parent = square,
			Children = {
				Corner(PILL),
				Create("UIStroke", { Thickness = 2, Color = CN(0, 0, 0), Transparency = 0.5 }),
			},
		})

		hueBar = Frm({
			Position = UO(12, 158),
			Size = UO(216, 12),
			BackgroundColor3 = CN(1, 1, 1),
			ZIndex = 31,
			Parent = popup,
			Children = {
				Corner(6),
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, RGB(255, 0, 0)),
						ColorSequenceKeypoint.new(1 / 6, RGB(255, 255, 0)),
						ColorSequenceKeypoint.new(2 / 6, RGB(0, 255, 0)),
						ColorSequenceKeypoint.new(3 / 6, RGB(0, 255, 255)),
						ColorSequenceKeypoint.new(4 / 6, RGB(0, 0, 255)),
						ColorSequenceKeypoint.new(5 / 6, RGB(255, 0, 255)),
						ColorSequenceKeypoint.new(1.00, RGB(255, 0, 0)),
					}),
				}),
			},
		})
		hueKnob = Frm({
			AnchorPoint = V2(0.5, 0.5),
			Size = UO(14, 14),
			Position = UN(h, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			ZIndex = 32,
			Parent = hueBar,
			Children = {
				Corner(PILL),
				Create("UIStroke", { Thickness = 2, Color = CN(1, 1, 1), Transparency = 0.2 }),
			},
		})

		hexBox = U.TxB(popup, {
			Pos = UO(12, 182),
			Size = UO(70, 24),
			Font = EF.GothamBold,
			Ts = 11,
			Ph = "#RRGGBB",
			Align = ETA.Center,
			Text = ColorToHex(color),
			Z = 31,
			Kids = { Corner(6), Pad(6, 6), StrokeBind(1, "Stroke", 0.5) },
		})

		local hexCopy = U.MkBtn(popup, {
			Pos = UO(88, 182),
			Size = UO(50, 24),
			Text = "Copy",
			Ts = 10,
			Color = "SubText",
			Z = 31,
		})
		hexCopy.MouseButton1Click:Connect(function()
			CopyToClipboard(ColorToHex(color))
		end)

		hexBox.FocusLost:Connect(function()
			local c = HexToColor(hexBox.Text)
			if c then
				local rh, rs, rv = RGBtoHSV(c)
				apply(rh, rs, rv, true)
				SaveValue(saveKey, ColorToHex(color))
			else
				hexBox.Text = ColorToHex(color)
			end
		end)

		local function dragTracker(handle, onMove)
			TrackInput(handle, {
				Active = handle,
				MoveNow = true,
				Move = function(pos)
					onMove(pos)
				end,
				End = function()
					SaveValue(saveKey, ColorToHex(color))
				end,
			})
		end

		dragTracker(square, function(pos)
			local ap, as = square.AbsolutePosition, square.AbsoluteSize
			s = clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
			v = 1 - clamp((pos.Y - ap.Y) / math.max(1, as.Y), 0, 1)
			apply(h, s, v, true)
		end)
		dragTracker(hueBar, function(pos)
			local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
			h = clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
			apply(h, s, v, true)
		end)
	end

	local function openPopup()
		if not popup then build() end
		if open then return end
		open = true
		local sc = GetScale()
		local ap = swatchBtn.AbsolutePosition
		local asz = swatchBtn.AbsoluteSize
		local pw, ph = 240 * sc, 216 * sc
		local px = ap.X + asz.X + 10
		if px + pw > Viewport.X - 8 then
			px = ap.X - pw - 10
		end
		px = ClampEdge(px, pw, Viewport.X, 8)
		local py = ClampEdge(ap.Y + asz.Y / 2 - ph / 2, ph, Viewport.Y, 8)
		popup.Position = UO(px / sc, py / sc)
		catcher.Visible = true
		popup.Visible = true
		pickerScale.Scale = 0.94
		Tween(pickerScale, "Pop", { Scale = 1 })
		popup.GroupTransparency = 1
		Tween(popup, "Snappy", { GroupTransparency = 0 })
		ModalManager.Remove(modalEntry)
		modalEntry = ModalManager.Push(tab.Window, closePopup)
		apply(h, s, v, false)
	end

	function closePopup()
		if not open then return end
		open = false
		ModalManager.Remove(modalEntry)
		modalEntry = nil
		SaveValue(saveKey, ColorToHex(color))
		Tween(pickerScale, "Vanish", { Scale = 0.95 })
		Tween(popup, "Fast", { GroupTransparency = 1 }, function()
			if not open then
				popup.Visible = false
				catcher.Visible = false
			end
		end)
	end

	Click(self.Maid, swatchBtn, function()
		if self._disabled then return end
		Tap(swatchBtn, "Click", 0.6)
		if open then
			closePopup()
		else
			openPopup()
		end
	end)

	local escHook = AddInputHook(function()
		return not self._destroyed
	end, function(input, gp)
		if open ~= true then return end
		if input.KeyCode ~= EKC.Escape then return end
		if gp then
			local focused = UIS:GetFocusedTextBox()
			if hexBox and focused == hexBox then
				closePopup()
			end
			return
		end
		closePopup()
	end)
	self.Maid:Give(function()
		RemoveInputHook(escHook)
	end)
	self.Maid:Give(function()
		ModalManager.Remove(modalEntry)
	end)
	self.Maid:Give(tab.Page:GetPropertyChangedSignal("Visible"):Connect(function()
		if not tab.Page.Visible then
			closePopup()
		end
	end))
	if tab.Window and tab.Window.MinimizedChanged then
		self.Maid:Give(tab.Window.MinimizedChanged:Connect(function(min)
			if min then
				closePopup()
			end
		end))
	end

	function self:Set(c, silent)
		if self._destroyed then return end
		if typeof(c) ~= "Color3" then return end
		local rh, rs, rv = RGBtoHSV(c)
		apply(rh, rs, rv, false)
		SaveValue(saveKey, ColorToHex(color))
		if not silent then
			RunCallback(self.Callback, self.Title, color)
		end
	end

	function self:SetDefault(c)
		if self._destroyed then return end
		if typeof(c) ~= "Color3" then return end
		default = c
	end

	function self:Get() return color end
	function self:CopyValue() return ColorToHex(color) end

	self:_bindSave(saveKey, function(v)
		if type(v) == "string" then
			local c = HexToColor(v)
			if c then
				local rh, rs, rv = RGBtoHSV(c)
				apply(rh, rs, rv, false)
				SaveValue(saveKey, ColorToHex(color))
			end
		end
	end)
	self:_deferInit(hadSaved or opts.Default ~= nil, color)

	return self
end

Elements.Stepper = MakeElementClass()

function Elements.Stepper.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local min = tonumber(opts.Min) or 0
	local max = tonumber(opts.Max) or 10
	if max <= min then
		max = min + 1
	end
	local step = tonumber(opts.Step) or 1
	if step <= 0 then
		step = 1
	end
	local default = tonumber(opts.Default or min) or min
	local value = clamp(U.LoadNum(saveKey, default), min, max)

	local decimals = DecimalsOf(step)
	local fmt = opts.Format
	if type(fmt) ~= "function" then
		local prefix, suffix = opts.Prefix or "", opts.Suffix or ""
		fmt = function(v)
			return prefix .. string.format("%." .. decimals .. "f", v) .. suffix
		end
	end

	local self = ENew(Elements.Stepper, tab, opts, {
		Name = opts.Name or "Stepper",
		RightWidth = 118,
	})
	local right, row = self.RightContainer, self.Row

	local function mkStepBtn(text, order)
		return U.MkBtn(right, {
			Size = UO(26, 26),
			Text = text,
			Ts = 14,
			Order = order,
			R = 8,
		})
	end

	local minus = mkStepBtn("-", 1)
	local valLabel = U.Txt(right, {
		Size = UO(56, 26),
		Font = EF.GothamBold,
		Ts = 12,
		Align = ETA.Center,
		Trunc = true,
		Order = 2,
	})
	local plus = mkStepBtn("+", 3)

	local function refreshLabel()
		valLabel.Text = fmt(value)
	end
	refreshLabel()

	function self:Set(v, silent)
		if self._destroyed then return end
		local n = tonumber(v)
		if n == nil then return end
		n = clamp(n, min, max)
		if n == value then return end
		value = n
		refreshLabel()
		SaveValue(saveKey, value)
		if not silent then
			RunCallback(self.Callback, self.Title, value)
		end
	end

	function self:Get() return value end
	function self:CopyValue()
		return string.format("%." .. decimals .. "f", value)
	end

	local function bindHold(btn, dir)
		TrackInput(btn, {
			Guard = function()
				return not self._disabled
			end,
			Active = btn,
			Start = function(state)
				ApplyRipple(btn)
				self:Set(value + dir * step)
				state.RepeatThread = task.delay(0.45, function()
					while state.Alive do
						self:Set(value + dir * step)
						task.wait(0.09)
					end
				end)
			end,
			End = function(state)
				if state.RepeatThread then
					pcall(task.cancel, state.RepeatThread)
				end
			end,
		})
	end
	bindHold(minus, -1)
	bindHold(plus, 1)

	function self:HandleArrow(dir)
		if self._destroyed or self._disabled then return end
		self:Set(value + dir * step)
	end

	U.TrackHot(self, row)
	self:_saveAs(saveKey, "number")
	self:_deferInit(opts.Default ~= nil or SaveManager:Get(saveKey, nil) ~= nil, value)

	return self
end

Elements.Segmented = MakeElementClass()

function Elements.Segmented.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)

	local options = {}
	for _, v in ipairs(opts.Options or {}) do
		if type(v) == "table" and v.Text ~= nil then
			options[#options + 1] = { Text = tostring(v.Text), Value = (v.Value ~= nil) and v.Value or v.Text }
		else
			options[#options + 1] = { Text = tostring(v), Value = v }
		end
	end
	local itemW = opts.ItemWidth or 56
	local rightW = clamp(#options * (itemW + 4), 60, 280)
	local selected = nil

	local self = ENew(Elements.Segmented, tab, opts, {
		Name = opts.Name or "Segmented",
		RightWidth = rightW,
	})

	local holder = Frm({
		BackgroundTransparency = 1,
		Size = UN(1, 0, 1, -4),
		Parent = self.RightContainer,
		Children = { U.HL(4) },
	})

	local buttons = {}
	local function paint()
		for i, b in ipairs(buttons) do
			local sel = options[i] == selected
			b.BackgroundColor3 = sel and CurrentTheme.Accent or CurrentTheme.Element
			b.TextColor3 = sel and CurrentTheme.OnAccent or CurrentTheme.SubText
		end
	end

	for i, opt in ipairs(options) do
		local b = U.MkBtn(holder, {
			Size = UO(itemW, 26),
			Text = opt.Text,
			Ts = 11,
			Color = "SubText",
			Trunc = true,
			Order = i,
			R = 8,
		})
		buttons[i] = b
		b.MouseButton1Click:Connect(function()
			if self._disabled then return end
			Tap(b, "Click", 0.7)
			if selected ~= opt then
				selected = opt
				paint()
				SaveValue(saveKey, opt.Value)
				RunCallback(self.Callback, self.Title, opt.Value)
			end
		end)
	end

	do
		local sv = SaveManager:Get(saveKey, nil)
		local d = (sv ~= nil) and sv or opts.Default
		if d ~= nil then
			for _, o in ipairs(options) do
				if o.Value == d or tostring(o.Value) == tostring(d) then
					selected = o
					break
				end
			end
		end
	end
	paint()

	function self:Set(v, silent)
		if self._destroyed then return end
		for _, o in ipairs(options) do
			if o.Value == v or tostring(o.Value) == tostring(v) then
				if selected ~= o then
					selected = o
					paint()
					SaveValue(saveKey, o.Value)
					if not silent then
						RunCallback(self.Callback, self.Title, o.Value)
					end
				end
				return
			end
		end
	end

	function self:Get()
		return selected and selected.Value or nil
	end

	function self:CopyValue()
		return selected and tostring(selected.Value) or nil
	end

	self:_bindSave(saveKey, function(v)
		self:Set(v, true)
	end)
	self.Maid:Give(Kailex.ThemeChanged:Connect(paint))
	self:_deferInit(selected ~= nil, selected and selected.Value)

	return self
end

Elements.Vector3Input = MakeElementClass()

function Elements.Vector3Input.new(tab, opts)
	opts = opts or {}
	local saveKey = tab:GetSaveKey(opts)
	local self = ENew(Elements.Vector3Input, tab, opts, {
		Name = opts.Name or "Vector3",
		RightWidth = 196,
		Height = 60,
	})

	local function load()
		local sv = SaveManager:Get(saveKey, nil)
		if type(sv) == "table" and tonumber(sv.X) and tonumber(sv.Y) and tonumber(sv.Z) then
			return Vector3.new(sv.X, sv.Y, sv.Z)
		end
		return opts.Default
	end
	local value = load()
	if typeof(value) ~= "Vector3" then
		value = Vector3.new()
	end

	local boxes = {}
	local names = { "X", "Y", "Z" }
	for i = 1, 3 do
		local b = U.TxB(self.RightContainer, {
			Size = UO(60, 24),
			Font = EF.GothamBold,
			Ts = 11,
			Ph = names[i],
			Align = ETA.Center,
			Text = string.format("%.2f", ({ value.X, value.Y, value.Z })[i]),
			Order = i,
			Kids = { Corner(6), StrokeBind(1, "Stroke", 0.5) },
		})
		boxes[i] = b
		b.FocusLost:Connect(function()
			local n = tonumber((b.Text:gsub(",", ".")))
			if n then
				local c = { value.X, value.Y, value.Z }
				c[i] = n
				self:Set(Vector3.new(c[1], c[2], c[3]))
			else
				b.Text = string.format("%.2f", ({ value.X, value.Y, value.Z })[i])
			end
		end)
	end

	function self:Set(v, silent)
		if self._destroyed then return end
		if typeof(v) ~= "Vector3" then return end
		value = v
		for i = 1, 3 do
			if not boxes[i]:IsFocused() then
				boxes[i].Text = string.format("%.2f", ({ value.X, value.Y, value.Z })[i])
			end
		end
		SaveValue(saveKey, { X = value.X, Y = value.Y, Z = value.Z })
		if not silent then
			RunCallback(self.Callback, self.Title, value)
		end
	end

	function self:Get() return value end
	function self:CopyValue() return tostring(value) end

	self:_bindSave(saveKey, function(v)
		if type(v) == "table" then
			self:Set(Vector3.new(tonumber(v.X) or 0, tonumber(v.Y) or 0, tonumber(v.Z) or 0), true)
		end
	end)

	self:_deferInit(opts.Default ~= nil or SaveManager:Get(saveKey, nil) ~= nil, value)

	return self
end

local GridRow = {}
GridRow.__index = GridRow

function GridRow:_newFrame()
	self.Frame = Frm({
		Size = UN(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = self.Tab:_nextOrder(),
		Parent = self.Tab.Content,
		Children = { U.HL(6, Enum.HorizontalAlignment.Left, EVA.Center) },
	})
	self.Frame:SetAttribute("__grid", true)
	if self.Tab._gridFrames then
		table.insert(self.Tab._gridFrames, self.Frame)
	end
	self.Used = 0
	self.CellOrder = 0
	self.FrameH = 0
	self.AutoH = false
end

function GridRow:Place(el, span)
	local g = 6
	local cols = self.Cols
	if self.Used + span > cols then
		self:_newFrame()
	end
	local off = floor(g * (span - 1) - g * span * (cols - 1) / cols + 0.5)
	local sz = el.Row.Size
	local target = UN(span / cols, off, sz.Y.Scale, sz.Y.Offset)
	el.Row:SetAttribute("__el", true)
	el._gridFrame = self.Frame
	self.CellOrder += 1
	el.Row.LayoutOrder = self.CellOrder
	el.Row.Size = target
	el.Row.Parent = self.Frame
	if el.Row.AutomaticSize == AS.Y then
		self.Frame.AutomaticSize = AS.Y
		self.AutoH = true
	elseif not self.AutoH then
		if sz.Y.Offset > self.FrameH then
			self.FrameH = sz.Y.Offset
		end
		self.Frame.Size = UN(1, 0, 0, self.FrameH)
	end
	self.Used += span
end

local function RefreshEmptySoon(win, tab)
	if win and not win._destroyed and win.CurrentTab == tab
		and win.EmptyLabel and win.EmptyLabel.Visible then
		task.defer(function()
			if not win._destroyed and not tab._destroyed and win.CurrentTab == tab then
				win:ApplyFilter(win._filterQuery)
			end
		end)
	end
end

local TabClass = {}
TabClass.__index = TabClass

function TabClass.new(window, opts)
	opts = opts or {}
	local self = setmetatable({}, TabClass)
	self.Window = window
	self.Title = tostring(opts.Title or opts.Name or "Tab")
	self.Elements = {}
	self.Sections = {}
	self._gridFrames = {}
	self.CurrentSection = nil
	self._order = 0
	self._saveKeys = {}
	self._selected = false
	self._openDropdown = nil
	self._autoRow = nil

	self.Page = Grp({
		Size = US(1, 1),
		Visible = false,
		GroupTransparency = 1,
		BackgroundTransparency = 1,
		Parent = window.Pages,
	})
	self.Content = Scr({
		Size = US(1, 1),
		Parent = self.Page,
		Children = {
			Pad(10, 10, 10, 0), List(6),
			Frm({
				Name = "__BottomSpacer",
				BackgroundTransparency = 1,
				Size = UN(1, 0, 0, 16),
				LayoutOrder = 1000000000,
			}),
		},
	})
	Bind(self.Content, "ScrollBarImageColor3", "Stroke")

	self.TabButton = Hit({
		BackgroundColor3 = "Element",
		Size = UN(1, 0, 0, 30),
		Parent = window.TabList,
	})
	Corner(7, self.TabButton)
	Pad(0, 8, 0, 0, self.TabButton)

	self.Bar = Frm({
		AnchorPoint = V2(0, 0.5),
		Position = UN(0, 0, 0.5, 0),
		Size = UO(3, 8),
		BackgroundColor3 = "Accent",
		BackgroundTransparency = 1,
		Parent = self.TabButton,
	})
	Corner(PILL, self.Bar)

	self.Badge = U.Txt(self.TabButton, {
		Ap = V2(1, 0.5),
		Pos = UN(1, -6, 0.5, 0),
		Size = UO(0, 14),
		Auto = AS.X,
		Font = EF.GothamBold,
		Ts = 10,
		Color = "SubText",
		Text = "",
		Visible = false,
	})

	local iconOffset = 12
	if opts.Icon then
		iconOffset = 32
		local raw = tostring(opts.Icon)
		local isAsset = tonumber(opts.Icon) ~= nil
			or raw:sub(1, 11) == "rbxassetid" or raw:sub(1, 9) == "rbxasset://"
		if isAsset then
			self.IconImg = Create("ImageLabel", {
				AnchorPoint = V2(0, 0.5),
				Position = UN(0, 10, 0.5, 0),
				Size = UO(16, 16),
				BackgroundTransparency = 1,
				Image = tonumber(opts.Icon) and ("rbxassetid://" .. opts.Icon) or opts.Icon,
				ImageColor3 = "SubText",
				Parent = self.TabButton,
			})
		else
			self.IconImg = Icon(self.TabButton, raw, "SubText")
			self.IconImg.AnchorPoint = V2(0, 0.5)
			self.IconImg.Position = UN(0, 10, 0.5, 0)
			self.IconImg.Size = UO(16, 16)
		end
	end
	self._iconOffset = iconOffset

	self.TabLabel = U.Txt(self.TabButton, {
		Pos = UO(iconOffset, 0),
		Size = UN(1, -iconOffset - 6, 1, 0),
		Font = EF.GothamMedium,
		Ts = 12,
		Color = "SubText",
		Align = ETA.Left,
		Trunc = true,
		Text = self.Title,
	})

	self.Maid = Maid.new()
	window.Maid:Give(self.Maid)
	Click(self.Maid, self.TabButton, function()
		Tap(self.TabButton, "Click", 0.6)
		self:Select()
	end)
	self.Maid:Give(Kailex.ThemeChanged:Connect(function()
		self:_setSelected(self._selected)
	end))
	return self
end

function TabClass:_setSelected(on, instant)
	self._selected = on
	if instant then
		local t = on and 0 or 1
		self.TabButton.BackgroundTransparency = t
		self.Bar.BackgroundTransparency = t
		self.Bar.Size = on and UO(3, 16) or UO(3, 8)
		self.TabLabel.TextColor3 = on and CurrentTheme.Text or CurrentTheme.SubText
		if self.IconImg and self.IconImg:IsA("ImageLabel") then
			self.IconImg.ImageColor3 = on and CurrentTheme.Text or CurrentTheme.SubText
		end
		return
	end
	Tween(self.TabButton, "Fast", { BackgroundTransparency = on and 0 or 1 })
	Tween(self.Bar, "PopSoft", {
		BackgroundTransparency = on and 0 or 1,
		Size = on and UO(3, 16) or UO(3, 8),
	})
	Tween(self.TabLabel, "Fast", { TextColor3 = on and CurrentTheme.Text or CurrentTheme.SubText })
	if self.IconImg and self.IconImg:IsA("ImageLabel") then
		Tween(self.IconImg, "Fast", { ImageColor3 = on and CurrentTheme.Text or CurrentTheme.SubText })
	end
end

function TabClass:_setHorizontal(on)
	if self._horizontalState == on then return end
	self._horizontalState = on
	if on then
		self.TabButton.AutomaticSize = AS.X
		self.TabButton.Size = UN(0, 0, 1, -8)
		self.TabLabel.AutomaticSize = AS.X
		self.TabLabel.Size = UN(0, 0, 1, 0)
		self.Bar.Visible = false
	else
		self.TabButton.AutomaticSize = AS.None
		self.TabButton.Size = UN(1, 0, 0, 30)
		self.TabLabel.AutomaticSize = AS.None
		self.TabLabel.Size = UN(1, -(self._iconOffset or 12) - 6, 1, 0)
		self.Bar.Visible = true
	end
end

function TabClass:Select(instant)
	local win = self.Window
	if win.CurrentTab == self then return end
	local prev = win.CurrentTab
	win.CurrentTab = self
	win:_closeDropdowns()
	ModalManager.CloseAll(win)
	if prev then
		Tween(prev.Page, "Vanish", { GroupTransparency = 1 }, function()
			if win.CurrentTab ~= prev then
				prev.Page.Visible = false
			end
		end)
		prev:_setSelected(false)
	end
	self.Page.Visible = true
	self:_setSelected(true, instant)
	if instant then
		self.Page.GroupTransparency = 0
	else
		self.Page.GroupTransparency = 1
		Tween(self.Page, "Fast", { GroupTransparency = 0 })
	end
	self.Content.CanvasPosition = V2(0, 0)
	win:ApplyFilter(win._filterQuery)
end

function TabClass:_nextOrder()
	self._order += 1
	return self._order
end

function TabClass:_syncGridFrames()
	local frames = self._gridFrames
	if not frames then return end
	for i = #frames, 1, -1 do
		local frame = frames[i]
		if not frame.Parent then
			table.remove(frames, i)
		else
			local anyVisible = false
			local anyAlive = false
			for _, ch in ipairs(frame:GetChildren()) do
				if ch:IsA("GuiObject") and ch:GetAttribute("__el") then
					anyAlive = true
					if ch.Visible then
						anyVisible = true
						break
					end
				end
			end
			if not anyAlive then
				frame:Destroy()
				table.remove(frames, i)
			else
				frame.Visible = anyVisible
			end
		end
	end
end

function TabClass:_track(el)
	local opts = el._opts or {}
	local span = tonumber(opts.Span) or 1
	if span < 1 then
		span = 1
	end

	local section = self.CurrentSection
	local secCols = 1
	if section and not section._destroyed then
		secCols = tonumber(section.Columns) or 1
	end
	local cols = 0
	if secCols > 1 then
		cols = secCols
	else
		local wf = tonumber(opts.Width)
		if wf and wf > 0 and wf < 0.95 then
			local wc = floor(1 / wf + 0.34)
			if wc > 1 then
				cols = wc
			end
		end
	end
	if cols > 1 then
		if span > cols then
			span = cols
		end
		if not (self._autoRow and self._autoRow.Cols == cols) then
			self._autoRow = setmetatable({ Tab = self, Cols = cols }, GridRow)
			self._autoRow:_newFrame()
		end
		self._autoRow:Place(el, span)
	else
		self._autoRow = nil
		el.Row.LayoutOrder = self:_nextOrder()
	end

	self.Window:_introElement(el)

	local win, tab = self.Window, self
	el.Maid:Give(function()
		if win and not win._destroyed and win.CurrentTab == tab and not tab._destroyed then
			task.defer(function()
				if win and not win._destroyed and win.CurrentTab == tab then
					win:ApplyFilter(win._filterQuery)
				end
			end)
		end
	end)

	RefreshEmptySoon(win, tab)
	return el
end

function TabClass:Section(opts)
	if type(opts) == "string" then
		opts = { Name = opts }
	end
	opts = opts or {}
	self._autoRow = nil
	local section = Elements.Section.new(self, opts)
	section.Columns = clamp(floor(tonumber(opts and opts.Columns) or 1), 1, 6)
	section.IsSection = true
	section.Tab = self
	section.Row.LayoutOrder = self:_nextOrder()
	table.insert(self.Sections, section)
	self.CurrentSection = section

	self.Window:_introElement(section)

	local tab = self
	section.Maid:Give(function()
		RemoveValue(tab.Sections, section)
		if tab.CurrentSection == section then
			tab.CurrentSection = nil
		end
		if tab._gridFrames then
			tab:_syncGridFrames()
		end
	end)

	RefreshEmptySoon(self.Window, self)
	return section
end

for _, name in ipairs({
	"Button", "Toggle", "Slider", "Dropdown", "Keybind", "ColorPicker",
	"TextInput", "Label", "Paragraph", "Divider",
	"Stepper", "Segmented", "Vector3Input",
	}) do
	TabClass[name] = function(self, opts)
		return self:_track(Elements[name].new(self, opts or {}))
	end
end

function TabClass:ApplyFilter(query)
	local q = (query or ""):lower()
	local matches = 0

	for _, el in ipairs(self.Elements) do
		if not el._destroyed and el.Section == nil then
			local vis
			if q == "" then
				vis = el._manualVisible ~= false
			else
				vis = el.SearchText and el.SearchText:find(q, 1, true) ~= nil
			end
			el.Row.Visible = vis
			if vis and q ~= "" then
				matches += 1
			end
		end
	end

	for _, sec in ipairs(self.Sections) do
		if not sec._destroyed then
			local secMatch = q ~= "" and sec.Title:lower():find(q, 1, true) ~= nil
			local childMatch = 0
			for _, el in ipairs(sec.Elements) do
				if not el._destroyed then
					local vis
					if q == "" then
						vis = (el._manualVisible ~= false) and not sec.Collapsed
					else
						vis = (secMatch or (el.SearchText and el.SearchText:find(q, 1, true) ~= nil)) and not sec.Collapsed
					end
					el.Row.Visible = vis
					if vis and q ~= "" then
						childMatch += 1
					end
				end
			end
			local secVis
			if q == "" then
				secVis = sec._manualVisible ~= false
			else
				secVis = secMatch or childMatch > 0
			end
			sec.Row.Visible = secVis
			matches += childMatch
		end
	end

	self:_syncGridFrames()
	return matches
end

function TabClass:CountMatches(q)
	if not q or q == "" then return 0 end
	local n = 0
	for _, el in ipairs(self.Elements) do
		if not el._destroyed and el.SearchText and el.SearchText:find(q, 1, true) then
			n += 1
		end
	end
	for _, sec in ipairs(self.Sections) do
		if not sec._destroyed then
			if sec.Title:lower():find(q, 1, true) then
				n += 1
			end
			for _, el in ipairs(sec.Elements) do
				if not el._destroyed and el.SearchText and el.SearchText:find(q, 1, true) then
					n += 1
				end
			end
		end
	end
	return n
end

function TabClass:SetFilterBadge(text)
	if text and text ~= "" then
		self.Badge.Text = text
		self.Badge.Visible = true
	else
		self.Badge.Visible = false
	end
end

function TabClass:GetSaveKey(opts)
	opts = opts or {}
	if opts.SaveKey == false then
		return nil
	end
	local el = tostring(opts.SaveKey or opts.Name or opts.Title or "Element")
	local base = self.Window.SavePrefix .. "/" .. self.Title .. "/" .. el
	local seen = self._saveKeys
	local n = (seen[base] or 0) + 1
	seen[base] = n
	if n > 1 then
		return base .. " #" .. n
	end
	return base
end

local function BuildSettingsTab(win)
	local tab = win:Tab({ Title = "Settings", Icon = "Gear" })

	local function Note(t, x, ty, d)
		Kailex:Notify({ Title = t, Text = x, Type = ty, Duration = d })
	end

	local pickers = {}
	local editing = table.clone(CurrentTheme.Base)

	local function syncPickers()
		for k, cp in pairs(pickers) do
			cp:Set(editing[k], true)
		end
	end

	local function resetDefaults(b)
		for k, cp in pairs(pickers) do
			cp:SetDefault(b[k])
		end
	end

	local function applyColors(persist)
		ApplyTheme(DeriveTheme(editing))
		if not persist then return end
		local b = BaseColors()
		if editing.Background == b.Background and editing.Surface == b.Surface
			and editing.Text == b.Text and editing.Accent == b.Accent then
			SaveManager:Set("__customColors", nil)
		else
			SaveManager:Set("__customColors", {
				Background = ColorToHex(editing.Background),
				Surface = ColorToHex(editing.Surface),
				Text = ColorToHex(editing.Text),
				Accent = ColorToHex(editing.Accent),
			})
		end
	end

	tab:Section("Appearance")
	local themeDrop = tab:Dropdown({
		Name = "Theme",
		SaveKey = false,
		Options = Kailex:GetThemes(),
		Callback = function(name)
			local th = Themes[tostring(name)]
			if not th then return end
			Setting.Theme = tostring(name)
			CustomBase = nil
			SaveManager:Set("__theme", Setting.Theme)
			SaveManager:Set("__customColors", nil)
			ApplyTheme(th)
			editing = table.clone(th.Base)
			resetDefaults(th.Base)
			syncPickers()
		end,
	})
	themeDrop:Set(Themes[Setting.Theme] and Setting.Theme or "Dark-Blue", true)

	tab:Slider({
		Name = "UI Scale",
		Min = 0.8, Max = 1.3,
		Default = tonumber(Setting.UIScale) or 1,
		Increment = 0.05,
		FireOnRelease = true,
		Callback = function(v)
			Setting.UIScale = v
			SaveManager:Set("__scale", v)
			UpdateViewport()
		end,
	})
	tab:Slider({
		Name = "Text Size",
		Min = 0.85, Max = 1.4,
		Default = tonumber(Setting.TextScale) or 1.1,
		Increment = 0.05,
		Callback = function(v)
			Setting.TextScale = v
			ApplyTextScale()
			SaveManager:Set("__textScale", v)
		end,
	})
	tab:Slider({
		Name = "Animation Speed",
		Min = 0.2, Max = 1,
		Default = tonumber(Setting.MotionScale) or 1,
		Increment = 0.05,
		Callback = function(v)
			Setting.MotionScale = v
			SaveManager:Set("__motion", v)
		end,
	})

	tab:Section({ Name = "Colors", Columns = 2 })
	local baseNow = BaseColors()
	for _, key in ipairs({ "Background", "Surface", "Text", "Accent" }) do
		local cp = tab:ColorPicker({
			Name = key,
			SaveKey = false,
			Callback = function(c)
				editing[key] = c
				applyColors(true)
			end,
		})
		cp:SetDefault(baseNow[key])
		pickers[key] = cp
	end
	syncPickers()
	tab:Button({
		Name = "Reset Colors",
		Span = 2,
		Callback = function()
			local b = BaseColors()
			editing = table.clone(b)
			resetDefaults(b)
			syncPickers()
			applyColors(true)
			Note("Colors", "Colors reset to default.", "Success")
		end,
	})

	tab:Section("Behavior")
	tab:Toggle({
		Name = "Interface Sounds",
		Description = "Click and hover sound effects",
		Default = Setting.Sounds == true,
		Callback = function(v)
			Setting.Sounds = v
			SaveManager:Set("__sounds", v)
		end,
	})
	tab:Toggle({
		Name = "Visual Effects",
		Description = "Ripple effects on click",
		Default = Setting.Effects ~= false,
		Callback = function(v)
			Setting.Effects = v
			SaveManager:Set("__effects", v)
		end,
	})
	tab:Keybind({
		Name = "Show / Hide UI",
		Default = Setting.ToggleUIKey,
		Callback = function(code)
			Setting.ToggleUIKey = code
			SaveManager:Set("__toggleKey", code and ("Key:" .. code.Name) or "__none")
		end,
	})

	tab:Section("Profiles")
	local nameInput = tab:TextInput({ Name = "Profile name", Placeholder = "My config" })
	local profDrop = tab:Dropdown({ Name = "Profile", Options = Configs:List() })
	local function refreshProfiles()
		profDrop:SetOptions(Configs:List())
	end
	tab:Button({
		Name = "Save profile",
		Callback = function()
			local n = nameInput:Get()
			if n == "" then
				Note("Profiles", "Enter a profile name first.", "Warning")
				return
			end
			SaveManager:Flush()
			if Configs:Save(n) then
				refreshProfiles()
				profDrop:Set(n, true)
				Note("Profiles", "Saved \"" .. n .. "\".", "Success")
			else
				Note("Profiles", "Saving files is not supported here.", "Error")
			end
		end,
	})
	tab:Button({
		Name = "Load profile",
		Callback = function()
			local n = profDrop:Get()
			if not n then return end
			if Configs:Load(n) then
				Note("Profiles", "Loaded \"" .. n .. "\".", "Success")
			else
				Note("Profiles", "Could not load that profile.", "Error")
			end
		end,
	})
	tab:Button({
		Name = "Delete profile",
		Callback = function()
			local n = profDrop:Get()
			if not n then return end
			Kailex:Confirm({
				Title = "Delete profile?",
				Text = "This permanently removes \"" .. n .. "\".",
			}, function()
				Configs:Delete(n)
				refreshProfiles()
				Note("Profiles", "Deleted \"" .. n .. "\".")
			end)
		end,
	})

	tab:Section("About")
	tab:Paragraph({
		Title = "Kailex UI",
		Text = "Device: " .. (Device.IsTouch and "Mobile" or (Device.IsConsole and "Console" or "Desktop"))
			.. " | Files: " .. (HasFileSystem and "available" or "unavailable"),
	})
	tab:Button({
		Name = "Reset all settings",
		Callback = function()
			Kailex:Confirm({
				Title = "Reset everything?",
				Text = "All saved values and themes will be cleared. Re-execute the script after.",
			}, function()
				local backup = table.clone(SaveManager.Data)
				SaveManager:Clear()
				Kailex:Notify({
					Title = "Settings",
					Text = "Cleared. Re-execute the script.",
					Type = "Success",
					Duration = 10,
					Actions = {
						{
							Text = "Undo",
							Callback = function()
								SaveManager.Data = backup
								SaveManager:Flush()
								SaveManager.DataChanged:Fire()
								Note("Settings", "Reset undone - previous settings restored.", "Success", 4)
							end,
						},
					},
				})
			end)
		end,
	})
	return tab
end

local IntroReveal

do
	local function Scan(inst, list)
		if inst:IsA("GuiObject") then
			if inst.BackgroundTransparency < 0.995 then
				list[#list + 1] = { inst, "BackgroundTransparency", inst.BackgroundTransparency, 0 }
				inst.BackgroundTransparency = 1
			end
			if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
				if inst.TextTransparency < 0.995 then
					list[#list + 1] = { inst, "TextTransparency", inst.TextTransparency, 0 }
					inst.TextTransparency = 1
				end
			elseif inst:IsA("ImageLabel") then
				if inst.ImageTransparency < 0.995 then
					list[#list + 1] = { inst, "ImageTransparency", inst.ImageTransparency, 0 }
					inst.ImageTransparency = 1
				end
			end
		elseif inst:IsA("UIStroke") then
			if inst.Transparency < 0.995 then
				list[#list + 1] = { inst, "Transparency", inst.Transparency, 0 }
				inst.Transparency = 1
			end
		end
	end

	function IntroReveal(target, delay, cfg)
		if not target or not target.Parent then return end
		cfg = cfg or {}
		local list = {}
		Scan(target, list)
		for _, d in ipairs(target:GetDescendants()) do
			Scan(d, list)
		end

		local slides = {}
		if cfg.SelfX or cfg.SelfY then
			slides[#slides + 1] = { target, target.Position }
			target.Position = target.Position + UO(cfg.SelfX or 0, cfg.SelfY or 0)
		end

		local pad, padBase
		if cfg.Rise then
			pad = target:FindFirstChildOfClass("UIPadding")
			if pad then
				padBase = pad.PaddingTop
				pad.PaddingTop = UD(padBase.Scale, padBase.Offset + cfg.Rise)
			end
		end

		if cfg.Cascade then
			local slots = {}
			local idx = 0
			for _, ch in ipairs(target:GetChildren()) do
				if ch:IsA("GuiObject")
					and not (ch:IsA("TextButton") and ch.Text == "" and ch.BackgroundTransparency > 0.99) then
					idx += 1
					slots[ch] = idx * cfg.Cascade
				end
			end
			for _, f in ipairs(list) do
				local p = f[1]
				while p and p ~= target do
					local d = slots[p]
					if d then
						f[4] = d
						break
					end
					p = p.Parent
				end
			end
		end

		local preset = cfg.Preset or "Reveal"
		for _, f in ipairs(list) do
			Tween(f[1], preset, { [f[2]] = f[3] }, nil, delay + f[4])
		end
		if pad then
			Tween(pad, preset, { PaddingTop = padBase }, nil, delay)
		end
		for _, s in ipairs(slides) do
			Tween(s[1], preset, { Position = s[2] }, nil, delay)
		end
	end
end

local function IntroTab(tab, delay)
	local btn = tab.TabButton
	local bar = tab.Bar
	local label = tab.TabLabel
	local icon = tab.IconImg
	btn.BackgroundTransparency = 1
	bar.BackgroundTransparency = 1
	label.TextTransparency = 1
	local extra = {}
	if icon then
		if icon:IsA("ImageLabel") then
			icon.ImageTransparency = 1
			extra[#extra + 1] = { icon, "ImageTransparency" }
		else
			for _, d in ipairs(icon:GetDescendants()) do
				if d:IsA("GuiObject") and d.BackgroundTransparency < 0.995 then
					d.BackgroundTransparency = 1
					extra[#extra + 1] = { d, "BackgroundTransparency" }
				elseif d:IsA("UIStroke") and d.Transparency < 0.995 then
					d.Transparency = 1
					extra[#extra + 1] = { d, "Transparency" }
				end
			end
		end
	end
	local slides = {}
	for _, ch in ipairs(btn:GetChildren()) do
		if ch:IsA("GuiObject") then
			slides[#slides + 1] = { ch, ch.Position }
			ch.Position = ch.Position + UO(-12, 0)
		end
	end
	task.delay(delay * (tonumber(Setting.MotionScale) or 1), function()
		if not btn.Parent then return end
		local sel = tab._selected == true
		Tween(btn, "Reveal", { BackgroundTransparency = sel and 0 or 1 })
		Tween(bar, "Reveal", { BackgroundTransparency = sel and 0 or 1 })
		Tween(label, "Reveal", { TextTransparency = 0 })
		for _, h in ipairs(extra) do
			Tween(h[1], "Reveal", { [h[2]] = 0 })
		end
		for _, s in ipairs(slides) do
			Tween(s[1], "Reveal", { Position = s[2] })
		end
	end)
end

local Window = {}
Window.__index = Window

function Kailex:Window(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Window)
	self.Title = tostring(cfg.Title or cfg.Name or "Kailex")
	self.SubTitle = cfg.SubTitle
	self.SavePrefix = tostring(cfg.SaveKey or cfg.SavePrefix or self.Title)
	self._destroyed = false
	self._filterQuery = ""
	self.Tabs = {}
	self.CurrentTab = nil
	self.Minimized = false
	self.Maximized = false
	self.MinimizedChanged = Signal.new()
	self.Closed = Signal.new()
	self._hidden = false
	self.ToggleKey = ParseKey(cfg.ToggleKey)
	self._remember = cfg.RememberPosition ~= false

	if type(cfg.Theme) == "table" then
		local t = DeriveTheme(cfg.Theme)
		CustomBase = t.Base
		ApplyTheme(t)
	elseif type(cfg.Theme) == "string" then
		local th = Themes[cfg.Theme]
		if th then
			Setting.Theme = cfg.Theme
			CustomBase = nil
			ApplyTheme(th)
		end
	end

	local MIN_W, MIN_H = 380, 280
	local defW, defH = 580, 420

	local s = GetScale()
	local vw, vh = Viewport.X / s, Viewport.Y / s
	if Device.IsTouch then
		defW = math.min(defW, vw - 16)
		defH = math.min(defH, vh - 16)
	end
	defW = clamp(defW, math.min(MIN_W, vw - 12), vw - 12)
	defH = clamp(defH, math.min(MIN_H, vh - 12), vh - 12)

	local px, py
	if self._remember then
		local sp = SaveManager:Get("__win:" .. self.SavePrefix, nil)
		if type(sp) == "table" then
			local sx, sy, sw, sh = tonumber(sp.X), tonumber(sp.Y), tonumber(sp.W), tonumber(sp.H)
			if sx and sy and sw and sh then
				defW = clamp(sw, math.min(MIN_W, vw - 12), vw - 12)
				defH = clamp(sh, math.min(MIN_H, vh - 12), vh - 12)
				px = ClampEdge(sx, defW, vw, 8)
				py = ClampEdge(sy, defH, vh, 8)
			end
		end
	end
	if not px then
		if #Kailex.Windows == 0 then
			px = math.max(8, floor((vw - defW) / 2 + 0.5))
			py = math.max(8, floor((vh - defH) / 2 + 0.5))
		else
			local n = #Kailex.Windows % 5
			px, py = 40 + n * 28, 34 + n * 24
		end
	end

	self.Root = Grp({
		Position = UO(px, py),
		Size = UO(defW, defH),
		BackgroundColor3 = "Background",
		ClipsDescendants = true,
		GroupTransparency = 1,
		Parent = LayerWindows,
	})
	self._rootCorner = Corner(14, self.Root)
	self._rootStroke = Bind(Create("UIStroke", {
		Thickness = 1, Transparency = 0.35, ApplyStrokeMode = SB, Parent = self.Root,
	}), "Color", "Stroke")
	self._winScale = UISC(self.Root, 0.94)

	self.Maid = Maid.new()
	self.Maid:Link(self.Root)

	local TITLE_FINAL = UN(0, 0, 0, 0)
	local BODY_FINAL = UN(0, 0, 0, 56)

	local titleBar = Frm({
		Position = TITLE_FINAL,
		Size = UN(1, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = self.Root,
	})
	self.TitleBar = titleBar

	local body = Frm({
		Position = BODY_FINAL,
		Size = UN(1, 0, 1, -46),
		BackgroundTransparency = 1,
		Parent = self.Root,
	})
	self.Body = body

	local dim

	local function killDim()
		if dim then
			local d = dim
			dim = nil
			Tween(d, "Smooth", { BackgroundTransparency = 1 }, function()
				d:Destroy()
			end)
		end
	end

	local function RestoreGeom()
		self._introActive = false
		if self.Root.AnchorPoint ~= V2(0, 0) then
			self.Root.AnchorPoint = V2(0, 0)
			self.Root.Position = UO(px, py)
		end
	end

	local function KillIntroMotion()
		if not self._introActive then return end
		RestoreGeom()
		Tween(self.Root, "Instant", { GroupTransparency = 0 })
		Tween(self._winScale, "Instant", { Scale = 1 })
		Tween(self._rootCorner, "Instant", { CornerRadius = UD(0, 14) })
		Tween(self._rootStroke, "Instant", { Transparency = 0.35 })
		Tween(titleBar, "Instant", { Position = TITLE_FINAL })
		killDim()
	end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == EUT.MouseButton1
			or input.UserInputType == EUT.Touch then
			KillIntroMotion()
		end
	end)

	MakeDraggable(titleBar, self.Root, {
		Clamp = true,
		OnDragStart = function(root)
			if not self.Maximized then return end
			self.Maximized = false
			self.ResizeGrip.Visible = true
			Tween(root, "Instant", { Size = root.Size, Position = root.Position })
			if self._restore then
				local sc = GetScale()
				local m = UIS:GetMouseLocation()
				local ap = root.AbsolutePosition
				local oldW = root.AbsoluteSize.X
				local newW = self._restore.Size.X.Offset
				local newH = self._restore.Size.Y.Offset
				local frac = oldW > 1 and clamp((m.X - ap.X) / oldW, 0.12, 0.88) or 0.5
				local nx = ClampEdge(m.X / sc - frac * newW, newW, Viewport.X / sc, 8)
				local ny = ClampEdge(ap.Y / sc, newH, Viewport.Y / sc, 8)
				root.Size = self._restore.Size
				root.Position = UO(nx, ny)
			end
		end,
		OnEnd = function()
			self:SavePlacement()
		end,
	})

	local titleLabel = U.Txt(titleBar, {
		Pos = UO(14, 7),
		Size = UN(1, -130, 0, 20),
		Font = EF.GothamBold,
		Ts = 15,
		Align = ETA.Left,
		Trunc = true,
		Text = self.Title,
	})
	local subLabel = U.Txt(titleBar, {
		Pos = UO(14, 26),
		Size = UN(1, -130, 0, 14),
		Ts = 11,
		Color = "SubText",
		Align = ETA.Left,
		Trunc = true,
		Text = tostring(cfg.SubTitle or ""),
	})

	local searchBox = U.TxB(titleBar, {
		Pos = UO(14, 11),
		Size = UN(0, 220, 0, 24),
		Trans = 1,
		Visible = false,
		Ts = 12,
		Ph = "Search ...",
		Align = ETA.Left,
	})

	local searchLine = Frm({
		Position = UO(14, 35),
		Size = UN(0, 0, 0, 1),
		BackgroundColor3 = "Accent",
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = titleBar,
	})

	searchBox.ClipsDescendants = true
	local searchActive = false
	local searchDebounce = nil
	local setSearch

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = searchBox.Text
		if searchDebounce then
			pcall(task.cancel, searchDebounce)
		end
		if text == "" then
			self._filterQuery = ""
			self:ApplyFilter("")
			return
		end
		searchDebounce = task.delay(0.15, function()
			self._filterQuery = text
			self:ApplyFilter(text)
		end)
	end)
	searchBox.FocusLost:Connect(function(enter)
		if not enter and searchBox.Text == "" then
			setSearch(false)
		end
	end)

	function setSearch(on)
		if searchActive == on then return end
		searchActive = on
		if on then
			searchBox.Visible = true
			searchLine.Visible = true
			titleLabel.Visible = false
			subLabel.Visible = false
			searchBox.Text = ""
			self._filterQuery = ""
			self:ApplyFilter("")
			searchBox.Size = UN(0, 0, 0, 24)
			searchLine.Size = UN(0, 0, 0, 1)
			Tween(searchBox, "Snappy", { Size = UN(0, 220, 0, 24) }, function()
				if searchActive then
					pcall(function()
						searchBox:CaptureFocus()
					end)
				end
			end)
			Tween(searchLine, "Snappy", { Size = UN(0, 220, 0, 1) })
		else
			pcall(function()
				searchBox:ReleaseFocus()
			end)
			Tween(searchBox, "Fast", { Size = UN(0, 0, 0, 24) }, function()
				if not searchActive then
					searchBox.Visible = false
					searchLine.Visible = false
					titleLabel.Visible = true
					subLabel.Visible = true
				end
			end)
			Tween(searchLine, "Fast", { Size = UN(0, 0, 0, 1) })
			self._filterQuery = ""
			self:ApplyFilter("")
		end
	end

	self.Maid:Give(UIS.InputBegan:Connect(function(input, gp)
		if not searchActive then return end
		if input.KeyCode ~= EKC.Escape then return end
		if gp and UIS:GetFocusedTextBox() ~= searchBox then return end
		setSearch(false)
	end))

	local function titleButton(kind, xPos, colorKey)
		local b = Hit({
			AnchorPoint = V2(1, 0.5),
			Position = UN(1, xPos, 0.5, 0),
			Size = UO(28, 28),
			BackgroundColor3 = "Element",
			Parent = titleBar,
		})
		Icon(b, kind, colorKey or "SubText", 12)
		return b
	end

	local closeB = titleButton("Close", -10, "Text")
	closeB.MouseEnter:Connect(function()
		Tween(closeB, "Fast", { BackgroundColor3 = CurrentTheme.Error, BackgroundTransparency = 0.15 })
	end)
	closeB.MouseLeave:Connect(function()
		Tween(closeB, "Fast", { BackgroundTransparency = 1 })
	end)
	Click(self.Maid, closeB, function()
		PlaySound("Click", 0.5)
		self:Close()
	end)

	local minB = titleButton("Minimize", -44)
	AddHover(minB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
	Click(self.Maid, minB, function()
		PlaySound("Click", 0.5)
		self:SetMinimized(true)
	end)

	local searchB = titleButton("Search", -78)
	AddHover(searchB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
	Click(self.Maid, searchB, function()
		PlaySound("Click", 0.5)
		setSearch(not searchActive)
	end)

	local _titleButtons = { searchB, minB, closeB }

	self._sidebarWidth = clamp(tonumber(SaveManager:Get("__sidebarWidth", 152)) or 152, 110, 320)

	local sidebar = Frm({
		Size = UN(0, self._sidebarWidth, 1, 0),
		BackgroundColor3 = "TabBar",
		Parent = body,
	})
	StrokeBind(1, "Stroke", 0.55, sidebar)
	self.Sidebar = sidebar

	self.TabList = Scr({
		Position = UO(6, 6),
		Size = UN(1, -12, 1, -12),
		Parent = sidebar,
		Children = {
			List(4),
			Frm({
				Name = "__BottomSpacer",
				BackgroundTransparency = 1,
				Size = UN(0, 0, 0, 8),
				LayoutOrder = 1000000000,
			}),
		},
	})
	Bind(self.TabList, "ScrollBarImageColor3", "Stroke")

	self.Pages = Frm({
		Position = UO(self._sidebarWidth, 0),
		Size = UN(1, -self._sidebarWidth, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	self.EmptyLabel = U.Txt(self.Pages, {
		Ap = V2(0.5, 0.5),
		Pos = US(0.5, 0.5),
		Size = UO(240, 40),
		Ts = 12,
		Color = "SubText",
		Wrap = true,
		Text = "",
		Visible = false,
		Z = 5,
	})

	local splitter = Hit({
		Position = UN(0, self._sidebarWidth - 4, 0, 0),
		Size = UN(0, 9, 1, 0),
		ZIndex = 4,
		Parent = body,
	})
	self.Splitter = splitter
	Frm({
		AnchorPoint = V2(0.5, 0),
		Position = US(0.5, 0, 0, 10),
		Size = UN(0, 1, 1, -20),
		BackgroundColor3 = "Stroke",
		BackgroundTransparency = 0.5,
		Parent = splitter,
	})

	TrackInput(splitter, {
		Guard = function()
			return not self.Minimized
		end,
		Active = splitter,
		Start = function()
			KillIntroMotion()
			ModalManager.CloseAll(self)
		end,
		Step = function()
			local m = UIS:GetMouseLocation()
			local sc = GetScale()
			local rel = (m.X - body.AbsolutePosition.X) / sc + 4
			self:SetSidebarWidth(rel)
		end,
		End = function()
			SaveManager:Set("__sidebarWidth", self._sidebarWidth)
		end,
	})

	local grip = Hit({
		AnchorPoint = V2(1, 1),
		Position = UN(1, -3, 1, -3),
		Size = UO(18, 18),
		Parent = self.Root,
	})
	Icon(grip, "Grip", "SubText", 12)
	self.ResizeGrip = grip

	TrackInput(grip, {
		Guard = function()
			return not self.Maximized and not self.Minimized
		end,
		Active = grip,
		Start = function(state)
			KillIntroMotion()
			ModalManager.CloseAll(self)
			state.StartMouse = UIS:GetMouseLocation()
			state.StartSize = V2(self.Root.Size.X.Offset, self.Root.Size.Y.Offset)
		end,
		Step = function(state)
			local m = UIS:GetMouseLocation()
			local sc = GetScale()
			local vw2, vh2 = Viewport.X / sc, Viewport.Y / sc
			local minW = math.min(MIN_W, math.max(200, vw2 - 12))
			local minH = math.min(MIN_H, math.max(160, vh2 - 12))
			local w = clamp(state.StartSize.X + (m.X - state.StartMouse.X) / sc, minW, math.max(minW, vw2 - 8))
			local h = clamp(state.StartSize.Y + (m.Y - state.StartMouse.Y) / sc, minH, math.max(minH, vh2 - 8))
			self.Root.Size = UO(w, h)
		end,
		End = function()
			ClampToScreen(self.Root)
			self:SavePlacement()
		end,
	})

	local function BringToFront()
		local z = 20
		for _, w in ipairs(Kailex.Windows) do
			if w ~= self and w.Root and w.Root.ZIndex > z then
				z = w.Root.ZIndex
			end
		end
		self.Root.ZIndex = z + 1
	end

	local lastClick = 0
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= EUT.MouseButton1
			and input.UserInputType ~= EUT.Touch then return end
		BringToFront()
		if Device.IsTouch then return end
		local now = os.clock()
		if now - lastClick < 0.3 then
			lastClick = 0
			self:SetMaximized(not self.Maximized)
		else
			lastClick = now
		end
	end)

	local expandIcon = Icon(self.Root, "Chevron", "SubText", 12)
	expandIcon.Rotation = 180
	expandIcon.Visible = false

	local pillHit = U.Overlay(self.Root, 60, false)
	MakeDraggable(pillHit, self.Root, { Clamp = true })
	Click(self.Maid, pillHit, function()
		if pillHit:GetAttribute("Dragging") then return end
		BringToFront()
		PlaySound("Click", 0.6)
		self:SetMinimized(false)
	end)

	function self:SetTitle(t)
		self.Title = tostring(t or "")
		titleLabel.Text = self.Title
	end

	local function applySidebarGeom(horizontal, multi)
		local w = self.Root.Size.X.Offset
		local maxSw = math.max(110, math.min(320, w - 240))
		local sw = clamp(self._sidebarWidth or 152, 110, maxSw)
		if not multi then
			self.Sidebar.Visible = false
			self.Splitter.Visible = false
			self.Pages.Position = UO(0, 0)
			self.Pages.Size = US(1, 1)
		elseif horizontal then
			self.Sidebar.Visible = true
			self.Splitter.Visible = false
			self.Sidebar.Size = UN(1, 0, 0, 44)
			self.TabList.Size = UN(1, -12, 0, 32)
			self.TabList.ScrollingDirection = ESD.X
			self.TabList.AutomaticCanvasSize = AS.X
			self.Pages.Position = UO(0, 44)
			self.Pages.Size = UN(1, 0, 1, -44)
		else
			self.Sidebar.Visible = true
			self.Splitter.Visible = true
			self.Sidebar.Size = UN(0, sw, 1, 0)
			self.TabList.Size = UN(1, -12, 1, -12)
			self.TabList.ScrollingDirection = ESD.Y
			self.TabList.AutomaticCanvasSize = AS.Y
			self.Pages.Position = UO(sw, 0)
			self.Pages.Size = UN(1, -sw, 1, 0)
			self.Splitter.Position = UN(0, sw - 4, 0, 0)
		end
	end

	function self:SetSidebarWidth(w)
		w = tonumber(w)
		if not w then return end
		local maxSw = math.max(110, math.min(320, self.Root.Size.X.Offset - 240))
		w = floor(clamp(w, 110, maxSw) + 0.5)
		if w == self._sidebarWidth then return end
		self._sidebarWidth = w
		applySidebarGeom(self._lastHorizontal == true, #self.Tabs > 1)
	end

	function self:UpdateLayout()
		if self._destroyed or self._layoutQueued then return end
		self._layoutQueued = true
		task.defer(function()
			self._layoutQueued = false
			if self._destroyed then return end
			local w = self.Root.Size.X.Offset
			local multi = #self.Tabs > 1
			local horizontal = multi and w < 500
			local maxSw = math.max(110, math.min(320, w - 240))
			local sw = clamp(self._sidebarWidth or 152, 110, maxSw)
			local changed = (horizontal ~= self._lastHorizontal)
				or (multi ~= self._lastMulti)
				or (sw ~= self._lastSw)
			self._lastHorizontal = horizontal
			self._lastMulti = multi
			self._lastSw = sw
			if changed then
				applySidebarGeom(horizontal, multi)
				for _, tab in ipairs(self.Tabs) do
					tab:_setHorizontal(horizontal)
				end
			end
		end)
	end

	self.Maid:Give(self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:UpdateLayout()
	end))

	function self:ApplyFilter(q)
		self._filterQuery = q or ""
		local tab = self.CurrentTab
		if not tab then return end
		local n = tab:ApplyFilter(self._filterQuery)
		for _, t in ipairs(self.Tabs) do
			if t ~= tab and not t._destroyed then
				local c = t:CountMatches(self._filterQuery)
				t:SetFilterBadge(c > 0 and tostring(c) or "")
			else
				t:SetFilterBadge("")
			end
		end
		local shouldShow, txt = false, ""
		if self._filterQuery ~= "" then
			txt = "No results for \"" .. self._filterQuery .. "\""
			shouldShow = (n == 0)
		elseif #tab.Elements == 0 and #tab.Sections == 0 then
			txt = "This tab is empty"
			shouldShow = true
		end
		local el = self.EmptyLabel
		if shouldShow then
			el.Text = txt
			if not el.Visible then
				el.Visible = true
				el.TextTransparency = 1
				Tween(el, "Fast", { TextTransparency = 0 })
			end
		else
			el.Visible = false
		end
	end

	function self:_introElement(el)
		if self._destroyed or el._destroyed or not el.Row then return end
		local elapsed = os.clock() - self._introT0
		if elapsed > 2 then return end
		local n = self._introN + 1
		self._introN = n
		IntroReveal(el.Row, math.max(0.02, 0.62 + math.min(n * 0.035, 0.3) - elapsed), { Rise = 10, Cascade = 0.045 })
	end

	function self:Tab(tabOpts)
		local tab = TabClass.new(self, tabOpts)
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then
			tab:Select(true)
		end
		self:UpdateLayout()
		local elapsed = os.clock() - self._introT0
		if elapsed < 2 then
			IntroTab(tab, math.max(0.03, 0.5 + math.min((#self.Tabs - 1) * 0.05, 0.3) - elapsed))
		else
			IntroTab(tab, 0.04)
		end
		return tab
	end

	function self:_closeDropdowns()
		for _, tab in ipairs(self.Tabs) do
			if tab._openDropdown then
				local fn = tab._openDropdown
				tab._openDropdown = nil
				fn()
			end
		end
	end

	function self:SetMinimized(state)
		if self._destroyed or self.Minimized == state then return end
		self.Minimized = state
		self.MinimizedChanged:Fire(state)
		KillIntroMotion()
		Tween(self._winScale, "Snappy", { Scale = 0.97 }, function()
			if not self._destroyed then
				Tween(self._winScale, "PopSoft", { Scale = 1 })
			end
		end)
		if state then
			ModalManager.CloseAll(self)
			if self.Maximized then
				self.Maximized = false
				if self._restore then
					self.Root.Size = self._restore.Size
					self.Root.Position = UO(self._restore.X, self._restore.Y)
				end
			end
			self._preMin = { Size = self.Root.Size, Position = self.Root.Position }
			self.Body.Visible = false
			self.ResizeGrip.Visible = false
			subLabel.Visible = false
			titleLabel.Size = UN(1, -44, 0, 20)
			for _, b in ipairs(_titleButtons) do
				b.Visible = false
			end
			expandIcon.Visible = true
			expandIcon.Size = UO(8, 8)
			Tween(expandIcon, "Pop", { Size = UO(12, 12) })
			pillHit.Visible = true
			if searchActive then
				setSearch(false)
			end
			local tw = TextService:GetTextSize(self.Title, TS(15), EF.GothamBold, V2(10000, 100)).X
			Tween(self.Root, "Smooth", { Size = UO(tw + 74, 38) })
		else
			pillHit.Visible = false
			expandIcon.Visible = false
			for _, b in ipairs(_titleButtons) do
				b.Visible = true
			end
			subLabel.Visible = true
			titleLabel.Size = UN(1, -130, 0, 20)
			Tween(self.Root, "Smooth", { Size = self._preMin and self._preMin.Size or UO(580, 420) }, function()
				if not self._destroyed and not self.Minimized then
					self.Body.Visible = true
					self.ResizeGrip.Visible = not self.Maximized
					ClampToScreen(self.Root)
				end
			end)
		end
	end

	function self:SetMaximized(on)
		if self._destroyed or self.Minimized then return end
		KillIntroMotion()
		if on then
			local sp = V2(self.Root.Position.X.Offset, self.Root.Position.Y.Offset)
			self._restore = { Size = self.Root.Size, X = sp.X, Y = sp.Y }
			self.Maximized = true
			self.ResizeGrip.Visible = false
			local vw2, vh2 = Viewport.X / GetScale(), Viewport.Y / GetScale()
			Tween(self.Root, "Smooth", {
				Size = UO(vw2 - 16, vh2 - 16),
				Position = UO(8, 8),
			})
		else
			self.Maximized = false
			self.ResizeGrip.Visible = true
			if self._restore then
				Tween(self.Root, "Smooth", {
					Size = self._restore.Size,
					Position = UO(self._restore.X, self._restore.Y),
				}, function()
					if not self._destroyed and not self.Maximized then
						ClampToScreen(self.Root)
					end
				end)
			end
		end
	end

	function self:SavePlacement()
		if self._destroyed or self.Minimized or self.Maximized or self._hidden then return end
		if not self._remember then return end
		SaveManager:Set("__win:" .. self.SavePrefix, {
			X = floor(self.Root.Position.X.Offset + 0.5),
			Y = floor(self.Root.Position.Y.Offset + 0.5),
			W = floor(self.Root.Size.X.Offset + 0.5),
			H = floor(self.Root.Size.Y.Offset + 0.5),
		})
	end

	function self:ToggleHidden()
		if self._destroyed then return end
		self._hidden = not self._hidden
		if self._hidden then
			ModalManager.CloseAll(self)
			self.Root.Visible = false
		else
			self.Root.Visible = true
			BringToFront()
		end
	end

	function self:OnViewport()
		if self._destroyed then return end
		KillIntroMotion()
		if self.Minimized then
			ClampToScreen(self.Root)
			return
		end
		ModalManager.CloseAll(self)
		local sc = GetScale()
		local vw2, vh2 = Viewport.X / sc, Viewport.Y / sc
		local minW = math.min(MIN_W, math.max(200, vw2 - 12))
		local minH = math.min(MIN_H, math.max(160, vh2 - 12))
		if self.Maximized then
			self.Root.Size = UO(vw2 - 16, vh2 - 16)
			self.Root.Position = UO(8, 8)
		else
			local w = clamp(self.Root.Size.X.Offset, minW, math.max(minW, vw2 - 12))
			local h = clamp(self.Root.Size.Y.Offset, minH, math.max(minH, vh2 - 12))
			self.Root.Size = UO(w, h)
			ClampToScreen(self.Root)
		end
		self:UpdateLayout()
	end

	function self:Close(skipConfirm)
		if self._destroyed then return end
		if not skipConfirm then
			Kailex:Confirm({
				Title = "Close " .. self.Title .. "?",
				Text = "Are you sure you want to close this window?",
			}, function()
				self:Destroy()
			end)
			return
		end
		self:Destroy()
	end

	function self:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		KillIntroMotion()
		self:SavePlacement()
		self.Closed:Fire()
		RemoveValue(Kailex.Windows, self)
		ModalManager.CloseAll(self)
		local root = self.Root
		local done = false
		local function finish()
			if done then return end
			done = true
			self.Maid:Destroy()
			if root.Parent then
				root:Destroy()
			end
		end
		Once(root.Destroying, finish)
		task.delay(0.3, finish)
		Tween(self._winScale, "Vanish", { Scale = 0.96 })
		Tween(root, "Vanish", { Position = root.Position + UO(0, -10) })
		Tween(root, "Vanish", { GroupTransparency = 1 }, finish)
	end

	table.insert(Kailex.Windows, self)
	applySidebarGeom(#self.Tabs > 1, false)

	do
		if #Kailex.Windows == 1 then
			dim = Frm({
				Size = US(1, 1),
				BackgroundColor3 = CN(0, 0, 0),
				BackgroundTransparency = 1,
				ZIndex = 0,
				Parent = LayerWindows,
			})
			Tween(dim, "Smooth", { BackgroundTransparency = 0.5 })
			task.delay(1.1 * (tonumber(Setting.MotionScale) or 1), killDim)
		end

		self._introActive = true
		self._introT0 = os.clock()
		self._introN = 0

		self.Root.AnchorPoint = V2(0.5, 0.5)
		self.Root.Position = UO(px + defW / 2, py + defH / 2)
		self._winScale.Scale = 0.5
		self.Root.GroupTransparency = 1
		self._rootCorner.CornerRadius = UD(0, 26)
		self._rootStroke.Transparency = 1

		Tween(self.Root, TI(0.22, E.Quint, ED.Out), { GroupTransparency = 0 })
		Tween(self._winScale, TI(0.5, E.Back, ED.Out), { Scale = 1 }, RestoreGeom)
		Tween(self._rootCorner, TI(0.42, E.Quint, ED.Out), { CornerRadius = UD(0, 14) }, nil, 0.05)
		Tween(self._rootStroke, TI(0.32, E.Quint, ED.Out), { Transparency = 0.35 }, nil, 0.1)

		titleBar.Position = UN(0, 0, 0, -46)
		Tween(titleBar, TI(0.38, E.Quint, ED.Out), { Position = TITLE_FINAL }, nil, 0.3)

		IntroReveal(sidebar, 0.38, { SelfX = -22 })
		IntroReveal(titleLabel, 0.42, { SelfX = -14 })
		IntroReveal(subLabel, 0.48, { SelfX = -14 })
		IntroReveal(searchB, 0.5, { SelfX = 12 })
		IntroReveal(minB, 0.55, { SelfX = 12 })
		IntroReveal(closeB, 0.6, { SelfX = 12 })
		IntroReveal(splitter, 0.55, {})
		IntroReveal(grip, 0.68, { SelfY = 8 })
	end

	if cfg.Settings == true then
		task.defer(function()
			if not self._destroyed then
				BuildSettingsTab(self)
			end
		end)
	end
	return self
end

local uiVisible = true
local KeySystemLock = false

function Kailex:SetVisible(state)
	state = state == true
	uiVisible = state
	LayerWindows.Visible = state and not KeySystemLock
	LayerOverlay.Visible = state
	LayerNotify.Visible = state or KeySystemLock
	LayerTooltip.Visible = state
	if not state then
		Tooltip.Hide()
		ContextMenu.Hide()
		ModalManager.CloseAll()
	end
end

function Kailex:IsVisible()
	return uiVisible
end

function Kailex:MobileButton()
	if self._mobileButton then
		return self._mobileButton
	end
	local s = GetScale()
	local btn = Btn({
		AnchorPoint = V2(0.5, 0.5),
		Size = UO(46, 46),
		Position = UO((Viewport.X - 42) / s, (Viewport.Y - 42) / s),
		BackgroundColor3 = "Surface",
		ZIndex = 5,
		Parent = LayerNotify,
	})
	Corner(PILL, btn)
	StrokeBind(1, "Stroke", 0.35, btn)
	U.Txt(btn, {
		Size = US(1, 1),
		Font = EF.GothamBlack,
		Ts = 18,
		Text = "K",
	})
	local mmaid = Maid.new():Link(btn)
	MakeDraggable(btn, btn, { Clamp = true })
	btn.Size = UO(0, 0)
	Tween(btn, "Pop", { Size = UO(46, 46) })
	mmaid:Give(btn.MouseButton1Click:Connect(function()
		if btn:GetAttribute("Dragging") then return end
		ApplyRipple(btn)
		Kailex:SetVisible(not Kailex:IsVisible())
	end))
	self._mobileButton = btn
	return btn
end

function Kailex:KeySystem(options)
	options = options or {}

	local lp = Players.LocalPlayer
	local lpName = lp and lp.Name or ""
	local lpLower = lpName:lower()

	local secret = tostring(options.Secret or "Kailex.Default")
	local duration = math.max(0, floor(tonumber(options.Expiry) or 86400))

	local keySet, keyDur = {}, {}
	if options.Key ~= nil then
		if type(options.Key) == "table" then
			for k, v in pairs(options.Key) do
				if type(v) == "number" then
					keySet[tostring(k)] = true
					keyDur[tostring(k)] = math.max(0, floor(v))
				else
					keySet[tostring(v)] = true
				end
			end
		else
			keySet[tostring(options.Key)] = true
		end
	end
	local perKey = next(keyDur) ~= nil

	local title = tostring(options.Title or "Key System")
	local desc = tostring(options.SubTitle or "Enter your key to continue.")
	local link = options.Link

	local function validateKey(key)
		return keySet[tostring(key or "")] == true
	end

	local function keyDuration(key)
		return keyDur[tostring(key)] or duration
	end

	local function inList(list)
		if type(list) == "table" then
			for _, n in ipairs(list) do
				if tostring(n):lower() == lpLower then
					return true
				end
			end
		end
		return false
	end

	if inList(options.Blacklist) then
		Kailex:Notify({
			Title = "Access Denied",
			Text = "You are not allowed to use this script.",
			Type = "Error",
			Duration = 7,
		})
		Kailex:SetVisible(false)
		return nil
	end

	if inList(options.Whitelist) then
		if options.Silent ~= true then
			Kailex:Notify({ Title = "Key System", Text = "Welcome, " .. lpName .. " - you are whitelisted.", Type = "Success" })
		end
		return nil
	end

	local function serverNow()
		local ok, t = pcall(workspace.GetServerTimeNow, workspace)
		if ok and type(t) == "number" and t > 1e9 then
			return t
		end
		return os.time()
	end

	local function now()
		return math.max(os.time(), serverNow())
	end

	local function digest(str)
		local a, b, c, d = 5381, 52711, 65599, 506952113
		for i = 1, #str do
			local byte = str:byte(i)
			a = (a * 33 + byte) % 2147483648
			b = (b * 31 + byte) % 2147483648
			c = (c * 65599 + byte) % 2147483648
			d = (d * 33 + byte + i) % 2147483648
		end
		return string.format("%08x%08x%08x%08x", a, b, c, d)
	end

	local function hashStr(str, method)
		if method == "s" then
			local ok, h = pcall(function()
				return crypt.hash(str, "sha256")
			end)
			if ok and type(h) == "string" and #h > 0 then
				return h
			end
			return nil
		end
		return digest(str)
	end

	local bindId = tostring(lp and lp.UserId or 0) .. "|" .. tostring(game.GameId)
	if options.BindHardware ~= false then
		local ok, gh = pcall(function()
			return gethwid or get_hwid
		end)
		if ok and type(gh) == "function" then
			local ok2, hwid = pcall(gh)
			if ok2 and type(hwid) == "string" and #hwid > 0 then
				bindId = bindId .. "|" .. digest(hwid)
			end
		end
	end

	local storeBase = "__keySystem." .. digest(secret .. "|" .. tostring(game.GameId))
	local storeKey, storeSession = storeBase .. ".key", storeBase .. ".session"

	local function seal(key, g, e)
		local payload = bindId .. "|" .. key .. "|" .. g .. "|" .. e .. "|" .. secret
		local h = hashStr(payload, "s")
		if h then
			return string.format("s|%d|%d|%s", g, e, h)
		end
		return string.format("d|%d|%d|%s", g, e, hashStr(payload, "d"))
	end

	local function openSeal(key, raw)
		if type(raw) ~= "string" then return nil end
		local m, g, e, h = raw:match("^([sd])|(%d+)|(%d+)|(%x+)$")
		if not m then return nil end
		g, e = tonumber(g), tonumber(e)
		if not g or not e or e - g ~= keyDuration(key) or g > now() then return nil end
		local payload = bindId .. "|" .. key .. "|" .. g .. "|" .. e .. "|" .. secret
		if hashStr(payload, m) ~= h then return nil end
		return e > now() and e or nil
	end

	local function fmtTime(s)
		s = math.max(0, floor(s + 0.5))
		local h, m = floor(s / 3600), floor(s % 3600 / 60)
		if h > 0 then
			return string.format("%dh %02dm", h, m)
		end
		if m > 0 then
			return string.format("%dm %02ds", m, s % 60)
		end
		return s .. "s"
	end

	local openPrompt
	local sessionEnd, watching = 0, false

	local function expireSession()
		sessionEnd = 0
		SaveManager:Set(storeKey, "")
		SaveManager:Set(storeSession, "")
		Kailex:Notify({ Title = title, Text = "Your key has expired - enter a new key to continue.", Type = "Error", Duration = 7 })
		KeySystemLock = true
		LayerWindows.Visible = false
		task.delay(0.6, openPrompt)
	end

	local function watchSession()
		if watching or sessionEnd <= 0 then return end
		watching = true
		task.spawn(function()
			while sessionEnd > now() do
				task.wait(1)
			end
			watching = false
			expireSession()
		end)
	end

	local savedKey = SaveManager:Get(storeKey, nil)
	if type(savedKey) == "string" and savedKey ~= "" and validateKey(savedKey) then
		if keyDuration(savedKey) <= 0 then
			if options.Silent ~= true then
				Kailex:Notify({ Title = "Key System", Text = "Saved key accepted - welcome back.", Type = "Success" })
			end
			return nil
		end
		local expiresAt = openSeal(savedKey, SaveManager:Get(storeSession, nil))
		if expiresAt then
			sessionEnd = expiresAt
			if options.Silent ~= true then
				Kailex:Notify({ Title = "Key System", Text = "Saved key accepted - " .. fmtTime(sessionEnd - now()) .. " remaining.", Type = "Success" })
			end
			watchSession()
			return nil
		end
	end

	if next(keySet) == nil then return nil end

	openPrompt = function()
		KeySystemLock = true
		LayerWindows.Visible = false

		local alive = true
		local maid = Maid.new()
		local dimmer = U.Overlay(LayerOverlay, 40, nil, CN(0, 0, 0))
		local card = U.ModalCard(LayerOverlay, 41, 360, 210, 14, 0.35)
		local ksScale = UISC(card, 0.94)

		U.Txt(card, {
			Pos = UO(18, 16),
			Size = UN(1, -36, 0, 20),
			Font = EF.GothamBold,
			Ts = 15,
			Align = ETA.Left,
			Trunc = true,
			Text = title,
			Z = 42,
		})
		U.Txt(card, {
			Pos = UO(18, 38),
			Size = UN(1, -36, 0, 30),
			Ts = 12,
			Color = "SubText",
			Align = ETA.Left,
			Wrap = true,
			Text = desc,
			Z = 42,
		})

		local statusLabel = U.Txt(card, {
			Pos = UO(18, 122),
			Size = UN(1, -36, 0, 15),
			Ts = 11,
			Color = "SubText",
			Align = ETA.Left,
			Trunc = true,
			Text = not perKey and duration > 0 and ("Key validity: " .. fmtTime(duration)) or "",
			Z = 42,
		})
		local statusKey = "SubText"
		local function setStatus(text, colorKey)
			statusLabel.Text = tostring(text or "")
			statusKey = colorKey or "SubText"
			statusLabel.TextColor3 = CurrentTheme[statusKey] or CurrentTheme.SubText
		end
		maid:Give(Kailex.ThemeChanged:Connect(function()
			statusLabel.TextColor3 = CurrentTheme[statusKey] or CurrentTheme.SubText
		end))

		local okPaste, gc = pcall(function()
			return getclipboard
		end)
		local hasPaste = okPaste and type(gc) == "function"

		local inputBox = U.TxB(card, {
			Pos = UO(18, 76),
			Size = UN(1, -36, 0, 38),
			Ts = 13,
			Ph = "Enter your key...",
			Align = ETA.Left,
			Z = 42,
			Kids = { Corner(8) },
		})
		Pad(10, hasPaste and 66 or 10, 0, 0, inputBox)
		local inputStroke = StrokeBind(1, "Stroke", 0.5, inputBox)

		if hasPaste then
			local pasteBtn = U.MkBtn(inputBox, {
				Ap = V2(1, 0.5),
				Pos = UN(1, -6, 0.5, 0),
				Size = UO(56, 26),
				Text = "Paste",
				Ts = 11,
				Color = "SubText",
				Z = 43,
			})
			maid:Give(pasteBtn.MouseButton1Click:Connect(function()
				if not alive then return end
				local ok, txt = pcall(gc)
				if ok and type(txt) == "string" and txt:match("%S") then
					inputBox.Text = txt:match("^%s*(.-)%s*$")
					PlaySound("Click", 0.5)
					setStatus("Key pasted from clipboard - press Verify.")
				end
			end))
		end

		local function mkBtn(text, accent, xPos, w)
			return U.MkBtn(card, {
				Pos = UO(xPos, 152),
				Size = UO(w, 40),
				Text = text,
				Ts = 12,
				Accent = accent,
				Z = 42,
			})
		end

		local verifyBtn, linkBtn, declineBtn
		if link then
			verifyBtn = mkBtn("Verify", true, 226, 116)
			declineBtn = mkBtn("Decline", false, 122, 96)
			linkBtn = mkBtn("Get Key", false, 18, 96)
		else
			verifyBtn = mkBtn("Verify", true, 126, 216)
			declineBtn = mkBtn("Decline", false, 18, 100)
		end

		local function fadeOutCard()
			Tween(ksScale, "Vanish", { Scale = 0.95 })
			Tween(card, "Vanish", { GroupTransparency = 1 }, function()
				maid:Destroy()
				card:Destroy()
			end)
			Tween(dimmer, "Smooth", { BackgroundTransparency = 1 }, function()
				if dimmer.Parent then
					dimmer:Destroy()
				end
			end)
		end

		local function grantAccess(key)
			if not alive then return end
			alive = false
			PlaySound("ToggleOn")
			local dur = keyDuration(key)
			if dur > 0 then
				local g = floor(serverNow())
				sessionEnd = g + dur
				SaveManager:Set(storeSession, seal(key, g, sessionEnd))
			end
			SaveManager:Set(storeKey, key)
			Tween(inputStroke, "Fast", { Color = CurrentTheme.Success, Transparency = 0 })
			setStatus("Access granted - welcome!", "Success")
			Tween(ksScale, "PopSoft", { Scale = 1.02 })
			task.delay(0.42, function()
				fadeOutCard()
				KeySystemLock = false
				LayerWindows.Visible = uiVisible
				if sessionEnd > 0 then
					watchSession()
					if options.Silent ~= true then
						Kailex:Notify({ Title = title, Text = "Access granted - " .. fmtTime(sessionEnd - now()) .. " remaining.", Type = "Success" })
					end
				end
			end)
		end

		local function wrongKey()
			PlaySound("Error")
			FX.Shake(card, 9)
			Tween(inputStroke, "Fast", { Color = CurrentTheme.Error, Transparency = 0 })
			setStatus("Wrong key - try again.", "Error")
			task.delay(1.2, function()
				if alive then
					Tween(inputStroke, "Smooth", { Color = CurrentTheme.Stroke, Transparency = 0.5 })
				end
			end)
		end

		local function verify()
			if not alive then return end
			local val = inputBox.Text:match("^%s*(.-)%s*$")
			if val ~= "" and validateKey(val) then
				grantAccess(val)
			else
				wrongKey()
			end
		end

		local function declineNow()
			if not alive then return end
			alive = false
			PlaySound("Click", 0.5)
			fadeOutCard()
			Kailex:SetVisible(false)
		end

		maid:Give(verifyBtn.MouseButton1Click:Connect(function()
			ApplyRipple(verifyBtn)
			verify()
		end))
		maid:Give(declineBtn.MouseButton1Click:Connect(function()
			ApplyRipple(declineBtn)
			declineNow()
		end))
		maid:Give(inputBox.FocusLost:Connect(function(enter)
			if enter and alive then
				verify()
			end
		end))
		local escHook = AddInputHook(function()
			return alive
		end, function(input)
			if input.KeyCode == EKC.Escape then
				declineNow()
			end
		end)
		maid:Give(function()
			RemoveInputHook(escHook)
		end)
		if linkBtn then
			maid:Give(linkBtn.MouseButton1Click:Connect(function()
				if not alive then return end
				Tap(linkBtn, "Click", 0.5)
				local setc = GetClipboardFn()
				if setc then
					pcall(setc, tostring(link))
					setStatus("Link copied to clipboard - get your key, then paste it.", "Success")
				else
					Kailex:Notify({ Title = title, Text = tostring(link), Duration = 10 })
					setStatus("Link is shown in the notifications.")
				end
			end))
		end

		Tween(dimmer, "Normal", { BackgroundTransparency = 0.5 })
		card.GroupTransparency = 1
		Tween(card, "Snappy", { GroupTransparency = 0 })
		Tween(ksScale, "Pop", { Scale = 1 })
		task.defer(function()
			inputBox:CaptureFocus()
		end)
		return card
	end

	return openPrompt()
end

function Kailex:Unload()
	ModalManager.CloseAll()
	pcall(function()
		ContextMenu.Hide()
	end)
	for el in pairs(QuickWidgets.Active) do
		QuickWidgets.Destroy(el)
	end
	for i = #Kailex.Windows, 1, -1 do
		local w = Kailex.Windows[i]
		if w and w.Destroy then
			pcall(w.Destroy, w)
		end
	end
	Tooltip.Hide()
	HotElement = nil
	ActiveKeybindListener = nil
	KeySystemLock = false
	LibMaid:Destroy()
	for _, s in ipairs(SoundInstances) do
		pcall(function()
			s:Destroy()
		end)
	end
	table.clear(SoundInstances)
	table.clear(SoundPool)
	for _, r in ipairs(RipplePool) do
		pcall(function()
			r:Destroy()
		end)
	end
	table.clear(RipplePool)
	pcall(function()
		ScreenGui:Destroy()
	end)
	local g = Getgenv()
	if g and g.kailex == Kailex then
		g.kailex = nil
	end
end

local function ApplyPersisted()
	local th
	local cc = SaveManager:Get("__customColors", nil)
	if type(cc) == "table" then
		local bg = HexToColor(cc.Background)
		local sf = HexToColor(cc.Surface)
		local tx = HexToColor(cc.Text)
		local ac = HexToColor(cc.Accent)
		if bg and sf and tx and ac then
			th = DeriveTheme({ Background = bg, Surface = sf, Text = tx, Accent = ac })
		end
	end
	if not th then
		local t = SaveManager:Get("__theme", nil)
		if t and Themes[t] then
			Setting.Theme = t
			th = Themes[t]
		end
	end
	if th and not SameTheme(th, CurrentTheme) then
		ApplyTheme(th)
	end
	local snd = SaveManager:Get("__sounds", nil)
	if snd ~= nil then
		Setting.Sounds = (snd == true)
	end
	local sc = SaveManager:Get("__scale", nil)
	if type(sc) == "number" then
		local ns = clamp(sc, 0.75, 1.5)
		if ns ~= Setting.UIScale then
			Setting.UIScale = ns
			UpdateViewport()
		end
	end
	local txs = SaveManager:Get("__textScale", nil)
	if type(txs) == "number" then
		Setting.TextScale = clamp(txs, 0.75, 1.6)
		ApplyTextScale()
	end
	local mot = SaveManager:Get("__motion", nil)
	if type(mot) == "number" then
		Setting.MotionScale = clamp(mot, 0.1, 1)
	end
	local eff = SaveManager:Get("__effects", nil)
	if eff ~= nil then
		Setting.Effects = (eff == true)
	end
	local tk = SaveManager:Get("__toggleKey", nil)
	if tk ~= nil then
		Setting.ToggleUIKey = ParseKey(tk)
	end
end

ApplyPersisted()

if Device.IsConsole then
	Setting.UIScale = math.max(tonumber(Setting.UIScale) or 1, 1.15)
end
UpdateViewport()

LibMaid:Give(AddInputHook(function()
	return true
end, function(input, gp)
	if gp then return end
	local code = input.KeyCode
	if code == EKC.Unknown then return end
	if ActiveKeybindListener ~= nil then return end
	if UIS:GetFocusedTextBox() ~= nil then return end

	local key = Setting.ToggleUIKey
	if key ~= nil and code == key then
		Kailex:SetVisible(not Kailex:IsVisible())
		return
	end
	for _, w in ipairs(Kailex.Windows) do
		if not w._destroyed and w.ToggleKey == code then
			w:ToggleHidden()
			return
		end
	end

	local el = HotElement
	if el and not el._destroyed and not el._disabled and el.HandleArrow then
		local dir
		if code == EKC.Left or code == EKC.Down then
			dir = -1
		elseif code == EKC.Right or code == EKC.Up then
			dir = 1
		end
		if dir then
			el:HandleArrow(dir)
		end
	end
end))

LibMaid:Give(SaveManager.DataChanged:Connect(function()
	ApplyPersisted()
end))

if Device.IsTouch then
	Kailex:MobileButton()
end

LibMaid:Give(ScreenGui.Destroying:Connect(function()
	LibMaid:Destroy()
end))

if genv then
	genv.kailex = Kailex
end

return Kailex
