local json = require "json"
local utilities = require "functions.Utilities"

local globals = {}

-- size and location of several on screen areas
globals.cardHeight = 160
globals.cardWidth = 100
globals.discardXLoc = 570
globals.discardYLoc = 140
globals.drawPileXLoc = 425
globals.drawPileYLoc = 140
globals.gameLogXLoc = 225
globals.gameLogYLoc = 100

-- tables for locations for where cards should be played on the field
globals.chainY = 300
globals.envLocs = {}    
globals.chainLocs = {}    
    
globals.envLocs[1] = {["xLoc"] = 100, ["yLoc"] = 250}
globals.envLocs[2] = {["xLoc"] = 350, ["yLoc"] = 250}
globals.envLocs[3] = {["xLoc"] = 600, ["yLoc"] = 250}
globals.chainLocs[1] = {["chain1"] = {["xLoc"] = 50, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = 150, ["yLoc"] = globals.chainY}}
globals.chainLocs[2] = {["chain1"] = {["xLoc"] = 300, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = 400, ["yLoc"] = globals.chainY}}
globals.chainLocs[3] = {["chain1"] = {["xLoc"] = 550, ["yLoc"] = globals.chainY},["chain2"] = {["xLoc"] = 650, ["yLoc"] = globals.chainY}}





local jsonStr = utilities:loadFile("data/cards.json", system.ResourceDirectory)
globals.deck = json.decode(jsonStr)

globals.font =
{
    regular = native.systemFont,
    bold = native.systemFontBold,	
}

return globals

