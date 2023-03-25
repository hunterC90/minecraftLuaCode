workingArea = {}
workingArea.S = -5116.5
workingArea.W = 7464.5
workingArea.N = -5368.5
workingArea.E = 7662.5

local component = require("component")
local computer = require("computer")
local shell = require("shell")
local os = require("os")
event = require("event")
local thread = require("thread")
local gen = component.generator
local nav = component.navigation
local inv = component.inventory_controller
local robot = require("robotLib")
local io = require("io")
local sides = require("sides")
local txt = require("textDatabase")
signals = require("signals")

message = ""

local thr = {}
thr["energy"] = thread.create(os.execute, "/home/checkPower")


local comport = 69

local homeSpot = {}
homeSpot.x = 7463.5 homeSpot.y = 63.5 homeSpot.z = -5119.5

homeNav = {}
homeNav.x = 359.5 homeNav.y = 63.5 homeNav.z = 64.5

workingArea.S = workingArea.S - homeSpot.z
workingArea.N = workingArea.N - homeSpot.z
workingArea.W = workingArea.W - homeSpot.x
workingArea.E = workingArea.E - homeSpot.x

function interrupted()
  for k,v in pairs(thr) do
    thr[tostring(k)]:kill()
  end
  for ix = 1,#events do 
    event.ignore(events[ix][1], events[ix][2])
  end
  print("\nInterrupted - Closing")
  os.exit()
end

function refuel()
  local curSlot = robot.select()
  robot.select(16)
  gen.insert(1)
  robot.select(curSlot)
end

function table_invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

function itemDucts()
  local state = robot.getState()
  
  robot.goHome()
  robot.select(15)
  
  local stack = inv.getStackInSlot(sides.front, 1)
  if (stack == nil) then
    print("where are my item-ducts :(")
  end
  while (inv.getStackInSlot(sides.front, 1) == nil) do end
  
  robot.select(1)
  inv.suckFromSlot(sides.front, 2, 64)
  
  -- Return robot to old position
  robot.goToState(state)
end

