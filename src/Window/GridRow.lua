return function(ctx)
    local I = ctx.Internal

    local GridRow = {}
    GridRow.__index = GridRow
    I.GridRow = GridRow

    function GridRow:_newFrame()
        self.Frame = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            LayoutOrder = self.Tab:_nextOrder(),
            Parent = self.Tab.Content,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = I.Setting.RTL and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })
        self.Frame:SetAttribute("__grid", true)
        if self.Tab._gridFrames then
            table.insert(self.Tab._gridFrames, self.Frame)
        end
        self.Used = 0
        self.CellOrder = 0
        self.FrameH = 0
        self.AutoH = false
    end

    function GridRow:Place(el, span)
        local g = 6
        local cols = self.Cols
        if self.Used + span > cols then
            self:_newFrame()
        end
        local off = math.floor(g * (span - 1) - g * span * (cols - 1) / cols + 0.5)
        local sz = el.Row.Size
        local target = UDim2.new(span / cols, off, sz.Y.Scale, sz.Y.Offset)
        el.Row:SetAttribute("__el", true)
        el._gridFrame = self.Frame
        self.CellOrder += 1
        el.Row.LayoutOrder = self.CellOrder
        el.Row.Size = target
        el.Row.Parent = self.Frame
        if el.Row.AutomaticSize == Enum.AutomaticSize.Y then
            self.Frame.AutomaticSize = Enum.AutomaticSize.Y
            self.AutoH = true
        elseif not self.AutoH then
            if sz.Y.Offset > self.FrameH then
                self.FrameH = sz.Y.Offset
            end
            self.Frame.Size = UDim2.new(1, 0, 0, self.FrameH)
        end
        self.Used += span
    end

    function GridRow:Button(opts) opts = opts or {}; opts._gridRow = self; return self.Tab:Button(opts) end
    function GridRow:Toggle(opts) opts = opts or {}; opts._gridRow = self; return self.Tab:Toggle(opts) end
    function GridRow:Slider(opts) opts = opts or {}; opts._gridRow = self; return self.Tab:Slider(opts) end
    function GridRow:Dropdown(opts) opts = opts or {}; opts._gridRow = self; return self.Tab:Dropdown(opts) end
    function GridRow:Label(opts) opts = opts or {}; opts._gridRow = self; return self.Tab:Label(opts) end
end
