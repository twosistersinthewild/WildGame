-- Collection of useful functions that can be used anywhere in the program

-- the line below caused a problem because the load function is used in globals.lua
--local GLOB = require "globals"

local utilities = {}
local utilities_mt = { __index = utilities }	-- metatable
 
-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
 
-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------
 
function utilities.new()	-- constructor
local newUtilities = {}
return setmetatable( newUtilities, utilities_mt )
end
 
-------------------------------------------------
-- generate a random number with optional ranges
function utilities:RNG(high, low) -- can pass in 0, 1, or 2 numbers
    local newNum
    if low then
        newNum = math.random(low, high) -- in the range low - high inclusive
    elseif high then
        newNum = math.random(high) -- in the range 1 - high inclusive
    else
        newNum = math.random() -- in the range 0 - 1 inclusive
    end  
        
    return newNum
end  
--------------------------------------------------- 
 -- round a number up if it's decimial place is .5 or above, else round down 
 -- NOTE: may not work correctly for negative numbers
function utilities:Round(number) 
    local wholeNum = math.floor(number)
    local decNum = number - wholeNum
    
    if decNum >= 0.5 then
        return math.ceil(number)
    else
        return math.floor(number)
    end
end  

-------------------------------------------------
-- load a file into memory from the system.ResourceDirectory. this is being used to load a json file in and decoding it
-- filename to load is passed in as a parameter. location of file is passed in as variable dir. possible values are system.ResourceDirectory(read only) and system.DocumentsDirectory(read/write)
function utilities:loadFile(filename, dir)
    local path = system.pathForFile(filename, dir)
    local file = io.open(path, "r")
    
    if file then
        local contents = file:read("*a")
        io.close(file)
        return contents
    end    
end
-------------------------------------------------
 
return utilities

