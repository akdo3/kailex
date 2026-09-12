return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local TabClass = I.TabClass

    function TabClass:_deferFilter()
        local win = self.Window
        task.defer(function()
            if win and not win._destroyed and win.CurrentTab == self and not self._destroyed then
                win:ApplyFilter(win._filterQuery)
            end
        end)
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

        el.Maid:Give(function() self:_deferFilter() end)
        if self.Window.EmptyLabel and self.Window.EmptyLabel.Visible then
            self:_deferFilter()
        end
        return el
    end

    function TabClass:Section(opts)
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
        if self.Window.EmptyLabel and self.Window.EmptyLabel.Visible then
            self:_deferFilter()
        end
        section.Maid:Give(function()
            I.RemoveFrom(self.Sections, section)
            if self.CurrentSection == section then self.CurrentSection = nil end
            for _, el in ipairs(section.Elements) do
                if not el._destroyed then el.Section = nil end
            end
            if self._gridFrames then self:_syncGridFrames() end
            self:_deferFilter()
        end)
        return section
    end
end
