return function(ctx)
    local I = ctx.Internal
    local Window = I.WindowClass

    function Window:SavePlacement()
        if self._destroyed or self.Minimized or self._hidden then return end
        if not self._remember then return end
        I.SaveManager:Set("__win:" .. self.SavePrefix, {
            X = math.floor(self.Root.Position.X.Offset + 0.5),
            Y = math.floor(self.Root.Position.Y.Offset + 0.5),
            W = math.floor(self.Root.Size.X.Offset + 0.5),
            H = math.floor(self.Root.Size.Y.Offset + 0.5),
        })
    end
end
