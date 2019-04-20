local component = require "component"
local sides = require "sides"
local serialization = require "serialization"
local me = component.me_controller

local databaseAddress = component.get("3e342b1d")
local tempDatabaseAddress = component.get("55012883")
local tempDb = component.proxy(tempDatabaseAddress)
local mainDb = component.proxy(databaseAddress)
local buses = dofile("/usr/buses")

local t = component.proxy("3d5778e5-b3a3-44cc-aa09-e6886eb8fe2c") -- main trasposer, near the AE interface
local mainBus = "35d6692b-4d90-4715-9154-731f8803daa1"            -- center pedestal bus
local mainBusSide = sides.up

local clawRedstoneAddress = "f92c8dae-9153-46af-93af-06507f55e753" 
local centerPedestalTransposerAddress = "b0980aa1-c9a2-4ce4-8b2b-dad977dde255"
local detectorRedstoneAddress = "ba247c8c-6150-4229-8d1b-f4cdba7868fa" -- redstone IO near the interface that also controls pedestal clearing
local clawAcceleratorAddress = "dd60c4c8-83b9-4666-b3b6-59911b8b6ee8"

function activateClaw()
	local rs = component.proxy(clawRedstoneAddress)
	rs.setOutput(sides.north, 15)
	rs.setOutput(sides.north, 0)
end

function switchAccelerator(level)
	local rs = component.proxy(clawRedstoneAddress)
	rs.setOutput(sides.down,level)
	rs = component.proxy(clawAcceleratorAddress)
	rs.setOutput(sides.east,level)
end

function clearPedestals()
	local rs = component.proxy(detectorRedstoneAddress)
	rs.setOutput(sides.down, 15)
	os.sleep(1)
	rs.setOutput(sides.down, 0)
end

local recipeFile = io.open("/usr/recipes.txt", "r")
if not recipeFile then error("No recipes") end
local recipes = serialization.unserialize(recipeFile:read("*all"))
recipeFile:close()

function findRecipe(key)
	if (key < 1) then return nil end
	for i=1,#recipes do
		if (recipes[i][1][1] == key) then
			return recipes[i]
		end
	end
	return nil;
end
local recipe = nil
function refreshRecipe()
	t.store(sides.west, 1, tempDatabaseAddress, 1)
	recipe = findRecipe(mainDb.indexOf(tempDb.computeHash(1)))
	if not recipe then
		print ("No encoded recipe for " .. t.getStackInSlot(sides.west, 1).label)
		return false
	end
	return true
end

local essentia_names = dofile("/usr/essentia_names.lua")

function checkEssentiaLevels(r)
	local res = true
	local e = me.getEssentiaInNetwork()
	local ei = {}
	for i=1,#e do
		ei[e[i].label] = e[i].amount
	end
    for k,v in pairs(r) do
		local name = essentia_names[k] .. " Gas"
		if not ei[name] or ei[name] < v then 
			print("Not enough " .. name)
			res = false
		end
	end
	return res
end


refreshRecipe()

while t.getSlotStackSize(sides.west, 1) > 0 do
	if (not t.compareStackToDatabase(sides.west, 1, tempDatabaseAddress, 1)) and (not refreshRecipe()) then break end
	if not checkEssentiaLevels(recipe[2]) then break end
	local currentBus = 1
	local crafting_request = {}
	for i=2,#recipe[1] do
		local bus = component.proxy(buses[currentBus][1])
		bus.setExportConfiguration(buses[currentBus][2], 1, databaseAddress, recipe[1][i])
		if not bus.exportIntoSlot(buses[currentBus][2],1) then
			local filter = mainDb.get(recipe[1][i])
			print ("Not enough " .. filter.label)
			table.insert(crafting_request, filter)
		else
			currentBus = currentBus+1
		end
	end

	if #crafting_request > 0 then
		clearPedestals()
		break
	else
		local bus = component.proxy(mainBus)
		bus.setExportConfiguration(mainBusSide, 1, databaseAddress, recipe[1][1])
		if not bus.exportIntoSlot(mainBusSide, 1) then error("Main pedestal was not cleared") end
		activateClaw()
		bus.setExportConfiguration(mainBusSide, 1, databaseAddress, 81)
		switchAccelerator(15)
		local mt = component.proxy(centerPedestalTransposerAddress)
		while mt.compareStackToDatabase(sides.east, 1, tempDatabaseAddress, 1) do
			os.sleep(5)
		end
		switchAccelerator(0)
		clearPedestals()
	end
end
