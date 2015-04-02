local composer = require( "composer" )
local scene = composer.newScene()
local widget = require "widget"
local GLOB = require "globals"

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local soundChkBox
local musicChkBox
local play
local myParent

function jumpListener (event)
    local target = event.target;
            
    if(event.phase == "began") then
        display.getCurrentStage():setFocus(event.target)
    end
    if(event.phase == "ended") then
        display.getCurrentStage():setFocus(nil)
        if(target.name == "play")then
            composer.hideOverlay( "fade", 400 )
            --composer.gotoScene("screens.Game_test", options)
        end
        if(target.name == "menu") then
            --composer.hideOverlay()
            composer.gotoScene("screens.MainMenu")
        end
    end
    
    
end

local function catchStrays(event)
    return true
end
---------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view
    
    -- overlay background to absorb touch and tap events
    local oBack = display.newRect(sceneGroup,display.contentWidth/2, display.contentHeight/2,display.contentWidth, display.contentHeight)
    oBack:setFillColor(0,0,0)
    oBack.alpha = .7
    oBack:addEventListener("touch", catchStrays)
    oBack:addEventListener("tap", catchStrays)
    
    local background = display.newImage("images/ORIGINAL-settings-screen.png")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2
    sceneGroup:insert(background)
    
    local sOptions =     {
        id = "checkbox", 
        x = display.contentWidth / 2 - 100,
        y = 100,
        initialSwitchState = GLOB.pSound,
        onEvent = function(event) if event.phase == "ended" then GLOB.pSound = not GLOB.pSound end end
    }

    soundChkBox = widget.newSwitch(sOptions)
    sOptions["initialSwitchState"] = GLOB.pSound
    soundChkBox:setState( { isOn=GLOB.pSound} )
    
    
    local mOptions = {
        id = "checkbox", 
        x = display.contentWidth / 2 - 100,
        y = 200,
        initialSwitchState = GLOB.pMusic,
        onEvent = function(event) if event.phase == "ended" then GLOB.pMusic = not GLOB.pMusic end end
    }
    
    mOptions["initialSwitchState"] = GLOB.pMusic
    
    musicChkBox = widget.newSwitch(mOptions)
    --musicChkBox.isOn = false--GLOB.pMusic
    musicChkBox:setState( { isOn=GLOB.pMusic} )
    
    local soundLbl = display.newText( { text = "Sound", x = display.contentWidth / 2, y = 100, fontSize = 28 } )
    soundLbl:setTextColor( 1 )
    
    local musicLbl = display.newText( { text = "Music", x = display.contentWidth / 2, y = 200, fontSize = 28 } )
    musicLbl:setTextColor( 1 )
    
    
    sceneGroup:insert(soundChkBox)
    sceneGroup:insert(soundLbl)
    sceneGroup:insert(musicChkBox)
    sceneGroup:insert(musicLbl)
    

    play = display.newRect(665, 365, 314, 32);
    imgString = "images/main-play.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    play.fill = paint 
    play.alpha = 1;
    play:addEventListener("touch", jumpListener)
    play.name = "play"
    sceneGroup:insert(play)

    
    local menu = display.newRect(665, 415, 314, 32);
   imgString = "images/main-exit.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    menu.fill = paint 
    menu.alpha = 1;
    menu:addEventListener("touch", jumpListener)
    menu.name = "menu"
    sceneGroup:insert(menu)
   -- Initialize the scene here.
   -- Example: add display objects to "sceneGroup", add touch listeners, etc.
end

-- "scene:show()"
function scene:show( event )

   local sceneGroup = self.view
   local phase = event.phase
   local parent = event.parent -- this will be nil unless called by the game (not from main menu)
   myParent = event.params["name"] -- this is used in scene:hide

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
      if event.params["name"] == "menu" then -- the play/resume button will only be shown when called by game
          play.isVisible = false
      end
   elseif ( phase == "did" ) then
      -- Called when the scene is now on screen.
      -- Insert code here to make the scene come alive.
      -- Example: start timers, begin animation, play audio, etc.
   end
end

-- "scene:hide()"
function scene:hide( event )

   local sceneGroup = self.view
   local phase = event.phase
   local parent = nil
   
   if event.parent then
       parent = event.parent
   end  

   if ( phase == "will" ) then
      -- Called when the scene is on screen (but is about to go off screen).
      -- Insert code here to "pause" the scene.
      -- Example: stop timers, stop animation, stop audio, etc.
      if myParent == "game" then
          parent:ResumeGame()
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