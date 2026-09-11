return function(ctx)
    local I = ctx.Internal

    local View = {}

    function View.initRow(S)
        local opts, tab = S.opts, S.tab
        local rightW = 44
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Color",
            RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        S.row, S.title, S.right, S.left = row, title, right, left
        S.rightW = rightW

        S.swatchBtn = I.Create("TextButton", {
            Size = UDim2.fromOffset(38, 22),
            Text = "",
            BackgroundColor3 = S.color,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = 1,
            Parent = right,
            Children = {
                I.Corner(6),
                I.Create("UIStroke", {
                    Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.55,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            },
        })
    end

    function View.pushRecent(S, hex)
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
        if S.recentSwatches then View.refreshRecents(S) end
    end

    function View.refreshRecents(S)
        if not S.recentSwatches then return end
        local list = I.SaveManager:Get("__recentColors", {})
        if type(list) ~= "table" then list = {} end
        for i = 1, 8 do
            local sw = S.recentSwatches[i]
            local hex = list[i]
            local c = type(hex) == "string" and I.HexToColor(hex) or nil
            S.recentColors[i] = c
            if c then
                sw.BackgroundColor3 = c
                sw.Visible = true
            else
                sw.Visible = false
            end
        end
    end

    function View.sync(S)
        S.square.BackgroundColor3 = Color3.fromHSV(S.h, 1, 1)
        S.svKnob.Position = UDim2.new(S.s, 0, 1 - S.v, 0)
        S.hueKnob.Position = UDim2.new(S.h, 0, 0.5, 0)
        S.hueKnob.BackgroundColor3 = Color3.fromHSV(S.h, 1, 1)
        if not S.hexBox:IsFocused() then S.hexBox.Text = I.ColorToHex(S.color) end
    end

    function View.build(S)
        if S.popup then return end
        local self = S.self

        S.mc = I.ModalCard.MakeAnchor({
            Size = UDim2.fromOffset(240, 250),
            StrokeT = 0.35,
            HasScale = true,
            ZIndex = 100,
            Owner = S.tab.Window,
            Closer = S.closePopup,
            OnCatcherClick = S.closePopup,
        })
        S.popup = S.mc.Card
        S.catcher = S.mc.Catcher
        S.pickerScale = S.mc.Scale
        S.shadow = S.mc.Shadow

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
            Parent = S.popup,
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
            Parent = S.popup,
        })
        I.Icon(resetBtn, "Reset", "SubText", 13)
        I.AddTooltip(resetBtn, { Text = "Reset" })
        resetBtn.MouseButton1Click:Connect(function()
            I.ApplyRipple(resetBtn)
            I.PlaySound("Click", 0.6)
            S.fromColor(S.default, true)
            S.commit()
        end)

        S.square = I.Create("Frame", {
            Position = UDim2.fromOffset(12, 32),
            Size = UDim2.fromOffset(216, 120),
            BackgroundColor3 = Color3.fromHSV(S.h, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 31,
            Parent = S.popup,
            Children = { I.Corner(8) },
        })
        I.Create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 31,
            Parent = S.square,
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
            Parent = S.square,
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
        S.svKnob = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 33,
            Parent = S.square,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.Create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.5 }),
            },
        })

        S.hueBar = I.Create("Frame", {
            Position = UDim2.fromOffset(12, 158),
            Size = UDim2.fromOffset(216, 12),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 31,
            Parent = S.popup,
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
        S.hueKnob = I.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(S.h, 0, 0.5, 0),
            BackgroundColor3 = Color3.fromHSV(S.h, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 32,
            Parent = S.hueBar,
            Children = {
                I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                I.Create("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.2 }),
            },
        })

        S.hexBox = I.Create("TextBox", {
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
            Text = I.ColorToHex(S.color),
            ZIndex = 31,
            Parent = S.popup,
            Children = {
                I.Corner(6),
                I.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
                I.StrokeBind(1, "Stroke", 0.5),
            },
        })
        I.Bind(S.hexBox, "BackgroundColor3", "SurfaceLight")
        I.Bind(S.hexBox, "TextColor3", "Text")

        local hexCopy = I.MkButton(S.popup, {
            Position = UDim2.fromOffset(88, 182),
            Size = UDim2.fromOffset(50, 24),
            Text = "Copy",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            ZIndex = 31,
        }, { Text = "SubText", Corner = 6 })
        hexCopy.MouseButton1Click:Connect(function()
            I.CopyToClipboard(I.ColorToHex(S.color))
        end)

        S.hexBox.FocusLost:Connect(function()
            local c = I.HexToColor(S.hexBox.Text)
            if c then
                S.fromColor(c, true)
                S.commit()
            else
                S.hexBox.Text = I.ColorToHex(S.color)
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
            Parent = S.popup,
        })
        I.Bind(recentTitle, "TextColor3", "SubText")

        local recentRow = I.Create("Frame", {
            Position = UDim2.fromOffset(12, 226),
            Size = UDim2.new(1, -24, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 31,
            Parent = S.popup,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })
        S.recentSwatches = {}
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
                    I.Create("UIStroke", {
                        Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                },
            })
            S.recentSwatches[i] = sw
            sw.MouseButton1Click:Connect(function()
                local c = S.recentColors[idx]
                if not c or S.open ~= true then return end
                S.fromColor(c, true)
                S.commit()
            end)
        end
        View.refreshRecents(S)

        local function dragTracker(handle, onMove)
            handle.InputBegan:Connect(function(input)
                if I.DragManager.Active then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                I.BeginDrag(input, handle, {
                    ManagerKey = handle,
                    NoAttr = true,
                    OnMove = onMove,
                    OnEnd = function() S.commit() end,
                })
            end)
        end

        dragTracker(S.square, function(pos)
            local ap, as = S.square.AbsolutePosition, S.square.AbsoluteSize
            S.s = math.clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
            S.v = 1 - math.clamp((pos.Y - ap.Y) / math.max(1, as.Y), 0, 1)
            S.apply(S.h, S.s, S.v, true)
        end)
        dragTracker(S.hueBar, function(pos)
            local ap, as = S.hueBar.AbsolutePosition, S.hueBar.AbsoluteSize
            S.h = math.clamp((pos.X - ap.X) / math.max(1, as.X), 0, 1)
            S.apply(S.h, S.s, S.v, true)
        end)
    end

    I.ColorPickerView = View
end
