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
	if address == "9cb54ff6-3aa6-468c-802b-93090d61571a" and newValue > 0 then 
		dofile("assemble.lua")
	end
end
 
function handleEvent(eventID, ...)
  if (eventID) then
    myEventHandlers[eventID](...)
  end
end

while running do
	handleEvent(event.pull(15))
end
