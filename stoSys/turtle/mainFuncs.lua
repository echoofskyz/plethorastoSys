require("storageFuncs")

-- handles input from turtle's terminal
function terminalInput()
	while true do
		print("Enter command or e to exit")
		
		local inp = read()
		
		if inp == "e" then
			break
		end
		
		if inp == "dump" then
			for turtleSlot = 1, 16 do
				storeItemTurtle(turtleSlot)
			end
			
			sendData(2)
		end
		
		if inp:match("get ") then
			for turtleSlot = 1, 16 do
				storeItemTurtle(turtleSlot)
			end
			
			sendData(2)
			
			for turtleSlot = 1, 16 do
				if turtle.getItemDetail(turtleSlot) == nil then
					local itemID = getItemID(inp:sub(5)) 
	
					retrieveItemsND(itemID["name"], itemID["damage"], 64)
					break
				end
			end
		end
	end
end

-- handles recieving ender modem messages
function wirelessMessage()
	while true do
		local event, side, frequency, replyFrequency, message, distance = os.pullEvent("modem_message")
		
		if message:match("get ") then
			local item = loadstring(message:sub(5))()

			pullItemsToPlayerND(item[1], item[2], 64)
			
			sendData(replyFrequency)
		end
		
		if message and message:match("get") then
			sendData(replyFrequency)
		end
		
	end
end

function storeageUpdate()
	while true do
		os.pullEvent("storage_update")
		sendData(2)
	end
end