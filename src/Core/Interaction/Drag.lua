return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService
    local RunService = I.RunService

    local DragManager = { Active = nil }
    I.DragManager = DragManager

    local function ClampWindowToScreen(root)
        local s = I.GetScale()
        local margin = 8
        local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
        local x, y = root.AbsolutePosition.X, root.AbsolutePosition.Y
        local nx = math.clamp(x, margin, math.max(margin, I.Viewport.X - w - margin))
        local ny = math.clamp(y, margin, math.max(margin, I.Viewport.Y - h - margin))
        if nx ~= x or ny ~= y then
            local ap = root.AnchorPoint
            root.Position = UDim2.fromOffset(
                (nx + ap.X * w) / s,
                (ny + ap.Y * h) / s
            )
        end
    end
    I.ClampWindowToScreen = ClampWindowToScreen

    local function MakeDraggable(handle, target, opts)
        opts = opts or {}
        local threshold = opts.Threshold or 6
        local dragging = false
        local maid = I.Maid.new()

        maid:Give(handle.InputBegan:Connect(function(input)
            if dragging or DragManager.Active ~= nil then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end

            dragging = true
            DragManager.Active = target

            if target.AnchorPoint.X ~= 0 or target.AnchorPoint.Y ~= 0 then
                local s = I.GetScale()
                target.AnchorPoint = Vector2.new(0, 0)
                target.Position = UDim2.fromOffset(target.AbsolutePosition.X / s, target.AbsolutePosition.Y / s)
            end

            if opts.OnStart then I.SafeCall(opts.OnStart, target) end

            local startPos = target.Position
            local startMouse = UserInputService:GetMouseLocation()
            local moved = false
            local dragMaid = I.Maid.new()
            maid:Give(dragMaid)

            local function finish()
                if not dragging then return end
                dragging = false
                if DragManager.Active == target then DragManager.Active = nil end
                handle:SetAttribute("Dragging", nil)
                dragMaid:Destroy()
                if moved and opts.OnEnd then I.SafeCall(opts.OnEnd) end
            end

            dragMaid:Give(UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                    finish()
                end
            end))
            dragMaid:Give(handle.Destroying:Connect(finish))
            dragMaid:Give(RunService.Heartbeat:Connect(function()
                if not I.IsInputDown(input.UserInputType) then finish() end
            end))
            dragMaid:Give(RunService.RenderStepped:Connect(function()
                if not dragging then return end
                local mouse = UserInputService:GetMouseLocation()
                local dx, dy = mouse.X - startMouse.X, mouse.Y - startMouse.Y
                if not moved and math.abs(dx) + math.abs(dy) > threshold then
                    moved = true
                    handle:SetAttribute("Dragging", true)
                end
                if moved then
                    local s = I.GetScale()
                    target.Position = UDim2.fromOffset(startPos.X.Offset + dx / s, startPos.Y.Offset + dy / s)
                    if opts.Clamp then ClampWindowToScreen(target) end
                end
            end))
        end))

        I.Once(handle.Destroying, function() maid:Destroy() end)
        return maid
    end
    I.MakeDraggable = MakeDraggable

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            task.defer(function()
                local anyDown = false
                local ok, btns = pcall(UserInputService.GetMouseButtonsPressed, UserInputService)
                if ok and type(btns) == "table" then
                    anyDown = #btns > 0
                end
                if not anyDown then DragManager.Active = nil end
            end)
        end
    end)
end
