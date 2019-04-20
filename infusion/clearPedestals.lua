local component = require "component"
local sides = require "sides"
local rs = component.proxy("ba247c8c-6150-4229-8d1b-f4cdba7868fa")
rs.setOutput(sides.down, 15)
os.sleep(2)
rs.setOutput(sides.down, 0)