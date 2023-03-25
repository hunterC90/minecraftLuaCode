local f

-- I have to do this nonsense so that VSCode knows about storage.lua
pcall(function()
    robot = require("robot.lua")
end)

-- function set a home with name
-- will overwrite any home with the same name
-- homes are stored on home.txt in the main directory
function set(name, x, y, z, d)
    f = io.open("homes.txt", "r")

    if name == nil then
        name = "home"
    end

    local r = robot.getPos()
    if z == nil then
        d = robot.getDir()
        x = r.x
        y = r.y
        z = r.z
    end

    if f == nil then
        f = io.open("homes.txt", "w")
    else
        -- removes the home if it already exists to be replaced with new one
        f:close()
        remove(name)
        f = io.open("homes.txt", "a")
    end

    local fs = ""
    if d ~= nil then
        fs = name .. "," .. x .. "," .. y .. "," .. z .. "," .. d .. "\n"
    else
        fs = name .. "," .. x .. "," .. y .. "," .. z .. "\n"
    end

    if f ~= nil then
        f:write(fs)
        f:close()
    end
end

-- function get the coordinates for the home with the name
-- return nil if there is no home of that name
function get(name)
    local parts = {}

    if name == nil then
        name = "home"
    end

    -- if the file doens't exist return falses
    f = io.open("homes.txt", "r")
    if f == nil then
        return false
    end

    -- Read the file line by line and add each line to the table
    for line in f:lines() do
        parts = {}
        -- Match each part separated by a comma and add it to the table
        for part in line:gmatch("[^,]+") do
            table.insert(parts, part)
        end

        if parts[1] == name then
            f:close()
            return parts[2],parts[3],parts[4],parts[5]
        end
    end
    f:close()
    return nil
end

-- function removes a home with given name
-- return true if successful, false is not
function remove(name)
    local parts = {}
    local fs = ""
    local rmFlag = false

    if name == nil then
        name = "home"
    end

    -- if the file doens't exist return falses
    local f = io.open("homes.txt", "r")
    if f == nil then
        return rmFlag
    end

    -- Read the file line by line and add each line to the table
    for line in f:lines() do
        parts = {}
        -- Match each part separated by a comma and add it to the table
        for part in line:gmatch("[^,]+") do
            table.insert(parts, part)
        end

        if parts[1] ~= name then
            fs = fs .. line .. "\n"
        else
            rmFlag = true
        end
    end
    f:close()
    f = io.open("homes.txt", "w")

    -- not needed but the IDE gets mad if I don't do this
    if f ~= nil then
        f:write(fs)
        f:close()
    end

    return rmFlag
end

-- function returns array of all home names
-- if there are no homes returns nil
function list()
    local homes = {}

    -- if the file doens't exist return falses
    local f = io.open("homes.txt", "r")
    if f == nil then
        return nil
    end

    -- Read the file line by line and add each line to the table
    local i = 1
    for line in f:lines() do
        parts = {}
        -- Match each part separated by a comma and add it to the table
        for part in line:gmatch("[^,]+") do
            table.insert(parts, part)
        end

        homes[i] = parts[1]
        i = i + 1
    end

    if next(homes) == nil then
        return nil
    else
        return homes
    end
end