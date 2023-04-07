-- robot is an abstraction of turtle giving some more advanced functions involving gps 

local minFuelLevel = 100
local dir = nil
local automata = nil
local automataType = nil
local useOnBlockCoolDownS = os.time() + 5
local coolDownTime = 5.5

-- I have to do this nonsense so that VSCode knows about other files
pcall(function()
    egps = require("egps")
end)

function init()
    setmetatable(robot, {__index = turtle})
end

function initGPS()
    egps.setLocationFromGPS()
    getPos()
end

function initAutomata(printFlag)
    if printFlag == nil then printFlag = true end

    automata = peripheral.find("weakAutomata")
    if automata == nil then
        automata = peripheral.find("endAutomata")
        if automata == nil then
            automata = peripheral.find("husbandryAutomata")
            if automata == nil then
                automata = peripheral.find("overpoweredWeakAutomata")
                if automata == nil then
                    automata = peripheral.find("overpoweredHusbandryAutomata")
                    if automata == nil then 
                        automata = peripheral.find("overpoweredEndAutomata")
                        if automata == nil then
                            if printFlag then print("No automata core found - skipping") end
                            return false
                        end
                        automataType = "overpowered"
                        if printFlag then print("Overpowered automata core found") end
                    end
                    automataType = "overpowered"
                    if printFlag then print("Overpowered automata core found") end
                end
                automataType = "overpowered"
                if printFlag then print("Overpowered automata core found") end
            end
            automataType = "husbandry"
            if printFlag then print("Husbandry automata core found") end
        end
        automataType = "end"
        if printFlag then print("End automata core found") end
    else
        automataType = "weak"
        if printFlag then print("Weak automata core found") end
    end
    initAutomataFunctions()
    return true
end

-- Gets the first empty slot in the turtle
-- Return true if it finds one
-- False if it can't find one
function getEmptySlot()  
    for i = 1, 16 do
        robot.select(i)
        if robot.getItemCount() == 0 then
            return true
        end 
    end
    return false
end

-- default fuel value - reset to desired value
-- notice that if below minFuelLevel intended behavior is for the turtle to continue what it's doing
-- it is assumed that if you get below the minFuelLevel that the program will bring the turtle to where it can get fuel
function setMinFuelLevel(fuelLevel)
    if fuelLevel >= 100000 then
        fuelLevel = 100000
    else
        minFuelLevel = fuelLevel + 20
    end

end

function getMinFuelLevel()
    return minFuelLevel
end

-- variable that determines which slots can be refueled from
-- by default its all slots
local refuelSlot = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
function setRefuelSlots(var)
    refuelSlot = var
end

-- return refuelSlot
function getRefuelSlots()
    return refuelSlot
end

-- function to return pos as a table of x, y, and z
function getPos()
    local x, y, z = gps.locate()
    local pos = {
        x = x,
        y = y,
        z = z
    }
    return pos
end


-- return r1 - r2
function getPosDiff(r1, r2)
    local diff = {
        x=nil,
        y=nil,
        z=nil
    }

    diff.x = r1.x - r2.x
    diff.y = r1.y - r2.y
    diff.z = r1.z - r2.z
    return diff
end

local reservesPrinted = false -- if running on reserves print only once
-- refuels until above minFuelLevel
function refuel()
    local curSlot = turtle.getSelectedSlot()
    local refueled = false
    local outPrinted = false

    if (turtle.getFuelLevel() < minFuelLevel) then
        refueled = false

        for k,v in pairs(refuelSlot) do
            turtle.select(v)
            while turtle.refuel(1) and (turtle.getFuelLevel() < minFuelLevel) do
            end

            if turtle.getFuelLevel() > minFuelLevel then
                reservesPrinted = false
                refueled = true
                break
            end

        end

        if not refueled then
            if turtle.getFuelLevel() > 0 then
                if not reservesPrinted then
                    reservesPrinted = true
                    print("Running on reserves!")
                end
                turtle.select(curSlot)
                return false
            else
                if not outPrinted then
                    outPrinted = true
                    print("Outta fuel!")

                    -- TODO handling out of fuel
                    -- For now, should pause for fuel to be added to one of its fuel slots
                end
            end
        end
    end

    reservesPrinted = false
    turtle.select(curSlot)
    return true
end

