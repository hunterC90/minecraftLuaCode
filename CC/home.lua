local command, name, x, y, z, d = ...

-- I have to do this so the IDE knows about the API
pcall(function() 
    home = require("APIs/home.lua")
end)

x = tonumber(x)
y = tonumber(y)
z = tonumber(z)
d = tonumber(d)

if command == "set" then
    print(home.set(name, x, y, z, d))
elseif command == "get" then
    print(home.get(name))
elseif command == "list" then
    local homeList = home.list()
    for i = 1, #homeList do
        print(homeList[i])
    end
elseif command == "remove" then
    print(home.remove(name))
else
    print("Command not found")
end