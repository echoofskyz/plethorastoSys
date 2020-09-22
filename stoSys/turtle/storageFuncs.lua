cc = require("cc.pretty")

local recieveFrequency = 1

local modem = peripheral.wrap("right")
modem.open(recieveFrequency)

local baseDir = "stoSys"

local chests = {}
local numChests = 0

-- search through all peripherals for chests
--		might store chests as full id's instead of just the number parts
for _, peripheralName in ipairs(peripheral.getNames()) do
	-- if i want to add other things like shulker boxes i need to make their peripheral id match here
	if peripheralName:match("minecraft:chest") then
		local chest = peripheral.wrap(peripheralName)
		
		local chestID = peripheralName
		
		chests[chestID] = chest
		
		numChests = numChests + 1
	end
end

print("Found "..numChests.." chests.")

local turtleID

-- get the transfer location/id of this turtle
local firstChest = next(chests)

for _, id in ipairs(chests[firstChest].getTransferLocations()) do
	if id:match("turtle") then
		turtleID = id
	end
end


-- SLOTID
local slots = {}

function loadSlots()
	print("Loading Slots.")
	
	for chestID, chest in pairs(chests) do
		local items = chest.list()

		for chestSlot = 1, chest.size() do
			if items[chestSlot] ~= nil then
				slots[#slots + 1] = items[chestSlot]
				slots[#slots]["chest"] = chest
				slots[#slots]["slot"] = chestSlot
				slots[#slots]["chestID"] = chestID
			else
				slots[#slots + 1] = {
					name = nil,
					damage = nil, 
					count = nil, 
					chest = chest, 
					slot = chestSlot,
					chestID = chestID
					}
			end
		end		
	end
	
	os.queueEvent("storage_update")
end

loadSlots()

function pushItemsFromSysND(location, name, damage, count)
	for slotID, slot in ipairs(slots) do
		if slot["name"] == name and slot["damage"] == damage then
			slot["chest"].pushItems(location, slot["slot"], count)

			if slot["count"] > count then
				slot["count"] = slot["count"] - count
				break
			elseif slot["count"] == count then
				slot["count"] = nil
				slot["name"] = nil
				slot["damage"] = nil
				break
			elseif slot["count"] < count then
				count = count - slot["count"]
				
				slot["count"] = nil
				slot["name"] = nil
				slot["damage"] = nil
			end
		end
	end
	
	os.queueEvent("storage_update")
end

local manipulator

for _, peripheralName in pairs(peripheral.getNames()) do
	if peripheralName:match("manipulator") then
		manipulator = peripheralName
		break
	end
end

function pullItemsToPlayerND(name, damage, count)
	local location = peripheral.wrap(manipulator).getInventory()

	for slotID, slot in ipairs(slots) do
		if slot["name"] == name and slot["damage"] == damage then
			location.pullItems(slot["chestID"], slot["slot"], count)
			
			if slot["count"] > count then
				slot["count"] = slot["count"] - count
				break
			elseif slot["count"] == count then
				slot["count"] = nil
				slot["name"] = nil
				slot["damage"] = nil
				break
			elseif slot["count"] < count then
				count = count - slot["count"]
				
				slot["count"] = nil
				slot["name"] = nil
				slot["damage"] = nil
			end
		end
	end
	
	os.queueEvent("storage_update")
end

function storeItemTurtle(turtleSlot)
	local item = turtle.getItemDetail(turtleSlot)
	
	if item ~= nil then
		for slotID, slot in ipairs(slots) do
			if slot["name"] == nil then
				slot["chest"].pullItems(turtleID, turtleSlot, 64, slot["slot"])
				slot["name"] = item["name"]
				slot["damage"] = item["damage"]
				slot["count"] = item["count"]
				break
			end
		end
	end
	
	os.queueEvent("storage_update")
end
-- END SLOTID

-- NAMELOOKUP
local nameLookup = {}

function updateNameLookup()
	print("Updating nameLookup.")
	-- TODO: change this to use slotid instead of searching chests
	for slotid, slot in ipairs(slots) do
		if slot["name"] ~= nil then
			local inList = false
			
			for displayName, itemID in ipairs(nameLookup) do
				if slot["name"] == item["name"] and slot["damage"] == item["damage"] then 
					inList = true
					break
				end
			end
			
			if not inList then
				local itemMeta = slot["chest"].getItemMeta(slot["slot"])

				nameLookup[itemMeta["displayName"]] = {name = itemMeta["name"], damage = itemMeta["damage"]}
			end
		end
	end
	
	--[[for _, chest in pairs(getChests()) do
        for slot, item in pairs(chest.list()) do
			local inList = false
			
			for displayName, itemID in ipairs(nameLookup) do
				if item["name"] == itemID["name"] and item["damage"] == itemID["damage"] then
					inList = true
					break
				end
            end
			
			if not inList then
				local itemMeta = chest.getItemMeta(slot)
				
				nameLookup[itemMeta["displayName"] ] = {name = itemMeta["name"], damage = itemMeta["damage"]}
			end
        end
    end--]]
	
	local file = io.open("./"..baseDir.."/nameLookup", "w+")
	
	file:write("return "..tostring(cc.pretty(nameLookup)))	
	file:close()
end

-- TODO: see if i can get this to work with relative pathing
local file = io.open("./"..baseDir.."/nameLookup", "r")

if file == nil then
	updateNameLookup()
else
	local fileContent = file:read()
	file:close()
	
	nameLookup = loadstring(fileContent)()
end


function getDisplayName(name, damage)
	for displayName, itemID in pairs(nameLookup) do
		if itemID["name"] == name and itemID ["damage"] == damage then
			return displayName
		end
	end
end

-- END NAMELOOKUP

function getItemsTurtleDN(displayName, count)
	local itemID = nameLookup[displayName] 
	
	getItemsND(turtleID, itemID["name"], itemID["damage"], count)
end


-- maybe combine this with nameLookup?
function getStoredItems()
	local storedItems = {}

	for chestID, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
			local inList = false
			
			for stoSlot, stoItem in ipairs(storedItems) do
				if stoItem["name"] == item["name"] and stoItem["damage"] == item["damage"] then
					storedItems[stoSlot]["count"] = storedItems[stoSlot]["count"] + item["count"]
					
					inList = true
					break
				end
            end
			
			if not inList then
				storedItems[#storedItems + 1] = item
			end
        end
    end
	
	return storedItems
end

function sendData(replyFrequency)
	local message = "return "..tostring(cc.pretty(getStoredItems()))
	
	modem.transmit(replyFrequency, recieveFrequency, message)
end

sendData(2)