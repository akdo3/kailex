return function(ctx)
    local I = ctx.Internal
    local TabClass = I.TabClass

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
                    if not el._destroyed and q ~= ""
                        and el.SearchText and el.SearchText:find(q, 1, true) then
                        childMatch += 1
                    end
                end
                local shouldExpand = (q ~= "") and (secMatch or childMatch > 0)
                if shouldExpand ~= (sec._filterExpanded == true) then
                    sec._filterExpanded = shouldExpand or nil
                    if sec.Chevron then
                        I.Tween(sec.Chevron, "PopSoft", {
                            Rotation = (shouldExpand or not sec.Collapsed) and 0 or -90,
                        })
                    end
                end
                local open = (not sec.Collapsed) or shouldExpand
                for _, el in ipairs(sec.Elements) do
                    if not el._destroyed then
                        local vis
                        if q == "" then
                            vis = (el._manualVisible ~= false) and not sec.Collapsed
                        else
                            vis = (secMatch or (el.SearchText and el.SearchText:find(q, 1, true) ~= nil)) and open
                        end
                        el.Row.Visible = vis
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
end
