return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting
    local TextService = I.TextService

    local ModalActive = false

    function Kailex:Confirm(data, onAccept)
        if ModalActive then return nil end
        if type(data) == "string" then data = { Text = data } end
        data = data or {}
        if type(onAccept) == "function" then data.OnAccept = onAccept end
        for _, w in ipairs(Kailex.Windows) do
            if not w._destroyed and w._closeDropdowns then w:_closeDropdowns() end
        end
        ModalActive = true
        local maid = I.Maid.new()
        maid:Give(function() ModalActive = false end)

        local styleType = string.lower(tostring(data.Type or ""))
        local isDanger = styleType == "danger" or data.Danger == true
        local isInfo = styleType == "info"
        local accentKey = isDanger and "Error" or "Accent"

        local dimmer = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 300,
            Parent = I.LayerOverlay,
        })
        maid:Give(dimmer)
        maid:Link(dimmer)

        local card = I.Create("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(360, 200),
            BackgroundColor3 = I.CurrentTheme.Surface,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            ZIndex = 301,
            Parent = I.LayerOverlay,
            Children = { I.Corner(12), I.StrokeBind(1, "Stroke", 0.4) },
        })
        I.Bind(card, "BackgroundColor3", "Surface")
        maid:Give(card)
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
            PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16),
            Parent = card,
        })
        local shadow = I.DropShadow(card, { Radius = 12 })
        if shadow then shadow.SetFade(1) end

        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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

        local bodyText = tostring(data.Text or data.Description or "")
        local b = TextService:GetTextSize(bodyText, I.TS(13), Enum.Font.Gotham, Vector2.new(324, 300))
        local bodyH = math.min(b.Y, 140)
        local body = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 24),
            Size = UDim2.new(1, 0, 0, bodyH),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.SubText,
            TextWrapped = true,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
        })

        local function mkBtn(text, isAccent, pos)
            local btn = I.Create("TextButton", {
                Position = pos,
                Size = UDim2.new(0.48, -4, 1, 0),
                BackgroundColor3 = isAccent and I.CurrentTheme[accentKey] or I.CurrentTheme.Element,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = isAccent and I.CurrentTheme.OnAccent or I.CurrentTheme.Text,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = btnRow,
                Children = { I.Corner(8) },
            })
            if isAccent then
                I.Bind(btn, "BackgroundColor3", accentKey)
                I.Bind(btn, "TextColor3", "OnAccent")
                if isDanger then
                    I.AddHover(btn, { HoverKey = "Error", BaseKey = "Error", HoverTransparency = 0.15 })
                else
                    I.AddHover(btn, { HoverKey = "AccentHover", BaseKey = "Accent" })
                end
            else
                I.Bind(btn, "BackgroundColor3", "Element")
                I.Bind(btn, "TextColor3", "Text")
                I.AddHover(btn)
            end
            I.AddPress(btn)
            return btn
        end

        local decline = mkBtn(data.DeclineText or data.CancelText or "Cancel", false, UDim2.new(0, 0, 0, 0))
        local accept  = mkBtn(data.AcceptText  or data.ConfirmText or "Confirm", true,  UDim2.new(0.52, 0, 0, 0))

        card.Size = UDim2.fromOffset(360, 16 + 18 + 6 + bodyH + 14 + 34 + 16)

        local scale = I.Create("UIScale", { Scale = 0.88, Parent = card })

        local closed = false
        local modalEntry
        local function close(accepted)
            if closed then return end
            closed = true
            I.ModalManager.Remove(modalEntry)
            if shadow then shadow.FadeOut() end
            I.Tween(dimmer, "Fast", { BackgroundTransparency = 1 })
            I.Tween(scale, "Vanish", { Scale = 0.92 })
            I.Tween(card, "Fast", { GroupTransparency = 1 })
            if accepted and data.OnAccept then I.SafeCall(data.OnAccept, true) end
            if not accepted and data.OnDecline then I.SafeCall(data.OnDecline, false) end
            task.delay(0.2, function()
                maid:Destroy()
            end)
        end

        modalEntry = I.ModalManager.Push(nil, function() close(false) end)

        maid:Give(accept.MouseButton1Click:Connect(function()
            close(true)
            I.ApplyRipple(accept)
            I.PlaySound("Click")
        end))
        maid:Give(decline.MouseButton1Click:Connect(function()
            close(false)
            I.ApplyRipple(decline)
            I.PlaySound("Click")
        end))
        maid:Give(dimmer.MouseButton1Click:Connect(function() close(false) end))

        local hook = I.AddInputHook(function() return not closed end, function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                close(true)
            elseif input.KeyCode == Enum.KeyCode.Escape then
                close(false)
            end
        end)
        maid:Give(function() I.RemoveInputHook(hook) end)

        I.Tween(dimmer, "Normal", { BackgroundTransparency = 0.5 })
        I.Tween(card, "Snappy", { GroupTransparency = 0 })
        I.Tween(scale, "Pop", { Scale = 1 })
        if shadow then
            task.delay(0.1, function()
                if not closed and shadow then shadow.SetFade(0) end
            end)
        end
        return card
    end
end
