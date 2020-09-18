require("simpleAS")

local turtleId = "turtle_5"
local chestList = stoarr:new("chestList", 5) -- chest,slot,itemid,itemdamage,itemcount might have to regen every time
local nameLookup = stoarr:load("nameLookup") -- itemid..itemdamage,name

-- TODO: change slot referencing to slotID instead of chest, chestId, slot
-- TODO: add defrag
-- TODO: add get num empty slots
-- might be cool to have an invintory map printout
-- TODO: design gui
-- TODO: make printout for item types stored, count would be cool too
-- TODO: add BIGdump
-- might want to have a function to make the turtle suck and dump from an invintory in front of it or something

function getChests()
    local perips = peripheral.getNames()
    local chests = {}
    
    for _, perip in ipairs(perips) do
        if perip:match("minecraft:chest") then
            chest = peripheral.wrap(perip)
			
			local chestId = perip:sub(17)
			
            chests[chestId] = chest

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

function dumpItems()
	for turtleSlot = 1, 16 do
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
 
function getEmptySlot() -- TODO: switch to array instead of chest
	for chestId, chest in pairs(getChests()) do
		local slotList = chest.list()
		
		for slot = 1, 27 do
			if slotList[slot] == nil then
                return chest, chestId, slot
            end
        end
    end
end

function findItem(name) -- TODO: switch to array instead of chest maybe return all indexes instead of just one
    for chestId, chest in pairs(getChests()) do
        for slot, item in pairs(chest.list()) do
			if chest.getItemMeta(slot)["displayName"] == name then
                return chest, chestId, slot
            end
        end
    end
end
 
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