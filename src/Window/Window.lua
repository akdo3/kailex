return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService
    local TextService = I.TextService
    local Setting = I.Setting

    local Window = {}
    Window.__index = Window

    function Kailex:CreateWindow(cfg)
        cfg = cfg or {}
        local self = setmetatable({}, Window)
        self.Title = tostring(cfg.Title or cfg.Name or "Kailex")
        self.SubTitle = cfg.SubTitle
        self.SavePrefix = tostring(cfg.SaveKey or cfg.SavePrefix or self.Title)
        self.MinSize = cfg.MinSize or Vector2.new(380, 280)
        self._destroyed = false
        self._filterQuery = ""
        self.Tabs = {}
        self.CurrentTab = nil
        self.Minimized = false
        self.Maximized = false
        self.MinimizedChanged = I.Signal.new()
        self.Closed = I.Signal.new()
        self._hidden = false
        self._alwaysTop = false
        self.ToggleKey = I.ParseKey(cfg.ToggleKey)
        self._remember = cfg.RememberPosition ~= false

        local defW, defH = 580, 420
        if typeof(cfg.Size) == "Vector2" then
            defW, defH = cfg.Size.X, cfg.Size.Y
        elseif typeof(cfg.Size) == "UDim2" then
            defW, defH = cfg.Size.X.Offset, cfg.Size.Y.Offset
        elseif type(cfg.Size) == "table" then
            defW = tonumber(cfg.Size[1] or cfg.Size.X) or defW
            defH = tonumber(cfg.Size[2] or cfg.Size.Y) or defH
        end
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

        self.Root = I.Create("CanvasGroup", {
            Position = UDim2.fromOffset(px, py),
            Size = UDim2.fromOffset(defW, defH),
            BackgroundColor3 = I.CurrentTheme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
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
        self._winScale = I.Create("UIScale", { Scale = 0.94, Parent = self.Root })

        local shadow = I.DropShadow(self.Root, { Radius = 14 })
        self._shadow = shadow

        self.Maid = I.Maid.new()
        self.Maid:Link(self.Root)

        local introMaid = I.Maid.new()
        self.Maid:Give(introMaid)

        local setMaxIcon

        local TITLE_FINAL = UDim2.new(0, 0, 0, 0)
        local BODY_FINAL = UDim2.new(0, 0, 0, 56)
        local ROOT_FINAL = UDim2.fromOffset(px, py)

        local titleBar = I.Create("Frame", {
            Position = TITLE_FINAL,
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
            Parent = self.Root,
        })
        self.TitleBar = titleBar

        local body = I.Create("Frame", {
            Position = BODY_FINAL,
            Size = UDim2.new(1, 0, 1, -46),
            BackgroundTransparency = 1,
            Parent = self.Root,
        })
        self.Body = body

        local function KillIntroMotion()
            I.Tween(self.Root, "Instant", { Position = ROOT_FINAL, GroupTransparency = 0 })
            I.Tween(self._winScale, "Instant", { Scale = 1 })
            I.Tween(titleBar, "Instant", { Position = TITLE_FINAL })
            I.Tween(body, "Instant", { Position = BODY_FINAL })
            if shadow then shadow.SetFade(0) end
            introMaid:Destroy()
        end

        I.MakeDraggable(titleBar, self.Root, {
            Clamp = true,
            ModalOwner = self,
            OnStart = function(root)
                if self.Maximized then
                    self.Maximized = false
                    self.ResizeGrip.Visible = not self.Minimized
                    setMaxIcon("Maximize")
                    if self._restore then
                        local sc = I.GetScale()
                        local m = UserInputService:GetMouseLocation()
                        local ap = root.AbsolutePosition
                        local oldW = root.AbsoluteSize.X
                        local newW = self._restore.Size.X.Offset
                        local newH = self._restore.Size.Y.Offset
                        local frac = oldW > 1 and math.clamp((m.X - ap.X) / oldW, 0.12, 0.88) or 0.5
                        local nx = math.clamp(m.X / sc - frac * newW, 8, math.max(8, I.Viewport.X / sc - newW - 8))
                        local ny = math.clamp(ap.Y / sc, 8, math.max(8, I.Viewport.Y / sc - newH - 8))
                        root.Size = self._restore.Size
                        root.Position = UDim2.fromOffset(nx, ny)
                    end
                end
            end,
            OnEnd = function() self:SavePlacement() end,
        })

        local titleX = 14
        local winIcon
        if cfg.Icon ~= nil then
            titleX = 40
            local raw = tostring(cfg.Icon)
            local isAsset = tonumber(cfg.Icon) ~= nil
                or raw:sub(1, 11) == "rbxassetid" or raw:sub(1, 9) == "rbxasset://"
            if isAsset then
                winIcon = I.Create("ImageLabel", {
                    Position = UDim2.fromOffset(14, 5),
                    Size = UDim2.fromOffset(20, 20),
                    BackgroundTransparency = 1,
                    Image = tonumber(cfg.Icon) and ("rbxassetid://" .. cfg.Icon) or cfg.Icon,
                    ImageColor3 = I.CurrentTheme.SubText,
                    Parent = titleBar,
                })
                I.Bind(winIcon, "ImageColor3", "SubText")
            else
                winIcon = I.Icon(titleBar, raw, "SubText")
                winIcon.Position = UDim2.fromOffset(14, 5)
                winIcon.Size = UDim2.fromOffset(20, 20)
            end
            self.IconImg = winIcon
        end

        local titleReserve = 130 + (titleX - 14)
        local titleLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(titleX, 7),
            Size = UDim2.new(1, -titleReserve, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = self.Title,
            Parent = titleBar,
        })
        I.Bind(titleLabel, "TextColor3", "Text")
        local subLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(titleX, 26),
            Size = UDim2.new(1, -titleReserve, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(cfg.SubTitle or ""),
            Parent = titleBar,
        })
        I.Bind(subLabel, "TextColor3", "SubText")

        local titleDivider = I.Create("Frame", {
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = I.CurrentTheme.Stroke,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Parent = titleBar,
        })
        I.Bind(titleDivider, "BackgroundColor3", "Stroke")

        local searchBox = I.Create("TextBox", {
            Position = UDim2.fromOffset(14, 11),
            Size = UDim2.new(0, 220, 0, 24),
            BackgroundTransparency = 1,
            Visible = false,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            PlaceholderText = "Search ...",
            PlaceholderColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = titleBar,
        })
        I.Bind(searchBox, "TextColor3", "Text")
        I.Bind(searchBox, "PlaceholderColor3", "SubText")

        local searchLine = I.Create("Frame", {
            Position = UDim2.fromOffset(14, 35),
            Size = UDim2.new(0, 0, 0, 1),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = titleBar,
        })
        I.Bind(searchLine, "BackgroundColor3", "Accent")

        searchBox.ClipsDescendants = true
        local searchActive = false
        local searchDebounce = nil
        local setSearch

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = searchBox.Text
            if searchDebounce then pcall(task.cancel, searchDebounce) end
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
            if not enter and searchBox.Text == "" then setSearch(false) end
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
                searchBox.Size = UDim2.new(0, 0, 0, 24)
                searchLine.Size = UDim2.new(0, 0, 0, 1)
                I.Tween(searchBox, "Snappy", { Size = UDim2.new(0, 220, 0, 24) }, function()
                    if searchActive then pcall(function() searchBox:CaptureFocus() end) end
                end)
                I.Tween(searchLine, "Snappy", { Size = UDim2.new(0, 220, 0, 1) })
            else
                pcall(function() searchBox:ReleaseFocus() end)
                I.Tween(searchBox, "Fast", { Size = UDim2.new(0, 0, 0, 24) }, function()
                    if not searchActive then
                        searchBox.Visible = false
                        searchLine.Visible = false
                        titleLabel.Visible = true
                        subLabel.Visible = true
                    end
                end)
                I.Tween(searchLine, "Fast", { Size = UDim2.new(0, 0, 0, 1) })
                self._filterQuery = ""
                self:ApplyFilter("")
            end
        end
        self._setSearch = function(_, on) setSearch(on) end

        self.Maid:Give(UserInputService.InputBegan:Connect(function(input, gp)
            if not searchActive then return end
            if input.KeyCode ~= Enum.KeyCode.Escape then return end
            if #I.ModalManager.Stack > 0 then return end
            if gp and UserInputService:GetFocusedTextBox() ~= searchBox then return end
            setSearch(false)
        end))

        local function titleButton(kind, xPos, colorKey)
            local b = I.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xPos, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                BackgroundTransparency = 1,
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = titleBar,
            })
            local ic = I.Icon(b, kind, colorKey or "SubText")
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.Position = UDim2.fromScale(0.5, 0.5)
            ic.Size = UDim2.fromOffset(12, 12)
            I.AddPress(b)
            return b
        end

        local closeB = titleButton("Close", -10, "Text")
        closeB.MouseEnter:Connect(function()
            I.Tween(closeB, "Fast", { BackgroundColor3 = I.CurrentTheme.Error, BackgroundTransparency = 0.15 })
        end)
        closeB.MouseLeave:Connect(function()
            I.Tween(closeB, "Fast", { BackgroundTransparency = 1 })
        end)
        self.Maid:Give(closeB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self:Close()
        end))

        local minB = titleButton("Minimize", -44)
        I.AddHover(minB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
        self.Maid:Give(minB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self:SetMinimized(true)
        end))

        local maxB = titleButton("Maximize", -78)
        I.AddHover(maxB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
        local maxIcon
        setMaxIcon = function(kind)
            if maxIcon then maxIcon:Destroy() end
            maxIcon = I.Icon(maxB, kind, "SubText")
            maxIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            maxIcon.Position = UDim2.fromScale(0.5, 0.5)
            maxIcon.Size = UDim2.fromOffset(12, 12)
        end
        setMaxIcon("Maximize")
        self.Maid:Give(maxB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self:SetMaximized(not self.Maximized)
        end))

        local searchB = titleButton("Search", -112)
        I.AddHover(searchB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
        self.Maid:Give(searchB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            setSearch(not searchActive)
        end))

        local _titleButtons = { searchB, minB, maxB, closeB }
        self._titleButtons = _titleButtons

        self._sidebarWidth = math.clamp(tonumber(I.SaveManager:Get("__sidebarWidth", 152)) or 152, 110, 320)

        local sidebar = I.Create("Frame", {
            Size = UDim2.new(0, self._sidebarWidth, 1, 0),
            BackgroundColor3 = I.CurrentTheme.TabBar,
            BorderSizePixel = 0,
            Parent = body,
        })
        I.Bind(sidebar, "BackgroundColor3", "TabBar")
        I.StrokeBind(1, "Stroke", 0.55).Parent = sidebar
        self.Sidebar = sidebar

        self.TabList = I.Create("ScrollingFrame", {
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.new(1, -12, 1, -12),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Parent = sidebar,
        })
        I.Bind(self.TabList, "ScrollBarImageColor3", "Stroke")
        I.Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.TabList })
        I.Create("Frame", {
            Name = "__BottomSpacer",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 0, 8),
            LayoutOrder = 1000000000,
            Parent = self.TabList,
        })

        self.Pages = I.Create("Frame", {
            Position = UDim2.fromOffset(self._sidebarWidth, 0),
            Size = UDim2.new(1, -self._sidebarWidth, 1, 0),
            BackgroundTransparency = 1,
            Parent = body,
        })

        self.EmptyLabel = I.Create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(240, 40),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextWrapped = true,
            Text = "",
            Visible = false,
            ZIndex = 5,
            Parent = self.Pages,
        })
        I.Bind(self.EmptyLabel, "TextColor3", "SubText")

        local splitter = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.new(0, self._sidebarWidth - 4, 0, 0),
            Size = UDim2.new(0, 9, 1, 0),
            ZIndex = 4,
            AutoButtonColor = false,
            Parent = body,
        })
        self.Splitter = splitter
        local splitLine = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 10),
            Size = UDim2.new(0, 1, 1, -20),
            BackgroundColor3 = I.CurrentTheme.Stroke,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = splitter,
        })
        I.Bind(splitLine, "BackgroundColor3", "Stroke")

        splitter.InputBegan:Connect(function(input)
            if self.Minimized or I.DragManager.Active then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            I.BeginDrag(input, splitter, {
                ManagerKey = splitter,
                ModalOwner = self,
                NoAttr = true,
                OnFrame = function(mouse)
                    local sc = I.GetScale()
                    local rel = (mouse.X - body.AbsolutePosition.X) / sc + 4
                    self:SetSidebarWidth(rel)
                end,
                OnEnd = function()
                    I.SaveManager:Set("__sidebarWidth", self._sidebarWidth)
                end,
            })
        end)

        local grip = I.Create("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -3, 1, -3),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = self.Root,
        })
        local gIcon = I.Icon(grip, "Grip", "SubText")
        gIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        gIcon.Position = UDim2.fromScale(0.5, 0.5)
        gIcon.Size = UDim2.fromOffset(12, 12)
        self.ResizeGrip = grip

        grip.InputBegan:Connect(function(input)
            if self.Maximized or self.Minimized or I.DragManager.Active then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local startMouse = UserInputService:GetMouseLocation()
            local startSize = self.Root.AbsoluteSize / I.GetScale()
            I.BeginDrag(input, grip, {
                ManagerKey = grip,
                ModalOwner = self,
                NoAttr = true,
                OnFrame = function(mouse)
                    local sc = I.GetScale()
                    local vw2, vh2 = I.Viewport.X / sc, I.Viewport.Y / sc
                    local minW = math.min(self.MinSize.X, math.max(200, vw2 - 12))
                    local minH = math.min(self.MinSize.Y, math.max(160, vh2 - 12))
                    local w = math.clamp(startSize.X + (mouse.X - startMouse.X) / sc, minW, math.max(minW, vw2 - 8))
                    local h = math.clamp(startSize.Y + (mouse.Y - startMouse.Y) / sc, minH, math.max(minH, vh2 - 8))
                    self.Root.Size = UDim2.fromOffset(w, h)
                end,
                OnEnd = function()
                    I.ClampWindowToScreen(self.Root)
                    self:SavePlacement()
                end,
            })
        end)

        local function BringToFront()
            local z = 20
            local isTop = true
            for _, w in ipairs(Kailex.Windows) do
                if w ~= self and not w._destroyed and w.Root and w.Root.Visible and not w._alwaysTop then
                    if w.Root.ZIndex >= self.Root.ZIndex then
                        isTop = false
                    end
                    if w.Root.ZIndex > z then
                        z = w.Root.ZIndex
                    end
                end
            end
            if self._alwaysTop then
                self.Root.ZIndex = 100
            elseif not isTop or self.Root.ZIndex >= 100 then
                self.Root.ZIndex = math.min(99, z + 1)
            end
            Kailex._lastActive = self
        end
        self._focus = BringToFront

        local lastClick = 0
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                BringToFront()
                if I.Device.IsTouch then return end
                local now = os.clock()
                if now - lastClick < 0.3 then
                    lastClick = 0
                    self:SetMaximized(not self.Maximized)
                else
                    lastClick = now
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                local m = UserInputService:GetMouseLocation()
                I.ContextMenu.Show({
                    {
                        Text = self.Maximized and "Restore" or "Maximize",
                        Callback = function()
                            if not self._destroyed then self:SetMaximized(not self.Maximized) end
                        end,
                    },
                    {
                        Text = self.Minimized and "Expand" or "Minimize",
                        Callback = function()
                            if not self._destroyed then self:SetMinimized(not self.Minimized) end
                        end,
                    },
                    { Separator = true },
                    {
                        Text = self._alwaysTop and "Disable always on top" or "Always on top",
                        Callback = function()
                            if self._destroyed then return end
                            self._alwaysTop = not self._alwaysTop
                            if self._alwaysTop then
                                self.Root.ZIndex = 100
                            else
                                BringToFront()
                            end
                        end,
                    },
                    { Separator = true },
                    {
                        Text = "Close",
                        Danger = true,
                        Callback = function()
                            if not self._destroyed then self:Close() end
                        end,
                    },
                }, m.X, m.Y)
            end
        end)

        local expandIcon = I.Icon(self.Root, "Chevron", "SubText")
        expandIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        expandIcon.Position = UDim2.new(1, -18, 0.5, 0)
        expandIcon.Size = UDim2.fromOffset(12, 12)
        expandIcon.Rotation = 180
        expandIcon.Visible = false
        self._expandIcon = expandIcon

        local pillHit = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Visible = false,
            ZIndex = 60,
            Parent = self.Root,
        })
        I.MakeDraggable(pillHit, self.Root, { Clamp = true, ModalOwner = self })
        self.Maid:Give(pillHit.MouseButton1Click:Connect(function()
            if pillHit:GetAttribute("Dragging") then return end
            BringToFront()
            I.PlaySound("Click", 0.6)
            self:SetMinimized(false)
        end))

        function self:SetTitle(t)
            self.Title = tostring(t or "")
            titleLabel.Text = self.Title
        end

        local function applySidebarGeom(horizontal, multi)
            local w = self.Root.Size.X.Offset
            local maxSw = math.max(110, math.min(320, w - 240))
            local sw = math.clamp(self._sidebarWidth or 152, 110, maxSw)
            if not multi then
                self.Sidebar.Visible = false
                self.Splitter.Visible = false
                self.Pages.Position = UDim2.fromOffset(0, 0)
                self.Pages.Size = UDim2.fromScale(1, 1)
            elseif horizontal then
                self.Sidebar.Visible = true
                self.Splitter.Visible = false
                self.Sidebar.Size = UDim2.new(1, 0, 0, 44)
                self.TabList.Size = UDim2.new(1, -12, 0, 32)
                self.TabList.ScrollingDirection = Enum.ScrollingDirection.X
                self.TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
                self.Pages.Position = UDim2.fromOffset(0, 44)
                self.Pages.Size = UDim2.new(1, 0, 1, -44)
            else
                self.Sidebar.Visible = true
                self.Splitter.Visible = true
                self.Sidebar.Size = UDim2.new(0, sw, 1, 0)
                self.TabList.Size = UDim2.new(1, -12, 1, -12)
                self.TabList.ScrollingDirection = Enum.ScrollingDirection.Y
                self.TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
                self.Pages.Position = UDim2.fromOffset(sw, 0)
                self.Pages.Size = UDim2.new(1, -sw, 1, 0)
                self.Splitter.Position = UDim2.new(0, sw - 4, 0, 0)
            end
        end

        function self:SetSidebarWidth(w)
            w = tonumber(w)
            if not w then return end
            local maxSw = math.max(110, math.min(320, self.Root.Size.X.Offset - 240))
            w = math.floor(math.clamp(w, 110, maxSw) + 0.5)
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
                local sw = math.clamp(self._sidebarWidth or 152, 110, maxSw)
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
                    I.Tween(el, "Fast", { TextTransparency = 0 })
                end
            else
                el.Visible = false
            end
        end

        function self:Tab(tabOpts)
            local tab = I.TabClass.new(self, tabOpts)
            table.insert(self.Tabs, tab)
            if #self.Tabs == 1 then
                tab:Select()
            end
            self:UpdateLayout()
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
            I.Tween(self._winScale, "Snappy", { Scale = 0.97 }, function()
                if not self._destroyed then I.Tween(self._winScale, "PopSoft", { Scale = 1 }) end
            end)
            if state then
                KillIntroMotion()
                I.ModalManager.CloseAll(self)
                if self.Root.AnchorPoint.X ~= 0 or self.Root.AnchorPoint.Y ~= 0 then
                    local sc = I.GetScale()
                    self.Root.AnchorPoint = Vector2.new(0, 0)
                    self.Root.Position = UDim2.fromOffset(self.Root.AbsolutePosition.X / sc, self.Root.AbsolutePosition.Y / sc)
                end
                self._preMin = { Size = self.Root.Size, Position = self.Root.Position }
                self.Body.Visible = false
                self.ResizeGrip.Visible = false
                subLabel.Visible = false
                titleLabel.Size = UDim2.new(1, -44, 0, 20)
                for _, b in ipairs(_titleButtons) do b.Visible = false end
                expandIcon.Visible = true
                expandIcon.Size = UDim2.fromOffset(8, 8)
                I.Tween(expandIcon, "Pop", { Size = UDim2.fromOffset(12, 12) })
                pillHit.Visible = true
                if searchActive then setSearch(false) end
                local tw = TextService:GetTextSize(self.Title, I.TS(15), Enum.Font.GothamBold, Vector2.new(10000, 100)).X
                I.Tween(self.Root, "Smooth", { Size = UDim2.fromOffset(tw + 74 + (winIcon and 24 or 0), 38) })
            else
                pillHit.Visible = false
                expandIcon.Visible = false
                for _, b in ipairs(_titleButtons) do b.Visible = true end
                subLabel.Visible = true
                titleLabel.Size = UDim2.new(1, -titleReserve, 0, 20)
                I.Tween(self.Root, "Smooth", { Size = self._preMin and self._preMin.Size or UDim2.fromOffset(580, 420) }, function()
                    if not self._destroyed and not self.Minimized then
                        self.Body.Visible = true
                        self.ResizeGrip.Visible = not self.Maximized
                    end
                end)
                I.ClampWindowToScreen(self.Root)
            end
        end

        function self:SetMaximized(on)
            if self._destroyed or self.Minimized then return end
            KillIntroMotion()
            local sc = I.GetScale()
            if on then
                local sp = self.Root.AbsolutePosition / sc
                self._restore = { Size = self.Root.Size, X = sp.X, Y = sp.Y }
                self.Maximized = true
                self.ResizeGrip.Visible = false
                setMaxIcon("Restore")
                self.Root.AnchorPoint = Vector2.new(0.5, 0.5)
                self.Root.Position = UDim2.fromOffset(I.Viewport.X / (2 * sc), I.Viewport.Y / (2 * sc))
                I.Tween(self.Root, "Smooth", { Size = UDim2.fromOffset(I.Viewport.X / sc - 16, I.Viewport.Y / sc - 16) })
            else
                self.Maximized = false
                self.ResizeGrip.Visible = true
                setMaxIcon("Maximize")
                self.Root.AnchorPoint = Vector2.new(0, 0)
                if self._restore then
                    self.Root.Position = UDim2.fromOffset(self._restore.X, self._restore.Y)
                    I.Tween(self.Root, "Smooth", { Size = self._restore.Size })
                end
            end
        end

        function self:SavePlacement()
            if self._destroyed or self.Minimized or self.Maximized or self._hidden then return end
            if not self._remember then return end
            I.SaveManager:Set("__win:" .. self.SavePrefix, {
                X = math.floor(self.Root.Position.X.Offset + 0.5),
                Y = math.floor(self.Root.Position.Y.Offset + 0.5),
                W = math.floor(self.Root.Size.X.Offset + 0.5),
                H = math.floor(self.Root.Size.Y.Offset + 0.5),
            })
        end

        function self:ToggleHidden()
            if self._destroyed then return end
            self._hidden = not self._hidden
            if self._hidden then
                I.ModalManager.CloseAll(self)
                self.Root.Visible = false
            else
                self.Root.Visible = true
                BringToFront()
            end
        end

        function self:OnViewport()
            if self._destroyed then return end
            local sc = I.GetScale()
            I.ClampWindowToScreen(self.Root)
            if self.Minimized then return end
            I.ModalManager.CloseAll(self)
            local vw2, vh2 = I.Viewport.X / sc, I.Viewport.Y / sc
            local minW = math.min(self.MinSize.X, math.max(200, vw2 - 12))
            local minH = math.min(self.MinSize.Y, math.max(160, vh2 - 12))
            local w, h
            if self.Maximized then
                w, h = vw2 - 16, vh2 - 16
            else
                w = math.clamp(self.Root.Size.X.Offset, minW, math.max(minW, vw2 - 12))
                h = math.clamp(self.Root.Size.Y.Offset, minH, math.max(minH, vh2 - 12))
            end
            self.Root.Size = UDim2.fromOffset(w, h)
            self:UpdateLayout()
        end

        function self:Close(skipConfirm)
            if self._destroyed then return end
            if not skipConfirm and cfg.ConfirmClose then
                Kailex:Confirm({
                    Title = "Close " .. self.Title .. "?",
                    Text = tostring(cfg.ConfirmClose),
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
            self:SavePlacement()
            self.Closed:Fire()
            for i, w in ipairs(Kailex.Windows) do
                if w == self then table.remove(Kailex.Windows, i) break end
            end
            I.ModalManager.CloseAll(self)
            KillIntroMotion()
            if shadow then shadow.FadeOut() end
            local root = self.Root
            local done = false
            local function finish()
                if done then return end
                done = true
                self.Maid:Destroy()
                if root.Parent then root:Destroy() end
            end
            I.Once(root.Destroying, finish)
            task.delay(0.3, finish)
            I.Tween(self._winScale, "Vanish", { Scale = 0.96 })
            I.Tween(root, "Vanish", { Position = root.Position + UDim2.fromOffset(0, -10) })
            I.Tween(root, "Vanish", { GroupTransparency = 1 }, finish)
        end

        table.insert(Kailex.Windows, self)
        applySidebarGeom(#self.Tabs > 1, false)

        do
            local first = (#Kailex.Windows == 1)
            local dim
            if first then
                dim = I.Create("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 0,
                    Parent = I.LayerWindows,
                })
                introMaid:Give(dim)
                I.Tween(dim, "Smooth", { BackgroundTransparency = 0.5 })
            end

            titleBar.Position = UDim2.new(0, 0, 0, -18)
            body.Position = UDim2.new(0, 0, 0, 74)
            I.Tween(self.Root, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = ROOT_FINAL })
            I.Tween(self._winScale, TweenInfo.new(0.44, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
            I.Tween(titleBar, TweenInfo.new(0.46, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = TITLE_FINAL })
            I.Tween(body, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = BODY_FINAL })

            task.delay(0.1, function()
                if not self._destroyed and shadow then shadow.SetFade(0.55) end
            end)
            task.delay(0.24, function()
                if not self._destroyed and shadow then shadow.SetFade(0) end
            end)
            task.delay(0.55, function()
                if not self._destroyed and dim then
                    I.Tween(dim, "Smooth", { BackgroundTransparency = 1 }, function()
                        dim:Destroy()
                    end)
                end
            end)
        end
        return self
    end

    local uiVisible = true
    function Kailex:SetVisible(state)
        state = state == true
        uiVisible = state
        I.LayerWindows.Visible = state
        I.LayerOverlay.Visible = state
        I.LayerNotify.Visible = state
        I.LayerTooltip.Visible = state
        if not state then
            I.Tooltip.Hide()
            I.ContextMenu.Hide()
            I.ModalManager.CloseAll()
        end
    end
    function Kailex:IsVisible()
        return uiVisible
    end
end
