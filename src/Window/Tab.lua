return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Elements = I.Elements
    local Setting = I.Setting

    local TabClass = {}
    TabClass.__index = TabClass
    I.TabClass = TabClass

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
        self._liveKeys = {}
        self._pendingKeyRelease = nil
        self._selected = false
        self._openDropdown = nil
        self._autoRow = nil

        local useGroup = not I.Device.IsTouch
        self.Page = I.Create(useGroup and "CanvasGroup" or "Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = window.Pages,
        })
        if useGroup then self.Page.GroupTransparency = 1 end

        self.Content = I.Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Parent = self.Page,
        })
        I.Bind(self.Content, "ScrollBarImageColor3", "Stroke")
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 0),
            Parent = self.Content,
        })
        I.Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.Content,
        })
        I.Create("Frame", {
            Name = "__BottomSpacer",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 16),
            LayoutOrder = 1000000000,
            Parent = self.Content,
        })

        self.TabButton = I.Create("TextButton", {
            BackgroundTransparency = 1,
            BackgroundColor3 = I.CurrentTheme.Element,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            AutoButtonColor = false,
            Parent = window.TabList,
        })
        I.Bind(self.TabButton, "BackgroundColor3", "Element")
        I.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = self.TabButton })
        I.Create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = self.TabButton })
        self.Bar = I.Create("Frame", {
            AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5),
            Position = Setting.RTL and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 8),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = self.TabButton,
        })
        I.Bind(self.Bar, "BackgroundColor3", "Accent")
        I.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.Bar })

        self.Badge = I.Create("TextLabel", {
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0.5),
            Position = Setting.RTL and UDim2.new(0, 6, 0.5, 0) or UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = I.CurrentTheme.SubText,
            Text = "",
            Visible = false,
            Parent = self.TabButton,
        })
        I.Bind(self.Badge, "TextColor3", "SubText")

        local iconOffset = 12
        if opts.Icon then
            iconOffset = 32
            self.IconImg = I.MkIcon(self.TabButton, opts.Icon, {
                AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5),
                Position = Setting.RTL and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
            })
        end

        self._iconOffset = iconOffset
        self.TabLabel = I.Create("TextLabel", {
            Position = Setting.RTL and UDim2.new(1, -iconOffset, 0, 0) or UDim2.fromOffset(iconOffset, 0),
            Size = UDim2.new(1, -iconOffset - 6, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = self.Title,
            Parent = self.TabButton,
        })

        self.Maid = I.Maid.new()
        window.Maid:Give(self.Maid)
        self.Maid:Give(self.TabButton.MouseButton1Click:Connect(function()
            I.ApplyRipple(self.TabButton)
            I.PlaySound("Click", 0.6)
            self:Select()
        end))
        self.Maid:Give(Kailex.ThemeChanged:Connect(function()
            self:_setSelected(self._selected)
        end))
        self:_setSelected(false)

        if window._introKilled then return self end
        self._labelFinal = self.TabLabel.Position
        self._iconTabFinal = self.IconImg and self.IconImg.Position
        local slide = UDim2.fromOffset(Setting.RTL and 20 or -20, 0)
        self.TabLabel.TextTransparency = 1
        self.TabLabel.Position = self._labelFinal + slide
        if self._iconTabFinal then
            self.IconImg.Visible = false
            self.IconImg.Position = self._iconTabFinal + slide
        end

        local function play(delay)
            I.Tween(self.TabLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delay),
                { TextTransparency = 0, Position = self._labelFinal })
            if self._iconTabFinal then
                task.delay(delay, function()
                    if window._destroyed then return end
                    self.IconImg.Visible = true
                    if window._introKilled then
                        self.IconImg.Position = self._iconTabFinal
                    else
                        I.Tween(self.IconImg, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                            { Position = self._iconTabFinal })
                    end
                end)
            end
        end

        if window._assemblyClock then
            local elapsed = os.clock() - window._assemblyClock
            play(math.max(0, 1.85 - elapsed))
        else
            table.insert(window._tabQueue, self)
            self._playIntro = function(_, delay) play(delay) end
        end
        return self
    end

    function TabClass:_setSelected(on)
        self._selected = on
        I.Tween(self.TabButton, "Fast", { BackgroundTransparency = on and 0 or 1 })
        I.Tween(self.Bar, "PopSoft", {
            BackgroundTransparency = on and 0 or 1,
            Size = on and UDim2.fromOffset(3, 16) or UDim2.fromOffset(3, 8),
        })
        I.Tween(self.TabLabel, "Fast", { TextColor3 = on and I.CurrentTheme.Text or I.CurrentTheme.SubText })
        if self.IconImg and self.IconImg:IsA("ImageLabel") then
            I.Tween(self.IconImg, "Fast", { ImageColor3 = on and I.CurrentTheme.Text or I.CurrentTheme.SubText })
        end
    end

    function TabClass:_setHorizontal(on)
        if self._horizontalState == on then return end
        self._horizontalState = on
        if on then
            self.TabButton.AutomaticSize = Enum.AutomaticSize.X
            self.TabButton.Size = UDim2.new(0, 0, 1, -8)
            self.TabLabel.AutomaticSize = Enum.AutomaticSize.X
            self.TabLabel.Size = UDim2.new(0, 0, 1, 0)
            self.Bar.Visible = false
        else
            self.TabButton.AutomaticSize = Enum.AutomaticSize.None
            self.TabButton.Size = UDim2.new(1, 0, 0, 30)
            self.TabLabel.AutomaticSize = Enum.AutomaticSize.None
            self.TabLabel.Size = UDim2.new(1, -(self._iconOffset or 12) - 6, 1, 0)
            self.Bar.Visible = true
        end
    end

    function TabClass:Select()
        local win = self.Window
        if win.CurrentTab == self then return end
        local prev = win.CurrentTab
        win.CurrentTab = self
        win:_closeDropdowns()
        I.ModalManager.CloseAll(win)
        if prev then
            if prev.Page:IsA("CanvasGroup") then
                I.Tween(prev.Page, "Vanish", { GroupTransparency = 1 }, function()
                    if win.CurrentTab ~= prev then prev.Page.Visible = false end
                end)
            else
                prev.Page.Visible = false
            end
            prev:_setSelected(false)
        end
        self.Page.Visible = true
        self:_setSelected(true)
        if self.Page:IsA("CanvasGroup") then
            self.Page.GroupTransparency = 1
            I.Tween(self.Page, "Fast", { GroupTransparency = 0 })
        end
        self.Content.CanvasPosition = Vector2.new(0, 0)
        task.defer(function()
            if not self._destroyed and not win._destroyed and win.CurrentTab == self then
                win:ApplyFilter(win._filterQuery)
            end
        end)
    end

    function TabClass:_nextOrder()
        self._order += 1
        return self._order
    end

    local ADD = {
        Button = Elements.Button, Toggle = Elements.Toggle, Slider = Elements.Slider,
        Dropdown = Elements.Dropdown, Keybind = Elements.Keybind,
        TextInput = Elements.TextInput, ColorPicker = Elements.ColorPicker,
        Stepper = Elements.Stepper,
        Segmented = Elements.Segmented, Vector3Input = Elements.Vector3Input,
        DataTable = Elements.DataTable, Label = Elements.Label,
        Paragraph = Elements.Paragraph, Divider = Elements.Divider,
    }
    for name, class in pairs(ADD) do
        TabClass[name] = function(self, opts)
            opts = opts or {}
            self._pendingKeyRelease = nil
            return self:_track(class.new(self, opts))
        end
    end

    function TabClass:Row(cols)
        self._autoRow = nil
        cols = math.clamp(math.floor(tonumber(cols) or 2), 1, 6)
        local row = setmetatable({ Tab = self, Cols = cols }, I.GridRow)
        row:_newFrame()
        return row
    end

    function TabClass:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        self.Window:RemoveTab(self)
    end
end
