itemNBT = require("item")
component = require("component")
trs = component.transposer

function getProperties(item)
  return itemNBT.readTag(item).astralsorcery.crystalProperties
end