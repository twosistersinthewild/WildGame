application = {
	content = {
                -- trying a 3:2 resolution. this fits between 16:9 and 4:3.
                -- todo: 4:3 may have top and bottom cut off so needs testing
		width = 640,
		height = 960, 
		scale = "letterBox",
		fps = 30,
		
		--[[
        imageSuffix = {
		    ["@2x"] = 2,
		}
		--]]
	},

    --[[
    -- Push notifications

    notification =
    {
        iphone =
        {
            types =
            {
                "badge", "sound", "alert", "newsstand"
            }
        }
    }
    --]]    
}
