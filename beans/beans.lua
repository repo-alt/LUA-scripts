local component = require "component"
local event = require "event"
local r = component.robot
local geo = component.geolyzer
local rs = component.redstone
local data = component.database
local inv = component.inventory_controller
local sides = require "sides"
local computer = require "computer"
package.loaded.navigation = nil -- force reload, for debugging
local nav = require "navigation"

nav.setBase(-2148, -304) 		-- chest & charger location

local slot = 1					-- currently selected slot cache
r.select(slot)

local MaxEnergy = computer.maxEnergy()

local lightError = 0xFF0000     -- error = red
local lightIdle = 0x0000FF      -- idle = blue
local lightCharge = 0xFFFFFF    -- charging = white
local lightMove = 0x00FF00      -- moving = green
local lightWork = 0xFFFF00      -- working = yellow (dig, drop, suck, etc.)
local lightBusy = 0xFF00FF      -- busy = magenta


function placeBean(index, bailiffail)
	if not inv.compareToDatabase(slot, data.address, index, true) then
		for i=1, r.inventorySize() do
			if inv.compareToDatabase(i, data.address, index, true) then
				slot = i
				r.select(slot)
			end
		end
	end
	if not inv.compareToDatabase(slot, data.address, index, true) then
		if bailiffail then
		  print("No beans for database index ", index)
		  r.setLightColor(lightError)
		  os.exit()
		end
	else
    	r.place(sides.up)
	end
end

local function work(index)
  if r.detect(sides.up) then
	r.setLightColor(lightWork)
	local v = geo.analyze(sides.up)
	if v and v.name == "Thaumcraft:blockManaPod" and v.metadata == 7 then
		r.swing(sides.up)
		placeBean(index, true)
	elseif not v then
		placeBean(index, false)
	end
	r.setLightColor(lightMove)
  else	
    placeBean(index, false)
  end
end


local plantations = {
	{startx = -2136, starty = -303,
	 endx = -2145,  endy = -299,
	 dbindex = 1 -- index of that plantation bean in the database
	 },
	{startx = -2133, starty = -303,
	 endx = -2134,  endy = -299,
	 dbindex = 2 -- index of that plantation bean in the database
	 }
}

local function charge()
	rs.setOutput(sides.right, 15) -- charger to the right
	r.setLightColor(lightCharge)
	while (computer.energy() < (MaxEnergy * 0.9)) do
	  local e = event.pull(10, "interrupted")
  	  if e then break end
	end
	rs.setOutput(sides.right, 0) -- charger to the right
    r.setLightColor(lightIdle)
end

local function dropInventory()
	r.setLightColor(lightBusy)
	for i=1, r.inventorySize() do
		r.select(i)
		r.drop(sides.front)
	end
	r.select(slot)
    r.setLightColor(lightIdle)
end

while true do
  r.setLightColor(lightMove)
  for i, p in ipairs(plantations) do
  for y = p.starty, p.endy do
	local sx, ex, dx = p.startx, p.endx, -1
	if (y % 2) == 0 then sx, ex, dx = p.endx, p.startx, 1 end
	for x = sx, ex, dx do
	   nav.move(x,y)
	   work(p.dbindex)
	end
  end
  end
  nav.moveHome()
  rs.setOutput(sides.right, 15) -- charger to the right
  dropInventory()
  charge()
  r.setLightColor(lightIdle)
  local e = event.pull(120, "interrupted")
  if e then break end
end
