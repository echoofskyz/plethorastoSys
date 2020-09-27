require("mainFuncs")

-- start functions that handle events
parallel.waitForAny(
	terminalInput,
	wirelessMessage,
	sendData
	)