return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local View = I.SliderView

    Elements.Slider = I.MakeElementClass()

    function Elements.Slider.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Slider)

        local S = {
            self = self, tab = tab, opts = opts,
            saveKey = tab:GetSaveKey(opts),
        }

        local min, max, step, decimals, snapValue = I.NumSpec(opts, 0, 100)
        S.min, S.max = min, max
        S.step = step
        S.decimals = decimals

        local default = tonumber(opts.Default or opts.Value or min) or min
        S.defaultValue = snapValue(default)

        local value = I.SaveManager:Get(S.saveKey, default)
        if type(value) ~= "number" then value = default end
        S.value = math.clamp(value, min, max)

        S.prefix = opts.Prefix and tostring(opts.Prefix) or nil
        S.suffix = opts.Suffix and tostring(opts.Suffix) or nil
        S.onRelease = opts.FireOnRelease == true
        S.dragging = false

        local function fmt(val)
            local s
            if S.decimals <= 0 then
                s = tostring(math.floor(val + 0.5))
            else
                s = string.format("%." .. S.decimals .. "f", val)
            end
            return (S.prefix or "") .. s .. (S.suffix or "")
        end
        S.fmt = fmt

        local function snap(f)
            return snapValue(min + (max - min) * f)
        end

        View.initRow(S)
        self:_init(S.row, opts, tab)
        self:_initRow(S.title, S.right, S.left, 0, 0)
        self.Callback = opts.Callback or function() end

        S.apply = function(newValue, instant)
            S.value = math.clamp(newValue, min, max)
            View.applyVisuals(S, instant)
            if S.updateResetVisibility then S.updateResetVisibility() end
        end

        S.updateResetVisibility = function()
            local show = math.abs(S.value - S.defaultValue) > 1e-4
            if show == S.resetShown then return end
            S.resetShown = show
            if show then
                S.resetBtn.Visible = true
                S.resetScale.Scale = 0.4
                I.Tween(S.resetScale, "PopSoft", { Scale = 1 })
            else
                I.Tween(S.resetScale, "Vanish", { Scale = 0.4 }, function()
                    if not S.resetShown then S.resetBtn.Visible = false end
                end)
            end
        end

        local function resetToDefault()
            if self._destroyed then return end
            if math.abs(S.value - S.defaultValue) > 1e-6 then
                I.ApplyRipple(S.resetBtn)
                I.PlaySound("ToggleOn", 0.5)
                self:Set(S.defaultValue)
                S.bubble.Visible = true
                S.bubble.Text = fmt(S.value)
                S.bubbleScale.Scale = 0.7
                I.Tween(S.bubbleScale, "PopSoft", { Scale = 1 })
                task.delay(0.55, function()
                    if not S.dragging and not self._destroyed then
                        I.Tween(S.bubbleScale, "Vanish", { Scale = 0.7 }, function()
                            if not S.dragging and not self._destroyed then S.bubble.Visible = false end
                        end)
                    end
                end)
            end
        end
        self.Maid:Give(S.resetBtn.MouseButton1Click:Connect(resetToDefault))
        self.Maid:Give(S.hit.MouseButton2Click:Connect(resetToDefault))
        function self:Reset() resetToDefault() end

        S.hit.InputBegan:Connect(function(input)
            if S.dragging or I.DragManager.Active then return end
            if self._disabled then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            S.dragging = true
            I.PlaySound("Slider")
            I.Tween(S.knob, "Spring", { Size = UDim2.fromOffset(18, 18) })
            I.Tween(S.knobStroke, "Fast", { Transparency = 0 })
            S.bubble.Visible = true
            S.bubbleScale.Scale = 0.7
            I.Tween(S.bubbleScale, "PopSoft", { Scale = 1 })

            local function update(x)
                local ap, as = S.track.AbsolutePosition, S.track.AbsoluteSize
                if as.X <= 1 then return end
                local frac = math.clamp((x - ap.X) / as.X, 0, 1)
                local v = snap(frac)
                if v ~= S.value then
                    S.apply(v)
                    if not S.onRelease then
                        I.RunCallback(self.Callback, self.Title, S.value)
                    end
                end
            end

            update(input.Position.X)

            local drag = I.BeginDrag(input, S.hit, {
                ManagerKey = S.track,
                NoAttr = true,
                OnMove = function(pos)
                    update(pos.X)
                end,
                OnEnd = function()
                    S.dragging = false
                    I.Tween(S.knob, "Spring", { Size = UDim2.fromOffset(14, 14) })
                    I.Tween(S.knobStroke, "Fast", { Transparency = 0.35 })
                    I.Tween(S.bubbleScale, "Vanish", { Scale = 0.7 }, function()
                        if not S.dragging and not self._destroyed then S.bubble.Visible = false end
                    end)
                    I.SaveValue(S.saveKey, S.value)
                    if S.onRelease then
                        I.RunCallback(self.Callback, self.Title, S.value)
                    end
                end,
            })
            if not drag then
                S.dragging = false
            end
        end)

        S.track.MouseEnter:Connect(function()
            if not S.dragging then I.Tween(S.knob, "Fast", { Size = UDim2.fromOffset(16, 16) }) end
        end)
        S.track.MouseLeave:Connect(function()
            if not S.dragging then I.Tween(S.knob, "Fast", { Size = UDim2.fromOffset(14, 14) }) end
        end)

        self.Maid:Give(S.box.FocusLost:Connect(function()
            local t = tostring(S.box.Text or "")
            if S.prefix and t:sub(1, #S.prefix) == S.prefix then t = t:sub(#S.prefix + 1) end
            if S.suffix and #S.suffix > 0 and t:sub(-#S.suffix) == S.suffix then t = t:sub(1, -#S.suffix - 1) end
            local num = tonumber((t:gsub(",", "."):gsub("%s", "")))
            if num then
                self:Set(num)
            else
                S.box.Text = string.format("%." .. S.decimals .. "f", S.value)
            end
        end))

        function self:Set(newValue, silent)
            if self._destroyed then return end
            local nv = tonumber(newValue)
            if nv == nil then return end
            nv = snapValue(nv)
            local changed = nv ~= S.value
            S.apply(nv)
            if changed then I.SaveValue(S.saveKey, S.value) end
            if changed and not silent then I.RunCallback(self.Callback, self.Title, S.value) end
        end

        function self:Get()
            return S.value
        end

        function self:CopyValue()
            return string.format("%." .. math.max(S.decimals, 0) .. "f", S.value)
        end

        function self:HandleArrow(dir)
            if self._destroyed or self._disabled then return end
            self:Set(S.value + step * dir)
        end

        I.TrackHot(self, S.row)

        self:_bindSaveReload(S.saveKey, function(v)
            if type(v) == "number" then self:Set(v, true) end
        end)

        S.apply(S.value, true)
        self:_initialCallback(opts.Default ~= nil or I.SaveManager:Get(S.saveKey, nil) ~= nil, S.value)

        self:RecalcWidth()
        return self
    end
end
