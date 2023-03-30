-- shell.run("rm mixerInstaller.lua") shell.run("pastebin get dCSnwFwY mixerInstaller.lua") shell.run("mixerInstaller.lua")

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
    shell.run("rm mixerBoi.lua")
    shell.run("pastebin get 0UraU1AP mixerBoi.lua")
    shell.run("mixerBoi.lua")
elseif dt == "computer" then
    shell.run("rm mixerDude.lua")
    shell.run("pastebin get FV0GEAQv mixerDude.lua")
    shell.run("mixerDude.lua")
end