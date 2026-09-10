return function(ctx)
    local I = ctx.Internal

    local FX = {}

    function FX.Shake(inst, dist)
        if not inst then return end
        local orig = inst.Position
        local d = dist or 8
        I.Tween(inst, "Fast", { Position = orig + UDim2.fromOffset(d, 0) }, function()
            I.Tween(inst, "Fast", { Position = orig + UDim2.fromOffset(-d * 0.7, 0) }, function()
                I.Tween(inst, "Fast", { Position = orig + UDim2.fromOffset(d * 0.35, 0) }, function()
                    I.Tween(inst, "Snappy", { Position = orig })
                end)
            end)
        end)
    end

    I.FX = FX
end
