local component = require "component"
local sides = require "sides"
local serialization = require "serialization"
local event = require("event")

local databaseAddress = component.get("0a091528")
local tempDatabaseAddress = component.get("6b0d1ea8")
local tempDb = component.proxy(tempDatabaseAddress) or error("no temp database!")
local mainDb = component.proxy(databaseAddress) or error("no main database!")
if tempDb == nil then  end
if mainDb == nil then  end
local buses = dofile("/usr/buses")
local trans = dofile("/usr/trans")
local fbuses = dofile("/usr/fbuses")
local ftrans = dofile("/usr/ftrans")
local me = component.me_controller

local t = component.proxy("118b16b2-5fd3-4e59-9034-268188d8be98") or error("no main transposer!") -- main trasposer, near the AE interface
local assline = component.proxy( "4b661686-3021-47d8-ae38-3d6ddc22dd37") or error("no assembly line adapter")

local itemBusSide = sides.north
local mainChestSide = sides.west
local extractorSide = sides.top
local cannerSide = sides.south

function readTable(file)
	local recipeFile = io.open(file, "r") or error("No recipes")
	local recipes = serialization.unserialize(recipeFile:read("*all"))
	recipeFile:close()
	return recipes
end

local recipes = readTable("/usr/recipes.txt")
local recipeMap = readTable("/usr/signatures.txt")

function calculateSignature()
	local key = ""
	for i=1,9 do 
		if not t.store(mainChestSide, i, tempDatabaseAddress, 1) then 
			print ("signature: ".. key)
			return key 
		end
		local idx = mainDb.indexOf(tempDb.computeHash(1))
		if (idx < 1) then 
			print ("Component " .. i .. "not in database")
			return nil 
		end
		key = key .. idx
	end
	print ("signature: ".. key)
	return key
end

function findRecipe(key)
	if not key then return nil end
	local i = recipeMap[key]
	if not i then return nil end
	return recipes[i]
end

function waitForMachine()
	while not assline.isMachineActive() do
		if event.pull(1, "interrupted") then return false end
	end
	while assline.isMachineActive() do
		os.sleep(2)
	end
	return true
end

local modem = component.modem
local local_port = 1200
local server_port = 1201

function requestCrafing(item, amount)
	if not _G.crafting_server then return false end
	modem.open(local_port)
	modem.send(_G.crafting_server, server_port, "request", item.name, item.damage, amount)
	print("Requesting " .. amount .. " of " .. item.label)
	local result = false
	while true do
		local id, _, _, p, _, message = event.pullMultiple("modem_message", "interrupted")
		if id == "interrupted" then
			break
		elseif id == "modem_message" and p == local_port then
			print("Request result: " .. message)
			if message == "ok" then	result = true end
			break;
		end
	end
	modem.close(local_port)
	return result
end

function craftCells(filter, count)
	local request = me.getCraftables({name=filter.name, damage=filter.damage})
	if request ~= nil and request.n > 0 then
		local job = request[1].request(count)
		if job.isDone() or job.isCanceled() then
			print("invalid job")
		end
		while not job.isDone() and not job.isCanceled() do
			os.sleep(1)
		end
	else
		print("Invalid cell request name = " .. filter.name .. "damage = " .. tostring(filter.damage))
	end
end

function clearFluids()
	for i = 1,4 do
		local tr = component.proxy(ftrans[i])
		local n = tr.getFluidInTank(sides.south,1).amount
		if (n > 0) then
			tr.transferFluid(sides.south, sides.north, n)
		end
	end
end

function clearInput()
	for i = 2,9 do
		if t.getSlotStackSize(mainChestSide, 1) > 0 then return end
		local n = t.getSlotStackSize(mainChestSide, i)
		if n > 0 then 
			t.transferItem(mainChestSide, sides.down, n, i)
		end
	end
end

while t.getSlotStackSize(mainChestSide, 1) > 0 do
	local recipe = findRecipe(calculateSignature())
	if not recipe then 
		print ("No encoded assembly recipe for current request")
		break
	end
	-- push items
	for i=#recipe[1],1,-1 do
		local bus = component.proxy(buses[i])
		local tr = component.proxy(trans[i])
		bus.setExportConfiguration(itemBusSide, 1, databaseAddress, recipe[1][i][1])
		local requiredAmount = recipe[1][i][2] 
		while tr.getSlotStackSize(sides.down,1) < requiredAmount do
			if not bus.exportIntoSlot(itemBusSide,1) then
				if not requestCrafing(mainDb.get(recipe[1][i][1]), requiredAmount - tr.getSlotStackSize(sides.down,1)) then
					print ("Not enough " .. mainDb.get(recipe[1][i][1]).label)
					return
				end
			end
		end
		local n = tr.getSlotStackSize(sides.down,1)
		if n < requiredAmount then
			return
		elseif n > requiredAmount then
			tr.transferItem(sides.down, sides.north, n-requiredAmount)
			os.sleep(2)
		end
	end
	-- push fluids
	for i=1, #recipe[2] do
		local bus = component.proxy(fbuses[i])
		local cells = recipe[2][i][3]
		local key = recipe[2][i][1]
		local amount = recipe[2][i][2]
		local s = extractorSide
		if cells then
			s = cannerSide
			craftCells(mainDb.get(key), amount)
		end
        bus.setExportConfiguration(s, 1, databaseAddress, key)
		for j = 1,amount do
			if not bus.exportIntoSlot(s,5) then
				if cells then 
					print("not enough cells")
					return
				else
					if not requestCrafing(mainDb.get(key), amount - j + 1) then
						print ("Not enough " .. mainDb.get(key).label)
						return
					end
				end
			end
		end
	end
	-- transfer ready items into buses
	for i=#recipe[1],1,-1 do
		component.proxy(trans[i]).transferItem(sides.down, sides.up, recipe[1][i][2])
	end
	for i=1, #recipe[2] do
		local amount = recipe[2][i][2]
		if recipe[2][i][3] then 
			amount = amount*1000
		else
			amount = amount*144
		end
		component.proxy(ftrans[i]).transferFluid(sides.down, sides.south, amount)
	end

	if waitForMachine() then 
		print("Crafting ok") 
		clearFluids()
		clearInput()
	end
end
