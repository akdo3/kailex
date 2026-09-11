return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService
    local Window = I.WindowClass

    local Layout = {}

    function Layout.build(self)
        self._sidebarWidth = math.clamp(tonumber(I.SaveManager:Get("__sidebarWidth", 152)) or 152, 110, 320)

        local sidebar = I.Create("Frame", {
            Size = UDim2.new(0, self._sidebarWidth, 1, 0),
            BackgroundColor3 = I.CurrentTheme.TabBar,
            BorderSizePixel = 0,
            Parent = self.Body,
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
            Parent = self.Body,
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

        local splitW = I.Device.IsTouch and 26 or 9
        self._splitW = splitW

        local splitter = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.new(0, self._sidebarWidth - math.floor(splitW / 2), 0, 0),
            Size = UDim2.new(0, splitW, 1, 0),
            ZIndex = 4,
            AutoButtonColor = false,
            Parent = self.Body,
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
                    local rel = (mouse.X - self.Body.AbsolutePosition.X) / sc + math.floor(splitW / 2)
                    self:SetSidebarWidth(rel)
                end,
                OnEnd = function()
                    I.SaveManager:Set("__sidebarWidth", self._sidebarWidth)
                end,
            })
        end)

        local gripSize = I.Device.IsTouch and 44 or 18
        local grip = I.Create("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -3, 1, -3),
            Size = UDim2.fromOffset(gripSize, gripSize),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = self.Root,
        })
        I.Icon(grip, "Grip", "SubText", I.Device.IsTouch and 18 or 12)
        self.ResizeGrip = grip

        grip.InputBegan:Connect(function(input)
            if self.Minimized or I.DragManager.Active then return end
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
                    local vw, vh = I.Viewport.X / sc, I.Viewport.Y / sc
                    local minW = math.min(self.MinSize.X, math.max(200, vw - 12))
                    local minH = math.min(self.MinSize.Y, math.max(160, vh - 12))
                    local w = math.clamp(startSize.X + (mouse.X - startMouse.X) / sc, minW, math.max(minW, vw - 8))
                    local h = math.clamp(startSize.Y + (mouse.Y - startMouse.Y) / sc, minH, math.max(minH, vh - 8))
                    self.Root.Size = UDim2.fromOffset(w, h)
                end,
                OnEnd = function()
                    I.ClampWindowToScreen(self.Root)
                    self:SavePlacement()
                end,
            })
        end)

        self.Maid:Give(self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:UpdateLayout()
        end))
    end

    function Layout.geom(self, horizontal, multi)
        local w = self.Root.Size.X.Offset
        local maxSw = math.max(110, math.min(320, w - 240))
        local sw = math.clamp(self._sidebarWidth or 152, 110, maxSw)
        local halfSplit = math.floor((self._splitW or 9) / 2)
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
            self.Splitter.Position = UDim2.new(0, sw - halfSplit, 0, 0)
        end
    end

    function Window:SetSidebarWidth(w)
        w = tonumber(w)
        if not w then return end
        local maxSw = math.max(110, math.min(320, self.Root.Size.X.Offset - 240))
        w = math.floor(math.clamp(w, 110, maxSw) + 0.5)
        if w == self._sidebarWidth then return end
        self._sidebarWidth = w
        Layout.geom(self, self._lastHorizontal == true, #self.Tabs > 1)
    end

    function Window:UpdateLayout()
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
                Layout.geom(self, horizontal, multi)
                for _, tab in ipairs(self.Tabs) do
                    tab:_setHorizontal(horizontal)
                end
            end
        end)
    end

    I.WindowLayout = Layout
end
