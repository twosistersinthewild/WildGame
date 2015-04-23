local composer = require( "composer" )
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local loadingScreen
---------------------------------------------------------------------------------
function scene:create( event )
    local sceneGroup = self.view
    --sound = event.params.pSound
    
    local function menuListener(event)
        local self = event.target
        
        if(event.phase == "began") then
            self.alpha = 1
            display.getCurrentStage():setFocus(event.target)
        elseif(event.phase == "ended") then
            self.alpha = .1
            display.getCurrentStage():setFocus(nil)
            if self.name == "play" then -- display loading screen then call next scene
                -- i put a small delay on the call to gotoScene or else the loading screen wouldn't actually come to front
                -- before starting the load
                loadingScreen:toFront()
                timer.performWithDelay(50, function() composer.gotoScene("screens.Game") end)
            elseif self.name == "howToPlay" then
                --system.openURL( "https://www.youtube.com/watch?v=n4Cc02VLYq4" )
                loadingScreen:toFront()
                timer.performWithDelay(50, function() composer.gotoScene("screens.tutorial") end)                
            elseif self.name == "settings" then
                local options = {
                isModal = true,
                effect = "fade",
                time = 400,
                params = {name = "menu", pTime = 7, pDrawn = 8, pPlayed = 9, pTurns = 10}
                }
                composer.showOverlay( "screens.SettingsOverlay", options )
                --composer.showOverlay( "screens.Lose", options )
                --composer.showOverlay( "screens.Win", options )
            elseif self.name == "exit" then
                os.exit();
            end
        end    
    end
    
    loadingScreen = display.newRect(sceneGroup, display.contentWidth / 2, display.contentHeight / 2, display.contentWidth, display.contentHeight )
    imgString = "images/ORIGINAL-Load-Screen.png"
    local paint = {
        type = "image",
        filename = imgString
    }
    loadingScreen.fill = paint
    sceneGroup:insert(loadingScreen)   
    
    local background = display.newImage("images/ORIGINAL-Main-Menu.jpg")
    background.x = display.contentWidth / 2
    background.y = display.contentHeight / 2
    sceneGroup:insert(background)
   
   local play = display.newRect(665, 365, 314, 32);
   imgString = "images/main-play.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    play.fill = paint 
    play.alpha = .1;
    play:addEventListener("touch", menuListener)
    play.name = "play"
    sceneGroup:insert(play)
    play:toFront()
    
    local howToPlay = display.newRect(665, 437, 314, 32);
    imgString = "images/main-how-to-play.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    howToPlay.fill = paint 
    howToPlay.alpha = .1;
    howToPlay:addEventListener("touch", menuListener)
    howToPlay.name = "howToPlay"
    sceneGroup:insert(howToPlay)
    
    local settings = display.newRect(665, 513, 314, 32);
    imgString = "images/main-settings.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    settings.fill = paint 
    settings.alpha = .1;
    settings:addEventListener("touch", menuListener)
    settings.name = "settings"
    sceneGroup:insert(settings)
    
    local exit = display.newRect(665, 585, 314, 32);
    imgString = "images/main-exit.jpg"
    local paint = {
        type = "image",
        filename = imgString
    }
    exit.fill = paint 
    exit.alpha = .1;
    exit:addEventListener("touch", menuListener)
    exit.name = "exit"
    sceneGroup:insert(exit)
end

-- "scene:show()"
function scene:show( event )

   local sceneGroup = self.view
   local phase = event.phase

   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
      -- scene:showButton()
   elseif ( phase == "did" ) then
      composer.removeScene("screens.Game")
      composer.removeScene("screens.tutorial")
      loadingScreen:toBack();
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
  
  composer.removeScene("screens.MainMenu")
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