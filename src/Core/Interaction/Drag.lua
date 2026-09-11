return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService
    local RunService = I.RunService

    local DragManager = { Active = nil }
    I.DragManager = DragManager

    local function ClampToScreen(root, margin)
        margin = margin or 8
        local s = I.GetScale()
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
    I.ClampWindowToScreen = ClampToScreen
    I.ClampFloat = ClampToScreen

    local function BeginDrag(input, handle, opts)
        opts = opts or {}
        if DragManager.Active ~= nil then return nil end
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1
            and inputType ~= Enum.UserInputType.Touch then return nil end

        local key = opts.ManagerKey or handle
        local threshold = tonumber(opts.Threshold) or 0
        local useAttr = opts.NoAttr ~= true
        local moved = threshold <= 0
        DragManager.Active = key
        if moved and useAttr then handle:SetAttribute("Dragging", true) end

        if opts.ModalOwner ~= nil then I.ModalManager.CloseAll(opts.ModalOwner) end

        local maid = I.Maid.new()
        local finished = false
        local startMouse = UserInputService:GetMouseLocation()

        local function markMoved()
            if not moved then
                moved = true
                if useAttr then handle:SetAttribute("Dragging", true) end
            end
        end

        local function finish()
            if finished then return end
            finished = true
            if DragManager.Active == key then DragManager.Active = nil end
            if useAttr then
                task.defer(function()
                    if handle and handle.Parent then handle:SetAttribute("Dragging", nil) end
                end)
            end
            maid:Destroy()
            if opts.OnEnd then I.SafeCall(opts.OnEnd, moved) end
        end

        if opts.OnStart then I.SafeCall(opts.OnStart) end

        maid:Give(UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                finish()
            end
        end))
        if handle and handle.Destroying then
            maid:Give(handle.Destroying:Connect(finish))
        end
        maid:Give(RunService.Heartbeat:Connect(function()
            if not I.IsInputDown(inputType) then finish() end
        end))

        if type(opts.OnFrame) == "function" then
            maid:Give(RunService.RenderStepped:Connect(function()
                if finished then return end
                local mouse = UserInputService:GetMouseLocation()
                local dx, dy = mouse.X - startMouse.X, mouse.Y - startMouse.Y
                if threshold > 0 and not moved then
                    if math.abs(dx) + math.abs(dy) > threshold then markMoved() end
                    if not moved then return end
                end
                opts.OnFrame(mouse, dx, dy)
            end))
        end

        if type(opts.OnMove) == "function" then
            local function tryMove(pos)
                if threshold > 0 and not moved then
                    local dx, dy = pos.X - startMouse.X, pos.Y - startMouse.Y
                    if math.abs(dx) + math.abs(dy) <= threshold then return end
                    markMoved()
                end
                opts.OnMove(pos)
            end
            maid:Give(UserInputService.InputChanged:Connect(function(inp)
                if finished then return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch then
                    tryMove(inp.Position)
                end
            end))
            if threshold <= 0 then opts.OnMove(input.Position) end
        end

        return {
            Finish = finish,
            Maid = maid,
            IsMoved = function() return moved end,
        }
    end
    I.BeginDrag = BeginDrag

    local function MakeDraggable(handle, target, opts)
        opts = opts or {}
        local threshold = opts.Threshold or 6
        local maid = I.Maid.new()

        maid:Give(handle.InputBegan:Connect(function(input)
            if DragManager.Active ~= nil then return end
            local startPos
            BeginDrag(input, handle, {
                Threshold = threshold,
                ModalOwner = opts.ModalOwner,
                ManagerKey = target,
                OnStart = function()
                    if target.AnchorPoint.X ~= 0 or target.AnchorPoint.Y ~= 0 then
                        local s = I.GetScale()
                        target.AnchorPoint = Vector2.new(0, 0)
                        target.Position = UDim2.fromOffset(
                            target.AbsolutePosition.X / s, target.AbsolutePosition.Y / s)
                    end
                    if opts.OnStart then I.SafeCall(opts.OnStart, target) end
                    startPos = target.Position
                end,
                OnEnd = function(moved)
                    if moved and opts.OnEnd then I.SafeCall(opts.OnEnd) end
                end,
                OnFrame = function(_, dx, dy)
                    if not startPos then return end
                    local s = I.GetScale()
                    target.Position = UDim2.fromOffset(
                        startPos.X.Offset + dx / s, startPos.Y.Offset + dy / s)
                    if opts.Clamp then ClampToScreen(target) end
                end,
            })
        end))

        I.Once(handle.Destroying, function() maid:Destroy() end)
        return maid
    end
    I.MakeDraggable = MakeDraggable

    I.LibMaid:Give(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            task.defer(function()
                local ok, btns = pcall(UserInputService.GetMouseButtonsPressed, UserInputService)
                if ok and type(btns) == "table" and #btns == 0 then
                    DragManager.Active = nil
                end
            end)
        end
    end))
end
