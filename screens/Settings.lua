local composer = require( "composer" )
local scene = composer.newScene()
local widget = require "widget"

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local soundChkBox

function checkSound(event)
    if(event.phase == "ended") then
        print(soundChkBox.isOn)
    end
end

function jumpListener (event)
    local target = event.target;
    local options = 
        {
            params = {pSound = soundChkBox.isOn}
        }
            
    if(event.phase == "began") then
        display.getCurrentStage():setFocus(event.target)
    end
    if(event.phase == "ended") then
        display.getCurrentStage():setFocus(nil)
        if(target.name == "play")then
            composer.gotoScene("screens.Game_test_DO", options)
        end
        if(target.name == "menu") then
            composer.gotoScene("screens.MainMenu", options)
        end
    end
    
    
end
---------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view
    sound = event.params.pSound;
    
    local background = display.newImage("images/ORIGINAL-settings-screen.png")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2
    sceneGroup:insert(background)
    

    soundChkBox = widget.newSwitch
    {
        id = "checkbox", 
        x = display.contentWidth / 2 - 100,
        y = 100
    }
    
    local soundLbl = display.newText( { text = "Sound", x = display.contentWidth / 2, y = 100, fontSize = 28 } )
    soundLbl:setTextColor( 1 )
    soundLbl:addEventListener("touch", checkSound)
    
    sceneGroup:insert(soundChkBox)
    sceneGroup:insert(soundLbl)
    
    local play = display.newRect(665, 365, 314, 32);
   imgString = "/images/main-play.jpg"
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
   imgString = "/images/main-exit.jpg"
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

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
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