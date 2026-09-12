return function(ctx)
    local I = ctx.Internal
    local N = I.NotifyState

    function N.newCard()
        local card = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = N.container,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 10) }) },
        })
        I.Bind(card, "BackgroundColor3", "Surface")
        local stroke = I.StrokeBind(1, "Stroke", 0.5)
        stroke.Parent = card
        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 8),
            Size = UDim2.new(1, -38, 0, 16),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
            Parent = card,
        })
        I.Bind(title, "TextColor3", "Text")
        local body = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 26),
            Size = UDim2.new(1, -24, 0, 0),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextWrapped = true,
            TextXAlignment = I.XAlign(),
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 2,
            Parent = card,
        })
        I.Bind(body, "TextColor3", "SubText")
        local actions = I.Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 1, -32),
            Size = UDim2.new(1, -24, 0, 26),
            ZIndex = 2,
            Parent = card,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = I.HAlign(),
                    Padding = UDim.new(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })
        local progress = I.Create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 12, 1, -5),
            Size = UDim2.new(1, -24, 0, 2),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = card,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        local hit = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 1,
            Parent = card,
        })
        local cardScale = I.Create("UIScale", { Scale = 1, Parent = card })
        local meta = {
            Card = card, Stroke = stroke, Title = title, Body = body,
            Actions = actions, Progress = progress, Hit = hit,
            InUse = false, CardScale = cardScale,
        }
        table.insert(N.pool, meta)
        return meta
    end

    function N.getFreeCard()
        for _, m in ipairs(N.pool) do
            if not m.InUse and not m.Card.Visible then return m end
        end
        if #N.pool < N.POOL_CAP then return N.newCard() end
        return nil
    end

    function N.dismiss(meta)
        if not meta.InUse then return end
        meta.InUse = false
        N.active = math.max(0, N.active - 1)
        if meta.DelayThread then pcall(task.cancel, meta.DelayThread) meta.DelayThread = nil end
        if meta.ProgressTween then pcall(function() meta.ProgressTween:Cancel() end) meta.ProgressTween = nil end
        if meta.Maid then meta.Maid:Destroy() meta.Maid = nil end
        if meta.Glyph then meta.Glyph:Destroy() meta.Glyph = nil end
        I.Tween(meta.Card, "Fast", { BackgroundTransparency = 1 })
        I.Tween(meta.Stroke, "Fast", { Transparency = 1 })
        I.Tween(meta.Title, "Fast", { TextTransparency = 1 })
        I.Tween(meta.Body, "Fast", { TextTransparency = 1 })
        I.Tween(meta.Progress, "Fast", { BackgroundTransparency = 1 })
        for _, b in ipairs(meta.Actions:GetChildren()) do
            if b:IsA("TextButton") then I.Tween(b, "Fast", { TextTransparency = 1 }) end
        end
        if meta.CardScale then I.Tween(meta.CardScale, "Vanish", { Scale = 0.88 }) end
        I.Tween(meta.Card, "Snappy", { Size = UDim2.new(1, 0, 0, 0) }, function()
            if not meta.InUse then meta.Card.Visible = false end
            N.process()
        end)
        N.process()
    end
end
