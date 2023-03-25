local component = require("component")
local tunnel = component.tunnel
m = component.modem
local comport = 69
local os = require("os")

signals = {}

function getStrFromComputer(str)
  local _,n = string.find(str, "computer")
  return string.sub(str, 2+n, string.len(str))
end

function getStrFromRobot(str)
  local _,n = string.find(str, "robot")
  return string.sub(str, 2+n, string.len(str))
end

function signals.sendRobot(str)
  if (not m.isOpen(comport)) then m.open(comport) end
  m.broadcast(comport, "interrupt")
  os.sleep(0.2)
  m.broadcast(comport, getStrFromComputer(str))
end

function signals.sendComputer(str)
  event.ignore("modem_message", signals.modem_message)
  tunnel.send("interrupt")
  os.sleep(0.2)
  tunnel.send(getStrFromRobot(str))
  event.listen("modem_message", signals.modem_message)
end

function signals.modem_message()
  event.ignore("modem_message", signals.modem_message)
  _, _, from, port, _, message = event.pull("modem_message")
  message = tostring(message)
  event.listen("modem_message", signals.modem_message)
end

function signals.getMessage()
  if (not m.isOpen(comport)) then m.open(comport) end

  while message == "" do  os.sleep(0.1) end
  
  local msg = message
  message = ""
  return msg
end

return signals