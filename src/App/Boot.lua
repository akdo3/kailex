return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local UserInputService = I.UserInputService
    local genv = I.Getgenv()
    local unloaded = false

    function Kailex:Unload()
        if unloaded then return end
        unloaded = true
        pcall(function() I.SaveManager:Flush() end)
        I.ModalManager.CloseAll()
        pcall(function() I.ContextMenu.Hide() end)
        for el in pairs(I.QuickWidgets.Active) do
            pcall(I.QuickWidgets.Destroy, el)
        end
        for i = #Kailex.Windows, 1, -1 do
            local w = Kailex.Windows[i]
            if w and w.Destroy then pcall(w.Destroy, w) end
        end
        pcall(function() I.Tooltip.Hide() end)
        I.HotElement = nil
        I.ActiveKeybindListener = nil
        I.LibMaid:Destroy()
        pcall(function() I.ScreenGui:Destroy() end)
        if genv and genv.kailex == Kailex then genv.kailex = nil end
    end

    I.ApplyPersisted()
    if I.Device.IsConsole then
        I.Setting.UIScale = math.max(tonumber(I.Setting.UIScale) or 1, 1.15)
    end
    I.UpdateViewport()

    local bootHook = I.AddInputHook(function() return true end, function(input, gp)
        if input.KeyCode == Enum.KeyCode.Escape then
            if gp then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            if I.ActiveKeybindListener == nil and I.ModalManager.CloseTop() then
                return
            end
        end

        local code = input.KeyCode
        if code == Enum.KeyCode.Unknown then return end
        if I.ActiveKeybindListener ~= nil then return end
        if UserInputService:GetFocusedTextBox() ~= nil then return end

        if code == Enum.KeyCode.F
            and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            local w = Kailex._lastActive
            if not (w and not w._destroyed and not w._hidden
                and not w.Minimized and w._setSearch) then
                w = nil
                local best = -1
                for _, cw in ipairs(Kailex.Windows) do
                    if not cw._destroyed and not cw._hidden and not cw.Minimized
                        and cw._setSearch and cw.Root and cw.Root.ZIndex > best then
                        best = cw.Root.ZIndex
                        w = cw
                    end
                end
            end
            if w then w:_setSearch(true) end
            return
        end

        if gp then return end

        local key = I.Setting.ToggleUIKey
        if key ~= nil and code == key then
            Kailex:SetVisible(not Kailex:IsVisible())
            return
        end
        for _, w in ipairs(Kailex.Windows) do
            if not w._destroyed and w.ToggleKey == code then
                w:ToggleHidden()
                return
            end
        end

        local el = I.HotElement
        if el and not el._destroyed and not el._disabled and el.HandleArrow then
            local dir
            if code == Enum.KeyCode.Left or code == Enum.KeyCode.Down then dir = -1
            elseif code == Enum.KeyCode.Right or code == Enum.KeyCode.Up then dir = 1 end
            if dir then el:HandleArrow(dir) end
        end
    end)
    I.LibMaid:Give(function() I.RemoveInputHook(bootHook) end)

    if I.Device.IsTouch then
        Kailex:CreateMobileButton()
    end

    I.LibMaid:Give(I.ScreenGui.Destroying:Connect(function()
        I.LibMaid:Destroy()
    end))

    if genv then genv.kailex = Kailex end
end
