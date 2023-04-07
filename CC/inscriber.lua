os.loadAPI("APIs/storage.lua")

-- I have to do this nonsense so that VSCode knows about storage.lua
pcall(function()
    storage = require("storage.lua")
end)

local inscriberSide = "left"
local inputSide = "right"
local outputSide = "top"

local inscriber = peripheral.wrap(inscriberSide)
local inputChest = peripheral.wrap(inputSide)
local outputChest = peripheral.wrap(outputSide)

local inscriberSlots = {1, 3, 2}

items = {
    ["au"] = "minecraft:gold_ingot",
    ["di"] = "minecraft:diamond",
    ["si"] = "emendatusenigmatica:silicon_gem",
    ["cp"] = "appliedenergistics2:calculation_processor_press",
    ["ep"] = "appliedenergistics2:engineering_processor_press",
    ["lp"] = "appliedenergistics2:logic_processor_press",
    ["pq"] = "appliedenergistics2:purified_certus_quartz_crystal",
    ["pc"] = "appliedenergistics2:printed_calculation_processor",
    ["pe"] = "appliedenergistics2:printed_engineering_processor",
    ["pl"] = "appliedenergistics2:printed_logic_processor",
    ["rs"] = "extendedcrafting:redstone_component"
}

recipes = {
    {"pe", "rs", "si"},
    {"ep", "di"},
    {"pl", "rs", "si"},
    {"lp", "au"},
    {"pc", "rs", "si"},
    {"cp", "pq"}
}


function craft(v)
    local slots = {}
    local num = #v
    for i = 1, num do
        slots[i] = storage.searchInv(inputChest, items[v[i]])
        if slots[i] == nil then
            return false
        end
    end


    for i = 1, num do
        inputChest.pushItems(inscriberSide, slots[i][1], 1, inscriberSlots[i])
    end

    while inscriber.getItemDetail(4) == nil do sleep(0) end
    if num == 2 then
        inputChest.pullItems(inscriberSide, inscriberSlots[1])
    end
    outputChest.pullItems(inscriberSide, 4)
    return true

end



function cleanUp()
    inputChest.pullItems(inscriberSide, 4)
    inputChest.pullItems(inscriberSide,1)
    inputChest.pullItems(inscriberSide,2)
    inputChest.pullItems(inscriberSide,3)
end

cleanUp()
while true do
    for k,v in pairs(recipes) do
        while(craft(v)) do
            
        end
    end
    os.sleep(1)
end