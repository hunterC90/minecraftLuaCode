-- shell.run("rm loadAPIs.lua") shell.run("pastebin get 6x0B3PVu loadAPIs.lua") shell.run("loadAPIs.lua") shell.run("rm aquamarinePlacerAdvanced.lua") shell.run("pastebin get C0dTipWs aquamarinePlacerAdvanced.lua") shell.run("aquamarinePlacerAdvanced.lua")

-- Configured for 4x2
robot.init()
robot.initGPS()
robot.initAutomata()
robot.goHome()
robot.setFuelConsumptionRate(2)

function getItemSlot()
    turtle.select(1)
    while turtle.getItemCount() == 0  and turtle.getSelectedSlot() ~= 16 do
        turtle.select(turtle.getSelectedSlot() + 1)
    end
end

function getCharcoal()
    robot.select(16)
    robot.suckDown(64 - robot.getItemCount())
end

function getAquamarine()
    for i = 1, 15 do
        robot.select(i)
        robot.suckDown(64 - robot.getItemCount())

        local item = robot.getItemDetail()
        if item ~= nil and item.name == "mekanism:block_charcoal" then
            robot.dropDown()
            return false
        end
        
    end
end

function aquaCheckAndPlace()
    well = peripheral.wrap("front")
    if turtle.getFuelLevel() < 80 then
        turtle.select(16)
        turtle.refuel()
    end
    wellCur = well.tanks()
    wellItems = well.list()

    -- Check to see that there is no aquamarine and that the tank contains less than 2000mb
    if (wellItems[1] == nil) and ((wellCur[1] == nil or wellCur[1].amount < 2000)) then
        getItemSlot()
        robot.useOnBlock(true)
    end
end

function notEmpty()
    local itemNum = 0
    for i = 1, 15 do
        robot.select(i)
        itemNum = itemNum + robot.getItemCount()
    end
    if itemNum == 0 then
        print("Out of Aquamarine!")
        return false
    else
        return true
    end
end

while true do
    getCharcoal()
    getAquamarine()
    getItemSlot()
    if notEmpty() then
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        robot.forward(3)
        robot.turnLeft()
        robot.forward()
        robot.turnLeft()
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        aquaCheckAndPlace()
        robot.right()
        robot.forward(3)
        robot.turnLeft()
        robot.forward()
        robot.turnLeft()

        os.sleep(60)
    end
end