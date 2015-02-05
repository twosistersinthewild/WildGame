local composer = require( "composer" )
local GLOB = require "globals"
local utilities = require "functions.Utilities"
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local deck, hand, drawPile, curEco
local activeEnvs = {}
--local env1
--local env2
--local env3
local deckIndex = 1
local maxEnvirons = 3
local maxDiets = 5

--controls
local testLabel

---------------------------------------------------------------------------------



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

-- cards will be dealt to hand
--@params: num is number of cards to draw. myHand is the hand to deal cards to (can be player or npc)
function scene:drawCards( num, myHand )
    
    -- todo: make sure there is a card to draw or this will crash. i think this is fixed
    
    local numDraw = deckIndex + num - 1 -- todo make sure this is ok  
    
    for i = deckIndex, numDraw, 1 do -- start from deckIndex and draw the number passed in. third param is step
        
        if deck[i] then -- make sure there is a card to draw
            -- insert the card into the hand, then nil it from the deck
            table.insert(myHand, deck[i])

            print("You have been dealt the " .. deck[i].Name .. " card.")
            deck[i] = nil
        else
            -- the draw pile is empty
            -- todo: deal with this by either reshuffling discard or ending game
            print("There are no cards left to draw.")
        end
        
    end
    
    -- increment the deck index for next deal
    deckIndex = deckIndex + num
    
    
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
                            cardValue = activeEnvs[i][chainStr][j].Value
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
            if hand[ind].Type == "Environment" then   
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
                        hand[ind] = nil
                        print(activeEnvs[j]["activeEnv"].Name .. " environment card has been played.") 

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
            elseif hand[ind].Type == "Small Plant" or hand[ind].Type == "Large Plant" then
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
                            for myEnv = 1, 4 do
                                local myEnvSt = "Env"..myEnv                            

                                if hand[ind][myEnvSt] and hand[ind][myEnvSt] == envType then
                                    envMatch = true
                                    break
                                end
                            end

                            if envMatch then
                                -- create the table for the food chain
                                activeEnvs[j][availChain] = {}
                                
                                -- assign the plant to first postion of the food chain array chosen above
                                activeEnvs[j][availChain][1] = hand[ind]
                                
                                played = true
                                -- remove the card from the hand
                                hand[ind] = nil
                                print(activeEnvs[j][availChain][1].Name .. " card has been played on top of " .. activeEnvs[j]["activeEnv"].Name .. ".") 
                            else                                
                                print("I didn't get a type")--todo: remove this
                            end
                        end

                    end  

                    if space then
                        break
                    end                
                end
            -- invertebrate
            elseif hand[ind].Type == "Invertebrate" or hand[ind].Type == "Small Animal" or hand[ind].Type == "Large Animal" or hand[ind].Type == "Apex" then
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
                                local foodType = activeEnvs[j]["chain1"][tabLen].Type
                                
                                -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                                if foodType == "Small Plant" or foodType == "Large Plant" then
                                    foodType = "Plant"
                                end
                                
                                -- loop through the card's available diets and try to match the chain
                                for diet = 1, maxDiets do
                                    local dietString = "Diet"..diet.."_Type"
                                                                    
                                    -- if this is true, there is space and the last card in the chain is edible
                                    if hand[ind][dietString] and hand[ind][dietString] == foodType then
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
                                local foodType = activeEnvs[j]["chain2"][tabLen].Type
                                
                                -- since other creatures don't discriminate between sm and lg plant, change the string to just Plant
                                if foodType == "Small Plant" or foodType == "Large Plant" then
                                    foodType = "Plant"
                                end
                                
                                -- loop through the card's available diets and try to match the chain
                                for diet = 1, maxDiets do
                                    local dietString = "Diet"..diet.."_Type"
                                                                    
                                    -- if this is true, there is space and the last card in the chain is edible
                                    if hand[ind][dietString] and hand[ind][dietString] == foodType then
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

                            -- see if any of the animal's' places to live match the environment played
                            for myEnv = 1, 4 do
                                local myEnvSt = "Env"..myEnv                            

                                if hand[ind][myEnvSt] and hand[ind][myEnvSt] == envType then
                                    envMatch = true
                                    break
                                end
                            end

                            -- add it to chain, change its value, nil it from hand
                            if envMatch then
                                local valueStr = "Diet"..dietValue.."_Value"                                
                                
                                hand[ind].Value = hand[ind][valueStr]
                                
                                -- assign to next available spot in the table
                                activeEnvs[j][availChain][tabLen + 1] = hand[ind]
                                
                                played = true
                                -- remove the card from the hand
                                hand[ind] = nil
                                print(activeEnvs[j][availChain][tabLen + 1].Name .. " card has been played on top of " .. activeEnvs[j][availChain][tabLen].Name .. ".") 
                            else                                
                                print("I didn't get a type")--todo: remove this
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
end


