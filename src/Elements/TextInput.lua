return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements
    local Setting = I.Setting

    Elements.TextInput = I.MakeElementClass()

    function Elements.TextInput.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.TextInput)
        local saveKey = tab:GetSaveKey(opts)
        local rightW = 170
        local row, title, right, left = I.CreateRow(tab.Content, {
            Name = opts.Name or "Input", RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        })
        self:_init(row, opts, tab)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = rightW
        self._width = rightW
        self.Callback = opts.Callback or function() end

        local value = I.SaveManager:Get(saveKey, opts.Default or "")
        if type(value) ~= "string" then value = tostring(opts.Default or "") end
        local lastFired = value
        local validator = type(opts.Validator) == "function" and opts.Validator or nil

        local box = I.Create("TextBox", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = I.CurrentTheme.SurfaceLight,
            BorderSizePixel = 0,
            Text = value,
            PlaceholderText = opts.Placeholder or "",
            PlaceholderColor3 = I.CurrentTheme.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Setting.RTL and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = right,
            Children = {
                I.Corner(6),
                I.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
                I.StrokeBind(1, "Stroke", 0.5),
            },
        })
        I.Bind(box, "BackgroundColor3", "SurfaceLight")
        I.Bind(box, "TextColor3", "Text")
        I.Bind(box, "PlaceholderColor3", "SubText")
        local boxStroke = box:FindFirstChildOfClass("UIStroke")

        self.Maid:Give(box.Focused:Connect(function()
            I.Tween(boxStroke, "Fast", { Color = I.CurrentTheme.Accent, Transparency = 0 })
        end))
        self.Maid:Give(box.FocusLost:Connect(function(enter)
            I.Tween(boxStroke, "Fast", { Color = I.CurrentTheme.Stroke, Transparency = 0.5 })
            local text = box.Text
            if validator then
                local ok = validator(text)
                if ok ~= true then
                    text = value
                    box.Text = text
                    I.PlaySound("Error")
                    I.FX.Shake(row, 6)
                    I.Tween(boxStroke, "Fast", { Color = I.CurrentTheme.Error, Transparency = 0 })
                    task.delay(1, function()
                        if not self._destroyed then
                            I.Tween(boxStroke, "Smooth", { Color = I.CurrentTheme.Stroke, Transparency = 0.5 })
                        end
                    end)
                    return
                end
            end
            if text ~= value then
                value = text
                I.SaveValue(saveKey, value)
            end
            if value ~= lastFired or enter then
                lastFired = value
                I.RunCallback(self.Callback, self.Title, value)
            end
        end))

        function self:Set(text, silent)
            if self._destroyed then return end
            value = tostring(text or "")
            lastFired = value
            box.Text = value
            I.SaveValue(saveKey, value)
            if not silent then I.RunCallback(self.Callback, self.Title, value) end
        end
        function self:Get() return value end
        function self:CopyValue() return value end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "string" then self:Set(v, true) end
        end)

        self:RecalcWidth()
        return self
    end
end
