return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Kailex = ctx.Kailex

    Elements.ColorPicker = I.MakeElementClass()

    function Elements.ColorPicker.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.ColorPicker)
        local saveKey = tab:GetSaveKey(opts)
        local default = opts.Default or opts.Color or Color3.fromRGB(122, 162, 247)
        if typeof(default) ~= "Color3" then default = Color3.fromRGB(122, 162, 247) end

        local function loadColor()
            local sv = I.SaveManager:Get(saveKey, nil)
            if type(sv) == "string" then
                local c = I.HexToColor(sv)
                if c then return c end
            end
            return default
        end

        local color = loadColor()
        local hadSaved = I.SaveManager:Get(saveKey, nil) ~= nil
        local h, s, v = I.RGBtoHSV(color)

        local rightW = 44
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Color", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
        self.Callback = opts.Callback or function() end

        local swatchBtn = I.Create("TextButton", {
            Size = UDim2.fromOffset(38, 22),
            Text = "",
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = 1,
            Parent = right,
            Children = {
                I.Corner(6),
                I.Create("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            },
        })

        local popup, catcher, square, svKnob, hueBar, hueKnob, hexBox
        local pickerScale
        local closePopup
        local open = false
        local modalEntry
        local shadow
        local recentSwatches
        local recentColors = {}

        local refreshRecents
        local function pushRecent(hex)
            hex = tostring(hex or "")
            if hex == "" then return end
            local list = I.SaveManager:Get("__recentColors", {})
            if type(list) ~= "table" then list = {} end
            local out = { hex }
            for _, h2 in ipairs(list) do
                if h2 ~= hex and #out < 8 then
                    out[#out + 1] = h2
                end
            end
            I.SaveManager:Set("__recentColors", out)
            if recentSwatches then refreshRecents() end
        end
        refreshRecents = function()
            if not recentSwatches then return end
            local list = I.SaveManager:Get("__recentColors", {})
            if type(list) ~= "table" then list = {} end
            for i = 1, 8 do
                local sw = recentSwatches[i]
                local hex = list[i]
                local c = type(hex) == "string" and I.HexToColor(hex) or nil
                recentColors[i] = c
                if c then
                    sw.BackgroundColor3 = c
                    sw.Visible = true
                else
                    sw.Visible = false
                end
            end
        end

        local function apply(nh, ns, nv, notify)
            h, s, v = nh, ns, nv
            color = Color3.fromHSV(h, s, v)
            swatchBtn.BackgroundColor3 = color
            if popup and open then
                square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
                hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
                hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                if not hexBox:IsFocused() then hexBox.Text = I.ColorToHex(color) end
            end
            if notify then I.RunCallback(self.Callback, self.Title, color) end
        end

        local function build()
            popup = I.Create("CanvasGroup", {
                Size = UDim2.fromOffset(240, 250),
                BackgroundColor3 = I.CurrentTheme.Surface,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 30,
                Parent = I.LayerOverlay,
                Children = { I.Corner(12), I.StrokeBind(1, "Stroke", 0.35) },
            })
            I.Bind(popup, "BackgroundColor3", "Surface")
            pickerScale = I.Create("UIScale", { Scale = 1, Parent = popup })
            shadow = I.DropShadow(popup, { Radius = 12 })

            catcher = I.Create("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 29,
                Visible = false,
                Parent = I.LayerOverlay,
            })
            catcher.MouseButton1Click:Connect(function() closePopup() end)

            local ttl = I.Create("TextLabel", {
                Position = UDim2.fromOffset(12, 10),
                Size = UDim2.new(1, -56, 0, 16),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = I.CurrentTheme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = self.Title,
                ZIndex = 31,
                Parent = popup,
            })
            I.Bind(ttl, "TextColor3", "Text")

            local resetBtn = I.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 8),
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 31,
                Parent = popup,
            })
            local resetIcon = I.Icon(resetBtn, "Reset", "SubText")
            resetIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            resetIcon.Position = UDim2.fromScale(0.5, 0.5)
            resetIcon.Size = UDim2.fromOffset(13, 13)
            I.AddTooltip(resetBtn, { Text = "Reset" })
            resetBtn.MouseButton1Click:Connect(function()
                I.ApplyRipple(resetBtn)
                I.PlaySound("Click", 0.6)
                local rh, rs, rv = I.RGBtoHSV(default)
                apply(rh, rs, rv, true)
                I.SaveValue(saveKey, I.ColorToHex(color))
                pushRecent(I.ColorToHex(color))
            end)

            square = I.Create("Frame", {
                Position = UDim2.fromOffset(12, 32),
                Size = UDim2.fromOffset(216, 120),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
                Parent = popup,
                Children = { I.Corner(8) },
            })
            I.Create("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
                Parent = square,
                Children = {
                    I.Corner(8),
                    I.Create("UIGradient", {
                        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                    }),
                },
            })
            I.Create("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 32,
                Parent = square,
                Children = {
                    I.Corner(8),
                    I.Create("UIGradient", {
                        Rotation = 90,
                        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 0),
                        }),
                    }),
                },
            })
            svKnob = I.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 33,
                Parent = square,
                Children = {
                    I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    I.Create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.5 }),
                },
            })

            hueBar = I.Create("Frame", {
                Position = UDim2.fromOffset(12, 158),
                Size = UDim2.fromOffset(216, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
                Parent = popup,
                Children = {
                    I.Corner(6),
                    I.Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                        }),
                    }),
                },
            })
            hueKnob = I.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(h, 0, 0.5, 0),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 32,
                Parent = hueBar,
                Children = {
                    I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    I.Create("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.2 }),
                },
            })

            hexBox = I.Create("TextBox", {
                Position = UDim2.fromOffset(12, 182),
                Size = UDim2.fromOffset(70, 24),
                BackgroundColor3 = I.CurrentTheme.SurfaceLight,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.Text,
                PlaceholderText = "#RRGGBB",
                PlaceholderColor3 = I.CurrentTheme.SubText,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClearTextOnFocus = false,
                Text = I.ColorToHex(color),
                ZIndex = 31,
                Parent = popup,
                Children = {
                    I.Corner(6),
                    I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
                    I.StrokeBind(1, "Stroke", 0.5),
                },
            })
            I.Bind(hexBox, "BackgroundColor3", "SurfaceLight")
            I.Bind(hexBox, "TextColor3", "Text")

            local hexCopy = I.Create("TextButton", {
                Position = UDim2.fromOffset(88, 182),
                Size = UDim2.fromOffset(50, 24),
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = "Copy",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = I.CurrentTheme.SubText,
                AutoButtonColor = false,
                ZIndex = 31,
                Parent = popup,
                Children = { I.Corner(6) },
            })
            I.Bind(hexCopy, "BackgroundColor3", "Element")
            I.Bind(hexCopy, "TextColor3", "SubText")
            I.AddHover(hexCopy)
            hexCopy.MouseButton1Click:Connect(function()
                I.CopyToClipboard(I.ColorToHex(color))
            end)

            hexBox.FocusLost:Connect(function()
                local c = I.HexToColor(hexBox.Text)
                if c then
                    local rh, rs, rv = I.RGBtoHSV(c)
                    apply(rh, rs, rv, true)
                    I.SaveValue(saveKey, I.ColorToHex(color))
                    pushRecent(I.ColorToHex(color))
                else
                    hexBox.Text = I.ColorToHex(color)
                end
            end)

            local recentTitle = I.Create("TextLabel", {
                Position = UDim2.fromOffset(12, 212),
                Size = UDim2.new(1, -24, 0, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextColor3 = I.CurrentTheme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Recent",
                ZIndex = 31,
                Parent = popup,
            })
            I.Bind(recentTitle, "TextColor3", "SubText")
            local recentRow = I.Create("Frame", {
                Position = UDim2.fromOffset(12, 226),
                Size = UDim2.new(1, -24, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 31,
                Parent = popup,
                Children = {
                    I.Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                },
            })
            recentSwatches = {}
            for i = 1, 8 do
                local idx = i
                local sw = I.Create("TextButton", {
                    Size = UDim2.fromOffset(20, 20),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    ZIndex = 31,
                    Parent = recentRow,
                    Children = {
                        I.Corner(5),
                        I.Create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                    },
                })
                recentSwatches[i] = sw
                sw.MouseButton1Click:Connect(function()
                    local c = recentColors[idx]
                    if not c or open ~= true then return end
                    local rh, rs, rv = I.RGBtoHSV(c)
                    apply(rh, rs, rv, true)
                    I.SaveValue(saveKey, I.ColorToHex(color))
                    pushRecent(I.ColorToHex(color))
                end)
            end
            refreshRecents()

            local function dragTracker(handle, onMove)
                handle.InputBegan:Connect(function(input)
                    if I.DragManager.Active then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1
                        and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    I.BeginDrag(input, handle, {
                        ManagerKey = handle,
                        NoAttr = true,
                        OnMove = onMove,
                        OnEnd = function()
                            I.SaveValue(saveKey, I.ColorToHex(color))
                            pushRecent(I.ColorToHex(color))
                        end,
                    })
                end)
            end

            dragTracker(square, function(pos)
                local ap, as = square.AbsolutePosition, square.AbsoluteSize
                s = math.clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
                v = 1 - math.clamp((pos.Y - ap.Y) / math.max(1, as.Y), 0, 1)
                apply(h, s, v, true)
            end)
            dragTracker(hueBar, function(pos)
                local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
                h = math.clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
                apply(h, s, v, true)
            end)
        end

        local function openPopup()
            if not popup then build() end
            if open then return end
            open = true
            if shadow then shadow.SetFade(1) end
            I.HotElement = nil
            refreshRecents()
            local sc = I.GetScale()
            local ap = swatchBtn.AbsolutePosition
            local asz = swatchBtn.AbsoluteSize
            local pw, ph = 240 * sc, 250 * sc
            local px = ap.X + asz.X + 10
            if px + pw > I.Viewport.X - 8 then px = ap.X - pw - 10 end
            px = math.clamp(px, 8, math.max(8, I.Viewport.X - pw - 8))
            local py = math.clamp(ap.Y + asz.Y / 2 - ph / 2, 8, math.max(8, I.Viewport.Y - ph - 8))
            popup.Position = UDim2.fromOffset(px / sc, py / sc)
            catcher.Visible = true
            popup.Visible = true
            pickerScale.Scale = 0.94
            I.Tween(pickerScale, "Pop", { Scale = 1 })
            popup.GroupTransparency = 1
            I.Tween(popup, "Snappy", { GroupTransparency = 0 })
            if shadow then
                task.delay(0.1, function()
                    if open and shadow then shadow.SetFade(0) end
                end)
            end
            I.ModalManager.Remove(modalEntry)
            modalEntry = I.ModalManager.Push(tab.Window, closePopup)
            apply(h, s, v, false)
        end

        function closePopup()
            if not open then return end
            open = false
            I.ModalManager.Remove(modalEntry)
            modalEntry = nil
            I.SaveValue(saveKey, I.ColorToHex(color))
            if shadow then shadow.FadeOut() end
            I.Tween(pickerScale, "Vanish", { Scale = 0.95 })
            I.Tween(popup, "Fast", { GroupTransparency = 1 }, function()
                if not open then
                    popup.Visible = false
                    catcher.Visible = false
                end
            end)
        end

        self.Maid:Give(swatchBtn.MouseButton1Click:Connect(function()
            if self._disabled then return end
            if swatchBtn:GetAttribute("Dragging") then return end
            I.ApplyRipple(swatchBtn)
            I.PlaySound("Click", 0.6)
            if open then closePopup() else openPopup() end
        end))
        I.HookContextMenu(self, swatchBtn)
        local escHook = I.AddInputHook(function() return not self._destroyed end, function(input, gp)
            if open ~= true then return end
            if input.KeyCode ~= Enum.KeyCode.Escape then return end
            if gp then
                local focused = I.UserInputService:GetFocusedTextBox()
                if hexBox and focused == hexBox then
                    closePopup()
                end
                return
            end
            closePopup()
        end)
        self.Maid:Give(function() I.RemoveInputHook(escHook) end)
        self.Maid:Give(function()
            I.ModalManager.Remove(modalEntry)
        end)
        self.Maid:Give(tab.Page:GetPropertyChangedSignal("Visible"):Connect(function()
            if not tab.Page.Visible then closePopup() end
        end))
        if tab.Window and tab.Window.MinimizedChanged then
            self.Maid:Give(tab.Window.MinimizedChanged:Connect(function(min)
                if min then closePopup() end
            end))
        end

        function self:Set(c, silent)
            if self._destroyed then return end
            if typeof(c) ~= "Color3" then return end
            local rh, rs, rv = I.RGBtoHSV(c)
            apply(rh, rs, rv, false)
            I.SaveValue(saveKey, I.ColorToHex(color))
            pushRecent(I.ColorToHex(color))
            if not silent then I.RunCallback(self.Callback, self.Title, color) end
        end
        function self:Get() return color end
        function self:CopyValue() return I.ColorToHex(color) end
        function self:Reset()
            if self._destroyed then return end
            self:Set(default, false)
        end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "string" then
                local c = I.HexToColor(v)
                if c then
                    local rh, rs, rv = I.RGBtoHSV(c)
                    apply(rh, rs, rv, false)
                    I.SaveValue(saveKey, I.ColorToHex(color))
                end
            end
        end)
        if hadSaved or opts.Default ~= nil then
            task.defer(function()
                if not self._destroyed then I.RunCallback(self.Callback, self.Title, color) end
            end)
        end

        self:RecalcWidth()
        return self
    end
end
