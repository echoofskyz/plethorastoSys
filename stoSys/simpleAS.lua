-- Eli Cosley (echoofskyz)
-- got annoyed so i made a class for storing tables
-- to a file

-- TODO: make files store in their own directory
-- implement higher dimensional arrays, multiple files?
-- figure out __index so i can have the array be indexed normally
-- add functions for storing or getting an array without constructing the class

--maybe i could do something with load() instead?
-- or just literally store a table declaration in a file?
 
stoarr = {}
stoarr.__index = stoarr

function stoarr:new(fileName, numValues)
	-- enforces that fileName is a string
	if not (type(fileName) == "string") then
		error("stoarr:new() needs a string")
	end
	
	-- sets default parameters
	numValues = numValues or 2
	
	-- creates a file for the stoarr
	local newFile = io.open("./stoSys/"..fileName, "w+")
	print(newFile)
	newFile:close()
	
	local this = {
		fileName = fileName,
		arr = {},
		numValues = numValues
	}
	setmetatable(this, self)
	return this
end

-- loads a array from file
function stoarr:load(fileName, numValues)
	-- enforces that fileName is a string
	if not (type(fileName) == "string") then
		error("stoarr:load() needs a string")
	end

	-- checks if file exists
	local file = io.open("./stoSys/"..fileName, "r")
	if file == nil then
		print("stoarr:load file: "..fileName.." does not exist creating file "..fileName)
		return self:new(fileName, numValues)
	end
	file:close()
	
	-- sets defult value for numValues to 2
	numValues = numValues or 2
	
	-- loads the array from file
	arr = {}
	for line in io.lines("./stoSys/"..fileName) do
		-- array at at new index = a list from the file
		arr[#arr + 1] = {line:match(string.rep("([^,]+),", numValues))}
	end
	
	local this = {
		fileName = fileName,
		arr = arr,
		numValues = numValues
	}
	setmetatable(this, self)
	return this
end

-- requires 1 based indexed array of 1 based indexed arrays
-- deletes previous data
-- now accepts an array for input or a number and a table (index, value)
-- might refactor to better handle input types
-- might refactor to not rewrite the file every time
function stoarr:set(inp0, inp1)
	if type(inp0) == "table" then
		local arr = inp0
		local file = io.open("./stoSys/"..self.fileName, "w+")
		self.arr = {}

		for i = 1, #self.arr do
			for j = 1, #self.arr[i] do
				self.arr[i][j] = arr[i][j]
				file:write(self.arr[line][col]..",")
			end
		end
		
		file:write("\n")
		
		file:close()
		
		return
	end
	
	if type(inp0) == "number" then -- test to see if indexing properly
		local arr = self.arr
		arr[inp0] = value
		
		self:set(arr)
	end
end

-- looks for index of value in array, only searches first column
-- might make 2d indexable instead of just first column
-- should allow matching tables shorter than numValues
-- maybe it should return a list of indexes
function stoarr:indexOf(value, rev)
	if rev == true then
		for line = 1, #self.arr do
			if self.arr[line][self.numValues] == value then
				return line
			end
		end
	else
		if type(value) == table then
			for line = 1, #self.arr do
				if self.arr[line] == value then
					return line
				end
			end
		else
			for line = 1, #self.arr do
				if self.arr[line][1] == value then
					return line
				end
			end
		end
	end
	
	return nil
end

function stoarr:indexesOf(item)
	local indexes = {}
	
	if type(item) == table then
		for line = 1, #self.arr do
			for i, value in ipairs(item) do
				if self.arr[line][i] == item then
					indexes[#indexes + 1] = line
				end
			end
		end
	else
		for line = 1, #self.arr do
			if self.arr[line][1] == item then
				indexes[#indexes + 1] = line
			end
		end
	end
	
	return indexes
end

function stoarr:get(index)
	return self.arr[index]
end

-- value is a table of length numValues
function stoarr:append(value)
	self.arr[#self.arr + 1] = value
	
	local file = io.open("./stoSys/"..self.fileName, "a+")
	
	for i = 1, self.numValues do
		file:write(""..tostring(self.arr[#self.arr][i])..",")
	end
	
	file:write("\n")
	
	file:close()
end	


-- FIXME: figure out why its not working in my testing thing
function stoarr:printArr(slowMode)
	print("Array "..self.fileName..":")
	for line in ipairs(self.arr) do
		for col = 1, self.numValues do
			write(tostring(self.arr[line][col]).." ")
		end
		
		if slowMode then sleep(.5) end
		
		print()
	end
end