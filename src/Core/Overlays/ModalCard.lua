return function(ctx)
    local I = ctx.Internal

    local ModalCard = {}

    function ModalCard.OpenCenter(cfg)
        cfg = cfg or {}
        local h = {}
        local closed = false
        local z = cfg.ZIndex or 200

        h.Dimmer = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = z,
            Parent = I.LayerOverlay,
        })
        h.Card = I.Create("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = cfg.Size or UDim2.fromOffset(360, 246),
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            ZIndex = z + 1,
            Parent = I.LayerOverlay,
            Children = { I.Corner(12), I.StrokeBind(1, "Stroke", 0.4) },
        })
        I.Bind(h.Card, "BackgroundColor3", "Surface")
        h.Scale = I.Create("UIScale", { Scale = 0.88, Parent = h.Card })
        h.Shadow = I.DropShadow(h.Card, { Radius = 12 })

        h.Maid = I.Maid.new()
        h.Maid:Give(h.Dimmer)
        h.Maid:Give(h.Card)
        h.Maid:Link(h.Card)

        local function close()
            if closed then return end
            closed = true
            I.ModalManager.Remove(h.Entry)
            h.Entry = nil
            if h.Shadow then h.Shadow.FadeOut() end
            I.Tween(h.Dimmer, "Fast", { BackgroundTransparency = 1 })
            I.Tween(h.Scale, "Vanish", { Scale = 0.92 })
            I.Tween(h.Card, "Fast", { GroupTransparency = 1 })
            task.delay(0.2, function()
                h.Maid:Destroy()
            end)
        end

        h.Close = close
        h.IsClosed = function() return closed end

        if cfg.OnDimmerClick then
            h.Maid:Give(h.Dimmer.MouseButton1Click:Connect(cfg.OnDimmerClick))
        end

        h.Entry = I.ModalManager.Push(cfg.Owner, cfg.Closer or close)

        I.Tween(h.Dimmer, "Normal", { BackgroundTransparency = 0.5 })
        I.Tween(h.Card, "Snappy", { GroupTransparency = 0 })
        I.Tween(h.Scale, "Pop", { Scale = 1 })
        I.ShadowIn(h.Shadow, function() return not closed end)
        return h
    end

    function ModalCard.MakeAnchor(cfg)
        cfg = cfg or {}
        local h = {}
        local open = false
        local z = cfg.ZIndex or 100

        h.Card = I.Create("CanvasGroup", {
            Size = cfg.Size or UDim2.fromOffset(240, 250),
            BackgroundColor3 = I.CurrentTheme[cfg.BgKey or "Surface"],
            BackgroundTransparency = cfg.BgTransparency or 0,
            BorderSizePixel = 0,
            Visible = false,
            GroupTransparency = 1,
            ZIndex = z,
            Parent = I.LayerOverlay,
            Children = {
                I.Corner(cfg.Corner or 12),
                I.StrokeBind(1, cfg.StrokeKey or "Stroke", cfg.StrokeT or 0.4),
            },
        })
        I.Bind(h.Card, "BackgroundColor3", cfg.BgKey or "Surface")
        h.Shadow = I.DropShadow(h.Card, { Radius = cfg.ShadowR or 12 })
        if cfg.HasScale then
            h.Scale = I.Create("UIScale", { Scale = 1, Parent = h.Card })
        end

        h.Catcher = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Visible = false,
            ZIndex = z - 1,
            Parent = I.LayerOverlay,
        })

        h.Maid = I.Maid.new()
        h.Maid:Give(h.Catcher)
        h.Maid:Give(h.Card)
        h.Maid:Link(h.Card)
        h.Maid:Give(function()
            I.ModalManager.Remove(h.Entry)
        end)
        if cfg.OnCatcherClick then
            h.Maid:Give(h.Catcher.MouseButton1Click:Connect(cfg.OnCatcherClick))
        end

        function h.Show()
            I.ModalManager.Remove(h.Entry)
            open = true
            h.Catcher.Visible = true
            h.Card.Visible = true
            h.Card.GroupTransparency = 1
            if h.Scale then h.Scale.Scale = 0.94 end
            I.Tween(h.Card, "Snappy", { GroupTransparency = 0 })
            if h.Scale then I.Tween(h.Scale, "Pop", { Scale = 1 }) end
            I.ShadowIn(h.Shadow, function() return open end)
            h.Entry = I.ModalManager.Push(cfg.Owner, cfg.Closer or h.Hide)
        end

        function h.Hide()
            open = false
            I.ModalManager.Remove(h.Entry)
            h.Entry = nil
            h.Catcher.Visible = false
            if h.Shadow then h.Shadow.FadeOut() end
            if h.Scale then I.Tween(h.Scale, "Vanish", { Scale = 0.95 }) end
            I.Tween(h.Card, "Fast", { GroupTransparency = 1 }, function()
                if not open then h.Card.Visible = false end
            end)
        end

        h.IsOpen = function() return open end

        return h
    end

    I.ModalCard = ModalCard
end
