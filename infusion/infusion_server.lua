local component = require "component"
local event = require "event"

local running = true

function unknownEvent() end
 
local myEventHandlers = setmetatable({}, { __index = function() return unknownEvent end })
 
function myEventHandlers.key_up(adress, char, code, playerName)
  if (char == char_space) then
    running = false
  end
end

function myEventHandlers.interrupted(uptime)
	running = false
end

function myEventHandlers.redstone_changed(address, side, oldValue, newValue)
	if address == "ba247c8c-6150-4229-8d1b-f4cdba7868fa" and newValue > 0 then 
		dofile("infuse.lua")
	end
end
 
function handleEvent(eventID, ...)
  if (eventID) then
    myEventHandlers[eventID](...)
  end
end

function reportStatus()
end



while running do
	reportStatus()
	handleEvent(event.pull(15))
end
