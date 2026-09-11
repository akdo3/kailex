return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    local Sections = {}

    function Sections.themeEditor(tab, themeDrop)
        tab:AddSection({ Name = "Theme Editor", Columns = 2 })
        local editing = { colors = table.clone(I.Themes[Setting.Theme] or I.Themes.Nocturne) }
        local pickers = {}

        for _, key in ipairs(I.ThemeKeys) do
            local cp = tab:AddColorPicker({
                Name = key,
                Default = editing.colors[key],
                Callback = function(c)
                    editing.colors[key] = c
                    I.ApplyTheme(editing.colors)
                end,
            })
            cp.ThemeKey = key
            table.insert(pickers, cp)
        end

        local themeNameInput = tab:AddTextInput({
            Name = "Theme name",
            Placeholder = "e.g. Midnight Ocean",
            Span = 2,
        })

        tab:AddButton({
            Name = "Save Theme",
            Callback = function()
                local n = themeNameInput:Get()
                if n == "" then
                    I.Note("Theme Editor", "Enter a theme name first.", "Warning")
                    return
                end
                if not Kailex:RegisterTheme(n, editing.colors) then
                    I.Note("Theme Editor", "Built-in theme names cannot be overwritten.", "Warning")
                    return
                end
                Kailex:SaveCustomThemes()
                Setting.Theme = n
                I.SaveManager:Set("__theme", n)
                I.ApplyTheme(I.Themes[n])
                themeDrop:SetOptions(Kailex:GetThemes())
                themeDrop:Set(n, true)
                Kailex:Notify({ Title = "Theme Editor", Text = "Theme \"" .. n .. "\" saved & applied.", Type = "Success" })
            end,
        })

        tab:AddButton({
            Name = "Discard Edits",
            Callback = function()
                editing.colors = table.clone(I.Themes[Setting.Theme] or I.Themes.Nocturne)
                for _, cp in ipairs(pickers) do
                    cp:Set(editing.colors[cp.ThemeKey], true)
                end
                I.ApplyTheme(editing.colors)
                I.Note("Theme Editor", "Edits reverted to \"" .. Setting.Theme .. "\".")
            end,
        })

        tab:AddButton({
            Name = "Export Theme",
            Description = "Copy the current edits as JSON",
            Callback = function()
                local out = {}
                for _, key in ipairs(I.ThemeKeys) do
                    out[key] = I.ColorToHex(editing.colors[key])
                end
                I.CopyToClipboard(I.HttpService:JSONEncode(out))
            end,
        })

        tab:AddButton({
            Name = "Import Theme",
            Description = "Load a theme JSON from the clipboard",
            Callback = function()
                local raw = I.ReadClipboard()
                if not raw then
                    I.Note("Theme Editor", "Clipboard is not available on this executor.", "Error")
                    return
                end
                local data = nil
                if raw ~= "" then
                    local okDecode, decoded = pcall(I.HttpService.JSONDecode, I.HttpService, raw)
                    if okDecode and type(decoded) == "table" then data = decoded end
                end
                if not data then
                    I.Note("Theme Editor", "Clipboard does not contain a valid theme.", "Warning")
                    return
                end
                for _, key in ipairs(I.ThemeKeys) do
                    local v = data[key]
                    if type(v) == "string" then
                        local c = I.HexToColor(v)
                        if c then editing.colors[key] = c end
                    end
                end
                for _, cp in ipairs(pickers) do
                    cp:Set(editing.colors[cp.ThemeKey], true)
                end
                I.ApplyTheme(editing.colors)
                I.Note("Theme Editor", "Theme imported from clipboard.", "Success")
            end,
        })
    end

    function Sections.profiles(tab)
        tab:AddSection("Profiles")
        local nameInput = tab:AddTextInput({ Name = "Profile name", Placeholder = "My config" })
        local profDrop = tab:AddDropdown({ Name = "Profile", Options = I.Configs:List() })
        local function refreshProfiles()
            profDrop:SetOptions(I.Configs:List())
        end

        tab:AddButton({
            Name = "Save profile",
            Callback = function()
                local n = nameInput:Get()
                if n == "" then
                    I.Note("Profiles", "Enter a profile name first.", "Warning")
                    return
                end
                I.SaveManager:Flush()
                if I.Configs:Save(n) then
                    refreshProfiles()
                    profDrop:Set(n, true)
                    I.Note("Profiles", "Saved \"" .. n .. "\".", "Success")
                else
                    I.Note("Profiles", "Saving files is not supported here.", "Error")
                end
            end,
        })

        tab:AddButton({
            Name = "Load profile",
            Callback = function()
                local n = profDrop:Get()
                if not n then return end
                if I.Configs:Load(n) then
                    I.Note("Profiles", "Loaded \"" .. n .. "\".", "Success")
                else
                    I.Note("Profiles", "Could not load that profile.", "Error")
                end
            end,
        })

        tab:AddButton({
            Name = "Delete profile",
            Callback = function()
                local n = profDrop:Get()
                if not n then return end
                Kailex:Confirm({
                    Title = "Delete profile?",
                    Text = "This permanently removes \"" .. n .. "\".",
                }, function()
                    I.Configs:Delete(n)
                    refreshProfiles()
                    I.Note("Profiles", "Deleted \"" .. n .. "\".")
                end)
            end,
        })
    end

    I.SettingsSections = Sections
end
