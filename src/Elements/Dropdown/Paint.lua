return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting
    local View = I.DropdownView

    function View.paintRec(S, rec, opt)
        local isSel = opt ~= nil and S.selSet[opt.Key] == true
        local btn = rec.Button
        btn.Text = opt and opt.Text or ""
        btn.BackgroundColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Element
        btn.BackgroundTransparency = isSel and 0.75 or 1
        btn.TextColor3 = isSel and I.CurrentTheme.Accent or I.CurrentTheme.Text
        if S.multi and rec.Box then
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

    function View.recAt(S, idx)
        if S.virtual then return S.virtualButtons[idx] end
        return S.optionButtons[idx]
    end

    function View.paintHl(S, rec, on)
        if not rec or not rec.Button then return end
        local opt = S.display[rec._idx]
        local isSel = opt ~= nil and S.selSet[opt.Key] == true
        I.Tween(rec.Button, "Instant", {
            BackgroundColor3 = on
                and (isSel and I.CurrentTheme.AccentHover or I.CurrentTheme.ElementHover)
                or (isSel and I.CurrentTheme.Accent or I.CurrentTheme.Element),
            BackgroundTransparency = on
                and (isSel and 0.6 or 0.35)
                or (isSel and 0.75 or 1),
        })
    end

    function View.clearHl(S)
        if S.hl == nil then return end
        local rec = View.recAt(S, S.hl)
        if rec then View.paintHl(S, rec, false) end
        S.hl = nil
    end

    function View.setHl(S, idx)
        if idx == S.hl then return end
        View.clearHl(S)
        if idx == nil or idx < 1 or idx > #S.display then return end
        S.hl = idx
        local rowStep = S.optH + S.pad
        local target = (idx - 1) * rowStep
        local viewH = S.listCanvas.AbsoluteSize.Y
        local top = S.listCanvas.CanvasPosition.Y
        if target < top or target + S.optH > top + viewH then
            S.listCanvas.CanvasPosition = Vector2.new(0, math.max(0, target - math.max(0, (viewH - S.optH) / 2)))
        end
        local rec = View.recAt(S, idx)
        if rec then View.paintHl(S, rec, true) end
    end

    function View.moveHl(S, dir)
        local n = #S.display
        if n == 0 then return end
        local idx = S.hl or 0
        if dir > 0 then
            idx += 1
            if idx > n then idx = 1 end
        else
            idx -= 1
            if idx < 1 then idx = n end
        end
        View.setHl(S, idx)
    end

    function View.refreshOptions(S)
        if S.virtual then
            for idx, rec in pairs(S.virtualButtons) do
                View.paintRec(S, rec, S.display[idx])
            end
        else
            for i, opt in ipairs(S.display) do
                local rec = S.optionButtons[i]
                if rec then
                    View.paintRec(S, rec, opt)
                    if rec.Check and rec.Check.Visible then
                        I.Tween(rec.Check, "Spring", { Rotation = 0 })
                    end
                end
            end
        end
        if S.hl ~= nil then
            local rec = View.recAt(S, S.hl)
            if rec then View.paintHl(S, rec, true) end
        end
    end

    function View.refreshLabel(S)
        local sel = View.selectedOpts(S)
        local text
        if S.multi then
            if #sel == 0 then text = "-"
            elseif #sel == 1 then text = sel[1].Text
            else text = #sel .. " selected" end
        else
            text = (#sel > 0) and sel[1].Text or "-"
        end
        S.valueLabel.Text = text
        S.valueLabel.TextColor3 = (next(S.selSet) ~= nil) and I.CurrentTheme.Text or I.CurrentTheme.SubText
    end

    function View.newRec(S)
        local btn = I.Create("TextButton", {
            Size = UDim2.new(1, 0, 0, S.optH),
            BackgroundTransparency = 1,
            BackgroundColor3 = I.CurrentTheme.Element,
            BorderSizePixel = 0,
            Text = "",
            TextXAlignment = I.XAlign(),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            Parent = S.listCanvas,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 6) }) },
        })
        I.Create("UIPadding", {
            [Setting.RTL and "PaddingRight" or "PaddingLeft"] = UDim.new(0, 24),
            Parent = btn,
        })
        local rec = { Button = btn, _idx = nil }

        if S.multi then
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
                Thickness = 1,
                Transparency = 0.4,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = I.CurrentTheme.Stroke,
                Parent = box,
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
            if I.Device.IsTouch or not S.expanded or not rec._idx then return end
            if S.hl ~= nil and S.hl ~= rec._idx then
                local prev = View.recAt(S, S.hl)
                if prev and prev ~= rec then View.paintHl(S, prev, false) end
            end
            S.hl = rec._idx
            I.PlaySound("Hover", 0.1)
            View.paintHl(S, rec, true)
        end)
        btn.MouseLeave:Connect(function()
            if not rec._idx then return end
            if S.hl == rec._idx then return end
            View.paintHl(S, rec, false)
        end)
        btn.MouseButton1Click:Connect(function()
            local idx = rec._idx
            if not idx then return end
            S.selectOption(S.display[idx], btn)
        end)
        return rec
    end
end
