-- This script automates the compactor in create
-- Assumptions
-- Constant mechanical power is provided to the mixer
-- inputs will come in from the top
-- outputs will go out the back

----- CONFIG VALUES -----
local heatTime = 0
local craftTime = 0.5

local heatOverride = true -- If creative blaze cakes are being used set to true
-------------------------

-- Program parameters
ioSide = "back"
medSide = "top"
fuelSide = "bottom"

-- Robot initialization
robot.init()
robot.initAutomata()
robot.setRefuelSlots({16})
robot.setMinFuelLevel(800)
robot.setFuelConsumptionRate(5) -- allows the automata to operate once a second at the cost of 8 fuel

-- I have to do this so the IDE knows about the API
pcall(function() 
    robot = require("APIs/robot.lua")
end)

-- structure of recipes
-- recipes
--    recipes[i].inputs (inputs to recipe)
--      recipes[i].inputs[j].name (name of ingredient)
--      recipes[i].inputs[j].count  (number of ingredient per craft)
--      recipes[i].inputs[j].liquid (is the input a liquid - may be more than one bucket)
--    recipes[i].outputs (outputs of recipes)
--      recipes[i].outputs[j].name (name of output)
--      recipes[i].outputs[j].count  (number of the output)
--      recipes[i].outputs[j].liquid (is the output a liquid - may be more than one bucket)
--    recipes[i].heated (if the item is heated - false, true, and blazed are possible values)
--    recipes[i].craftNum (number of times the machines operates to craft the recipe - will pull items out and put new items in for each craftNum)

-- Sets the robot its correct position facing the basin
function initPosition()
    while robot.down() do end
    robot.up()

    local _,block = robot.inspect()

    while block == nil or block.name ~= "create:basin" do
        robot.turnRight()
    end
end

-- This function loads the recipes.txt file from pastebin and refreshes the recipes
-- This function gets run when the an unknown recipe shows up
function loadRecipes()

    -- open file for reading
    local file = io.open("recipes.txt", "r")

    if file ~= nil then
        -- read file contents into a string
        local contents = file:read("*all")

        -- close file
        file:close()

        -- load contents as a Lua chunk and execute it to set the recipes variable
        recipes = load("return " .. contents)()
    end
end

-- Initializes the chests
function initChests()
    ioChest = peripheral.wrap(ioSide)
    medChest = peripheral.wrap(medSide)
    robot.down()
    fuelChest = peripheral.wrap(fuelSide)
    turtle.select(16)
    turtle.suckDown(64-turtle.getItemCount())
    robot.up()
end

-- Clears the items from the basin (also breaks it so clear and liquid)
function clearItems()
    robot.getEmptySlot()
    print("using on block")
    robot.useOnBlock(true)
    print("done")
    robot.getEmptySlot()
    robot.dig()
    robot.place()

    robot.select(1)
    while robot.getItemCount() ~= 0 and robot.getSelectedSlot() ~= 16 do
        robot.dropUp()
        robot.select(robot.getSelectedSlot() + 1)
    end
    robot.select(1)

    local medItems = medChest.list()

    for k,_ in pairs(medItems) do
        medChest.pushItems(ioSide, k)
    end

end

-- checks if the recipe matches the items
-- courtesy of GPT3
function checkRecipe(items, recipe)
    -- First, we need to check if the tables have the same number of elements
    if #items ~= #recipe then
        return false
    end

    -- Next, we need to create a copy of recipe to keep track of the elements that we've already matched
    local recipe_copy = {}
    for i, v in ipairs(recipe) do
        recipe_copy[i] = v
    end

    -- Then, we loop through each element in items
    for _, element1 in ipairs(items) do
        local match_found = false
        
        -- We loop through each element in recipe_copy to find a match for element1
        for i, element2 in ipairs(recipe_copy) do
        if element1.name == element2.name and element1.count == element2.count then
            -- We found a match, so we remove element2 from recipe_copy and move on to the next element in items
            table.remove(recipe_copy, i)
            match_found = true
            break
        end
        end
        
        -- If we didn't find a match for element1 in recipe, then the tables don't match
        if not match_found then
        return false
        end
    end

    -- If we got through all of the elements in items without finding any mismatches, and recipe_copy is now empty, then the tables match
    return #recipe_copy == 0
