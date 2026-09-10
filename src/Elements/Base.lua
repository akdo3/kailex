return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local Elements = {}
    I.Elements = Elements

    local Element = {}
    Element.__index = Element
    I.Element = Element

    function Element:_init(row, opts, tab)
        opts = opts or {}
        self._opts = opts
        self.Row = row
        self.Maid = I.Maid.new()
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
        if opts.Tooltip then I.AddTooltip(row, self._tooltip) end
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

    function Element:_bindSaveReload(saveKey, fn)
        if not saveKey then return end
        local reg = I.SaveReloadRegistry
        if not reg then return end
        local list = reg[saveKey]
        if not list then list = {} reg[saveKey] = list end
        table.insert(list, fn)
        self.Maid:Give(function()
            for i, f in ipairs(list) do
                if f == fn then table.remove(list, i) break end
            end
        end)
    end

    function Element:SetTitle(text)
        if self._destroyed then return end
        self.Title = tostring(text or "")
        self.SearchText = (self.Title .. " " .. self._searchExtra):lower()
        if self.TitleLabel and self.TitleLabel.Parent then self.TitleLabel.Text = self.Title end
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
        if self.Row then self.Row:SetAttribute("Disabled", v) end
        if self.TitleLabel then I.Tween(self.TitleLabel, "Fast", { TextTransparency = v and 0.55 or 0 }) end
        local st = self.Row and self.Row:FindFirstChildOfClass("UIStroke")
        if st then I.Tween(st, "Fast", { Transparency = v and 0.9 or 0.65 }) end
    end

    function Element:IsDisabled()
        return self._disabled == true
    end

    function Element:RecalcWidth()
        if not self.RightContainer then return end
        local w = (self._baseRightW or 0) + (self._extraW or 0)
        self.RightContainer.Size = UDim2.new(0, w, 1, -4)
        if self.LeftFrame then
            self.LeftFrame.Size = UDim2.new(1, -w, 1, 0)
        end
    end

    function Element:AddExtra(className, opts)
        if self._destroyed then return nil end
        local elClass = Elements[className]
        if not elClass then return nil end
        opts = opts or {}
        local el = elClass.new(self.Tab, opts)

        local row = el.Row
        local pad = row:FindFirstChildOfClass("UIPadding")
        if pad then pad:Destroy() end
        row.BackgroundTransparency = 1
        row:SetAttribute("NoHoverFX", true)
        local rowStroke = row:FindFirstChildOfClass("UIStroke")
        if rowStroke then rowStroke.Transparency = 1 end
        if el.LeftFrame then
            el.LeftFrame.Size = UDim2.new(0, 0, 1, 0)
        end
        if el.TitleLabel and el.TitleLabel:IsA("TextLabel") then
            el.TitleLabel.Visible = false
        end
        if el.RightContainer then
            el.RightContainer.AnchorPoint = Vector2.new(0, 0.5)
            el.RightContainer.Position = UDim2.new(0, 0, 0.5, 0)
            el.RightContainer.Size = UDim2.new(1, 0, 1, 0)
        end

        row.Parent = self.RightContainer
        row.LayoutOrder = (#self._extras + 1) + 10
        row.Size = UDim2.new(0, el._width or 0, 0, el._extraH or I.ROW_H)

        for i, v in ipairs(self.Tab.Elements) do
            if v == el then table.remove(self.Tab.Elements, i) break end
        end
        if el.Section then
            for i, v in ipairs(el.Section.Elements) do
                if v == el then table.remove(el.Section.Elements, i) break end
            end
            el.Section = nil
        end

        table.insert(self._extras, el)
        self._extraW = (self._extraW or 0) + (el._width or 0)
        self:RecalcWidth()

        el.Maid:Give(function()
            if self._destroyed then return end
            for i, v in ipairs(self._extras) do
                if v == el then table.remove(self._extras, i) break end
            end
            self._extraW = math.max(0, (self._extraW or 0) - (el._width or 0))
            self:RecalcWidth()
        end)

        return el
    end

    function Element:AddToggle(opts)
        if self._destroyed then return nil end
        if self.AttachedToggle then return self.AttachedToggle end
        opts = opts or {}
        local tg = self:AddExtra("Toggle", opts)
        if not tg then return nil end
        self.AttachedToggle = tg
        self.Enabled = tg.Changed
        function self:IsEnabled() return tg:Get() == true end
        function self:SetEnabled(v, silent) tg:Set(v == true, silent) end
        return tg
    end

    function Element:_contextItems()
        local items = {}
        if self.CopyValue then
            table.insert(items, { Text = "Copy value", Callback = function()
                local v = self:CopyValue()
                if v ~= nil then I.CopyToClipboard(v) end
            end })
        end
        if self.Reset then
            table.insert(items, { Text = "Reset to default", Callback = function() self:Reset() end })
        end
        table.insert(items, {
            Text = self._disabled and "Enable" or "Disable",
            Callback = function() self:SetDisabled(not self._disabled) end,
        })
        return items
    end

    local function HookContextMenu(el, overlay)
        overlay.MouseButton2Click:Connect(function()
            if el._destroyed then return end
            local items = el:_contextItems()
            if #items == 0 then return end
            local m = I.UserInputService:GetMouseLocation()
            I.ContextMenu.Show(items, m.X, m.Y)
        end)
    end
    I.HookContextMenu = HookContextMenu

    function Element:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if I.HotElement == self then I.HotElement = nil end
        local tab = self.Tab
        if tab then
            for i, el in ipairs(tab.Elements) do
                if el == self then table.remove(tab.Elements, i) break end
            end
            if self.IsSection then
                for i, s in ipairs(tab.Sections) do
                    if s == self then table.remove(tab.Sections, i) break end
                end
                if tab.CurrentSection == self then tab.CurrentSection = nil end
                for _, el in ipairs(self.Elements) do
                    if not el._destroyed then el.Section = nil end
                end
            end
            if self.Section then
                for i, el in ipairs(self.Section.Elements) do
                    if el == self then table.remove(self.Section.Elements, i) break end
                end
            end
        end
        for _, ex in ipairs(self._extras) do
            if not ex._destroyed then ex:Destroy() end
        end
        if self.Changed then self.Changed:Destroy() end
        if self.Maid then self.Maid:Destroy() end
        if self.Row then self.Row:Destroy() end
        self.Row, self.Maid, self.Tab, self.Section = nil, nil, nil, nil
    end

    local function CreateRow(parent, opts)
        opts = opts or {}
        local desc = opts.Description and tostring(opts.Description) or nil
        local height = opts.Height or (desc and (I.ROW_H + 16) or I.ROW_H)
        local rowProps = {
            Size = UDim2.new((opts.Width or 1), -3, 0, height),
            BackgroundColor3 = I.CurrentTheme.Element,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Parent = parent,
            Children = { I.Corner(8), I.StrokeBind(1, "Stroke", 0.65) },
        }
        if type(opts.Order) == "number" then
            rowProps.LayoutOrder = opts.Order
        end
        local row = I.Create("Frame", rowProps)
        I.Bind(row, "BackgroundColor3", "Element")
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2),
            Parent = row,
        })

        local rightW = opts.RightWidth or 0
        local leftFrame = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -rightW, 1, 0),
            Parent = row,
        })
        local title, descLabel
        if desc then
            title = I.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 15),
                Position = UDim2.new(0, 0, 0, 2),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = I.CurrentTheme.Text,
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = opts.Name or "",
                Parent = leftFrame,
            })
            descLabel = I.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 13),
                Position = UDim2.new(0, 0, 0, 17),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                TextTransparency = 0.35,
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = desc,
                Parent = leftFrame,
            })
            I.Bind(descLabel, "TextColor3", "SubText")
        else
            title = I.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 1, 0),
                Position = UDim2.fromOffset(0, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = I.CurrentTheme.Text,
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = opts.Name or "",
                Parent = leftFrame,
            })
        end
        I.Bind(title, "TextColor3", "Text")

        local right = I.Create("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0.5),
            Position = Setting.RTL and UDim2.new(0, 0, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, rightW, 1, -4),
            Parent = row,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Setting.RTL and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })

        if not opts.NoHover then
            I.AddHover(row, { StrokeTransparency = 0.65 })
        end
        return row, title, right, leftFrame, descLabel
    end
    I.CreateRow = CreateRow

    local function MakeElementClass()
        local class = {}
        class.__index = class
        setmetatable(class, { __index = Element })
        return class
    end
    I.MakeElementClass = MakeElementClass
end
