-- the line below caused a problem because the load function is used in globals.lua
local GLOB = require "globals"
local widget = require "widget"
local composer = require "composer"

local controls = {}
local controls_mt = { __index = controls }	-- metatable
 
-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
 
-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------
 
function controls.new()	-- constructor
local newControls = {}
return setmetatable( newControls, controls_mt )
end
 
-------------------------------------------------
function controls:MakeElements(myGroup)
    -- background
    local background = display.newImage("images/ORIGINAL-background-green.jpg")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2
    
    -- env indicators
    local env1Indicator = display.newImage("assets/2014-RIVER-03.jpg")
    env1Indicator.x = GLOB.envLocs[1]["xLoc"]
    env1Indicator.y = GLOB.envLocs[1]["yLoc"]
    env1Indicator.width = 100
    env1Indicator.height = 160
    env1Indicator.rotation = 270
    env1Indicator.alpha = .5
    local env2Indicator = display.newImage("assets/2014-FOREST-02.jpg")
    env2Indicator.x = GLOB.envLocs[2]["xLoc"]
    env2Indicator.y = GLOB.envLocs[2]["yLoc"]
    env2Indicator.width = 100
    env2Indicator.height = 160
    env2Indicator.rotation = 270    
    env2Indicator.alpha = .5
    local env3Indicator = display.newImage("assets/2014-FIELD-03.jpg")
    env3Indicator.x = GLOB.envLocs[3]["xLoc"]
    env3Indicator.y = GLOB.envLocs[3]["yLoc"]  
    env3Indicator.width = 100
    env3Indicator.height = 160
    env3Indicator.rotation = 270    
    env3Indicator.alpha = .5
    
    -- discard image
    local discardImage = display.newRect(GLOB.discardXLoc, GLOB.discardYLoc, GLOB.cardWidth, GLOB.cardHeight)   
    discardImage.fill = {type = "image",filename = "images/discard-pile.png"}  
    
    local settingsBtn = display.newRect( GLOB.scoreImages["col1"] + 25, 315, 100, 100 )
    settingsBtn.fill = {type = "image",filename = "images/options-button.png"}
 
    local function settingsBtnListener( event ) 
        local self = event.target
    
        if(event.phase == "began") then
            self.alpha = 1
            display.getCurrentStage():setFocus(event.target)
        elseif(event.phase == "ended") then
            display.getCurrentStage():setFocus(nil)
            local options = 
            {
                isModal = true,
                effect = "fade",
                time = 400,
                params = {name = "game"}
            }
            audio.pause()
            composer.showOverlay( "screens.SettingsOverlay", options )
        end 
    end      
    
    settingsBtn:addEventListener( "touch", settingsBtnListener )         
    
    -- order matters here
    myGroup:insert(background)
    myGroup:insert(discardImage)
    myGroup:insert(settingsBtn)  
    myGroup:insert(env1Indicator)
    myGroup:insert(env2Indicator)
    myGroup:insert(env3Indicator)
end

function controls:MakeOverlay(myGroup)
    local element
    element = display.newRect(display.contentWidth / 2, display.contentHeight / 2, display.contentWidth, display.contentHeight)    
    element:setFillColor(0,0,0)    
    element.alpha = .5    
    myGroup:insert(element)
    return element
end

function controls:MakeLogScroll(myGroup, scrollWidth)
    local element
    element = widget.newScrollView
    {
        width = scrollWidth,
        -- aww
        height = 160,
        horizontalScrollDisabled = true,
        isBounceEnabled = false,
        hideScrollBar = false,
        backgroundColor = {1,1,1},
        friction = 0
    }
    
    element.x = GLOB.gameLogXLoc
    element.y = GLOB.gameLogYLoc

    myGroup:insert(element) 
    return element
end

function controls:MakeScrollView(myGroup)
    local element
    element = widget.newScrollView
    {
        width = GLOB.cardWidth * 5,
        height = GLOB.cardHeight,
        verticalScrollDisabled = true,
        backgroundColor = {0,0,0,0} -- transparent. remove the 0 to see it
    }
                
    --location
    element.x = GLOB.cardWidth * 2.5 + 50;    
    element.y = display.contentHeight - 80;    
    
    myGroup:insert(element)    
    return element
end

function controls:MakeArrows(myGroup, scroller)
    local rightScroll = function ()
        local newX, newY = scroller:getContentPosition();
        newX = newX - GLOB.cardWidth;
        scroller:scrollToPosition{ x = newX; y = newY; }
    end
    
    local leftScroll = function ()
        local newX, newY = scroller:getContentPosition();
        newX = newX + GLOB.cardWidth;
        scroller:scrollToPosition{ x = newX; y = newY; }
    end    
    
    local left_arrow = display.newRect(25, 580, 16, 57);
    left_arrow:addEventListener("tap" , leftScroll)
    left_arrow.fill = { type = "image", filename = "images/arrow.png"} 
    local right_arrow = display.newRect(GLOB.cardWidth * 5 + 75, 580, 16, 57);
    right_arrow:addEventListener("tap" , rightScroll)    
    right_arrow.fill = {type = "image",filename = "images/arrow.png"} 
    right_arrow.rotation = 180

    myGroup:insert(left_arrow)
    myGroup:insert(right_arrow)  
