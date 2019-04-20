local component = require "component"
local sides = require "sides"
local serialization = require "serialization"

-- recipe encoding script prerequisites:
-- T3 database in some adapter (set databaseAddress below)
-- transposer (set transposerAddress below)
-- inventory with at least 27 slots at the side specified at 'chest' variable below
-- item stacks go in first 15 slots (2 chest rows are dedicated to items)
local fluidStart = 19 -- slots 19-22 are for fluids extracted via fluid extractor (moltem metals, etc)
local fluidCellStart = 23 -- slots 23-26 are for fluids extracted via canner (lubricant, etc)

local databaseAddress = component.get("0a091528")
local transposerAddress = "04e578cc-2324-4bb5-bf43-881fbf940f3c"
local chest = sides.down

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

local t = component.proxy(transposerAddress) or error("Transposer not found")
local N = t.getInventorySize(chest)
if (N == 0) then error("No chest found") end

function findItem(slot)
	for i = 1, (lastFreeIndex-1) do
		if t.compareStackToDatabase(chest, slot, databaseAddress, i) then return i end
	end
	return -1
end

function processRange(b, e)
  local res = {}
  for i = b, e do
	local s = t.getStackInSlot(chest,i)
	if not s then break	end
	local g = findItem(i)
	if g < 0 then 
		if lastFreeIndex > 81 then error("Database full, contact developer!") end
		g = lastFreeIndex
		t.store(chest, i, databaseAddress, lastFreeIndex)
		lastFreeIndex = lastFreeIndex + 1
	end
	table.insert(res, {g, t.getSlotStackSize(chest,i)})
  end
  return res
end

function processRangeFluids(res, b, e, cells)
  for i = b, e do
	local s = t.getStackInSlot(chest,i)
	if s then
		local g = findItem(i)
		if g < 0 then 
			if lastFreeIndex > 81 then error("Database full, contact developer!") end
			g = lastFreeIndex
			t.store(chest, i, databaseAddress, lastFreeIndex)
			lastFreeIndex = lastFreeIndex + 1
		end
		res[i-b+1] = {g, t.getSlotStackSize(chest,i), cells}
	end
  end
end


local recipe = {}
table.insert(recipe, processRange(1,16))
local fluids = {}
processRangeFluids(fluids, fluidStart, fluidStart+3, false)
processRangeFluids(fluids, fluidCellStart, fluidCellStart+3, true)
table.insert(recipe,fluids)

local recipes = {}
local recipeFile = io.open("/usr/recipes.txt", "r")
if recipeFile then
	recipes = serialization.unserialize(recipeFile:read("*all"))
	if not recipes then recipes = {} end
	recipeFile:close()
end

table.insert(recipes, recipe)

recipeFile = io.open("/usr/recipes.txt", "w")
recipeFile:write(serialization.serialize(recipes))
recipeFile:close()

dofile("calc-sig.lua")
