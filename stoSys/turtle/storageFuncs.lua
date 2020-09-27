local recieveFrequency = 1
local replyFrequency = 2
local baseDir = "stoSys"

local modem

for _, modemPerip in pairs({peripheral.find("modem")}) do
	if modemPerip.isWireless() then
		modem = modemPerip
		break
	end
end

if not modem then error("No wireless modem found.") end

modem.open(recieveFrequency)

local chests = {}

for _, chest in ipairs({peripheral.find("minecraft:chest")}) do
	chests[peripheral.getName(chest)] = chest
end

print("Found "..#{peripheral.find("minecraft:chest")}.." chests.")

local turtleID

for _, id in pairs(chests[next(chests)].getTransferLocations()) do
	if id:match("turtle") then
		turtleID = id
	end
end

local slots = {}

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

print("Slots loaded.")

function retrieveItemsND(name, damage, count)
	print("ret "..name)
	for slotID, slot in ipairs(slots) do
		if slot["name"] == name and slot["damage"] == damage then
			slot["chest"].pushItems(turtleID, slot["slot"], count)

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

local manipulator = peripheral.getName(peripheral.find("manipulator") or error("Manipulator not found"))

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
-- END SLOTID

-- itemTypes
local itemTypes = {}

function updateItemTypes()
	print("Updating itemTypes.")
	-- TODO: change this to use slotid instead of searching chests
	for slotid, slot in ipairs(slots) do
		if slot["name"] ~= nil then
			local inList = false
			
			for _, itemType in ipairs(itemTypes) do
				if slot["name"] == itemType["name"] and slot["damage"] == itemType["damage"] then 
					inList = true
					break
				end
			end
			
			if not inList then
				local itemMeta = slot["chest"].getItem(slot["slot"]).getMetadata()

				itemTypes[#itemTypes + 1] = {displayName = itemMeta["displayName"], name = itemMeta["name"], damage = itemMeta["damage"], maxCount = itemMeta["maxCount"]}
			end
		end
	end
	
	local file = io.open("./"..baseDir.."/itemTypes", "w+")
	
	file:write("return "..textutils.serialize(itemTypes))	
	file:close()
end

-- TODO: see if i can get this to work with relative pathing
local file = io.open("./"..baseDir.."/itemTypes", "r")

if file == nil then
	updateItemTypes()
else
	local fileContent = file:read()
	file:close()
	
	itemTypes = loadstring(fileContent)()
end


function getDisplayName(name, damage)
	for _, itemType in pairs(itemTypes) do
		if itemID["name"] == name and itemID ["damage"] == damage then
			return itemType["displayName"]
		end
	end
end

function getItemID(displayName)
	for _, itemType in pairs(itemTypes) do
		if  itemType["displayName"] == displayName then
			return itemType
		end
	end
end

function getMaxStack(name, damage)
	for _, itemType in pairs(itemTypes) do
		if itemID["name"] == name and itemID ["damage"] == damage then
			return itemType["maxCount"]
		end
	end
end

function storeItemTurtle(turtleSlot)
	local item = turtle.getItemDetail(turtleSlot)
	
	if item ~= nil and item["nbtHash"] == nil then
		local maxCount = turtle.getItemSpace(turtleSlot) + item["count"]
		local count = item["count"]
		
		for slotID, slot in ipairs(slots) do			
			if count > 0 then
				if (slot["name"] == item["name"] 
						and slot["damage"] == item["damage"] 
						and maxCount > slot["count"]) then
					count = count - slot["chest"].pullItems(turtleID, turtleSlot, 64, slot["slot"])
				end
			else 
				break
			end
		end
		
		if count < 0 then
			error("descrepecny, negative item count when transfering items")
		end
		
		if count > 0 then
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
end

-- maybe combine this with itemTypes?
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

function sendData()
	while true do
		local message = "sto ".."return "..textutils.serialize(getStoredItems())
		modem.transmit(replyFrequency, recieveFrequency, message)

		message = "end ".."return "..textutils.serialize(peripheral.wrap(manipulator).getEnder().list())
		modem.transmit(replyFrequency, recieveFrequency, message)
		
		message = "inv ".."return "..textutils.serialize(peripheral.wrap(manipulator).getInventory().list())
		modem.transmit(replyFrequency, recieveFrequency, message)
		
		sleep(0.05)
	end
end