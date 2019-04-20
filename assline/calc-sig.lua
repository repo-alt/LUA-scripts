local serialization = require "serialization"

function readTable(file)
	local recipeFile = io.open(file, "r")
	if not recipeFile then error("No recipes") end
	local recipes = serialization.unserialize(recipeFile:read("*all"))
	recipeFile:close()
	return recipes
end

local recipes = readTable("/usr/recipes.txt")
local recipeMap = {}

for i=1,#recipes do
	local key = ""
	local n = #recipes[i][1]
	local l = 0
	for j = 1, n  do
		if not (j > 1 and recipes[i][1][j][2] < 64 and recipes[i][1][j-1][1] == recipes[i][1][j][1]) then 
			key = key .. recipes[i][1][j][1]
			l = l + 1
		end
		if l == 9 then break end
	end
	recipeMap[key] = i
end

sigFile = io.open("/usr/signatures.txt", "w")
sigFile:write(serialization.serialize(recipeMap))
sigFile:close()
