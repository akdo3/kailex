return function(ctx)
    local I = ctx.Internal
    local Setting = I.Setting
    local UserInputService = I.UserInputService

    local RipplePool = {}
    I.RipplePool = RipplePool

    local function ApplyRipple(target, inputPos)
        if not Setting.Effects then return end
        if not target or not target.Parent or I.Device.IsConsole then return end
        local count = target:GetAttribute("__rpl")
        if not count then
            target:SetAttribute("__rplPrev", target.ClipsDescendants)
        end
        target.ClipsDescendants = true
        count = (count or 0) + 1
        target:SetAttribute("__rpl", count)

        local mouse = inputPos or UserInputService:GetMouseLocation()
        local s = I.GetScale()
        local relX = (mouse.X - target.AbsolutePosition.X) / s
        local relY = (mouse.Y - target.AbsolutePosition.Y) / s

        local function newRipple()
            local r = I.Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Visible = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 50,
                Children = { I.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
            })
            I.Once(r.Destroying, function()
                for i, x in ipairs(RipplePool) do
                    if x == r then table.remove(RipplePool, i) break end
                end
            end)
            table.insert(RipplePool, r)
            return r
        end

        local rpl
        for _, r in ipairs(RipplePool) do
            if not r.Visible and not r.Parent then rpl = r break end
        end
        if not rpl then rpl = newRipple() end

        if not pcall(function() rpl.Parent = target end) then
            for i, r in ipairs(RipplePool) do
                if r == rpl then table.remove(RipplePool, i) break end
            end
            rpl = newRipple()
            rpl.Parent = target
        end

        rpl.Position = UDim2.fromOffset(relX, relY)
        rpl.Size = UDim2.fromOffset(0, 0)
        rpl.BackgroundTransparency = 0.68
        rpl.Visible = true

        local size = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * 1.2
        local t = I.Tween(rpl, "Ripple", {
            Size = UDim2.fromOffset(size / s, size / s),
            BackgroundTransparency = 1,
        })
        I.Once(t.Completed, function()
            if rpl.Visible then
                rpl.Visible = false
                rpl.Parent = nil
            end
            local c = (target:GetAttribute("__rpl") or 1) - 1
            if c > 0 then
                target:SetAttribute("__rpl", c)
            else
                target:SetAttribute("__rpl", nil)
                target.ClipsDescendants = target:GetAttribute("__rplPrev") == true
                target:SetAttribute("__rplPrev", nil)
            end
        end)
    end

    I.LibMaid:Give(function()
        for i = #RipplePool, 1, -1 do
            pcall(function() RipplePool[i]:Destroy() end)
        end
        table.clear(RipplePool)
    end)

    I.ApplyRipple = ApplyRipple
end