end

function controls:CardBack(myGroup)
    -- show the back of the card for the draw pile
    local element = display.newRect( GLOB.drawPileXLoc, GLOB.drawPileYLoc, GLOB.cardWidth, GLOB.cardHeight )
    element.fill = {type = "image",filename = "assets/v2-Back.jpg"} 
    myGroup:insert(element)  
    return element
end

function controls:CPUBG(myGroup)
    local element = display.newImage("images/ORIGINAL-background-green.jpg")
    element.x = display.contentWidth / 2
    element.y = display.contentHeight / 2
    myGroup:insert(element)
    element:toBack() 
    return element
end

function controls:ScoreIconsOff(myGroup)
    local iconTable = {}
    
    iconTable[1] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"],44,44) 
    iconTable[1].fill = {type = "image",filename = "images/1a.png"}  
    iconTable[1].alpha = .33    
    iconTable[2] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"],44,44)    
    iconTable[2].fill = {type = "image",filename = "images/2a.png"}
    iconTable[2].alpha = .33  
    iconTable[3] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50,44,44)
    iconTable[3].fill = {type = "image",filename = "images/3a.png"}
    iconTable[3].alpha = .33   
    iconTable[4] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50,44,44)
    iconTable[4].fill = {type = "image",filename = "images/4a.png"}
    iconTable[4].alpha = .33
    iconTable[5] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 2,44,44)
    iconTable[5].fill = {type = "image",filename = "images/5a.png"}
    iconTable[5].alpha = .33
    iconTable[6] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 2,44,44)
    iconTable[6].fill = {type = "image",filename = "images/6a.png"}
    iconTable[6].alpha = .33
    iconTable[7] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 3,44,44)
    iconTable[7].fill = {type = "image",filename = "images/7a.png"}
    iconTable[7].alpha = .33
    iconTable[8] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 3,44,44)
    iconTable[8].fill = {type = "image",filename = "images/8a.png"}
    iconTable[8].alpha = .33    
    iconTable[9] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 4,44,44)
    iconTable[9].fill = {type = "image",filename = "images/9a.png"}
    iconTable[9].alpha = .33 
    iconTable[10] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 4,44,44)
    iconTable[10].fill = {type = "image",filename = "images/10a.png"}
    iconTable[10].alpha = .33
    
    for i = 1, 10 do
        myGroup:insert(iconTable[i])
    end    
    
    return iconTable
end

function controls:ScoreIconsOn(myGroup) 
    local iconTable = {}
    
    iconTable[1] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"],44,44)
    iconTable[1].fill = {type = "image",filename = "images/1.png"}
    iconTable[2] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"],44,44)
    iconTable[2].fill = {type = "image",filename = "images/2.png"}
    iconTable[3] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50,44,44)
    iconTable[3].fill = {type = "image",filename = "images/3.png"}
    iconTable[4] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50,44,44)
    iconTable[4].fill = {type = "image",filename = "images/4.png"}
    iconTable[5] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 2,44,44)
    iconTable[5].fill = {type = "image",filename = "images/5.png"}
    iconTable[6] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 2,44,44)
    iconTable[6].fill = {type = "image",filename = "images/6.png"}
    iconTable[7] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 3,44,44)
    iconTable[7].fill = {type = "image",filename = "images/7.png"}
    iconTable[8] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 3,44,44)
    iconTable[8].fill = {type = "image",filename = "images/8.png"}
    iconTable[9] = display.newRect(myGroup,GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 4,44,44)
    iconTable[9].fill = {type = "image",filename = "images/9.png"}
    iconTable[10] = display.newRect(myGroup,GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 4,44,44)
    iconTable[10].fill = {type = "image",filename = "images/10.png"}
    
    for i = 1, 10 do        
        iconTable[i].isVisible = false
    end
    
    return iconTable
end

function controls:GameLogAdd(myScroller, scrollPos,logText)
    -- multiline text will be split and looped through, adding a max number of characters each line until completion
    -- todo make multiline text break at whole words rather than just split it
    
    print(logText) -- also show in console output for debugging. todo remove this
    
    local strMaxLen = 48
    local textWidth = GLOB.logScrollWidth
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
            y = scrollPos,
            width = textWidth,
            height = textHeight,
            font = native.systemFont,
            fontSize = 14,
            align = "left"    
        }  

        scrollPos = scrollPos + textHeight

        local itemLabel = display.newText(logOptions)
        itemLabel:setFillColor(0,0,0) 
        myScroller:insert(itemLabel)
        
        if charCount > strMaxLen then
            logText = "   "..multiLine
        else
            outputDone = true
        end    
    end

    myScroller:scrollTo("bottom",{time = 400}) -- had to set the y position to negative to get this to work right  

    return scrollPos
end


-------------------------------------------------

-------------------------------------------------
 
return controls

