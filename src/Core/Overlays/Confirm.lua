return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local TextService = I.TextService

    local ModalActive = false
    local ConfirmQueue = {}

    local function tryRunNext()
        if ModalActive or #ConfirmQueue == 0 then return end
        local item = table.remove(ConfirmQueue, 1)
        Kailex:Confirm(item.data, item.fn)
    end

    I.LibMaid:Give(function() table.clear(ConfirmQueue) end)

    function Kailex:Confirm(data, onAccept)
        if ModalActive then
            if #ConfirmQueue < 8 then
                table.insert(ConfirmQueue, { data = data, fn = onAccept })
            end
            return nil
        end
        if type(data) == "string" then data = { Text = data } end
        data = (type(data) == "table") and table.clone(data) or {}
        if type(onAccept) == "function" then data.OnAccept = onAccept end
        for _, w in ipairs(Kailex.Windows) do
            if not w._destroyed and w._closeDropdowns then w:_closeDropdowns() end
        end
        ModalActive = true

        local styleType = string.lower(tostring(data.Type or ""))
        local isDanger = styleType == "danger" or data.Danger == true
        local isInfo = styleType == "info"

        local bodyText = tostring(data.Text or data.Description or "")
        local measured = TextService:GetTextSize(bodyText, I.TS(13), Enum.Font.Gotham, Vector2.new(324, 300))
        local bodyH = math.min(measured.Y, 140)
        local cardH = 16 + 18 + 6 + bodyH + 14 + 34 + 16

        local h
        local closed = false
        local function close(accepted)
            if closed then return end

            closed = true
            if h then h.Close() end

            I.RunCallback(accepted and data.OnAccept or data.OnDecline, data.Title or "Confirm", accepted)
        end

        local ok
        ok, h = pcall(I.ModalCard.OpenCenter, {
            Size = UDim2.fromOffset(360, cardH),
            OnDimmerClick = function() close(false) end,
            Closer = function() close(false) end,
        })
        if not ok then
            warn("[Kailex] " .. tostring(h))
            h = nil
        end
        if not h then
            ModalActive = false
            tryRunNext()
            return nil
        end

        local card = h.Card
        h.Maid:Give(function()
            ModalActive = false
            tryRunNext()
        end)

        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
            PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16),
            Parent = card,
        })

        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = data.Title or "Are you sure?",
            Parent = card,
        })
        I.Bind(title, "TextColor3", "Text")

        if isDanger or isInfo then
            local icon = I.Icon(card, isDanger and "Alert" or "Info", isDanger and "Error" or "Accent")
            icon.AnchorPoint = Vector2.new(0, 0.5)
            icon.Position = UDim2.new(0, 0, 0, 9)
            icon.Size = UDim2.fromOffset(15, 15)
            title.Position = UDim2.new(0, 21, 0, 0)
            title.Size = UDim2.new(1, -21, 0, 18)
        end

        local body = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 24),
            Size = UDim2.new(1, 0, 0, bodyH),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.SubText,
            TextWrapped = true,
            TextXAlignment = I.XAlign(),
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = bodyText,
            Parent = card,
        })
        I.Bind(body, "TextColor3", "SubText")

        local btnRow = I.Create("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 34),
            Parent = card,
            Children = {
                I.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = I.HAlign(),
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            },
        })

        local function mkBtn(text, accent, order)
            return I.MkButton(btnRow, {
                Size = UDim2.new(0.5, -4, 1, 0),
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                LayoutOrder = order,
                ZIndex = 42,
            }, accent and {
                Bg = "Accent", Text = "OnAccent",
                Hover = { HoverKey = "AccentHover", BaseKey = "Accent" },
            } or nil)
        end

        local decline = mkBtn(data.DeclineText or data.CancelText or "Cancel", false, 1)
        local accept = mkBtn(data.AcceptText or data.ConfirmText or "Confirm", true, 2)

        h.Maid:Give(accept.MouseButton1Click:Connect(function()
            close(true)
            I.ApplyRipple(accept)
            I.PlaySound("Click")
        end))
        h.Maid:Give(decline.MouseButton1Click:Connect(function()
            close(false)
            I.ApplyRipple(decline)
            I.PlaySound("Click")
        end))

        local hook = I.AddInputHook(function() return not closed end, function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                close(true)
            end
        end)
        h.Maid:Give(function() I.RemoveInputHook(hook) end)

        return card
    end
end
