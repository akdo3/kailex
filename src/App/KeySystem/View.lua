return function(ctx)
    local I = ctx.Internal

    local View = {}

    function View.setStatus(K, text, colorKey)
        K.statusLabel.Text = tostring(text or "")
        K.statusLabel.TextColor3 = I.CurrentTheme[colorKey] or I.CurrentTheme.SubText
    end

    function View.fadeOut(K)
        K.h.Close()
    end

    function View.enter(K)
        task.defer(function()
            if K.alive and K.inputBox then K.inputBox:CaptureFocus() end
        end)
    end

    function View.build(K)
        local opts = K.options
        K.h = I.ModalCard.OpenCenter({
            Size = K.cardSize or UDim2.fromOffset(360, 246),
            Closer = K.declineNow,
        })
        K.maid = K.h.Maid
        K.card = K.h.Card
        K.ksScale = K.h.Scale

        local titleLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 16),
            Size = UDim2.new(1, -36, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = K.title, ZIndex = 42, Parent = K.card,
        })
        I.Bind(titleLabel, "TextColor3", "Text")
        local descLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 38),
            Size = UDim2.new(1, -36, 0, 30),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Text = K.desc, ZIndex = 42, Parent = K.card,
        })
        I.Bind(descLabel, "TextColor3", "SubText")

        local descShown = K._descSpace or 30
        descLabel.Size = UDim2.new(1, -36, 0, descShown)

        K.statusLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(18, 38 + 12 + descShown + 38 + 6),
            Size = UDim2.new(1, -36, 0, 15),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
            ZIndex = 42, Parent = K.card,
        })
        I.Bind(K.statusLabel, "TextColor3", "SubText")

        local hasPaste = I.ReadClipboard ~= nil

        K.inputBox = I.Create("TextBox", {
            Position = UDim2.fromOffset(18, 38 + 12 + descShown),
            Size = UDim2.new(1, -36, 0, 38),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            PlaceholderText = "Enter your key...",
            PlaceholderColor3 = I.CurrentTheme.SubText,
            ClearTextOnFocus = false, Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 42, Parent = K.card,
            Children = { I.Corner(8) },
        })
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, hasPaste and 66 or 10),
            Parent = K.inputBox,
        })
        I.Bind(K.inputBox, "BackgroundColor3", "SurfaceLight")
        I.Bind(K.inputBox, "TextColor3", "Text")
        I.Bind(K.inputBox, "PlaceholderColor3", "SubText")
        K.inputStroke = I.Create("UIStroke", {
            Thickness = 1, Transparency = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = K.inputBox,
        })
        I.Bind(K.inputStroke, "Color", "Stroke")

        if hasPaste then
            local pasteBtn = I.MkButton(K.inputBox, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(56, 26),
                Text = "Paste",
                Font = Enum.Font.GothamBold, TextSize = 11,
                ZIndex = 43,
            }, { Text = "SubText", Corner = 6 })
            K.maid:Give(pasteBtn.MouseButton1Click:Connect(function()
                if not K.alive then return end
                local txt = I.ReadClipboard()
                if type(txt) == "string" and txt:match("%S") then
                    K.inputBox.Text = I.Trim(txt)
                    I.PlaySound("Click", 0.5)
                    View.setStatus(K, "Key pasted from clipboard - press Verify.")
                end
            end))
        end

        local btnY = 38 + 12 + descShown + 38 + 6 + 15 + 14
        local function mkBtn(text, accent, xPos, w)
            return I.MkButton(K.card, {
                Position = UDim2.fromOffset(xPos, btnY),
                Size = UDim2.fromOffset(w, 40),
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                ZIndex = 42,
            }, accent and {
                Bg = "Accent", Text = "OnAccent",
                Hover = { HoverKey = "AccentHover", BaseKey = "Accent" },
            } or nil)
        end

        if K.link then
            K.verifyBtn = mkBtn("Verify", true, 226, 116)
            K.declineBtn = mkBtn(opts.DeclineText or "Decline", false, 122, 96)
            K.linkBtn = mkBtn(opts.LinkText or "Get Key", false, 18, 96)
        else
            K.verifyBtn = mkBtn("Verify", true, 126, 216)
            K.declineBtn = mkBtn(opts.DeclineText or "Decline", false, 18, 100)
        end
    end

    I.KeySystemView = View
end
