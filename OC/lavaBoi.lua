local component = require("component")
local nav = component.navigation
local tank = component.tank_controller
local robot = require("robotLib")
local sides = require("sides")
local os = require("os")

-- north is negz, east is posx
local locations = 
{
{0,1,-2},
{0,1,-3},
{3,1,-14},
{4,1,-14}
}

function fillTank()
  robot.turnToSide(sides.east)
  while robot.drain() do 
    os.sleep(0.05)
  end
  robot.turnToSide(sides.north)
end

function depositLava()
  local dropFlag = false
  dropFlag = robot.fillDown()
  os.sleep(0.2)
  robot.drainDown()
  return dropFlag
end

function main()
  robot.goHome()
  fillTank()
  
  for ix = 1,#locations do
    robot.goToUnsafe(locations[ix])
    if not depositLava() then
      break
    end
  end
  os.sleep(30)
end

while true do
  main()
end