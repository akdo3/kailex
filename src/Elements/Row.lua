return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting

    local function CreateRow(parent, opts)
        opts = opts or {}
        local desc = opts.Description and tostring(opts.Description) or nil
        local height = opts.Height or (desc and (I.ROW_H + 16) or I.ROW_H)
        local rowProps = {
            Size = UDim2.new((opts.Width or 1), -3, 0, height),
            BackgroundColor3 = I.CurrentTheme.Element,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Parent = parent,
            Children = { I.Corner(8), I.StrokeBind(1, "Stroke", 0.65) },
        }
        if type(opts.Order) == "number" then
            rowProps.LayoutOrder = opts.Order
        end
        local row = I.Create("Frame", rowProps)
        I.Bind(row, "BackgroundColor3", "Element")
        I.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2),
            Parent = row,
        })

        local rightW = opts.RightWidth or 0
        local leftFrame = I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -rightW, 1, 0),
            Parent = row,
        })

        local title = I.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = desc and UDim2.new(1, -4, 0, 15) or UDim2.new(1, -4, 1, 0),
            Position = desc and UDim2.new(0, 0, 0, 2) or UDim2.fromOffset(0, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = I.CurrentTheme.Text,
            TextXAlignment = I.XAlign(),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = opts.Name or "",
            Parent = leftFrame,
        })

        if desc then
            local descLabel = I.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 13),
                Position = UDim2.new(0, 0, 0, 17),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = I.CurrentTheme.SubText,
                TextTransparency = 0.35,
                TextXAlignment = I.XAlign(),
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = desc,
                Parent = leftFrame,
            })

            descLabel.Name = "__desc"
            I.Bind(descLabel, "TextColor3", "SubText")
        end
        I.Bind(title, "TextColor3", "Text")

        local right
        if rightW > 0 or opts.ForceRight then
            right = I.Create("Frame", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(Setting.RTL and 0 or 1, 0.5),
                Position = Setting.RTL and UDim2.new(0, 0, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, rightW, 1, -4),
                Parent = row,
                Children = {
                    I.Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = I.HAlign(),
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                },
            })
        end

        if not opts.NoHover then
            I.AddHover(row, { StrokeTransparency = 0.65 })
        end
        return row, title, right, leftFrame
    end

    local function BareRow(parent, width, height)
        return I.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(width or 1, -3, 0, height),
            Parent = parent,
        })
    end

    I.CreateRow = CreateRow
    I.BareRow = BareRow
end
