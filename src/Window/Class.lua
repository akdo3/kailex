return function(ctx)
    local I = ctx.Internal

    local Window = {}
    Window.__index = Window

    I.WindowClass = Window
end
