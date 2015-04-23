require "CiderDebugger";local composer = require "composer"


-- can comment this out to get predicable values for testing
math.randomseed(os.time()) -- seed the RNG

composer.gotoScene("screens.MainMenu")