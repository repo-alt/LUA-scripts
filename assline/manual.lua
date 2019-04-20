local component = require "component"
local sides = require "sides"
local serialization = require "serialization"

local databaseAddress = component.get("0a091528")
local smallDbAddress = component.get("6b0d1ea8")
local buses = dofile("/usr/buses")
local trans = dofile("/usr/trans")
local ftrans = dofile("/usr/ftrans")


local t = component.proxy("3d5778e5-b3a3-44cc-aa09-e6886eb8fe2c") -- main trasposer, near the AE interface

function pushInputs()
	for i=1,15 do 
		local tr = component.proxy(trans[i])
		local n = tr.getSlotStackSize(sides.down,1)	
		if n > 0 then
			tr.transferItem(sides.down, side.up, n, 1)
		end
	end
end

function pushFluids()
	for i = 1,4 do
		local tr = component.proxy(ftrans[i])
		local n = tr.getFluidInTank(sides.down,1).amount
		if (n > 0) then
			tr.transferFluid(sides.down, sides.south, n)
		end
	end
end

pushFluids()
pushInputs()
