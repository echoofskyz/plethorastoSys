local address = "http://localhost:8000/"
local baseDir = "stoSys"

-- open new shell so theres a user usable terminal
shell.run("bg")

-- loop waiting for R keypress to redownload and run code
print( "Press R to test, or S to update this program." )	
repeat
	local event, key = os.pullEvent( "key" )
	
	-- retests
	if key == keys.r then
		-- gets the fileNames file that has all of the files to download
		shell.run("wget "..address.."fileNames tmp")
		
		-- deletes the old folder
		shell.run("rm "..baseDir)

		-- makes a new folder
		shell.run("mkdir "..baseDir)
		for line in io.lines("tmp") do
			shell.run("wget "..address..baseDir.."/"..line.." ./"..baseDir.."/"..line)
		end

		shell.run("rm tmp")
		--shell.run("bg ./"..baseDir.."/main")
		
		sleep(.5)
		term.clear()
		term.setCursorPos(1, 1)
		print( "Press R to test, or S to update this program." )
	end
	
	-- updates this file
	if key == keys.s then 
		shell.run("rm startup.lua")
		shell.run("wget http://localhost:8000/startup.lua")
		shell.run("reboot")
	end
until false