end


-- returns the recipe corresponding to the items in the input chest
-- first checks if the correct recipe is the previous recipe
function findRecipe(inputItems, prevRecipe)
    if prevRecipe == nil then
        prevRecipe = recipes[1] -- sets prevRecipe to the first recipe if there wasn't a prev recipe. 
    end

    if checkRecipe(inputItems, prevRecipe.inputs) then
        return prevRecipe
    end

    rIx = nil
    for i = 1, #recipes do
        if checkRecipe(inputItems, recipes[i].inputs) then
            rIx = i
            break
        end
    end
    
    if rIx ~= nil then
        return recipes[rIx]
    else
        return nil
    end
end

-- Takes the items from the IO chest and gets them to the turtle
-- Collects the items in the same order as the in the recipe
function collectIngredients(ioItems, recipe)
    -- create a copy of ioItems to keep track of the elements that we've already matched
    local itemsCopy = {}
    for i, v in ipairs(ioItems) do
        itemsCopy[i] = v
    end

    local slot = 1
    robot.select(1)
    for _,v1 in pairs(recipe.inputs) do
        for i,v2 in ipairs(itemsCopy) do
            if v1.name == v2.name then
                medChest.pullItems(ioSide, slot)
                slot = slot + 1
                turtle.suckUp()
                table.remove(itemsCopy, i)
                robot.select(robot.getSelectedSlot()+1)
                break
            end
        end
    end
end

-- heats the blaze burner if needed
function heat()
    if (heatTime - os.clock()) < 16 then
        print("heating")
        robot.down()
        local curSlot = robot.getSelectedSlot()
        robot.select(16)
        robot.useOnBlock(true)
        heatTime = 64 + math.max(heatTime, os.clock())
        robot.select(curSlot)
        robot.up()
    end
end

function getFuel()
    -- Refuel here if needed
    if robot.getItemCount(16) < 32 then
        local downFlag = robot.down()
        local curSlot = robot.getSelectedSlot()
        robot.select(16)
        while robot.getItemCount() < 64 do
            robot.suckDown(64 - robot.getItemCount())
        end

        if downFlag then robot.up() end
        robot.select(curSlot)
    end
end

-- With all of the ingredients ready, crafts the items
function craft(recipe)
    for i = 1, recipe.craftNum do
        if recipe.heated == true then
            heat()
        end

        for k,v in pairs(recipe.inputs) do
            robot.select(k)

            if string.find(v.name, "bucket")  and not string.find(v.name,"minecraft:bucket") then
                robot.useOnBlock(true)
            elseif v.name == "create:blaze_cake" then
                robot.down()
                robot.useOnBlock(true)
                robot.up()
            else
                robot.drop(v.count/recipe.craftNum)
            end
        end

        os.sleep(craftTime)
    end
    robot.useOnBlock(true)
end

-- Take all of the results and puts them in the ioChest
function depositResult()
    outputIx = 0
    for i = 1, 15 do
        if robot.getItemCount(i) > 0 then
            robot.select(i)
            robot.dropUp()
            medChest.pushItems(ioSide, 1)
        end
    end
end

-- Initializes the computer for mixer automation
function init()
    if heatOverride then
        heatTime = 2147483648
    end

    initPosition()
    loadRecipes()
    initChests()
    clearItems()
end

-- The main function - does the things
function main()
    init()
    
    local prevRecipe = nil
    while true do
        local ioItems = ioChest.list()

        if ioItems[1] ~= nil then
            recipe = findRecipe(ioItems, prevRecipe)

            if recipe ~= nil then
                collectIngredients(ioItems, recipe)
                craft(recipe)
                depositResult()
                prevRecipe = recipe
            end
        end

        os.sleep(0) -- sleep to prevent 'Too long without yielding' error
    end
end

main()