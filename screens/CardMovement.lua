local composer = require( "composer" )
local scene = composer.newScene()

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------
-- local forward references should go here

---------------------------------------------------------------------------------
function scene:doIt ()
    
-- screen orientation should rotate when user rotates phone

-- ** Tasks **
-- bind together in a group and rotate all as one (adjustments need to be made)
-- get objects bound within screen space

-- ** Locking into Place **
-- x threshold, moves onto another card and locks ?


-- create object
local myObject = display.newRect( 300, 430, 75, 75 )
     

-- create second object
local anotherObject = display.newRect(100, 430, 50, 50)
local tapCounter = 0

-- store x pos
local xPos 

-- stores orientation text
local orientation = system.orientation

-- updates with orientation changes
local displayText = display.newText(orientation, 300, 200, font, 50)

-- touch listener function 
function anotherObject:touch( event )
    
    if event.phase == "began" then
        
        print(tapCounter)
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object
                   	
    elseif event.phase == "moved" then
	
        local x = (event.x - event.xStart) + self.markX
        local y = (event.y - event.yStart) + self.markY
        
        self.x, self.y = x, y    -- move object based on calculations above
    end
    
    return true
end

-- tap listener function (generic example)
function myObject:tap( event )
if (event.numTaps >= 2 ) then
print( "The object was double-tapped." )
return true;
elseif (event.numTaps == 1 ) then
print("The object was tapped once.")
end
return true
end

-- tap function with resizing
function anotherObject:tap( event )
    -- checks for double tap event
    if (event.numTaps >= 2 ) then
        -- checks to make sure image isn't already zoomed
        if tapCounter == 0 then
            self.xScale = 10 -- resize is relative to original size
            self.yScale = 10
            xPos = self.x   -- store original position
            self.x = 300    -- center x pos to give max viewable area
            tapCounter = 1 -- sets flag to indicate zoomed image
        else
            self.xScale = 1 -- reset size
            self.yScale = 1
            self.x = xPos  -- reset x pos
            tapCounter = 0 -- reset flag
        end
            print( "The object was double-tapped." )
    end

    --  ** single tap event **
    -- elseif (event.numTaps == 1 ) then
       -- print("The object was tapped once.")
return true
end



function myObject:touch( event )
    if event.phase == "began" then
	
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object
	
    elseif event.phase == "moved" then
	
        local x = (event.x - event.xStart) + self.markX
        local y = (event.y - event.yStart) + self.markY
        
        self.x, self.y = x, y    -- move object based on calculations above
    end
    
    return true
end


local group = display.newGroup()
group:insert( myObject )
group:insert( anotherObject )
group: insert( displayText)

function onRotation( event )
    displayText.text = event.type
    
    -- group.rotation = group.rotation - event.delta
    displayText.rotation = displayText.rotation - event.delta -- displays text - the change which is event.delta
    -- anotherObject.rotation = anotherObject.rotation - event.delta
    -- myObject.rotation = myObject.rotation - event.delta
end

-- make 'myObject' listen for touch events
myObject:addEventListener( "touch", myObject )
myObject:addEventListener( "tap")
anotherObject:addEventListener("touch", anotherObject)
anotherObject:addEventListener( "tap")

Runtime:addEventListener("orientation", onRotation)





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
      scene: doIt()
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