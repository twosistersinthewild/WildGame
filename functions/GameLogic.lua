-- Collection of useful functions that can be used anywhere in the program

-- the line below caused a problem because the load function is used in globals.lua
--local GLOB = require "globals"

local gameLogic = {}
local gameLogic_mt = { __index = gameLogic }	-- metatable
 
-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
 
-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------




-------------------------------------------------
 
return gameLogic



