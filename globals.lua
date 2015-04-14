local json = require "json"
local utilities = require "functions.Utilities"

local globals = {}

-- size and location of several on screen areas
globals.cardHeight = 160
globals.cardWidth = 100
globals.discardXLoc = 75
globals.discardYLoc = 275
globals.drawPileXLoc = 75
globals.drawPileYLoc = 100
globals.spCardXLoc = 75
globals.spCardYLoc = 425
globals.gameLogXLoc = 775
globals.gameLogYLoc = display.contentHeight - 80
globals.logScrollWidth = 350
globals.tutBoxX = display.contentWidth/2 + 100
globals.tutBoxY = 250

-- score button image locs
globals.scoreImages = {}
globals.scoreImages["row1"] = 35 -- y value
globals.scoreImages["col1"] = 875 -- x value



-- tables for locations for where cards should be played on the field
globals.cardOffset = 35 -- physical space between cards on chain on screen
globals.chainY = 110
globals.envLocs = {}    
globals.chainLocs = {}    
    
globals.envLocs[1] = {["xLoc"] = 250, ["yLoc"] = 60}
globals.envLocs[2] = {["xLoc"] = display.contentWidth/2, ["yLoc"] = 60}
globals.envLocs[3] = {["xLoc"] = display.contentWidth - 250, ["yLoc"] = 60}
globals.chainLocs[1] = {["chain1"] = {["xLoc"] = 200, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = 300, ["yLoc"] = globals.chainY}}
globals.chainLocs[2] = {["chain1"] = {["xLoc"] = display.contentWidth/2 - 50, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = display.contentWidth/2 + 50, ["yLoc"] = globals.chainY}}
globals.chainLocs[3] = {["chain1"] = {["xLoc"] = display.contentWidth - 300, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = display.contentWidth - 200, ["yLoc"] = globals.chainY}}

-- sound and music
globals.pSound = true
globals.pMusic = true

local jsonStr = utilities:loadFile("data/cards.json", system.ResourceDirectory)
globals.deck = json.decode(jsonStr)

globals.font =
{
    regular = native.systemFont,
    bold = native.systemFontBold,	
}

return globals

