-- incomplete

robot = require("robot")
component = require("component")
inv = component.inventory_controller
sides = require("sides")

function doPass()
  robot.useDown()
  for ix = 1,7 do
    robot.forward()
    robot.useDown()
  end
end

function main()
  robot.turnAround()
  inv.suckFromSlot(sides.front, 1)
  inv.equip()
  robot.turnAround()
  
  turnFlag = "right"
  
  for ix = 1,8 do
    doPass()
    
    if turnFlag == "right" then
      robot.turnRight()
      robot.forward()
      robot.turnRight()
      turnFlag = "left"
    else
      robot.turnLeft()
      robot.forward()
      robot.turnLeft()
      turnFlag = "right"
    end
  end
  robot.turnRight()
  for ix = 1,8 do robot.forward() end
  robot.useDown()
  robot.turnRight()
  os.sleep(5)
end

while true do
  os.sleep(0.1)
  main()
end