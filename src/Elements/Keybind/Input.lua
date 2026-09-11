return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local dispatcher = nil
    local function ensureDispatcher()
        if dispatcher then return end
        dispatcher = I.AddInputHook(function() return #I.KeybindRegistry > 0 end, function(input, gp)
            local regs = table.clone(I.KeybindRegistry)
            for i = 1, #regs do
                local el = regs[i] and regs[i].el
                if el and not el._destroyed and el._handleInput then
                    local ok, err = pcall(el._handleInput, input, gp)
                    if not ok then warn("[Kailex] " .. tostring(err)) end
                end
            end
        end)
        I.LibMaid:Give(function() I.RemoveInputHook(dispatcher) end)
    end

    local function matches(S, input, excludeMB1)
        local b = S.binding
        if b.Kind == "Key" then return input.KeyCode == b.Code end
        return b.Kind == "Mouse" and input.UserInputType == b.Code
            and not (excludeMB1 and input.UserInputType == Enum.UserInputType.MouseButton1)
    end

    local function Wire(S)
        local self, opts = S.self, S.opts

        S.handleInput = function(input, gp)
            if self._destroyed then return end
            if S.listening then
                if input.KeyCode == Enum.KeyCode.Escape then
                    S.listenToken += 1
                    S.setListening(false)
                    return
                end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    if gp then return end
                    S.listenToken += 1
                    S.setListening(false)
                    S.setBinding({
                        Kind = "Key",
                        Code = input.KeyCode,
                        Name = input.KeyCode.Name,
                    })
                    I.PlaySound("Click")
                elseif opts.MouseButtons
                    and (input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3) then
                    S.listenToken += 1
                    S.setListening(false)
                    S.setBinding({
                        Kind = "Mouse",
                        Code = input.UserInputType,
                        Name = input.UserInputType.Name,
                    })
                    I.PlaySound("Click")
                end
                return
            end
            if I.ActiveKeybindListener ~= nil then return end
            if gp then return end
            if self._disabled then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            if not S.binding then return end
            if not matches(S, input, true) then return end
            if S.mode == "toggle" then
                S.toggleState = not S.toggleState
                self._toggleState = S.toggleState
                I.RunCallback(self.Callback, self.Title, S.binding.Code, S.toggleState)
            elseif S.mode == "hold" then
                self._holding = true
                I.RunCallback(self.Callback, self.Title, S.binding.Code, true)
            else
                I.RunCallback(self.Callback, self.Title, S.binding.Code)
            end
        end
        self._handleInput = S.handleInput

        if S.mode == "hold" then
            self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
                if self._destroyed or self._holding ~= true then return end
                if not S.binding then return end
                if matches(S, input) then
                    self._holding = false
                    I.RunCallback(self.Callback, self.Title, S.binding.Code, false)
                end
            end))
        end

        ensureDispatcher()
    end

    I.WireKeybind = Wire
end
