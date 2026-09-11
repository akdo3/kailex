return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Window = I.WindowClass
    local Chrome = I.WindowChrome
    local Search = I.WindowSearch
    local Layout = I.WindowLayout
    local State = I.WindowState

    function Window:Tab(tabOpts)
        local tab = I.TabClass.new(self, tabOpts)
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then
            tab:Select()
        end
        self:UpdateLayout()
        return tab
    end

    function Window:ApplyFilter(q)
        self._filterQuery = q or ""
        local tab = self.CurrentTab
        if not tab then return end
        local n = tab:ApplyFilter(self._filterQuery)
        for _, t in ipairs(self.Tabs) do
            if t ~= tab and not t._destroyed then
                local c = t:CountMatches(self._filterQuery)
                t:SetFilterBadge(c > 0 and tostring(c) or "")
            else
                t:SetFilterBadge("")
            end
        end
        local shouldShow, txt = false, ""
        if self._filterQuery ~= "" then
            txt = "No results for \"" .. self._filterQuery .. "\""
            shouldShow = (n == 0)
        elseif #tab.Elements == 0 and #tab.Sections == 0 then
            txt = "This tab is empty"
            shouldShow = true
        end
        local el = self.EmptyLabel
        if shouldShow then
            el.Text = txt
            if not el.Visible then
                el.Visible = true
                el.TextTransparency = 1
                I.Tween(el, "Fast", { TextTransparency = 0 })
            end
        else
            el.Visible = false
        end
    end

    function Window:_closeDropdowns()
        for _, tab in ipairs(self.Tabs) do
            if tab._openDropdown then
                local fn = tab._openDropdown
                tab._openDropdown = nil
                fn()
            end
        end
    end

    function Kailex:CreateWindow(cfg)
        cfg = cfg or {}
        local self = setmetatable({}, Window)
        self._cfg = cfg
        self.Title = tostring(cfg.Title or cfg.Name or "Kailex")
        self.SubTitle = cfg.SubTitle
        self.SavePrefix = tostring(self.Title)
        self.MinSize = cfg.MinSize or Vector2.new(380, 280)
        self._destroyed = false
        self._filterQuery = ""
        self.Tabs = {}
        self.CurrentTab = nil
        self.Minimized = false
        self.MinimizedChanged = I.Signal.new()
        self.Closed = I.Signal.new()
        self._hidden = false
        self._alwaysTop = false
        self.ToggleKey = I.ParseKey(cfg.ToggleKey)
        self._remember = cfg.RememberPosition ~= false

        local defW, defH = 580, 420
        local s = I.GetScale()
        local vw, vh = I.Viewport.X / s, I.Viewport.Y / s
        if I.Device.IsTouch then
            defW = math.min(defW, vw - 16)
            defH = math.min(defH, vh - 16)
        end
        defW = math.clamp(defW, math.min(self.MinSize.X, vw - 12), vw - 12)
        defH = math.clamp(defH, math.min(self.MinSize.Y, vh - 12), vh - 12)

        local px, py
        if self._remember then
            local sp = I.SaveManager:Get("__win:" .. self.SavePrefix, nil)
            if type(sp) == "table" then
                local sx, sy, sw, sh = tonumber(sp.X), tonumber(sp.Y), tonumber(sp.W), tonumber(sp.H)
                if sx and sy and sw and sh then
                    defW = math.clamp(sw, math.min(self.MinSize.X, vw - 12), vw - 12)
                    defH = math.clamp(sh, math.min(self.MinSize.Y, vh - 12), vh - 12)
                    px = math.clamp(sx, 8, math.max(8, vw - defW - 8))
                    py = math.clamp(sy, 8, math.max(8, vh - defH - 8))
                end
            end
        end
        if not px then
            if #Kailex.Windows == 0 then
                px = math.max(8, math.floor((vw - defW) / 2 + 0.5))
                py = math.max(8, math.floor((vh - defH) / 2 + 0.5))
            else
                local n = #Kailex.Windows % 5
                px, py = 40 + n * 28, 34 + n * 24
            end
        end

        self._rootFinal = UDim2.fromOffset(px, py)
        self._titleFinal = UDim2.new(0, 0, 0, 0)
        self._bodyFinal = UDim2.new(0, 0, 0, 56)

        self.Root = I.Create("CanvasGroup", {
            Position = self._rootFinal,
            Size = UDim2.fromOffset(defW, defH),
            BackgroundColor3 = I.CurrentTheme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            GroupTransparency = 1,
            Parent = I.LayerWindows,
        })
        I.Bind(self.Root, "BackgroundColor3", "Background")
        I.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = self.Root })
        I.Bind(I.Create("UIStroke", {
            Thickness = 1,
            Transparency = 0.35,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = self.Root,
        }), "Color", "Stroke")
        self._winScale = I.Create("UIScale", { Scale = 0.94, Parent = self.Root })
        self._shadow = I.DropShadow(self.Root, { Radius = 14 })

        self.Maid = I.Maid.new()
        self.Maid:Link(self.Root)

        Chrome.build(self)
        Search.build(self)
        Layout.build(self)

        self._focus = function() State.bringToFront(self) end

        self.Maid:Give(self.Root.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local top = I.ModalManager.Stack[#I.ModalManager.Stack]
            if top and top.Owner ~= self then return end
            State.bringToFront(self)
        end))

        table.insert(Kailex.Windows, self)
        self._focus()
        Layout.geom(self, false, #self.Tabs > 1)

        local dim
        if #Kailex.Windows == 1 then
            dim = I.Create("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 0,
                Parent = I.LayerWindows,
            })
            self._introMaid:Give(dim)
            I.Tween(dim, "Smooth", { BackgroundTransparency = 0.5 })
        end

        self.TitleBar.Position = UDim2.new(0, 0, 0, -18)
        self.Body.Position = UDim2.new(0, 0, 0, 74)
        I.Tween(self.Root, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { GroupTransparency = 0, Position = self._rootFinal })
        I.Tween(self._winScale, TweenInfo.new(0.44, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        I.Tween(self.TitleBar, TweenInfo.new(0.46, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Position = self._titleFinal })
        I.Tween(self.Body, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Position = self._bodyFinal })

        task.delay(0.1, function()
            if not self._destroyed and self._shadow then self._shadow.SetFade(0.55) end
        end)
        task.delay(0.24, function()
            if not self._destroyed and self._shadow then self._shadow.SetFade(0) end
        end)
        task.delay(0.55, function()
            if not self._destroyed and dim then
                I.Tween(dim, "Smooth", { BackgroundTransparency = 1 }, function()
                    dim:Destroy()
                end)
            end
        end)

        return self
    end

    local uiVisible = true

    function Kailex:SetVisible(state)
        state = state == true
        uiVisible = state
        I.LayerWindows.Visible = state
        I.LayerOverlay.Visible = state
        I.LayerNotify.Visible = state
        I.LayerTooltip.Visible = state
        if not state then
            I.Tooltip.Hide()
            I.ContextMenu.Hide()
            I.ModalManager.CloseAll()
        end
    end

    function Kailex:IsVisible()
        return uiVisible
    end
end
