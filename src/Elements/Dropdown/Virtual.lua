return function(ctx)
    local View = ctx.Internal.DropdownView

    function View.releaseRec(S, rec)
        rec._idx = nil
        rec.Button.Visible = false
        table.insert(S.virtualPool, rec)
    end

    function View.acquireRec(S)
        local rec = table.remove(S.virtualPool)
        if rec then
            rec.Button.Visible = true
            return rec
        end
        return View.newRec(S)
    end

    function View.updateVirtualWindow(S)
        if not S.virtual or not S.expanded then return end
        local viewH = S.listCanvas.AbsoluteSize.Y
        local top = S.listCanvas.CanvasPosition.Y
        local rowStep = S.optH + S.pad
        local first = math.max(1, math.floor(top / rowStep) - 2)
        local count = math.ceil(viewH / rowStep) + 5
        local last = math.min(#S.display, first + count)
        for idx, rec in pairs(S.virtualButtons) do
            if idx < first or idx > last then
                S.virtualButtons[idx] = nil
                View.releaseRec(S, rec)
            end
        end
        for idx = first, last do
            if not S.virtualButtons[idx] then
                local rec = View.acquireRec(S)
                S.virtualButtons[idx] = rec
                rec._idx = idx
                rec.Button.Position = UDim2.fromOffset(0, (idx - 1) * rowStep)
                View.paintRec(S, rec, S.display[idx])
            end
        end
    end

    function View.clearButtons(S)
        for _, rec in ipairs(S.optionButtons) do
            if rec.Button then rec.Button:Destroy() end
        end
        table.clear(S.optionButtons)
        for _, rec in pairs(S.virtualButtons) do
            rec.Button:Destroy()
        end
        table.clear(S.virtualButtons)
        for _, rec in ipairs(S.virtualPool) do
            rec.Button:Destroy()
        end
        table.clear(S.virtualPool)
    end
end
