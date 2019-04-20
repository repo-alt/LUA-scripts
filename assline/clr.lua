local component = require "component"
local sides = require "sides"
local ftrans = dofile("/usr/ftrans")
local trans = dofile("/usr/trans")

	for i = 1,15 do
		local tr = component.proxy(trans[i])
		local n = tr.getSlotStackSize(sides.down,1)
		if n > 0 then
			tr.transferItem(sides.down, sides.north, n, 1, 1)
		end
	end

	for i = 1,15 do
		local tr = component.proxy(trans[i])
		local n = tr.getSlotStackSize(sides.up,1)
		if n > 0 then
			tr.transferItem(sides.up, sides.north, n, 1, 1)
		end
	end

	for i = 1,4 do
		local tr = component.proxy(ftrans[i])
		local n = tr.getFluidInTank(sides.south,1).amount
		if (n > 0) then
			tr.transferFluid(sides.south, sides.north, n)
		end
	end

	for i = 1,4 do
		local tr = component.proxy(ftrans[i])
		local n = tr.getFluidInTank(sides.down,1).amount
		if (n > 0) then
			tr.transferFluid(sides.down, sides.north, n)
		end
	end
local interfaceRedstone = "9cb54ff6-3aa6-468c-802b-93090d61571a"
local rs = component.proxy(interfaceRedstone)
rs.setOutput(sides.north, 15)
os.sleep(4)
rs.setOutput(sides.north, 0)
