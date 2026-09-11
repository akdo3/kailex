return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local DROP_VIRTUALIZE = 60
    local DROP_SEARCH_AT = 12

    local View = {}

    function View.findOpt(S, key)
        for _, o in ipairs(S.options) do
            if o.Key == key then return o end
        end
        return nil
    end

    function View.setSelection(S, items)
        local ns = {}
        for _, x in ipairs(items) do
            if x ~= nil then
                local o = View.findOpt(S, tostring(x))
                if o then ns[o.Key] = true end
            end
        end
        S.selSet = ns
    end

    function View.selectedOpts(S)
        local out = {}
        for _, o in ipairs(S.options) do
            if S.selSet[o.Key] then out[#out + 1] = o end
        end
        return out
    end

    function View.valuesOf(list)
        local out = {}
        for _, o in ipairs(list) do out[#out + 1] = o.Value end
        return out
    end

    function View.saveSelection(S)
        local sel = View.selectedOpts(S)
        I.SaveValue(S.saveKey, S.multi and View.valuesOf(sel) or (sel[1] and sel[1].Value or nil))
    end

    function View.initOptions(S)
        S.options = I.NormalizeOptions(S.opts.Options or S.opts.Items)
        S.display = S.options
        S.searchShown = (#S.options > DROP_SEARCH_AT) or S.opts.Searchable == true
    end

    function View.applyQuery(S)
        if S.query == "" then
            S.display = S.options
            return
        end
        local out = {}
        for _, o in ipairs(S.options) do
            if o.Text:lower():find(S.query, 1, true) then out[#out + 1] = o end
        end
        S.display = out
    end

    function View.setOptions(S, newOptions)
        S.options = I.NormalizeOptions(newOptions)
        View.applyQuery(S)
        local valid = {}
        for _, opt in ipairs(S.options) do valid[opt.Key] = true end
        local ns = {}
        for k in pairs(S.selSet) do
            if valid[k] then ns[k] = true end
        end
        S.selSet = ns
    end

    function View.initSelection(S)
        local opts, multi = S.opts, S.multi
        local defaults
        if multi then
            local sv = I.SaveManager:Get(S.saveKey, nil)
            if type(sv) == "table" then
                defaults = sv
            elseif type(opts.Defaults) == "table" then
                defaults = opts.Defaults
            end
        else
            local sv = I.SaveManager:Get(S.saveKey, nil)
            local d
            if sv ~= nil and type(sv) ~= "table" then
                d = sv
            elseif opts.Default ~= nil then
                d = opts.Default
            end
            if d ~= nil then defaults = { d } end
        end
        S.selSet = {}
        if defaults then View.setSelection(S, defaults) end
    end

    function View.measureWidth(S)
        local w = 96
        local cap = math.min(#S.options, 120)
        for i = 1, cap do
            local text = S.options[i].Text
            if #text > 64 then text = text:sub(1, 64) end
            local b = I.TextService:GetTextSize(text, I.TS(12), Enum.Font.Gotham, Vector2.new(2000, 20))
            if b.X > w then w = b.X end
        end
        return math.clamp(w + 30, 122, 220)
    end

    function View.initRow(S)
        local opts, tab = S.opts, S.tab
        local baseH = I.ROW_H + (opts.Description and 16 or 0)
        local rightW = View.measureWidth(S)
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Dropdown",
            RightWidth = rightW,
            Height = baseH,
            Width = opts.Width,
            Description = opts.Description,
        })
        S.row, S.title, S.right, S.left = row, title, right, left
        S.rightW = rightW
        S.baseH = baseH

        S.valueLabel = I.Create("TextLabel", {
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
        S.chevHolder = I.Icon(right, "Chevron", "SubText")
        S.chevHolder.LayoutOrder = 2

        S.headerH = (S.searchShown or S.multi) and 28 or 0
        S.optH = I.Device.IsTouch and 38 or 30
        S.pad = 4
        S.innerList = 26
        S.query = ""
        S.optionButtons = {}
        S.virtual = false
        S.virtualButtons = {}
        S.virtualPool = {}
        S.expanded = false
        S.hl = nil
    end

    function View.buildUI(S)
        if S.list then return end
        local self = S.self

        S.mc = I.ModalCard.MakeAnchor({
            Size = UDim2.new(0, 120, 0, 0),
            BgKey = "SurfaceLight",
            BgTransparency = 0.05,
            Corner = 10,
            StrokeT = 0.2,
            ShadowR = 10,
            ZIndex = 100,
            Owner = S.tab.Window,
            Closer = S.closeFn,
            OnCatcherClick = S.closeFn,
        })
        S.list = S.mc.Card
        S.catcher = S.mc.Catcher
        S.shadow = S.mc.Shadow

        S.header = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = S.list,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = I.HAlign(),
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })

        S.listCanvas = I.Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Parent = S.list,
        })
        I.Bind(S.listCanvas, "ScrollBarImageColor3", "Stroke")

        if S.searchShown then
            S.searchBox = I.Create("TextBox", {
                Size = UDim2.new(1, S.multi and -84 or -32, 1, -6),
                BackgroundColor3 = I.CurrentTheme.Surface,
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.Text,
                PlaceholderText = "Search...",
                PlaceholderColor3 = I.CurrentTheme.SubText,
                TextXAlignment = I.XAlign(),
                ClearTextOnFocus = false,
                Text = "",
                LayoutOrder = 1,
                Parent = S.header,
                Children = {
                    I.Corner(6),
                    I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
                    I.StrokeBind(1, "Stroke", 0.5),
                },
            })
            I.Bind(S.searchBox, "BackgroundColor3", "Surface")
            I.Bind(S.searchBox, "TextColor3", "Text")
            I.Bind(S.searchBox, "PlaceholderColor3", "SubText")

            local clearBtn = I.Create("TextButton", {
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1,
                Text = "×",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = I.CurrentTheme.SubText,
                AutoButtonColor = false,
                LayoutOrder = 4,
                Visible = false,
                Parent = S.header,
                Children = { I.Corner(5) },
            })
            I.Bind(clearBtn, "TextColor3", "SubText")

            S.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                clearBtn.Visible = S.searchBox.Text ~= ""
                S.query = S.searchBox.Text:lower()
                View.applyQuery(S)
                S.hl = nil
                S.listCanvas.CanvasPosition = Vector2.new(0, 0)
                View.buildOptions(S)
            end)

            clearBtn.MouseButton1Click:Connect(function()
                S.searchBox.Text = ""
                pcall(function() S.searchBox:CaptureFocus() end)
            end)
        end

        if S.multi then
            local function mkMini(text, order)
                return I.MkButton(S.header, {
                    Size = UDim2.fromOffset(26, 20),
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    LayoutOrder = order,
                }, { Text = "SubText", Corner = 5 })
            end
            S.allBtn = mkMini("All", 2)
            S.noneBtn = mkMini("None", 3)

            S.allBtn.MouseButton1Click:Connect(function()
                for _, o in ipairs(S.options) do S.selSet[o.Key] = true end
                S.commitSel()
                I.RunCallback(self.Callback, self.Title, self:Get())
            end)
            S.noneBtn.MouseButton1Click:Connect(function()
                S.selSet = {}
                S.commitSel()
                I.RunCallback(self.Callback, self.Title, self:Get())
            end)
        end

        S.emptyLabel = I.Create("TextLabel", {
            Position = UDim2.new(0, 0, 0, 6),
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = I.XAlign(),
            Text = "No options",
            LayoutOrder = 1000000000,
            Visible = false,
            Parent = S.listCanvas,
        })
        I.Bind(S.emptyLabel, "TextColor3", "SubText")

        S.listCanvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if S.virtual and S.expanded then View.updateVirtualWindow(S) end
        end)
        S.listCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if S.virtual and S.expanded then View.updateVirtualWindow(S) end
        end)
    end

    function View.buildOptions(S)
        if not S.listCanvas then return end
        if S._builtOpts == S.options and S._builtQuery == S.query then
            View.refreshOptions(S)
            if S.expanded then
                local sc = I.GetScale()
                S.list.Size = UDim2.new(0, math.max(140, S.row.AbsoluteSize.X / sc), 0, S.headerH + S.innerList)
            end
            return
        end
        View.clearButtons(S)
        local count = #S.display
        S.virtual = count > DROP_VIRTUALIZE
        S.emptyLabel.Visible = count == 0

        local layout = S.listCanvas:FindFirstChildOfClass("UIListLayout")
        if not S.virtual and not layout then
            I.Create("UIListLayout", {
                Padding = UDim.new(0, S.pad),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = S.listCanvas,
            })
        elseif S.virtual and layout then
            layout:Destroy()
        end

        if S.virtual then
            S.listCanvas.AutomaticCanvasSize = Enum.AutomaticSize.None
            S.listCanvas.CanvasSize = UDim2.new(0, 0, 0, count * (S.optH + S.pad) + 8)
            S.innerList = math.min(count, 6) * S.optH + math.min(count, 5) * S.pad + 12
            View.updateVirtualWindow(S)
        else
            S.listCanvas.AutomaticCanvasSize = Enum.AutomaticSize.Y
            S.listCanvas.CanvasSize = UDim2.new()
            local rows = math.clamp(count, 1, 6)
            S.innerList = count > 0 and (rows * S.optH + (rows - 1) * S.pad + 12) or 26
            for i, opt in ipairs(S.display) do
                local rec = View.newRec(S)
                rec._idx = i
                rec.Button.LayoutOrder = i
                S.optionButtons[i] = rec
                View.paintRec(S, rec, opt)
            end
        end
        S.header.Size = UDim2.new(1, 0, 0, S.headerH)
        S.listCanvas.Position = UDim2.new(0, 0, 0, S.headerH)
        S.listCanvas.Size = UDim2.new(1, 0, 1, -S.headerH)
        View.refreshOptions(S)
        if S.expanded then
            local sc = I.GetScale()
            S.list.Size = UDim2.new(0, math.max(140, S.row.AbsoluteSize.X / sc), 0, S.headerH + S.innerList)
        end
        S._builtOpts, S._builtQuery = S.options, S.query
    end

    I.DropdownView = View
end
