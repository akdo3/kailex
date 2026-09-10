return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local NotificationLog = {}
    Kailex.GetNotificationLog = function()
        local out = table.create(#NotificationLog)
        for i, e in ipairs(NotificationLog) do out[i] = table.clone(e) end
        return out
    end

    local MAX_ACTIVE = I.Device.IsTouch and 3 or 5
    local POOL_CAP = MAX_ACTIVE + 3
    local TypeColors = { info = "Accent", success = "Success", warning = "Warning", error = "Error" }
    local queue = {}
    local active = 0
    local pool = {}

    local container = I.Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 1),
        Position = Setting.RTL and UDim2.new(0, 14, 1, -14) or UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 320, 1, -28),
        Parent = I.LayerNotify,
        Children = {
            I.Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Setting.RTL and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8),
            }),
        },
    })

    local process

    local function newCard()
        local card = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = container,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 10) }) },
        })
        I.Bind(card, "BackgroundColor3", "Surface")
        local stroke = I.StrokeBind(1, "Stroke", 0.5)
        stroke.Parent = card
        local dot = I.Create("Frame", {
            Size = UDim2.fromOffset(7, 7),
            Position = UDim2.fromOffset(12, 11),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = card,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 8),
            Size = UDim2.new(1, -38, 0, 16),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
                    HorizontalAlignment = Setting.RTL and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
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
            ZIndex = 3,
            Parent = card,
        })
        local cardScale = I.Create("UIScale", { Scale = 1, Parent = card })
        local dotScale = I.Create("UIScale", { Scale = 1, Parent = dot })
        local meta = {
            Card = card, Stroke = stroke, Dot = dot, Title = title,
            Body = body, Actions = actions, Progress = progress, Hit = hit, InUse = false,
            CardScale = cardScale, DotScale = dotScale,
        }
        table.insert(pool, meta)
        return meta
    end

    local function getFreeCard()
        for _, m in ipairs(pool) do
            if not m.InUse and not m.Card.Visible then return m end
        end
        if #pool < POOL_CAP then return newCard() end
        return nil
    end

    local function dismiss(meta)
        if not meta.InUse then return end
        meta.InUse = false
        active = math.max(0, active - 1)
        if meta.DelayThread then pcall(task.cancel, meta.DelayThread) meta.DelayThread = nil end
        if meta.ProgressTween then pcall(function() meta.ProgressTween:Cancel() end) meta.ProgressTween = nil end
        if meta.Maid then meta.Maid:Destroy() meta.Maid = nil end
        I.Tween(meta.Card, "Fast", { BackgroundTransparency = 1 })
        I.Tween(meta.Stroke, "Fast", { Transparency = 1 })
        I.Tween(meta.Title, "Fast", { TextTransparency = 1 })
        I.Tween(meta.Body, "Fast", { TextTransparency = 1 })
        I.Tween(meta.Progress, "Fast", { BackgroundTransparency = 1 })
        for _, b in ipairs(meta.Actions:GetChildren()) do
            if b:IsA("TextButton") then b:Destroy() end
        end
        if meta.CardScale then I.Tween(meta.CardScale, "Vanish", { Scale = 0.88 }) end
        I.Tween(meta.Card, "Snappy", { Size = UDim2.new(1, 0, 0, 0) }, function()
            if not meta.InUse then meta.Card.Visible = false end
            process()
        end)
        process()
    end

    process = function()
        while active < MAX_ACTIVE and #queue > 0 do
            local item = table.remove(queue, 1)
            local meta = getFreeCard()
            if not meta then
                table.insert(queue, 1, item)
                break
            end
            active += 1
            meta.InUse = true
            local themeKey = TypeColors[item.Type] or "Accent"
            meta.ThemeKey = themeKey
            meta.Card.Visible = true
            meta.Dot.BackgroundColor3 = I.CurrentTheme[themeKey]
            meta.Progress.BackgroundColor3 = I.CurrentTheme[themeKey]
            meta.Title.Text = item.Title
            meta.Body.Text = item.Text

            local textH = 0
            if item.Text ~= "" then
                local b = I.TextService:GetTextSize(item.Text, I.TS(12), Enum.Font.Gotham, Vector2.new(296, 400))
                textH = math.min(b.Y, 120)
                meta.Body.Size = UDim2.new(1, -24, 0, textH)
                meta.Body.Visible = true
            else
                meta.Body.Visible = false
            end

            local actCount = 0
            for _, b in ipairs(meta.Actions:GetChildren()) do
                if b:IsA("TextButton") then b:Destroy() end
            end
            if type(item.Actions) == "table" then
                local cardMaid = I.Maid.new()
                meta.Maid = cardMaid
                for i = 1, math.min(#item.Actions, 3) do
                    local a = item.Actions[i]
                    local b = I.Create("TextButton", {
                        Size = UDim2.fromOffset(64, 24),
                        BackgroundColor3 = I.CurrentTheme.Element,
                        BorderSizePixel = 0,
                        Text = tostring(a.Text or "OK"),
                        Font = Enum.Font.GothamBold,
                        TextSize = 11,
                        TextColor3 = I.CurrentTheme.Text,
                        AutoButtonColor = false,
                        LayoutOrder = i,
                        ZIndex = 3,
                        Parent = meta.Actions,
                        Children = { I.Corner(6) },
                    })
                    I.Bind(b, "BackgroundColor3", "Element")
                    I.Bind(b, "TextColor3", "Text")
                    I.AddHover(b)
                    actCount += 1
                    cardMaid:Give(b.MouseButton1Click:Connect(function()
                        if not meta.InUse then return end
                        dismiss(meta)
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
            if meta.CardScale then meta.CardScale.Scale = 0.9 end
            if meta.DotScale then meta.DotScale.Scale = 0 end
            if not meta.Maid then meta.Maid = I.Maid.new() end

            I.Tween(meta.Card, "Snappy", { Size = UDim2.new(1, 0, 0, cardH) })
            I.Tween(meta.Card, "Snappy", { BackgroundTransparency = 0.04 })
            I.Tween(meta.Stroke, "Snappy", { Transparency = 0.5 })
            I.Tween(meta.Title, "Snappy", { TextTransparency = 0 })
            if textH > 0 then I.Tween(meta.Body, "Snappy", { TextTransparency = 0 }) end
            I.Tween(meta.Progress, "Snappy", { BackgroundTransparency = 0 })
            if meta.CardScale then I.Tween(meta.CardScale, "PopSoft", { Scale = 1 }) end
            if meta.DotScale then I.Tween(meta.DotScale, "Pop", { Scale = 1 }) end

            local duration = math.max(0.5, tonumber(item.Duration) or 4)
            local remaining = duration
            local startedAt = os.clock()
            meta.DelayThread = task.delay(duration, function()
                meta.DelayThread = nil
                dismiss(meta)
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
                    dismiss(meta)
                end)
            end))
            meta.Maid:Give(meta.Hit.MouseButton1Click:Connect(function() dismiss(meta) end))
        end
    end

    function Kailex:Notify(data)
        if type(data) == "string" then data = { Text = data } end
        data = data or {}
        local t = string.lower(tostring(data.Type or "info"))
        if not TypeColors[t] then t = "info" end
        local actions
        if type(data.Actions) == "table" then
            actions = {}
            for i, a in ipairs(data.Actions) do
                if type(a) == "table" and a.Text then
                    actions[#actions + 1] = { Text = a.Text, Callback = a.Callback }
                end
            end
        end
        local entry = {
            Title = data.Title or (t == "info" and "Notice" or (t:sub(1,1):upper() .. t:sub(2))),
            Text = tostring(data.Text or data.Description or ""),
            Duration = data.Duration,
            Type = t,
            Actions = actions,
        }
        table.insert(NotificationLog, { Title = entry.Title, Text = entry.Text, Type = t, Time = os.time() })
        while #NotificationLog > 50 do table.remove(NotificationLog, 1) end
        table.insert(queue, entry)
        process()
    end
end
