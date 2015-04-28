local composer = require( "composer" )
local scene = composer.newScene()
local GLOB = require "globals"

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local function menuListener (event)
    local self = event.target
    if event.phase == "ended" then
        if self.name == "play" then
            composer.removeScene("screens.Game")
            composer.gotoScene("screens.Game")
        elseif self.name == "menu" then
            composer.gotoScene("screens.MainMenu")
        elseif self.name == "exit" then
            os.exit();
        end
    end
end
---------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

   local sceneGroup = self.view
   sound = GLOB.pSound
   music = GLOB.pMusic
   
   local background = display.newImage("images/ORIGINAL-lose-screen.png")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2

    sceneGroup:insert(background)

    local timeLbl = display.newText( { text = event.params.pTime.." Seconds", x = 820, y = 188, fontSize = 28 } )
    timeLbl:setTextColor( 1 )
    sceneGroup:insert(timeLbl)
    
    local playedLbl = display.newText( { text = event.params.pPlayed, x = 755, y = 308, fontSize = 28 } )
    playedLbl:setTextColor( 1 )
    sceneGroup:insert(playedLbl)
    
    local drawnLbl = display.newText( { text = event.params.pDrawn, x = 755, y = 370, fontSize = 28 } )
    drawnLbl:setTextColor( 1 )
    sceneGroup:insert(drawnLbl)
    
    local turnLbl = display.newText( { text = event.params.pTurns, x = 755, y = 250, fontSize = 28 } )
    turnLbl:setTextColor( 1 )
    sceneGroup:insert(turnLbl)
    
    local play = display.newRect(450, 585, 80, 80);
    imgString = "images/new-game-button.png"
    local paint = {
        type = "image",
        filename = imgString
    }
    play.fill = paint 
    play:addEventListener("touch", menuListener)
    play.name = "play"
    sceneGroup:insert(play)
    
    local menu = display.newRect(650, 585, 80, 80);
    imgString = "images/main-menu-button.png"
    local paint = {
        type = "image",
        filename = imgString
    }
    menu.fill = paint 
    menu:addEventListener("touch", menuListener)
    menu.name = "menu"
    sceneGroup:insert(menu)
    
    local exit = display.newRect(850, 585, 80, 80);
    imgString = "images/exit-button.png"
    local paint = {
        type = "image",
        filename = imgString
    }
    exit.fill = paint 
    exit:addEventListener("touch", menuListener)
    exit.name = "exit"
    sceneGroup:insert(exit)
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
       composer.removeScene("screens.Game")
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

