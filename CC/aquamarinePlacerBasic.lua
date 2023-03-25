-- shell.run("rm loadAPIs.lua") shell.run("pastebin get 6x0B3PVu loadAPIs.lua") shell.run("loadAPIs.lua") shell.run("rm aquamarinePlacer.lua") shell.run("pastebin get hUUnD8Zi aquamarinePlacer.lua") shell.run("aquamarinePlacer.lua")


robot.init()
robot.initAutomata()

flag, block = turtle.inspect()
while block.name ~= "astralsorcery:well" do
    turtle.turnLeft()
    flag, block = turtle.inspect()
end

function getItemSlot()
    turtle.select(1)
    while turtle.getItemCount() == 0  and turtle.getSelectedSlot() ~= 16 do
        turtle.select(turtle.getSelectedSlot() + 1)
    end
end
well = peripheral.wrap("front")
os.sleep(8)
while true do
    if turtle.getFuelLevel() < 80 then
        turtle.select(16)
        turtle.refuel()
        turtle.select(1)
    end
    wellItems = well.list()

    if wellItems[1] == nil then
        getItemSlot()
        robot.useOnBlock()
    end
    
end