if _G.crafting_server then return end
local component = require("component")
local event = require("event")
local m = component.modem
m.open(1200)
m.broadcast(1201, "get-crafting")
while not _G.crafting_server do
	local id, _, from, port, _, message = event.pullMultiple("modem_message", "interrupted")
	if id  == "interrupted" then
		break
	elseif id == "modem_message" and message and message == "server-address" then
		_G.crafting_server = from
		print ("Server address: " .. from)
	end
end
m.close(1200)
