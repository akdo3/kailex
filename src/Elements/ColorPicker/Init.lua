return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local View = I.ColorPickerView

    Elements.ColorPicker = I.MakeElementClass()

    function Elements.ColorPicker.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.ColorPicker)

        local S = {
            self = self,
            tab = tab,
            opts = opts,
            saveKey = tab:GetSaveKey(opts),
        }

        local default = opts.Default or opts.Color or Color3.fromRGB(122, 162, 247)
        if typeof(default) ~= "Color3" then default = Color3.fromRGB(122, 162, 247) end
        S.default = default

        local sv = I.SaveManager:Get(S.saveKey, nil)
        local color
        if type(sv) == "string" then
            local c = I.HexToColor(sv)
            if c then color = c end
        end
        color = color or default
        S.hadSaved = sv ~= nil
        S.color = color
        S.h, S.s, S.v = I.RGBtoHSV(color)

        View.initRow(S)
        self:_init(S.row, opts, tab)
        self:_initRow(S.title, S.right, S.left, S.rightW)
        self.Callback = opts.Callback or function() end

        S.open = false
        S.recentColors = {}

        S.apply = function(nh, ns, nv, notify)
            S.h, S.s, S.v = nh, ns, nv
            S.color = Color3.fromHSV(S.h, S.s, S.v)
            S.swatchBtn.BackgroundColor3 = S.color
            if S.popup and S.open then
                View.sync(S)
            end
            if notify then I.RunCallback(self.Callback, self.Title, S.color) end
        end

        S.fromColor = function(c, notify)
            local rh, rs, rv = I.RGBtoHSV(c)
            S.apply(rh, rs, rv, notify)
        end

        S.commit = function()
            local hex = I.ColorToHex(S.color)
            I.SaveValue(S.saveKey, hex)
            View.pushRecent(S, hex)
        end

        S.closePopup = function()
            if not S.open then return end
            S.open = false
            I.SaveValue(S.saveKey, I.ColorToHex(S.color))
            if S.mc then S.mc.Hide() end
        end

        S.openPopup = function()
            View.build(S)
            if S.open then return end
            S.open = true
            I.HotElement = nil
            View.refreshRecents(S)
            local sc = I.GetScale()
            local ap = S.swatchBtn.AbsolutePosition
            local asz = S.swatchBtn.AbsoluteSize
            local pw, ph = 240 * sc, 250 * sc
            local px = ap.X + asz.X + 10
            if px + pw > I.Viewport.X - 8 then px = ap.X - pw - 10 end
            px = math.clamp(px, 8, math.max(8, I.Viewport.X - pw - 8))
            local py = math.clamp(ap.Y + asz.Y / 2 - ph / 2, 8, math.max(8, I.Viewport.Y - ph - 8))
            S.popup.Position = UDim2.fromOffset(px / sc, py / sc)
            S.mc.Show()
            S.apply(S.h, S.s, S.v, false)
        end

        self.Maid:Give(S.swatchBtn.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if S.swatchBtn:GetAttribute("Dragging") then return end
            I.ApplyRipple(S.swatchBtn)
            I.PlaySound("Click", 0.6)
            if S.open then S.closePopup() else S.openPopup() end
        end))
        I.HookContextMenu(self, S.swatchBtn)

        self.Maid:Give(function()
            if S.mc then S.mc.Maid:Destroy() end
        end)

        self.Maid:Give(tab.Page:GetPropertyChangedSignal("Visible"):Connect(function()
            if not tab.Page.Visible then S.closePopup() end
        end))
        if tab.Window and tab.Window.MinimizedChanged then
            self.Maid:Give(tab.Window.MinimizedChanged:Connect(function(min)
                if min then S.closePopup() end
            end))
        end

        function self:Set(c, silent)
            if self._destroyed then return end
            if typeof(c) ~= "Color3" then return end
            S.fromColor(c, false)
            S.commit()
            if not silent then I.RunCallback(self.Callback, self.Title, S.color) end
        end

        function self:Get()
            return S.color
        end

        function self:CopyValue()
            return I.ColorToHex(S.color)
        end

        function self:Reset()
            if self._destroyed then return end
            self:Set(S.default, false)
        end

        self:_bindSaveReload(S.saveKey, function(v)
            if type(v) == "string" then
                local c = I.HexToColor(v)
                if c then
                    S.fromColor(c, false)
                    I.SaveValue(S.saveKey, I.ColorToHex(S.color))
                end
            end
        end)

        self:_initialCallback(S.hadSaved or opts.Default ~= nil, S.color)

        self:RecalcWidth()
        return self
    end
end
