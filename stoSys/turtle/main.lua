-- can only have the one turtle on the network
-- might have to have a seperate project for the gui
-- crazy idea: could i place/destroy shulker boxes and use them for long term storage?

-- TODO: add defrag
-- TODO: add get num empty slots
-- TODO: make printout for item types stored, count would be cool too
-- TODO: add BIGdump? should probably dump turtle inventory on turtle_inventory event
-- might want to have a function to make the turtle suck and dump from an invintory in front of it or something

-- going to be used to create a list for cc.completion.choice()
--		to autocomplete item names when typing them in

require("networkFuncs")
require("storageFuncs")

function dumpItems()
	for turtleSlot = 1, 16 do
		storeItemTurtle(turtleSlot)
	end
	
	sendData(2, recieveFrequency)
end

-- retrieves all item from storage with the display name (request)
-- TODO: make it only take a specific amount of items instead of just getting a stack
function retrieveItems(request)
	dumpItems()
	
	for turtleSlot = 1, 16 do
		if turtleSlot == nil then
			getItemsTurtleDN(request, 64)
		end
	end
end



parallel.waitForAny(
	function()
		while true do
			print("Enter command or e to exit")
			
			local inp = read()
			
			if inp == "e" then
				break
			end
			
			if inp == "dump" then
				dumpItems()
			end
			
			if inp:match("get ") then
				retrieveItems(inp:sub(5))
			end
		end
	end,
	getWirelessMessage
	)