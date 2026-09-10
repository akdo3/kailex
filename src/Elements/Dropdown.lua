return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting

    local DROP_VIRTUALIZE = 60
    local DROP_SEARCH_AT = 12

    Elements.Dropdown = I.MakeElementClass()

    function Elements.Dropdown.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Dropdown)
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
                if o.Key == key then return o end
            end
            return nil
        end

        local selSet = {}
        do
            local defaults
            if multi then
                local sv = I.SaveManager:Get(saveKey, nil)
                if sv ~= nil and type(sv) == "table" then
                    defaults = sv
                elseif type(opts.Defaults) == "table" then
                    defaults = opts.Defaults
                end
            else
                local d
                local sv = I.SaveManager:Get(saveKey, nil)
                if sv ~= nil and type(sv) ~= "table" then
                    d = sv
                elseif opts.Default ~= nil then
                    d = opts.Default
                end
                if d ~= nil then defaults = { d } end
            end
            if defaults then
                for _, d in ipairs(defaults) do
                    local o = findOpt(tostring(d))
                    if o then selSet[o.Key] = true end
                end
            end
        end

        local function selectedOpts()
            local out = {}
            for _, o in ipairs(options) do
                if selSet[o.Key] then out[#out + 1] = o end
            end
            return out
        end

        local function valuesOf(list)
            local out = {}
            for _, o in ipairs(list) do out[#out + 1] = o.Value end
            return out
        end

        local function measureWidth()
            local w = 96
            local cap = math.min(#options, 400)
            for i = 1, cap do
                local text = options[i].Text
                if #text > 64 then text = text:sub(1, 64) end
                local b = I.TextService:GetTextSize(text, I.TS(12), Enum.Font.Gotham, Vector2.new(2000, 20))
                if b.X > w then w = b.X end
            end
            return math.clamp(w + 30, 122, 280)
        end

        local baseH = I.ROW_H + (opts.Description and 16 or 0)
        local rightW = measureWidth()
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Dropdown",
            RightWidth = rightW,
            Height = baseH,
            Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
        self.Callback = opts.Callback or function() end

        local valueLabel = I.Create("TextLabel", {
            Size = UDim2.new(0, rightW - 26, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 1,
            Parent = right,
        })
        local chevHolder = I.Icon(right, "Chevron", "SubText")
        chevHolder.LayoutOrder = 2

        local list = I.Create("CanvasGroup", {
            Size = UDim2.new(0, 120, 0, 0),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Visible = false,
            GroupTransparency = 1,
            ZIndex = 100,
            Parent = I.LayerOverlay,
            Children = { I.Corner(10), I.StrokeBind(1, "Stroke", 0.2) },
        })
        I.Bind(list, "BackgroundColor3", "SurfaceLight")

        local header = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = list,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Setting.RTL and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })

        local listCanvas = I.Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Parent = list,
        })
        I.Bind(listCanvas, "ScrollBarImageColor3", "Stroke")

        local catcher = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Visible = false,
            ZIndex = 99,
            Parent = I.LayerOverlay,
        })

        local searchShown = (#options > DROP_SEARCH_AT) or opts.Searchable == true
        local searchBox
        if searchShown then
            searchBox = I.Create("TextBox", {
                Size = UDim2.new(1, multi and -60 or -8, 1, -6),
                BackgroundColor3 = I.CurrentTheme.Surface,
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.Text,
                PlaceholderText = "Search...",
                PlaceholderColor3 = I.CurrentTheme.SubText,
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Text = "",
                LayoutOrder = 1,
                Parent = header,
                Children = {
                    I.Corner(6),
                    I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
                    I.StrokeBind(1, "Stroke", 0.5),
                },
            })
            I.Bind(searchBox, "BackgroundColor3", "Surface")
            I.Bind(searchBox, "TextColor3", "Text")
            I.Bind(searchBox, "PlaceholderColor3", "SubText")
        end

        local allBtn, noneBtn
        if multi then
            local function mkMini(text, order)
                local b = I.Create("TextButton", {
                    Size = UDim2.fromOffset(26, 20),
                    BackgroundColor3 = I.CurrentTheme.Element,
                    BorderSizePixel = 0,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    TextColor3 = I.CurrentTheme.SubText,
                    AutoButtonColor = false,
                    LayoutOrder = order,
                    Parent = header,
                    Children = { I.Corner(5) },
                })
                I.Bind(b, "BackgroundColor3", "Element")
                I.Bind(b, "TextColor3", "SubText")
                I.AddHover(b)
                return b
            end
            allBtn = mkMini("All", 2)
            noneBtn = mkMini("None", 3)
        end

        local headerH = (searchShown or multi) and 28 or 0

        local emptyLabel = I.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            Text = "No options",
            Visible = false,
            Parent = listCanvas,
        })
        I.Bind(emptyLabel, "TextColor3", "SubText")

        local query = ""
        local display = options
        local optionButtons = {}
        local innerList = 26
        local optH = I.Device.IsTouch and 38 or 30
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
            btn.BackgroundColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Element
            btn.BackgroundTransparency = isSel and 0.75 or 1
            btn.TextColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Text
            if multi and rec.Box then
                rec.Box.BackgroundColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.SurfaceLight
                rec.BoxStroke.Color = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Stroke
                rec.BoxStroke.Transparency = isSel and 0 or 0.4
                rec.Fill.Visible = isSel
                rec.Fill.Size = isSel and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0)
            elseif rec.Check then
                rec.Check.Visible = isSel
                if isSel and rec.Check.Rotation < -10 then rec.Check.Rotation = -80 end
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
                            I.Tween(rec.Check, "Spring", { Rotation = 0 })
                        end
                    end
                end
            end
        end

        refreshLabel = function()
            local text
            if multi then
                local sel = selectedOpts()
                if #sel == 0 then text = "-"
                elseif #sel == 1 then text = sel[1].Text
                else text = #sel .. " selected" end
            else
                local sel = selectedOpts()
                text = (#sel > 0) and sel[1].Text or "-"
            end
            valueLabel.Text = text
            local has = next(selSet) ~= nil
            valueLabel.TextColor3 = has and I.CurrentTheme.Text or I.CurrentTheme.SubText
        end

        local function newRec()
            local btn = I.Create("TextButton", {
                Size = UDim2.new(1, 0, 0, optH),
                BackgroundTransparency = 1,
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = "",
                TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = I.CurrentTheme.Text,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                Parent = listCanvas,
                Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 6) }) },
            })
            local rec = { Button = btn, _idx = nil }
            if multi then
                local box = I.Create("Frame", {
                    AnchorPoint = Vector2.new(Setting.RTL and 1 or 0, 0.5),
                    Position = Setting.RTL and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = I.CurrentTheme.SurfaceLight,
                    BorderSizePixel = 0,
                    Parent = btn,
                    Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 5) }) },
                })
                rec.BoxStroke = I.Create("UIStroke", {
                    Thickness = 1, Transparency = 0.4,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = I.CurrentTheme.Stroke, Parent = box,
                })
                rec.Fill = I.Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 0),
                    BackgroundColor3 = I.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                    Visible = false,
                    Parent = box,
                    Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 2) }) },
                })
            else
                local chk = I.Icon(btn, "Check", "Accent")
                chk.AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0.5)
                chk.Position = Setting.RTL and UDim2.new(0, 8, 0.5, 0) or UDim2.new(1, -8, 0.5, 0)
                chk.Size = UDim2.fromOffset(11, 11)
                chk.Visible = false
                rec.Check = chk
            end
            btn.MouseEnter:Connect(function()
                if I.Device.IsTouch or not expanded or not rec._idx then return end
                I.PlaySound("Hover", 0.1)
                local opt = display[rec._idx]
                local isSel = opt ~= nil and selSet[opt.Key] == true
                I.Tween(btn, "HoverIn", {
                    BackgroundColor3 = isSel and I.CurrentTheme.AccentHover or I.CurrentTheme.ElementHover,
                    BackgroundTransparency = isSel and 0.6 or 0.35,
                })
            end)
            btn.MouseLeave:Connect(function()
                if not rec._idx then return end
                local opt = display[rec._idx]
                local isSel = opt ~= nil and selSet[opt.Key] == true
                I.Tween(btn, "HoverOut", {
                    BackgroundColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Element,
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
            local first = math.max(1, math.floor(top / rowStep) - 2)
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
                    rec.Button.Position = UDim2.fromOffset(0, (idx - 1) * rowStep)
                    paintRec(rec, display[idx])
                end
            end
        end

        setExpanded = function(state)
            if expanded == state then return end
            expanded = state
            I.Tween(chevHolder, "PopSoft", { Rotation = state and 180 or 0 })
            if state then
                if tab._openDropdown and tab._openDropdown ~= closeFn then
                    tab._openDropdown()
                end
                tab._openDropdown = closeFn

                local sc = I.GetScale()
                local ap, asz = row.AbsolutePosition, row.AbsoluteSize
                local rowX, rowY = ap.X / sc, ap.Y / sc
                local rowW, rowH2 = asz.X / sc, asz.Y / sc
                local vw, vh = I.Viewport.X / sc, I.Viewport.Y / sc
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
                    y = math.clamp(rowY + rowH2 + 4, 8, math.max(8, vh - totalH - 8))
                    slideFrom = -6
                end
                local x = math.clamp(rowX, 8, math.max(8, vw - pw - 8))

                listCanvas.CanvasPosition = Vector2.new(0, 0)
                listCanvas.Position = UDim2.new(0, 0, 0, headerH)
                listCanvas.Size = UDim2.new(1, 0, 1, -headerH)
                list.Size = UDim2.new(0, pw, 0, 0)
                list.Position = UDim2.fromOffset(x, y + slideFrom)
                list.Visible = true
                catcher.Visible = true
                list.GroupTransparency = 1
                I.Tween(list, "Snappy", { Size = UDim2.new(0, pw, 0, totalH), GroupTransparency = 0 })
                I.Tween(list, "Smooth", { Position = UDim2.fromOffset(x, y) })

                I.ModalManager.Remove(modalEntry)
                modalEntry = I.ModalManager.Push(tab.Window, closeFn)

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
                            local delayT = math.min(i * 0.02, 0.16)
                            task.delay(delayT, function()
                                if not expanded then return end
                                I.Tween(btn, "Fast", { TextTransparency = 0, BackgroundTransparency = isSel and 0.75 or 1 })
                            end)
                        end
                    end
                end
            else
                if tab._openDropdown == closeFn then tab._openDropdown = nil end
                I.ModalManager.Remove(modalEntry)
                modalEntry = nil
                catcher.Visible = false
                I.Tween(list, "Fast", { Size = UDim2.new(0, list.AbsoluteSize.X / I.GetScale(), 0, 0) })
                I.Tween(list, "Fast", { GroupTransparency = 1 }, function()
                    if not expanded then list.Visible = false end
                end)
            end
        end

        closeFn = function() setExpanded(false) end

        selectOption = function(opt, rippleTarget)
            if not opt then return end
            if self._disabled then return end
            I.PlaySound("Click", 0.7)
            if rippleTarget then I.ApplyRipple(rippleTarget) end
            if multi then
                if selSet[opt.Key] then selSet[opt.Key] = nil
                else selSet[opt.Key] = true end
                refreshOptions()
                refreshLabel()
                I.SaveValue(saveKey, valuesOf(selectedOpts()))
                I.RunCallback(self.Callback, self.Title, self:Get())
            else
                selSet = { [opt.Key] = true }
                refreshOptions()
                refreshLabel()
                I.SaveValue(saveKey, opt.Value)
                setExpanded(false)
                I.RunCallback(self.Callback, self.Title, self:Get())
            end
        end

        local function clearButtons()
            for _, rec in ipairs(optionButtons) do
                if rec.Button then rec.Button:Destroy() end
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
                I.Create("UIListLayout", { Padding = UDim.new(0, pad), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listCanvas })
            elseif virtual and layout then
                layout:Destroy()
            end

            if virtual then
                listCanvas.AutomaticCanvasSize = Enum.AutomaticSize.None
                listCanvas.CanvasSize = UDim2.new(0, 0, 0, count * (optH + pad) + 8)
                innerList = math.min(count, 6) * optH + math.min(count, 5) * pad + 12
                updateVirtualWindow()
            else
                listCanvas.AutomaticCanvasSize = Enum.AutomaticSize.Y
                listCanvas.CanvasSize = UDim2.new()
                local rows = math.clamp(count, 1, 6)
                innerList = count > 0 and (rows * optH + (rows - 1) * pad + 12) or 26
                for i, opt in ipairs(display) do
                    local rec = newRec()
                    rec._idx = i
                    rec.Button.LayoutOrder = i
                    optionButtons[i] = rec
                    paintRec(rec, opt)
                end
            end
            header.Size = UDim2.new(1, 0, 0, headerH)
            listCanvas.Position = UDim2.new(0, 0, 0, headerH)
            listCanvas.Size = UDim2.new(1, 0, 1, -headerH)
            refreshOptions()
            if expanded then
                local sc = I.GetScale()
                list.Size = UDim2.new(0, row.AbsoluteSize.X / sc, 0, headerH + innerList)
            end
        end

        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                query = searchBox.Text:lower()
                if query == "" then
                    display = options
                else
                    local out = {}
                    for _, o in ipairs(options) do
                        if o.Text:lower():find(query, 1, true) then out[#out + 1] = o end
                    end
                    display = out
                end
                listCanvas.CanvasPosition = Vector2.new(0, 0)
                buildOptions()
                refreshOptions()
                if expanded then
                    list.Size = UDim2.new(0, row.AbsoluteSize.X / I.GetScale(), 0, headerH + innerList)
                end
            end)
        end

        if allBtn then
            allBtn.MouseButton1Click:Connect(function()
                for _, o in ipairs(options) do selSet[o.Key] = true end
                refreshOptions()
                refreshLabel()
                I.SaveValue(saveKey, valuesOf(selectedOpts()))
                I.RunCallback(self.Callback, self.Title, self:Get())
            end)
        end
        if noneBtn then
            noneBtn.MouseButton1Click:Connect(function()
                selSet = {}
                refreshOptions()
                refreshLabel()
                I.SaveValue(saveKey, {})
                I.RunCallback(self.Callback, self.Title, self:Get())
            end)
        end

        listCanvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if virtual and expanded then updateVirtualWindow() end
        end)
        listCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if virtual and expanded then updateVirtualWindow() end
        end)

        catcher.MouseButton1Click:Connect(function()
            if expanded then setExpanded(false) end
        end)

        local overlay = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.new(1, 0, 0, baseH),
            ZIndex = 1,
            Parent = row,
        })
        self.Maid:Give(overlay.MouseButton1Click:Connect(function()
            if self._disabled then return end
            I.ApplyRipple(overlay)
            I.PlaySound("Click", 0.7)
            setExpanded(not expanded)
        end))
        I.HookContextMenu(self, overlay)

        self.Maid:Give(function()
            if tab._openDropdown == closeFn then tab._openDropdown = nil end
            I.ModalManager.Remove(modalEntry)
            if list and list.Parent then list:Destroy() end
            if catcher and catcher.Parent then catcher:Destroy() end
        end)

        function self:Set(v, silent)
            if self._destroyed then return end
            local items = (multi and type(v) == "table") and v or { v }
            local ns = {}
            for _, x in ipairs(items) do
                if x ~= nil then
                    local o = findOpt(tostring(x))
                    if o then ns[o.Key] = true end
                end
            end
            selSet = ns
            I.SaveValue(saveKey, multi and valuesOf(selectedOpts()) or (selectedOpts()[1] and selectedOpts()[1].Value or nil))
            refreshOptions()
            refreshLabel()
            if not silent then I.RunCallback(self.Callback, self.Title, self:Get()) end
        end
        function self:Get()
            if multi then return valuesOf(selectedOpts()) end
            local sel = selectedOpts()
            return sel[1] and sel[1].Value or nil
        end
        function self:GetText()
            if multi then
                local out = {}
                for _, o in ipairs(selectedOpts()) do out[#out + 1] = o.Text end
                return out
            end
            local sel = selectedOpts()
            return sel[1] and sel[1].Text or nil
        end
        function self:CopyValue() return table.concat(self:GetText() or {}, ", ") end
        function self:SetOptions(newOptions)
            if self._destroyed then return end
            options = normalize(newOptions)
            local valid = {}
            for _, opt in ipairs(options) do valid[opt.Key] = true end
            local ns = {}
            for k in pairs(selSet) do
                if valid[k] then ns[k] = true end
            end
            selSet = ns
            local newW = measureWidth()
            if newW ~= rightW then
                rightW = newW
                self._baseRightW = rightW
                self._width = rightW
                valueLabel.Size = UDim2.new(0, rightW - 26, 1, 0)
                self:RecalcWidth()
            end
            buildOptions()
            refreshLabel()
        end

        self:_bindSaveReload(saveKey, function(v)
            self:Set(v, true)
        end)
        self.Maid:Give(ctx.Kailex.ThemeChanged:Connect(function()
            refreshLabel()
            if expanded then refreshOptions() end
        end))

        buildOptions()
        refreshLabel()
        if next(selSet) ~= nil then
            task.defer(function()
                if not self._destroyed then I.RunCallback(self.Callback, self.Title, self:Get()) end
            end)
        end

        self:RecalcWidth()
        return self
    end
end
