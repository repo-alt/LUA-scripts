local component = require "component"
local event = require "event"
local meController = component.me_controller
local valuesToUpkeep = dofile("/usr/valuesToUpdate")
_G.craftingJobs = {}
if _G.valuesUpdater then
	event.cancel(_G.valuesUpdater)
	_G.valuesUpdater = nil
end

function log(s)
	local file = io.open("/log/crafting.log", "a")
	file:write(os.date())
	file:write(" ")
	file:write(s)
	file:write("\n")
	file:close()
end

local function getFreeCpus()
	local cpus = meController.getCpus()
	local freeCpus = 0
	for _, c in ipairs(cpus) do
		if not c.busy then 
			freeCpus = freeCpus + 1 
		end
	end
	return freeCpus
end

local function updateItems()
	local freeCpus = getFreeCpus()
	for _, value in ipairs(valuesToUpkeep) do
		if freeCpus < 2 then break end
		local job = _G.craftingJobs[value[1]] -- check current crafting status for that item
		if job and (job.isDone() or job.isCanceled()) then 
			_G.craftingJobs[value[1]] = nil
			job = nil
		end
		if job == nil then
			local data = meController.getItemsInNetwork(value[2])	
			if data.n == 0 or (data[1].size < value[3]) then
				local n = value[3]
				if (data.n > 0) then n = n - data[1].size end
				log("Crafting " .. n .. " " .. value[1])
				local request = meController.getCraftables(value[2])
				if request ~= nil and request.n > 0 then
					freeCpus = freeCpus - 1
					_G.craftingJobs[value[1]] = request[1].request(n)
				else
					log("Crafting recipe for " .. value[1] .. " not found.")
				end
			end
		end
	end
end

updateItems()

_G.valuesUpdater = event.timer(300, updateItems, math.huge)
