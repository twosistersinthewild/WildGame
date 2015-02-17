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
    local group = display.newGroup();
    
    local function newListener(event)
        if event.phase == "began" then
            print('x');
            --print(event.numTaps);
        
        elseif event.phase == "ended" then
            --scrollView:insert( icons[self.id] )
            --if (event.numTaps >= 2 ) then
            print(event.numTaps);
        end
    end
    
    local function movementListener(event)
        
        local self = event.target;
        
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object
        
        if event.phase == "began" then
	
            self.markX = self.x    -- store x location of object
            self.markY = self.y    -- store y location of object
            
            print(event.xStart, self.x);
	
        elseif event.phase == "moved"  then
	
            local x = (event.x - event.xStart) + self.markX
            local y = (event.y - event.yStart) + self.markY
        
        
            self.x, self.y = x, y    -- move object based on calculations above
        end;
        return true;
    end;

    local function iconListener( event )
        local id = event.target.id
        if ( event.phase == "moved" ) then
            local dx = math.abs( event.x - event.xStart ) 
            local dy = math.abs( event.y - event.yStart )
            if ( dx > 5 ) then
                scrollView:takeFocus( event ) 
            end
            
            if( dy > 10) then 
                icons[id].x = event.target.x;
                icons[id].y = display.contentHeight - event.target.y;
                group:insert(icons[id]);
                group:toFront();
                icons[id]:removeEventListener('touch', iconListener )
                icons[id]:addEventListener('touch', movementListener)
            end
        elseif ( event.phase == "ended" ) then
            --take action if an object was touched
            print( "object", id, "was touched" )
            --timer.performWithDelay( 10, function() scrollView:removeSelf(); scrollView = nil; end )
            --icons[id]:removeSelf();
            --icons[id].x = event.target.x;
            --icons[id].y = display.contentHeight - event.target.y;
            --print(event.target.x);
            --icons[id]:removeEventListener('touch', iconListener )
            --icons[id]:addEventListener('touch', movementListener)
            --icons[id]:addEventListener('touch', tapListener)
            --group:insert(icons[id]);
            --group:toFront();
            
        end
        return true
    end
    
    
    local function generateIcons()
        for i = 1, 10 do
            --originals
            --icons[i] = display.newCircle( i * 56, 50, 22 )
            --icons[i]:setFillColor( math.random(), math.random(), math.random() )
            local padding = 5;
            if i == 1 then
                icons[i] = display.newImage("images/assets/v2-Back.jpg",i * 200, 80 )
            elseif i ~= 1 then
                icons[i] = display.newImage("images/assets/v2-Back.jpg",i * 200 + padding , 80 )
            end
            
            icons[i].id = i
            icons[i]:addEventListener( "touch", iconListener )
        end
    end
    
    local function insertIntoScrollView()
        for i = 1, #icons do
            scrollView:insert( icons[i] )
        end
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
                    width = display.contentWidth,
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
            generateIcons();
            insertIntoScrollView();
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