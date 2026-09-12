return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Window = I.WindowClass
    local Chrome = I.WindowChrome
    local Search = I.WindowSearch
    local Layout = I.WindowLayout
    local State = I.WindowState

    local T_CORE = 0
    local T_CROWN_IN = 0.45
    local T_CROWN_W = 0.6
    local T_WIDTH = 1.05
    local T_HEIGHT = 1.85
    local T_ICON = 2.05
    local T_TITLE = 2.25
    local T_BTNS = 2.35
    local T_DIV = 2.45
    local T_SUB = 2.65
    local T_SHIMMER = 2.95
    local T_KILL = 4.15

    local function TI(dur, delay, style)
        return TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delay or 0)
    end

    function Window:Ready()
        self._loadForce = true
    end

    function Kailex:CreateWindow(cfg)
        cfg = cfg or {}
        local self = setmetatable({}, Window)
        self._cfg = cfg
        self.Title = tostring(cfg.Title or cfg.Name or "Kailex")
        self.SubTitle = cfg.SubTitle
        self.SavePrefix = tostring(self.Title)
        self.MinSize = cfg.MinSize or Vector2.new(380, 280)
        self._destroyed = false
        self._filterQuery = ""
        self.Tabs = {}
        self.CurrentTab = nil
        self.Minimized = false
        self.MinimizedChanged = I.Signal.new()
        self.Closed = I.Signal.new()
        self._hidden = false
        self._alwaysTop = false
        self.ToggleKey = I.ParseKey(cfg.ToggleKey)
        self._remember = cfg.RememberPosition ~= false

        local defW, defH = 580, 420
        local s = I.GetScale()
        local vw, vh = I.Viewport.X / s, I.Viewport.Y / s
        if I.Device.IsTouch then
            defW = math.min(defW, vw - 16)
            defH = math.min(defH, vh - 16)
        end
        defW = math.clamp(defW, math.min(self.MinSize.X, vw - 12), vw - 12)
        defH = math.clamp(defH, math.min(self.MinSize.Y, vh - 12), vh - 12)

        local px, py
        if self._remember then
            local sp = I.SaveManager:Get("__win:" .. self.SavePrefix, nil)
            if type(sp) == "table" then
                local sx, sy, sw, sh = tonumber(sp.X), tonumber(sp.Y), tonumber(sp.W), tonumber(sp.H)
                if sx and sy and sw and sh then
                    defW = math.clamp(sw, math.min(self.MinSize.X, vw - 12), vw - 12)
                    defH = math.clamp(sh, math.min(self.MinSize.Y, vh - 12), vh - 12)
                    px = math.clamp(sx, 8, math.max(8, vw - defW - 8))
                    py = math.clamp(sy, 8, math.max(8, vh - defH - 8))
                end
            end
        end
        if not px then
            if #Kailex.Windows == 0 then
                px = math.max(8, math.floor((vw - defW) / 2 + 0.5))
                py = math.max(8, math.floor((vh - defH) / 2 + 0.5))
            else
                local n = #Kailex.Windows % 5
                px, py = 40 + n * 28, 34 + n * 24
            end
        end

        self._rootFinal = UDim2.fromOffset(px, py)
        self._titleFinal = UDim2.new(0, 0, 0, 0)
        self._bodyFinal = UDim2.new(0, 0, 0, 56)

        self._introActive = true
        self._introW = defW
        self._introFinalSize = UDim2.fromOffset(defW, defH)
        self._introKilled = false
        self._tabQueue = {}
        self._loadForce = false

        local cx = px + defW / 2

        self.Root = I.Create("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(cx, py + 10),
            Size = UDim2.fromOffset(96, 46),
            BackgroundColor3 = I.CurrentTheme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            GroupTransparency = 1,
            Parent = I.LayerWindows,
        })
        I.Bind(self.Root, "BackgroundColor3", "Background")
        I.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = self.Root })
        I.Bind(I.Create("UIStroke", {
            Thickness = 1,
            Transparency = 0.35,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = self.Root,
        }), "Color", "Stroke")
        self._winScale = I.Create("UIScale", { Scale = 0.92, Parent = self.Root })
        self._shadow = I.DropShadow(self.Root, { Radius = 14 })

        self.Maid = I.Maid.new()
        self.Maid:Link(self.Root)

        Chrome.build(self)
        Search.build(self)
        Layout.build(self)

        self._focus = function() State.bringToFront(self) end

        self.Maid:Give(self.Root.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local top = I.ModalManager.Stack[#I.ModalManager.Stack]
            if top and top.Owner ~= self then return end
            State.bringToFront(self)
        end))

        self.Body.Visible = false
        self.ResizeGrip.Visible = false
        self.Body.Position = UDim2.new(0, 0, 0, 78)
        self.Sidebar.Position = UDim2.fromOffset(-12, 0)

        I.Tween(self.TitleLabel, "Instant", { TextTransparency = 1 })
        self._titleLabelFinal = self.TitleLabel.Position
        self._subLabelFinal = self.SubLabel.Position
        self.TitleLabel.Position = self._titleLabelFinal - UDim2.fromOffset(16, 0)
        self.SubLabel.TextTransparency = 1
        self.SubLabel.Position = self._subLabelFinal - UDim2.fromOffset(12, 0)
        if self.TitleDivider then
            self.TitleDivider.Size = UDim2.new(0, 0, 0, 1)
        end
        if self.IconImg then
            self._iconFinal = self.IconImg.Position
            self.IconImg.Visible = false
            self.IconImg.Position = self._iconFinal - UDim2.fromOffset(10, 0)
            I.Create("UIScale", { Scale = 0.4, Parent = self.IconImg })
        end

        self._titleBtnFinals = {}
        for i, b in ipairs(self._titleButtons) do
            self._titleBtnFinals[i] = b.Position
            b.Visible = false
            b.Position = self._titleBtnFinals[i] + UDim2.fromOffset(26, 0)
            I.Create("UIScale", { Scale = 0.5, Parent = b })
        end

        local crown = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.fromOffset(0, 3),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30,
            Parent = self.Root,
        })
        I.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = crown })
        self._introMaid:Give(crown)

        local loadLabel = I.Create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 2),
            Size = UDim2.new(1, -16, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = self.Title,
            ZIndex = 40,
            Parent = self.Root,
        })
        I.Bind(loadLabel, "TextColor3", "Text")
        self._introMaid:Give(loadLabel)

        local shimmer = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(-0.3, 0, 0.5, 0),
            Size = UDim2.new(0, 90, 2.4, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Rotation = 16,
            ZIndex = 50,
            Visible = false,
            Parent = self.Root,
        })
        I.Create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.55),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = shimmer,
        })
        self._introMaid:Give(shimmer)

        table.insert(Kailex.Windows, self)
        self._focus()
        Layout.geom(self, false, #self.Tabs > 1)

        local skipStart = nil
        self._introMaid:Give(self.Root.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                skipStart = input.Position
            end
        end))
        self._introMaid:Give(self.Root.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if not skipStart then return end
            local moved = (input.Position - skipStart).Magnitude
            skipStart = nil
            if moved < 6 then
                State.killIntro(self)
            end
        end))

        local function imposeBirth()
            self.Root.AnchorPoint = Vector2.new(0.5, 0)
            self.Root.Position = UDim2.fromOffset(cx, py + 10)
            self.Root.Size = UDim2.fromOffset(96, 46)
            self.Root.Rotation = 0
            self.Root.ClipsDescendants = false
            self._winScale.Scale = 0.92
            self.Body.Visible = false
            self.ResizeGrip.Visible = false
            self.Body.Position = UDim2.new(0, 0, 0, 78)
            self.Sidebar.Position = UDim2.fromOffset(-12, 0)
            self.TitleLabel.TextTransparency = 1
            self.TitleLabel.Position = self._titleLabelFinal - UDim2.fromOffset(16, 0)
            self.SubLabel.TextTransparency = 1
            self.SubLabel.Position = self._subLabelFinal - UDim2.fromOffset(12, 0)
            if self.TitleDivider then
                self.TitleDivider.Size = UDim2.new(0, 0, 0, 1)
            end
            if self.IconImg then
                self.IconImg.Visible = false
                self.IconImg.Position = self._iconFinal - UDim2.fromOffset(10, 0)
                local us = self.IconImg:FindFirstChildOfClass("UIScale")
                if us then us.Scale = 0.4 end
            end
            for i, b in ipairs(self._titleButtons) do
                b.Visible = false
                b.Position = self._titleBtnFinals[i] + UDim2.fromOffset(26, 0)
                local us = b:FindFirstChildOfClass("UIScale")
                if us then us.Scale = 0.5 end
            end
            crown.Size = UDim2.fromOffset(0, 3)
            crown.BackgroundTransparency = 1
            loadLabel.Visible = true
            loadLabel.TextTransparency = 1
        end

        local function startAssembly(hadLoader)
            self._assemblyClock = os.clock()
            local queue = self._tabQueue
            self._tabQueue = nil
            if queue then
                for i, t in ipairs(queue) do
                    if t.Button and t.Button.Parent and t._playIntro then
                        t:_playIntro(math.min(T_HEIGHT + (i - 1) * 0.09, 2.85))
                    end
                end
            end
            if hadLoader then
                I.Tween(crown, TI(0.18), { Size = UDim2.fromOffset(88, 3) })
            else
                I.Tween(self.Root, TI(0.55, T_CORE), { GroupTransparency = 0, Position = UDim2.fromOffset(cx, py) })
                I.Tween(self._winScale, TI(0.65, T_CORE, Enum.EasingStyle.Back), { Scale = 1 })
                I.Tween(crown, TI(0.3, T_CROWN_IN), { BackgroundTransparency = 0.1 })
            end
            task.delay(T_CROWN_W, function()
                if self._destroyed or self._introKilled then return end
                I.Tween(crown, TI(0.75), { Size = UDim2.fromOffset(defW, 3) })
            end)
            task.delay(0.5, function()
                if not self._destroyed and not self._introKilled and self._shadow then self._shadow.SetFade(0.7) end
            end)
            task.delay(T_WIDTH, function()
                if self._destroyed or self._introKilled then return end
                I.Tween(self.Root, TI(0.8), { Size = UDim2.fromOffset(defW, 46) })
            end)
            task.delay(T_HEIGHT, function()
                if self._destroyed or self._introKilled then return end
                self.Root.ClipsDescendants = true
                self.Body.Visible = true
                self.ResizeGrip.Visible = true
                I.Tween(self.Root, TI(0.95), { Size = self._introFinalSize })
                I.Tween(self.Body, TI(0.55, 0.15), { Position = self._bodyFinal })
                I.Tween(self.Sidebar, TI(0.6, 0.25), { Position = UDim2.new(0, 0, 0, 0) })
            end)
            if self.IconImg then
                task.delay(T_ICON, function()
                    if self._destroyed or self._introKilled then return end
                    self.IconImg.Visible = true
                    I.Tween(self.IconImg, TI(0.45), { Position = self._iconFinal })
                    local us = self.IconImg:FindFirstChildOfClass("UIScale")
                    if us then
                        I.Tween(us, TI(0.5, 0, Enum.EasingStyle.Back), { Scale = 1 })
                    end
                end)
            end
            I.Tween(self.TitleLabel, TI(0.5, T_TITLE), { TextTransparency = 0, Position = self._titleLabelFinal })
            if self.TitleDivider then
                I.Tween(self.TitleDivider, TI(0.55, T_DIV), { Size = UDim2.new(1, 0, 0, 1) })
            end
            I.Tween(self.SubLabel, TI(0.45, T_SUB), { TextTransparency = 0, Position = self._subLabelFinal })
            local btnCount = #self._titleButtons
            for i, b in ipairs(self._titleButtons) do
                task.delay(T_BTNS + (btnCount - i) * 0.12, function()
                    if self._destroyed or self._introKilled then return end
                    b.Visible = true
                    I.Tween(b, TI(0.5), { Position = self._titleBtnFinals[i] })
                    local us = b:FindFirstChildOfClass("UIScale")
                    if us then
                        I.Tween(us, TI(0.45, 0.02, Enum.EasingStyle.Back), { Scale = 1 })
                    end
                end)
            end
            task.delay(T_SHIMMER, function()
                if self._destroyed or self._introKilled or not shimmer.Parent then return end
                shimmer.Visible = true
                I.Tween(shimmer, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Position = UDim2.new(1.3, 0, 0.5, 0) })
            end)
            task.delay(2.1, function()
                if not self._destroyed and not self._introKilled and self._shadow then self._shadow.SetFade(0.35) end
            end)
            task.delay(2.8, function()
                if not self._destroyed and not self._introKilled and self._shadow then self._shadow.SetFade(0) end
            end)
            task.delay(2.9, function()
                if self._destroyed or self._introKilled or not crown.Parent then return end
                I.Tween(crown, TI(0.55, 0, Enum.EasingStyle.Sine),
                    { BackgroundTransparency = 1, Size = UDim2.fromOffset(math.max(defW - 60, 0), 3) })
            end)
            task.delay(T_KILL, function()
                if self._destroyed then return end
                State.killIntro(self)
            end)
        end

        if cfg.Intro == false then
            State.killIntro(self)
            return self
        end

        if cfg.Loading == false then
            task.delay(0.05, function()
                if self._destroyed or self._introKilled then return end
                imposeBirth()
                startAssembly(false)
            end)
            return self
        end

        local built = 0
        self._introMaid:Give(self.Pages.DescendantAdded:Connect(function() built += 1 end))
        self._introMaid:Give(self.TabList.DescendantAdded:Connect(function() built += 1 end))

        task.spawn(function()
            task.wait(0.05)
            if self._destroyed or self._introKilled then return end
            imposeBirth()
            I.Tween(self.Root, TI(0.3), { GroupTransparency = 0, Position = UDim2.fromOffset(cx, py) })
            I.Tween(self._winScale, TI(0.45, 0, Enum.EasingStyle.Back), { Scale = 1 })
            I.Tween(crown, TI(0.2), { BackgroundTransparency = 0.1 })
            I.Tween(loadLabel, TI(0.3, 0.08), { TextTransparency = 0.25 })

            local display, lastCount, quiet, ready, lastW = 0, 0, 0, false, -1
            while not self._destroyed and not self._introKilled do
                task.wait()
                if self._destroyed or self._introKilled then return end
                if self._loadForce then ready = true end
                local c = built
                if c ~= lastCount then
                    lastCount = c
                    quiet = 0
                else
                    quiet += 1
                    if quiet >= 4 then ready = true end
                end
                local target = ready and 1 or (1 - math.exp(-built / 10)) * 0.93
                display += (target - display) * (ready and 0.5 or 0.25)
                local w = math.floor(4 + display * 60 + 0.5)
                if w ~= lastW then
                    lastW = w
                    crown.Size = UDim2.fromOffset(w, 3)
                end
                if ready and display > 0.985 then break end
            end
            if self._destroyed or self._introKilled then return end
            crown.Size = UDim2.fromOffset(64, 3)
            I.Tween(loadLabel, TI(0.16), { TextTransparency = 1 })
            task.delay(0.18, function()
                if self._destroyed or self._introKilled then return end
                loadLabel.Visible = false
                startAssembly(true)
            end)
        end)

        return self
    end
end
