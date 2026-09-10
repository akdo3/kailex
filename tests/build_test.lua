os.execute("lua build.lua")

local f = io.open("dist/Kailex.lua", "r")
if not f then
    print("FAIL: dist/Kailex.lua not found")
    os.exit(1)
end
local content = f:read("*a")
f:close()

if #content < 1000 then
    print("FAIL: bundle too small (" .. #content .. " bytes)")
    os.exit(1)
end

if not content:find("Bundle.__order") then
    print("FAIL: LoadOrder not embedded")
    os.exit(1)
end

if not content:find("Elements/Dropdown") then
    print("FAIL: Dropdown module missing")
    os.exit(1)
end

local count = select(2, content:gsub("Bundle%[", ""))
if count < 48 then
    print("FAIL: expected 48 modules, found " .. count)
    os.exit(1)
end

print("PASS: " .. #content .. " bytes, " .. count .. " modules")
