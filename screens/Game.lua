local composer = require( "composer" )
local widget = require "widget"
local GLOB = require "globals"
local utilities = require "functions.Utilities"
local gameLogic = require "functions.GameLogic"
local controls = require "functions.Controls"
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local deck = {}
local hand, discardPile, cpuHand
local activeEnvs = {} -- player cards on playfield
local cpuActiveEnvs = {} -- cpu cards on playfield

-- number of cpu or other opponents
local numOpp = 0
local turnCount = 1
local currentOpp = 1

local drawCount = 1
local deckIndex = 1
local tapCounter = 0 -- flag
local stalemateCounter = 0

-- variables for the scroller x and y
local scrollYPos = GLOB.cardHeight / 2 
local scrollXPos = GLOB.cardWidth / 2--display.contentWidth / 2
local scrollY = 10

--controls
local mainGroup
local oppGroup -- display's opponent cards
local scrollView
local overlay
local hiddenGroup
local logScroll
local scoreIconsOn = {}
local scoreIconsOff = {}
local cpuScoreIconsOn = {}
local cpuScoreIconsOff = {}
local cardBack
local cpuBackground

local cardMoving = false

local HandMovementListener
local FieldMovementListener
local DiscardMovementListener

-- sound effects
local cardSlide
local click
local sound
local music
local backgroundMusic

local gameTimer
local gameTime
local cardsPlayed
local drawn
---------------------------------------------------------------------------------

local function gameTimeListener()
    gameTime = gameTime + 1;
end



