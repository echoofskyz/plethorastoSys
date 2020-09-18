require("simpleAS")

local turtleId = "turtle_5" -- TODO: figure out how to get this automatically

-- chestList is a list of all chest slots and what is in them
-- chest,slot,itemid,itemdamage,itemcount
-- might have to regen every time, currently am
-- TODO: rename chestList
local chestList = stoarr:new("chestList", 5)

-- nameLookup is a list of all item types that have been encountered
-- going to be used to create a list for cc.completion.choice()
--		to autocomplete item names when typing them in
-- going to be used to lookup itemid and itemdamage for item given displayname
--		so I can request items with displayname without having to use
--		chest.getItemMeta(), which is slow, on each item in storage
local nameLookup = stoarr:load("nameLookup") -- itemid..itemdamage,name

-- TODO: change slot referencing to slotID instead of chest, chestId, slot
-- TODO: add defrag
-- TODO: add get num empty slots
-- might be cool to have an invintory map printout
-- TODO: design gui
-- TODO: make printout for item types stored, count would be cool too
-- TODO: add BIGdump maybe in main?
-- might want to have a function to make the turtle suck and dump from an invintory in front of it or something

-- reterns a list of chest peripheral table? object? things
function getChests()
	-- get all of the peripherals on the network
    local peripheralNames = peripheral.getNames()
    local chests = {}
    
    for _, peripheralName in ipairs(peripheralNames) do
        if peripheralName:match("minecraft:chest") then
            chest = peripheral.wrap(peripheralName)
			
			local chestId = peripheralName:sub(17)
			
            chests[chestId] = chest

			-- finds if chestList already has this chest otherwise adds it
			if  chestList:indexOf(chestId) == nil then
				local slotList = chest.list()
				
				for slot = 1, 27 do
					if slotList[slot] ~= nil then
						local name = slotList[slot]["name"]
						local damage = slotList[slot]["damage"]
						
						chestList:append({
							chestId,
							slot,
							name,
							damage,
							slotList[slot]["count"]
							})
						
						-- if nameLookup doesnt yet have an entry with this item's name and damage
						--		get the display name of the item and store the name, damage and display name
						if nameLookup:indexOf(name..damage) == nil then
							nameLookup:append({name..damage, chest.getItemMeta(slot)["displayName"]})
						end
					else
						chestList:append({chestId, slot, nil, nil, nil})
					end
				end
			end
		end
    end
    
    return chests
end

-- pulls all of the items out of the turtle's inventory
function dumpItems()
	for turtleSlot = 1, 16 do
		-- turtle.getItemDetail() is a lot faster than geting item info from items in chests
		local item = turtle.getItemDetail(turtleSlot)
		
		if item ~= nil then
			local chest, chestId, slot = getEmptySlot()
			
			local name = item["name"]
			local damage = item["damage"]
			local count = item["count"]
			
			chest.pullItems(turtleId, turtleSlot, 64, slot)
			
			chestList:set(chestList:indexesOf({chestId, slot})[1], {chestId, slot, name, damage, count})
			
			if damage == nil then
				print(name)
			end
			
			if nameLookup:indexOf(name..damage) == nil then
				nameLookup:append({name..damage, chest.getItemMeta(slot)["displayName"]})
			end
		end
	end
end
 
-- returns a chest object, the id of the chest, and an empty slot in the chest
-- TODO: switch to chestList instead of scanning chests
function getEmptySlot() 
	for chestId, chest in pairs(getChests()) do
		local slotList = chest.list()
		
		for slot = 1, 27 do
			if slotList[slot] == nil then
                return chest, chestId, slot
            end
        end
    end
end

-- returns a chest object, the id of the chest, and the slot of an item with display name (name)
-- TODO: switch to array instead of chest maybe return all indexes instead of just one
function findItem(name) 
    for chestId, chest in pairs(getChests()) do
        for slot, item in pairs(chest.list()) do
			if chest.getItemMeta(slot)["displayName"] == name then
                return chest, chestId, slot
            end
        end
    end
end

-- retrieves all item from storage with the display name (request)
function retrieveItems(request)
	for turtleSlot = 1, 16 do
		local chest, chestId, slot = findItem(request)
		
		if chest == nil then
			break
		end
		
		chest.pushItems(turtleId, slot)
		chestList:set(chestList:indexesOf({chestId, slot})[1], {chestId, slot, nil, nil, nil})
	end
end