-- function that checks fuel level before moving
-- will try to refuel from 1st slot first then others
-- returns false if it can't move
-- gets stuck if out of fuel
-- if multiple movements are requested then it will return true and the number of moves if succesful
-- or return false and number of moves if failed
function forward(num)
    if num == 0 then return true, 0 end
    if num == nil then num = 1 end

    local numMoved = 0
    for i = 1, num do
        refuel()
        if turtle.forward() then
            numMoved = numMoved + 1
        else
            return false, numMoved
        end
    end
    return true, numMoved
end

function back(num)
    if num == 0 then return true, 0 end
    if num == nil then num = 1 end
    local numMoved = 0
    for i = 1, num do
        refuel()
        if turtle.back() then
            numMoved = numMoved + 1
        else
            return false, numMoved
        end
    end
    return true, numMoved
end

function up(num)
    if num == 0 then return true, 0 end
    if num == nil then num = 1 end
    local numMoved = 0
    for i = 1, num do
        refuel()
        if turtle.up() then
            numMoved = numMoved + 1
        else
            return false, numMoved
        end
    end
    return true, numMoved
end

function down(num)
    if num == 0 then return true, 0 end
    if num == nil then num = 1 end
    local numMoved = 0
    for i = 1, num do
        refuel()
        if turtle.down() then
            numMoved = numMoved + 1
        else
            return false, numMoved
        end
    end
    return true, numMoved
end

-- these two functions are like the other move functions except they go right and left
-- rotates the robot back to its orginial orientation, set rotFlag to keep it that orientation
-- if num is 0 somehow then it will turn one way then the other (depending on rotFlag) without moving
function right(num, rotFlag)
    if rotFlag == nil then rotFlag = true end
    turnRight()
    local flag, movNum = forward(num)
    if rotFlag then
        turnLeft()
    end
    return flag, movNum
end

function left(num)
    if rotFlag == nil then rotFlag = true end
    turnLeft()
    local flag, movNum = forward(num)
    if rotFlag then
        turnRight()
    end
    return flag, movNum
end

-- making taking turtle functions and calling them using robot api
function turnLeft(num)
    if num == 0 then return true end
    if num == nil then num = 1 end
    for i = 1 , num do
        turtle.turnLeft()
    end

    -- updates the direction
    if dir ~= nil then
        dir = math.fmod(dir+num,4)
    end

    return true
end

function turnRight(num)
    if num == 0 then return true end
    if num == nil then num = 1 end
    for i = 1, num do
        turtle.turnRight()
    end

    -- updates the direction
    if dir ~= nil then
        dir = math.fmod(dir-num,4)
        if dir < 0 then
            dir = dir + 4
        end
    end

    return true
end

function turnAround()
    return robot.turnRight(2)
end

-- gets the turtle to move 1 block horizontally
-- returns false if it cannot move
-- tries to move all 4 directions
-- if it can't then it will move up
-- if it can no longer move up it will try to move all the way down
-- if it can no longer move down it return to its starting pos and dir and returns false
local function moveHor()
    local moved = false
    local yDiff = 0
    local leftTurns = 0
    -- tries to move, if it can't move it goes up
    while not moved do
        for i = 1, 4 do
            moved = forward()
            if not moved then
                turnLeft()
                leftTurns = math.fmod(leftTurns+1, 4)
            else
                break
            end
        end
        if not moved and up() then
            yDiff = yDiff + 1
        else
            break
        end
    end

    -- tries to move, if it can't move it goes down
    if not moved then
        -- goes to 1 position lower than where it started
        for i = 1, yDiff+1 do
            if down() then
                yDiff = yDiff - 1
            end
        end

        -- if it was able to go to 1 position lower than it started try to move forward again
        if yDiff == -1 then
            while not moved do
                for i = 1, 4 do
                    moved = forward()
                    if not moved then
                        turnLeft()
                        leftTurns = math.fmod(leftTurns+1, 4)
                    else
                        break
                    end
                end
                if not moved and down() then
                    yDiff = yDiff - 1
                else
                    break
                end
            end
        end
    end

    local newPos = getPos()
    back()

    if yDiff > 0 then
        down(yDiff)
    elseif yDiff < 0 then
        up(-1*yDiff)
    end

    return newPos, leftTurns

end

