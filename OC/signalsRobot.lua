m = require("component").modem
comport = 69
local os = require("os")
local io = require("io")

signals = {}

if (not m.isOpen(comport)) then m.open(comport) end

function signals.send(str)
  if (not m.isOpen(comport)) then m.open(comport) end
  
  m.broadcast(comport, "interrupt")
  os.sleep(0.2)
  m.broadcast(comport, str)
end

function signals.sendFile(filePath)
  local fileSendInitial = assert(io.open(filePath,"r"),"Failed to open existing file to send.")
  local sendString = fileSendInitial:read("*a") --reads the entire file into one gigantic string
  signals.send("robot transfer " .. filePath)
  os.sleep(0.2)
  signals.send(sendString)
end

function signals.modem_message()
  print("modem_message()")
  event.ignore("modem_message", signals.modem_message)
  print("ignoring event")
  _, _, from, port, _, message = event.pull("modem_message")
  print("got message")
  message = tostring(message)
  print(message)
  event.listen("modem_message", signals.modem_message)
  print("listening again")
end

function signals.getMessage()
  print("waiting for message")
  while message == "" do os.sleep(0.05) end
  
  local msg = message
  message = ""
  return msg
end

return signals