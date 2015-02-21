local composer = require( "composer" )
local widget = require "widget"
local GLOB = require "globals"
local utilities = require "functions.Utilities"
local gameLogic = require "functions.GameLogic"
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local deck = {}
local hand, discardPile, curEco, cpuHand
local activeEnvs = {}

-- number of cpu or other opponents
local numOpp = 0

local deckIndex = 1
local maxEnvirons = 3
local maxDiets = 5
local firstTurn = true -- flag 

-- values for card size
-- todo see if this needs to change

local scrollYPos = GLOB.cardHeight / 2 
local scrollXPos = GLOB.cardWidth / 2--display.contentWidth / 2

--controls
local testLabel
local discardImage
local mainGroup
local scrollView

-- locations for on screen elements
--local envLocs = {} -- locations that environment cards will be placed
--local chainLocs = {}

---------------------------------------------------------------------------------

-- todo enable strohmstead special ability to move plants

-- shuffle deck


-- deal 5 cards

-- 

-- count the number of elements from a passed in table and return the count
function scene:tableLength(myTable)
    local count = 0
    
    for k,v in pairs(myTable) do
        count = count + 1
    end
    
    return count
end

-- test this
function scene:shuffleDeck(myTable)
    local rand = math.random 
    --assert( myTable, "shuffleTable() expected a table, got nil" )
    local iterations = #myTable
    local j
    
    for i = iterations, 2, -1 do
        j = rand(i)
        myTable[i], myTable[j] = myTable[j], myTable[i]
    end
end

