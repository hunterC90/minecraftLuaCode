-- function inventory peripheral for any items with the given name in the given slots
-- if the array of slots is not given then all slots are checked
-- if name is not given then returns info on every item
-- returns arrays of slots that the item is in and an array of how many
function searchInv(inventory, name, slotsToSearch)
    local slotsContaining = {}
    local slotsFilled = 0
    local quatities = {} -- notice that this gives a value for each slot
    
    if slotsToSearch == nil then
        slotsToSearch = {}
        for i = 1, inventory.size() do
            slotsToSearch[i] = i
        end    
    end

    local item = inventory.list()
    for i = 1, #slotsToSearch do        
        if (item[i] ~= nil) and (name == nil or name == item[i].name) then
            slotsFilled = slotsFilled + 1
            quatities[slotsFilled] = item[i].count
            slotsContaining[slotsFilled] = i
        end
    end

    if slotsFilled ~= 0 then
        return slotsContaining, quatities
    else
        return nil, nil
    end
end

-- prints all items and quantity, and names
function printItems(inventory)
    local item = inventory.list()

    for k,v in pairs(item) do
        print(v.count, v.name)
    end
end