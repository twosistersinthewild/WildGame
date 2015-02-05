local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )
---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local scrollView
local icons = {}
---------------------------------------------------------------------------------
function scene:doit()   
    
    
    

    local function iconListener( event )
        local id = event.target.id
        if ( event.phase == "moved" ) then
            local dx = math.abs( event.x - event.xStart ) 
            if ( dx > 5 ) then
                scrollView:takeFocus( event ) 
            end
        elseif ( event.phase == "ended" ) then
            --take action if an object was touched
            print( "object", id, "was touched" )
            timer.performWithDelay( 10, function() scrollView:removeSelf(); scrollView = nil; end )
        end
        return true
    end
    local function showSlidingMenu( event )
        if ( "ended" == event.phase ) then
            scrollView = widget.newScrollView
            {
                --Originals
                --left = 37.5,
                --top = 225,
                --width = 460,
                --height = 100,
                --scrollWidth = 1200,
                --scrollHeight = 100,
                --verticalScrollDisabled = true

                --left = 0,
                --top = 225,
                --dimensions of scroll window
                width = 300,
                height = 169,

                verticalScrollDisabled = true,
                backgroundColor = {.5,.5,.5}
            }
            --location
            scrollView.x = display.contentCenterX
            scrollView.y = display.contentHeight - 80
            --Original scrollView.y = display.contentCenterY

            --Background
            --local scrollViewBackground = display.newRect( 600, 50, 1200, 100 )
            --scrollViewBackground:setFillColor( 1, 1, 1 )
           -- scrollView:insert( scrollViewBackground )
            --generate icons
            for i = 1, 10 do
                --originals
                --icons[i] = display.newCircle( i * 56, 50, 22 )
                --icons[i]:setFillColor( math.random(), math.random(), math.random() )
                local padding = 5;
                if i == 1 then
                    icons[i] = display.newImage("images/assets/v2-Back.jpg",i * 106, 80 )
                elseif i ~= 1 then
                    icons[i] = display.newImage("images/assets/v2-Back.jpg",i * 106 + padding , 80 )
                end
                scrollView:insert( icons[i] )
                icons[i].id = i
                icons[i]:addEventListener( "touch", iconListener )
            end
        end
        return true
    end
    --showSlidingMenu()
    local obj;
    obj = display.newCircle( display.contentCenterX, display.contentCenterY, 10 )
    print("hello")
    obj:setFillColor( 1, 1, 1)
    --Runtime:addEventListener("touch", showSlidingMenu)
    obj:addEventListener("touch", showSlidingMenu)




end

-- "scene:create()"
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
      scene:doit()
   elseif ( phase == "did" ) then
       composer.removeScene("screens.Start")
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