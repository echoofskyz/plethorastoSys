require("funcs")

local chest = peripheral.wrap("minecraft:chest_0")
local t1 = os.epoch()
chest.pullItems("turtle_0", 1)
local t2 = os.epoch()
print(t2 - t1)


--########################
--chest.pullItems() 3600
--turtle.dropUp(): 0
--turtle.getItemDetail(): 0 
--chest.getItemMeta(): 3600


--########################
-- timing for find empty
-- 295200
-- using chest.size() 399599 so only use fixed slot invintories
-- using chest.list once 10800, Fucking Hell
-- using chest.list once per chest and chest.size once per chest 21600, dynamic sizing may not be evil
-- not sure why chest.list once per chest doesnt use noticible time, may be that it doesnt care about ticks
-- might do this solely on memory and not checking chests
-- should mark full chests so they can be skipped, 
-- could say not to check slots for empty if #chest.list() == chest.size but would probably only decrease speed
-- should work faster with defrag chests, might want to think about how i want to sort chests
-- 		but find would be slower
-- hopper system could sort itself and i wouldnt have to worry about what chests would be 
--		empty and what chests would be full, could probably dump to hoppers

--#############################
-- timing for find item
--3600 for list
--97200 for shit old find in chest
--18000 for skip empty
--10800 for getItemMeta
--setup lookup table for displaynames vs id and damage
--eventually do findItems on a stored list
-- on larger network should have to specify stack limit as it would be much faster to stop early
--		unless chests are filtered and i search only filtered chests


--maybe use introspection module on turtle and use getInventory()
-- chest.size() is a thing
-- try pushItems() with a list if this works, then items of same type should be grouped