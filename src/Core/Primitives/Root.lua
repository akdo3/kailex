return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex

    Kailex.Setting = {
        Theme          = "Nocturne",
        Sounds         = false,
        AutoSave       = true,
        UIScale        = 1,
        TextScale      = 1.1,
        ToggleUIKey    = Enum.KeyCode.RightShift,
        SaveFolder     = "KailexUI",
        Effects        = true,
        MotionScale    = 1,
        RTL            = false,
        AsyncCallbacks = false,
    }
    Kailex.ThemeChanged = I.Signal.new()

    local LibMaid = I.Maid.new()
    Kailex._libMaid = LibMaid

    I.Setting = Kailex.Setting
    I.LibMaid = LibMaid
end
