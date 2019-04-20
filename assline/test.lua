local component = require "component"
local sides = require "sides"
local serialization = require "serialization"

local databaseAddress = component.get("0a091528")
local tempDatabaseAddress = component.get("6b0d1ea8")
local tempDb = component.proxy(tempDatabaseAddress)
local mainDb = component.proxy(databaseAddress)
local buses = dofile("/usr/buses")
local trans = dofile("/usr/trans")
local ftrans = dofile("/usr/ftrans")

local t = component.proxy("5259b3cf-1cf4-4a29-8709-e04a40007f40") -- main trasposer, near the AE interface
local mainRedstoneAddress = "5bb9cf81-10b0-4295-b5f1-438064c6ee8b" 
local detectorRedstoneAddress = "9cb54ff6-3aa6-468c-802b-93090d61571a" -- redstone IO near the interface
local assline = component.proxy( "4b661686-3021-47d8-ae38-3d6ddc22dd37")

local recipeFile = io.open("/usr/recipes.txt", "r")
if not recipeFile then error("No recipes") end
local recipes = serialization.unserialize(recipeFile:read("*all"))
recipeFile:close()
function findRecipe(key)
	if (key < 1) then return nil end
	for i=1,#recipes do
		if (recipes[i][1][1][1] == key) then
			return recipes[i]
		end
	end
	return nil;
end
local recipe = nil
function refreshRecipe()
	t.store(sides.north, 1, tempDatabaseAddress, 1)
	local index = mainDb.indexOf(tempDb.computeHash(1))
	print ("Item index = " .. index)
	recipe = findRecipe(index)
	if not recipe then
		print ("No encoded recipe for " .. t.getStackInSlot(sides.north, 1).label)
		return false
	end
	return true
end

refreshRecipe()

local bus = component.proxy(buses[3])
bus.setExportConfiguration(sides.north, 1, databaseAddress, recipe[1][3][1])
local n = bus.exportIntoSlot(sides.north,1)
print (n)

