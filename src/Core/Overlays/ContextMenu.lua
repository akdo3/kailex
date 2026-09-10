return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local ContextMenu = {}
    I.ContextMenu = ContextMenu

    local frame, catcher, shadow
    local entry = nil
    local hideToken = 0

    local function build()
        frame = I.Create("Frame", {
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 320,
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
            ZIndex = 310,
            Parent = I.LayerOverlay,
        })
        catcher.MouseButton1Click:Connect(function() ContextMenu.Hide() end)
    end

    function ContextMenu.Show(items, x, y)
        if not items or #items == 0 then return end
        if not frame then build() end
        hideToken += 1
        for _, ch in ipairs(frame:GetChildren()) do
            if ch:IsA("TextButton") or (ch:IsA("Frame") and ch.Name == "__sep") then ch:Destroy() end
        end
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
                local b = I.TextService:GetTextSize(text, I.TS(12), Enum.Font.Gotham, Vector2.new(400, 20))
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
                    TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
                I.AddHover(btn)
                I.AddPress(btn)
                btn.MouseButton1Click:Connect(function()
                    ContextMenu.Hide()
                    if type(item.Callback) == "function" then
                        task.defer(function() I.SafeCall(item.Callback) end)
                    end
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
        if shadow then
            shadow.SetFade(1)
            task.delay(0.08, function()
                if frame.Visible and shadow then shadow.SetFade(0) end
            end)
        end
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
        I.ModalManager.Remove(entry)
        entry = nil
    end

    I.LibMaid:Give(function() ContextMenu.Hide() end)
end
