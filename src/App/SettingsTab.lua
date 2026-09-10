return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting

    function Kailex:CreateSettingsTab(win)
        local tab = win:Tab({ Title = "Settings", Icon = "Gear" })

        tab:AddSection("Appearance")
        local themeDrop
        themeDrop = tab:AddDropdown({
            Name = "Theme",
            Options = Kailex:GetThemes(),
            Default = Setting.Theme,
            Callback = function(name)
                Setting.Theme = tostring(name)
                Kailex:SetTheme(Setting.Theme)
                I.SaveManager:Set("__theme", Setting.Theme)
            end,
        })
        tab:AddSlider({
            Name = "UI Scale",
            Min = 0.8, Max = 1.3, Default = tonumber(Setting.UIScale) or 1, Increment = 0.05,
            Callback = function(v)
                Setting.UIScale = v
                I.SaveManager:Set("__scale", v)
                I.UpdateViewport()
            end,
        })
        tab:AddSlider({
            Name = "Text Size",
            Min = 0.85, Max = 1.4, Default = tonumber(Setting.TextScale) or 1.1, Increment = 0.05,
            Callback = function(v)
                Setting.TextScale = v
                I.ApplyTextScale()
                I.SaveManager:Set("__textScale", v)
            end,
        })
        tab:AddSlider({
            Name = "Animation Speed",
            Min = 0.2, Max = 1, Default = tonumber(Setting.MotionScale) or 1, Increment = 0.05,
            Callback = function(v)
                Setting.MotionScale = v
                I.SaveManager:Set("__motion", v)
            end,
        })

        tab:AddSection("Behavior")
        tab:AddToggle({
            Name = "Interface Sounds",
            Description = "Click and hover sound effects",
            Default = Setting.Sounds == true,
            Callback = function(v)
                Setting.Sounds = v
                I.SaveManager:Set("__sounds", v)
            end,
        })
        tab:AddToggle({
            Name = "Visual Effects",
            Description = "Ripple effects on click",
            Default = Setting.Effects ~= false,
            Callback = function(v)
                Setting.Effects = v
                I.SaveManager:Set("__effects", v)
            end,
        })
        tab:AddToggle({
            Name = "Async Callbacks",
            Description = "Run callbacks in background threads",
            Default = Setting.AsyncCallbacks == true,
            Callback = function(v)
                Setting.AsyncCallbacks = v
                I.SaveManager:Set("__async", v)
            end,
        })
        local keybindEl = tab:AddKeybind({
            Name = "Show / Hide UI",
            Default = Setting.ToggleUIKey,
            Callback = function(code)
                Setting.ToggleUIKey = code
                I.SaveManager:Set("__toggleKey", code and ("Key:" .. tostring(code):match("%.(.+)$")) or "__none")
            end,
        })

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
                    Kailex:Notify({ Title = "Theme Editor", Text = "Enter a theme name first.", Type = "Warning" })
                    return
                end
                Kailex:RegisterTheme(n, editing.colors)
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
                Kailex:Notify({ Title = "Theme Editor", Text = "Edits reverted to \"" .. Setting.Theme .. "\"." })
            end,
        })

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
                    Kailex:Notify({ Title = "Profiles", Text = "Enter a profile name first.", Type = "Warning" })
                    return
                end
                I.SaveManager:Flush()
                if I.Configs:Save(n) then
                    refreshProfiles()
                    profDrop:Set(n, true)
                    Kailex:Notify({ Title = "Profiles", Text = "Saved \"" .. n .. "\".", Type = "Success" })
                else
                    Kailex:Notify({ Title = "Profiles", Text = "Saving files is not supported here.", Type = "Error" })
                end
            end,
        })
        tab:AddButton({
            Name = "Load profile",
            Callback = function()
                local n = profDrop:Get()
                if not n then return end
                if I.Configs:Load(n) then
                    Kailex:Notify({ Title = "Profiles", Text = "Loaded \"" .. n .. "\".", Type = "Success" })
                else
                    Kailex:Notify({ Title = "Profiles", Text = "Could not load that profile.", Type = "Error" })
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
                    Kailex:Notify({ Title = "Profiles", Text = "Deleted \"" .. n .. "\"." })
                end)
            end,
        })

        tab:AddSection("About")
        tab:AddParagraph({
            Title = "Kailex UI " .. Kailex.Version,
            Text = "Device: " .. (I.Device.IsTouch and "Mobile" or (I.Device.IsConsole and "Console" or "Desktop"))
                .. " | Files: " .. (I.HasFileSystem and "available" or "unavailable"),
        })
        tab:AddButton({
            Name = "Reset all settings",
            Callback = function()
                Kailex:Confirm({
                    Title = "Reset everything?",
                    Text = "All saved values and themes will be cleared. Re-execute the script after.",
                }, function()
                    I.SaveManager:Clear()
                    Kailex:Notify({ Title = "Settings", Text = "Cleared. Re-execute the script.", Type = "Success" })
                end)
            end,
        })
        return tab
    end
end
