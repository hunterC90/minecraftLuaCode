-- pastebin 6x0B3PVu
-- Script for loading APIs
-- This script will be updated with new apis as I make new ones
-- Another script will have to be called to get this from pastebin and run it
local forceLoad = ...

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

local APIs_all = {
    ["storage.lua"] = "https://raw.githubusercontent.com/hunterC90/minecraftLuaCode/main/CC/APIs/storage.lua?token=GHSAT0AAAAAAB7V2JHNWT7MNJ6AT2XQ5BSMZBE55AQ"
}

local APIs_turtle = {
    ["home.lua"] = "https://raw.githubusercontent.com/hunterC90/minecraftLuaCode/main/CC/APIs/setHome.lua?token=GHSAT0AAAAAAB7V2JHMYZNHXI4LXNRAP7LEZBE55AA",
    ["egps"] = "https://raw.githubusercontent.com/hunterC90/minecraftLuaCode/main/CC/APIs/egps.lua?token=GHSAT0AAAAAAB7V2JHNFLWD76RQQ7F5BMSKZBE546Q",
    ["robot.lua"] = "https://raw.githubusercontent.com/hunterC90/minecraftLuaCode/main/CC/APIs/robot.lua?token=GHSAT0AAAAAAB7V2JHMRRXOYKWXGORIAMS2ZBE547A"
}

local APIs_computer = {

}

local APIs_pocket = {

}

if forceLoad == "force"  or forceLoad == "f" then 
    shell.run("rm " .. "APIs/")
end

APIs = APIs_all
if dt == "turtle" then
    print("Turtle detected")
    for k, v in pairs(APIs_turtle) do APIs[k] = v end
elseif dt == "pocket" then
    print("Pocket computer detected")
    for k, v in pairs(APIs_computer) do APIs[k] = v end
elseif dt == "computer" then
    print("Computer detected")
    for k, v in pairs(APIs_pocket) do APIs[k] = v end
end

for k,v in pairs(APIs) do

    local f = io.open("APIs/" .. k, "r")
    if f == nil then
        shell.run("wget " .. v .. " APIs/" .. k)
    end
    io.close(f)
end

for k,v in pairs(APIs) do
    pcall(function()
        os.loadAPI("APIs/" .. k)
    end)
end

-- Any files to be included that aren't APIs
local localFiles_all = {
    
}

local localFiles_turtle = {
    ["home.lua"] = "https://raw.githubusercontent.com/hunterC90/minecraftLuaCode/main/CC/home.lua?token=GHSAT0AAAAAAB7V2JHMLJYH6MNXG5V6U764ZBE55YQ"
}

local localFiles_computer = {

}

local localFiles_pocket = {

}

localFiles = localFiles_all
if dt == "turtle" then
    for k, v in pairs(localFiles_turtle) do localFiles[k] = v end
elseif dt == "pocket" then
    for k, v in pairs(localFiles_computer) do localFiles[k] = v end
elseif dt == "computer" then
    for k, v in pairs(localFiles_pocket) do localFiles[k] = v end
end

for k,v in pairs(localFiles) do
    if forceLoad == "force"  or forceLoad == "f" then 
        shell.run("rm " .. k)
    end

    local f = io.open(k, "r")
    if f == nil then
        shell.run("wget " .. v .. " " .. k)
    end
    io.close(f)
end
