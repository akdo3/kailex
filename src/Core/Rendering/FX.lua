return function(ctx)
    local I = ctx.Internal

    local FX = {}

    function FX.Shake(inst, dist)
        if not inst then return end
        if inst:GetAttribute("__shaking") then return end
        inst:SetAttribute("__shaking", true)
        task.delay(1, function()
            pcall(function() inst:SetAttribute("__shaking", nil) end)
        end)
        local orig, d = inst.Position, dist or 8
        local steps = { d, -d * 0.7, d * 0.35, 0 }
        local function run(i)
            if i > 1 and inst.Position ~= orig + UDim2.fromOffset(steps[i - 1], 0) then return end
            I.Tween(inst, i < #steps and "Fast" or "Snappy",
                { Position = orig + UDim2.fromOffset(steps[i], 0) },
                i < #steps and function() run(i + 1) end or nil)
        end
        run(1)
    end

    I.FX = FX
end
