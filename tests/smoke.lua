local Kailex = require(game:GetService("ReplicatedStorage"):WaitForChild("Kailex"))

local win = Kailex:CreateWindow({ Title = "Smoke Test", SubTitle = "auto" })
local tab = win:Tab({ Title = "T" })

local els = {
    tab:AddLabel({ Text = "label" }),
    tab:AddParagraph({ Title = "par", Text = "text" }),
    tab:AddDivider(),
    tab:AddSection("sec"),
    tab:AddButton({ Name = "btn" }),
    tab:AddToggle({ Name = "tgl" }),
    tab:AddSlider({ Name = "sld", Min = 0, Max = 10 }),
    tab:AddKeybind({ Name = "kbd" }),
    tab:AddDropdown({ Name = "dpd", Options = { "a", "b" } }),
    tab:AddTextInput({ Name = "txt" }),
    tab:AddColorPicker({ Name = "col" }),
    tab:AddProgressBar({ Name = "pgb" }),
    tab:AddStepper({ Name = "ste" }),
    tab:AddSegmented({ Name = "seg", Options = { "x", "y" } }),
    tab:AddVector3Input({ Name = "vec" }),
}

local failures = 0
for i, el in ipairs(els) do
    if not el then
        print("FAIL: element " .. i .. " is nil")
        failures += 1
    elseif not el.Row then
        print("FAIL: element " .. i .. " has no Row")
        failures += 1
    end
end

local row = tab:AddRow(2)
row:AddButton({ Name = "g1" })
row:AddToggle({ Name = "g2" })

Kailex:Notify({ Title = "passed" })
Kailex:CreateSettingsTab(win)

if failures > 0 then
    print("SMOKE TEST FAILED: " .. failures .. " failures")
else
    print("SMOKE TEST PASSED: " .. #els .. " elements + grid + settings")
end