-- function to get the turtle's direction then returns to its startPos and direction
-- return 0 for north, 1 for east, 2 for south, and 3 for west
-- return false for a failed attempt
-- return dir if already known
function getDir(flag)
    if dir ~= nil and flag == nil then
        return dir
    end

    local startPos = getPos()
    -- try to move
    local newPos, leftTurns = moveHor()

    if newPos == nil then
        print("Door stuck! Please! I beg you!")
        return false
    end

    local diffPos = getPosDiff(startPos, newPos)

    if diffPos.x == 1 then -- west
        dir = 1
    elseif diffPos.x == -1 then -- east
        dir = 3
    elseif diffPos.z == 1 then -- north
        dir = 0
    elseif diffPos.z == -1 then -- south
        dir = 2
    elseif diffPos ~= nil then
        print("Something went very wrong trying to get the direction!")
        return false
    end

    if leftTurns == 3 then
        turnLeft()
    else
        turnRight(leftTurns)
    end
    return dir

end

-- function to set the turtle's direction
-- if it doesn't already know its direction then it finds it out
function setDir(newDir)
    if dir == nil then
        dir = getDir()
    end

    newDir = math.fmod(newDir, 4)

    local diffDir = math.fmod(math.fmod(newDir-dir, 4) + 4, 4)

    if diffDir == 3 then
        turnRight()
    else
        turnLeft(diffDir)
    end

    dir = newDir
    return true

end

-- function to write the direction to the turtle if determined by another program
function writeDir(newDir)
    dir = newDir
end

-- function to move the turtle to a given pos coordinate (pos has x, y, and z values)
-- simple pathfinding that assumes it can eventually get over obstacles
-- if it can no longer move up it will attempt to move backwards until it can move up
function moveToPos(x, y, z, finDir)
    if z == nil then
        finDir = y
        y = x.y
        z = z.z
        x = x.x
    end

    local flag = egps.moveTo(x, y, z, finDir)

    if finDir ~= nil then
        setDir(finDir)
    end

    return flag
end



-- Give it a set of coordinates 
function moveToRel(x, y, z, finDir)
    if z == nil then
        finDir = y
        y = y.y
        z = z.z
        x = x.x
    end

    local newPos = getPos()
    newPos.x = newPos.x + x
    newPos.y = newPos.y + y
    newPos.z = newPos.z + z

    return moveToPos(newPos.x, newPos.y, newPos.z, finDir)
end

function mapDir(mappedDir)
    if mappedDir == nil then
        local mappedDir = dir
    end
    if mappedDir == 1 then mappedDir = 3
    elseif mappedDir == 3 then mappedDir = 1
    end
    return mappedDir
end

-- This function will tell the robot that it can pop down an enderchest
-- to refuel, get, and deposit items
function enableEnderChest()

end

function goHome(name)
    moveToPos(home.get(name))
end

-- Automata integration
-- In order for the IDE and lua interpreter in game to see automata operations using the robot I need to define every method here
function initAutomataFunctions()
    if automataType == "overpowered" then
        initOverpoweredAutomataFunction()
    elseif automataType == "end" then
        initEndAutomataFunctions()
    elseif automataType == "husbandry" then
        initHusbandryAutomataFunction()
    else
        initWeakAutomataFunctions()
    end
end

function initWeakAutomataFunctions()
    function robot.setFuelConsumptionRate(num)
        local flag, msg = automata.setFuelConsumptionRate(num)
        if flag then
            coolDownTime = 5/num
            useOnBlockCoolDownS = math.min(useOnBlockCoolDownS,os.clock() + coolDownTime)
            return true
        else
            return flag, msg
        end
    end

    function robot.getFuelConsumptionRate()
        return automata.getFuelConsumptionRate()
    end

    function robot.getCoolDownTime()
        return coolDownTime
    end

    function robot.useOnBlock(waitFlag)
        while waitFlag and robot.getUseOnBlockCooldown() > 0 do os.sleep(0.01) end
        if not waitFlag and robot.getUseOnBlockCooldown() > 0 then
            return false
        else
            refuel()
            flag, str = automata.useOnBlock()
            while flag == nil  and waitFlag do
                os.sleep(0.01)
                refuel()
                flag, str = automata.useOnBlock()
            end
            useOnBlockCoolDownS = os.clock()
            return flag, str
        end
    end

    function robot.getUseOnBlockCooldown()
        return math.max(robot.getCoolDownTime() + useOnBlockCoolDownS - os.clock(), 0)
    end

    robot.getUseOnBlockCooldown()
end

function initEndAutomataFunctions()
    initWeakAutomataFunctions()
end

function initHusbandryAutomataFunction()
    initWeakAutomataFunctions()
end

function initOverpoweredAutomataFunction()
    initWeakAutomataFunctions()
    initEndAutomataFunctions()
    initHusbandryAutomataFunction()
end
