local component = require "component"
local sides = require "sides"
local serialization = require "serialization"

-- recipe encoding script prerequisites:
-- T3 database in some adapter (set databaseAddress below)
-- transposer (set transposerAddress below)
-- inventory with at least 16 slots at the side specified at 'chest' variable below

local databaseAddress = component.get("500f167d")
local transposerAddress = "9d217d1e-2ac6-4bc3-8b8c-9625d1f99f07"
local chest = sides.up

function findFreeIndex(address)
	local lastFreeIndex = 1
	local mdb = component.proxy(address)   -- global database used for storing recipes
	for i = 1,81 do 
		if mdb.get(i) then 
			lastFreeIndex = lastFreeIndex + 1
		else 
			break
		end
	end
	return lastFreeIndex;
end

local lastFreeIndex = findFreeIndex(databaseAddress) -- last free index in the global database

print("Last free index in the database:  " .. lastFreeIndex)
if lastFreeIndex > 80 then error("Database full, contact developer!") end

local t = component.proxy(transposerAddress) or error("Transposer not found")
local N = t.getInventorySize(chest)
if (N == 0) then error("No chest found") end

function findItem(slot, db_adr, db_size)
	for i = 1, db_size do
		if t.compareStackToDatabase(chest, slot, db_adr, i, true) then return i end
	end
	return -1
end

function processItems(s, e)
  local res = {}
  for i = s, e do
	local s = t.getStackInSlot(chest,i)
	if not s then break	end
	local g = findItem(i, databaseAddress, lastFreeIndex-1)
	if g < 0 then 
		g = lastFreeIndex
		t.store(chest, i, databaseAddress, lastFreeIndex)
		lastFreeIndex = lastFreeIndex + 1
	end
	table.insert(res, g)
  end
  return res
end

local recipe = processItems(1,2)

if #recipe == 0 then error("Empty recipe") end

local recipes = {}
local recipeFile = io.open("/usr/alchemy_recipes.txt", "r")
if recipeFile then
	recipes = serialization.unserialize(recipeFile:read("*all"))
	if not recipes then recipes = {} end
	recipeFile:close()
end

function findRecipe(rcp)
	local key = rcp[1]
		for i=1,#recipes do
		if (recipes[i][1] == key) then
			return i
		end
	end
	return -1;
end
local oldRecipe = findRecipe(recipe)
if oldRecipe > 0 then
	print("Replacing recipe at database index " .. oldRecipe)
	recipes[oldRecipe] = recipe
else
	table.insert(recipes, recipe)
end

recipeFile = io.open("/usr/alchemy_recipes.txt", "w")
recipeFile:write(serialization.serialize(recipes))
recipeFile:close()
