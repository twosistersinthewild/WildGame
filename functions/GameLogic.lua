-- Collection of useful functions that can be used anywhere in the program
local GLOB = require "globals"
local utilities = require "functions.Utilities"

local gameLogic = {}
local gameLogic_mt = { __index = gameLogic }	-- metatable
 
-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
 
-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function gameLogic:Testing(myScene)
    
    --local sceneG = myScene.view
    
    for i=1, 10 do
    myScene:remove(myScene[i])
    end
    
end


-- todo make sure these parameters are correct
function gameLogic:ValidLocation(myCard, myEnvs)
    
    -- determine if being dropped back into hand as well
    
    -- return a sring of where the card was dropped
    local hotspot = ""
    
    -- over discard pile
    if myCard.x >= GLOB.discardXLoc - GLOB.cardWidth/2 and myCard.x <= GLOB.discardXLoc + GLOB.cardWidth/2 and myCard.y >= GLOB.discardYLoc - GLOB.cardHeight/2 and myCard.y <= GLOB.discardYLoc + GLOB.cardHeight/2 then
        hotspot = "discard"
        
    -- over special card area
    -- todo uncomment and get this in game
    --elseif myCard.x >= GLOB.spCardXLoc - GLOB.cardWidth/2 and myCard.x <= GLOB.spCardXLoc + GLOB.cardWidth/2 and myCard.y >= GLOB.spCardYLoc - GLOB.cardHeight/2 and myCard.y <= GLOB.spCardYLoc + GLOB.cardHeight/2 then
        --hotspot = "special"    
        
    -- over hand
    elseif myCard.x >= 50 and myCard.x <= GLOB.cardWidth * 5 + 50 and myCard.y >= display.contentHeight - GLOB.cardHeight and myCard.y <= display.contentHeight then
        hotspot = "hand"
    end  
    
    -- see if the card is dropped over an environment and which chain
    if hotspot == "" then
        for i = 1, 3 do
            local chain1Len = 0
            local chain2Len = 0
            
            if myEnvs[i] then
                if myEnvs[i]["chain1"] then
                    chain1Len = #myEnvs[i]["chain1"] + 1
                end

                if myEnvs[i]["chain2"] then
                    chain2Len = #myEnvs[i]["chain2"] + 1
                end
            end
            
            if myCard.x >= GLOB.chainLocs[i]["chain1"]["xLoc"] - GLOB.cardWidth/2 and myCard.x <= GLOB.chainLocs[i]["chain1"]["xLoc"]  + GLOB.cardWidth/2 
                    and myCard.y >= GLOB.chainLocs[i]["chain1"]["yLoc"] - GLOB.cardHeight/2 and myCard.y <= GLOB.chainLocs[i]["chain1"]["yLoc"] + GLOB.cardHeight/2 + (GLOB.cardOffset * chain1Len) then
                
                hotspot = "env"..i.."chain1"
                break
            elseif myCard.x >= GLOB.chainLocs[i]["chain2"]["xLoc"] - GLOB.cardWidth/2 and myCard.x <= GLOB.chainLocs[i]["chain2"]["xLoc"] + GLOB.cardWidth/2 
                    and myCard.y >= GLOB.chainLocs[i]["chain2"]["yLoc"] - GLOB.cardHeight/2 and myCard.y <= GLOB.chainLocs[i]["chain2"]["yLoc"] + GLOB.cardHeight/2 + (GLOB.cardOffset * chain2Len) then
                hotspot = "env"..i.."chain2"  
                break
            end
        end
    end
        
    if hotspot == "" then
        return nil -- snap back to hand
    else
        return hotspot
    end    
end

