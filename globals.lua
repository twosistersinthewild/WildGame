local json = require "json"
local utilities = require "functions.Utilities"

local globals = {}

local jsonStr = utilities:loadFile("data/cards.json", system.ResourceDirectory)
globals.deck = json.decode(jsonStr)

globals.font =
{
    regular = native.systemFont,
    bold = native.systemFontBold,	
}

return globals

