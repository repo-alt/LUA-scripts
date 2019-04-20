local component = require("component")
local event = require("event")
local m = component.modem -- get primary modem component
m.open(123)
print(m.isOpen(123)) -- true
-- Wait for a message from another network card.
local id, _, from, port, _, message = event.pullMultiple("modem_message", "interrupted")
if id == "modem_message" then
	print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
end

