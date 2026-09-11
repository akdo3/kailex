return function(ctx)
    local I = ctx.Internal
    local Elements = I.Elements

    Elements.Vector3Input = I.MakeElementClass()

    function Elements.Vector3Input.new(tab, opts)
        opts = opts or {}
        local self = setmetatable({}, Elements.Vector3Input)
        local saveKey = tab:GetSaveKey(opts)
        local rightW = 196
        local rowH = 60
        local _, _, right = I.MkRow(self, tab, opts, "Vector3", rightW, rowH)
        self.Callback = opts.Callback or function() end

        local function load()
            local sv = I.SaveManager:Get(saveKey, nil)
            if type(sv) == "table" and tonumber(sv.X) and tonumber(sv.Y) and tonumber(sv.Z) then
                return Vector3.new(sv.X, sv.Y, sv.Z)
            end
            return opts.Default
        end
        local value = load()
        if typeof(value) ~= "Vector3" then value = Vector3.new() end

        local boxes = {}
        local names = { "X", "Y", "Z" }
        for i = 1, 3 do
            local b = I.Create("TextBox", {
                Size = UDim2.fromOffset(60, 24),
                BackgroundColor3 = I.CurrentTheme.SurfaceLight,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.Text,
                PlaceholderText = names[i],
                PlaceholderColor3 = I.CurrentTheme.SubText,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClearTextOnFocus = false,
                Text = string.format("%.2f", ({value.X, value.Y, value.Z})[i]),
                LayoutOrder = i,
                Parent = right,
                Children = { I.Corner(6), I.StrokeBind(1, "Stroke", 0.5) },
            })
            I.Bind(b, "BackgroundColor3", "SurfaceLight")
            I.Bind(b, "TextColor3", "Text")
            boxes[i] = b
            self.Maid:Give(b.FocusLost:Connect(function()
                local n = tonumber((b.Text:gsub(",", ".")))
                if n then
                    local c = { value.X, value.Y, value.Z }
                    c[i] = n
                    self:Set(Vector3.new(c[1], c[2], c[3]))
                else
                    b.Text = string.format("%.2f", ({value.X, value.Y, value.Z})[i])
                end
            end))
        end

        function self:Set(v, silent)
            if self._destroyed then return end
            if typeof(v) ~= "Vector3" then return end
            value = v
            for i = 1, 3 do
                if not boxes[i]:IsFocused() then
                    boxes[i].Text = string.format("%.2f", ({value.X, value.Y, value.Z})[i])
                end
            end
            I.SaveValue(saveKey, { X = value.X, Y = value.Y, Z = value.Z })
            if not silent then I.RunCallback(self.Callback, self.Title, value) end
        end
        function self:Get() return value end
        function self:CopyValue() return tostring(value) end

        function self:Reset()
            if self._destroyed then return end
            if typeof(opts.Default) == "Vector3" then
                self:Set(opts.Default)
            else
                self:Set(Vector3.new())
            end
        end

        function self:SetDisabled(state)
            I.Element.SetDisabled(self, state)
            I.SetBoxDisabled(boxes, state)
        end

        self:_bindSaveReload(saveKey, function(v)
            if type(v) == "table" then
                self:Set(Vector3.new(tonumber(v.X) or 0, tonumber(v.Y) or 0, tonumber(v.Z) or 0), true)
            end
        end)

        self:_initialCallback(opts.Default ~= nil or I.SaveManager:Get(saveKey, nil) ~= nil, value)

        self:RecalcWidth()
        return self
    end
end
