local sides = require("sides")
local component = require("component")
local tunnel = component.tunnel
local trs = component.transposer
local trsGet = sides.bottom
local trsPut = sides.top
local io = require("io")
local event = require("event")
local thread = require("thread")
local os = require("os")
local shell = require("shell")
local txt = require("textDatabase")
local computer = require("computer")
local db = component.database
local export = component.me_exportbus
local exportSide = sides.top
local int = component.me_interface

dbItems = {}
for ix = 1,5 do
  dbItems[ix] = db.get(ix)
  dbItems[ix].size = nil
  dbItems[ix].aspects = nil
end

message = ""

-- Splits string into array according to sep
function split(str, sep) 
  local sep, fields = sep or ":", {} 
  local pattern = string.format("([^%s]+)", sep) 
  str:gsub(pattern, function(c) fields[#fields+1] = c end) 
  return fields 
end

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

function getItems(item, n)
  n = n or 1
  local itemsAvail = int.getItemsInNetwork(item)[1]
  if itemsAvail == nil then
    itemsAvail = {size=0}
  end
  
  if (itemsAvail.size < n) then
    local itemCrafter = int.getCraftables(item)[1]
    local craftTracker = itemCrafter.request(n-itemsAvail.size)
    if craftTracker.isCanceled() then return false end
    
    while (not craftTracker.isDone()) do os.sleep(0.05) end
    return true
  else
    return true
  end
    
end

function checkConsumables()
  local itemDucts = trs.getStackInSlot(trsPut, 1)
  local charcoal = trs.getStackInSlot(trsPut, 2)
  
  if itemDucts == nil then itemDucts = {size=0} end
  if charcoal == nil then charcoal = {size=0} end
  
  if itemDucts.size < 64 then
    getItems(dbItems[1], 64-itemDucts.size)
    export.setExportConfiguration(exportSide, 1, db.address, 1)
    for ix = 1,64-itemDucts.size do
      export.exportIntoSlot(exportSide, 1)
    end
    trs.transferItem(trsGet, trsPut, 64, 1, 1)
  end
  if charcoal.size < 64 then
    getItems(dbItems[5], 64-charcoal.size)
    export.setExportConfiguration(exportSide, 1, db.address, 5)
    for ix = 1,64-charcoal.size do
      export.exportIntoSlot(exportSide, 2)
    end
    trs.transferItem(trsGet, trsPut, 64, 2, 2)
  end
  
end

function printHelp()
  print("queue n - adds n or 1 automated farmer, sprinkler, and water bucket to the queue     of farmers to add")
  print("checkQueue - gets the amount of farmers that can be placed")
  print("newPlot n - creates n or 1 new plots if there is that many queued")
  print("checkPlot n - displays all the seeds (and dirt) in a particular plot as a            histogram")
  print("checkAllPlots - displays all seeds in all plots as a histogram")
  print("replace l1 m1 l2 m2 ... ln m2 - Replace m amount of l seeds for n seeds types        with available seeds")
  print("getAllSeeds - display a list of all the seeds in the database")
  print("exit (or ctrl+c) - exits program")
  print("cls - os.execute(\"cls\")")
end

function queue(n)

  checkConsumables()

  n = n or 1
  local ix = 0
  
  local currentQueue = checkQueue()
  if currentQueue == 49 then
    print("Max queue of 64 already achieved")
  elseif (n + currentQueue >= 49) then
    print("Current queue + n >= 49. Current queue is " .. checkQueue())
  end
  
  local craftFlag = true
  
  for ix =2,4 do
    craftFlag = getItems(dbItems[ix], n)
    if not craftFlag then 
      print("Unable to queue " .. n .. " farming sets!")
      return false
    end
  end
  
  for ix =2,3 do
    export.setExportConfiguration(exportSide, 1, db.address, ix)
    for nix = 1,n do
      export.exportIntoSlot(exportSide, ix+1)
    end
  end
  
  ix = 4
  export.setExportConfiguration(exportSide, 1, db.address, ix)
  for nix = 1,n do
    export.exportIntoSlot(exportSide, ix+nix)
  end
  
  ix = 3
  while (trs.transferItem(trsGet, trsPut, 64, ix, ix) ~= 0.0) do 
    ix = ix + 1
  end
  
  local ixPut = 5
  while (trs.getStackInSlot(trsPut, ixPut)) do 
    ixPut = ixPut + 1
  end
  
  while (trs.transferItem(trsGet, trsPut, 64, ix, ixPut) ~= 0.0) do 
    ix = ix + 1
    ixPut = ixPut + 1
  end
  
end

function checkQueue()
  local item = trs.getStackInSlot(trsPut, 3)
  if item == nil then
    return 0
  else
    return item.size
  end
end

function newPlot(n)
  n = n or 1
  if n < checkQueue() then 
    print("There are only " .. checkQueue() .. " farmers queued!")
    return false
  end
  
  signals.send("new " .. n)
  local msg = signals.getMessage()
  if msg == "no" then print("Robot doesn't want to for some reason :(") return 0 end
  signals.send("okay")
  msg = signals.getMessage()
  while msg == "transfer" do
    signals.saveFile(split(msg, " ")[2])
  end
  
  print("plots successfully created!")
end

function checkPlot(n)
  local numPlots = tonumber(txt.getNumPlots())

  if ( n == nil or n > numPlots ) then print("Enter a valid number between 1 and " .. numPlots .. " (inclusive)") return 0 end
  
  local plotHist = txt.getPlotSeeds(n)
  local seedTypes = txt.getAllSeedTypes()
  for k,v in pairs(plotHist) do 
    print(k, txt.getSeedName(seedTypes[k]), v) 
  end
end

function checkAllPlots()
  local plotHist = txt.getAllSeeds()
  local seedTypes = txt.getAllSeedTypes()
  for k,v in pairs(plotHist) do 
    print(txt.getSeedName(k, seedTypes[k]),v) 
  end
end

function replaceSeed(str)
  local allSeeds = txt.getAllSeeds()
  local allSeedTypes = txt.getAllSeedTypes()
  
  local strArray = split(str, " ")
  
  for ix = 1,(#strArray-1)/2 do
    if (allSeeds[strArray[ix*2]] <= strArray[ix*2+1]) then
      print("Cannot Replace " .. txt.getSeedName(allSeedTypes[strArray[ix*2]]) )
      print("Tried replacing " .. strArray[ix*2+1] " when there is " .. allSeeds[strArray[ix*2]])
      return false
    end
  end
  
  signals.send(str)
  local msg = signals.getMessage()
  if msg == "no" then print("Robot doesn't want to for some reason :(") return 0 end
  signals.send("okay")
  msg = signals.getMessage()
  while msg == "transfer" do
    signals.saveFile(split(msg, " ")[2])
  end
  
  print("plots successfully created!")
end

function getAllSeeds()
  for k,v in pairs(txt.getAllSeedTypes()) do
    print(k, v)
  end
end

function exitFarmer()
  computer.pushSignal("interrupted")
end

function main()
  local str = io.read()
  local strArray = {}
  local strArray = split(str, " ")
  
  if strArray[1] == "help" then
    printHelp()
  elseif strArray[1] == "queue" then
    queue(tonumber(strArray[2]))
  elseif strArray[1] == "checkQueue" then
    print(checkQueue())
  elseif strArray[1] == "newPlot" then
    newPlot(tonumber(strArray[2]))
  elseif strArray[1] == "checkPlot" then
    checkPlot(tonumber(strArray[2]))
  elseif strArray[1] == "checkAllPlots" then
    checkAllPlots()
  elseif strArray[1] == "replace" then
    replaceSeed(str)
  elseif strArray[1] == "getAllSeeds" then
    getAllSeeds()
  elseif strArray[1] == "exit" then
    exitFarmer()   
  elseif strArray[1] == "cls" then
    os.execute("cls")
  else
    print("Command not recognized - type help to see a list of commands")
  end
  
end

thr = {}
events = {}
table.insert(events, {"interrupted", interrupted}) event.listen("interrupted", interrupted)

while true do main() end

--thr["main"] = thread.create(function() while true do os.sleep(0.1) main() end end)