--[[
This is a simple program that allows for transfer of a file over an OC network. Pronounced gift, stands for gangsir file transfer.
The program is composed of two sub-programs, for receiving and sending. The first argument should be which action
to take, the second is the file to send/receive to.
example:
gft send "/path/to/file.txt"
Uses port 20 by default, the standard for FTP.
By default, it can send files up to about 8190 characters, about the size of a small essay.
--]]


local component = require("component")
local io = require("io")
if not component.isAvailable("modem") then error("A network card is required for this program. Please install.") end
local modem = component.modem
local port = 69 --port to use for transfer and getting

modem.open(port)

local args = {...} --{send/receive,filename}
if args[1] == nil then error("Provide function of program in first arg, send or receive.") end


if args[1] == "send" then
  if args[2] == nil then error("Provide filesystem path to file to send.") end
  local fileSendInitial = assert(io.open(args[2],"r"),"Failed to open existing file to send.")
  local sendString = fileSendInitial:read("*a") --reads the entire file into one gigantic string
  modem.broadcast(port,tostring(sendString)) --broadcasts the string on the set port.
  fileSendInitial:close()
end

if args[1] == "receive" then
  if args[2] == nil then error("Provide filesystem path to file to create on receive.") end
  local _,_,sender,_,_,receivedFileData = require("event").pull("modem_message")
  local fileReceiveFinal = assert(io.open(args[2],"w"),"Failed to open new file to receive into.")
  fileReceiveFinal:write(receivedFileData) --writes the receivedFileData to file.
  fileReceiveFinal:flush() --ensure all data is written and saved.
  fileReceiveFinal:close()
end
modem.close(port)

--eof