-- nil a card out of the hand
-- this function will shift elements in the hand table to fill any holes after a card is played or discarded
-- pass in player or npc hand
function gameLogic:RemoveFromHand(myCard, myHand)
    local index = 0
    
    for i = 1, #myHand do
        if myHand[i]["cardData"].ID == myCard["cardData"].ID then
            index = i
            myHand[i] = nil
            break
        end   
    end
    
    while myHand[index + 1] do
        myHand[index] = myHand[index + 1]
        myHand[index + 1] = nil
        index = index + 1
    end
end

--------------------------
-- try to play an environment card
--------------------------    
--params: myCard is the card object, myHand is the hand table that the card will be pulled from,  
--myEnvs is the player's cards on the field, index is the index of the env, who is a string for text output
function gameLogic:PlayEnvironment(myCard, myHand, myEnvs, index, who)
    local played = false       
    local playedString = ""

    if not myEnvs[index] then
        -- create the env1 table
        myEnvs[index] = {}

        -- the card for the enviro will be added here rather than in the hand
        -- todo deal with this better
        myEnvs[index]["activeEnv"] = myCard

        if who == "Player" then
            myEnvs[index]["activeEnv"].x = GLOB.envLocs[index]["xLoc"]
            myEnvs[index]["activeEnv"].y = GLOB.envLocs[index]["yLoc"]
            myEnvs[index]["activeEnv"].rotation = 270                        
        end

        playedString = who.." has played "..myEnvs[index]["activeEnv"]["cardData"].Name .. " environment card." 

        played = true
        myEnvs[index]["activeEnv"]["cardData"].Played = true
    end
    
    if played then
        if myCard["cardData"]["Type"] == "Wild" then
            myCard["cardData"]["Value"] = 1
        end       
        
        gameLogic:RemoveFromHand(myCard, myHand)
        
        return true, playedString
    else
        playedString = myCard["cardData"]["Name"].." could not be played."
        return false, playedString
    end
end
-------------------------------------------------
--------------------------
-- try to play a plant card
--------------------------   
function gameLogic:PlayPlant(myCard, myHand, myEnvs, index, availChain, who)
    -- must have an environment to play on
    local played = false
    local playedString = ""

    -- make sure an environment has already been played in this spot
    if myEnvs[index] then             
        -- if the chain doesn't exist yet, a plant can be played on it
        if not myEnvs[index][availChain] then
            -- make sure types match
            local envMatch = false

            --todo might need to check 2 envs for nature bites back
            local envType = ""
            envType = utilities:DetermineEnvType(myEnvs, index)

            -- see if any of the plants places to live match the environment played
            -- loop through and check all 4 against the current environment
            -- check first for The Strohmstead. If it is present, then the card can be played
            -- todo might want to check here for when first plant is played on strohmstead. 
            -- this plant will determine what can be played after it
            if envType == "ST" then
                envMatch = true
            else
                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    if myCard["cardData"][myEnvSt] and myCard["cardData"][myEnvSt] == envType then
                        envMatch = true
                        break
                    end
                end
            end
            if envMatch then
                -- create the table for the food chain
                myEnvs[index][availChain] = {}

                -- assign the plant to first postion of the food chain array chosen above
                myEnvs[index][availChain][1] = myCard                

                if who == "Player" then
                    -- place in the proper position                        
                    local tabLen = #myEnvs[index][availChain]
                    myCard.x = GLOB.chainLocs[index][availChain]["xLoc"]
                    myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] + (tabLen * GLOB.cardOffset)                           
                end

                playedString = who.." has played "..myEnvs[index][availChain][1]["cardData"].Name .. " card on top of " .. myEnvs[index]["activeEnv"]["cardData"].Name .. "."

                played = true
                myCard["cardData"].Played = true
            end
        end
    end      

    if played then
        if myCard["cardData"]["Type"] == "Wild" then
            local myScore = gameLogic:CalculateScore(myEnvs)
            
            if myScore[2] then
                myCard["cardData"]["Value"] = 3
            elseif myScore[3] then
                myCard["cardData"]["Value"] = 2
            else
                myCard["cardData"]["Value"] = 2
            end
        end          
        
        gameLogic:RemoveFromHand(myCard, myHand)
        return true, playedString
    else
        playedString = myCard["cardData"]["Name"].." could not be played."
        return false, playedString 
    end        
