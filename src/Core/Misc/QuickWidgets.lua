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
        local widget = I.Create("Frame", {
            Size = UDim2.fromOffset(0, 0),
            Position = UDim2.fromOffset((I.Viewport.X - 70) / s, (I.Viewport.Y * 0.35 + count * 56) / s),
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            ZIndex = 20,
            Parent = I.LayerWindows,
            Children = { I.Corner(12), I.StrokeBind(1, "Stroke", 0.4) },
        })
        I.Bind(widget, "BackgroundColor3", "Surface")
        local wMaid = I.Maid.new()
        wMaid:Link(widget)
        QuickWidgets.Active[element] = { Frame = widget, Maid = wMaid }

        local state = element:Get() == true
        local hit = I.Create("TextButton", {
            BackgroundTransparency = 1, Text = "",
            Size = UDim2.fromScale(1, 1),
            Parent = widget,
        })
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
        refresh()
        I.MakeDraggable(hit, widget, { Clamp = true })
        wMaid:Give(hit.MouseButton1Click:Connect(function()
            if hit:GetAttribute("Dragging") then return end
            I.ApplyRipple(hit)
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
        I.Tween(widget, "SpringBig", { Size = UDim2.fromOffset(46, 46) })
    end

    table.insert(I.ViewportHooks, function()
        for _, w in pairs(QuickWidgets.Active) do I.ClampFloat(w.Frame) end
        if Kailex._mobileButton then I.ClampFloat(Kailex._mobileButton) end
    end)
end
