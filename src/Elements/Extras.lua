return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting
    local Elements = I.Elements
    local Element = I.Element
    local removeFrom = I.RemoveFrom

    function Element:EnsureRight()
        if self._destroyed then return nil end
        if self.RightContainer then return self.RightContainer end
        if not self.Row or not self.Row.Parent then return nil end
        local right = I.Create("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0.5),
            Position = Setting.RTL and UDim2.new(0, 0, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, -4),
            Parent = self.Row,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = I.HAlign(),
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })
        self.RightContainer = right
        self:RecalcWidth()
        return right
    end

    function Element:AddExtra(className, opts)
        if self._destroyed then return nil end
        if not self.Tab then return nil end
        local elClass = Elements[className]
        if not elClass then return nil end
        local rc = self:EnsureRight()
        if not rc then return nil end
        opts = opts or {}
        if self.Tab and self.Tab._pendingKeyRelease then
            self.Tab._pendingKeyRelease = nil
        end
        local el = elClass.new(self.Tab, opts)
        if self.Tab and self.Tab._consumeKeyRelease then
            self.Tab:_consumeKeyRelease(el)
        end

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

        row.Parent = rc
        row.LayoutOrder = (#self._extras + 1) + 10
        row.Size = UDim2.new(0, el._width or 0, 0, el._extraH or I.ROW_H)

        removeFrom(self.Tab.Elements, el)
        if el.Section then
            removeFrom(el.Section.Elements, el)
            el.Section = nil
        end

        table.insert(self._extras, el)
        self._extraW = (self._extraW or 0) + (el._width or 0)
        self:RecalcWidth()

        el.Maid:Give(function()
            if self._destroyed then return end
            removeFrom(self._extras, el)
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
end
