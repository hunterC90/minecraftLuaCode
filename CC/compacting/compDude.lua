-- This script is part of the compactor automation

----- CONFIG VALUES -----
inputSide = "minecraft:chest_15" -- side of input chest
outputSide = "minecraft:chest_16" -- side of output chest which connects to AE network
robotNum = 8
-------------------------

robot = {} -- a list where each element is a table with keys chest, name (name of chest peripheral), recipe, and busy flag
inputItems = {} -- list of input items from chest.list()

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
--    recipes[i].heated (if the item is heated - false and true are possible values)
--    recipes[i].craftNum (number of times the machines operates to craft the recipe - will pull items out and put new items in for each craftNum)

-- This function loads the recipes.txt file from pastebin and refreshes the recipes
-- This function gets run when the an unknown recipe shows up
function loadRecipes()
    -- delete the old recipes.txt file and get a new one from pastebin
    shell.run("rm recipes.txt")
    shell.run("pastebin get q0DyXpAc recipes.txt")

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

-- function that initializes input and output chests and all chests that go to the robots
-- it will get chests until there are no more - this way more mixers can be added without needing to change the code
function initChests()
    inputChest = peripheral.wrap(inputSide)
    outputChest = peripheral.wrap(outputSide)

    local i = 1
    local k = 0
    local chest = peripheral.find("minecraft:chest_0") -- Check name that CC gives when connecting chests to modems
    local chestStr = "minecraft:chest_" .. tostring(k)
    while robotNum - i >= 0 do
        if chest ~= nil and chestStr ~= inputSide and chestStr ~= outputSide then 
            robot[i] = {}
            robot[i].name = "minecraft:chest_" .. tostring(k)
            robot[i].recipe = nil
            robot[i].busy = false
            robot[i].chest = chest
            i = i + 1
        end
        k = k + 1
        chestStr = "minecraft:chest_" .. tostring(k)
        chest = peripheral.wrap(chestStr)
    end
end

-- iterates through all robots to clear out anything that's in their chests
-- takes everything that's in the robot's chest and sends it to the output chest
function clearItems()
    local items
    for i = 1, #robot do
        items = robot[i].chest.list()

        for k, v in pairs(items) do
            outputChest.pullItems(robot[i].name, k)
        end
    end
end

-- return the index of the first robot that is free
-- returns false if not robot is free
function findNextFree()
    for i = 1, # robot do
        if not robot[i].busy then
            return i
        end
    end
    return false
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
        print("Couldn't find recipe - updating list and trying again")
        loadRecipes()
        rIx = nil
        for i = 1, #recipes do
            if checkRecipe(inputItems, recipes[i].inputs) then
                rIx = i
                break
            end
        end
    end

    if rIx ~= nil then
        return recipes[rIx]
    else
        local errStr = inputItems[1].count  .. " " .. inputItems[1].name .. "\n"
        for i = 2, #inputItems do
            errStr = errStr .. inputItems[i].count  .. " " .. inputItems[i].name .. "\n"
        end
        error("Recipe could not be found! Check the recipe list for the following\n" .. errStr)
    end
end

-- Sends the items to the avaliable robot
function sendToRobot(robot, inputItems, nextRecipe)
    for k, v in pairs(inputItems) do
        inputChest.pushItems(robot.name, k)
    end
    robot.recipe = nextRecipe
    robot.busy = true
end

-- checks of the output of a recipe given to a robot is finished
-- if the output is finished the result is placed in the output chest and the robot's busy flag is set to false
function getOutput(robot)
    outputItems = robot.chest.list()

    if outputItems ~= nil and checkRecipe(outputItems, robot.recipe.outputs) then
        robot.busy = false
        for k,v in pairs(outputItems) do
            outputChest.pullItems(robot.name, k)
        end
    end
end

-- Initializes the computer for mixer automation
function init()
    os.sleep(0) -- wait for robots to dump anything that was in the process of being crafted
    
    loadRecipes()
    initChests()

    clearItems()
end

-- The main function which handles the automation
function main()
    init()
    local nextRecipe = nil
    while true do
        local inputItems = inputChest.list()
        if inputItems[1] ~= nil then
            local freeIx = findNextFree()
            if freeIx then
                nextRecipe = findRecipe(inputItems, nextRecipe)
                sendToRobot(robot[freeIx], inputItems, nextRecipe)
            end
        end

        -- loop through all busy robots to check for outputs
        for i = 1, #robot do
            if robot[i].busy then
                getOutput(robot[i])
            end
        end
        os.sleep(0) -- sleep to prevent 'Too long without yielding' error
    end
end

args = ...
if args == "debug" or args == "d" then
    os.loadAPI("mixerDude.lua")
else
    main()
end