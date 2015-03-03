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
local activeEnvs = {} -- player cards on playfield
local cpuActiveEnvs = {} -- cpu cards on playfield

-- number of cpu or other opponents
local numOpp = 0

local deckIndex = 1
local maxEnvirons = 3
local firstTurn = true -- flag 
local tapCounter = 0 -- flag
local strohm = false -- flag for when strohmstead is on playfield
-- todo make sure strohm flag is set properly when strohmstead is played and set when it is discarded

-- variables for the scroller x and y
local scrollYPos = GLOB.cardHeight / 2 
local scrollXPos = GLOB.cardWidth / 2--display.contentWidth / 2

--controls
local discardImage
local mainGroup
local oppGroup -- display's opponent cards
local scrollView
local overlay
local logScroll
local logScrollWidth = 350
local scrollY = 10 -- this will allow the first item added to be in the right position

local HandMovementListener

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

-- shuffle elements in table
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

-- activated when a *single* card has been dropped onto the discard pile
-- can be used by player and cpu
function scene:DiscardCard(myCard, myHand, origin)
    table.insert(discardPile, myCard) -- insert the card in the last available position on discard
    mainGroup:insert(discardPile[#discardPile])
    discardPile[#discardPile]["x"] = GLOB.discardXLoc
    discardPile[#discardPile]["y"] = GLOB.discardYLoc    
    
    -- when discarded, return the card to its original value since it might have changed if it had been played
    -- plants will become a 2 or 3, everything else will get a default value of 1
    if discardPile[#discardPile]["cardData"].Type == "Small Plant" then
        discardPile[#discardPile]["cardData"]["Value"] = 2
    elseif discardPile[#discardPile]["cardData"]["Type"] == "Large Plant" then        
        discardPile[#discardPile]["cardData"]["Value"] = 3
    else
        discardPile[#discardPile]["cardData"]["Value"] = 1
    end
    
    scene:GameLogAdd(discardPile[#discardPile]["cardData"]["Name"].." has been discarded.")	
	    
    if origin == "hand" then
        gameLogic:RemoveFromHand(myCard, myHand)
    end
end

-- discard the *entire current hand* and add it to the discard pile table
-- last card discarded will appear on top of discard pile
function scene:DiscardHand(myHand)

    for i = 1, #myHand do
        table.insert(discardPile, myHand[i]) -- insert the first card in hand to the last available position on discard
        myHand[i] = nil
        mainGroup:insert(discardPile[#discardPile])
        discardPile[#discardPile]["x"] = GLOB.discardXLoc
        discardPile[#discardPile]["y"] = GLOB.discardYLoc
        
        -- when discarded, return the card to its original value since it might have changed if it had been played
        -- plants will become a 2 or 3, everything else will get a default value of 1
        if discardPile[#discardPile]["cardData"].Type == "Small Plant" then
            discardPile[#discardPile]["cardData"]["Value"] = 2
        elseif discardPile[#discardPile]["cardData"]["Type"] == "Large Plant" then        
            discardPile[#discardPile]["cardData"]["Value"] = 3
        else
            discardPile[#discardPile]["cardData"]["Value"] = 1
        end
    end
    
    scene:GameLogAdd("All cards in hand have been discarded")
end

-- for moving a card out of discard
local function DiscardMovementListener(event)
    
    
    
end


-- aww
-- listener for cards out on the playfield to move them around
local function FieldMovementListener(event)

    local self = event.target

    if event.phase == "began" then
        --self.x, self.y = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview
        self.originalX = self.x -- store starting x. needed if card will snap back
        self.originalY = self.y -- store starting y
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  

        -- figure out type and where in chain then drag rest of cards
        -- todo: can plants be brought off at all?

        self:toFront()
        display.getCurrentStage():setFocus(event.target)
        print(self.markX, self.markY, self.x, self.y);
    elseif event.phase == "moved" and self.x>0 and self.x<display.contentWidth and (self.y - self.height/2)> 0 and self.y < (display.contentHeight - self.height/2.5)then
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
    elseif event.phase == "ended" then -- try to click into place
        display.getCurrentStage():setFocus(nil)
        
         -- make sure to move card to appropriate table (env, discard, etc)
        -- or snap back to hand if not in a valid area

        -- may need to remove the listener here?

        local validLoc = ""
        local played = false
        local playedString = ""
        
        -- get a string if the card has been dropped in a valid spot
        validLoc = gameLogic:ValidLocation(self)
        
        -- need to know
        -- type, env, chain
        
        local envNum, myChain, myIndex
        
        if not validLoc then
            self.x = self.originalX
            self.y = self.originalY
        elseif validLoc == "discard" then
            -- any card on playfield can be put in discard
            -- when discarded, the lowest level card is compared when in a chain
            -- if it is an environment, then it and any plant will be discarded.
            -- if it is an environment, any animals on its chain will be put in hand
            
            self:removeEventListener("touch", FieldMovementListener)
            
            if gameLogic:GetStat(self, "Value") == 1 then  -- rotate image to appear properly
                self["rotation"] = 0
            end            
            
            --
            envNum, myChain, myIndex = gameLogic:GetMyEnv(self, activeEnvs)
            
            if gameLogic:GetStat(self, "Value") == 1 then
                if activeEnvs[envNum] then
                    
                    -- if the env has chains on it, move the cards to hand or discard
                    for i = 1, 2 do
                        if activeEnvs[envNum]["chain"..i] then
                            
                            local chainSize = #activeEnvs[envNum]["chain"..i]
                            local chainCount = 0
                            
                           -- it will work backwards through the chain from highest played card 
                            while chainSize > chainCount do                               
                                
                                local ind = chainSize - chainCount
                                local myCard = activeEnvs[envNum]["chain"..i][ind]
                                
                                -- do what needs to be done to card here
                                -- if plant move to discard
                                -- if animal, move to hand    
                                
                                myCard:removeEventListener("touch", FieldMovementListener)

                                if myCard["cardData"]["Type"] == "Small Plant" or myCard["cardData"]["Type"] == "Large Plant" then
                                    
                                    -- add to discard pile                                    
                                    scene:DiscardCard(myCard, hand, "field")
                                    myCard:addEventListener( "touch", DiscardMovementListener )   
                                    
                                    activeEnvs[envNum]["chain"..i][ind] = nil
                                
                                else -- **other cards can be put back in hand
                                    
                                    -- set value back to default 1
                                    gameLogic:SetStat(myCard, "Value", 1) 
                                    
                                    -- insert card into hand
                                    table.insert(hand, activeEnvs[envNum]["chain"..i][ind])
                                    local myImg = hand[#hand]
                                    scrollView:insert(hand[#hand])
                                    myImg.x = scrollXPos
                                    myImg.y = scrollYPos
                                    scrollXPos = scrollXPos + GLOB.cardWidth 

                                    myImg:addEventListener( "touch", HandMovementListener )                
                                    --myImg:addEventListener( "tap", ZoomTapListener )


                                    activeEnvs[envNum]["chain"..i][ind] = nil  

                                    scene:AdjustScroller()

                                end
                                
                                chainCount = chainCount + 1
                            end                           
                            
                            -- nil chain here
                            activeEnvs[envNum]["chain"..i] = nil
                        end
                    end                                    
                    
                    -- add env card to discard pile                                    
                    scene:DiscardCard(activeEnvs[envNum]["activeEnv"], hand, "field")
                    self:addEventListener( "touch", DiscardMovementListener )   


                    -- nil env card here
                    activeEnvs[envNum]["activeEnv"] = nil                    
                    
                    -- nil out the playfield table so that a new environment can be played
                    activeEnvs[envNum] = nil
                end                
            elseif gameLogic:GetStat(self, "Value") == 2 or gameLogic:GetStat(self, "Value") == 3 then
                if activeEnvs[envNum][myChain] then                    
                    local chainSize = #activeEnvs[envNum][myChain]
                    local chainCount = 0 
                    
                    -- it will work backwards through the chain from highest played card 
                    while chainSize > chainCount do  
                         local ind = chainSize - chainCount
                         local myCard = activeEnvs[envNum][myChain][ind]

                         -- do what needs to be done to card here
                         -- if plant move to discard
                         -- if animal, move to hand
                         --activeEnvs[envNum]["chain"..i][ind]

                        myCard:removeEventListener("touch", FieldMovementListener)

                        if myCard["cardData"]["Type"] == "Small Plant" or myCard["cardData"]["Type"] == "Large Plant" then
                            -- add to discard pile                                    
                            scene:DiscardCard(myCard, hand, "field")
                            myCard:addEventListener( "touch", DiscardMovementListener )   

                            activeEnvs[envNum][myChain][ind] = nil
                        else
                            -- set value back to default 1
                            gameLogic:SetStat(myCard, "Value", 1) 

                            -- insert card into hand
                            table.insert(hand, activeEnvs[envNum][myChain][ind])
                            local myImg = hand[#hand]
                            scrollView:insert(hand[#hand])
                            myImg.x = scrollXPos
                            myImg.y = scrollYPos
                            scrollXPos = scrollXPos + GLOB.cardWidth 

                            myImg:addEventListener( "touch", HandMovementListener )                
                            --myImg:addEventListener( "tap", ZoomTapListener )

                            activeEnvs[envNum][myChain][ind] = nil  

                            scene:AdjustScroller()
                        
                        end

                        chainCount = chainCount + 1
                    end   
                    
                    activeEnvs[envNum][myChain] = nil -- nil chain here      
                end                
            else -- animals
                if activeEnvs[envNum][myChain] then                    
                    local chainSize = #activeEnvs[envNum][myChain]
                    local chainCount = 0 
                    
                    -- it will work backwards through the chain from highest played card 
                    while chainSize - myIndex >= chainCount do  
                         local ind = chainSize - chainCount
                         local myCard = activeEnvs[envNum][myChain][ind]

                         -- do what needs to be done to card here
                         -- if plant move to discard
                         -- if animal, move to hand
                         --activeEnvs[envNum]["chain"..i][ind]

                        myCard:removeEventListener("touch", FieldMovementListener)

                        -- set value back to default 1
                        gameLogic:SetStat(myCard, "Value", 1) 

                        if self["cardData"]["ID"] == activeEnvs[envNum][myChain][ind]["cardData"]["ID"] then
                            -- add to discard pile                                    
                            scene:DiscardCard(myCard, hand, "field")
                            myCard:addEventListener( "touch", DiscardMovementListener )
                        else
                            -- insert card into hand
                            table.insert(hand, activeEnvs[envNum][myChain][ind])
                            local myImg = hand[#hand]
                            scrollView:insert(hand[#hand])
                            myImg.x = scrollXPos
                            myImg.y = scrollYPos
                            scrollXPos = scrollXPos + GLOB.cardWidth 

                            myImg:addEventListener( "touch", HandMovementListener )                
                            --myImg:addEventListener( "tap", ZoomTapListener )
                            scene:AdjustScroller()                        
                        end
                        
                        activeEnvs[envNum][myChain][ind] = nil 
                        chainCount = chainCount + 1
                    end    
                end                
            end
            
            -- before doing this, need to nil out all cards below it as well as its env table
            -- animals can be sent back to hand
            -- plants will be discarded
            
            -- todo remove this from here
            -- aww
            --scene:DiscardCard(self, hand, "chain") 
        elseif validLoc == "hand" then
            -- envs cannot return to hand unless their type is not env
            -- plants can only return to hand if strohm active
            -- all others can return
            
            -- need to send their chain as well
            if gameLogic:GetStat(self, "Value") == 1 then
                scene:GameLogAdd("Environments cannot be moved back into the hand.")
                self["rotation"] = 0
                self.x = self.originalX
                self.y = self.originalY   
                self["rotation"] = 270
                gameLogic:BringToFront(self["cardData"]["ID"], activeEnvs)
            elseif gameLogic:GetStat(self, "Value") == 2 or gameLogic:GetStat(self, "Value") == 3 then    
                if not strohm then
                    scene:GameLogAdd("Plants cannot be moved back into the hand.")
                    self.x = self.originalX
                    self.y = self.originalY  
                    gameLogic:BringToFront(self["cardData"]["ID"], activeEnvs)
                else
                    -- todo write this
                    
                    -- plants can be migrated
                    
                end
            else -- they can move back to hand
                envNum, myChain, myIndex = gameLogic:GetMyEnv(self, activeEnvs)
                
                if activeEnvs[envNum][myChain] then                    
                    local chainSize = #activeEnvs[envNum][myChain]
                    local chainCount = 0 
                    
                    -- it will work backwards through the chain from highest played card 
                    while chainSize - myIndex >= chainCount do  
                         local ind = chainSize - chainCount
                         local myCard = activeEnvs[envNum][myChain][ind]

                         -- do what needs to be done to card here
                         -- if plant move to discard
                         -- if animal, move to hand
                         --activeEnvs[envNum]["chain"..i][ind]

                        myCard:removeEventListener("touch", FieldMovementListener)

                        -- set value back to default 1
                        gameLogic:SetStat(myCard, "Value", 1) 
                        
                        -- insert card into hand
                        table.insert(hand, activeEnvs[envNum][myChain][ind])
                        local myImg = hand[#hand]
                        scrollView:insert(hand[#hand])
                        myImg.x = scrollXPos
                        myImg.y = scrollYPos
                        scrollXPos = scrollXPos + GLOB.cardWidth 

                        myImg:addEventListener( "touch", HandMovementListener )                
                        --myImg:addEventListener( "tap", ZoomTapListener )
                        scene:AdjustScroller()        
                        
                        activeEnvs[envNum][myChain][ind] = nil 
                        chainCount = chainCount + 1
                    end    
                end                   
                
            end
            
        
        elseif validLoc ~= "" then
            
            
        end
        
        

--        if not validLoc or validLoc == "hand" then -- if card hasn't been moved to a valid place, snap it back to the hand
--            scrollView:insert(self)
--        
--            self:removeEventListener("touch", HandMovementListener) -- todo may not need to remove this
--            scene:DiscardCard(self, hand)
--        elseif validLoc ~= "" then
--            for i = 1, 3 do
--                if validLoc == "env"..i.."chain1" or validLoc == "env"..i.."chain2" then
--                    -- try to play an env card
--                   if self["cardData"].Type == "Environment" then
--                        played = gameLogic:PlayEnvironment(self, hand, activeEnvs, i, "Player")
--                        break
--                   -- try to play a plant card
--                   elseif self["cardData"].Type == "Small Plant" or self["cardData"].Type == "Large Plant" then
--                       if validLoc == "env"..i.."chain1" then
--                            played = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain1", "Player")
--                            break
--                       elseif validLoc == "env"..i.."chain2" then
--                            played = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain2", "Player")
--                            break
--                       end
--                   elseif self["cardData"].Type == "Invertebrate" or self["cardData"].Type == "Small Animal" or self["cardData"].Type == "Large Animal" or self["cardData"].Type == "Apex" then
--                       if validLoc == "env"..i.."chain1" then
--                            played = gameLogic:PlayAnimal(self, hand, activeEnvs, i, "chain1", "Player")
--                            break
--                       elseif validLoc == "env"..i.."chain2" then
--                           played = gameLogic:PlayAnimal(self, hand, activeEnvs, i, "chain2", "Player")
--                           break
--                       end                       
--                   end                   
--                end
--            end            
--        end   
--
--        if not played and validLoc and validLoc ~= "discard" then
--            scrollView:insert(self)
--        elseif played then
--            mainGroup:insert(self) 
--            self:removeEventListener("touch", HandMovementListener)
--            -- todo add any new listener that the card may need
--        end
--
--        scrollView.isVisible = true
--        scene:AdjustScroller()
    end

    return true
end 


-- movement of a card from the hand out onto the playfield
function HandMovementListener(event)

    local self = event.target

    if event.phase == "began" then
        self.x, self.y = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview

        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  

        mainGroup:insert(self)
        self:toFront()
        display.getCurrentStage():setFocus(event.target)
        scrollView.isVisible = false
        print(self.markX, self.markY, self.x, self.y);
    elseif event.phase == "moved" and self.x>0 and self.x<display.contentWidth and (self.y - self.height/2)> 0 and self.y < (display.contentHeight - self.height/2.5)then
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

        display.getCurrentStage():setFocus(nil)

        local validLoc = ""
        local played = false
        local playedString = ""
        
        -- get a string if the card has been dropped in a valid spot
        validLoc = gameLogic:ValidLocation(self)
        
        
        if not validLoc or validLoc == "hand" then -- if card hasn't been moved to a valid place, snap it back to the hand
            scrollView:insert(self)
        elseif validLoc == "discard" then
            self:removeEventListener("touch", HandMovementListener) -- todo may not need to remove this
            scene:DiscardCard(self, hand, "hand")
        elseif validLoc ~= "" then
            for i = 1, 3 do
                if validLoc == "env"..i.."chain1" or validLoc == "env"..i.."chain2" then
                    -- try to play an env card
                   if self["cardData"].Type == "Environment" then
                        played, playedString = gameLogic:PlayEnvironment(self, hand, activeEnvs, i, "Player")
                        break
                   -- try to play a plant card
                   elseif self["cardData"].Type == "Small Plant" or self["cardData"].Type == "Large Plant" then
                       if validLoc == "env"..i.."chain1" then
                            played, playedString = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain1", "Player")
                            break
                       elseif validLoc == "env"..i.."chain2" then
                            played, playedString = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain2", "Player")
                            break
                       end
                   elseif self["cardData"].Type == "Invertebrate" or self["cardData"].Type == "Small Animal" or self["cardData"].Type == "Large Animal" or self["cardData"].Type == "Apex" then
                       if validLoc == "env"..i.."chain1" then
                            played, playedString = gameLogic:PlayAnimal(self, hand, activeEnvs, i, "chain1", "Player")
                            break
                       elseif validLoc == "env"..i.."chain2" then
                           played, playedString = gameLogic:PlayAnimal(self, hand, activeEnvs, i, "chain2", "Player")
                           break
                       end                       
                   end                   
                end
            end            
        end   

        if not played and validLoc and validLoc ~= "discard" then
            scrollView:insert(self)
        elseif played then
            mainGroup:insert(self) 
            self:removeEventListener("touch", HandMovementListener)
            event.phase = nil -- have to explicitely set the event to nil here or else the following line will start into its ended phase
            self:addEventListener("touch", FieldMovementListener)
            -- todo add any new listener that the card may need
        end
        
        if playedString ~= "" then
            scene:GameLogAdd(playedString)
        end

        scrollView.isVisible = true
        scene:AdjustScroller()
    end

    return true
end 

local function ZoomTapListener( event )
    local self = event.target;
        
    -- checks for double tap event
    if (event.numTaps >= 2 ) then
        
        -- checks to make sure image isn't already zoomed
        if tapCounter == 0 then
            self.orgX, self.orgY = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview
            self.xScale = 4 -- resize is relative to original size
            self.yScale = 4
            self:removeEventListener("touch", HandMovementListener)
            mainGroup:insert(self)
            overlay.isHitTestable = true -- Only needed if alpha is 0
            overlay:addEventListener("touch", function() return true end)
            overlay:addEventListener("tap", function() return true end)
            overlay:toFront()
            self:toFront()
            self.y = display.contentHeight/2    -- Location of image once it is zoomed
            self.x = display.contentWidth/2    
            scrollView.isVisible = false
            tapCounter = 1 -- sets flag to indicate zoomed image
            
            print( "The object was double-tapped." )
        else
            self.xScale = 1 -- reset size
            self.yScale = 1
            
            
            if self.orgY > display.contentHeight - GLOB.cardHeight then--it came from the hand
                scrollView:insert(self)
                self:addEventListener("touch", HandMovementListener)
                scene:AdjustScroller()
            else -- else kick back to position on playfield
                --todo add field movement listener
                self.x = self.orgX
                self.y = self.orgY                        
                        
                gameLogic:BringToFront(self.cardData.ID, activeEnvs)
                -- if on playfield, bring everything below it to front
                -- else on discard don't need to do this'

            end               
            
            scrollView.isVisible = true
            overlay:toBack()
            tapCounter = 0 -- reset flag
        end 
    end
    -- ecm end

    --  ** single tap event **
    -- elseif (event.numTaps == 1 ) then
       -- print("The object was tapped once.")
    return true
end

-- cards will be dealt to hand
--@params: num is number of cards to draw. myHand is the hand to deal cards to (can be player or npc)
function scene:drawCards( num, myHand, who )    
    local numDraw = deckIndex + num - 1 -- todo make sure this is ok  
    local numPlayed = 0
    
    for i = deckIndex, numDraw, 1 do -- start from deckIndex and draw the number passed in. third param is step
        
        if deck[i] then -- make sure there is a card to draw
            -- insert the card into the hand, then nil it from the deck            
            table.insert(myHand, deck[i])

        -- if the player is being dealt a card, put the image on screen
        
            local imgString = "assets/"
            local filenameString = myHand[#myHand]["cardData"]["File Name"]
            imgString = imgString..filenameString

            local paint = {
                type = "image",
                filename = imgString
            }

            local myImg = myHand[#myHand]
            myImg.fill = paint  

            if who == "Player" then 

                scrollView:insert(myHand[#myHand])
                myImg.x = scrollXPos
                myImg.y = scrollYPos
                scrollXPos = scrollXPos + GLOB.cardWidth 

                myImg:addEventListener( "touch", HandMovementListener )                
                myImg:addEventListener( "tap", ZoomTapListener )
            else                
                -- do anything cpu player might need
            end            

            scene:GameLogAdd(who.." has drawn the " .. deck[i]["cardData"].Name .. " card.")
            deck[i] = nil  
            numPlayed = numPlayed + 1
            
            if who == "Player" then
                scene:AdjustScroller()
            end
        else
            -- the draw pile is empty
            -- todo: deal with this by either reshuffling discard or ending game
            scene:GameLogAdd("There are no cards left to draw.")
        end
        
    end
    
    -- increment the deck index for next deal. it should stop incrementing if deck is empty
    deckIndex = deckIndex + numPlayed
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
    
    scene:GameLogAdd("Current Score:")
    
    for i = 1, 10 do
        if curEco[i] then
            scene:GameLogAdd(i..": ",curEco[i]) -- needed to use , here to concatenate a boolean value
        else
            scene:GameLogAdd(i..": false")
        end
        
        
    end
    
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
                        scene:GameLogAdd(activeEnvs[j]["activeEnv"]["cardData"].Name .. " environment card has been played.") 


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
                                scene:GameLogAdd(activeEnvs[j][availChain][1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j]["activeEnv"]["cardData"].Name .. ".") 
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
                                scene:GameLogAdd("No card was in that position. You have an Error.")
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
                                scene:GameLogAdd("No card was in that position. You have an Error.")
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
                                scene:GameLogAdd(activeEnvs[j][availChain][tabLen + 1]["cardData"].Name .. " card has been played on top of " .. activeEnvs[j][availChain][tabLen]["cardData"].Name .. ".") 
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
        scene:GameLogAdd("No card to play.")    
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

function scene:EndTurn()

    -- shift control to npc
    -- if not first turn
        -- don't discard'
    -- draw 2 cards
    -- if first turn, try to play env from hand

    if numOpp > 0 then       
        for i = 1, numOpp do
            local whoString = "Opponent"..i
            local playedString = ""
            -- todo check discard pile for a card to draw from
            scene:drawCards(2,cpuHand[i], whoString)
                      
            -- opponent tries to play cards
            -- cycle through their entire hand
            local ind = 1
            while cpuHand[i][ind] do
                local cardPlayed = false


                if cpuHand[i][ind]["cardData"].Type == "Environment" then -- try to play an environment card
                    for j = 1, 3 do                            
                        cardPlayed, playedString = gameLogic:PlayEnvironment(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, "Opponent"..i)
                        
                        if playedString ~= "" then
                            scene:GameLogAdd(playedString)
                        end
                        
                        if cardPlayed then -- break the for loop if a card has been played
                            break
                        end
                    end
                elseif cpuHand[i][ind]["cardData"].Type == "Small Plant" or cpuHand[i][ind]["cardData"].Type == "Large Plant" then
                    for j = 1, 3 do -- try all 3 environments                        
                        if cardPlayed then
                            break
                        end                        
                        
                        for k = 1, 2 do -- try both chains on each env
                            local chainString = "chain"..k
                                                                           
                            cardPlayed, playedString = gameLogic:PlayPlant(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)
                        
                            if playedString ~= "" then
                                scene:GameLogAdd(playedString)
                            end
                        
                            if cardPlayed then -- break the for loop if a card has been played
                                break
                            end
                        end
                    end
                elseif cpuHand[i][ind]["cardData"].Type == "Invertebrate" or cpuHand[i][ind]["cardData"].Type == "Small Animal" or cpuHand[i][ind]["cardData"].Type == "Large Animal" or cpuHand[i][ind]["cardData"].Type == "Apex" then
                    for j = 1, 3 do -- try all 3 environments                        
                        if cardPlayed then
                            break
                        end
                        
                        for k = 1, 2 do -- try both chains on each env
                            local chainString = "chain"..k
                                                                           
                            cardPlayed, playedString = gameLogic:PlayAnimal(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)
                        
                            if playedString ~= "" then
                                scene:GameLogAdd(playedString)
                            end
                        
                            if cardPlayed then -- break the for loop if a card has been played
                                break
                            end
                        end
                    end
                end

                
                 -- decrement counter if card was played since
                 -- the hand's index has been changed
                if not cardPlayed then
                    ind = ind + 1
                end
                
            end
            
            -- discard remaining hand after playing
            scene:DiscardHand(cpuHand[i])
        end
    end     
    
    
    
    
    -- determine current score    
    --scene:CalculateScore()
    
        
    -- if there's a winner do something
    
end

function scene:ShowOpponentCards(oppNum)
    
    -- hide the player's hand and cards
    mainGroup.isVisible = false
    scrollView.isVisible = false
    
    local myChain = ""
    
    for i = 1, 3 do
        if cpuActiveEnvs[oppNum][i] then
            oppGroup:insert(cpuActiveEnvs[oppNum][i]["activeEnv"])
            cpuActiveEnvs[oppNum][i]["activeEnv"].x = GLOB.envLocs[i]["xLoc"]
            cpuActiveEnvs[oppNum][i]["activeEnv"].y = GLOB.envLocs[i]["yLoc"]
            cpuActiveEnvs[oppNum][i]["activeEnv"].rotation = 270   

            for j = 1, 2 do
                myChain = "chain"..j             
                
                if cpuActiveEnvs[oppNum][i][myChain] then
                    for k = 1, #cpuActiveEnvs[oppNum][i][myChain] do
                    
                    local myCard = cpuActiveEnvs[oppNum][i][myChain][k]
                    
                    oppGroup:insert(myCard)
                    myCard.x = GLOB.chainLocs[i][myChain]["xLoc"]
                    myCard.y = GLOB.chainLocs[i][myChain]["yLoc"] + (k * 35)
                    end
                end  
            end
        end 
    end
    
    oppGroup.isVisible = true
end


function scene:HideOpponentCards()
    
    -- hide the player's hand and cards
    mainGroup.isVisible = true
    scrollView.isVisible = true
    
    -- remove all display objects from the group before hiding again
    -- this allows it to be empty the next time cards are displayed
    for i = 1, #oppGroup do
        oppGroup:remove(i)
    end
    
    oppGroup.isVisible = false
end

function scene:InitializeGame()
    -- deck should be shuffled after this
    scene:shuffleDeck(deck)
    
    --initialize tables for where cards will be stored
    hand = {}
    discardPile = {}  
    
    -- pass 5 cards out to the player
    scene:drawCards(5,hand, "Player")
           
    numOpp = 1
    
    -- pass 5 cards out to other players 
    if numOpp > 0 then
        cpuHand = {} -- initialize computer's hand       
        
        for i = 1, numOpp do
            cpuActiveEnvs[i] = {} -- initialize computer's playfield area
            cpuHand[i] = {}
            local whoString = "Opponent"..i
            scene:drawCards(5,cpuHand[i], whoString)
            
        end
    end 
    

    
    -- flip over a card and add to discard if we want
    
    -- todo change this from an automated process
    
    --scene:PlayCard()


    
end

function scene:GameLogAdd(logText)
    -- multiline text will be split and looped through, adding a max number of characters each line until completion
    -- todo make multiline text break at whole words rather than just split it
    
    print(logText) -- also show in console output for debugging    -- todo remove this
    
    local strMaxLen = 48
    local textWidth = logScrollWidth
    local textHeight = 20    
    local outputDone = false
    local charCount = 0
    
    while not outputDone do
        local multiLine = ""
        charCount = string.len(logText)

        if charCount > strMaxLen then            
            multiLine = string.sub(logText, strMaxLen + 1)
            logText = string.sub(logText, 0, strMaxLen)
        end    

       local logOptions = {
            text = logText,
            x = textWidth/2 + 5,
            y = scrollY,
            width = textWidth,
            height = textHeight,
            font = native.systemFont,
            fontSize = 14,
            align = "left"    
        }  

        scrollY = scrollY + textHeight
        local itemLabel = display.newText(logOptions)
        itemLabel:setFillColor(1,1,1) 
        logScroll:insert(itemLabel)
        
        if charCount > strMaxLen then
            logText = "   "..multiLine
        else
            outputDone = true
        end    
    end

    logScroll:scrollTo("bottom",{time = 400}) -- had to set the y position to negative to get this to work right
end

function scene:create( event )

    --scene:SetLocs()

    local sceneGroup = self.view
    mainGroup = display.newGroup() -- display group for anything that just needs added
    sceneGroup:insert(mainGroup)
    
    oppGroup = display.newGroup()
    sceneGroup:insert(oppGroup)
    oppGroup.isVisible = false
    
    local imgString, paint, filename
 
    local background = display.newImage("images/ORIGINAL-background.jpg")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2

    mainGroup:insert(background)
    
    overlay = display.newRect(display.contentWidth / 2, display.contentHeight / 2, display.contentWidth, display.contentHeight)    
    mainGroup:insert(overlay)
    overlay:setFillColor(0,0,0)    
    overlay.alpha = .5
    overlay:toBack()
    
    logScroll = widget.newScrollView
    {
        width = logScrollWidth,
        height = 150,
        horizontalScrollDisabled = true,
        isBounceEnabled = false,
        hideScrollBar = false,
        backgroundColor = {.5,.5,.5},
        friction = 0
    }
    
    logScroll.x = GLOB.gameLogXLoc
    logScroll.y = GLOB.gameLogYLoc

    mainGroup:insert(logScroll)
  
    
    
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

    mainGroup:insert(scrollView)
    
    local function right_scroll_listener ()
        local newX, newY = scrollView:getContentPosition();
        newX = newX - GLOB.cardWidth;
        scrollView:scrollToPosition{
        x = newX;
        y = newY;
        }
    end
    
    local function left_scroll_listener ()
        local newX, newY = scrollView:getContentPosition();
        newX = newX + GLOB.cardWidth;
        scrollView:scrollToPosition{
        x = newX;
        y = newY;
        }
    end
    
    local left_arrow = display.newRect(200, 580, 50, 50);
    left_arrow:addEventListener("tap" , left_scroll_listener)
    
    --local right_arrow = display.newRect(800, 580, 50, 50);
    local right_arrow = display.newRect(800, 500, 50, 50);
    right_arrow:addEventListener("tap" , right_scroll_listener)

    mainGroup:insert(left_arrow)
    mainGroup:insert(right_arrow)
    -- create a rectangle for each card
    -- attach card data to the image as a table
    -- insert into main group
    -- they will sit on the draw pile for now
    -- actual card image will be shown once the card is put into play
    for i = 1, #GLOB.deck do
        deck[i] = display.newRect(GLOB.drawPileXLoc, GLOB.drawPileYLoc, GLOB.cardWidth, GLOB.cardHeight)
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
    discardImage = display.newRect(GLOB.discardXLoc, GLOB.discardYLoc, GLOB.cardWidth, GLOB.cardHeight) 
    discardImage:setFillColor(.5,.5,.5)
    mainGroup:insert(discardImage)             
        
    -- show the back of the card for the draw pile
    local cardBack = display.newRect( GLOB.drawPileXLoc, GLOB.drawPileYLoc, GLOB.cardWidth, GLOB.cardHeight )
    paint = {
        type = "image",
        filename = "assets/v2-Back.jpg"
    }    
    
    cardBack.fill = paint
    mainGroup:insert(cardBack)

    local btnY = 500
    
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
    
    -- show opp 1 cards
    local showOpp = display.newRect( 75, btnY + 100, 100, 100 )
    showOpp:setFillColor(.5,.5,.5)
    local showOppLabel = display.newText( { text = "Show Opponent", x = 75, y = btnY + 100, fontSize = 16 } )
    showOppLabel:setTextColor( 1 )
    
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:ShowOpponentCards(1)
    end
    
    showOpp:addEventListener( "tap", tapListener )

    mainGroup:insert(showOpp)
    mainGroup:insert(showOppLabel)    
    
    -- show opp 1 cards
    local showMain = display.newRect( 75, btnY + 100, 100, 100 )
    showMain:setFillColor(.5,.5,.5)
    local showMainLabel = display.newText( { text = "Show Main", x = 75, y = btnY + 100, fontSize = 16 } )
    showMainLabel:setTextColor( 1 )
    
    local function tapListener( event )
        scene:HideOpponentCards()
    end
    
    showMain:addEventListener( "tap", tapListener )

    oppGroup:insert(showMain)
    oppGroup:insert(showMainLabel)       
    
    local endTurnBtn = display.newRect( 830, 575, 200 * .75, 109 * .75 )
    
    imgString = "images/button-end-turn.jpg"
    
    local paint = {
        type = "image",
        filename = imgString
    }
    
    endTurnBtn.fill = paint   
    
    local function endTurnListener( event )
        scene:EndTurn()
    end    
    
    endTurnBtn:addEventListener( "tap", endTurnListener )
    mainGroup:insert(endTurnBtn)    
    
    local function drawCardListener( event )
        local object = event.target
        scene:drawCards(1,hand, "Player")
        return true
    end    
    
    cardBack:addEventListener( "tap", drawCardListener )
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

