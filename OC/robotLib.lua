robot = require("robot")
local sides = require("sides")
local nav = require("component").navigation

homeNav = {}
--homeNav.x = 359.5 homeNav.y = 63.5 homeNav.z = 64.5
homeNav.x = -56.5 homeNav.y = 151.5 homeNav.z = -73.5

function robot.safeUp(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.up()) do end
  end
end

function robot.safeDown(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.down()) do end
  end
end

function robot.safeForward(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.forward()) do end
  end
end

function robot.safeBack(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.back()) do end
  end
end

function robot.turnToSide(side)
  local curSide = nav.getFacing()
  
  while (curSide ~= side) do
    robot.turnRight()
    curSide = nav.getFacing()
  end
end

-- Returns the position of the robot relative to home
function robot.getRelPos()
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  curSpot.x = curSpot.x - homeNav.x
  curSpot.y = curSpot.y - homeNav.y
  curSpot.z = curSpot.z - homeNav.z
  
  return curSpot
end

-- gets current state of robot
function robot.getState()
  local state = {}
  
  state.spot = robot.getRelPos()
  state.side = nav.getFacing()
  state.slot = robot.select()
  
  return state
end

-- Takes the robot to defined state
function robot.goToState(state)
  robot.goTo(state.spot)
  robot.turnToSide(state.side)
  robot.select(state.slot)
end

-- Go to position relative to home
function robot.goTo(x, y, z)
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  if (y == nil) then
    y = x.y
    z = x.z
    x = x.x
  end
  
  local dx = homeNav.x - curSpot.x + x
  local dy = homeNav.y - curSpot.y + y
  local dz = homeNav.z - curSpot.z + z
  
  robot.safeUp(2)
  
  if (dy > 0) then
    robot.safeUp(dy)
  end 

  if (dx > 0) then
    robot.turnToSide(sides.posx)
    robot.safeForward(dx)
  elseif (dx < 0) then
    robot.turnToSide(sides.negx)
    robot.safeForward(-1*dx)
  end
  
  if (dz > 0) then
    robot.turnToSide(sides.posz)
    robot.safeForward(dz)
  elseif (dz < 0) then 
    robot.turnToSide(sides.negz)
    robot.safeForward(-1*dz)
  end
  
  if (dy < 0) then
    robot.safeDown(-1*dy)
  end
  
  robot.safeDown(2)
end

-- Go to position relative to home without going up then down
function robot.goToUnsafe(x, y, z)
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  if (y == nil) then
    if x.x == nil then
      y = x[2]
      z = x[3]
      x = x[1]
    else
      y = x.y
      z = x.z
      x = x.x
    end
  end
  
  local dx = homeNav.x - curSpot.x + x
  local dy = homeNav.y - curSpot.y + y
  local dz = homeNav.z - curSpot.z + z
  
  if (dy > 0) then
    robot.safeUp(dy)
  end 

  if (dx > 0) then
    robot.turnToSide(sides.posx)
    robot.safeForward(dx)
  elseif (dx < 0) then
    robot.turnToSide(sides.negx)
    robot.safeForward(-1*dx)
  end
  
  if (dz > 0) then
    robot.turnToSide(sides.posz)
    robot.safeForward(dz)
  elseif (dz < 0) then 
    robot.turnToSide(sides.negz)
    robot.safeForward(-1*dz)
  end
  
  if (dy < 0) then
    robot.safeDown(-1*dy)
  end
end

function robot.goHome()
  robot.goTo(0, 0, 0)
  robot.turnToSide(sides.negx)
end

return robotrobot = require("robot")
local sides = require("sides")
local nav = require("component").navigation

homeNav = {}
--homeNav.x = 359.5 homeNav.y = 63.5 homeNav.z = 64.5
homeNav.x = -56.5 homeNav.y = 151.5 homeNav.z = -73.5

function robot.safeUp(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.up()) do end
  end
end

function robot.safeDown(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.down()) do end
  end
end

function robot.safeForward(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.forward()) do end
  end
end

function robot.safeBack(n)
  n = n or 1
  for ix = 1,n do
    while (not robot.back()) do end
  end
end

function robot.turnToSide(side)
  local curSide = nav.getFacing()
  
  while (curSide ~= side) do
    robot.turnRight()
    curSide = nav.getFacing()
  end
end

-- Returns the position of the robot relative to home
function robot.getRelPos()
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  curSpot.x = curSpot.x - homeNav.x
  curSpot.y = curSpot.y - homeNav.y
  curSpot.z = curSpot.z - homeNav.z
  
  return curSpot
end

-- gets current state of robot
function robot.getState()
  local state = {}
  
  state.spot = robot.getRelPos()
  state.side = nav.getFacing()
  state.slot = robot.select()
  
  return state
end

-- Takes the robot to defined state
function robot.goToState(state)
  robot.goTo(state.spot)
  robot.turnToSide(state.side)
  robot.select(state.slot)
end

-- Go to position relative to home
function robot.goTo(x, y, z)
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  if (y == nil) then
    y = x.y
    z = x.z
    x = x.x
  end
  
  local dx = homeNav.x - curSpot.x + x
  local dy = homeNav.y - curSpot.y + y
  local dz = homeNav.z - curSpot.z + z
  
  robot.safeUp(2)
  
  if (dy > 0) then
    robot.safeUp(dy)
  end 

  if (dx > 0) then
    robot.turnToSide(sides.posx)
    robot.safeForward(dx)
  elseif (dx < 0) then
    robot.turnToSide(sides.negx)
    robot.safeForward(-1*dx)
  end
  
  if (dz > 0) then
    robot.turnToSide(sides.posz)
    robot.safeForward(dz)
  elseif (dz < 0) then 
    robot.turnToSide(sides.negz)
    robot.safeForward(-1*dz)
  end
  
  if (dy < 0) then
    robot.safeDown(-1*dy)
  end
  
  robot.safeDown(2)
end

-- Go to position relative to home without going up then down
function robot.goToUnsafe(x, y, z)
  local curSpot = {}
  curSpot.x, curSpot.y, curSpot.z = nav.getPosition()
  
  if (y == nil) then
    if x.x == nil then
      y = x[2]
      z = x[3]
      x = x[1]
    else
      y = x.y
      z = x.z
      x = x.x
    end
  end
  
  local dx = homeNav.x - curSpot.x + x
  local dy = homeNav.y - curSpot.y + y
  local dz = homeNav.z - curSpot.z + z
  
  if (dy > 0) then
    robot.safeUp(dy)
  end 

  if (dx > 0) then
    robot.turnToSide(sides.posx)
    robot.safeForward(dx)
  elseif (dx < 0) then
    robot.turnToSide(sides.negx)
    robot.safeForward(-1*dx)
  end
  
  if (dz > 0) then
    robot.turnToSide(sides.posz)
    robot.safeForward(dz)
  elseif (dz < 0) then 
    robot.turnToSide(sides.negz)
    robot.safeForward(-1*dz)
  end
  
  if (dy < 0) then
    robot.safeDown(-1*dy)
  end
end

os.sleep(345)
robot.goHome()
function robot.goHome()
  robot.goTo(0, 0, 0)
  robot.turnToSide(sides.negx)
end

return robot