-- activated when a card has been dropped onto the discard pile
function scene:DiscardCard(myCard)
    table.insert(discardPile, myCard) -- insert the card in the last available position on discard
    mainGroup:insert(discardPile[#discardPile])
    discardPile[#discardPile]["x"] = 850
    discardPile[#discardPile]["y"] = 100    
    scene:AdjustHandTable(myCard)
end

-- nil a card out of the hand
-- this function will shift elements in the hand table to fill any holes after a card is played or discarded
function scene:AdjustHandTable(myCard)
    local index = 0
    
    for i = 1, #hand do
        if hand[i]["cardData"].ID == myCard["cardData"].ID then
            print (myCard["cardData"].Name.. " is the same as "..hand[i]["cardData"].Name)
            index = i
            hand[i] = nil
            break
        end   
    end
    
    while hand[index + 1] do
        hand[index] = hand[index + 1]
        hand[index + 1] = nil
        index = index + 1
    end
end

-- from damian's code'
-- movement of a card from the hand out onto the playfield
local function HandMovementListener(event)

    local self = event.target

    if event.phase == "began" then
        self.x, self.y = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview

        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  

        mainGroup:insert(self)
        self:toFront()
        scrollView.isVisible = false
        print(self.markX, self.markY, self.x, self.y);
    elseif event.phase == "moved"  then
        local x, y
        
        -- todo make sure the check for markX and setting it to a specific x and y don't cause a problem
        -- before adding that check it would sometimes crash and say that mark x or y had a nil value
        
        if self.markX then
            x = (event.x - event.xStart) + self.markX
        else 
            x = display.contentWidth/2
        end
        
        if self.markX then
            y = (event.y - event.yStart) + self.markY
        else
            y = display.contentWidth/2
        end
        
        self.x, self.y = x, y    -- move object based on calculations above    
    elseif event.phase == "ended" then
        -- try to click into place
            -- make sure to move card to appropriate table (env, discard, etc)
            -- at this point, check can be made to put card into playfield and snap back to hand if it can't be played
        -- or snap back to hand if not in a valid area

        -- may need to remove the listener here?

        local validLoc = ""
        local played = false
        
        -- get a string if the card has been dropped in a valid spot
        validLoc = gameLogic:ValidLocation(self)
        
        
        if not validLoc then -- if card hasn't been moved to a valid place, snap it back to the hand
            scrollView:insert(self)
         elseif validLoc == "discard" then
            self:removeEventListener("touch", HandMovementListener) -- todo may not need to remove this
            scene:DiscardCard(self)
        elseif validLoc ~= "" then
            for i = 1, 3 do
                if validLoc == "env"..i.."chain1" or validLoc == "env"..i.."chain2" then
                    -- try to play an env card
                   if self["cardData"].Type == "Environment" then
                       played = scene:PlayEnvironment(self, i)
                       break
                   -- try to play a plant card
                   elseif self["cardData"].Type == "Small Plant" or self["cardData"].Type == "Large Plant" then
                       if validLoc == "env"..i.."chain1" then
                           played = scene:PlayPlant(self, i, "chain1")
                           break
                       elseif validLoc == "env"..i.."chain2" then
                           played = scene:PlayPlant(self, i, "chain2")
                           break
                       end
                   elseif self["cardData"].Type == "Invertebrate" or self["cardData"].Type == "Small Animal" or self["cardData"].Type == "Large Animal" or self["cardData"].Type == "Apex" then
                       if validLoc == "env"..i.."chain1" then
                           played = scene:PlayAnimal(self, i, "chain1")
                           break
                       elseif validLoc == "env"..i.."chain2" then
                           played = scene:PlayAnimal(self, i, "chain2")
                           break
                       end                       
                   end
                   
                end
            end
            
        end   
            
            
        --elseif validLoc == "env1chain1" or validLoc == "env1chain2" then
           

          


        if not played and validLoc and validLoc ~= "discard" then
            scrollView:insert(self)
        elseif played then
            self:removeEventListener("touch", HandMovementListener)
            -- todo add any new listener that the card may need
        end

        scrollView.isVisible = true
        scene:AdjustScroller()
    end

    return true
end 

-- cards will be dealt to hand
--@params: num is number of cards to draw. myHand is the hand to deal cards to (can be player or npc)
function scene:drawCards( num, myHand )    
    local numDraw = deckIndex + num - 1 -- todo make sure this is ok  
    
    for i = deckIndex, numDraw, 1 do -- start from deckIndex and draw the number passed in. third param is step
        
        if deck[i] then -- make sure there is a card to draw
            -- insert the card into the hand, then nil it from the deck            
            table.insert(myHand, deck[i])

            local imgString = "/images/assets/"
            local filenameString = myHand[#myHand]["cardData"]["File Name"]
            imgString = imgString..filenameString

            --print(imgString)
            --print(myHand[#myHand].x)
            local paint = {
                type = "image",
                filename = imgString
            }

            
            local myImg = myHand[#myHand]
            myImg.fill = paint    
            
            scrollView:insert(myHand[#myHand])
            
            myImg.x = scrollXPos
            myImg.y = scrollYPos
            scrollXPos = scrollXPos + GLOB.cardWidth
            
            print("You have been dealt the " .. deck[i]["cardData"].Name .. " card.")     
            
            myImg:addEventListener( "touch", HandMovementListener )
            -- end from damian's code'
            
            deck[i] = nil
        else
            -- the draw pile is empty
            -- todo: deal with this by either reshuffling discard or ending game
            print("There are no cards left to draw.")
        end
        
    end
    
    -- increment the deck index for next deal
    deckIndex = deckIndex + num
    
    scene:AdjustScroller()
end

function scene:CalculateScore()
    -- run through activeEnvs
    -- run through each chain
    
    -- for each card found, flag the value in curEco for that spot of chain
    
    local envFound = false
    local tabLen = 0
    
    -- todo: might want to deal with this differently
    local curEco = {} -- clear the table first so that we only mark true if they are currently there
    local chainStr = "chain"
    
    for i = 1, maxEnvirons do 
        if activeEnvs[i] then
            if not envFound then -- only want to set this once, so once an env has been found this will not be true again
                envFound = true
                curEco[1] = true
            end
            
            -- todo: change this for loop if there are more than 2 possible chains
            for chainCount = 1, 2 do
                chainStr = "chain"..chainCount -- will have a value of "chain1" or "chain2"
                
                if activeEnvs[i][chainStr] then
                    tabLen = scene:tableLength(activeEnvs[i][chainStr])                            

                    local cardValue = 0

                    if tabLen > 0 then
                        for j = 1, tabLen do                        
                            cardValue = activeEnvs[i][chainStr][j]["cardData"].Value
                            curEco[cardValue] = true
                        end
                    end
                end
                
                
            end            
        end 
    end
    
    print("Current Score:")
    
    for i = 1, 10 do
        if curEco[i] then
            print(i..": ",curEco[i]) -- needed to use , here to concatenate a boolean value
        else
            print(i..": false")
        end
        
        
    end
    
end

function scene:EndTurn()
    
    --print("hello")
    -- shift control to npc
    
    -- determine current score    
    scene:CalculateScore()
    -- if there's a winner do something
    
end

-- discard the current hand and add it to the discard pile
-- todo: change this so that it discards one at a time or however it will work in actual game
-- make sure when this is changed to remove any potential holes from hand or discard
function scene:Discard(myHand)

    for i = 1, #myHand do
        table.insert(discardPile, myHand[i]) -- insert the first card in hand to the last available position on discard
        --myHand[i]:removeSelf()
        myHand[i] = nil
        mainGroup:insert(discardPile[#discardPile])
        discardPile[#discardPile].x = 850
        discardPile[#discardPile].y = 100
    end
    
    print("All cards in hand have been discarded")
end

--------------------------
-- try to play an environment card
--------------------------   
function scene:PlayEnvironment(myCard, index)
    local played = false          
         
    if myCard["cardData"].Type == "Environment" then
        if not activeEnvs[index] then
            -- create the env1 table
            activeEnvs[index] = {}

            -- the card for the enviro will be added here rather than in the hand
            -- todo deal with this better
            activeEnvs[index]["activeEnv"] = myCard

            -- insert the card to the mainGroup display and rotate it
            mainGroup:insert(activeEnvs[index]["activeEnv"])
            activeEnvs[index]["activeEnv"].x = GLOB.envLocs[index]["xLoc"]
            activeEnvs[index]["activeEnv"].y = GLOB.envLocs[index]["yLoc"]
            activeEnvs[index]["activeEnv"].rotation = 270                        

             print(activeEnvs[index]["activeEnv"]["cardData"].Name .. " environment card has been played.") 

            played = true
            activeEnvs[index]["activeEnv"]["cardData"].Played = true
        end

          
    end 
    
    if played then
        scene:AdjustHandTable(myCard)
        return true
    else
        return false
    end

end

--------------------------
-- try to play a plant card
--------------------------   
function scene:PlayPlant(myCard, index, availChain)
    if myCard["cardData"].Type == "Small Plant" or myCard["cardData"].Type == "Large Plant" then
        -- must have an environment to play on
        local played = false

        -- make sure an environment has already been played in this spot
        if activeEnvs[index] then             
            -- if the chain doesn't exist yet, a plant can be played on it
            if not activeEnvs[index][availChain] then
                -- make sure types match
                local envMatch = false

                --todo might need to check 2 envs for nature bites back
                local envType = ""
                envType = utilities:DetermineEnvType(activeEnvs, index)

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
                    activeEnvs[index][availChain] = {}

                    -- assign the plant to first postion of the food chain array chosen above
                    activeEnvs[index][availChain][1] = myCard                

                    -- place into the main display group in the proper position
                    mainGroup:insert(activeEnvs[index][availChain][1])
                    myCard.x = GLOB.chainLocs[index][availChain]["xLoc"]
                    myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] + 30                             

                    print(activeEnvs[index][availChain][1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[index]["activeEnv"]["cardData"].Name .. ".") 
                
                    played = true
                    myCard["cardData"].Played = true
                end
            end
            
            
            
            
        end   
        
        if played then
            scene:AdjustHandTable(myCard)
            return true
        else
            return false  
        end        
    end
end

--------------------------
-- try to play an invert or animal card
--------------------------   
function scene:PlayAnimal(myCard, index, availChain)
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
            if activeEnvs[index] then         
                    --todo: make sure there is something to eat on one of the chains
                    if activeEnvs[index][availChain] then
                            -- first get the table length to find the last card played on the chain
                            tabLen = scene:tableLength(activeEnvs[index][availChain])

                            if tabLen > 0 then
                                    local foodType = activeEnvs[index][availChain][tabLen]["cardData"].Type

                                    -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                                    if foodType == "Small Plant" or foodType == "Large Plant" then
                                            foodType = "Plant"
                                    end

                                    -- loop through the card's available diets and try to match the chain
                                    for diet = 1, maxDiets do
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

                            envType = utilities:DetermineEnvType(activeEnvs, index)

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
                                            if activeEnvs[index][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                                                    table.insert(supportedEnvs, activeEnvs[index][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
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
                                    activeEnvs[index][availChain][tabLen + 1] = myCard

                                    played = true
                                    myCard["cardData"].Played = true

                                    mainGroup:insert(activeEnvs[index][availChain][tabLen + 1])
                                    myCard.x = GLOB.chainLocs[index][availChain]["xLoc"]
                                    myCard.y = GLOB.chainLocs[index][availChain]["yLoc"] +  ((tabLen + 1) * 35)

                                    print(activeEnvs[index][availChain][tabLen + 1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[index][availChain][tabLen]["cardData"].Name .. ".") 
                            end
                    end
                    



            end 
            
            if played then
                scene:AdjustHandTable(myCard)
                return true
            else
                return false  
            end
    end 
end

function scene:PlayCard2(myCard)
        -- todo change this so that a click will try to play a certain card
        -- todo this is only for testing. the outer for loop will be thrown off by holes in hand table
        -- this will need to be addressed. using in pairs for hand might be better
        
        --todo account for strohmstead card
    local played = false
          
   
    if myCard then
        --------------------------
        -- try to play an environment card
        --------------------------            
        if myCard["cardData"].Type == "Environment" then   
            local space = false

            -- todo can change this to pass in a specific slot to check for when returning from a tap
            for j = 1, maxEnvirons do 
                if not activeEnvs[j] then
                    -- create the env1 table
                    activeEnvs[j] = {}

                    -- the card for the enviro will be added here rather than in the hand
                    -- todo deal with this better
                    activeEnvs[j]["activeEnv"] = myCard

                    -- remove the card from the hand
                    --todo might not want removeself here
                    --hand[ind]:removeSelf()
                    mainGroup:insert(activeEnvs[j]["activeEnv"])
                    activeEnvs[j]["activeEnv"].x = GLOB.envLocs[j]["xLoc"]
                    activeEnvs[j]["activeEnv"].y = GLOB.envLocs[j]["yLoc"]
                    activeEnvs[j]["activeEnv"].rotation = 270                        

                    --myCard = nil
                    print(activeEnvs[j]["activeEnv"]["cardData"].Name .. " environment card has been played.") 


                    space = true
                    played = true
                    activeEnvs[j]["activeEnv"]["cardData"].Played = true
                end

                -- break the loop. a card has been successfully played
                if space then
                    break
                end
            end
 --[[]
        --------------------------
        -- try to play a plant card
        --------------------------
        elseif myCard["cardData"].Type == "Small Plant" or myCard["cardData"].Type == "Large Plant" then
            -- must have an environment to play on
            local space = false
            local availChain = ""

            -- todo maxEnvirons could be substituted if a card allows up to 3 chains
            for j = 1, maxEnvirons do
                if activeEnvs[j] then                 
                    if not activeEnvs[j]["chain1"] then
                        space = true
                        availChain = "chain1"
                    end

                    if not space and not activeEnvs[j]["chain2"] then                            
                        space = true
                        availChain = "chain2"
                    end

                    if space then
                        -- make sure types match
                        local envMatch = false

                        --todo might need to check 2 envs for nature bites back
                        local envType = ""

                        envType = utilities:DetermineEnvType(activeEnvs, j)

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
                            activeEnvs[j][availChain] = {}

                            -- assign the plant to first postion of the food chain array chosen above
                            activeEnvs[j][availChain][1] = myCard

                            played = true

                            local myCard = activeEnvs[j][availChain][1]

                            mainGroup:insert(activeEnvs[j][availChain][1])
                            myCard.x = chainLocs[j][availChain]["xLoc"]
                            myCard.y = chainLocs[j][availChain]["yLoc"]                                  

                            -- remove the card from the hand
                            myCard = nil
                            print(activeEnvs[j][availChain][1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j]["activeEnv"]["cardData"].Name .. ".") 
                        end
                    end

                end  

                if space then
                    break
                end                
            end
        -- invertebrate
        elseif myCard["cardData"].Type == "Invertebrate" or myCard["cardData"].Type == "Small Animal" or myCard["cardData"].Type == "Large Animal" or myCard["cardData"].Type == "Apex" then
            -- todo may need a special case for apex to make it a 10 if played on a 9

            -- make sure there is an available chain to play on
            -- check diet types against cards in play
            -- check environment
            -- if ok add to chain and set value appropriately


            local space = false
            local availChain = ""
            local tabLen = 0
            local dietValue = 0

            -- todo maxEnvirons could be substituted if a card allows up to 3 chains
            for j = 1, maxEnvirons do
                if activeEnvs[j] then         
                    --todo: make sure there is something to eat on one of the chains
                    if activeEnvs[j]["chain1"] then
                        -- first get the table length to find the last card played on the chain
                        tabLen = scene:tableLength(activeEnvs[j]["chain1"])

                        if tabLen > 0 then
                            local foodType = activeEnvs[j]["chain1"][tabLen]["cardData"].Type

                            -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                            if foodType == "Small Plant" or foodType == "Large Plant" then
                                foodType = "Plant"
                            end

                            -- loop through the card's available diets and try to match the chain
                            for diet = 1, maxDiets do
                                local dietString = "Diet"..diet.."_Type"

                                -- if this is true, there is space and the last card in the chain is edible
                                if myCard["cardData"][dietString] and myCard["cardData"][dietString] == foodType then
                                    space = true
                                    availChain = "chain1"
                                    dietValue = diet
                                    break
                                end                                        
                            end                                
                        else
                            print("No card was in that position. You have an Error.")
                        end 
                    end

                    if not space and activeEnvs[j]["chain2"] then                            
                        -- first get the table length to find the last card played on the chain
                        tabLen = scene:tableLength(activeEnvs[j]["chain2"])

                        if tabLen > 0 then
                            local foodType = activeEnvs[j]["chain2"][tabLen]["cardData"].Type

                            -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                            if foodType == "Small Plant" or foodType == "Large Plant" then
                                foodType = "Plant"
                            end

                            -- loop through the card's available diets and try to match the chain
                            for diet = 1, maxDiets do
                                local dietString = "Diet"..diet.."_Type"

                                -- if this is true, there is space and the last card in the chain is edible
                                if myCard["cardData"][dietString] and myCard["cardData"][dietString] == foodType then
                                    space = true
                                    availChain = "chain2"
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

                        envType = utilities:DetermineEnvType(activeEnvs, j)

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
                                if activeEnvs[j][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                                    table.insert(supportedEnvs, activeEnvs[j][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
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
                            activeEnvs[j][availChain][tabLen + 1] = myCard

                            local myCard = activeEnvs[j][availChain][tabLen + 1]

                            played = true

                            mainGroup:insert(activeEnvs[j][availChain][tabLen + 1])
                            myCard.x = chainLocs[j][availChain]["xLoc"]
                            myCard.y = chainLocs[j][availChain]["yLoc"] + ((tabLen + 1) * 15)

                            -- remove the card from the hand
                            myCard = nil
                            print(activeEnvs[j][availChain][tabLen + 1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j][availChain][tabLen]["cardData"].Name .. ".") 
                        end
                    end

                end  

                if space then
                    break
                end                
            end
--]]
        end 
    end


    -- todo need to make sure this happens any time a card is played from hand
    -- may want to abstract it out to its own fx
    if played then
        -- loop up through deck from where card was played to fill empty hole
        -- if the card played was the last card in hand
        
        local curCard = 0
        
        for i = 1, #hand do
            if hand[i]["cardData"].ID == myCard["cardData"].ID then
                print (myCard["cardData"].Name.. " is the same as "..hand[i]["cardData"].Name)
                curCard = i
                hand[i] = nil
                break
            end   
        end
        
        
   
        while hand[curCard + 1] do
            hand[curCard] = hand[curCard + 1]
            --hand[curCard + 1]:removeSelf()
            hand[curCard + 1] = nil
            curCard = curCard + 1
        end

        -- since a card was played, break the loop so as not to continue checking more to play

    end
        
    
    
    if not played then
        print("No card to play.")    
    else
        
    end
    
    scene:AdjustScroller()
end


function scene:PlayCard()
        -- todo change this so that a click will try to play a certain card
        -- todo this is only for testing. the outer for loop will be thrown off by holes in hand table
        -- this will need to be addressed. using in pairs for hand might be better
        
        --todo account for strohmstead card
    local played = false
    
    local handSize = #hand
    
    for ind = 1, handSize do
                
   
        if hand[ind] then
            --------------------------
            -- try to play an environment card
            --------------------------            
            if hand[ind]["cardData"].Type == "Environment" then   
                local space = false

                -- todo can change this to pass in a specific slot to check for when returning from a tap
                for j = 1, maxEnvirons do 
                    if not activeEnvs[j] then
                        -- create the env1 table
                        activeEnvs[j] = {}

                        -- the card for the enviro will be added here rather than in the hand
                        -- todo deal with this better
                        activeEnvs[j]["activeEnv"] = hand[ind]

                        -- remove the card from the hand
                        --todo might not want removeself here
                        --hand[ind]:removeSelf()
                        mainGroup:insert(activeEnvs[j]["activeEnv"])
                        activeEnvs[j]["activeEnv"].x = GLOB.envLocs[j]["xLoc"]
                        activeEnvs[j]["activeEnv"].y = GLOB.envLocs[j]["yLoc"]
                        activeEnvs[j]["activeEnv"].rotation = 270                        
                        
                        hand[ind] = nil
                        print(activeEnvs[j]["activeEnv"]["cardData"].Name .. " environment card has been played.") 


                        space = true
                        played = true
                        activeEnvs[j]["activeEnv"]["cardData"].Played = true
                    end

                    -- break the loop. a card has been successfully played
                    if space then
                        break
                    end
                end
            --------------------------
            -- try to play a plant card
            --------------------------
            elseif hand[ind]["cardData"].Type == "Small Plant" or hand[ind]["cardData"].Type == "Large Plant" then
                -- must have an environment to play on
                local space = false
                local availChain = ""

                -- todo maxEnvirons could be substituted if a card allows up to 3 chains
                for j = 1, maxEnvirons do
                    if activeEnvs[j] then                 
                        if not activeEnvs[j]["chain1"] then
                            space = true
                            availChain = "chain1"
                        end

                        if not space and not activeEnvs[j]["chain2"] then                            
                            space = true
                            availChain = "chain2"
                        end

                        if space then
                            -- make sure types match
                            local envMatch = false

                            --todo might need to check 2 envs for nature bites back
                            local envType = ""

                            envType = utilities:DetermineEnvType(activeEnvs, j)

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

                                    if hand[ind]["cardData"][myEnvSt] and hand[ind]["cardData"][myEnvSt] == envType then
                                        envMatch = true
                                        break
                                    end
                                end
                            end
                            if envMatch then
                                -- create the table for the food chain
                                activeEnvs[j][availChain] = {}
                                
                                -- assign the plant to first postion of the food chain array chosen above
                                activeEnvs[j][availChain][1] = hand[ind]

                                
                                
                                
                                local myCard = activeEnvs[j][availChain][1]
                                played = true
                                myCard["cardData"].Played = true
                                
                                mainGroup:insert(activeEnvs[j][availChain][1])
                                myCard.x = GLOB.chainLocs[j][availChain]["xLoc"]
                                myCard.y = GLOB.chainLocs[j][availChain]["yLoc"] + 30                               
                                
                                -- remove the card from the hand
                                hand[ind] = nil
                                print(activeEnvs[j][availChain][1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j]["activeEnv"]["cardData"].Name .. ".") 
                            end
                        end

                    end  

                    if space then
                        break
                    end                
                end
            -- invertebrate
            elseif hand[ind]["cardData"].Type == "Invertebrate" or hand[ind]["cardData"].Type == "Small Animal" or hand[ind]["cardData"].Type == "Large Animal" or hand[ind]["cardData"].Type == "Apex" then
                -- todo may need a special case for apex to make it a 10 if played on a 9
                
                -- make sure there is an available chain to play on
                -- check diet types against cards in play
                -- check environment
                -- if ok add to chain and set value appropriately
                
                
                local space = false
                local availChain = ""
                local tabLen = 0
                local dietValue = 0

                -- todo maxEnvirons could be substituted if a card allows up to 3 chains
                for j = 1, maxEnvirons do
                    if activeEnvs[j] then         
                        --todo: make sure there is something to eat on one of the chains
                        if activeEnvs[j]["chain1"] then
                            -- first get the table length to find the last card played on the chain
                            tabLen = scene:tableLength(activeEnvs[j]["chain1"])
                            
                            if tabLen > 0 then
                                local foodType = activeEnvs[j]["chain1"][tabLen]["cardData"].Type
                                
                                -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                                if foodType == "Small Plant" or foodType == "Large Plant" then
                                    foodType = "Plant"
                                end
                                
                                -- loop through the card's available diets and try to match the chain
                                for diet = 1, maxDiets do
                                    local dietString = "Diet"..diet.."_Type"
                                                                    
                                    -- if this is true, there is space and the last card in the chain is edible
                                    if hand[ind]["cardData"][dietString] and hand[ind]["cardData"][dietString] == foodType then
                                        space = true
                                        availChain = "chain1"
                                        dietValue = diet
                                        break
                                    end                                        
                                end                                
                            else
                                print("No card was in that position. You have an Error.")
                            end 
                        end

                        if not space and activeEnvs[j]["chain2"] then                            
                            -- first get the table length to find the last card played on the chain
                            tabLen = scene:tableLength(activeEnvs[j]["chain2"])
                            
                            if tabLen > 0 then
                                local foodType = activeEnvs[j]["chain2"][tabLen]["cardData"].Type
                                
                                -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                                if foodType == "Small Plant" or foodType == "Large Plant" then
                                    foodType = "Plant"
                                end
                                
                                -- loop through the card's available diets and try to match the chain
                                for diet = 1, maxDiets do
                                    local dietString = "Diet"..diet.."_Type"
                                                                    
                                    -- if this is true, there is space and the last card in the chain is edible
                                    if hand[ind]["cardData"][dietString] and hand[ind]["cardData"][dietString] == foodType then
                                        space = true
                                        availChain = "chain2"
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

                            envType = utilities:DetermineEnvType(activeEnvs, j)

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
                                    if activeEnvs[j][availChain][1]["cardData"]["Env"..pos] then -- access the plant in the chain's environments
                                        table.insert(supportedEnvs, activeEnvs[j][availChain][1]["cardData"]["Env"..pos]) -- insert the env string that the plant supports
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

                                    if hand[ind]["cardData"][myEnvSt] and hand[ind]["cardData"][myEnvSt] == envType then
                                        envMatch = true
                                        break
                                    end
                                end
                            end
                            

                            -- add it to chain, change its value, nil it from hand
                            if envMatch then
                                local valueStr = "Diet"..dietValue.."_Value"                                
                                
                                hand[ind]["cardData"].Value = hand[ind]["cardData"][valueStr]
                                
                                -- assign to next available spot in the table
                                activeEnvs[j][availChain][tabLen + 1] = hand[ind]
                                
                                local myCard = activeEnvs[j][availChain][tabLen + 1]
                                
                                played = true
                                myCard["cardData"].Played = true
                                
                                mainGroup:insert(activeEnvs[j][availChain][tabLen + 1])
                                myCard.x = GLOB.chainLocs[j][availChain]["xLoc"]
                                myCard.y = GLOB.chainLocs[j][availChain]["yLoc"] +  ((tabLen + 1) * 35)
                                
                                -- remove the card from the hand
                                hand[ind] = nil
                                print(activeEnvs[j][availChain][tabLen + 1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j][availChain][tabLen]["cardData"].Name .. ".") 
                            end
                        end

                    end  

                    if space then
                        break
                    end                
                end
                
            end 
        end
        
        
        -- todo need to make sure this happens any time a card is played from hand
        -- may want to abstract it out to its own fx
        if played then
            -- loop up through deck from where card was played to fill empty hole
            -- if the card played was the last card in hand
            local curCard = ind
            while hand[curCard + 1] do
                hand[curCard] = hand[curCard + 1]
                --hand[curCard + 1]:removeSelf()
                hand[curCard + 1] = nil
                curCard = curCard + 1
            end
            
            -- since a card was played, break the loop so as not to continue checking more to play
            break
        end
        
    end
    
    if not played then
        print("No card to play.")    
    else
        
    end
    
    scene:AdjustScroller()
end

-- reset back to original position, then adjust each card's x value. 
-- this seems to fill in gaps properly and adjust the size as desired. 
function scene:AdjustScroller()    
    scrollXPos = GLOB.cardWidth / 2    
    
    for i = 1, #hand do  
        hand[i].y = scrollYPos
        hand[i].x = scrollXPos
        scrollXPos = scrollXPos + GLOB.cardWidth
    end
    
    scrollView:setScrollWidth(GLOB.cardWidth * #hand)
    scrollView:scrollTo("left", {time=1200})
end

function scene:InitializeGame()
    


    
    --initialize tables for where cards will be stored
    hand = {}
    discardPile = {}
    
    if numOpp > 0 then
        for i = 1, numOpp do
            cpuHand[numOpp] = {}
            
            
        end
        
        
        
    end
    
    
    --local deckSize = scene:tableLength(deck)
    
    -- deck should be shuffled after this
    scene:shuffleDeck(deck)
    
    -- pass 5 cards out to the player
    scene:drawCards(5,hand)
    
    -- flip over a card and add to discard if we want
    
    -- todo change this from an automated process
    
    --scene:PlayCard()


    
end

--[[]
function scene:SetLocs()
    local chainY = 300
    
    envLocs[1] = {["xLoc"] = 100, ["yLoc"] = 250}
    envLocs[2] = {["xLoc"] = 350, ["yLoc"] = 250}
    envLocs[3] = {["xLoc"] = 600, ["yLoc"] = 250}
    chainLocs[1] = {["chain1"] = {["xLoc"] = 50, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 150, ["yLoc"] = chainY}}
    chainLocs[2] = {["chain1"] = {["xLoc"] = 300, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 400, ["yLoc"] = chainY}}
    chainLocs[3] = {["chain1"] = {["xLoc"] = 550, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 650, ["yLoc"] = chainY}}
end
--]]
function scene:create( event )

    --scene:SetLocs()

    local sceneGroup = self.view
    mainGroup = display.newGroup() -- display group for anything that just needs added
    sceneGroup:insert(mainGroup)
    
    local imgString, paint, filename
 
    local background = display.newImage("images/background-create-cafe.jpg")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2

    mainGroup:insert(background)
    
    scrollView = widget.newScrollView
    {
        width = GLOB.cardWidth * 5,
        height = GLOB.cardHeight,

        verticalScrollDisabled = true,
        backgroundColor = {.5,.5,.5, 0} -- transparent. remove the 0 to see it
    }
                
    --location
    scrollView.x = display.contentWidth / 2;    
    scrollView.y = display.contentHeight - 80;    
    
    sceneGroup:insert(scrollView)
    

    -- create a rectangle for each card
    -- attach card data to the image as a table
    -- insert into main group
    -- they will sit on the draw pile for now
    -- actual card image will be shown once the card is put into play
    for i = 1, #GLOB.deck do
        deck[i] = display.newRect(725, 100, GLOB.cardWidth, GLOB.cardHeight)
        deck[i]["cardData"] = GLOB.deck[i]
        mainGroup:insert(deck[i])
    end    
    

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    -- create a rect to use for discard pile display
    -- this will be "filled" with a card image once a discard has occurred

    -- initialize the discard pile image and add to scene group
    -- no image shown currently, just a white rect
    -- todo change this
    discardImage = display.newRect(850, 100, 100, 160) 
    --discardImage.Whatever = "hello"
    --print(discardImage.Whatever)
    discardImage:setFillColor(.5,.5,.5)
    mainGroup:insert(discardImage)             
        
    -- show the back of the card for the draw pile
    local cardBack = display.newRect( 725, 100, 100, 160 )
    paint = {
        type = "image",
        filename = "/images/assets/v2-Back.jpg"
    }    
    
    cardBack.fill = paint
    mainGroup:insert(cardBack)
       
    local btnY = 50
    
    -- touch demo
    local frontObject = display.newRect( 75, btnY, 100, 100 )
    frontObject:setFillColor(.5,.5,.5)
    frontObject.name = "Front Object"
    local frontLabel = display.newText( { text = "Play Card", x = 75, y = btnY, fontSize = 16 } )
    frontLabel:setTextColor( 1 )
    
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:PlayCard()
    end
    
    frontObject:addEventListener( "tap", tapListener )

    mainGroup:insert(frontObject)
    mainGroup:insert(frontLabel)
    
    local endTurnBtn = display.newRect( 220, btnY, 200 * .75, 109 * .75)
    
    imgString = "/images/button-end-turn.jpg"
    
    local paint = {
        type = "image",
        filename = imgString
    }
    
    endTurnBtn.fill = paint   
    
    local function endTurnListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:EndTurn()
    end    
    
    endTurnBtn:addEventListener( "tap", endTurnListener )
    mainGroup:insert(endTurnBtn)    
    --
    
    --local drawCardBtn = display.newRect( 400, btnY, 200 * .75, 109 * .75 )
    
    imgString = "/images/button-draw-a-card.jpg"
    
    local paint = {
        type = "image",
        filename = imgString
    }
    
    --drawCardBtn.fill = paint       
    
    local function drawCardListener( event )
        local object = event.target
        scene:drawCards(1,hand)
    end    
    
    --drawCardBtn:addEventListener( "tap", drawCardListener )
    cardBack:addEventListener( "tap", drawCardListener ) 
    --mainGroup:insert(drawCardBtn)
    
    local discardBtn = display.newRect( 580, btnY, 200 * .75, 109 * .75 )
    
    imgString = "/images/button-discard-card.jpg"
    
    local paint = {
        type = "image",
        filename = imgString
    }
    
    discardBtn.fill = paint         
    
    local function discardListener( event )
        --local object = event.target
        scene:Discard(hand)
    end    
    
    discardBtn:addEventListener( "tap", discardListener )  
    mainGroup:insert(discardBtn)
    --
end

-- "scene:show()"
function scene:show( event )

   local sceneGroup = self.view
   local phase = event.phase

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
   elseif ( phase == "did" ) then
      -- Called when the scene is now on screen.
      -- Insert code here to make the scene come alive.
      -- Example: start timers, begin animation, play audio, etc.
        scene:InitializeGame()
   end
end

-- "scene:hide()"
function scene:hide( event )

   local sceneGroup = self.view
   local phase = event.phase

   if ( phase == "will" ) then
      -- Called when the scene is on screen (but is about to go off screen).
      -- Insert code here to "pause" the scene.
      -- Example: stop timers, stop animation, stop audio, etc.
   elseif ( phase == "did" ) then
      -- Called immediately after scene goes off screen.
   end
end

-- "scene:destroy()"
function scene:destroy( event )

   local sceneGroup = self.view

   -- Called prior to the removal of scene's view ("sceneGroup").
   -- Insert code here to clean up the scene.
   -- Example: remove display objects, save state, etc.
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------------

return scene

