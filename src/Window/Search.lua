return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local Search = {}

    function Search.build(self)
        local searchBox = self._searchBox
        local searchLine = self._searchLine
        local searchDebounce = nil
        self._searchActive = false
        searchBox.ClipsDescendants = true

        local function setSearch(on)
            if self._searchActive == on then return end
            self._searchActive = on
            if on then
                searchBox.Visible = true
                searchLine.Visible = true
                self.TitleLabel.Visible = false
                self.SubLabel.Visible = false
                searchBox.Text = ""
                self._filterQuery = ""
                self:ApplyFilter("")
                searchBox.Size = UDim2.new(0, 0, 0, 24)
                searchLine.Size = UDim2.new(0, 0, 0, 1)
                I.Tween(searchBox, "Snappy", { Size = UDim2.new(0, 220, 0, 24) }, function()
                    if self._searchActive then pcall(function() searchBox:CaptureFocus() end) end
                end)
                I.Tween(searchLine, "Snappy", { Size = UDim2.new(0, 220, 0, 1) })
            else
                pcall(function() searchBox:ReleaseFocus() end)
                I.Tween(searchBox, "Fast", { Size = UDim2.new(0, 0, 0, 24) }, function()
                    if not self._searchActive then
                        searchBox.Visible = false
                        searchLine.Visible = false
                        self.TitleLabel.Visible = true
                        self.SubLabel.Visible = true
                    end
                end)
                I.Tween(searchLine, "Fast", { Size = UDim2.new(0, 0, 0, 1) })
                self._filterQuery = ""
                self:ApplyFilter("")
            end
        end

        self._setSearch = function(_, on) setSearch(on) end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = searchBox.Text
            if searchDebounce then pcall(task.cancel, searchDebounce) end
            if text == "" then
                self._filterQuery = ""
                self:ApplyFilter("")
                return
            end
            searchDebounce = task.delay(0.15, function()
                self._filterQuery = text
                self:ApplyFilter(text)
            end)
        end)

        searchBox.FocusLost:Connect(function(enter)
            if not enter and searchBox.Text == "" then setSearch(false) end
        end)

        self.Maid:Give(UserInputService.InputBegan:Connect(function(input, gp)
            if not self._searchActive then return end
            if input.KeyCode ~= Enum.KeyCode.Escape then return end
            if #I.ModalManager.Stack > 0 then return end
            if gp and UserInputService:GetFocusedTextBox() ~= searchBox then return end
            setSearch(false)
        end))
    end

    I.WindowSearch = Search
end
