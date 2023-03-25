-- Script for loading APIs
-- This script will be updated with new apis as I make new ones
-- Another script will have to be called to get this from pastebin and run it
local forceLoad = ...

local APIs = {
    ["storage.lua"] = "3MzNhUv4",
    ["home.lua"] = "ad7iiybK",
    ["egps"] = "9x7wXGBm",
    ["robot.lua"] = "n26GUHfJ"
}

if forceLoad == "force"  or forceLoad == "f" then 
    shell.run("rm " .. "APIs/")
end

for k,v in pairs(APIs) do
    local f = io.open("APIs/" .. k, "r")
    if f == nil then
        shell.run("pastebin get " .. v .. " APIs/" .. k)
    end
    io.close(f)
end

for k,v in pairs(APIs) do
    pcall(function()
        os.loadAPI("APIs/" .. k)
    end)
end

-- Any files to be included that aren't APIs
local localFiles = {
    ["home.lua"] = "KmGB4sne"
}



for k,v in pairs(localFiles) do
    if forceLoad == "force"  or forceLoad == "f" then 
        shell.run("rm " .. k)
    end

    local f = io.open(k, "r")
    if f == nil then
        shell.run("pastebin get " .. v .. " " .. k)
    end
    io.close(f)
end
