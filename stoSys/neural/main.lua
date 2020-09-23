-- ok, so to transfer items, a bound introspection module in a module manipulator
--		needs to be on the same wired network as the chests
-- 		it cant just be connected to the turtle, it wont be able to access any inventory if it is

-- i'm going to assume that the canvas is always 512x288
require("mainFuncs")
cc = require("cc.pretty")

parallel.waitForAny(
	wirelessMessage,
	updateTimeDisplay,
	stoSys
	)