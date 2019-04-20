local component = require "component"
local sides = require "sides"
local serialization = require "serialization"

local databaseAddress = component.get("500f167d")
local tempDatabaseAddress = component.get("8f101f02")
local tempDb = component.proxy(tempDatabaseAddress)
local mainDb = component.proxy(databaseAddress)

local t_key = component.proxy("68b881c0-dab8-4a4d-81ab-2d7cfbe92ddb")
local t_input = component.proxy("9d217d1e-2ac6-4bc3-8b8c-9625d1f99f07")
local altarSide = sides.south
local keyChestSide = sides.east
local interfaceChest = sides.west
local inputChest = sides.east
local resultChest = sides.down
local outChest = sides.west

local recipeFile = io.open("/usr/alchemy_recipes.txt", "r")
if not recipeFile then error("No recipes") end
local recipes = serialization.unserialize(recipeFile:read("*all"))
recipeFile:close()

function findRecipe(key)
	if (key < 1) then return nil end
	for i=1,#recipes do
		if (recipes[i][1] == key) then
			return recipes[i]
		end
	end
	return nil;
end
local recipe = nil
function refreshRecipe()
	t_input.store(interfaceChest, 1, tempDatabaseAddress, 1)
	recipe = findRecipe(mainDb.indexOf(tempDb.computeHash(1)))
	if not recipe then
		print ("No encoded recipe for " .. t_input.getStackInSlot(interfaceChest, 1).label)
		return false
	else
		print ("Key:" .. tempDb.get(1).label)
		print ("Recipe: " .. recipe[1] .. " -> " .. recipe[2])
	end
	return true
end


function clearAltar()
	t_key.transferItem(altarSide, keyChestSide, 1)
end

function putKey(key)
	for i=1,27 do
		if t_key.compareStackToDatabase(keyChestSide, i, databaseAddress, key) then 
			t_key.transferItem(keyChestSide, altarSide, 1, i, 1)
			break
		end
	end
end

function transferInput()
	for i=1,5 do
		local n = t_input.getSlotStackSize(interfaceChest,i)
		if n > 0 then t_input.transferItem(interfaceChest, inputChest, n, i) end
	end
end

function isCurrentInputActive()
	return t_input.compareStackToDatabase(interfaceChest, 1, tempDatabaseAddress, 1)
end

refreshRecipe()

while t_input.getSlotStackSize(interfaceChest, 1) > 0 do
	if (not isCurrentInputActive()) and (not refreshRecipe()) then break end
	print ("Achemy: " .. mainDb.get(recipe[2]).label)
	if t_key.getSlotStackSize(altarSide, 1) == 0 then
		putKey(recipe[2])
	elseif not t_key.compareStackToDatabase(altarSide, 1, databaseAddress, recipe[2]) then
		clearAltar()
		putKey(recipe[2])
	end
	transferInput()
	while t_key.getSlotStackSize(resultChest, 1) == 0 do os.sleep(1) end
	t_key.transferItem(resultChest, outChest, t_key.getSlotStackSize(resultChest, 1), 1)
	local n = t_key.getSlotStackSize(resultChest, 2)
	if n > 0 then t_key.transferItem(resultChest, outChest, n, 2) end
end
