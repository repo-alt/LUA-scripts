local component = require("component")
local event = require("event")
local m = component.modem
local me = component.me_controller

local function hasFreeCpus(meController)
	local cpus = meController.getCpus()
	for _, c in ipairs(cpus) do
		if not c.busy then 
			return true
		end
	end
	return false
end

local function modem_handler(id, to, from, port, dist, message, name, damage, count)
	print ("Got message " .. id .. " to: " .. to .. "from: " .. from .. "port: " .. toString(port) .. " message: " .. message)
	if message == "get-crafting" then
		m.send(from, 1200, "server-address")
	elseif message == "request" then
		while true do
			if not hasFreeCpus(me) then
				os.sleep(10)
			else
				local filter = {}
				filter.name = name
				filter.damage = damage
				print ("Got crafting request for " .. toString(count) .. " " .. name)
				local request = me.getCraftables(filter)
				if request ~= nil and request.n > 0 then
					local job = request[1].request(count)
					while not job.isDone() and not job.isCanceled() do
						os.sleep(2)
					end
					if (job.isDone()) then
						m.send(from, 1200, "ok")
					else
						m.send(from, 1200, "fail")
					end
				else
					m.send(from, 1200, "fail")
				end
			end
		end		
	end
end

m.open(1201)
while true do
	local id, to, from, port, dist, message, name, damage, count = event.pull()
	print (id)
	if (id == "interrupted") then break 
	elseif id == "modem" then
	end
end
