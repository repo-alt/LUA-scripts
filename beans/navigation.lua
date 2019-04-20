local component = require "component"
local r = component.robot
local sides = require "sides"

local x = 0
local y = 0
local basex = 0
local basey = 0
local o = 0

local function tryMove()
  local tries = 10
  while not r.move(sides.forward) do
	r.swing(sides.forward)
    tries = tries - 1
  if tries == 0 then 
	print("can't move")
	os.exit() 
	end
  end
end

local function orient(s)
	if o == s then return end
	local cs = (s + 4 - o) % 4
	if cs == 3 then r.turn(true) 
	else 
		while cs > 0 do
			r.turn(false)
			cs = cs - 1
		end
	end
	o = s
end

local function movey(cy)
  local dy = cy - y
  if dy == 0 then return end
  local inc = 1
  if (dy > 0) then
  	orient(2)
  else
  	orient(0)
  	dy = -dy
  	inc = -1
  end
  while dy ~= 0 do
	tryMove()
	y = y + inc
	dy = dy - 1
  end
end

local function movex(cx)
  local dx = cx - x
  if dx == 0 then return end
  local inc = 1
  if (dx > 0) then
  	orient(3)
  else
  	orient(1)
  	dx = -dx
  	inc = -1
  end
  while dx ~= 0 do
	tryMove(side)
	x = x + inc
	dx = dx - 1
  end
end

local function move(cx, cy)
	if cx < basex then
		movex(cx)
		movey(cy)
	else
		movey(cy)
		movex(cx)
	end
end

local function setBase(bx, by)
basex, basey = bx, by
x,y = bx, by
end

local function moveHome()
  move(basex, basey)
  orient(0)
end

navigation = {
	move = move,
	setBase = setBase,
	moveHome = moveHome
}

return navigation
