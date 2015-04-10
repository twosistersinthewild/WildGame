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

function controls:ScoreIcons(myGroup)    
    local one_off = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"],44,44) 
    one_off.fill = {type = "image",filename = "images/1a.png"}  
    one_off.alpha = .33
    
    local one_on = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"],44,44)
    one_on.fill = {type = "image",filename = "images/1.png"}
    
    local two_off = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"],44,44)    
    two_off.fill = {type = "image",filename = "images/2a.png"}
    two_off.alpha = .33
    
    local two_on = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"],44,44)
    two_on.fill = {type = "image",filename = "images/2.png"}
    
    local three_off = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50,44,44)
    three_off.fill = {type = "image",filename = "images/3a.png"}
    three_off.alpha = .33
    
    local three_on = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50,44,44)
    three_on.fill = {type = "image",filename = "images/3.png"}
    
    local four_off = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50,44,44)
    four_off.fill = {type = "image",filename = "images/4a.png"}
    four_off.alpha = .33
    
    local four_on = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50,44,44)
    four_on.fill = {type = "image",filename = "images/4.png"}
    
    local five_off = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 2,44,44)
    five_off.fill = {type = "image",filename = "images/5a.png"}
    five_off.alpha = .33
    
    local five_on = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 2,44,44)
    five_on.fill = {type = "image",filename = "images/5.png"}
        
    local six_off = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 2,44,44)
    six_off.fill = {type = "image",filename = "images/6a.png"}
    six_off.alpha = .33
    
    local six_on = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 2,44,44)
    six_on.fill = {type = "image",filename = "images/6.png"}
    
    local seven_off = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 3,44,44)
    seven_off.fill = {type = "image",filename = "images/7a.png"}
    seven_off.alpha = .33
    
    local seven_on = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 3,44,44)
    seven_on.fill = {type = "image",filename = "images/7.png"}
    
    local eight_off = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 3,44,44)
    eight_off.fill = {type = "image",filename = "images/8a.png"}
    eight_off.alpha = .33
    
    local eight_on = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 3,44,44)
    eight_on.fill = {type = "image",filename = "images/8.png"}
    
    local nine_off = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 4,44,44)
    nine_off.fill = {type = "image",filename = "images/9a.png"}
    nine_off.alpha = .33
    
    local nine_on = display.newRect(GLOB.scoreImages["col1"],GLOB.scoreImages["row1"] + 50 * 4,44,44)
    nine_on.fill = {type = "image",filename = "images/9.png"}
    
    local ten_off = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 4,44,44)
    ten_off.fill = {type = "image",filename = "images/10a.png"}
    ten_off.alpha = .33
    
    local ten_on = display.newRect(GLOB.scoreImages["col1"] + 50,GLOB.scoreImages["row1"] + 50 * 4,44,44)
    ten_on.fill = {type = "image",filename = "images/10.png"}
    
    one_on.isVisible = false;
    two_on.isVisible = false;
    three_on.isVisible = false;
    four_on.isVisible = false;
    five_on.isVisible = false;
    six_on.isVisible = false;
    seven_on.isVisible = false;
    eight_on.isVisible = false;
    nine_on.isVisible = false;
    ten_on.isVisible = false;    
    
    myGroup:insert(one_on)
    myGroup:insert(one_off)
    myGroup:insert(two_on)
    myGroup:insert(two_off)
    myGroup:insert(three_on)
    myGroup:insert(three_off)
    myGroup:insert(four_on)
    myGroup:insert(four_off)
    myGroup:insert(five_on)
    myGroup:insert(five_off)
    myGroup:insert(six_on)
    myGroup:insert(six_off)
    myGroup:insert(seven_on)
    myGroup:insert(seven_off)
    myGroup:insert(eight_on)
    myGroup:insert(eight_off)
    myGroup:insert(nine_on)
    myGroup:insert(nine_off)
    myGroup:insert(ten_on)
    myGroup:insert(ten_off)      
    
    return one_on,one_off,two_on,two_off,three_on,three_off,four_on,four_off,five_on,five_off,six_on,six_off,seven_on,seven_off,eight_on,eight_off,nine_on,nine_off,ten_on,ten_off
end

function controls:GameLogAdd(myScroller, logText)
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
            y = GLOB.scrollY,
            width = textWidth,
            height = textHeight,
            font = native.systemFont,
            fontSize = 14,
            align = "left"    
        }  

        GLOB.scrollY = GLOB.scrollY + textHeight

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
end
-------------------------------------------------

-------------------------------------------------
 
return controls

