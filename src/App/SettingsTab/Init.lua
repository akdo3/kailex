return function(ctx)
    local I = ctx.Internal
    local Kailex = ctx.Kailex
    local Setting = I.Setting
    local Sections = I.SettingsSections

    local SLIDERS = {
        { Name = "UI Scale", Min = 0.8, Max = 1.3, Inc = 0.05, Fallback = 1,
            Key = "UIScale", Save = "__scale", After = function() I.UpdateViewport() end },
        { Name = "Text Size", Min = 0.85, Max = 1.4, Inc = 0.05, Fallback = 1.1,
            Key = "TextScale", Save = "__textScale", After = function() I.ApplyTextScale() end },
        { Name = "Animation Speed", Min = 0.2, Max = 1, Inc = 0.05, Fallback = 1,
            Key = "MotionScale", Save = "__motion" },
    }

    local TOGGLES = {
        { Name = "Interface Sounds", Desc = "Click and hover sound effects",
            Key = "Sounds", Save = "__sounds" },
        { Name = "Visual Effects", Desc = "Ripple effects on click",
            Key = "Effects", Save = "__effects" },
        { Name = "Async Callbacks", Desc = "Run callbacks in background threads",
            Key = "AsyncCallbacks", Save = "__async" },
    }

    function Kailex:CreateSettingsTab(win)
        local tab = win:Tab({ Title = "Settings", Icon = "Gear" })

        tab:AddSection("Appearance")
        local themeDrop = tab:AddDropdown({
            Name = "Theme",
            Options = Kailex:GetThemes(),
            Default = Setting.Theme,
            Callback = function(name)
                Setting.Theme = tostring(name)
                Kailex:SetTheme(Setting.Theme)
                I.SaveManager:Set("__theme", Setting.Theme)
            end,
        })
        for _, s in ipairs(SLIDERS) do
            tab:AddSlider({
                Name = s.Name, Min = s.Min, Max = s.Max, Increment = s.Inc,
                Default = tonumber(Setting[s.Key]) or s.Fallback,
                Callback = function(v)
                    Setting[s.Key] = v
                    I.SaveManager:Set(s.Save, v)
                    if s.After then s.After() end
                end,
            })
        end

        tab:AddSection("Behavior")
        for _, t in ipairs(TOGGLES) do
            tab:AddToggle({
                Name = t.Name, Description = t.Desc,
                Default = Setting[t.Key] == true,
                Callback = function(v)
                    Setting[t.Key] = v
                    I.SaveManager:Set(t.Save, v)
                end,
            })
        end
        tab:AddToggle({
            Name = "Auto-Save",
            Description = "Write settings to disk automatically",
            Default = Setting.AutoSave ~= false,
            Callback = function(v)
                Setting.AutoSave = v
                I.SaveManager:Flush()
            end,
        })
        tab:AddSlider({
            Name = "Sound Volume",
            Min = 0, Max = 1, Increment = 0.05,
            Default = tonumber(Kailex.Audio.Master) or 1,
            Callback = function(v)
                Kailex.Audio.Master = v
                I.SaveManager:Set("__volume", v)
            end,
        })
        tab:AddKeybind({
            Name = "Show / Hide UI",
            Default = Setting.ToggleUIKey,
            Callback = function(code)
                Setting.ToggleUIKey = code
                I.SaveManager:Set("__toggleKey", code and ("Key:" .. code.Name) or "__none")
            end,
        })

        Sections.themeEditor(tab, themeDrop)
        Sections.profiles(tab)

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
                    I.Note("Settings", "Cleared. Re-execute the script.", "Success")
                end)
            end,
        })
        return tab
    end
end
