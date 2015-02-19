local composer = require( "composer" )
local widget = require "widget"
local GLOB = require "globals"
local utilities = require "functions.Utilities"
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local deck = {}
local hand, discardPile, curEco
local activeEnvs = {}
--local env1
--local env2
--local env3
local deckIndex = 1
local maxEnvirons = 3
local maxDiets = 5
local firstTurn = true -- flag 

-- values for card size
-- todo see if this needs to change
local cardHeight = 160
local cardWidth = 100
local scrollYPos = cardHeight / 2 
local scrollXPos = cardWidth / 2

--controls
local testLabel
local discardImage
local mainGroup
local scrollView

-- locations for on screen elements
local envLocs = {} -- locations that environment cards will be placed
local chainLocs = {}

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

-- from damian's code'            
local function movementListener(event)

    local self = event.target

    if event.phase == "began" then
        --new
        self.x = event.target.x;
        self.y = display.contentHeight - (cardHeight / 2)

        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  

        --new
        mainGroup:insert(self)
        self:toFront()
        scrollView.isVisible = false
        print(self.markX, self.markY, self.x, self.y);
    elseif event.phase == "moved"  then
        local x = (event.x - event.xStart) + self.markX
        local y = (event.y - event.yStart) + self.markY
        self.x, self.y = x, y    -- move object based on calculations above    
    elseif event.phase == "ended" then
        -- try to click into place
            -- make sure to move card to appropriate table (env, discard, etc)
            -- at this point, check can be made to put card into playfield and snap back to hand if it can't be played
        -- or snap back to hand if not in a valid area

        -- may need to remove the listener here?

        local validLoc = ""

        validLoc = scene:ValidLocation(self)
        


        -- if card hasn't been moved to a valid place, snap it back to the hand
        if not validLoc then
            scrollView:insert(self)
            scene:AdjustScroller()
        elseif validLoc == "play" then
            scene:PlayCard2(self)
        elseif validLoc == "discard" then
            print("discard")
        end

        scrollView.isVisible = true
    end

    return true
end 

