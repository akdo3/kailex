return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    local QuickWidgets = { Active = {} }
    I.QuickWidgets = QuickWidgets

    function QuickWidgets.Destroy(el)
        local w = QuickWidgets.Active[el]
        if not w then return end
        QuickWidgets.Active[el] = nil
        I.Tween(w.Frame, "Collapse", { Size = UDim2.fromOffset(0, 0) }, function()
            w.Maid:Destroy()
            w.Frame:Destroy()
        end)
    end

    function QuickWidgets.Toggle(element)
        if QuickWidgets.Active[element] then
            QuickWidgets.Destroy(element)
            return
        end
        local count = 0
        for _ in pairs(QuickWidgets.Active) do count += 1 end
        local name = element.Title
        local s = I.GetScale()
        local widget, _, wMaid = I.FloatingChip({
            Anchor = Vector2.new(0, 0),
            ZIndex = 20,
            Parent = I.LayerWindows,
            Position = UDim2.fromOffset((I.Viewport.X - 70) / s, (I.Viewport.Y * 0.35 + count * 56) / s),
        })
        local entry = { Frame = widget, Maid = wMaid }
        QuickWidgets.Active[element] = entry

        local state = element:Get() == true
        local letter = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.42),
            Size = UDim2.fromOffset(20, 20),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = I.CurrentTheme.Text,
            Text = name:sub(1, 1):upper(),
            Parent = widget,
        })
        I.Bind(letter, "TextColor3", "Text")
        local dot = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -8),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = state and I.CurrentTheme.Accent or I.CurrentTheme.Stroke,
            BorderSizePixel = 0,
            Parent = widget,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        local closeB = I.Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -2, 0, 2),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Text = "x",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            Parent = widget,
        })
        I.Bind(closeB, "TextColor3", "SubText")

        local function refresh()
            dot.BackgroundColor3 = state and I.CurrentTheme.Accent or I.CurrentTheme.Stroke
        end
        entry.Refresh = refresh
        refresh()

        wMaid:Give(widget.MouseButton1Click:Connect(function()
            if widget:GetAttribute("Dragging") then return end
            I.ApplyRipple(widget)
            state = not state
            element:Set(state)
            refresh()
        end))

        wMaid:Give(closeB.MouseButton1Click:Connect(function() QuickWidgets.Destroy(element) end))

        wMaid:Give(element.Changed:Connect(function(v)
            state = v == true
            refresh()
        end))

        local letterScale = I.Create("UIScale", { Parent = letter })
        letterScale.Scale = 0.2
        I.Tween(letterScale, "Pop", { Scale = 1 })
    end

    local function onViewport()
        for _, w in pairs(QuickWidgets.Active) do
            if w.Frame and w.Frame.Parent then I.ClampFloat(w.Frame) end
        end
        local mb = Kailex._mobileButton
        if mb and mb.Parent then I.ClampFloat(mb) end
    end
    table.insert(I.ViewportHooks, onViewport)
    I.LibMaid:Give(function()
        local idx = table.find(I.ViewportHooks, onViewport)
        if idx then table.remove(I.ViewportHooks, idx) end
    end)

    I.LibMaid:Give(Kailex.ThemeChanged:Connect(function()
        for _, w in pairs(QuickWidgets.Active) do
            if w.Refresh then w.Refresh() end
        end
    end))
end
