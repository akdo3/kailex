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
        self._saveKeys = {}
        self._selected = false
        self._openDropdown = nil
        self._autoRow = nil

        self.Page = I.Create("CanvasGroup", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            GroupTransparency = 1,
            Parent = window.Pages,
        })
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
            local isAsset = tonumber(opts.Icon) ~= nil
                or raw:sub(1, 11) == "rbxassetid" or raw:sub(1, 9) == "rbxasset://"
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
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
            I.Tween(prev.Page, "Vanish", { GroupTransparency = 1 }, function()
                if win.CurrentTab ~= prev then prev.Page.Visible = false end
            end)
            prev:_setSelected(false)
        end
        self.Page.Visible = true
        self:_setSelected(true)
        self.Page.GroupTransparency = 1
        I.Tween(self.Page, "Fast", { GroupTransparency = 0 })
        self.Content.CanvasPosition = Vector2.new(0, 0)
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
        section.Maid:Give(function()
            for i, s in ipairs(tab.Sections) do
                if s == section then table.remove(tab.Sections, i) break end
            end
            if tab.CurrentSection == section then tab.CurrentSection = nil end
            if tab._gridFrames then tab:_syncGridFrames() end
        end)
        return section
    end

    function TabClass:AddButton(opts) opts = opts or {}; return self:_track(Elements.Button.new(self, opts)) end
    function TabClass:AddToggle(opts) opts = opts or {}; return self:_track(Elements.Toggle.new(self, opts)) end
    function TabClass:AddSlider(opts) opts = opts or {}; return self:_track(Elements.Slider.new(self, opts)) end
    function TabClass:AddDropdown(opts) opts = opts or {}; return self:_track(Elements.Dropdown.new(self, opts)) end
    function TabClass:AddKeybind(opts) opts = opts or {}; return self:_track(Elements.Keybind.new(self, opts)) end
    function TabClass:AddColorPicker(opts) opts = opts or {}; return self:_track(Elements.ColorPicker.new(self, opts)) end
    function TabClass:AddTextInput(opts) opts = opts or {}; return self:_track(Elements.TextInput.new(self, opts)) end
    function TabClass:AddLabel(opts) opts = opts or {}; return self:_track(Elements.Label.new(self, opts)) end
    function TabClass:AddParagraph(opts) opts = opts or {}; return self:_track(Elements.Paragraph.new(self, opts)) end
    function TabClass:AddDivider(opts) opts = opts or {}; return self:_track(Elements.Divider.new(self, opts)) end
    function TabClass:AddProgressBar(opts) opts = opts or {}; return self:_track(Elements.ProgressBar.new(self, opts)) end
    function TabClass:AddStepper(opts) opts = opts or {}; return self:_track(Elements.Stepper.new(self, opts)) end
    function TabClass:AddSegmented(opts) opts = opts or {}; return self:_track(Elements.Segmented.new(self, opts)) end
    function TabClass:AddVector3Input(opts) opts = opts or {}; return self:_track(Elements.Vector3Input.new(self, opts)) end

    function TabClass:AddRow(cols)
        self._autoRow = nil
        cols = math.clamp(math.floor(tonumber(cols) or 2), 1, 6)
        local row = setmetatable({ Tab = self, Cols = cols, Manual = true }, I.GridRow)
        row:_newFrame()
        return row
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
                if vis and q ~= "" then matches += 1 end
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
                        if vis and q ~= "" then childMatch += 1 end
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
            if not el._destroyed and el.SearchText and el.SearchText:find(q, 1, true) then n += 1 end
        end
        for _, sec in ipairs(self.Sections) do
            if not sec._destroyed then
                if sec.Title:lower():find(q, 1, true) then n += 1 end
                for _, el in ipairs(sec.Elements) do
                    if not el._destroyed and el.SearchText and el.SearchText:find(q, 1, true) then n += 1 end
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
        local el = tostring(opts.SaveKey or opts.Name or opts.Title or "Element")
        local base = self.Window.SavePrefix .. "/" .. self.Title .. "/" .. el
        local seen = self._saveKeys
        local n = (seen[base] or 0) + 1
        seen[base] = n
        if n > 1 then return base .. " #" .. n end
        return base
    end

    function TabClass:AddDataTable(opts) opts = opts or {}; return self:_track(Elements.DataTable.new(self, opts)) end
end
