return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local N = {
        LOG_CAP = 50,
        TypeColors = { info = "Accent", success = "Success", warning = "Warning", error = "Error" },
        TypeGlyphs = { info = "Info", success = "Check", warning = "Alert", error = "Alert" },
        Log = {},
        MAX_ACTIVE = I.Device.IsTouch and 3 or 5,
        queue = {},
        active = 0,
        pool = {},
    }
    N.POOL_CAP = N.MAX_ACTIVE + 3
    I.NotifyState = N

    function Kailex:GetNotificationLog()
        local out = table.create(#N.Log)
        for i, e in ipairs(N.Log) do out[i] = table.clone(e) end
        return out
    end

    N.container = I.Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 1),
        Position = Setting.RTL and UDim2.new(0, 14, 1, -14) or UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 320, 1, -28),
        Parent = I.LayerNotify,
        Children = {
            I.Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = I.HAlign(),
                Padding = UDim.new(0, 8),
            }),
        },
    })

    function Kailex:Notify(data)
        if type(data) == "string" then data = { Text = data } end
        data = data or {}
        local t = string.lower(tostring(data.Type or "info"))
        if not N.TypeColors[t] then t = "info" end
        local actions
        if type(data.Actions) == "table" then
            actions = {}
            for _, a in ipairs(data.Actions) do
                if type(a) == "table" and a.Text then
                    actions[#actions + 1] = { Text = a.Text, Callback = a.Callback }
                end
            end
        end
        local entry = {
            Title = data.Title or (t == "info" and "Notice" or (t:sub(1, 1):upper() .. t:sub(2))),
            Text = tostring(data.Text or data.Description or ""),
            Duration = data.Duration,
            Type = t,
            Actions = actions,
        }
        table.insert(N.Log, { Title = entry.Title, Text = entry.Text, Type = t, Time = os.time() })
        while #N.Log > N.LOG_CAP do table.remove(N.Log, 1) end
        table.insert(N.queue, entry)
        if #N.queue > 30 then table.remove(N.queue, 1) end
        N.process()
    end

    I.LibMaid:Give(Kailex.ThemeChanged:Connect(function()
        for _, m in ipairs(N.pool) do
            if m.InUse and m.ThemeKey then
                m.Progress.BackgroundColor3 = I.CurrentTheme[m.ThemeKey] or I.CurrentTheme.Accent
            end
        end
    end))
end