function newPlotPos()
  local plotSpotFound = false
  local plotSpot = {}
  local plotsPos = txt.getAllPlotsPos()
  local xStr = plotsPos[1].x
  local zStr = plotsPos[1].z
  
  while (not plotSpotFound) do
    plotRow = {}
    plotEast = plotsPos[1]
    
    -- get all plots in the row
    for ix = 1,#plotsPos do
      if (plotsPos[ix].z == zStr) then
        table.insert(plotRow, plotsPos[ix])
      end
    end
    
    if (#plotRow ~= 0) then
      for ix = 1,#plotRow do
        if ( (plotEast.x <= plotRow[ix].x) and (zStr == plotRow[ix].z) ) then
          plotEast = plotRow[ix]
        end
      end
      -- check if position east is valid
      if plotEast.x + 13 <= workingArea.E then -- plot spot is good!
        plotSpot = plotEast
        plotSpot.x = plotSpot.x + 9
        plotSpotFound = true
        signals.send("robot Area Found!")
        return plotSpot, false
      end
    else -- no plots in this hypothetical new row
      plotSpot = plotsPos[1]
      plotSpot.z = zStr
      if plotSpot.z <= workingArea.N then -- plot spot too far north
        signals.send("robot No Working Area!")
        computer.pushSignal("interrupted")
        os.exit()
      else
        signals.send("robot Area Found!")
        return plotSpot, true
      end
    end
    zStr = zStr - 11
  end
end

function plantSeedHoeDown(slot)
  robot.select(slot)
  while (robot.select() ~= 16) do
    if inv.getStackInInternalSlot() then
      robot.placeDown()
      return robot.select()
    else
      robot.select(robot.select() + 1)
    end
  end
  return 16
end

function hoeDown()
  local slot = 5
  robot.useDown() slot = plantSeedHoeDown(slot)
  for ix1 = 1,9 do
    for ix2 = 1,8 do
      robot.safeForward()
      robot.useDown() slot = plantSeedHoeDown(slot)
    end
    if (ix1 ~= 9) then
      if ( (ix1 - math.floor(ix1/2)*2 ) ~= 0 ) then
        robot.turnRight()
        robot.safeForward()
        robot.useDown() slot = plantSeedHoeDown(slot)
        robot.turnRight()
      else
        robot.turnLeft()
        robot.safeForward()
        robot.useDown() slot = plantSeedHoeDown(slot)
        robot.turnLeft()
      end
    end
  end
end

function getPlotItems()
  robot.select(1) inv.suckFromSlot(sides.front, 1, 64-inv.getStackInInternalSlot(1).size)
  robot.select(2) inv.suckFromSlot(sides.front, 3, 1)
  robot.select(4) inv.suckFromSlot(sides.front, 4, 1)
  robot.select(16) inv.suckFromSlot(sides.front, 2, 64-inv.getStackInInternalSlot(16).size)
  robot.select(3)
  local ix = 5
  while (not inv.suckFromSlot(sides.front, ix, 1)) do
    ix = ix + 1
  end
  return 
end

function get80Seeds()
  local seedsArray = {}
  robot.turnRight()
  
  local seedsToGet = 80
  local maxSlots = 10
  local item = {}
  local seedTypes = txt.getAllSeedTypes()
  
  local ix = 0
  while ( (ix<54) and (seedsToGet > 0) and (maxSlots > 0) ) do
    ix = ix + 1
    item = inv.getStackInSlot(sides.front,ix)
    if (item ~= nil) then
      table.insert(seedsArray, item)
      robot.select(15-maxSlots)
      inv.suckFromSlot(sides.front, ix, seedsToGet)
      seedsToGet = seedsToGet - item.size
      maxSlots = maxSlots - 1
      if (not txt.check(item.name)) then
        txt.add(item.name)
        sendSeedsFile = true
      end
    end
  end
  robot.select(1)
  if sendSeedsFile then
    signals.sendFile("/home/seeds")
  end
  return seedsArray
end

function prefillPlot()
  local plot = {}
  for ix = 1,9 do plot[ix] = {1, 1, 1, 1, 1, 1, 1, 1, 1} end
  plot[5][5] = 0
  return plot
end

function getPlotVar(seedsArray)
  local seedArray = table_invert(txt.getAllSeedTypes())
  local rev = false
  local row = 1
  local col = 1
  
  local plot = prefillPlot()
  
  if seedsArray == nil then return plot end
  
  for ix = 1,#seedsArray do
    while (seedsArray[ix].size ~= 0) do
      plot[row][col] = seedArray[seedsArray[ix].name]
      seedsArray[ix].size = seedsArray[ix].size -  1
      if rev then
        col = col - 1
        if col == 0 then
          rev = false
          col = 1
          row = row + 1
        end
      else
        col = col + 1
        if col == 10 then
          col = 9
          rev = true
          row = row + 1
        end
      end
      if (col == 5 and row == 5) then
        col = 6
      end
    end
  end
  return plot
end

function appendPlotPos(plotPos)
  local f = io.open("../home/plotPos", "a")
  f:write(plotPos.x .. " " .. plotPos.y .. " " .. plotPos.z .. "\n")
  f:flush()
  f:close()
end

function newPlot()
  print("making new plot")
  local plotSpot = {}
  local rowFlag = false
  plotSpot, rowFlag = newPlotPos()
  if (plotSpot == nil) then
    print("unable to do new plot")
    signals.send("robot fuck")
    return false
  end
  signals.send("robot New plot coming up at " .. plotSpot.x .. " " .. plotSpot.y .. " " .. plotSpot.z)
  
  getPlotItems()
  print(plotSpot.x, plotSpot.y, plotSpot.z)
  
  robot.select(1)
  if not rowFlag then
    robot.goTo(plotSpot.x-8, plotSpot.y+1, plotSpot.z-1)
    robot.turnToSide(sides.east)
    for ix = 1,8 do
      robot.placeDown()
      robot.safeForward()
    end
    robot.placeDown()
  else
    robot.goTo(plotSpot.x-5, plotSpot.y+1, plotSpot.z+10)
    robot.turnToSide(sides.north)
    for ix = 1,11 do  
      robot.placeDown()
      robot.safeForward()
    end
    robot.placeDown()
    robot.turnToSide(sides.east)
    for ix = 1,5 do
      robot.safeForward()
      robot.placeDown()
    end
  end
  robot.turnToSide(sides.south)
  robot.safeForward(2)
  robot.turnAround()
  robot.safeDown()
  robot.select(2)
  robot.place()
  robot.turnAround()
  robot.safeForward(4)
  robot.swingDown()
  robot.select(3)
  inv.equip()
  robot.useDown()
  inv.equip()
  robot.safeUp()
  robot.safeForward()
  robot.select(2)
  robot.placeDown()
  robot.safeBack(2)
  robot.safeDown()
  robot.select(4)
  robot.place(sides.front)
  robot.safeUp()
  robot.safeForward(2)
  robot.swingDown()
  robot.drop()
  robot.select(2)
  robot.drop()
  
  robot.goHome()
  local seedArray = get80Seeds()
  
  robot.goTo(plotSpot.x-4, plotSpot.y+1, plotSpot.z+1)
  robot.turnToSide(sides.east)
  hoeDown()
  
  robot.goTo(plotSpot.x-4, plotSpot.y+1, plotSpot.z-1)
  os.sleep(5)
  robot.goHome()

  local plot = getPlotVar(seedArray)
  appendPlotPos(plotSpot)
  txt.savePlot(plot)
  signals.sendFile("/home/plots/plot" .. txt.getNumPlots())
  os.sleep(0.2)
  signals.sendFile("/home/plotPos")
  os.sleep(0.2)
  signals.send("robot All done!")
end

-- turns the message into instructions with ixs and nums to be replaced
function getInstructions(msg)
  local instructions = {}
  instructions.ixs = {}
  instructions.nums = {}
  for ix = 1,(#msg-1)/2 do
    instructions.ixs[ix] = tonumber(msg[ix*2])
    instructions.nums[ix] = tonumber(msg[ix*2+1])
  end
  return instructions
end

function plotToEdit(instructions, n)
  local plotHist = txt.getPlotSeeds(n)
  
  for k,v in pairs(plotHist) do
    for ix = 1,#instructions.ixs do
      if (tonumber(k) == instructions.ixs[ix]) then
        return true
      end
    end
  end
  return false
end

-- returns true if seed is in instructions (and there are more of that seed to replace)
function seedInInstructions(instructions, seedIx)
  for ix = 1,#instructions.ixs do
    if ( (instructions.ixs[ix] == seedIx) and (instructions.nums[ix] ~= 0) ) then
      return ix
    end
  end
  return false
end

-- returns array pos[plotIx][tileIx] with pos and ix fields and 
function getReplaceLocations(instructions)
  local pos = {}
  local plot = {}
  
  local tileIx = 1
  local editPlot = false
  local seedIx = false
  for n = 1, txt.getNumPlots() do
    pos[n] = {}
    tileIx = 1
    editPlot = plotToEdit(instructions, n)
    if editPlot then
      plot = txt.getPlotSeedsAndPos(n)
      for rowIx = 1,9 do
        for colIx = 1,9 do
          seedIx = seedInInstructions(instructions, plot[rowIx][colIx])
          if seedIx then
            pos[n][tileIx] = {}
            instructions.nums[seedIx] = instructions.nums[seedIx] - 1
            pos[n][tileIx].ixs = {rowIx, colIx}
            tileIx = tileIx + 1
          end
        end
      end
    end
  end
  
  for k,v in pairs(pos) do
    if #pos[k] == 0 then
      pos[k] = nil
    end
  end
  
  local plotPosition = {}
  local tileRelPos = {}
  for k,v in pairs(pos) do
    plotPosition = txt.getPlotPos(k)
    for ix = 1,#pos[k] do
      tileRelPos = txt.getTilePos(pos[k][ix].ixs[1], pos[k][ix].ixs[2])
      pos[k][ix].pos = {}
      pos[k][ix].pos.x =  plotPosition.x + tileRelPos.x
      pos[k][ix].pos.y =  plotPosition.y + tileRelPos.y + 1
      pos[k][ix].pos.z =  plotPosition.z + tileRelPos.z
    end
  end
  return pos
end

function getAvailableSeeds()
  robot.turnToSide(sides.north)
  
  local availableSeeds = {}
  local slotIx = 1
  local item = {}
  for ix = 1,54 do
    item = inv.getStackInSlot(sides.front, ix)
    if item then
      availableSeeds[slotIx] = item
      availableSeeds[slotIx].slot = ix
      slotIx = slotIx + 1
      if (not txt.check(item.name)) then
        txt.add(item.name)
      end
    end
  end
  signals.sendFile("/home/seeds")
  return availableSeeds
end

function pickupSeeds(locIx, location, availableSeeds)
  robot.goHome()
  robot.turnToSide(sides.north)
  local maxSeeds = #location
  local currentSlot = robot.select()
  local slotsFilled = 0
  local slotSize = 0
  robot.select(9)
  for ix = locIx,#availableSeeds do
    if slotsFilled == 4 then
      robot.select(currentSlot)
      return true -- slots are full more can pick up more seeds later
    end
    
    if availableSeeds[ix].size ~= 0 then
      slotsFilled = slotsFilled + 1
      inv.suckFromSlot(sides.front, ix, maxSeeds)
      maxSeeds = maxSeeds - (inv.getStackInInternalSlot() or {size=0}).size
      availableSeeds[ix].size = availableSeeds[ix].size - inv.getStackInInternalSlot().size
      robot.select(robot.select()+1)
    end
    if maxSeeds == 0 then
      robot.select(currentSlot)
      return true -- return true so it's indicated that there's more seeds for the next plot
    end
  end
  robot.select(currentSlot)
  return false -- no more seeds to pick up
end

function getSeedTypeIxs(allSeedTypes)
  local seedIxs = {}
  local currentSlot = robot.select()
  robot.select(9)
  local item = inv.getStackInInternalSlot(9)
  while item do
    for ix = 1,#allSeedTypes do
      if ( item and (allSeedTypes[ix] == item.name)) then
        table.insert(seedIxs, ix)
      end
    end
    robot.select(robot.select()+1)
    item = inv.getStackInInternalSlot(robot.select())
  end
  robot.select(currentSlot)
  return seedIxs
end

function plantSeed(plot, tileIxs, seedTypeIxs, canPlant)
  local curSlot = robot.select()
  robot.select(8) robot.select(7) robot.select(6) robot.select(5) 
  robot.swingDown()
  robot.select(curSlot)
  robot.useDown()
  local item = {}
  if canPlant then
    item = inv.getStackInInternalSlot(robot.select())
    while ( (not item) and (robot.select() < 13) ) do
      robot.select(robot.select() + 1)
      item = inv.getStackInInternalSlot(robot.select())
      
      if robot.select() == 13 then
        plot[tileIxs[1]][tileIxs[2]] = 1
        canPlant = false
        return canPlant
      end
    end
    plot[tileIxs[1]][tileIxs[2]] = seedTypeIxs[robot.select()-8]
    robot.placeDown()
    print("planted, " .. seedTypeIxs[robot.select()-8])
  else
    plot[tileIxs[1]][tileIxs[2]] = 1
  end
  return canPlant
end

function replaceSeeds(msg)
  local instructions = getInstructions(msg) -- removes "replace" from array
  local locations = getReplaceLocations(instructions)
  
  local plot = {}
  local availableSeeds = getAvailableSeeds()
  local seedFlag = false
  local seedTypeIxs = {}
  local canPlant = true
  local plotPos = {}
  local allSeedTypes = txt.getAllSeedTypes()
  
  for k,v in pairs(locations) do
    print(k)
  end
  
  for k,v in pairs(locations) do
    plotPos = {}
    canPlant = true
    robot.select(9)
    plot = txt.getPlotSeedsAndPos(k)
    seedFlag = pickupSeeds(1, locations[k], availableSeeds) -- if seedFlag then pick up more seeds when empty
    seedTypeIxs = getSeedTypeIxs(allSeedTypes)
    for ix = 1,#seedTypeIxs do
      print(seedTypeIxs[ix])
    end
    for ix = 1,#allSeedTypes do
      print(allSeedTypes[ix])
    end
    
    robot.goTo(locations[k][1].pos)
    for ix = 1,#locations[k] do
      robot.goToUnsafe(locations[k][ix].pos)
      canPlant = plantSeed(plot, locations[k][ix].ixs, seedTypeIxs, canPlant)
      
      print(canPlant, seedFlag)
      if ( (not canPlant) and seedFlag) then
        seedFlag = pickupSeeds(ix, locations[k], availableSeeds)
        seedTypeIxs = getSeedTypeIxs(allSeedTypes)
        canPlant = true
        robot.goTo(locations[k][ix].pos)
      end
    end
    plotPos = txt.getPlotPos(k)
    plotPos.y = plotPos.y + 1
    plotPos.z = plotPos.z - 1
    robot.goTo(plotPos)
    os.sleep(5)
    robot.goHome()
    txt.savePlot(plot, k)
    signals.sendFile("/home/plots/plot" .. k)
  end
  signals.send("robot All done!")
end

function main()
  local msg = txt.split(signals.getMessage(), " ")
  
  for ix = 1,#msg do print(msg[ix]) end
  
  if (msg[1] == "new") then
    newPlot()
  end
  
  if (msg[1] == "replace") then
    print("replacing")
    replaceSeeds(msg)
  end
  
end

if (not m.isOpen(comport)) then m.open(comport) end

events = {}
table.insert(events, {"energy", refuel}) event.listen("energy", refuel)
table.insert(events, {"interrupted", interrupted}) event.listen("interrupted", interrupted)
table.insert(events, {"modem_message", signals.modem_message}) event.listen("modem_message", signals.modem_message)

robot.select(1)
robot.goHome()
while true do os.sleep(0.1) main() end

--thr["main"] = thread.create(function() while true do os.sleep(0.1) main() end end)