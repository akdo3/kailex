return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting
    local Workspace = I.Workspace

    local ScreenGui = I.Create("ScreenGui", {
        Name = "KailexUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })
    Kailex.CurrentScreenGui = ScreenGui
    pcall(I.protect_gui, ScreenGui)
    ScreenGui.Parent = I.SafeParent

    local LayerWindows = I.Create("Frame", { Name = "Windows", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = ScreenGui })
    local LayerOverlay = I.Create("Frame", { Name = "Overlay",  BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = ScreenGui })
    local LayerNotify  = I.Create("Frame", { Name = "Notify",   BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = ScreenGui })
    local LayerTooltip = I.Create("Frame", { Name = "Tooltip",  BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = ScreenGui })
    local LayerPersistent = I.Create("Frame", { Name = "Persistent", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = ScreenGui })
    I.LayerPersistent = LayerPersistent

    local RootScale = I.Create("UIScale", { Parent = ScreenGui })
    local Camera = nil
    I.Viewport = Vector2.new(1920, 1080)

    local ViewportHooks = {}
    I.ViewportHooks = ViewportHooks

    local function GetScale()
        return RootScale and RootScale.Scale or 1
    end

    local function UpdateViewport()
        if not Camera then return end
        I.Viewport = Camera.ViewportSize
        local short = math.min(I.Viewport.X, I.Viewport.Y)
        local s = math.clamp(short / 880, 0.85, 1.1)
        if I.Device.IsTouch then s = math.max(s, 1) end
        RootScale.Scale = s * (tonumber(Setting.UIScale) or 1)
        for _, win in ipairs(Kailex.Windows) do
            if not win._destroyed then pcall(function() win:OnViewport() end) end
        end
        for _, fn in ipairs(ViewportHooks) do pcall(fn) end
    end

    local CameraConn = nil
    local function BindCamera(cam)
        if cam == Camera then return end
        if CameraConn then CameraConn:Disconnect() CameraConn = nil end
        Camera = cam
        if cam then
            CameraConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateViewport)
            UpdateViewport()
        end
    end
    BindCamera(Workspace.CurrentCamera)
    I.LibMaid:Give(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        BindCamera(Workspace.CurrentCamera)
    end))
    I.LibMaid:Give(function()
        if CameraConn then CameraConn:Disconnect() end
    end)

    I.ScreenGui = ScreenGui
    I.LayerWindows = LayerWindows
    I.LayerOverlay = LayerOverlay
    I.LayerNotify = LayerNotify
    I.LayerTooltip = LayerTooltip
    I.ToggleLayers = { LayerWindows, LayerOverlay, LayerNotify, LayerTooltip }
    I.GetScale = GetScale
    I.UpdateViewport = UpdateViewport
end
