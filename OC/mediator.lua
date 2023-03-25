event = require("event")
local signals = require("signals")
local comport = 69

message = ""

-- Splits string into array according to sep
function split(str, sep) 
  local sep, fields = sep or ":", {} 
  local pattern = string.format("([^%s]+)", sep) 
  str:gsub(pattern, function(c) fields[#fields+1] = c end) 
  return fields 
end

function main()
  local msg = signals.getMessage()
  local msgArray = split(msg, " ")
  
  if msgArray[1] == "robot" then
    if msgArray[2] == "transfer" then
      signals.sendComputer("robot " .. msgArray[2] .. " " .. msgArray[3])
      msg = signals.getMessage()
      os.sleep(0.1)
      signals.sendComputer("robot " .. msg)
    else
      os.sleep(0.1)
      signals.sendComputer(msg)
    end
  elseif msgArray[1] == "computer" then
    if msgArray[2] == "transfer" then
      signals.sendRobot("computer " .. msgArray[2] .. " " .. msgArray[3])
      msg = signals.getMessage
      os.sleep(0.1)
      signals.sendRobot("computer " .. msg)
    else
      os.sleep(0.1)
      signals.sendRobot(msg)
    end
  else
    print("I don't know who this message is from!")
    os.exit()
  end
end

events = {}
table.insert(events, event.listen("modem_message", signals.modem_message))

if (not m.isOpen(comport)) then m.open(comport) end
while true do
  os.sleep(0.1)
  main()
end