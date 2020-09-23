-- for updating stoSys and running it
-- might be a good idea to have this ask for settings
-- 		like which side a peripheral is on and
--		edit the fields of the program to use them

local address = "http://localhost:8000/"
local baseDir = "stoSys"

-- open new shell so theres a user usable terminal
shell.run("bg")
shell.run("bg lua")

-- loop waiting for R keypress to redownload and run code
while true do
	print("Press R to test, or S to update this program.")
	local event, key = os.pullEvent( "key" )
	
	-- tests
	if key == keys.r then
		local isNeural = false
		-- determine if the computer is a neural interface with glasses
		-- i want to install different things if it is
		--		checks if the glasses's canvas exists
		local modules = peripheral.wrap("back")
		
		if modules and modules.hasModule("plethora:glasses") then
			isNeural = true

			-- gets the fileNames file that has all of the files to download
			shell.run("wget "..address.."neuralFiles tmp")
		else
			-- gets the fileNames file that has all of the files to download
			shell.run("wget "..address.."turtleFiles tmp")
		end
		
		-- deletes the old folder
		shell.run("rm "..baseDir)

		-- makes a new folder
		shell.run("mkdir "..baseDir)
		
		for line in io.lines("tmp") do
			if isNeural then
				shell.run("wget "..address..baseDir.."/neural/"..line.." ./"..baseDir.."/"..line)
			else
				shell.run("wget "..address..baseDir.."/turtle/"..line.." ./"..baseDir.."/"..line)
			end
		end

		shell.run("rm tmp")
		
		shell.run("bg ./"..baseDir.."/main")
		
		sleep(0.5)
		term.clear()
		term.setCursorPos(1, 1)
	end
	
	-- updates this file
	if key == keys.s then 
		shell.run("rm startup.lua")
		shell.run("wget http://localhost:8000/startup.lua")
		shell.run("reboot")
	end
end
