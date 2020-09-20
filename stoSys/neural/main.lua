-- could potentially have a crafting table in the gui, but i think i might have to do the crafting on a turtle

-- ok, so to transfer items, a bound introspection module in a module manipulator
--		needs to be on the same wired network as the chests
-- 		it cant just be connected to the turtle, it wont be able to access any inventory if it is

-- i'm going to assume that the canvas is always 512x288

-- might setup a hotkey to use a kinetic module to stick a keyboard in my hand and click when i press it 

-- might be cool to have an invintory map printout

-- TODO: queue event for global action, like exit menu or something

--

cc = require("cc.pretty")

local requestFrequency = 1
local recieveFrequency = 2

local modules = peripheral.wrap("back")
local modem = peripheral.wrap("left")
local mainCan = modules.canvas()

-- will be set in getWirelessMessage
local storedItems

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

-- going to have to think about what to do for network protocall
--		turtle should send a table of all items every time it reboots
--		probably going to resend list every time the inventory system updates
--		if thats a probblem will have to set up some sort of protocall for sending table updates
--		probably would need to setup slotid/ slot indexing system first
--			the glasses wouldnt even need to deal with chests directly, just ask for 
--			a list of all items and ammounts or make the list (items and amouunts, no chests or slots) on turtle
--			should only have to ask for item, lets have the glasses ask for itemid, damage and not displayname
-- display will probably be item icons with ammounts in an array, will have to make this searchable
--		should make this scrollable, it would be cool to have inventory, enderchest, and a 3x3 crafting grid in the gui
-- also want gui to show gametime/realtime if possible
-- and waypoints would be really cool
-- gui will probably be split off at some point
function getWirelessMessage()
	while true do
		local event, side, frequency, replyFrequency, message, distance = os.pullEvent("modem_message")
		
		-- not at all secure if on multiplayer someone could feasibly wreck your shit
		--		like modem.transmit(2, 1, "shell.run('rm *')")
		--		is this even command injection? this is just running things...
		--		much worse if you have kinetic modules on, then they can do more than just wrek your invin
		--		or if you had a laser...
		--		you can only ctrl-q your neural interface off if it goes bad... if you even notice...
		--		if neural interfaces have curse of binding, dont wear them
		-- with baubles can you wear two neural interfaces? how would that work with the connector?
		
		-- figure out how to update the gui on change, i guess i could listen for epoch change constantly
		--		probaly should setup a whole new parallel function to update gui on recieve message
		-- 		then i dont have to re request everywhere
		-- 		just listen for changes which are handled on the turtle
		-- should i use event queing instead?
		storedItems = loadstring(message)()
		
		os.queueEvent("loaded_stored")
	end
end

-- this adds a checkerboard pattern to show coords sort of
--[[
for x = 0, math.floor(w / 20) - 1 do
	for y = 0, math.floor(h / 10) - 1 do
		if y % 2 == 0 then
			mainCan.addRectangle(x * 20, y * 10, 10, 10, 0x44444433)
		else
			mainCan.addRectangle(x * 20 + 10, y * 10, 10, 10, 0x44444433)
		end
	end
end--]]

-- only should use at most the top 10 pix
--		 might add os.date()
local function updateInfoDisplay()
	mainCan.addRectangle(0, 0, 512, 10, 0xAAAAAA44)
	
	local timeDispl = mainCan.addText({4, 1}, "test", 0xFFFFFFAA, 1)
	timeDispl.setShadow(true)
	
	
	while true do
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
		
		timeDispl.setText(gameTime)
		
		sleep(0.2)
	end
end

-- definantly want to have a menu for the gui, maybe just have an icon to open it always on the screen
-- like neural interface over an ender chest over in a corner
function openStoSys()
	while true do
		-- wait for the glasses to get clicked
		--		should make this a button
		local _, button, x, y = os.pullEvent("glasses_click")
		
		-- if storedItems isnt loaded, wait for it to be loaded
		--		might add a loading animation
		if not storedItems then
			wGetStored()
			
			os.pullEvent("loaded_stored")
		end
		
		-- initialize things for this new open gui
		local can = mainCan.addGroup({0, 10})
		local guiSlots = {group = {}, item = {}, count = {}}
		
		local slot = 1
		
		for row = 1, 8 do
			for col = 1, 32 do
				guiSlots["group"][slot] = can.addGroup({col * 14 + 18, row * 14 + 10 })
				
				-- want to add some cool animations and shrink the top/bottom items later
				guiSlots["item"][slot] = guiSlots["group"][slot].addItem({0, 0}, "minecraft:structure_void", 0, 0.9)
				guiSlots["count"][slot] = guiSlots["group"][slot].addText({0, 10}, "", 0xFFFFFFFF, 0.5)
				
				slot = slot + 1
			end
		end
		
		function loadStoSys()
			-- get the first key, value pair in storedItems
			--		will be used to step through storedItems
			local storedKey, storedItem = next(storedItems)
		
			for slot = 1, #guiSlots["group"] do
				guiSlots["item"][slot].setItem("minecraft:structure_void", 0)
				guiSlots["count"][slot].setText("")

				if storedItem then
					guiSlots["item"][slot].setItem(storedItem["name"], storedItem["damage"])
					
					if storedItem["count"] < 1000 then
						guiSlots["count"][slot].setText(tostring(storedItem["count"]))
					else
						guiSlots["count"][slot].setText("999+")
					end
					
					storedKey, storedItem = next(storedItems, storedKey)
				end
			end
		end
		
		loadStoSys()
		
		-- initialize state variables
		local searchOpen = false
		local searchQuery = ""
		
		-- listen and react to events
		parallel.waitForAny(
			-- click interaction
			function()
				while true do
					local _, button, x, y = os.pullEvent("glasses_click")
					
					-- gets the index of guiSlots that the click was in
					-- floor((x|y - offset) / cellwidth|height) + 1 => col|row
					local col = math.floor((x - 32) / 14) + 1
					local row = math.floor((y - 34) / 14) + 1
					local slot = ((row - 1) * 32) + col
					
					if guiSlots["group"][slot] then
						getItem(guiSlots["item"][slot].getItem())
					end
				end
			end,
			
			function ()
				while true do
					os.pullEvent("loaded_stored")
					
					loadStoSys()
				end
			end,
			
			-- keyboard interaction, will be used in search bar, and for exiting
			function()
				while true do
					local event, chr = os.pullEvent("char")
					
					if chr == "e" then
						break
					end
				end
			end
			)
		
		-- when the parallel breaks, this will close the gui
		can:remove()
	end
end

parallel.waitForAny(
	getWirelessMessage,
	updateInfoDisplay,
	openStoSys
	)