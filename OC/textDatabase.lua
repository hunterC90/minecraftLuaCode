local component = require("component")
local io = require("io")
local filesystem = require("filesystem")

textDatabase = {}

-- Splits string into array according to sep
function split(str, sep) 
  local sep, fields = sep or ":", {} 
  local pattern = string.format("([^%s]+)", sep) 
  str:gsub(pattern, function(c) fields[#fields+1] = c end) 
  return fields 
end

-- Splits string into array according to sep
function textDatabase.split(str, sep) 
  local sep, fields = sep or ":", {} 
  local pattern = string.format("([^%s]+)", sep) 
  str:gsub(pattern, function(c) fields[#fields+1] = c end) 
  return fields 
end

function textDatabase.getSeedName(str)
  return string.sub(str, 1+string.find(str, ":"), string.len(str))
end

--returns a histogram of all seeds in the plot
function hist2D(plotTbl)
  local hist = {}
  for ix1 = 1,#plotTbl do
    for ix2 = 1,#plotTbl[ix1] do
      if (plotTbl[ix1][ix2] ~= "0") then
        hist[tonumber(plotTbl[ix1][ix2])] = (hist[tonumber(plotTbl[ix1][ix2])] or 0) + 1
      end
    end
  end
  return hist
end

--[[
Returns a table of all seeds indexed by line in file
--]]
function textDatabase.getAllSeedTypes()
  local f = io.open("../home/seeds", "r")
  local seeds = {}
  
  local count = 0
  for line in f:lines() do
    count = count + 1
    seeds[count] = line
  end
  f:close()
  return seeds
end

-- Checks if a line exists in seeds.txt
function textDatabase.check(seedName)
  local f = io.open("../home/seeds", "r")
  
  for line in f:lines() do
    if line==seedName then
      f:close()
      return true
    end
  end
  f:close()
  return false
end

-- Appends line to the file
function textDatabase.add(seedName)
  local f = io.open("../home/seeds", "a")
  f:write(seedName .. "\n")
  f:flush()
  f:close()
end

-- returns the seeds in the plot in a 2D array
function textDatabase.getPlotSeedsAndPos(n)
  local plot = {}
  local f = io.open("../home/plots/plot" .. tostring(n), "r")
  
  local count = 0
  for line in f:lines() do
    count = count + 1
    plot[count] = split(line, " ")
    for ix = 1,9 do
      plot[count][ix] = tonumber(plot[count][ix])
    end
  end
  f:close()
  return plot
end

-- returns the seeds in the plot in a histogram
function textDatabase.getPlotSeeds(n)
  local plot = textDatabase.getPlotSeedsAndPos(n)
  return hist2D(plot)
end

--[[ 
returns all of the seeds present in all plots database order by plot and position
will return main table indexed by plot
--]]
function textDatabase.getAllSeedsAndPos()
  local plots = {}
  
  n = 0
  while (filesystem.exists("../home/plots/plot" .. tostring(n))) do
    n = n + 1
    plots[n] = textDatabase.getAllSeedsAndPos(n)
  end  
  return plots
end

--returns all of the seeds present in all plots in database order
function textDatabase.getAllSeeds()
  local n = 1
  local hist = {}
  local tempHist = {}
  while (filesystem.exists("../home/plots/plot" .. tostring(n))) do
    tempHist = textDatabase.getPlotSeeds(n)
    for k,v in pairs(tempHist) do
      hist[k] = (hist[k] or 0) + v
    end
    n = n + 1
  end
  return hist
end

-- Returns the number of plots
function textDatabase.getNumPlots()
  local n = 1
  while (filesystem.exists("/home/plots/plot" .. tostring(n))) do
    n = n + 1
  end  
  return n - 1
end

-- Saves new plot file or overwrites current one 
-- plot is a 2D array of rows and columns
function textDatabase.savePlot(plot, n)
  totalPlots = textDatabase.getNumPlots()
  n = n or (totalPlots + 1)
  
  local plotStr = "plot" .. n
  if (n <= totalPlots) then
    os.execute("rm /home/plots_old/" .. plotStr)
    os.execute("mv -f ../home/plots/" .. plotStr .. " /home/plots_old/" .. plotStr)
  end
  
  local f = io.open("../home/plots/" .. plotStr, "a")
  for ix1 = 1,9 do
    local str = ""
    for ix2 = 1,9 do
      str = str .. " " .. plot[ix1][ix2]
    end
    str = str .. "\n"
    f:write(str)
  end
  
  f:flush()
  f:close()
end

-- returns the position of the farmer relative to the home
function textDatabase.getPlotPos(n)
  local f = io.open("../home/plotPos", "r")
  local str = ""
  
  local count = 1
  for line in f:lines() do
    if (count == n) then
      str = tostring(line)
      break
    end
    count = count + 1
  end
  
  local posTemp = split(str, " ")
  local pos = {}
  pos.x = tonumber(posTemp[1])
  pos.y = tonumber(posTemp[2])
  pos.z = tonumber(posTemp[3])
  
  f:close
  return pos
end

function textDatabase.getAllPlotsPos()
  local pos = {}
  local n = textDatabase.getNumPlots()
  
  for ix = 1,n do
    pos[ix] = textDatabase.getPlotPos(ix)
  end
  
  return pos
end

-- returns the position of the plot's tile relative to the farmer
function textDatabase.getTilePos(ix1, ix2)
  local relPos = {}
  relPos.x = ix2 - 5
  relPos.y = 0
  relPos.z = ix1
  
  return relPos
end

return textDatabase