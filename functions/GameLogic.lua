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

-- todo make sure these parameters are correct
function gameLogic:ValidLocation(myCard)
    
    -- determine if being dropped back into hand as well
    
    -- return a sring of where the card was dropped
    local hotspot = ""
    
    -- over discard pile
    if myCard.x >= GLOB.discardXLoc - GLOB.cardWidth/2 and myCard.x <= GLOB.discardXLoc + GLOB.cardWidth/2 and myCard.y >= GLOB.discardYLoc - GLOB.cardHeight/2 and myCard.y <= GLOB.discardYLoc + GLOB.cardHeight/2 then
        hotspot = "discard"
    -- over hand
    elseif myCard.x >= (display.contentWidth / 2 - GLOB.cardWidth * 2.5) and myCard.x <= (display.contentWidth / 2 + GLOB.cardWidth * 2.5) and myCard.y >= display.contentHeight - GLOB.cardHeight and myCard.y <= display.contentHeight then
        hotspot = "hand"
    end  
    
    -- see if the card is dropped over an environment and which chain
    if hotspot == "" then
        for i = 1, 3 do
            if myCard.x >= GLOB.chainLocs[i]["chain1"]["xLoc"] - GLOB.cardWidth/2 and myCard.x <= GLOB.chainLocs[i]["chain1"]["xLoc"]  + GLOB.cardWidth/2 and myCard.y >= GLOB.chainLocs[i]["chain1"]["yLoc"] - GLOB.cardHeight/2 and myCard.y <= GLOB.chainLocs[i]["chain1"]["yLoc"] + GLOB.cardHeight/2 then
                hotspot = "env"..i.."chain1"
                break
            elseif myCard.x >= GLOB.chainLocs[i]["chain2"]["xLoc"] - GLOB.cardWidth/2 and myCard.x <= GLOB.chainLocs[i]["chain2"]["xLoc"] + GLOB.cardWidth/2 and myCard.y >= GLOB.chainLocs[i]["chain2"]["yLoc"] - GLOB.cardHeight/2 and myCard.y <= GLOB.chainLocs[i]["chain2"]["yLoc"] + GLOB.cardHeight/2 then
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
            --print (myCard["cardData"].Name.. " is the same as "..myHand[i]["cardData"].Name)
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
         
    if myCard["cardData"].Type == "Environment" then
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
            
            print(who.." has played "..myEnvs[index]["activeEnv"]["cardData"].Name .. " environment card.") 

            played = true
            myEnvs[index]["activeEnv"]["cardData"].Played = true
        end
    end 
    
    if played then
        gameLogic:RemoveFromHand(myCard, myHand)
        return true
    else
        return false
    end
end
-------------------------------------------------
--------------------------
-- try to play a plant card
--------------------------   
function gameLogic:PlayPlant(myCard, myHand, myEnvs, index, availChain, who)
    if myCard["cardData"].Type == "Small Plant" or myCard["cardData"].Type == "Large Plant" then
        -- must have an environment to play on
        local played = false

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
                        myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] + (tabLen * 35)                           
                    end
                    
                    print(who.." has played "..myEnvs[index][availChain][1]["cardData"].Name .. " card on top of " .. myEnvs[index]["activeEnv"]["cardData"].Name .. ".") 
                
                    played = true
                    myCard["cardData"].Played = true
                end
            end
        end   
        
        if played then
            gameLogic:RemoveFromHand(myCard, myHand)
            return true
        else
            return false  
        end        
    end
end
-------------------------------------------------
--------------------------
-- try to play an invert or animal card
--------------------------   
function gameLogic:PlayAnimal(myCard, myHand, myEnvs, index, availChain, who)
    if myCard["cardData"].Type == "Invertebrate" or myCard["cardData"].Type == "Small Animal" or myCard["cardData"].Type == "Large Animal" or myCard["cardData"].Type == "Apex" then
        -- todo may need a special case for apex to make it a 10 if played on a 9

        -- make sure there is an available chain to play on
        -- check diet types against cards in play
        -- check environment
        -- if ok add to chain and set value appropriately

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
                else
                        print("No card was in that position. You have an Error.")
                end 
            end

            if space then
                -- make sure types match
                local envMatch = false

                --todo might need to check 2 envs for nature bites back
                local envType = ""

                envType = utilities:DetermineEnvType(myEnvs, index)

                -- see if any of the animal's places to live match the environment played
                -- loop through and check all 4 against the current environment
                -- check first for The Strohmstead. If it is present, then the card can be played
                -- todo fix this. the strohmstead will become whatever environments are supported                            
                -- by the previous cards played. currently it just lets a card be played regardless of 
                -- what is below

                -- todo: this may need tweaked. i think that the first plant card played will determine strohmstead type. 
                --may need to store this as an added field to the strohmstead card data
                -- this would be done when the first plant is played onto strohmstead
                if envType == "ST" then                                
                        -- determine envs supported by plant played (in a table)
                        local supportedEnvs = {}

                        for pos = 1, 4 do
                                if myEnvs[index][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                                        table.insert(supportedEnvs, myEnvs[index][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
                                end                                    
                        end

                        -- if there are more cards in the chain, continue checking each one
                                -- if the next creature in the chain doesn't support everything that the original plant did, nil it and fix table
                                -- can probably use table.remove to take them out of supportedEnvs table to fill the hole properly

                        -- once all creatures in chain are checked do check similar to below but may need to be nested loop in order to check
                        -- both the creature being played and possible envs
                        -- todo: make this a reusable function so that it works for wild cards as well                                

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
                        myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] + ((tabLen + 1) * 35)
                    end

                    print(who.." has played "..myEnvs[index][availChain][tabLen + 1]["cardData"]["Name"] .. " card on top of " .. myEnvs[index][availChain][tabLen]["cardData"]["Name"] .. ".") 
                end
            end
        end 

        if played then
            gameLogic:RemoveFromHand(myCard, myHand)
            return true
        else
            return false  
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


-------------------------------------------------
 
return gameLogic



