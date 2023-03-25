local component = require("component")
local nav = component.navigation
local inv = component.inventory_controller
local robot = require("robotLib")
local sides = require("sides")
local os = require("os")
local geo = component.geolyzer


function pickup64()
  robot.turnToSide(sides.east)
  local itemsLeft = 64 - (inv.getStackInInternalSlot(2) or {size=0}).size - (inv.getStackInInternalSlot(3) or {size=0}).size
  local item = {}
  
  for ix = 1,54 do
    if itemsLeft == 0 then
      return true
    end
  
    item = inv.getStackInSlot(sides.front,ix)
    if item then
      if item.name == "thaumcraft:stone_arcane" then
        robot.select(2)
        inv.suckFromSlot(sides.front,ix,itemsLeft)
        itemsLeft = 64 - (inv.getStackInInternalSlot(2) or {size=0}).size - (inv.getStackInInternalSlot(3) or {size=0}).size
      elseif item.name == "astralsorcery:blockinfusedwood" then
        robot.select(3)
        inv.suckFromSlot(sides.front,ix,itemsLeft)
        itemsLeft = 64 - (inv.getStackInInternalSlot(2) or {size=0}).size - (inv.getStackInInternalSlot(3) or {size=0}).size
      end      
    end
  end
  
end

function placeBlock()
  robot.select(2)
  if not robot.placeDown() then
    robot.select(3)
    robot.placeDown()
  end  
end

function doThing()
  robot.select(1)
  local block = geo.analyze(sides.down)
  local tool = inv.getStackInInternalSlot(1).name
  if block.name == "botania:livingwood" then
    if tool == "tconstruct:hatchet" then
      inv.equip()
    end
    robot.select(4)
    robot.swingDown()
  elseif block.name == "botania:livingrock" then
    if tool == "tconstruct:pickaxe" then
      inv.equip()
    end
    robot.select(5)
    robot.swingDown()
  end
  placeBlock()
end

function deposit()
  robot.turnToSide(sides.west)
  robot.select(4)
  inv.dropIntoSlot(sides.front,10,64)
  robot.select(5)
  inv.dropIntoSlot(sides.front,11,64)
end

function main()
  local leftFlag = true

  robot.goHome()
  deposit()
  pickup64()
  os.sleep(2)
  robot.goToUnsafe({0,1,-2})
  
  for ix1 = 1,6 do
    doThing()
    for ix2 = 1,11 do
      doThing()
      robot.safeForward()
    end
    
    doThing()
    if leftFlag then      
      robot.turnLeft()      
      robot.safeForward()
      robot.turnLeft()
      leftFlag = false
    else
      robot.turnRight()
      robot.safeForward()
      robot.turnRight()
      leftFlag = true
    end
    
  end
  
end

robot.goHome()
while true do main() os.sleep(0.05) end