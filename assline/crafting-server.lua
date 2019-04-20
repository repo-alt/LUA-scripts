local component = require("component")
local event = require("event")
local m = component.modem
local me = component.me_controller

function hasFreeCpus(meController)
	local cpus = meController.getCpus()
	for _, c in ipairs(cpus) do
		if not c.busy then 
			return true
		end
	end
	return false
end

function modem_handler(id, to, from, port, dist, message, name, damage, count)
	if message == "get-crafting" then
		m.send(from, 1200, "server-address")
	elseif message == "request" then
		if _G.crafted_item and _G.crafted_item == name then return end
		while true do
			if not hasFreeCpus(me) then
				os.sleep(10)
			else
				local filter = {}
				filter.name = name
				filter.damage = damage
				print ("Got crafting request for " .. count .. " " .. name)
				local request = me.getCraftables(filter)
				if request ~= nil and request.n > 0 then
					local job = request[1].request(count)
					_G.crafted_item = name
					while not job.isDone() and not job.isCanceled() do
						os.sleep(2)
					end
					if (job.isDone()) then
						m.send(from, 1200, "ok")
					else
						m.send(from, 1200, "fail")
					end
					_G.crafted_item = nil
				else
					m.send(from, 1200, "fail")
				end
				break
			end
		end		
	end
end

m.open(1201)
event.listen("modem_message", modem_handler)
