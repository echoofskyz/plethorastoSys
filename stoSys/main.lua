require("funcs")

repeat
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
until false