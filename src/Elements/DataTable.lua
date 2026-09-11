return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.DataTable = I.MakeElementClass()

    function Elements.DataTable.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.DataTable)

        local columns = {}
        for i, c in ipairs(opts.Columns or {}) do
            columns[i] = {
                Name = tostring(type(c) == "table" and (c.Name or c.Title) or c),
                Width = type(c) == "table" and tonumber(c.Width) or nil,
            }
        end

        local bodyH = tonumber(opts.Height) or 200
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Table", Height = bodyH, RightWidth = 0, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self:_initRow(title, right, left, 0, 0)
        self.Callback = opts.Callback or nil

        local rowH = I.Device.IsTouch and 34 or 26
        local rows = {}
        local sortCol, sortAsc = nil, true

        local header = I.Create("Frame", {
            Position = UDim2.new(0, 0, 0, 4),
            Size = UDim2.new(1, 0, 0, rowH),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Parent = left,
            Children = { I.Corner(6) },
        })
        I.Bind(header, "BackgroundColor3", "SurfaceLight")

        local canvas = I.Create("ScrollingFrame", {
            Position = UDim2.new(0, 0, 0, rowH + 8),
            Size = UDim2.new(1, 0, 1, -(rowH + 14)),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Parent = left,
        })
        I.Bind(canvas, "ScrollBarImageColor3", "Stroke")
        I.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = canvas })

        local function buildRows()
            for _, ch in ipairs(canvas:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            local list = rows
            if sortCol then
                local col = sortCol
                local asc = sortAsc
                list = table.clone(rows)
                local allNum = true
                for _, r in ipairs(list) do
                    if tonumber(r.Cells[col]) == nil then allNum = false break end
                end
                table.sort(list, function(a, b)
                    local av, bv = a.Cells[col], b.Cells[col]
                    if allNum then
                        local an, bn = tonumber(av), tonumber(bv)
                        if asc then return an < bn else return an > bn end
                    end
                    av, bv = tostring(av), tostring(bv)
                    if asc then return av < bv else return av > bv end
                end)
            end
            for ri, r in ipairs(list) do
                local rBtn = I.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, rowH),
                    BackgroundColor3 = I.CurrentTheme.Element,
                    BackgroundTransparency = (ri % 2 == 0) and 0.45 or 0.75,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = ri,
                    Parent = canvas,
                    Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) },
                })
                I.Bind(rBtn, "BackgroundColor3", "Element")
                I.AddHover(rBtn, { BaseTransparency = (ri % 2 == 0) and 0.45 or 0.75, HoverTransparency = 0.2, IgnoreStroke = true })
                for ci, col in ipairs(columns) do
                    local w = col.Width or math.floor(300 / math.max(1, #columns))
                    local cl = I.Create("TextLabel", {
                        Position = UDim2.fromOffset((ci - 1) * (w + 2), 0),
                        Size = UDim2.fromOffset(w, rowH),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextColor3 = I.CurrentTheme.SubText,
                        TextXAlignment = I.XAlign(),
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = tostring(r.Cells[ci] or ""),
                        Parent = rBtn,
                        Children = { I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) },
                    })
                    I.Bind(cl, "TextColor3", "SubText")
                end
                rBtn.MouseButton1Click:Connect(function()
                    if self._disabled then return end
                    if self.Callback then I.RunCallback(self.Callback, self.Title, r.Data, r.Index) end
                end)
            end
        end

        local headerButtons = {}
        for i, col in ipairs(columns) do
            local w = col.Width or math.floor(300 / math.max(1, #columns))
            local hb = I.Create("TextButton", {
                Position = UDim2.fromOffset((i - 1) * (w + 2), 0),
                Size = UDim2.fromOffset(w, rowH),
                BackgroundTransparency = 1,
                Text = col.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                TextXAlignment = I.XAlign(),
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                Parent = header,
                Children = { I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) },
            })
            I.Bind(hb, "TextColor3", "SubText")
            I.AddHover(hb, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
            headerButtons[i] = hb
            hb.MouseButton1Click:Connect(function()
                if sortCol == i then
                    sortAsc = not sortAsc
                else
                    sortCol = i
                    sortAsc = true
                end
                for j, b2 in ipairs(headerButtons) do
                    b2.Text = columns[j].Name .. (sortCol == j and (sortAsc and " ▲" or " ▼") or "")
                end
                buildRows()
            end)
        end

        function self:SetRows(newRows, keepSort)
            if self._destroyed then return end
            rows = {}
            for i, r in ipairs(newRows or {}) do
                if type(r) == "table" and r.Cells ~= nil then
                    rows[#rows + 1] = { Cells = r.Cells, Data = r.Data, Index = i }
                elseif type(r) == "table" then
                    rows[#rows + 1] = { Cells = r, Data = r, Index = i }
                else
                    rows[#rows + 1] = { Cells = { tostring(r) }, Data = r, Index = i }
                end
            end
            if not keepSort then sortCol = nil end
            buildRows()
        end
        function self:GetRows()
            local out = {}
            for _, r in ipairs(rows) do out[#out + 1] = r.Data end
            return out
        end
        function self:Sort(colIndex, asc)
            sortCol = tonumber(colIndex)
            sortAsc = asc ~= false
            buildRows()
        end

        if opts.Rows then self:SetRows(opts.Rows) end
        return self
    end
end
