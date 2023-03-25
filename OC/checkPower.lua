local component = require("component")
local gen = component.generator
local os = require("os")
local computer = require("computer")

while true do
  os.sleep(1)
  if ( (computer.energy()/computer.maxEnergy() < 0.5) and (gen.count() == 0) ) then
    computer.pushSignal("energy")
  end
end