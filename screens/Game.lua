local composer = require( "composer" )
local GLOB = require "globals"
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

local function drawCards( num, myHand )

    for i = deckIndex, num do
        -- insert the card into the hand, then nil it from the deck
        table.insert(myHand, deck[i])
        
        print("You have been dealt the " .. deck[i].Name .. " card.")
        deck[i] = nil
                
        
    end
    
    -- increment the deck index for next deal
    deckIndex = deckIndex + num
    
    
end

function scene:PlayCard()
        -- todo change this so that a click will try to play a certain card
        -- todo this is only for testing. the outer for loop will be thrown off by holes in hand table
        -- this will need to be addressed. using in pairs for hand might be better
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

                            --todo: change this to id perhaps
                            if activeEnvs[j]["activeEnv"].Name == "Rivers and Streams" then
                                envType = "RS"
                            elseif activeEnvs[j]["activeEnv"].Name == "Lakes and Ponds" then
                                envType = "LP"                            
                            elseif activeEnvs[j]["activeEnv"].Name == "Fields and Meadows" then
                                envType = "FM"                            
                            elseif activeEnvs[j]["activeEnv"].Name == "Forests and Woodlands" then
                                envType = "FW"                            
                            --!!human wildcard played
                            elseif activeEnvs[j]["activeEnv"].Type == "Wild" then
                                --todo need to check to make sure that another active chain on this card
                                -- hasn't already determined the type for the wild card'

                                -- todo need to determine how this is chosen and accounted for
                            end

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
            elseif hand[ind].Type == "Invertebrate" then
                -- check diet types against cards in play
                -- can eat plants and or invertebrates
                -- check environment
                -- if ok add to chain and set value appropriately
                 --[[]           
                local space = false
                local availChain = ""
                
                for j = 1, maxEnvirons do
                    if activeEnvs[j] then 
                        if activeEnvs[j]["chain1"] then
                            -- determine if anything can be eaten
                            if activeEnvs[j]["chain1"][1] then -- if there is a plant
                                
                                --space = true
                                --availChain = "chain1"   
                            --elseif invert 
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
    
    
    
    deck = GLOB.deck
    hand = {}
    
    --local deckSize = scene:tableLength(deck)
    
    -- deck should be shuffled after this
    scene:shuffleDeck(deck)
    
    -- pass 5 cards out to the player
    drawCards(10,hand)
    
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
    local frontObject = display.newRect( 150, 150, 150, 150 )
    frontObject.alpha = 0.8
    frontObject.name = "Front Object"
    local frontLabel = display.newText( { text = "Play Card", x = 150, y = 150, fontSize = 28 } )
    frontLabel:setTextColor( 1 )
    
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:PlayCard()
    end
    
    local function touchListener( event )
        local object = event.target
        print( event.target.name.." TOUCH on the '"..event.phase.."' Phase!" )
    end
    --add "tap" event listener to back object and update text label
    --backObject:addEventListener( "tap", tapListener )
    --backLabel.text = "tap"
    --add "tap" event listener to front object and update text label
    frontObject:addEventListener( "tap", tapListener )
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

