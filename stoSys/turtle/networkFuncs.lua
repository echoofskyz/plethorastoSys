cc = require("cc.pretty")

require("storageFuncs")

local recieveFrequency = 1

local modem = peripheral.wrap("right")
modem.open(recieveFrequency)


-- move to storageFuncs
local manipulator

for _, peripheralName in pairs(peripheral.getNames()) do
	if peripheralName:match("manipulator") then
		manipulator = peripheralName
		break
	end
end

function getWirelessMessage()
	while true do
		local event, side, frequency, replyFrequency, message, distance = os.pullEvent("modem_message")
		
		if message:match("get ") then
			local item = loadstring(message:sub(5))()

			pullItemsToPlayerND(manipulator, item[1], item[2], 64)
			
			sendData(replyFrequency, frequency)
		end
		
		if message and message:match("get") then
			sendData(replyFrequency, frequency)
		end
		
	end
end

function sendData(replyFrequency, frequency)
	local message = "return "..tostring(cc.pretty(getStoredItems()))
	
	modem.transmit(replyFrequency, frequency, message)
end