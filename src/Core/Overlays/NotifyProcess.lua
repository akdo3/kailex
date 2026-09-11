return function(ctx)
    local I = ctx.Internal
    local TextService = I.TextService
    local N = I.NotifyState

    function N.process()
        while N.active < N.MAX_ACTIVE and #N.queue > 0 do
            local item = table.remove(N.queue, 1)
            local meta = N.getFreeCard()
            if not meta then
                table.insert(N.queue, 1, item)
                break
            end
            N.active += 1
            meta.InUse = true
            local themeKey = N.TypeColors[item.Type] or "Accent"
            meta.ThemeKey = themeKey
            meta.Card.Visible = true
            meta.Progress.BackgroundColor3 = I.CurrentTheme[themeKey]
            meta.Title.Text = item.Title
            meta.Body.Text = item.Text

            local textH = 0
            if item.Text ~= "" then
                local b = TextService:GetTextSize(item.Text, I.TS(12), Enum.Font.Gotham, Vector2.new(296, 400))
                textH = math.min(b.Y, 120)
                meta.Body.Size = UDim2.new(1, -24, 0, textH)
                meta.Body.Visible = true
            else
                meta.Body.Visible = false
            end

            local glyphKind = N.TypeGlyphs[item.Type]
            if glyphKind then
                meta.Glyph = I.Icon(meta.Card, glyphKind, themeKey)
                meta.Glyph.Position = UDim2.fromOffset(11, 9)
                meta.Glyph.Size = UDim2.fromOffset(14, 14)
                meta.Glyph.ZIndex = 2
                local glyphScale = I.Create("UIScale", { Scale = 0, Parent = meta.Glyph })
                I.Tween(glyphScale, "Pop", { Scale = 1 })
            end

            for _, b in ipairs(meta.Actions:GetChildren()) do
                if b:IsA("TextButton") then b:Destroy() end
            end
            local actCount = 0
            if type(item.Actions) == "table" then
                local cardMaid = I.Maid.new()
                meta.Maid = cardMaid
                for i = 1, math.min(#item.Actions, 3) do
                    local a = item.Actions[i]
                    local b = I.MkButton(meta.Actions, {
                        Size = UDim2.fromOffset(64, 24),
                        Text = tostring(a.Text or "OK"),
                        Font = Enum.Font.GothamBold,
                        TextSize = 11,
                        LayoutOrder = i,
                        ZIndex = 3,
                    }, { Corner = 6 })
                    actCount += 1
                    cardMaid:Give(b.MouseButton1Click:Connect(function()
                        if not meta.InUse then return end
                        N.dismiss(meta)
                        if type(a.Callback) == "function" then
                            I.SafeCall(a.Callback)
                        end
                    end))
                end
            end

            local cardH = 38 + textH + (actCount > 0 and 30 or 0)
            meta.Card.BackgroundTransparency = 1
            meta.Stroke.Transparency = 1
            meta.Title.TextTransparency = 1
            meta.Body.TextTransparency = 1
            meta.Progress.BackgroundTransparency = 1
            meta.Progress.Size = UDim2.new(1, -24, 0, 2)
            meta.Card.Size = UDim2.new(1, 0, 0, 0)
            if not meta.Maid then meta.Maid = I.Maid.new() end
            if meta.CardScale then meta.CardScale.Scale = 0.9 end

            I.Tween(meta.Card, "Snappy", { Size = UDim2.new(1, 0, 0, cardH) })
            I.Tween(meta.Card, "Snappy", { BackgroundTransparency = 0.04 })
            I.Tween(meta.Stroke, "Snappy", { Transparency = 0.5 })
            I.Tween(meta.Title, "Snappy", { TextTransparency = 0 })
            if textH > 0 then I.Tween(meta.Body, "Snappy", { TextTransparency = 0 }) end
            I.Tween(meta.Progress, "Snappy", { BackgroundTransparency = 0 })
            if meta.CardScale then I.Tween(meta.CardScale, "PopSoft", { Scale = 1 }) end

            local duration = math.max(0.5, tonumber(item.Duration) or 4)
            local remaining = duration
            local startedAt = os.clock()
            meta.DelayThread = task.delay(duration, function()
                meta.DelayThread = nil
                N.dismiss(meta)
            end)
            meta.ProgressTween = I.Tween(meta.Progress,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { Size = UDim2.new(0, 0, 0, 2) })

            meta.Maid:Give(meta.Hit.MouseEnter:Connect(function()
                if not meta.InUse then return end
                if meta.ProgressTween then pcall(function() meta.ProgressTween:Pause() end) end
                if meta.DelayThread then
                    pcall(task.cancel, meta.DelayThread)
                    remaining = math.max(0.05, remaining - (os.clock() - startedAt))
                    meta.DelayThread = nil
                end
            end))
            meta.Maid:Give(meta.Hit.MouseLeave:Connect(function()
                if not meta.InUse then return end
                startedAt = os.clock()
                if meta.ProgressTween then
                    pcall(function() meta.ProgressTween:Cancel() end)
                    meta.ProgressTween = I.Tween(meta.Progress,
                        TweenInfo.new(math.max(0.05, remaining), Enum.EasingStyle.Linear),
                        { Size = UDim2.new(0, 0, 0, 2) })
                end
                meta.DelayThread = task.delay(remaining, function()
                    meta.DelayThread = nil
                    N.dismiss(meta)
                end)
            end))
            meta.Maid:Give(meta.Hit.MouseButton1Click:Connect(function() N.dismiss(meta) end))
        end
    end
end
