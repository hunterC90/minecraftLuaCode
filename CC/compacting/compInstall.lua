-- shell.run("rm compInstaller.lua") shell.run("pastebin get iBFt18yH compInstaller.lua") shell.run("compInstaller.lua")
local function getDeviceType()
    if turtle then
        return "turtle"
    elseif pocket then
        return "pocket"
    elseif commands then
        return "command_computer"
    else
        return "computer"
    end
end
local dt = getDeviceType()

-- Get new loadAPIs.lua
shell.run("rm loadAPIs.lua")
shell.run("pastebin get 6x0B3PVu loadAPIs.lua")
shell.run("loadAPIs.lua")

if dt == "turtle" then
    shell.run("rm compBoi.lua")
    shell.run("pastebin get fvRmthSP compBoi.lua")
    shell.run("compBoi.lua")
elseif dt == "computer" then
    shell.run("rm compDude.lua")
    shell.run("pastebin get m2mp7RLX compDude.lua")
    shell.run("compDude.lua")
end