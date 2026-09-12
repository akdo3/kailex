return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Kailex = ctx.Kailex

    Elements.Toggle = I.MakeElementClass()

    function Elements.Toggle.new(tab, opts)
        opts = opts or {}
        if opts.Default == nil then opts.Default = opts.defaultVal end
        local self = setmetatable({}, Elements.Toggle)
        local saveKey = tab:GetSaveKey(opts)
        local hadSaved = I.SaveManager:Get(saveKey, nil) ~= nil
        local default = I.SaveManager:Get(saveKey, opts.Default or opts.defaultVal or false) == true

        local switchW = I.Device.IsTouch and 50 or 42
        local switchH = I.Device.IsTouch and 26 or 22
        local usePin = opts.Pin == true
        local rightW = switchW + (usePin and 30 or 0)

        local row, _, right = I.MkRow(self, tab, opts, "Toggle", rightW)
        self._extraH = switchH

        self.Callback = opts.Callback or function() end
        self.State = default
        self.Changed = I.Signal.new()

        local switch = I.Create("Frame", {
            Size = UDim2.fromOffset(switchW, switchH),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            LayoutOrder = 20,
            Parent = right,
            Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
        })
        I.Bind(switch, "BackgroundColor3", "SurfaceLight")
        local stroke = I.Create("UIStroke", { Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = switch })
        local knob = I.Create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = switch,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.Create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.75, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            },
        })

        local function applyVisuals(animated)
            local on = self.State
            local dis = self._disabled
            local knobX = on and (switchW - 19) or 3
            if animated then
                I.Tween(switch, "Reveal", { BackgroundColor3 = on and I.CurrentTheme.Accent or I.CurrentTheme.SurfaceLight })
                I.Tween(stroke, "Reveal", {
                    Color = on and I.CurrentTheme.Accent or I.CurrentTheme.Stroke,
                    Transparency = (on and not dis) and 0 or 0.5,
                })
                I.Tween(knob, "Fast", {
                    Size = UDim2.fromOffset(20, 12),
                    Position = UDim2.new(0, on and (switchW - 23) or 1, 0.5, 0),
                }, function()
                    I.Tween(knob, "Pop", {
                        Size = UDim2.fromOffset(16, 16),
                        Position = UDim2.new(0, knobX, 0.5, 0),
                    })
                end)
            else
                knob.Size = UDim2.fromOffset(16, 16)
                knob.Position = UDim2.new(0, knobX, 0.5, 0)
                switch.BackgroundColor3 = on and I.CurrentTheme.Accent or I.CurrentTheme.SurfaceLight
                stroke.Color = on and I.CurrentTheme.Accent or I.CurrentTheme.Stroke
                stroke.Transparency = (on and not dis) and 0 or 0.5
            end
        end

        self._applyVisuals = applyVisuals
        self.Maid:Give(Kailex.ThemeChanged:Connect(function() applyVisuals(false) end))
        applyVisuals(false)

        local overlay = I.Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
            Parent = row,
        })
        self.Maid:Give(overlay.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if overlay:GetAttribute("Dragging") then return end
            I.ApplyRipple(overlay)
            self:Set(not self.State)
        end))
        I.HookContextMenu(self, overlay)

        if usePin then
            local pinBtn = I.Create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.fromOffset(22, 22),
                AutoButtonColor = false,
                LayoutOrder = 10,
                Parent = right,
            })
            local pinIcon = I.Icon(pinBtn, "Pin", "SubText")
            pinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            pinIcon.Position = UDim2.fromScale(0.5, 0.5)
            pinIcon.Size = UDim2.fromOffset(14, 14)
            self.Maid:Give(pinBtn.MouseButton1Click:Connect(function()
                I.ApplyRipple(pinBtn)
                I.PlaySound("Click", 0.5)
                I.QuickWidgets.Toggle(self)
            end))
        end

        self.Maid:Give(function() I.QuickWidgets.Destroy(self) end)

        function self:Set(state, silent)
            state = state == true
            if state == self.State then return end
            self.State = state
            applyVisuals(true)
            I.SaveValue(saveKey, state)
            self.Changed:Fire(state)
            if not silent then I.RunCallback(self.Callback, self.Title, state) end
        end
        function self:Get() return self.State end
        function self:CopyValue() return tostring(self.State) end

        function self:Reset()
            if self._destroyed then return end
            self:Set(opts.Default == true)
        end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "boolean" then self:Set(v, true) end
        end)

        self:_initialCallback(opts.Default ~= nil or hadSaved, self.State)

        self:RecalcWidth()
        return self
    end

    function Elements.Toggle:SetDisabled(state)
        I.Element.SetDisabled(self, state)
        if self._applyVisuals then self._applyVisuals(false) end
    end
end
