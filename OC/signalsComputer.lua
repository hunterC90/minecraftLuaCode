local tunnel = require("component").tunnel
local os = require("os")
local filesystem = require("filesystem")


signals = {}

function signals.send(str)
  
  tunnel.send("interrupt")
  os.sleep(0.2)
  tunnel.send("computer " .. str)
end

function signals.modem_message()
  event.ignore("modem_message", signals.modem_message)
  _, _, from, port, _, message = event.pull("modem_message")
  message = tostring(message)
  event.listen("modem_message", signals.modem_message)
end

function signals.getMessage()
  while message == "" do os.sleep(0.05) end
  
  local msg = message
  message = ""
  return msg
end

function signals.saveFile(filePath)
  if filesystem.exists(filePath) then
    os.execute("rm " .. filePath)
  end

  local receivedFileData = signals.getMessage()
  
  local fileReceiveFinal = assert(io.open(filePath,"w"),"Failed to open new file to receive into.")
  fileReceiveFinal:write(receivedFileData) --writes the receivedFileData to file.
  fileReceiveFinal:flush() --ensure all data is written and saved.
  fileReceiveFinal:close()
end

return signals