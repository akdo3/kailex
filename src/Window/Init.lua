return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Window = I.WindowClass

    function Window:Tab(tabOpts)
        local tab = I.TabClass.new(self, tabOpts)
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then
            tab:Select()
        end
        self:UpdateLayout()
        return tab
    end

    function Window:ApplyFilter(q)
        self._filterQuery = q or ""
        local tab = self.CurrentTab
        if not tab then return end
        local n = tab:ApplyFilter(self._filterQuery)
        for _, t in ipairs(self.Tabs) do
            if t ~= tab and not t._destroyed then
                local c = t:CountMatches(self._filterQuery)
                t:SetFilterBadge(c > 0 and tostring(c) or "")
            else
                t:SetFilterBadge("")
            end
        end
        local shouldShow, txt = false, ""
        if self._filterQuery ~= "" then
            txt = "No results for \"" .. self._filterQuery .. "\""
            shouldShow = (n == 0)
        elseif #tab.Elements == 0 and #tab.Sections == 0 then
            txt = "This tab is empty"
            shouldShow = true
        end
        local el = self.EmptyLabel
        if shouldShow then
            el.Text = txt
            if not el.Visible then
                el.Visible = true
                el.TextTransparency = 1
                I.Tween(el, "Fast", { TextTransparency = 0 })
            end
        else
            el.Visible = false
        end
    end

    function Window:_closeDropdowns()
        for _, tab in ipairs(self.Tabs) do
            if tab._openDropdown then
                local fn = tab._openDropdown
                tab._openDropdown = nil
                fn()
            end
        end
    end

    local uiVisible = true

    function Kailex:SetVisible(state)
        state = state == true
        uiVisible = state
        for _, layer in ipairs(I.ToggleLayers) do layer.Visible = state end
        if not state then
            I.Tooltip.Hide()
            I.ContextMenu.Hide()
            I.ModalManager.CloseAll()
        end
    end

    function Kailex:IsVisible()
        return uiVisible
    end
end