function scene:ValidLocation(myCard)
    
    -- determine if being dropped back into hand as well
    
    -- over discard pile
    if myCard.x >= 850 - cardWidth/2 and 850 + cardWidth/2 and myCard.y >= 100 - cardHeight/2 and myCard.x >= 100 + cardHeight/2 then
        return "discard"
    else
        return nil
    end
    --[[]
    if myCard["cardData"].Type == "Environment" then
        if (myCard.x >= envLocs[1]["xLoc"] / 2 and myCard.x <= envLocs[1]["xLoc"] * 1.5) or
            (myCard.x >= envLocs[2]["xLoc"] / 2 and myCard.x <= envLocs[2]["xLoc"] * 1.5) or
            (myCard.x >= envLocs[3]["xLoc"] / 2 and myCard.x <= envLocs[3]["xLoc"] * 1.5) then
            
            return true
        
        end
        
    else
        return false
    end
    --]]
    
    
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
            scrollXPos = scrollXPos + cardWidth
            
            print("You have been dealt the " .. deck[i]["cardData"].Name .. " card.")     
            
            myImg:addEventListener( "touch", movementListener )
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
                    activeEnvs[j]["activeEnv"].x = envLocs[j]["xLoc"]
                    activeEnvs[j]["activeEnv"].y = envLocs[j]["yLoc"]
                    activeEnvs[j]["activeEnv"].rotation = 270                        

                    --myCard = nil
                    print(activeEnvs[j]["activeEnv"]["cardData"].Name .. " environment card has been played.") 


                    space = true
                    played = true
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
                        activeEnvs[j]["activeEnv"].x = envLocs[j]["xLoc"]
                        activeEnvs[j]["activeEnv"].y = envLocs[j]["yLoc"]
                        activeEnvs[j]["activeEnv"].rotation = 270                        
                        
                        hand[ind] = nil
                        print(activeEnvs[j]["activeEnv"]["cardData"].Name .. " environment card has been played.") 


                        space = true
                        played = true
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

                                played = true
                                
                                local myCard = activeEnvs[j][availChain][1]
                                
                                mainGroup:insert(activeEnvs[j][availChain][1])
                                myCard.x = chainLocs[j][availChain]["xLoc"]
                                myCard.y = chainLocs[j][availChain]["yLoc"]                                  
                                
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
                                
                                mainGroup:insert(activeEnvs[j][availChain][tabLen + 1])
                                myCard.x = chainLocs[j][availChain]["xLoc"]
                                myCard.y = chainLocs[j][availChain]["yLoc"] + ((tabLen + 1) * 15)
                                
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
    scrollXPos = cardWidth / 2    
    
    for i = 1, #hand do  
        hand[i].y = scrollYPos
        hand[i].x = scrollXPos
        scrollXPos = scrollXPos + cardWidth
    end
    
    scrollView:setScrollWidth(cardWidth * #hand)
    scrollView:scrollTo("left", {time=1200})
end

function scene:testfx()
    


    
    --deck = GLOB.deck
    hand = {}
    discardPile = {}
    
    
    --local deckSize = scene:tableLength(deck)
    
    -- deck should be shuffled after this
    scene:shuffleDeck(deck)
    
    -- pass 5 cards out to the player
    scene:drawCards(5,hand)
    
    -- flip over a card and add to discard if we want
    
    -- todo change this from an automated process
    
    --scene:PlayCard()


    
end

function scene:SetLocs()
    local chainY = 300
    
    envLocs[1] = {["xLoc"] = 100, ["yLoc"] = 250}
    envLocs[2] = {["xLoc"] = 350, ["yLoc"] = 250}
    envLocs[3] = {["xLoc"] = 600, ["yLoc"] = 250}
    chainLocs[1] = {["chain1"] = {["xLoc"] = 50, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 150, ["yLoc"] = chainY}}
    chainLocs[2] = {["chain1"] = {["xLoc"] = 300, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 400, ["yLoc"] = chainY}}
    chainLocs[3] = {["chain1"] = {["xLoc"] = 550, ["yLoc"] = chainY},["chain2"] = {["xLoc"] = 650, ["yLoc"] = chainY}}
end

function scene:create( event )

    scene:SetLocs()

    local sceneGroup = self.view
    mainGroup = display.newGroup() -- display group for anything that just needs added
    sceneGroup:insert(mainGroup)
    
    local imgString, paint, filename
 
    --local background = display.newRect(display.contentWidth/2, display.contentHeight/2, display.contentWidth, display.contentHeight)
    local background = display.newImage("images/background-create-cafe.jpg")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2
    --background:setFillColor(.3,.3,.3)
    --sceneGroup:insert(background)
    mainGroup:insert(background)

    
    scrollView = widget.newScrollView
    {
        --Originals
        --left = 37.5,
        --top = 225,
        --width = 460,
        --height = 100,
        --scrollWidth = 1200,
        --scrollHeight = 100,
        --verticalScrollDisabled = true

        --left = 0,
        --top = 225,
        --dimensions of scroll window
        --width = display.contentWidth,
        width = cardWidth * 5,
        height = cardHeight,

        verticalScrollDisabled = true,
        backgroundColor = {.5,.5,.5, 0} -- transparent. remove the 0 to see it
    }
                
    --location
    --scrollView.x = display.contentCenterX + 100
    scrollView.x = display.contentWidth / 2;
    scrollView.y = display.contentHeight - 80;    
    
    sceneGroup:insert(scrollView)
    

    -- create a rectangle for each card
    -- attach card data to the image as a table
    -- insert into main group
    -- they will sit on the draw pile for now
    -- actual card image will be shown once the card is put into play
    for i = 1, #GLOB.deck do
        deck[i] = display.newRect(725, 100, cardWidth, cardHeight)
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
   
       --[[
    local textOptions = {
    text = "Play Card",
    x = 100,
    y = 100,
    width = 350,
    height = 100,
    font = native.systemFont,
    fontSize = 20,
    align = "center", 
    onTap = self.PlayCard()
    }    

    testLabel = display.newText(textOptions) -- item description
    testLabel:setFillColor(1,1,1)
    --]]
    
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
    
    --local function touchListener( event )
    --    local object = event.target
    --    print( event.target.name.." TOUCH on the '"..event.phase.."' Phase!" )
    --end
    --add "tap" event listener to back object and update text label
    --backObject:addEventListener( "tap", tapListener )
    --backLabel.text = "tap"
    --add "tap" event listener to front object and update text label
    frontObject:addEventListener( "tap", tapListener )
    --    
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
        scene:testfx()
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