-- for moving a card out of discard
function DiscardMovementListener(event)
    local self = event.target

    if event.phase == "began" then
        --self.x, self.y = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview
        self.originalX = self.x -- store starting x. needed if card will snap back
        self.originalY = self.y -- store starting y
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  
        if sound then
            audio.play(cardSlide)
        end
        self:toFront()
        display.getCurrentStage():setFocus(event.target)
        cardMoving = true
    elseif event.phase == "moved" and cardMoving then
        local myX, myY
        
        if self.x >= self.width/2 and self.x <= display.contentWidth - self.width/2 and (self.y - self.height/2 + 10) >= 0 and self.y < (display.contentHeight - self.height/2.5 - 10)then
            if self.markX then
                myX = (event.x - event.xStart) + self.markX
            else 
                myX = display.contentWidth/2
            end

            if self.markY then
                myY = (event.y - event.yStart) + self.markY
            else
                myY = display.contentWidth/2
            end       
        else
            if self.x < self.width/2 then
                myX = self.width/2
            elseif self.x > display.contentWidth - self.width/2 then
                myX = display.contentWidth - self.width/2
            elseif self.markX then
                myX = (event.x - event.xStart) + self.markX           
            end

            if (self.y - self.height/2 + 10) < 0 then
                myY = self.height/2
            elseif self.y >= display.contentHeight - self.height/2.5 - 10 then
                myY = display.contentHeight - self.height/2 - 10
            elseif self.markY then
                myY = (event.y - event.yStart) + self.markY
            end      
        end
        
        self.x, self.y = myX, myY    -- move object based on calculations above 
    elseif event.phase == "ended" and cardMoving then 
        display.getCurrentStage():setFocus(nil)

        local validLoc = ""
        local played = false
        local playedString = ""
        
        -- get a string if the card has been dropped in a valid spot        
        validLoc = gameLogic:ValidLocation(self, activeEnvs)
        
        if validLoc == "hand" and drawCount < 3 and turnCount  > 1 then -- add card to hand from discard
            self:removeEventListener("touch", DiscardMovementListener) -- todo may not need to remove this
            event.phase = nil
            self:removeEventListener("touch", DiscardMovementListener)
            self:addEventListener("touch", HandMovementListener)
            drawCount = drawCount + 1
            
            --scene:DiscardCard(self, hand, "hand")
            table.insert(hand, discardPile[#discardPile])
            discardPile[#discardPile] = nil
        
            scrollView:insert(self)
            self.x = scrollXPos
            self.y = scrollYPos
            scrollXPos = scrollXPos + GLOB.cardWidth
            if sound then
                audio.play(click)
            end
            scrollY = controls:GameLogAdd(logScroll,scrollY,self["cardData"]["Name"].." was drawn from the discard pile.")
        else
            self.x = self.originalX
            self.y = self.originalY        
        
        end   

        scene:AdjustScroller()
        cardMoving = false 
    end

    return true
end 

-- listener for cards out on the playfield to move them around
function FieldMovementListener(event)
    local self = event.target

    if event.phase == "began" then
        --self.x, self.y = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview
        self.originalX = self.x -- store starting x. needed if card will snap back
        self.originalY = self.y -- store starting y
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object  
        self:toFront()
        display.getCurrentStage():setFocus(event.target)
        cardMoving = true
    elseif event.phase == "moved" and cardMoving then
        local myX, myY        
        if self.x >= self.width/2 and self.x <= display.contentWidth - self.width/2 and (self.y - self.height/2 + 10) >= 0 and self.y < (display.contentHeight - self.height/2.5 - 10)then
            if self.markX then
                myX = (event.x - event.xStart) + self.markX
            else 
                myX = display.contentWidth/2
            end

            if self.markY then
                myY = (event.y - event.yStart) + self.markY
            else
                myY = display.contentWidth/2
            end       
        else
            if self.x < self.width/2 then
                myX = self.width/2
            elseif self.x > display.contentWidth - self.width/2 then
                myX = display.contentWidth - self.width/2
            elseif self.markX then
                myX = (event.x - event.xStart) + self.markX           
            end

            if (self.y - self.height/2 + 10) < 0 then
                myY = self.height/2
            elseif self.y >= display.contentHeight - self.height/2.5 - 10 then
                myY = display.contentHeight - self.height/2 - 10
            elseif self.markY then
                myY = (event.y - event.yStart) + self.markY
            end      
        end
        
        self.x, self.y = myX, myY    -- move object based on calculations above 
    elseif event.phase == "ended" and cardMoving then -- try to click into place
        display.getCurrentStage():setFocus(nil)
        
        if self.x ~= self.originalX and self.y ~= self.originalY then
            local validLoc = ""
            local played = false
            local playedString = ""

            -- get a string if the card has been dropped in a valid spot
            validLoc = gameLogic:ValidLocation(self, activeEnvs)

            local envNum, myChain, myIndex -- need to know  type, env, chain

            if not validLoc or validLoc == "special" then -- snap back -- aww
                self.x = self.originalX
                self.y = self.originalY
            elseif validLoc == "discard" then
                -- any card on playfield can be put in discard
                -- when discarded, the lowest level card is compared when in a chain
                -- if it is an environment, then it and any plant will be discarded.
                -- if it is an environment, any animals on its chain will be put in hand

                self:removeEventListener("touch", FieldMovementListener)
                event.phase = nil

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
            
                else -- plants & animals discard
                    -- animals can be sent back to hand
                    -- plants will be discarded
                    if activeEnvs[envNum][myChain] then                    
                        local chainSize = #activeEnvs[envNum][myChain]
                        local chainCount = 0 

                        -- it will work backwards through the chain from highest played card 
                        while chainSize - myIndex >= chainCount do  
                            local ind = chainSize - chainCount
                            local myCard = activeEnvs[envNum][myChain][ind]
                            myCard:removeEventListener("touch", FieldMovementListener)

                            if myCard["cardData"]["Value"] == 2 or myCard["cardData"]["Value"] == 3 then				
                                -- this should work for wild card played as a plant
                                scene:DiscardCard(myCard, hand, "field")-- add to discard pile 
                                myCard:addEventListener( "touch", DiscardMovementListener )
                                activeEnvs[envNum][myChain][ind] = nil
                                activeEnvs[envNum][myChain] = nil -- nil chain here
                            -- don't put the card that was base of chain in hand
                            elseif self["cardData"]["ID"] == activeEnvs[envNum][myChain][ind]["cardData"]["ID"] then
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

                                activeEnvs[envNum][myChain][ind] = nil  
                                scene:AdjustScroller()
                            end

                            chainCount = chainCount + 1
                        end  
                    end                 
                end
            elseif validLoc == "hand" then
                -- envs cannot return to hand unless their type is not env
                -- plants can only return to hand if strohm active
                -- all others can return

                -- need to send their chain as well
                if gameLogic:GetStat(self, "Value") == 1 then
                    scrollY = controls:GameLogAdd(logScroll,scrollY,"Environments cannot be moved back into the hand.")
                    self["rotation"] = 0
                    self.x = self.originalX
                    self.y = self.originalY   
                    self["rotation"] = 270
                    gameLogic:BringToFront(self["cardData"]["ID"], activeEnvs)
                elseif (gameLogic:GetStat(self, "Type") == "Small Plant" or gameLogic:GetStat(self, "Type") == "Large Plant") and not scene:SearchForStrohm() then  
                    -- plants will not migrate unless stromstead is active
                    scrollY = controls:GameLogAdd(logScroll,scrollY,"Plants cannot be moved back into the hand.")
                    self.x = self.originalX
                    self.y = self.originalY  
                    gameLogic:BringToFront(self["cardData"]["ID"], activeEnvs)
                else -- they can move back to hand
                    envNum, myChain, myIndex = gameLogic:GetMyEnv(self, activeEnvs)

                    if activeEnvs[envNum][myChain] then                    
                        local chainSize = #activeEnvs[envNum][myChain]
                        local chainCount = 0 

                        -- it will work backwards through the chain from highest played card 
                        while chainSize - myIndex >= chainCount do  
                             local ind = chainSize - chainCount
                             local myCard = activeEnvs[envNum][myChain][ind]

                             -- do what needs to be done to card here. if plant move to discard. if animal, move to hand
                            myCard:removeEventListener("touch", FieldMovementListener)
                            event.phase = nil
                            
                            -- insert card into hand
                            table.insert(hand, activeEnvs[envNum][myChain][ind])
                            local myImg = hand[#hand]
                            scrollView:insert(hand[#hand])
                            myImg.x = scrollXPos
                            myImg.y = scrollYPos
                            scrollXPos = scrollXPos + GLOB.cardWidth 

                            myImg:addEventListener( "touch", HandMovementListener ) 
                            scene:AdjustScroller()        

                            if gameLogic:GetStat(myCard, "Value") == 2 or gameLogic:GetStat(myCard, "Value") == 3 then
                                activeEnvs[envNum][myChain] = nil -- nil out the chain if it is a plant or human working as plant
                            else
                                activeEnvs[envNum][myChain][ind] = nil -- else just nil the card from playfield
                            end    

                            -- set value back to default 1 if not a plant
                            if not gameLogic:GetStat(self, "Type") == "Small Plant" and not gameLogic:GetStat(self, "Type") == "Large Plant" then
                                gameLogic:SetStat(myCard, "Value", 1) 
                            end            
                             
                            chainCount = chainCount + 1
                        end    
                    end   
                end
            elseif validLoc ~= "" then -- attempt to migrate
                if gameLogic:GetStat(self, "Value") == 1 then
                    scrollY = controls:GameLogAdd(logScroll,scrollY,"Environments cannot migrate.")
                    self["rotation"] = 0
                    self.x = self.originalX
                    self.y = self.originalY   
                    self["rotation"] = 270
                elseif (gameLogic:GetStat(self, "Type") == "Small Plant" or gameLogic:GetStat(self, "Type") == "Large Plant") and not scene:SearchForStrohm() then   
                    -- plants will not migrate unless stromstead is active
                    scrollY = controls:GameLogAdd(logScroll,scrollY,"Plants cannot be moved back into the hand.")
                    self.x = self.originalX
                    self.y = self.originalY  
                    gameLogic:BringToFront(self["cardData"]["ID"], activeEnvs)
                else -- todo start here for plant migration
                    envNum, myChain, myIndex = gameLogic:GetMyEnv(self, activeEnvs)
                    local canMigrate = false
                    local iterations = #activeEnvs[envNum][myChain]-- - myIndex + 1 -- number of cards trying to be moved
                    local newChain = ""
                    local plantPlayed = false
                    
                    -- determine what chain is being played onto
                    for i = 1, 3 do                          
                        if validLoc == "env"..i.."chain1" or validLoc == "env"..i.."chain2" then
                            if validLoc == "env"..i.."chain1" and (myChain ~= "chain1" or envNum ~= i) then                                
                                newChain = "chain1"
                                for j = myIndex, iterations do
                                    if j == myIndex then
                                        if activeEnvs[envNum][myChain][j]["cardData"]["Value"] == 2 or activeEnvs[envNum][myChain][j]["cardData"]["Value"] == 3 then
                                            played = gameLogic:MigratePlant(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain1", "Player")
                                            
                                            if played then
                                                plantPlayed = true
                                            end
                                        else
                                            if plantPlayed then
                                                played = gameLogic:EnvTest(activeEnvs[envNum][myChain][j], activeEnvs, i)
                                            else
                                                played = gameLogic:MigrateAnimal(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain1", "Player", "first")
                                            end
                                        end
                                    else
                                        if plantPlayed then
                                            played = gameLogic:EnvTest(activeEnvs[envNum][myChain][j], activeEnvs, i)
                                        else
                                            played = gameLogic:MigrateAnimal(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain1", "Player", "other")
                                        end
                                    end

                                    if not played then 
                                        canMigrate = false
                                        break
                                    else
                                        canMigrate = true
                                    end
                                end
                            elseif validLoc == "env"..i.."chain2" and (myChain ~= "chain2" or envNum ~= i) then
                                newChain = "chain2"
                                for j = myIndex, iterations do
                                    if j == myIndex then
                                        if activeEnvs[envNum][myChain][j]["cardData"]["Value"] == 2 or activeEnvs[envNum][myChain][j]["cardData"]["Value"] == 3 then
                                            played = gameLogic:MigratePlant(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain2", "Player")
                                            
                                            if played then
                                                plantPlayed = true
                                            end 
                                        else
                                            if plantPlayed then
						played = gameLogic:EnvTest(activeEnvs[envNum][myChain][j], activeEnvs, i)
                                            else
                                                played = gameLogic:MigrateAnimal(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain2", "Player", "first")
                                            end
                                        end
                                    else
                                        if plantPlayed then
                                            played = gameLogic:EnvTest(activeEnvs[envNum][myChain][j], activeEnvs, i)
                                        else                                        
                                            played = gameLogic:MigrateAnimal(activeEnvs[envNum][myChain][j], activeEnvs[envNum][myChain], activeEnvs, i, "chain2", "Player", "other")
                                        end
                                    end

                                    if not played then 
                                        canMigrate = false
                                        break
                                    else
                                        canMigrate = true
                                    end
                                end
                            end 
                        end

                        if not canMigrate then
                            self.x = self.originalX
                            self.y = self.originalY
                        else -- move all of the cards now    
                            while activeEnvs[envNum][myChain] and activeEnvs[envNum][myChain][myIndex] do
                                if activeEnvs[envNum][myChain][myIndex]["cardData"]["Value"] == 2 or activeEnvs[envNum][myChain][myIndex]["cardData"]["Value"] == 3 then
                                    played, playedString = gameLogic:PlayPlant(activeEnvs[envNum][myChain][myIndex], activeEnvs[envNum][myChain], activeEnvs, i, newChain, "Player")                             
                                else
                                    played, playedString = gameLogic:PlayAnimal(activeEnvs[envNum][myChain][myIndex], activeEnvs[envNum][myChain], activeEnvs, i, newChain, "Player")                             
                                end
                                if sound then
                                    audio.play(click)
                                end
                                scrollY = controls:GameLogAdd(logScroll,scrollY,playedString)
                                
                                if not played then
                                    break
                                end
                            end                           
                            
                            if plantPlayed then
                                activeEnvs[envNum][myChain] = nil -- nil the chain when the plant is migrated                                
                            end
                            
                            break
                        end                       
                    end  
                end
            end

            local curEco = gameLogic:CalculateScore(activeEnvs)
            
            scene:ScoreImageChange(curEco, "player")            
        end
        gameLogic:RepositionCards(activeEnvs)
        cardMoving = false
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
        if sound then 
            audio.play(cardSlide)
        end
        mainGroup:insert(self)
        self:toFront()
        -- todo see if getCurrentStage can be used to pass to another file to manipulate controls
        display.getCurrentStage():setFocus(event.target)
        scrollView.isVisible = false
        cardMoving = true
    elseif event.phase == "moved" and cardMoving then
        local myX, myY
        
        if self.x >= self.width/2 and self.x <= display.contentWidth - self.width/2 and (self.y - self.height/2 + 10) >= 0 and self.y < (display.contentHeight - self.height/2.5 - 10)then
            if self.markX then
                myX = (event.x - event.xStart) + self.markX
            else 
                myX = display.contentWidth/2
            end

            if self.markY then
                myY = (event.y - event.yStart) + self.markY
            else
                myY = display.contentWidth/2
            end       
        else
            if self.x < self.width/2 then
                myX = self.width/2
            elseif self.x > display.contentWidth - self.width/2 then
                myX = display.contentWidth - self.width/2
            elseif self.markX then
                myX = (event.x - event.xStart) + self.markX           
            end

            if (self.y - self.height/2 + 10) < 0 then
                myY = self.height/2
            elseif self.y >= display.contentHeight - self.height/2.5 - 10 then
                myY = display.contentHeight - self.height/2 - 10
            elseif self.markY then
                myY = (event.y - event.yStart) + self.markY
            end      
        end
        
        self.x, self.y = myX, myY    -- move object based on calculations above 
    elseif event.phase == "ended" and cardMoving then
        -- try to click into place
            -- make sure to move card to appropriate table (env, discard, etc)
            -- at this point, check can be made to put card into playfield and snap back to hand if it can't be played
        -- or snap back to hand if not in a valid area
        display.getCurrentStage():setFocus(nil)

        local validLoc = ""
        local played = false
        local playedString = ""

        -- get a string if the card has been dropped in a valid spot
        validLoc = gameLogic:ValidLocation(self, activeEnvs)

        if not validLoc or validLoc == "hand" then -- if card hasn't been moved to a valid place, snap it back to the hand
            scrollView:insert(self)
        elseif validLoc == "discard" then
            self:removeEventListener("touch", HandMovementListener) -- todo may not need to remove this                       
            event.phase = nil -- prevent the next listener added from activating its ended phase
            scene:DiscardCard(self, hand, "hand")
        --elseif validLoc == "special" then -- aww
            -- todo try to put grandpa in special area
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
                   -- try to play a wild card in any available niche
                   elseif self["cardData"].Type == "Wild" then

                        -- try to play as env
                        played, playedString = gameLogic:PlayEnvironment(self, hand, activeEnvs, i, "Player")

                        if played then
                            break 
                        else
                            -- else try to play as plant
                            if validLoc == "env"..i.."chain1" then
                                 played, playedString = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain1", "Player")
                            elseif validLoc == "env"..i.."chain2" then
                                 played, playedString = gameLogic:PlayPlant(self, hand, activeEnvs, i, "chain2", "Player")
                            end

                            if played then
                                break
                            else
                                 -- else try to play as animal
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
            end            
        end
        
        if played then 
            cardsPlayed = cardsPlayed + 1
        end
        
        if not played and validLoc and validLoc ~= "discard" then
            scrollView:insert(self)
        elseif played then
            if sound then
                audio.play(click)
            end
            mainGroup:insert(self) 
            self:removeEventListener("touch", HandMovementListener)
            event.phase = nil -- have to explicitely set the event to nil here or else the following line will start into its ended phase
            self:addEventListener("touch", FieldMovementListener)
            -- todo add any new listener that the card may need
        end

        if playedString ~= "" then
            scrollY = controls:GameLogAdd(logScroll,scrollY,playedString)
        end

        scrollView.isVisible = true
        scene:AdjustScroller()
        local curEco = gameLogic:CalculateScore(activeEnvs)
        scene:ScoreImageChange(curEco, "player")
        
        cardMoving = false
    end

    return true
end 

local function ZoomTapListener( event )
    local self = event.target;
        
    -- checks for double tap event
    if (event.numTaps >= 2 ) then
        local orgX, orgY
        
        -- checks to make sure image isn't already zoomed
        if tapCounter == 0 then
            self.orgX, self.orgY = self:localToContent(0, 0) -- *important: this will return the object's x and y value on the stage, not the scrollview
            self.xScale = 4 -- resize is relative to original size
            self.yScale = 4
            self:removeEventListener("touch", HandMovementListener)
            self:removeEventListener("touch", FieldMovementListener)
            self:removeEventListener("touch", DiscardMovementListener)
            mainGroup:insert(self)
            overlay.isHitTestable = true -- Only needed if alpha is 0
            overlay:addEventListener("touch", function() return true end)
            overlay:addEventListener("tap", function() return true end)
            overlay:toFront()
            self:toFront()
            
            if self["cardData"].Type == "Environment" and self.rotation ~= 270 then
                self.rotation = 270
            end            
            
            self.y = display.contentHeight/2    -- Location of image once it is zoomed
            self.x = display.contentWidth/2    
            scrollView.isVisible = false
            tapCounter = 1 -- sets flag to indicate zoomed image
        else
            self.xScale = 1 -- reset size
            self.yScale = 1
            
            if self["cardData"].Type == "Environment" and (self.orgY > display.contentHeight - GLOB.cardHeight or self.orgX < 150) then
                self.rotation = 0
            end
            
            if self.orgY > display.contentHeight - GLOB.cardHeight then--it came from the hand
                scrollView:insert(self)
                self:addEventListener("touch", HandMovementListener)
                scene:AdjustScroller()
            -- todo put an elseif here to check if moving back to discard
            elseif self.orgX < 150 and self.orgY < display.contentHeight - GLOB.cardHeight then -- came from discard
                self:addEventListener("touch", DiscardMovementListener)
                self.x = self.orgX
                self.y = self.orgY 
            else -- else kick back to position on playfield
                --todo add field movement listener
                self:addEventListener("touch", FieldMovementListener)
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

-- activated when a *single* card has been dropped onto the discard pile
-- can be used by player and cpu
function scene:DiscardCard(myCard, myHand, origin)  
    table.insert(discardPile, myCard) -- insert the card in the last available position on discard    
    mainGroup:insert(discardPile[#discardPile])

    if not myCard._functionListeners or myCard._functionListeners.tap == nil then
        myCard:addEventListener( "tap", ZoomTapListener )
    end
    myCard:addEventListener("touch", DiscardMovementListener) 
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

    scrollY = controls:GameLogAdd(logScroll,scrollY,discardPile[#discardPile]["cardData"]["Name"].." has been discarded.")	

    if origin == "hand" then
        gameLogic:RemoveFromHand(myCard, myHand)
    end
end

-- discard the *entire current hand* and add it to the discard pile table
-- last card discarded will appear on top of discard pile
function scene:DiscardHand(myHand)

    for i = 1, #myHand do
        table.insert(discardPile, myHand[i]) -- insert the first card in hand to the last available position on discard
        mainGroup:insert(discardPile[#discardPile])

        if not myHand[i]._functionListeners or myHand[i]._functionListeners.tap == nil then
            myHand[i]:addEventListener( "tap", ZoomTapListener )
        end
        
        myHand[i]:removeEventListener("touch", HandMovementListener)
        myHand[i]:addEventListener("touch", DiscardMovementListener)        
        discardPile[#discardPile]["x"] = GLOB.discardXLoc
        discardPile[#discardPile]["y"] = GLOB.discardYLoc        
        myHand[i] = nil  

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
    
    scrollY = controls:GameLogAdd(logScroll,scrollY,"All cards in hand have been discarded")
end

-- cards will be dealt to hand
--@params: num is number of cards to draw. myHand is the hand to deal cards to (can be player or npc)
function scene:drawCards( num, myHand, who )
    local numDraw = num
    
    while numDraw > 0 do
        local deckCount = 0

        for k,v in pairs(deck) do -- see how many cards are left in deck
            deckCount = deckCount + 1
        end

        if deckCount < 1 then -- if number to draw exceeds cards in deck, empty discard pile and reshuffle deck
            deckIndex = 1 -- reset deckIndex             

            deck = {} -- nil out deck before reentering cards as a safety measure
            
            for i = 1, #discardPile do 
                discardPile[i]._functionListeners = nil -- remove any tap or touch listeners from cards in discard               
                discardPile[i].x = GLOB.drawPileXLoc
                discardPile[i].y = GLOB.drawPileYLoc
                table.insert(deck, discardPile[i])-- add discard cards back into deck                
            end

            discardPile = {}
            utilities:ShuffleDeck(deck)-- shuffle deck
            cardBack:toFront()
            scrollY = controls:GameLogAdd(logScroll,scrollY, "The deck has been shuffled.")-- print that deck has been shuffled
        end     
        
        if deck[deckIndex] then
            table.insert(myHand, deck[deckIndex])

            -- if the player is being dealt a card, put the image on screen
            local imgString = "assets/"
            local filenameString = myHand[#myHand]["cardData"]["File Name"]
            imgString = imgString..filenameString
            local paint = {type = "image",filename = imgString}
            local myImg = myHand[#myHand]
            myImg.fill = paint  

            if who == "Player" then 
                scrollView:insert(myHand[#myHand])
                myImg.x = scrollXPos
                myImg.y = scrollYPos
                scrollXPos = scrollXPos + GLOB.cardWidth 
                drawn = drawn + 1;
                myImg:addEventListener( "touch", HandMovementListener )

                if not myImg._functionListeners or myImg._functionListeners.tap == nil then
                    myImg:addEventListener( "tap", ZoomTapListener )
                end
            else                
                -- do anything cpu player might need
            end    
            
            scrollY = controls:GameLogAdd(logScroll,scrollY,who.." has drawn the " .. deck[deckIndex]["cardData"].Name .. " card.")
            deck[deckIndex] = nil  
            numDraw = numDraw - 1 
            deckIndex = deckIndex + 1 -- increment the deck index for next deal.
        else
            -- the draw pile is empty
            -- todo: deal with this by either reshuffling discard or ending game
            numDraw = 0
            scrollY = controls:GameLogAdd(logScroll,scrollY,"There are no cards left to draw.")     
        end
        
        if who == "Player" then
            scene:AdjustScroller()
        end
    end
end

-- search for Strohmstead to see if it is in play
function scene:SearchForStrohm()
    for i = 1, 3 do
        if activeEnvs[i] then
            if activeEnvs[i]["activeEnv"]["cardData"]["ID"] == 22 then
                return true
            end            
        end
    end 
    
    return false
end

--for testing to get a specific card from deck
-- aww
function scene:DebugGetCard(id, myHand, who)
    local size = #deck - deckIndex
    
    for i = deckIndex, size, 1 do -- start from deckIndex and draw the number passed in. third param is step
        if deck[i] then
            if deck[i]["cardData"]["ID"] == id then -- make sure there is a card to draw
                -- insert the card into the hand, then nil it from the deck            
                table.insert(myHand, deck[i])

                -- if the player is being dealt a card, put the image on screen
                if who == "player" then
                    local imgString = "assets/"
                    local filenameString = myHand[#myHand]["cardData"]["File Name"]
                    imgString = imgString..filenameString

                    local paint = {type = "image", filename = imgString}
                    local myImg = myHand[#myHand]
                    myImg.fill = paint  
                    scrollView:insert(myHand[#myHand])
                    myImg.x = scrollXPos
                    myImg.y = scrollYPos
                    scrollXPos = scrollXPos + GLOB.cardWidth 

                    myImg:addEventListener( "touch", HandMovementListener ) 

                    if not myImg._functionListeners or myImg._functionListeners.tap == nil then
                        myImg:addEventListener( "tap", ZoomTapListener )
                    end

                    scrollY = controls:GameLogAdd(logScroll,scrollY,"Player has drawn the " .. deck[i]["cardData"].Name .. " card.")
                
                    scene:AdjustScroller()
                else
                    scrollY = controls:GameLogAdd(logScroll,scrollY,who.." has drawn the " .. deck[i]["cardData"].Name .. " card.")
                end
                
                deck[i] = nil  

                local index = i
                
                while deck[index + 1] do
                    deck[index] = deck[index + 1]
                    deck[index + 1] = nil
                    index = index + 1
                end
                
                break
            end
        else
            -- the draw pile is empty
            -- todo: deal with this by either reshuffling discard or ending game
            scrollY = controls:GameLogAdd(logScroll,scrollY,"There are no cards left to draw.")
        end        
    end
end

-- for testing. will play a card to the playfield if there is one in the hand that can be played.
function scene:PlayCard()
        --todo account for strohmstead card
    local played = false
    local playedString = ""
    local handSize = #hand
    
    for ind = 1, handSize do 
        local myCard = hand[ind]
        
        if hand[ind] then    
            --------------------------
            -- try to play an environment card
            --------------------------            
            if myCard["cardData"].Type == "Environment" then   
                for j = 1, 3 do                            
                    played, playedString = gameLogic:PlayEnvironment(myCard, hand, activeEnvs, j, "Player")

                    if played then -- break the for loop if a card has been played
                        break
                    end
                end
            --------------------------
            -- try to play a plant card
            --------------------------
            elseif myCard["cardData"].Type == "Small Plant" or myCard["cardData"].Type == "Large Plant" then
                for j = 1, 3 do -- try all 3 environments                        
                    if played then
                        break
                    end

                    for k = 1, 2 do -- try both chains on each env
                        local chainString = "chain"..k

                        played, playedString = gameLogic:PlayPlant(myCard, hand, activeEnvs, j, chainString, "Player")

                        if played then -- break the for loop if a card has been played
                            break
                        end
                    end
                end
            -- invertebrate
            elseif myCard["cardData"].Type == "Invertebrate" or myCard["cardData"].Type == "Small Animal" or myCard["cardData"].Type == "Large Animal" or myCard["cardData"].Type == "Apex" then
                for j = 1, 3 do -- try all 3 environments                        
                    if played then
                        break
                    end

                    for k = 1, 2 do -- try both chains on each env
                        local chainString = "chain"..k

                        played, playedString = gameLogic:PlayAnimal(myCard, hand, activeEnvs, j, chainString, "Player")

                        if played then -- break the for loop if a card has been played
                            break
                        end
                    end
                end                
            elseif myCard["cardData"].Type == "Wild" then
                for j = 1, 3 do -- try all 3 environments  
                    -- try to play as env
                    played, playedString = gameLogic:PlayEnvironment(myCard, hand, activeEnvs, j, "Player")

                    if played then
                            break 
                    else
                        -- else try to play as plant
                        if validLoc == "env"..j.."chain1" then
                            played, playedString = gameLogic:PlayPlant(myCard, hand, activeEnvs, j, "chain1", "Player")
                        elseif validLoc == "env"..j.."chain2" then
                            played, playedString = gameLogic:PlayPlant(myCard, hand, activeEnvs, j, "chain2", "Player")
                        end

                        if played then
                            break
                        else
                            -- else try to play as animal
                            if validLoc == "env"..j.."chain1" then
                                played, playedString = gameLogic:PlayAnimal(myCard, hand, activeEnvs, j, "chain1", "Player")
                                break
                            elseif validLoc == "env"..j.."chain2" then
                                played, playedString = gameLogic:PlayAnimal(myCard, hand, activeEnvs, j, "chain2", "Player")
                                break
                            end  
                        end                            
                    end
                end
            end  
        end
                
        -- todo need to make sure this happens any time a card is played from hand
        -- may want to abstract it out to its own fx
        if played then
            -- loop up through deck from where card was played to fill empty hole
            -- if the card played was the last card in hand
            if sound then
                audio.play(click)
            end
            mainGroup:insert(myCard) 
            myCard:removeEventListener("touch", HandMovementListener)
            myCard:addEventListener("touch", FieldMovementListener)
            -- todo add any new listener that the card may need
            if playedString ~= "" then
                scrollY = controls:GameLogAdd(logScroll,scrollY,playedString)
            end
            
            scene:AdjustScroller()
            local curEco = gameLogic:CalculateScore(activeEnvs)
            scene:ScoreImageChange(curEco, "player")
            
            -- since a card was played, break the loop so as not to continue checking more to play
            break
        end        
    end
    
    if not played then
        scrollY = controls:GameLogAdd(logScroll,scrollY,"No card to play.")          
    end
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
    scrollView:scrollTo("right", {time=1200})
end

function scene:ComputerDiscard(cpuField, whoString, currentHand, totalDrawn)
    local drawFromDiscard = 0;
    local cpuScore = gameLogic:CalculateScore(cpuField)
    local needEnv = false;
    local needPlant = false;
    local envNeeded = 3
    local plantNeeded = 6

    for j = 1, 3 do
        if not cpuField[j] then
            needEnv = true;
            envNeeded = envNeeded - 1
        end
    end

    for j = 1, 3 do
        if cpuField[j] then
            for k = 1, 2 do
                if not cpuField[j]["chain"..k] then
                    needPlant = true;
                else
                    plantNeeded = plantNeeded - 1
                end
            end
        else
            plantNeeded = plantNeeded - 2
        end
    end

    -- always try to grab a human card. first check second card down on discard stack before checking top one
    if totalDrawn == 0 and #discardPile - 1 > 0 and discardPile[#discardPile - 1]["cardData"]["Type"] == "Wild" then
        drawFromDiscard = 2
    end

    if drawFromDiscard < 2 and #discardPile > 0 and discardPile[#discardPile]["cardData"]["Type"] == "Wild" then
        drawFromDiscard = 1
    end
    
    --check available cards to see if it will fill a role for computer
    --note: this does not check to see if it will match environments available, just checks possible roles it *could* fill
    for j=1, #cpuScore do
        if drawFromDiscard < 2 then
            if not cpuScore[j] then -- cpu doesn't have this role filled
                if j == 1 and needEnv then
                    if #discardPile > 0 and discardPile[#discardPile]["cardData"]["Type"] == "Environment" then
                        if drawFromDiscard < 2 then                                    
                            drawFromDiscard = 1
                        end
                    elseif totalDrawn == 0 and #discardPile - 1 > 0 and discardPile[#discardPile - 1]["cardData"]["Type"] == "Environment" then
                        drawFromDiscard = 2
                    end
                elseif (j == 2 or j == 3) and needPlant then
                    if #discardPile > 0 and (discardPile[#discardPile]["cardData"]["Type"] == "Small Plant" or discardPile[#discardPile]["cardData"]["Type"] == "Large Plant") then
                        if drawFromDiscard < 2 then                                    
                            drawFromDiscard = 1
                        end
                    elseif totalDrawn == 0 and #discardPile - 1 > 0 and discardPile[#discardPile - 1]["cardData"]["Type"] == "Small Plant" then
                        drawFromDiscard = 2
                    end
                elseif envNeeded < 2 and (plantNeeded + 2 <= (envNeeded + 1) * 2) then -- only try for the others if we're good on envs and plants on playfield'
                    for k=1, 4 do -- check all 4 possible roles card could fill
                        if #discardPile > 0 and discardPile[#discardPile]["cardData"]["Diet"..k.."_Value"] == j then
                            if drawFromDiscard < 2 then                                    
                                drawFromDiscard = 1
                            end
                            break
                        end
                    end
                    if totalDrawn == 0 and drawFromDiscard < 1 and #discardPile - 1 > 0 then -- if we didn't find it, check next lower one. this might need tweaked    
                        for k=1, 4 do -- check all 4 possible roles card could fill
                            if discardPile[#discardPile - 1]["cardData"]["Diet"..k.."_Value"] == j then
                                drawFromDiscard = 2
                                break
                            end
                        end
                    end   
                end
            end
        else
            break
        end
    end

    -- try to pull from discard pile now
    if drawFromDiscard > 0 then
        for j = 1 , drawFromDiscard do
            local discardCard = discardPile[#discardPile]
            scrollY = controls:GameLogAdd(logScroll,scrollY,whoString.." has drawn the "..discardCard["cardData"]["Name"].." card from the discard pile.")
            discardCard:removeEventListener("touch", DiscardMovementListener);
            discardCard:removeEventListener("tap", ZoomTapListener)
            table.insert(currentHand, discardCard)
            discardPile[#discardPile] = nil
            totalDrawn = totalDrawn + 1
        end
    end   
    
    return totalDrawn
end

function scene:EndTurn()
    if turnCount > 1 then
        scene:DiscardHand(hand)               
        scene:AdjustScroller()
    end    
    
    -- determine current score    
    local curEco = gameLogic:CalculateScore(activeEnvs)
    scene:ScoreImageChange(curEco, "player")    
    
    local pullCount = 0
    local playCount = 0
    local stalemate = true -- see if we have a stalemate
    
    drawCount = 1
    if numOpp > 0 then       
        for i = 1, numOpp do
            local whoString = "Opponent"..i
            
            -- computer will check discard pile before drawing blindly from deck
            if turnCount > 1 then -- only do this after first turn.                
                local cardsDrawn = 0
                
                while cardsDrawn < 2 do
                    cardsDrawn = scene:ComputerDiscard(cpuActiveEnvs[i], whoString, cpuHand[i], cardsDrawn)

                    -- draw from deck if they haven't taken 2 from discard
                    if cardsDrawn < 2 then
                        scene:drawCards(1, cpuHand[i], whoString)
                        cardsDrawn = cardsDrawn + 1
                    end
                end
            end 
            
            for j = 1, 3 do-- computer will try to replay hand by dumping active playfield into hand and replaying everything
                if cpuActiveEnvs[i][j] then  
                    for k = 1, 2 do
                        if cpuActiveEnvs[i][j]["chain"..k] then
                            for m = 1, #cpuActiveEnvs[i][j]["chain"..k] do
                                if m > 1 then -- we're going to ignore plants here. todo could make them placed into hand if strohmstead is active
                                    pullCount = pullCount + 1
                                    table.insert(cpuHand[i], cpuActiveEnvs[i][j]["chain"..k][m])
                                    cpuActiveEnvs[i][j]["chain"..k][m] = nil
                                end
                            end
                        end                        
                    end
                end
            end
            
            -- opponent tries to play cards
            -- cycle through their entire hand
            local ind = 1
            local playedString = ""
            
            while cpuHand[i][ind] do
                local cardPlayed = false

                if cpuHand[i][ind]["cardData"].Type == "Environment" then -- try to play an environment card
                    for j = 1, 3 do                            
                        cardPlayed, playedString = gameLogic:PlayEnvironment(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, "Opponent"..i)

                        if cardPlayed then -- break the for loop if a card has been played
                            playCount = playCount + 1
                            break
                        end
                    end
                elseif cpuHand[i][ind]["cardData"].Type == "Small Plant" or cpuHand[i][ind]["cardData"].Type == "Large Plant" then
                    for j = 1, 3 do -- try all 3 environments                        
                        if cardPlayed then
                            playCount = playCount + 1
                            break
                        end
                        
                        for k = 1, 2 do -- try both chains on each env
                            local chainString = "chain"..k
                                                                           
                            cardPlayed, playedString = gameLogic:PlayPlant(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)
                        
                            if cardPlayed then -- break the for loop if a card has been played
                                playCount = playCount + 1
                                break
                            end
                        end
                    end
                elseif cpuHand[i][ind]["cardData"].Type == "Invertebrate" or cpuHand[i][ind]["cardData"].Type == "Small Animal" or cpuHand[i][ind]["cardData"].Type == "Large Animal" or cpuHand[i][ind]["cardData"].Type == "Apex" then
                    for j = 1, 3 do -- try all 3 environments                        
                        if cardPlayed then
                            playCount = playCount + 1
                            break
                        end
                        
                        for k = 1, 2 do -- try both chains on each env
                            local chainString = "chain"..k
                                                                           
                            cardPlayed, playedString = gameLogic:PlayAnimal(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)
                        
                            if cardPlayed then -- break the for loop if a card has been played
                                playCount = playCount + 1
                                break
                            end
                        end
                    end
                elseif cpuHand[i][ind]["cardData"].Type == "Wild" then
                    for j = 1, 3 do -- try all 3 environments                          
                        if cardPlayed then
                            playCount = playCount + 1
                            break
                        else -- try to play as env
                            cardPlayed, playedString = gameLogic:PlayEnvironment(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, "Opponent"..i)
                        
                            if cardPlayed then
                                playCount = playCount + 1
                                break 
                            else -- else try to play as plant                            
                                for k = 1, 2 do -- try both chains on each env
                                    local chainString = "chain"..k
                                    cardPlayed, playedString = gameLogic:PlayPlant(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)

                                    if cardPlayed then
                                        playCount = playCount + 1
                                        break
                                    else-- else try to play as animal 
                                        cardPlayed, playedString = gameLogic:PlayAnimal(cpuHand[i][ind], cpuHand[i], cpuActiveEnvs[i], j, chainString, "Opponent"..i)

                                        if cardPlayed then
                                            playCount = playCount + 1
                                            break
                                        end
                                    end
                                end  
                            end    
                        end
                    end
                end 

                
                 -- decrement counter if card was played since
                 -- the hand's index has been changed
                if not cardPlayed then
                    ind = ind + 1
                elseif playedString ~= "" then
                    scrollY = controls:GameLogAdd(logScroll,scrollY,playedString)
                    ind = 1 -- if a card was played, start back at start of hand in case ones already tried can now be played
                end                
            end
            
            -- discard remaining hand after playing
            if turnCount > 1 then
                scene:DiscardHand(cpuHand[i])
            end
        end
    end 
    
    if pullCount == playCount and playCount > 0  then
        stalemateCounter = stalemateCounter + 1
    else
        stalemateCounter = 0
    end
    
    
    -- we've tried to replay all cards for cpu now.
    -- now check to see if there's still a deadlock for lg plant, apex, lg animal, wild, etc.
    if stalemateCounter >= 2 then
        stalemateCounter = 0
        
        local lgPlantCount = 0
        local lgAnimalCount = 0
        local apexCount = 0
        
        -- see if opponents are holding all of certain card types
        for i = 1, numOpp do
            for j = 1, 3 do
                if cpuActiveEnvs[i][j] then
                    for k = 1, 2 do
                        if cpuActiveEnvs[i][j]["chain"..k] then
                            for m = 1, #cpuActiveEnvs[i][j]["chain"..k] do
                                if cpuActiveEnvs[i][j]["chain"..k][m]["cardData"]["Type"] == "Large Plant" then
                                    lgPlantCount = lgPlantCount + 1
                                elseif cpuActiveEnvs[i][j]["chain"..k][m]["cardData"]["Type"] == "Large Animal" then
                                    lgAnimalCount = lgAnimalCount + 1
                                elseif cpuActiveEnvs[i][j]["chain"..k][m]["cardData"]["Type"] == "Apex" then
                                    apexCount = apexCount + 1
                                end                                
                            end
                        end 
                    end
                end
            end
        end
        
        if lgPlantCount == 6 or lgAnimalCount == 7 or apexCount == 6 or turnCount > 30 then
            local winString = "You lose!"
            local screenString = "screens.Lose" 
            scrollY = controls:GameLogAdd(logScroll,scrollY,winString)
            local options = 
            {
                params = {
                    pTime = gameTime,
                    pPlayed = cardsPlayed,
                    pDrawn = drawn,
                    pTurns = turnCount
                }
            }
            local catcherMain = controls:TouchCatcher(mainGroup)
            local catcherOpp = controls:TouchCatcher(oppGroup)
            timer.performWithDelay(1500, function() composer.gotoScene(screenString, options) end)          
        end        
    end
end

function scene:ShowOpponentCards(oppNum)
    
    -- hide the player's hand and cards
    mainGroup.isVisible = false
    scrollView.isVisible = false
    
    -- check to see if computer player has won. if so, go to lose screen
    local cpuScore = gameLogic:CalculateScore(cpuActiveEnvs[oppNum])            
    scene:ScoreImageChange(cpuScore, "cpu")    
    
    for i = 1, 10 do
        oppGroup:insert(cpuScoreIconsOn[i])
        oppGroup:insert(cpuScoreIconsOff[i])
    end    
    
    local myChain = ""
    
    for i = 1, 3 do
        if cpuActiveEnvs[oppNum] and cpuActiveEnvs[oppNum][i] then
            oppGroup:insert(cpuActiveEnvs[oppNum][i]["activeEnv"])
            if sound then
                audio.play(cardSlide)  
            end
            transition.moveTo( cpuActiveEnvs[oppNum][i]["activeEnv"], {x = GLOB.envLocs[i]["xLoc"], y = GLOB.envLocs[i]["yLoc"], time = 1000})
            cpuActiveEnvs[oppNum][i]["activeEnv"]:toFront()
            cpuActiveEnvs[oppNum][i]["activeEnv"].rotation = 270   

            for j = 1, 2 do
                myChain = "chain"..j            
                
                if cpuActiveEnvs[oppNum][i][myChain] then
                    for k = 1, #cpuActiveEnvs[oppNum][i][myChain] do                    
                        local myCard = cpuActiveEnvs[oppNum][i][myChain][k]                    
                        oppGroup:insert(myCard)                        
                        transition.moveTo( myCard, {x = GLOB.chainLocs[i][myChain]["xLoc"], y = GLOB.chainLocs[i][myChain]["yLoc"] + (k * GLOB.cardOffset), time = 1000})
                        myCard:toFront()
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
    utilities:ShuffleDeck(deck)-- deck should be shuffled after this    
    
    hand = {}--initialize tables for where cards will be stored
    discardPile = {} 
    scene:drawCards(5,hand, "Player")    -- pass 5 cards out to the player
    numOpp = 2
    
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
    
    scrollY = controls:GameLogAdd(logScroll,scrollY, "Drag an environment card onto the playfield.")
    scrollY = controls:GameLogAdd(logScroll,scrollY, "Plant cards can be played on environments.")
    scrollY = controls:GameLogAdd(logScroll,scrollY, "Other animals can be played on plants.")
    scrollY = controls:GameLogAdd(logScroll,scrollY, "If no more cards can be played, press end turn.")
    scrollY = controls:GameLogAdd(logScroll,scrollY, "On each successive turn, draw 2 cards and discard all cards at end of turn.")
    scrollY = controls:GameLogAdd(logScroll,scrollY, "Cards can be drawn from the draw pile or pulled from the discard pile into the hand.")
end

-- turn on/off the appropriate score indicators as well as checking for a winner
-- can be called for player and cpu
function scene:ScoreImageChange(myEco, who)
    local playerWin, cpuWin, winString, screenString, winningGroup
    local gameOver = false
    
    if who == "player" then
        playerWin = true
    else
        cpuWin = true
    end    
    
    for i = 1, 10 do
        if myEco[i] then
            if who == "player" then
                scoreIconsOn[i].isVisible = true
                scoreIconsOff[i].isVisible = false                
            else
                cpuScoreIconsOn[i].isVisible = true
                cpuScoreIconsOff[i].isVisible = false                 
            end
        else
            if who == "player" then
                scoreIconsOn[i].isVisible = false
                scoreIconsOff[i].isVisible = true 
                playerWin = false
            else
                cpuScoreIconsOn[i].isVisible = false
                cpuScoreIconsOff[i].isVisible = true
                cpuWin = false
            end
        end
    end 

    -- set things up if someone has one
    if who == "player" and playerWin then
        gameOver = true
        winString = "You win!"
        winningGroup = mainGroup
        screenString = "screens.Win"
    elseif who == "cpu" and cpuWin then
        gameOver = true
        winString = "You lose!"
        winningGroup = oppGroup
        screenString = "screens.Lose" 
    end  
    
    if gameOver then -- a winner has been found. do what needs to be done
        scrollY = controls:GameLogAdd(logScroll,scrollY,winString)
        local options = 
        {
            params = {
                pTime = gameTime,
                pPlayed = cardsPlayed,
                pDrawn = drawn,
                pTurns = turnCount
            }
        }
        local catcher = controls:TouchCatcher(winningGroup)
        timer.performWithDelay(1500, function() composer.gotoScene(screenString, options) end)
    end
end

function scene:ResumeGame()
    sound = GLOB.pSound
    music = GLOB.pMusic
    
    if GLOB.pMusic then
        --audio.resume(backgroundMusic)
    end    
end

function scene:create( event )
    local sceneGroup = self.view
    mainGroup = display.newGroup() -- display group for anything that just needs added
    sceneGroup:insert(mainGroup) 
    oppGroup = display.newGroup()
    cpuBackground = display.newRect( display.contentWidth/2, display.contentHeight/2, display.contentWidth, display.contentHeight )
    cpuBackground:toBack()    
    hiddenGroup = display.newGroup()
    sceneGroup:insert(oppGroup)
    sceneGroup:insert(hiddenGroup)
    oppGroup.isVisible = false
    hiddenGroup.isVisible = false  
    oppGroup:insert(cpuBackground)

    
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
    
    gameTime = 0
    gameTimer = timer.performWithDelay( 1000, gameTimeListener, -1)
    
    cardsPlayed = 0
    drawn = 0
    -- initialize sounds
    cardSlide = audio.loadSound("sounds/cardSlide.wav")
    click = audio.loadSound("sounds/click.wav")
    backgroundMusic = audio.loadStream("sounds/forestLoop.wav")
    sound = GLOB.pSound
    music = GLOB.pMusic 

    controls:MakeElements(mainGroup)
    overlay = controls:MakeOverlay(mainGroup)
    overlay:toBack()
    logScroll = controls:MakeLogScroll(mainGroup, GLOB.logScrollWidth)
    scrollView = controls:MakeScrollView(mainGroup)  
    controls:MakeArrows(mainGroup, scrollView)
    scoreIconsOn = controls:ScoreIconsOn(mainGroup)
    scoreIconsOff = controls:ScoreIconsOff(mainGroup)
    cpuScoreIconsOn = controls:ScoreIconsOn(oppGroup)
    cpuScoreIconsOff = controls:ScoreIconsOff(oppGroup)  
    
    local function drawCardListener( event )
        local object = event.target
        if(drawCount < 3 and turnCount > 1)then
            scene:drawCards(1,hand, "Player")
            drawCount = drawCount + 1
        end
        return true
    end      

    cardBack = controls:CardBack(mainGroup)
    cardBack:addEventListener( "tap", drawCardListener )    
       
    local btnY = 400
   
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:PlayCard()
    end
    
 -- frontObject:addEventListener( "tap", tapListener )

    --mainGroup:insert(frontObject)
    --mainGroup:insert(frontLabel)
    
    -- show opp 1 cards
    --local showOpp = display.newRect( 750, btnY, 100, 100 )
    --showOpp:setFillColor(.5,.5,.5)
    --local showOppLabel = display.newText( { text = "Show Opponent", x = 750, y = btnY, fontSize = 16 } )
    --showOppLabel:setTextColor( 1 )
    
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:ShowOpponentCards(1)
    end

    --showOpp:addEventListener( "tap", tapListener )

   -- mainGroup:insert(showOpp)
   -- mainGroup:insert(showOppLabel)    
    
    -- show opp 1 cards
    local showMain = display.newRect( 900, 424, 100, 100 )
    showMain:setFillColor(.5,.5,.5)
    
    local playerIndic = display.newRect(display.contentWidth/2, btnY + 200, 200,40)
    playerIndic:setFillColor(.5,.5,.5)
    
    local function oppViewListener( event )
        while oppGroup[1] do
           hiddenGroup:insert(oppGroup[1])
        end
        
  
        scene:HideOpponentCards()
        showMain.isVisible = true
        playerIndic.isVisible = true

       
        
        if(currentOpp<=numOpp)then
            currentOpp = currentOpp + 1
        end
        
        if(currentOpp==numOpp+1)then
            scene:HideOpponentCards() 
        else
            if(currentOpp == numOpp)then
                showMain.fill = {type = "image",filename = "images/view-your-hand.png"}
                playerIndic.fill = {type = "image",filename = "images/title-player-2.png"}
                cpuBackground.fill = {type = "image",filename = "images/background-player-2.png"}
            end
            
            scene:ShowOpponentCards(currentOpp)
        end
        
        oppGroup:insert(cpuBackground)
        cpuBackground:toBack()
        oppGroup:insert(showMain)
        oppGroup:insert(playerIndic)
    end
    
    showMain:addEventListener( "tap", oppViewListener )

    oppGroup:insert(cpuBackground)
    cpuBackground:toBack()
    oppGroup:insert(showMain)
    oppGroup:insert(playerIndic)

    
    --local getHuman = display.newRect( 650, btnY, 100, 100 )
    --getHuman:setFillColor(.5,.5,.5)
    --local getHumanLabel = display.newText( { text = "Get Human", x = 650, y = btnY, fontSize = 16 } )
    --getHumanLabel:setTextColor( 1 )
    
    local function tapListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
        scene:DebugGetCard(86) -- human card
        scene:DebugGetCard(22) -- strohmstead
        scene:DebugGetCard(1) -- env
        scene:DebugGetCard(26) -- plant
        scene:DebugGetCard(42) -- inv
        scene:DebugGetCard(63)  
        scene:DebugGetCard(60)
        scene:DebugGetCard(36)
        scene:DebugGetCard(29)
        scene:DebugGetCard(69)
    end
    
    --getHuman:addEventListener( "tap", tapListener )

   -- mainGroup:insert(getHuman)
    -- mainGroup:insert(getHumanLabel) 

    local endTurnBtn = display.newRect( GLOB.scoreImages["col1"] + 25, 425, 100, 100)    
    endTurnBtn.fill = {type = "image",filename = "images/end-turn-button.png"}
    
     local function endTurnListener( event )
        local self = event.target

        if(event.phase == "began") then
            currentOpp = 1
            display.getCurrentStage():setFocus(event.target)
        elseif(event.phase == "ended") then
            display.getCurrentStage():setFocus(nil)
            
            if drawCount < 3 and turnCount > 1 then
                scrollY = controls:GameLogAdd(logScroll,scrollY,"Please draw " .. 3 - drawCount  .. " card(s).")
                display.getCurrentStage():setFocus(nil)
            else
                display.getCurrentStage():setFocus(nil)
                scene:EndTurn()
                turnCount = turnCount + 1
                oppGroup:insert(cpuBackground)
                cpuBackground:toBack()
                showMain.fill = {type = "image",filename = "images/view-next-player.png"}
                playerIndic.fill = {type = "image",filename = "images/title-player-1.png"}
                cpuBackground.fill = {type = "image",filename = "images/background-player-1.png"}
                display.getCurrentStage():setFocus(event.target)
                scene:ShowOpponentCards(currentOpp)
            end           
        end 
    end        
    
    endTurnBtn:addEventListener( "touch", endTurnListener )
    mainGroup:insert(endTurnBtn)  
    
    --audio.play(backgroundMusic, {channel = 1,loops = -1,fadein = 5000})
    audio.setVolume( 0.5, { channel=1 } )
end

-- "scene:show()"
function scene:show( event )

   local sceneGroup = self.view
   local phase = event.phase

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
      sound = GLOB.pSound
      music = GLOB.pMusic
   elseif ( phase == "did" ) then
      -- Called when the scene is now on screen.
      -- Insert code here to make the scene come alive.
      -- Example: start timers, begin animation, play audio, etc.
        composer.removeScene("screens.Win")
        composer.removeScene("screens.Lose")
        composer.removeScene("screens.tutorial")
        timer.resume(gameTimer)
        scene:InitializeGame()
        if music then
            --audio.resume(backgroundMusic)
        end
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
      if music then
        --audio.pause(backgroundChanel)
      end

      if gameTimer then
        timer.pause(gameTimer)
      end

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
