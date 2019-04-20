local component = require "component"
local tempDb = component.proxy("12345") or error("no database")
