return function(ctx)
    local I = ctx.Internal
    local UserInputService = I.UserInputService

    local Elements = {}
    I.Elements = Elements

    local Element = {}
    Element.__index = Element
    I.Element = Element

    local function MkRow(self, tab, opts, name, rightW, height, width)
        local cfg = {
            Name = opts.Name or name, RightWidth = rightW, Width = opts.Width,
            Description = opts.Description,
        }
        if height then cfg.Height = height end
        local row, title, right, left = I.CreateRow(tab.Content, cfg)
        self:_init(row, opts, tab)
        self:_initRow(title, right, left, rightW, width)
        return row, title, right, left
    end

    local removeFrom = I.RemoveFrom

    function Element:_init(row, opts, tab)
        opts = opts or {}
        self._opts = opts
        self.Row = row
        self.Maid = I.Maid.new()
        self.Maid:Link(row)
        self.Tab = tab
        self.Title = tostring(opts.Name or opts.Title or "Element")
        self._searchExtra = tostring(opts.Search or opts.Tooltip or opts.Description or "")
        self.SearchText = (self.Title .. " " .. self._searchExtra):lower()
        self._destroyed = false
        self._extras = {}
        self._manualVisible = true
        self._disabled = false
        self._tooltip = { Text = opts.Tooltip }
        if opts.Tooltip then I.AddTooltip(row, self._tooltip) end
        local desc = row:FindFirstChild("__desc", true)
        if desc then self._descLabel = desc end
        if tab then
            table.insert(tab.Elements, self)
            if tab.CurrentSection then
                table.insert(tab.CurrentSection.Elements, self)
                self.Section = tab.CurrentSection
                if tab.CurrentSection.Collapsed then
                    row.Visible = false
                end
            end
        end
        return self
    end

    function Element:_bindSaveReload(saveKey, fn)
        if not saveKey then return end
        local reg = I.SaveReloadRegistry
        if not reg then return end
        local list = reg[saveKey]
        if not list then list = {} reg[saveKey] = list end
        table.insert(list, fn)
        self.Maid:Give(function()
            removeFrom(list, fn)
        end)
    end

    function Element:_initialCallback(cond, value)
        if not cond then return end
        task.defer(function()
            if not self._destroyed then I.RunCallback(self.Callback, self.Title, value) end
        end)
    end

    function Element:SetTitle(text)
        if self._destroyed then return end
        self.Title = tostring(text or "")
        self.SearchText = (self.Title .. " " .. self._searchExtra):lower()
        if self.TitleLabel and self.TitleLabel.Parent then self.TitleLabel.Text = self.Title end
    end

    function Element:SetTooltip(text)
        if self._destroyed then return end
        self._tooltip.Text = tostring(text or "")
    end

    function Element:SetDescription(text)
        if self._destroyed then return end
        if self._descLabel then self._descLabel.Text = tostring(text or "") end
    end

    function Element:Visible(state)
        if self._destroyed then return end
        if state == nil then
            self.Row.Visible = not self.Row.Visible
        else
            self.Row.Visible = state and true or false
        end
        self._manualVisible = self.Row.Visible
        if self.Section and self.Section.Collapsed then
            self.Row.Visible = false
        end
    end

    function Element:SetDisabled(state)
        if self._destroyed then return end
        local v = state == true
        if v == self._disabled then return end
        self._disabled = v
        if self.Row then self.Row:SetAttribute("Disabled", v) end
        if self.TitleLabel then I.Tween(self.TitleLabel, "Fast", { TextTransparency = v and 0.55 or 0 }) end
        local st = self.Row and self.Row:FindFirstChildOfClass("UIStroke")
        if st then I.Tween(st, "Fast", { Transparency = v and 0.9 or 0.65 }) end
    end

    function Element:IsDisabled()
        return self._disabled == true
    end

    function Element:RecalcWidth()
        if not self.RightContainer then return end
        local w = (self._baseRightW or 0) + (self._extraW or 0)
        self.RightContainer.Size = UDim2.new(0, w, 1, -4)
        if self.LeftFrame then
            self.LeftFrame.Size = UDim2.new(1, -w, 1, 0)
        end
    end

    function Element:_contextItems()
        local items = {}
        if self.CopyValue then
            table.insert(items, { Text = "Copy value", Callback = function()
                local v = self:CopyValue()
                if v ~= nil then I.CopyToClipboard(v) end
            end })
        end
        if self.Reset then
            table.insert(items, { Text = "Reset to default", Callback = function() self:Reset() end })
        end
        table.insert(items, {
            Text = self._disabled and "Enable" or "Disable",
            Callback = function() self:SetDisabled(not self._disabled) end,
        })
        return items
    end

    local function HookContextMenu(el, overlay, alive)
        local function open()
            local items = el:_contextItems()
            if #items == 0 then return false end
            local m = UserInputService:GetMouseLocation()
            I.ContextMenu.Show(items, m.X, m.Y)
        end
        I.OnLongPress(overlay, alive or function() return not el._destroyed end, open)
    end
    I.HookContextMenu = HookContextMenu

    function Element:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if I.HotElement == self then I.HotElement = nil end
        local tab = self.Tab
        if tab then
            removeFrom(tab.Elements, self)
            if self.Section then
                removeFrom(self.Section.Elements, self)
            end
        end
        for _, ex in ipairs(self._extras) do
            if not ex._destroyed then ex:Destroy() end
        end
        if self.Changed then self.Changed:Destroy() end
        if self.Maid then self.Maid:Destroy() end
        if self.Row then self.Row:Destroy() end
        self.Row, self.Maid, self.Tab, self.Section = nil, nil, nil, nil
    end

    function Element:_initRow(title, right, left, baseW, width)
        self.TitleLabel = title
        self.LeftFrame = left
        self.RightContainer = right
        self._baseRightW = baseW
        self._width = width or baseW
    end

    local function MakeElementClass()
        local class = {}
        class.__index = class
        setmetatable(class, { __index = Element })
        return class
    end
    I.MakeElementClass = MakeElementClass
    I.MkRow = MkRow
end
