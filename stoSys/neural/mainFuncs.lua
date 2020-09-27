local requestFrequency = 1
local recieveFrequency = 2

local modules = peripheral.wrap("back")
local modem = peripheral.wrap("left")
local mainCan = modules.canvas()

-- will be set in getWirelessMessage
local storedItems
local playerInv
local playerEnd

local w, h = mainCan.getSize()

mainCan.clear()

modem.open(2)

local function getItem(itemName, itemDamage)
	modem.transmit(requestFrequency, recieveFrequency, "get return {'"..itemName.."', "..itemDamage.."}")
end

local function wGetStored(itemName, itemDamage)
	modem.transmit(requestFrequency, recieveFrequency, "getlist")
end

wGetStored()

function wirelessMessage()
	while true do
		local event, side, frequency, replyFrequency, message, distance = os.pullEvent("modem_message")
		
		local msgType = message:sub(1, 3)
		message = message:sub(5)

		if msgType == "sto" then
			storedItems = loadstring(message)()
		elseif msgType == "inv" then
			playerInv = loadstring(message)()
		elseif msgType == "end" then
			playerEnd = loadstring(message)()
		end
		
		os.queueEvent("loaded_stored")
	end
end

-- this adds a checkerboard pattern to show coords sort of
---[[
for x = 0, math.floor(w / 20) - 1 do
	for y = 0, math.floor(h / 10) - 1 do
		if y % 2 == 0 then
			mainCan.addRectangle(x * 20, y * 10, 10, 10, 0x44444433)
		else
			mainCan.addRectangle(x * 20 + 10, y * 10, 10, 10, 0x44444433)
		end
	end
end--]]

