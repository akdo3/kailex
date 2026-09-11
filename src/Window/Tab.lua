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

        self.Button = I.Create("TextButton", {
            BackgroundTransparency = 1,
            BackgroundColor3 = I.CurrentTheme.Element,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            AutoButtonColor = false,
            Parent = window.TabList,
        })
        I.Bind(self.Button, "BackgroundColor3", "Element")
        I.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = self.Button })
        I.Create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = self.Button })
        self.Bar = I.Create("Frame", {
            AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5),
            Position = Setting.RTL and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 8),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = self.Button,
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
            Parent = self.Button,
        })
        I.Bind(self.Badge, "TextColor3", "SubText")

        local iconOffset = 12
        if opts.Icon then
            iconOffset = 32
            local raw = tostring(opts.Icon)
            local isAsset = I.IsAssetId(opts.Icon)
            if isAsset then
                self.IconImg = I.Create("ImageLabel", {
                    AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5),
                    Position = Setting.RTL and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundTransparency = 1,
                    Image = tonumber(opts.Icon) and ("rbxassetid://" .. opts.Icon) or opts.Icon,
                    ImageColor3 = I.CurrentTheme.SubText,
                    Parent = self.Button,
                })
                I.Bind(self.IconImg, "ImageColor3", "SubText")
            else
                self.IconImg = I.Icon(self.Button, raw, "SubText")
                self.IconImg.AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5)
                self.IconImg.Position = Setting.RTL and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
                self.IconImg.Size = UDim2.fromOffset(16, 16)
            end
        end
        self._iconOffset = iconOffset
        self.Label = I.Create("TextLabel", {
            Position = Setting.RTL and UDim2.new(1, -iconOffset, 0, 0) or UDim2.fromOffset(iconOffset, 0),
            Size = UDim2.new(1, -iconOffset - 6, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = self.Title,
            Parent = self.Button,
        })

        self.Maid = I.Maid.new()
        window.Maid:Give(self.Maid)
        self.Maid:Give(self.Button.MouseButton1Click:Connect(function()
            I.ApplyRipple(self.Button)
            I.PlaySound("Click", 0.6)
            self:Select()
        end))
        self.Maid:Give(Kailex.ThemeChanged:Connect(function()
            self:_setSelected(self._selected)
        end))
        self:_setSelected(false)
        return self
    end

    function TabClass:_setSelected(on)
        self._selected = on
        I.Tween(self.Button, "Fast", { BackgroundTransparency = on and 0 or 1 })
        I.Tween(self.Bar, "PopSoft", {
            BackgroundTransparency = on and 0 or 1,
            Size = on and UDim2.fromOffset(3, 16) or UDim2.fromOffset(3, 8),
        })
        I.Tween(self.Label, "Fast", { TextColor3 = on and I.CurrentTheme.Text or I.CurrentTheme.SubText })
        if self.IconImg and self.IconImg:IsA("ImageLabel") then
            I.Tween(self.IconImg, "Fast", { ImageColor3 = on and I.CurrentTheme.Text or I.CurrentTheme.SubText })
        end
    end

    function TabClass:_setHorizontal(on)
        if self._horizontalState == on then return end
        self._horizontalState = on
        if on then
            self.Button.AutomaticSize = Enum.AutomaticSize.X
            self.Button.Size = UDim2.new(0, 0, 1, -8)
            self.Label.AutomaticSize = Enum.AutomaticSize.X
            self.Label.Size = UDim2.new(0, 0, 1, 0)
            self.Bar.Visible = false
        else
            self.Button.AutomaticSize = Enum.AutomaticSize.None
            self.Button.Size = UDim2.new(1, 0, 0, 30)
            self.Label.AutomaticSize = Enum.AutomaticSize.None
            self.Label.Size = UDim2.new(1, -(self._iconOffset or 12) - 6, 1, 0)
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

    function TabClass:_consumeKeyRelease(el)
        local pending = self._pendingKeyRelease
        if not pending or not el or not el.Maid then return end
        self._pendingKeyRelease = nil
        local used = self._liveKeys[pending.base]
        el.Maid:Give(function()
            if used then used[pending.idx] = nil end
        end)
    end

    function TabClass:GetSaveKey(opts)
        opts = opts or {}
        local el = tostring(opts.SaveKey or opts.Name or opts.Title or "Element")
        local base = self.Window.SavePrefix .. "/" .. self.Title .. "/" .. el
        local used = self._liveKeys[base]
        if not used then used = {} self._liveKeys[base] = used end
        local idx = 1
        while used[idx] do idx += 1 end
        used[idx] = true
        self._pendingKeyRelease = { base = base, idx = idx }
        if idx > 1 then return base .. " #" .. idx end
        return base
    end

    function TabClass:_track(el)
        self:_consumeKeyRelease(el)
        local opts = el._opts or {}
        local row = opts._gridRow
        local span = tonumber(opts.Span) or 1
        if span < 1 then span = 1 end

        if not row then
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
                    local wc = math.floor(1 / wf + 0.34)
                    if wc > 1 then cols = wc end
                end
            end
            if cols > 1 then
                if span > cols then span = cols end
                if not (self._autoRow and self._autoRow.Cols == cols) then
                    self._autoRow = setmetatable({ Tab = self, Cols = cols }, I.GridRow)
                    self._autoRow:_newFrame()
                end
                row = self._autoRow
            end
        end

        if row then
            local cols = row.Cols
            if span > cols then span = cols end
            row:Place(el, span)
        else
            self._autoRow = nil
            el.Row.LayoutOrder = self:_nextOrder()
        end

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
        if win.EmptyLabel and win.EmptyLabel.Visible then
            task.defer(function()
                if win and not win._destroyed and win.CurrentTab == tab and not tab._destroyed then
                    win:ApplyFilter(win._filterQuery)
                end
            end)
        end
        return el
    end

    function TabClass:AddSection(opts)
        if type(opts) == "string" then opts = { Name = opts } end
        opts = opts or {}
        self._autoRow = nil
        local section = Elements.Section.new(self, opts)
        section.Columns = math.clamp(math.floor(tonumber(opts and opts.Columns) or 1), 1, 6)
        section.IsSection = true
        section.Tab = self
        section.Row.LayoutOrder = self:_nextOrder()
        table.insert(self.Sections, section)
        self.CurrentSection = section
        local tab = self
        local win = self.Window
        if win.EmptyLabel and win.EmptyLabel.Visible then
            task.defer(function()
                if win and not win._destroyed and win.CurrentTab == tab and not tab._destroyed then
                    win:ApplyFilter(win._filterQuery)
                end
            end)
        end
        section.Maid:Give(function()
            for i, s in ipairs(tab.Sections) do
                if s == section then table.remove(tab.Sections, i) break end
            end
            if tab.CurrentSection == section then tab.CurrentSection = nil end
            for _, el in ipairs(section.Elements) do
                if not el._destroyed then el.Section = nil end
            end
            if tab._gridFrames then tab:_syncGridFrames() end
            if win and not win._destroyed and win.CurrentTab == tab and not tab._destroyed then
                task.defer(function()
                    if win and not win._destroyed and win.CurrentTab == tab and not tab._destroyed then
                        win:ApplyFilter(win._filterQuery)
                    end
                end)
            end
        end)
        return section
    end

    local ADD = {
        Button = Elements.Button, Toggle = Elements.Toggle, Slider = Elements.Slider,
        Dropdown = Elements.Dropdown, Keybind = Elements.Keybind,
        TextInput = Elements.TextInput, ColorPicker = Elements.ColorPicker,
        ProgressBar = Elements.ProgressBar, Stepper = Elements.Stepper,
        Segmented = Elements.Segmented, Vector3Input = Elements.Vector3Input,
        DataTable = Elements.DataTable, Label = Elements.Label,
        Paragraph = Elements.Paragraph, Divider = Elements.Divider,
    }
    for name, class in pairs(ADD) do
        TabClass["Add" .. name] = function(self, opts)
            opts = opts or {}
            self._pendingKeyRelease = nil
            return self:_track(class.new(self, opts))
        end
    end

    function TabClass:AddRow(cols)
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
