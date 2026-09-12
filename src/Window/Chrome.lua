return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local Window = {}
    Window.__index = Window
    I.WindowClass = Window

    local Chrome = {}

    local TIPS = {
        Close = "Close",
        Minimize = "Minimize",
        Search = "Search (Ctrl+F)",
    }

    function Window:SetTitle(t)
        self.Title = tostring(t or "")
        self.TitleLabel.Text = self.Title
    end

    function Chrome.build(self)
        local cfg = self._cfg

        local introMaid = I.Maid.new()
        self.Maid:Give(introMaid)
        self._introMaid = introMaid

        local titleBar = I.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
            Parent = self.Root,
        })
        self.TitleBar = titleBar

        local body = I.Create("Frame", {
            Position = UDim2.new(0, 0, 0, 56),
            Size = UDim2.new(1, 0, 1, -56),
            BackgroundTransparency = 1,
            Parent = self.Root,
        })
        self.Body = body

        local titleX = 14
        if cfg.Icon ~= nil then
            titleX = 40
            self.IconImg = I.MkIcon(titleBar, cfg.Icon, {
                Position = UDim2.fromOffset(14, 5),
                Size = UDim2.fromOffset(20, 20),
            })
        end

        self._titleReserve = 130 + (titleX - 14)

        local titleLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(titleX, 7),
            Size = UDim2.new(1, -self._titleReserve, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = self.Title,
            Parent = titleBar,
        })
        I.Bind(titleLabel, "TextColor3", "Text")
        self.TitleLabel = titleLabel

        local subLabel = I.Create("TextLabel", {
            Position = UDim2.fromOffset(titleX, 26),
            Size = UDim2.new(1, -self._titleReserve, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(self.SubTitle or ""),
            Parent = titleBar,
        })
        I.Bind(subLabel, "TextColor3", "SubText")
        self.SubLabel = subLabel

        local titleDivider = I.Create("Frame", {
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = I.CurrentTheme.Stroke,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Parent = titleBar,
        })
        I.Bind(titleDivider, "BackgroundColor3", "Stroke")
        self.TitleDivider = titleDivider

        local searchBox = I.Create("TextBox", {
            Position = UDim2.fromOffset(14, 11),
            Size = UDim2.new(0, 220, 0, 24),
            BackgroundTransparency = 1,
            Visible = false,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = I.CurrentTheme.Text,
            PlaceholderText = "Search ...",
            PlaceholderColor3 = I.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = titleBar,
        })
        I.Bind(searchBox, "TextColor3", "Text")
        I.Bind(searchBox, "PlaceholderColor3", "SubText")
        self._searchBox = searchBox

        local searchLine = I.Create("Frame", {
            Position = UDim2.fromOffset(14, 35),
            Size = UDim2.new(0, 0, 0, 1),
            BackgroundColor3 = I.CurrentTheme.Accent,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = titleBar,
        })
        I.Bind(searchLine, "BackgroundColor3", "Accent")
        self._searchLine = searchLine

        local function titleButton(kind, xPos, colorKey)
            local b = I.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xPos, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                BackgroundTransparency = 1,
                BackgroundColor3 = I.CurrentTheme.Element,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = titleBar,
            })
            b:SetAttribute("FinalX", xPos)
            I.Icon(b, kind, colorKey or "SubText", 12)
            I.AddTooltip(b, { Text = TIPS[kind] or kind })
            return b
        end

        local closeB = titleButton("Close", -10, "Text")
        closeB.MouseEnter:Connect(function()
            I.Tween(closeB, "Fast", { BackgroundColor3 = I.CurrentTheme.Error, BackgroundTransparency = 0.15 })
        end)
        closeB.MouseLeave:Connect(function()
            I.Tween(closeB, "Fast", { BackgroundTransparency = 1 })
        end)
        self.Maid:Give(closeB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self:Close()
        end))

        local minB = titleButton("Minimize", -44)
        I.AddHover(minB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
        self.Maid:Give(minB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self:SetMinimized(true)
        end))

        local searchB = titleButton("Search", -78)
        I.AddHover(searchB, { BaseTransparency = 1, HoverTransparency = 0.85, IgnoreStroke = true })
        self.Maid:Give(searchB.MouseButton1Click:Connect(function()
            I.PlaySound("Click", 0.5)
            self._setSearch(nil, not self._searchActive)
        end))

        self._titleButtons = { searchB, minB, closeB }

        I.MakeDraggable(titleBar, self.Root, {
            Clamp = true,
            ModalOwner = self,
            OnEnd = function() self:SavePlacement() end,
        })

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                self._focus()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                local m = UserInputService:GetMouseLocation()
                I.ContextMenu.Show({
                    {
                        Text = self.Minimized and "Expand" or "Minimize",
                        Callback = function()
                            if not self._destroyed then self:SetMinimized(not self.Minimized) end
                        end,
                    },
                    { Separator = true },
                    {
                        Text = self._alwaysTop and "Disable always on top" or "Always on top",
                        Callback = function()
                            if self._destroyed then return end
                            self._alwaysTop = not self._alwaysTop
                            if self._alwaysTop then
                                self.Root.ZIndex = 100
                            else
                                self._focus()
                            end
                        end,
                    },
                    { Separator = true },
                    {
                        Text = "Close",
                        Danger = true,
                        Callback = function()
                            if not self._destroyed then self:Close() end
                        end,
                    },
                }, m.X, m.Y)
            end
        end)

        local expandIcon = I.Icon(self.Root, "Chevron", "SubText")
        expandIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        expandIcon.Position = UDim2.new(1, -18, 0.5, 0)
        expandIcon.Size = UDim2.fromOffset(12, 12)
        expandIcon.Rotation = 180
        expandIcon.Visible = false
        self._expandIcon = expandIcon

        local pillHit = I.Create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Visible = false,
            ZIndex = 60,
            Parent = self.Root,
        })
        I.MakeDraggable(pillHit, self.Root, { Clamp = true, ModalOwner = self })
        self.Maid:Give(pillHit.MouseButton1Click:Connect(function()
            if pillHit:GetAttribute("Dragging") then return end
            self._focus()
            I.PlaySound("Click", 0.6)
            self:SetMinimized(false)
        end))
        self._pillHit = pillHit
    end

    I.WindowChrome = Chrome
end
