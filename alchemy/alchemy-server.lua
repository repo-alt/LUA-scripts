local component = require("component")
local event = require("event")

function redstone_changed(id, address, side, oldValue, newValue)
	if address == "941f27b6-3c4d-4e14-92c1-83dbf99b9b75" and newValue > 0 then 
		dofile("alchemy.lua")
	end
end

event.listen("redstone_changed", redstone_changed)