-- definantly want to have a menu for the gui, maybe just have an icon to open it always on the screen
-- like neural interface over an ender chest over in a corner
function stoSys()
	-- wrapped in two infinant loops so i can do nice things
	--		like break the inner loop while still having things work
	while true do
		while true do
			local can = mainCan.addGroup({0, 10})
			
			local icon = {}
			icon[1] = can.addItem({0, 2}, "minecraft:ender_chest")
			icon[2] = can.addItem({8, 8}, "plethora:neuralconnector", 0, 0.7)
			
			while true do
				local _, button, x, y = os.pullEvent("glasses_click")
				
				-- if the button was pressed then continue past this loop
				if x < 20 and y > 10 and y < 30 then
					break
				end
			end
			
			icon[1].setItem("minecraft:structure_void")
			icon[2].setItem("minecraft:air")
			
			if not storedItems then
				print("Error opening StoSys: items not loaded")
				local loadingText = can.addText({20, 10}, "Items not loaded.", 0xFFFFFFFF, 3)
				
				wGetStored()
				
				sleep(2)
				can:remove()
				break
			end
			
			local function createGuiSlots(x, y, width, height)
				can.addRectangle(x, y, width * 14, height * 14, 0xAAAAAA44)
				
				local guiSlots = {group = {}, item = {}, count = {}, rect = {}, button = {}}
				
				local slot = 1
				for row = 1, height do
					for col = 1, width do
						guiSlots["group"][slot] = can.addGroup({(col - 1) * 14 + x, (row - 1) * 14 + y })
						
						-- want to add some cool animations and shrink the top/bottom items later
						guiSlots["rect"][slot] = guiSlots["group"][slot].addRectangle(2, 2, 10, 10, 0x00000055)
						guiSlots["item"][slot] = guiSlots["group"][slot].addItem({0, 0}, "minecraft:air", 0, 0.9)
						guiSlots["count"][slot] = guiSlots["group"][slot].addText({0, 10}, "", 0xFFFFFFFF, 0.5)
						
						guiSlots["button"][slot] = {
								minX = (col - 1) * 14 + x,
								minY = (row - 1) * 14 + y + 10,
								maxX = (col - 1) * 14 + x + 14,
								maxY = (row - 1) * 14 + y + 14 + 10,
								slot = slot,
								name = nil,
								damage = nil
								}
						
						slot = slot + 1
					end
				end
				
				return guiSlots
			end
			
			local stoSlots = createGuiSlots(32, 24, 32, 8)
			local endSlots = createGuiSlots(46, 150, 9, 3)
			local invSlots = createGuiSlots(200, 150, 9, 4)
			
			function loadSlots(guiSlots, itemList)
				for slot = 1, #guiSlots["group"] do
					guiSlots["item"][slot].setItem("minecraft:air", 0)
					guiSlots["count"][slot].setText("")
					
					local item = itemList[slot]
					if item then
						guiSlots["item"][slot].setItem(item["name"], item["damage"])
						guiSlots["button"][slot]["name"] = item["name"]
						guiSlots["button"][slot]["damage"] = item["damage"]
						
						if item["count"] < 1000 then
							guiSlots["count"][slot].setText(tostring(item["count"]))
						else
							guiSlots["count"][slot].setText("999+")
						end
					end
				end
			end
			
			loadSlots(stoSlots, storedItems)
			loadSlots(endSlots, playerEnd)
			
			local fixedPlayerInv = {}
			for i = 0, 36 do
				if i <= 9 then
					fixedPlayerInv[i + 27] = playerInv[i]
				else
					fixedPlayerInv[i - 9] = playerInv[i]
				end
			end
			
			loadSlots(invSlots, fixedPlayerInv)
			
			local searchOpen = false
			can.addRectangle(206, 8, 100, 10, 0x888888AA) 
			local searchText = can.addText({210, 12}, "Search:", 0xFFFFFFAA, 0.6)
			
			-- listen and react to events
			parallel.waitForAny(
				-- click interaction
				function()
					while true do
						local _, button, x, y = os.pullEvent("glasses_click")
						
						-- if the close button is clicked, close this loop
						--		which will cause the gui to close
						if x < 20 and y > 10 and y < 30 then
							break
						end
						
						--[[ gets the index of guiSlots that the click was in
						-- floor((x|y - offset) / cellwidth|height) + 1 => col|row
						local col = math.floor((x - 32) / 14) + 1
						local row = math.floor((y - 34) / 14) + 1
						local slot = ((row - 1) * 32) + col
						
						if stoSlots["group"][slot] then
							getItem(stoSlots["item"][slot].getItem())
						end--]]
						
						for _, button in ipairs(stoSlots["button"]) do
							if (button["name"] ~= nil
									and button["minX"] < x and button["maxX"] > x
									and button["minY"] < y and button["maxY"] > y) then
								getItem(button["name"], button["damage"])
							end
						end
						
						if 206 < x and x < 306 and 18 < y and y < 28 then
							searchOpen = true
							
							searchText.setColor(0xFFFFFFFF)
							
							if searchText.getText() == "Search:" then
								searchText.setText("")
							end
						elseif searchOpen then
							searchOpen = false
							
							searchText.setColor(0xFFFFFFAA)
						end
					end
				end,
				
				function ()
					while true do
						os.pullEvent("loaded_stored")
						
						loadSlots(stoSlots, storedItems)
						loadSlots(endSlots, playerEnd)
						
						local fixedPlayerInv = {}
						for i = 0, 36 do
							if i <= 9 then
								fixedPlayerInv[i + 27] = playerInv[i]
							else
								fixedPlayerInv[i - 9] = playerInv[i]
							end
						end
			
						loadSlots(invSlots, fixedPlayerInv)
					end
				end,
				
				-- keyboard interaction, will be used in search bar, and for exiting
				function()
					while true do
						local event, chr = os.pullEvent("char")
						
						if searchOpen and #searchText.getText() < 26 then
							searchText.setText(searchText.getText()..chr)
						end
					end
				end,
				
				function()
					while true do
						local event, key = os.pullEvent("key")
						
						-- backspace
						if key == 14 and searchOpen then
							searchText.setText(searchText.getText():sub(1, #searchText.getText() - 1))
						end
						
						-- enter
						if key == 28 and searchOpen then
							searchOpen = false
							searchText.setColor(0xFFFFFFAA)
							
							-- need to figure out how to filter
						end
					end
				end
				)
			
			-- when the parallel breaks ie: the gui closed, this will kill the stuff displayed
			can:remove()
		end
	end
end

-- add background of time display
mainCan.addRectangle(0, 0, 512, 10, 0xAAAAAA44)

-- add text element for time display and give it a shadow
local timeDisplay = mainCan.addText({4, 1}, "test", 0xFFFFFFAA, 1)
timeDisplay.setShadow(true)

function updateTimeDisplay()
	while true do
		-- TIME DISPLAY
		local gameTics = modules.getTime()
		local hour = math.floor(gameTics / 1000)
		local minute = math.floor(gameTics / (50 / 3) % 60)
		
		local gameTime = modules.getDay()..", "..(hour % 12)..":"
		
		if minute < 10 then
			gameTime = gameTime.."0"..minute
		else
			gameTime = gameTime..minute
		end
		
		if hour > 12 then
			gameTime = gameTime.." PM"
		else
			gameTime = gameTime.." AM"
		end
		
		timeDisplay.setText(os.date("%a %b %d %I:%M %p -------- "..gameTime))
		
		sleep(0.2)
	end
end