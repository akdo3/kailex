return function(ctx)
    local I = ctx.Internal
    local TextService = I.TextService

    local ContextMenu = {}
    I.ContextMenu = ContextMenu

    local frame, catcher, shadow
    local entry = nil
    local hideToken = 0
    local buttons = {}
    local actions = {}
    local hl = 0

    local function paintHl(idx, on)
        local b = buttons[idx]
        if not b then return end
        I.Tween(b, "Instant", {
            BackgroundColor3 = on and I.CurrentTheme.ElementHover or I.CurrentTheme.Element,
            BackgroundTransparency = on and 0.4 or 1,
        })
    end

    local function setHl(idx)
        if idx == hl then return end
        paintHl(hl, false)
        hl = idx
        paintHl(hl, true)
    end

    local function moveHl(dir)
        local n = #buttons
        if n == 0 then return end
        local idx = hl
        if idx == 0 then
            idx = dir > 0 and 1 or n
        else
            idx += dir
            if idx < 1 then idx = n elseif idx > n then idx = 1 end
        end
        setHl(idx)
    end

    local function activate(idx)
        if idx < 1 or idx > #buttons then return end
        ContextMenu.Hide()
        local cb = actions[idx]
        if type(cb) == "function" then
            task.defer(function() I.SafeCall(cb) end)
        end
    end

    local function build()
        frame = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 301,
            Parent = I.LayerOverlay,
            Children = {
                I.Corner(10), I.StrokeBind(1, "Stroke", 0.25),
                I.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
                I.Create("UIPadding", {
                    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
                }),
            },
        })
        I.Bind(frame, "BackgroundColor3", "SurfaceLight")
        shadow = I.DropShadow(frame, { Radius = 10 })
        catcher = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Visible = false,
            ZIndex = 300,
            Parent = I.LayerOverlay,
        })
        catcher.MouseButton1Click:Connect(function() ContextMenu.Hide() end)

        I.LibMaid:Give(I.AddInputHook(function() return frame ~= nil and frame.Visible end, function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.Up then
                moveHl(-1)
            elseif input.KeyCode == Enum.KeyCode.Down then
                moveHl(1)
            elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                if hl > 0 then activate(hl) end
            end
        end))
    end

    function ContextMenu.Show(items, x, y)
        if not items or #items == 0 then return end
        x = tonumber(x) or 0
        y = tonumber(y) or 0
        if not frame then build() end
        hideToken += 1
        for _, ch in ipairs(frame:GetChildren()) do
            if ch:IsA("TextButton") or (ch:IsA("Frame") and ch.Name == "__sep") then ch:Destroy() end
        end
        table.clear(buttons)
        table.clear(actions)
        hl = 0
        local width = 140
        local totalH = 12
        for i, item in ipairs(items) do
            if item.Separator then
                local sep = I.Create("Frame", {
                    Name = "__sep",
                    BackgroundColor3 = I.CurrentTheme.Stroke,
                    BackgroundTransparency = 0.4,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    LayoutOrder = i,
                    Parent = frame,
                })
                I.Bind(sep, "BackgroundColor3", "Stroke")
                totalH += 3
            else
                local text = tostring(item.Text or "")
                local b = TextService:GetTextSize(text, I.TS(12), Enum.Font.Gotham, Vector2.new(400, 20))
                if b.X + 26 > width then width = b.X + 26 end
                local btn = I.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = I.CurrentTheme.Element,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = item.Danger and I.CurrentTheme.Error or I.CurrentTheme.Text,
                    TextXAlignment = I.XAlign(),
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    Parent = frame,
                    Children = { I.Create("UICorner", { CornerRadius = UDim.new(0, 6) }) },
                })
                I.Bind(btn, "BackgroundColor3", "Element")
                if item.Danger then
                    I.Bind(btn, "TextColor3", "Error")
                else
                    I.Bind(btn, "TextColor3", "Text")
                end
                I.AddHover(btn, { BaseTransparency = 1, HoverTransparency = 0.4 })
                local idx = #buttons + 1
                buttons[idx] = btn
                actions[idx] = item.Callback
                btn.MouseEnter:Connect(function() setHl(idx) end)
                btn.MouseButton1Click:Connect(function()
                    activate(idx)
                end)
                totalH += 28
            end
        end
        frame.Size = UDim2.fromOffset(width, totalH)
        local s = I.GetScale()
        local fw, fh = width * s, totalH * s
        local px = math.clamp(x, 8, math.max(8, I.Viewport.X - fw - 8))
        local py = math.clamp(y, 8, math.max(8, I.Viewport.Y - fh - 8))
        frame.Position = UDim2.fromOffset(px / s, py / s)
        frame.Visible = true
        catcher.Visible = true
        I.ShadowIn(shadow, function() return frame.Visible end, 0.08)
        I.ModalManager.Remove(entry)
        local tk = hideToken
        entry = I.ModalManager.Push(nil, function()
            if hideToken == tk then ContextMenu.Hide() end
        end)
    end

    function ContextMenu.Hide()
        if frame and frame.Visible then
            hideToken += 1
            if shadow then shadow.FadeOut() end
            frame.Visible = false
            catcher.Visible = false
        end
        hl = 0
        I.ModalManager.Remove(entry)
        entry = nil
    end

    I.LibMaid:Give(function() ContextMenu.Hide() end)
end