function scene:testfx()
    
    -- a line for testing git
    --another test

    
    deck = GLOB.deck
    hand = {}
    
    
    --local deckSize = scene:tableLength(deck)
    
    -- deck should be shuffled after this
    scene:shuffleDeck(deck)
    
    -- pass 5 cards out to the player
    scene:drawCards(5,hand)
    
    -- flip over a card and add to discard if we want
    
    -- todo change this from an automated process
    
    --scene:PlayCard()

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
    
    -- touch demo
    local frontObject = display.newRect( 100, 100, 150, 150 )
    frontObject.alpha = 0.8
    frontObject.name = "Front Object"
    local frontLabel = display.newText( { text = "Play Card", x = 100, y = 100, fontSize = 28 } )
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
    
    local endTurnBtn = display.newRect( 100, 300, 150, 150 )
    endTurnBtn.alpha = 0.8
    endTurnBtn.name = "Front Object"
    local endTurnLbl = display.newText( { text = "End Turn", x = 100, y = 300, fontSize = 28 } )
    endTurnLbl:setTextColor( 1 )
    
    local function endTurnListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:EndTurn()
    end    
    
    endTurnBtn:addEventListener( "tap", endTurnListener )
    
    
    --
    local drawCardBtn = display.newRect( 100, 500, 150, 150 )
    drawCardBtn.alpha = 0.8
    drawCardBtn.name = "Front Object"
    local drawCardLbl = display.newText( { text = "Draw Card", x = 100, y = 500, fontSize = 28 } )
    drawCardLbl:setTextColor( 1 )
    
    local function drawCardListener( event )
        local object = event.target
        scene:drawCards(1,hand)
    end    
    
    drawCardBtn:addEventListener( "tap", drawCardListener )    
    --
    
    -- touch demo
    --[[
    local backObject = display.newRect( 25, 25, 150, 150 )
    backObject.alpha = 0.5
    backObject.name = "Back Object"
    local frontObject = display.newRect( 75, 75, 150, 150 )
    frontObject.alpha = 0.8
    frontObject.name = "Front Object"
    local backLabel = display.newText( { text = "", x = 0, y = 0, fontSize = 28 } )
    backLabel:setTextColor( 0 ) ; backLabel.x = 100 ; backLabel.y = 45
    local frontLabel = display.newText( { text = "", x = 0, y = 0, fontSize = 28 } )
    frontLabel:setTextColor( 0 ) ; frontLabel.x = 150 ; frontLabel.y = 200
    local function tapListener( event )
    local object = event.target
    print( object.name.." TAPPED!" )
    end
    local function touchListener( event )
    local object = event.target
    print( event.target.name.." TOUCH on the '"..event.phase.."' Phase!" )
    end
    --add "tap" event listener to back object and update text label
    backObject:addEventListener( "tap", tapListener )
    backLabel.text = "tap"
    --add "tap" event listener to front object and update text label
    frontObject:addEventListener( "tap", tapListener )
    frontLabel.text = "tap"    
    --]]
    
    
end


function scene:create( event )

   local sceneGroup = self.view

   -- Initialize the scene here.
   -- Example: add display objects to "sceneGroup", add touch listeners, etc.
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
          
        
        local cardBack = display.newImage( "/images/assets/v2-Back.jpg", 300, 500 )
        --sceneGroup:insert(cardBack)
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

