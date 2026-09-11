return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local TextService = I.TextService
    local Window = I.WindowClass

    local State = {}

    function State.bringToFront(self)
        local z = 20
        local isTop = true
        for _, w in ipairs(Kailex.Windows) do
            if w ~= self and not w._destroyed and w.Root and w.Root.Visible and not w._alwaysTop then
                if w.Root.ZIndex >= self.Root.ZIndex then
                    isTop = false
                end
                if w.Root.ZIndex > z then
                    z = w.Root.ZIndex
                end
            end
        end
        if self._alwaysTop then
            self.Root.ZIndex = 100
        elseif not isTop or self.Root.ZIndex >= 100 then
            self.Root.ZIndex = math.min(99, z + 1)
        end
        for _, w in ipairs(Kailex.Windows) do
            if w ~= self and not w._destroyed and w.TitleLabel then
                I.Tween(w.TitleLabel, "Fast", { TextTransparency = 0.45 })
            end
        end
        if self.TitleLabel then
            I.Tween(self.TitleLabel, "Fast", { TextTransparency = 0 })
        end
        Kailex._lastActive = self
    end

    function State.killIntro(self)
        I.Tween(self.Root, "Instant", { Position = self._rootFinal, GroupTransparency = 0 })
        I.Tween(self._winScale, "Instant", { Scale = 1 })
        I.Tween(self.TitleBar, "Instant", { Position = self._titleFinal })
        I.Tween(self.Body, "Instant", { Position = self._bodyFinal })
        if self._shadow then self._shadow.SetFade(0) end
        if self._introMaid then self._introMaid:Destroy() end
    end

    function Window:SetMinimized(state)
        if self._destroyed or self.Minimized == state then return end
        self.Minimized = state
        self.MinimizedChanged:Fire(state)
        I.Tween(self._winScale, "Snappy", { Scale = 0.97 }, function()
            if not self._destroyed then I.Tween(self._winScale, "PopSoft", { Scale = 1 }) end
        end)
        if state then
            State.killIntro(self)
            I.ModalManager.CloseAll(self)
            if self.Root.AnchorPoint.X ~= 0 or self.Root.AnchorPoint.Y ~= 0 then
                local sc = I.GetScale()
                self.Root.AnchorPoint = Vector2.new(0, 0)
                self.Root.Position = UDim2.fromOffset(self.Root.AbsolutePosition.X / sc, self.Root.AbsolutePosition.Y / sc)
            end
            self._preMin = { Size = self.Root.Size, Position = self.Root.Position }
            self.Body.Visible = false
            self.ResizeGrip.Visible = false
            self.SubLabel.Visible = false
            self.TitleLabel.Size = UDim2.new(1, -44, 0, 20)
            for _, b in ipairs(self._titleButtons) do b.Visible = false end
            local expandIcon = self._expandIcon
            expandIcon.Visible = true
            expandIcon.Size = UDim2.fromOffset(8, 8)
            I.Tween(expandIcon, "Pop", { Size = UDim2.fromOffset(12, 12) })
            self._pillHit.Visible = true
            if self._searchActive then self._setSearch(nil, false) end
            local tw = TextService:GetTextSize(self.Title, I.TS(15), Enum.Font.GothamBold, Vector2.new(10000, 100)).X
            I.Tween(self.Root, "Smooth", { Size = UDim2.fromOffset(tw + 74 + (self.IconImg and 24 or 0), 38) })
        else
            self._pillHit.Visible = false
            self._expandIcon.Visible = false
            for _, b in ipairs(self._titleButtons) do b.Visible = true end
            self.SubLabel.Visible = true
            self.TitleLabel.Size = UDim2.new(1, -self._titleReserve, 0, 20)
            I.Tween(self.Root, "Smooth", { Size = self._preMin and self._preMin.Size or UDim2.fromOffset(580, 420) }, function()
                if not self._destroyed and not self.Minimized then
                    self.Body.Visible = true
                    self.ResizeGrip.Visible = true
                end
            end)
            I.ClampWindowToScreen(self.Root)
        end
    end

    function Window:RemoveTab(tab)
        if self._destroyed then return end
        local idx = table.find(self.Tabs, tab)
        if not idx then return end
        if self.CurrentTab == tab then
            local nxt = self.Tabs[idx + 1] or self.Tabs[idx - 1]
            if nxt then nxt:Select() else self.CurrentTab = nil end
        end
        table.remove(self.Tabs, idx)
        tab.Maid:Destroy()
        tab.Page:Destroy()
        tab.Button:Destroy()
        self:UpdateLayout()
        if not self.CurrentTab then
            self.EmptyLabel.Text = "No tabs"
            self.EmptyLabel.Visible = true
        end
    end

    function Window:ToggleHidden()
        if self._destroyed then return end
        self._hidden = not self._hidden
        if self._hidden then
            I.ModalManager.CloseAll(self)
            self.Root.Visible = false
        else
            self.Root.Visible = true
            self._focus()
        end
    end

    function Window:OnViewport()
        if self._destroyed then return end
        local sc = I.GetScale()
        I.ClampWindowToScreen(self.Root)
        if self.Minimized then return end
        I.ModalManager.CloseAll(self)
        local vw, vh = I.Viewport.X / sc, I.Viewport.Y / sc
        local minW = math.min(self.MinSize.X, math.max(200, vw - 12))
        local minH = math.min(self.MinSize.Y, math.max(160, vh - 12))
        self.Root.Size = UDim2.fromOffset(
            math.clamp(self.Root.Size.X.Offset, minW, math.max(minW, vw - 12)),
            math.clamp(self.Root.Size.Y.Offset, minH, math.max(minH, vh - 12))
        )
        self:UpdateLayout()
    end

    function Window:Close(skipConfirm)
        if self._destroyed then return end
        if not skipConfirm and self._cfg.ConfirmClose then
            Kailex:Confirm({
                Title = "Close " .. self.Title .. "?",
                Text = tostring(self._cfg.ConfirmClose),
            }, function()
                self:Destroy()
            end)
            return
        end
        self:Destroy()
    end

    function Window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if Kailex._lastActive == self then Kailex._lastActive = nil end
        for _, w in ipairs(Kailex.Windows) do
            if w ~= self and not w._destroyed and w.TitleLabel then
                I.Tween(w.TitleLabel, "Fast", { TextTransparency = 0 })
            end
        end
        self:SavePlacement()
        self.Closed:Fire()
        local i = table.find(Kailex.Windows, self)
        if i then table.remove(Kailex.Windows, i) end
        I.ModalManager.CloseAll(self)
        State.killIntro(self)
        if self._shadow then self._shadow.FadeOut() end
        local root = self.Root
        local done = false
        local function finish()
            if done then return end
            done = true
            self.Maid:Destroy()
            if root and root.Parent then root:Destroy() end
        end
        I.Once(root.Destroying, finish)
        task.delay(0.3, finish)
        I.Tween(self._winScale, "Vanish", { Scale = 0.96 })
        I.Tween(root, "Vanish", { Position = root.Position + UDim2.fromOffset(0, -10) })
        I.Tween(root, "Vanish", { GroupTransparency = 1 }, finish)
    end

    I.WindowState = State
end
