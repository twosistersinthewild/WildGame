local composer = require( "composer" )
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here

---------------------------------------------------------------------------------


function scene:create( event )

   local sceneGroup = self.view
   
          local endTurnBtn = display.newRect( 75, 75, 150, 150 )
    endTurnBtn.alpha = 0.8
    endTurnBtn.name = "Front Object"
   
    
    local function endTurnListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
    composer.gotoScene("screens.CardMovement")
end    
    
    endTurnBtn:addEventListener( "tap", endTurnListener )
    sceneGroup: insert(endTurnBtn)
    
    local sliderDemo = display.newRect( 75, 250, 150, 150 )
    sliderDemo.alpha = 0.8
    sliderDemo.name = "Front Object"
    local sliderDemoLbl = display.newText( { text = "sliderDemo", x = 75, y = 250, fontSize = 28 } )
    sliderDemoLbl:setTextColor( 1 )
    
    local function sliderDemoListener( event )
        local object = event.target
        --print( object.name.." TAPPED!" )
    composer.gotoScene("screens.scrollViewDemo")
end    
    
    sliderDemo:addEventListener( "tap", sliderDemoListener )
    sceneGroup: insert(sliderDemo)
    sceneGroup:insert(sliderDemoLbl)
    
        local logicDemo = display.newRect( 75, 425, 150, 150 )
        logicDemo.alpha = 0.8
        logicDemo.name = "Front Object"
        local logicDemoLbl = display.newText( { text = "logicDemo", x = 75, y = 425, fontSize = 28 } )
        logicDemoLbl:setTextColor( 1 )

        local function logicDemoListener( event )
            local object = event.target
            --print( object.name.." TAPPED!" )
            composer.gotoScene("screens.Game_test")
        end    

        logicDemo:addEventListener( "tap", logicDemoListener )
        sceneGroup: insert(logicDemo)
        sceneGroup:insert(logicDemoLbl)    
   -- Initialize the scene here.
   -- Example: add display objects to "sceneGroup", add touch listeners, etc.
end

-- "scene:show()"
function scene:show( event )

   local sceneGroup = self.view
   local phase = event.phase

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
      -- scene:showButton()
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