end
-------------------------------------------------
--------------------------
-- try to play an invert or animal card
--------------------------   
function gameLogic:PlayAnimal(myCard, myHand, myEnvs, index, availChain, who)
    -- todo may need a special case for apex to make it a 10 if played on a 9

    -- make sure there is an available chain to play on
    -- check diet types against cards in play
    -- check environment
    -- if ok add to chain and set value appropriately

    local playedString = ""
    local played = false
    local space = false
    local tabLen = 0
    local dietValue = 0

    -- todo maxEnvirons could be substituted if a card allows up to 3 chains
    if myEnvs[index] then         
        --todo: make sure there is something to eat on one of the chains
        if myEnvs[index][availChain] then
            -- first get the table length to find the last card played on the chain
            tabLen = #myEnvs[index][availChain]

            if tabLen > 0 then
                local foodType = myEnvs[index][availChain][tabLen]["cardData"].Type

                -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                if foodType == "Small Plant" or foodType == "Large Plant" then
                        foodType = "Plant"
                end
                
                -- if it's a wild card, set the string based on its current value
                -- this will determine its "type"
                -- todo make sure this is working correctly
                if foodType == "Wild" then
                    if myEnvs[index][availChain][tabLen]["cardData"].Value == 2 or myEnvs[index][availChain][tabLen]["cardData"].Value == 3 then  
                        foodType = "Plant"
                    elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 6 or myEnvs[index][availChain][tabLen]["cardData"].Value == 7 then  
                        foodType = "Small Animal"
                    elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 8 then  
                        foodType = "Small Animal"
                    elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 9 then
                        foodType = "Large Animal"
                    else
                        foodType = "Apex"
                    end
                end

                -- loop through the card's available diets and try to match the chain
                for diet = 1, 5 do
                    local dietString = "Diet"..diet.."_Type"

                    -- if this is true, there is space and the last card in the chain is edible
                    if myCard["cardData"][dietString] and myCard["cardData"][dietString] == foodType then
                        space = true
                        dietValue = diet
                        break
                    end                                        
                end  
                
            end 
        end

        if space then
            -- make sure types match
            local envMatch = false

            --todo might need to check 2 envs for nature bites back
            local envType = ""

            envType = utilities:DetermineEnvType(myEnvs, index)

            if envType == "ST" then                                
                -- determine envs supported by plant played (in a table)
                local supportedEnvs = {}

                for pos = 1, 4 do
                    if myEnvs[index][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                        table.insert(supportedEnvs, myEnvs[index][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
                    end                                    
                end

                local stIndex = 2

                -- if there are more cards in the chain, continue checking each one
                        -- if the next creature in the chain doesn't support everything that the original plant did, nil it and fix table
                while myEnvs[index][availChain][stIndex] do
                    local found = false   
                    local count = #supportedEnvs

                    while count > 0  do
                        for cardEnvs = 1, 4 do
                            if  supportedEnvs[count] ~= "" then
                                if myEnvs[index][availChain][stIndex]["cardData"]["Env"..cardEnvs] == supportedEnvs[count] then
                                    found = true
                                    break
                                end
                            end
                        end

                        if not found then
                            supportedEnvs[count] = nil
                            --table.remove(supportedEnvs, count)
                        end

                        count = count - 1
                    end

                    stIndex = stIndex + 1
                end

                -- once all creatures in chain are checked do check similar to below but may need to be nested loop in order to check
                -- both the creature being played and possible envs
                -- todo: make this a reusable function so that it works for wild cards as well                                

                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    for thisInd = 1, #supportedEnvs do
                        if myCard["cardData"][myEnvSt] ~= "" and supportedEnvs[thisInd] ~= "" and myCard["cardData"][myEnvSt] == supportedEnvs[thisInd] then
                            envMatch = true
                            break
                        end
                    end
                    
                    if envMatch then
                        break
                    end      
                end
            else
                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    if myCard["cardData"][myEnvSt] and myCard["cardData"][myEnvSt] == envType then
                        envMatch = true
                        break
                    end
                end
            end


            -- add it to chain, change its value, nil it from hand
            if envMatch then
                local valueStr = "Diet"..dietValue.."_Value"                                

                myCard["cardData"].Value = myCard["cardData"][valueStr]    
                
                -- assign to next available spot in the table
                myEnvs[index][availChain][tabLen + 1] = myCard

                played = true
                myCard["cardData"].Played = true

                if who == "Player" then
                    myCard.x = GLOB.chainLocs[index][availChain]["xLoc"]
                    myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] + ((tabLen + 1) * GLOB.cardOffset)
                end

                playedString = who.." has played "..myEnvs[index][availChain][tabLen + 1]["cardData"]["Name"] .. " card on top of " .. myEnvs[index][availChain][tabLen]["cardData"]["Name"] .. "."
            end
        end
    end 

    if played then
        gameLogic:RemoveFromHand(myCard, myHand)
        return true, playedString
    else
        playedString = myCard["cardData"]["Name"].." could not be played."
        return false, playedString
    end
end


-- see if an animal can migrate to another chain
-- todo might need one for plants too (strohm)
-- will return true or false. does not actually move card or change values
-- changes to gameLogic:PlayAnimal need to be reflected here
function gameLogic:MigrateAnimal(myCard, myHand, myEnvs, index, availChain, who, order)
    local played = false
    local space = false
    local tabLen = 0
    local dietValue = 0

    -- todo maxEnvirons could be substituted if a card allows up to 3 chains
    if myEnvs[index] then         
        --todo: make sure there is something to eat on one of the chains
        if myEnvs[index][availChain] then
            if order == "first" then
                -- first get the table length to find the last card played on the chain
                tabLen = #myEnvs[index][availChain]

                if tabLen > 0 then
                    local foodType = myEnvs[index][availChain][tabLen]["cardData"].Type

                    -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                    if foodType == "Small Plant" or foodType == "Large Plant" then
                        foodType = "Plant"
                    end

                    -- if it's a wild card, set the string based on its current value
                    -- this will determine its "type"
                    -- todo make sure this is working correctly
                    if foodType == "Wild" then
                        if myEnvs[index][availChain][tabLen]["cardData"].Value == 2 or myEnvs[index][availChain][tabLen]["cardData"].Value == 3 then  
                            foodType = "Plant"
                        elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 6 or myEnvs[index][availChain][tabLen]["cardData"].Value == 7 then  
                            foodType = "Small Animal"
                        elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 8 then  
                            foodType = "Small Animal"
                        elseif myEnvs[index][availChain][tabLen]["cardData"].Value == 9 then
                            foodType = "Large Animal"
                        else
                            foodType = "Apex"
                        end
                    end

                    -- loop through the card's available diets and try to match the chain
                    for diet = 1, 5 do
                        local dietString = "Diet"..diet.."_Type"

                        -- if this is true, there is space and the last card in the chain is edible
                        if myCard["cardData"][dietString] and myCard["cardData"][dietString] == foodType then
                            space = true
                            dietValue = diet
                            break
                        end  
                    end  
                end 
            else
                space = true -- if not the first card being migrated, assume it can eat what is in front of it on the chain
            end
        end

        if space then
            -- make sure types match
            local envMatch = false

            --todo might need to check 2 envs for nature bites back
            local envType = ""

            envType = utilities:DetermineEnvType(myEnvs, index)

            if envType == "ST" then                                
                -- determine envs supported by plant played (in a table)
                local supportedEnvs = {}

                for pos = 1, 4 do
                    if myEnvs[index][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                        table.insert(supportedEnvs, myEnvs[index][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
                    end                                    
                end

                local stIndex = 2

                -- if there are more cards in the chain, continue checking each one
                        -- if the next creature in the chain doesn't support everything that the original plant did, nil it and fix table
                while myEnvs[index][availChain][stIndex] do
                    local found = false   
                    local count = #supportedEnvs

                    while count > 0  do
                        for cardEnvs = 1, 4 do
                            if  supportedEnvs[count] ~= "" then
                                if myEnvs[index][availChain][stIndex]["cardData"]["Env"..cardEnvs] == supportedEnvs[count] then
                                    found = true
                                    break
                                end
                            end
                        end

                        if not found then
                            supportedEnvs[count] = nil
                            --table.remove(supportedEnvs, count)
                        end

                        count = count - 1
                    end

                    stIndex = stIndex + 1
                end

                -- once all creatures in chain are checked do check similar to below but may need to be nested loop in order to check
                -- both the creature being played and possible envs
                -- todo: make this a reusable function so that it works for wild cards as well                                

                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    for thisInd = 1, #supportedEnvs do
                        if myCard["cardData"][myEnvSt] ~= "" and supportedEnvs[thisInd] ~= "" and myCard["cardData"][myEnvSt] == supportedEnvs[thisInd] then
                            envMatch = true
                            break
                        end
                    end
                    
                    if envMatch then
                        break
                    end      
                end
            else
                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    if myCard["cardData"][myEnvSt] and myCard["cardData"][myEnvSt] == envType then
                            envMatch = true
                            break
                    end
                end
            end

            if envMatch then
                played = true
            end
        end
    end 

    if played then
        return true
    else
        return false
    end
end

function gameLogic:MigratePlant(myCard, myHand, myEnvs, index, availChain, who)
    -- must have an environment to play on
    local played = false
    local playedString = ""

    -- make sure an environment has already been played in this spot
    if myEnvs[index] then             
        -- if the chain doesn't exist yet, a plant can be played on it
        if not myEnvs[index][availChain] then
            -- make sure types match
            local envMatch = false

            --todo might need to check 2 envs for nature bites back
            local envType = ""
            envType = utilities:DetermineEnvType(myEnvs, index)

            -- see if any of the plants places to live match the environment played
            -- loop through and check all 4 against the current environment
            -- check first for The Strohmstead. If it is present, then the card can be played
            -- todo might want to check here for when first plant is played on strohmstead. 
            -- this plant will determine what can be played after it
            if envType == "ST" then
                envMatch = true
            else
                for myEnv = 1, 4 do
                    local myEnvSt = "Env"..myEnv                            

                    if myCard["cardData"][myEnvSt] and myCard["cardData"][myEnvSt] == envType then
                        envMatch = true
                        break
                    end
                end
            end
            if envMatch then
                played = true
            end
        end
    end      

    if played then
        return true
    else
        return false
    end        
end

-- simply check to see if a card can play on a particular environment and return true or false
function gameLogic:EnvTest(myCard, myEnvs, index)
    local envType = ""

    envType = utilities:DetermineEnvType(myEnvs, index)

    if envType == "ST" then                                
        return true
    else
        for myEnv = 1, 4 do
            local myEnvSt = "Env"..myEnv                            

            if myCard["cardData"][myEnvSt] and myCard["cardData"][myEnvSt] == envType then
                return true
            end
        end
    end    
    
    return false
end


-- explicitely move all cards to their appropriate place on the playfield
function gameLogic:RepositionCards(myEnvs)
    local myChain = ""
    
    for i = 1, 3 do
        if myEnvs[i] then
            myEnvs[i]["activeEnv"].x = GLOB.envLocs[i]["xLoc"]
            myEnvs[i]["activeEnv"].y = GLOB.envLocs[i]["yLoc"]
            myEnvs[i]["activeEnv"]:toFront()
--            myEnvs[i]["activeEnv"].rotation = 270   

            for j = 1, 2 do
                if j == 1 then
                    myChain = "chain1"
                else
                    myChain = "chain2"
                end                
                
                if myEnvs[i][myChain] then
                    for k = 1, #myEnvs[i][myChain] do                    
                        local myCard = myEnvs[i][myChain][k]                    
                        myCard.x = GLOB.chainLocs[i][myChain]["xLoc"]
                        myCard.y = GLOB.chainLocs[i][myChain]["yLoc"] + (k * GLOB.cardOffset)
                        myCard:toFront() -- aww
                    end
                end  
            end
        end 
    end
end


-- called after a card is zoomed out from
-- finds the card that was zoomed, places it back on the playfield in the front
-- then it brings each card below it on the chain to the front
function gameLogic:BringToFront(myID, myEnvs)
    
    local found = false
    
    for i = 1, 3 do
        local myChain = ""        
        
        -- if the card matches and is an environment, bring it to front
        -- then bring all other cards on its chain forward
        if myEnvs[i] and myEnvs[i]["activeEnv"] and myEnvs[i]["activeEnv"]["cardData"].ID == myID then            
            found = true
            
            if found then
                myEnvs[i]["activeEnv"]:toFront()
            
                for j = 1, 2 do
                    myChain = "chain"..j
                    
                    if myEnvs[i][myChain] then
                        for k = 1, #myEnvs[i][myChain] do
                            myEnvs[i][myChain][k]:toFront()
                        end
                    end
                end
                
                break
            end
        end
        
        -- if not an environment, find the card
        -- once matched, bring to front, then any other cards below on its chain
        if not found then
            for j = 1, 2 do
                myChain = "chain"..j 
                
                if myEnvs[i] and myEnvs[i][myChain] then   
                    for k = 1, #myEnvs[i][myChain] do                        
                        if myEnvs[i][myChain][k] and myEnvs[i][myChain][k]["cardData"].ID == myID then
                            found = true  
                        end  
                        
                        if found then                            
                            myEnvs[i][myChain][k]:toFront()
                        end
                    end
                    
                    if found then
                        break
                    end
                end
            end
        end
        
        if found then
            break
        end        
    end
end



-- determine what environment and chain a card is on
-- card and player's environments who owns card are passed in
-- returns a number for the environment and a string for the chain
-- ex: (0, "") would be returned if the card was not found
function gameLogic:GetMyEnv(myCard, myEnvs)
    local found = false
    local envNum = 0
    local myChain = ""
    local myIndex = 0
    
    for i = 1, 3 do             
        -- determine if it's an environment
        if myEnvs[i] and myEnvs[i]["activeEnv"] and myEnvs[i]["activeEnv"]["cardData"].ID == myCard["cardData"]["ID"] then            
            found = true
            
            if found then
                envNum = i                
                break
            end
        end
        
        -- if not an environment, find the card
        if not found then
            for j = 1, 2 do
                myChain = "chain"..j 
                
                if myEnvs[i] and myEnvs[i][myChain] then   
                    for k = 1, #myEnvs[i][myChain] do                        
                        if myEnvs[i][myChain][k] and myEnvs[i][myChain][k]["cardData"].ID == myCard["cardData"]["ID"] then
                            found = true 
                            envNum = i
                            myIndex = k
                            break
                        end  
                    end
                    
                    if found then
                        break
                    end
                end
            end
            
            if not found then
                myChain = ""
            end
        end
        
        if found then -- break the outer loop
            break
        end        
    end    
    
    return envNum, myChain, myIndex
end

-- get the value of a card from any available stat
-- this references the data from the excel sheet/json data
function gameLogic:GetStat(myCard, stat)
    
    local retVal = nil
    
    if myCard["cardData"][stat] then -- make sure there is a value there
        retVal = myCard["cardData"][stat] 
    end
    
    -- return the stat or nil
    return retVal
end


-- set the value of a card from any available stat
function gameLogic:SetStat(myCard, stat, newValue)  
    myCard["cardData"][stat] = newValue
end

function gameLogic:CalculateScore(myEnvs)
    -- run through activeEnvs
    -- run through each chain
    
    -- for each card found, flag the value in curEco for that spot of chain
    -- also count the number of each occurance to use for checking that apex are not filling a double role
    
    local envFound = false
    local tabLen = 0
    local apexFound = false -- determine if an apex is in play. if it is and all 9 roles are filled player can win
    local apexValues = {[1]=0, [2]=0, [3]=0,[4]=0, [5]=0, [6]=0,[7]=0, [8]=0, [9]=0,[10]=0}
    local numCounts = {[1]=0, [2]=0, [3]=0,[4]=0, [5]=0, [6]=0,[7]=0, [8]=0, [9]=0,[10]=0}
    local allNumsPlayed = true -- flag to see if 10 can be set to true. if this becomes false, there is no win
    
    -- todo: might want to deal with this differently
    local curEco = {[1]=false, [2]=false, [3]=false,[4]=false, [5]=false, [6]=false,[7]=false, [8]=false, [9]=false,[10]=false} -- clear the table first so that we only mark true if they are currently there
    local chainStr = "chain"    
    
    for i = 1, 3 do 
        if myEnvs and myEnvs[i] then
            if not envFound then -- only want to set this once, so once an env has been found this will not be true again
                envFound = true
                curEco[1] = true -- hard coded to make it a 1 for env
                numCounts[1] = numCounts[1] + 1
            end
            
            -- todo: change this for loop if there are more than 2 possible chains
            for chainCount = 1, 2 do
                chainStr = "chain"..chainCount -- will have a value of "chain1" or "chain2"
                
                if myEnvs[i][chainStr] then
                    tabLen = #myEnvs[i][chainStr]                        

                    local cardValue = 0

                    if tabLen > 0 then
                        for j = 1, tabLen do                        
                            cardValue = myEnvs[i][chainStr][j]["cardData"].Value
                            curEco[cardValue] = true
                            numCounts[cardValue] = numCounts[cardValue] + 1
                            
                            if myEnvs[i][chainStr][j]["cardData"].Type == "Apex" then
                                apexFound = true
                                apexValues[cardValue] = apexValues[cardValue] + 1
                            -- human can become apex if it is played as last in chain
                            elseif myEnvs[i][chainStr][j]["cardData"].Type == "Wild" and not myEnvs[i][chainStr][j + 1] then
                                apexFound = true
                                apexValues[cardValue] = apexValues[cardValue] + 1
                            end
                        end
                    end
                end
            end            
        end 
    end
    
    if apexFound then -- if there is an apex in play, see if all other numbers are present
        -- if all other numbers are present, make sure that apex is not already fulfilling another role
        for i = 1, 10 do
            if apexValues[i] > 0 then
                if numCounts[i] > apexValues[i] or apexValues[i] > 1 then -- added second condition for cases when having 2 apex predators on playfield wouold not win
                    curEco[10] = true -- explicitely set 10 (apex) to true
                end
            end
        end      
    end
    
    return curEco
end

-- checks to see if player has proceeded with tutorial scenario
function gameLogic:TutorialCheck(myEnvs, counter)
    local animalFound = false
    local chainString = ""
    for i = 1, 3 do
        if myEnvs[i] then
            for j = 1, 2 do
                chainString = "chain"..j                    
                if myEnvs[i][chainString] and myEnvs[i][chainString][counter - 1] then
                    counter = counter + 1                    
                    animalFound = true
                    break
                end  
            end
        end

        if animalFound then 
            break 
        end  
    end    
    
    return counter
end

-------------------------------------------------
 
return gameLogic



