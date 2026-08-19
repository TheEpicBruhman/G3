--[[
    lib (ModuleScript)
    Path: ReplicatedFirst → G3 → Base
    Parent: Base
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]



--Get Service

const SharedTableRegistry = game:GetService("SharedTableRegistry")

--Get Module data

local T = require(script.Parent.types)


--Main code

local lib = {}
	
	--Checks if the value exists
	lib.exists = function(value: any)
		return value ~= nil
	end
	
	lib.config = require(script.Parent.Parent["G3 Config"])
	
	--Sets the bounds for the config
	local configBounds = {}
		configBounds.scalingFactor = {type = "number", clamp = {min = 0.01, max = 10}}
		configBounds.relativeScaling = {type = "boolean"}
		configBounds.relativeScalingUsesScreenSafeSpace = {type = "boolean"}
		configBounds.lockTo16by9 = {type = "boolean"}
		
		configBounds.occlusion = {type = "boolean"}
		configBounds.occlusionSpeedDial = {type = "number", integer = true, clamp = {min = 1, max = 4}}
		configBounds.occlusionParams = {type = "OverlapParams"}
		configBounds.occlusionON = {type = "function"}
		configBounds.occlusionOFF = {type = "function"}
		
		configBounds.minZoom = {type = "boolean"}
		
		configBounds.occlusionActors = {type = "number", clamp = {min = 1, max = 100}, integer = true}	
	
	
	
	--Verify config is correct
	for index, config in pairs(lib.config) do
		local bounds = configBounds[index]
		
		--Checks for a type bounds
		if lib.exists(bounds.type) then
			if typeof(config) ~= bounds.type then
				error("Config " .. index .. " is not a " .. typeof(config))
			end
		end
		
		--Checks for an integer bounds
		if bounds.integer == true then
			if math.floor(config) ~= config then
				error("Config " .. index .. " is not an integer")
			end
		end
		
		--Checks for a mod bounds
		if lib.exists(bounds.mod) then
			if config % bounds.mod ~= 0 then
				error("Config " .. index .. " is not a multiple of " .. bounds.mod)
			end
		end
		
		--Checks for a clamp bounds
		if lib.exists(bounds.clamp) then
			if config < bounds.clamp.min or config > bounds.clamp.max then
				error("Config " .. index .. " is out of bounds")
			end
		end
		
		--Checks for a blacklist
		if lib.exists(bounds.no) then
			if table.find(bounds.no, config) then
				error("Config " .. index .. " is not allowed")
			end
		end
		
		--Checks for a whitelist
		if lib.exists(bounds.yes) then
			if not table.find(bounds.yes, config) then
				error("Config " .. index .. " is not allowed")
			end
		end
	end
	
	--Events for G3
	--[[ New Parts ]]
	--These dont send the new g3 instance, as g3 instances are cyclic tables (Due to Parent and Child properties)
	lib.newG3Gui = Instance.new("BindableEvent")
	lib.newG3Part = Instance.new("BindableEvent")	
	
	
	--This is inefficient but really useful for important tables
	_G.G3 = {}
	
	--Stores all object data nested equally
	_G.G3.Objects = {} :: T.array
	
	--Stores all part data flattened into one big array
	_G.G3.allParts = {} :: T.array
	
	--Stores all g3Gui 
	_G.G3.allG3Gui = {} :: T.array
	
	--Stores data for the positioning script
	_G.G3.pointLookup = {} :: T.pointLookup
	_G.G3.parentPointLookup = {} :: T.parentPointLookup
	
	--Stores nested tables containing all the actors for each parallel script
	_G.G3.actors = {} :: T.dict


	-- [[ Basic functions ]]
	
	

	--Returns true if the value is a dictionary, false if array
	--Returns nil if not a table
	lib.tableType = function(value: any)
		if lib.isTable(value) then
			--the length operation errors under string keys, which will be the difference
			local returnValue
			for key, _ in pairs(value) do
				if type(key) == "string" then
					returnValue = "dictionary"
					break
				end
			end
			if returnValue == nil then
				return "array"
			end
			
			return returnValue
		end
		return nil
	end
	
	lib.isTable = function (value: any)
		return typeof(value) == "table"
	end
	
	--Bespoke function for deep cloning
	local function tableCloneWithSubtableSeperation(Table)
		local returnValue = {}
		local tables = {}
		for key, value in pairs(Table) do
			--Seperates the subtables from the main return value
			if type(value) == "table" then
				tables[key] = value
			else
				returnValue[key] = value
			end
		end
		return returnValue, tables
	end

	
	local function deepClone(original, tableMemory)
		--Custom cloning function that also pulls out subtables in a different table
		local returnValue, subtables = tableCloneWithSubtableSeperation(original) 


		-- Loop through the original table to check for table values
		-- If a table is found as a value, deep clone it to the key (index)
		for key, value in pairs(subtables) do
			--If it is a table already in the table memory, then its a cyclic table thus dont clone it but reference it
			if tableMemory[value] ~= nil then
				returnValue[key] = tableMemory[value]
			else
				--Add to the memory as the old table as an index, and the cloned table as the value
				tableMemory[value] = table.clone(value)

				--Keep searching through the table to clone it
				returnValue[key] = lib.deepClone(value, tableMemory)
			end
		end

		--Return the finished table
		return returnValue
	end
	
	--Custom made table cloner that can handle cyclic references
	lib.deepClone = function(Table: T.table)
		--This kind of wraps the cloning function so that it automatically passes the second variable as empty
		--Otherwise, you would have to define a second parameter up there as {} (empty table memory), which is clunky
		return deepClone(Table, {})
	end

	
	--Mainly used for the deep table search
	--Returns true if the value is a table and contains values inside it
	@native
	@checked
	function lib.isFilledTable (value: any)
		
		--Checks if it is a table, and that it is not an empty table
		return value ~= {} and typeof(value) == "table"
	end
	

	
	lib.isG3Part = function(input: any)
		--All g3 parts must have a type	
		return lib.Type ~= nil
	end
	
	--Sets the name of all instances of the given table
	lib.setName = function(Table: T.table, input: string)

		--Iterates through all the top-level values of the tabke
		for index, instance: Instance in pairs(Table) do
			--Makes sure to not trip up internal values
			if instance ~= "__internal" and typeof(instance) ~= "function" then
				--Core instances just get the name itself
				if index == "Part" or index == "Model" then
					instance.Name = input
					continue 
				end
				
				--Makes sure that setting the name multiple times doesnt make the parents name appear multiple times
				local name = instance.Name:gsub(".+'s (.+)", "%1")
				instance.Name = input .. "'s " .. name
			end
		end

		--update the value in the table
		rawset(Table.__internal, "Name", input)
	end
	
	--Sets the parent of all instances of the given table
	lib.setParent = function(g3Any: T.g3Any, parent: T.g3Gui | Folder)
		
		
		--If it is a part, then move out old spatial data to new location and delete old data
		if g3Any.Part ~= nil then
			
			--Move the pre-existing data to the new parent
			_G.G3.pointLookup[parent.Model][g3Any.Part] = _G.G3.pointLookup[g3Any.Parent.Model][g3Any.Part]
			
			--Clear the old data
			_G.G3.pointLookup[g3Any.Parent.Model][g3Any.Part] = nil
			
			--Update the parent
			g3Any.Part.Parent = parent.Model
		else
			--No points needed to be moved
			--If its moving to the top level, make sure it has special handling to not error
			if parent == lib.main then
				g3Any.Model.Parent = lib.main
			else
				g3Any.Model.Parent = parent.Model
			end
			
			if parent ~= lib.main then
				--Add it to the parent's children tracker
				rawset(parent.__internal.Children, #parent.__internal.Children + 1, g3Any)
			end
		end
	
		

		--update the value in the table
		rawset(g3Any.__internal, "Parent", parent)
		
		
		
		--If it was in the top-level table, remove it
		local index = table.find(_G.G3.Objects, g3Any)
		
		if index ~= nil then 
			table.remove(_G.G3.Objects, index)
		end
	end
	
	--Destroys the g3Gui
	lib.destroy = function(g3Any: T.g3Any)
		local pointLookup = _G.G3.pointLookup
		
		--If it is a part, then remove from parent's spatial data
		if g3Any.Part ~= nil then

			--Gets rid of the part's spatial data if it exists
			if pointLookup[g3Any.Parent.Model] ~= nil then
				pointLookup[g3Any.Parent.Model][g3Any.Part] = nil
			end
			
			--Clear the data from the global part tracker
			local allParts = _G.G3.allParts
			table.remove(allParts, table.find(allParts, g3Any))
			
			--Clear the data from the parent's part tracker
			table.remove(g3Any.Parent.Parts, table.find(g3Any.Parent.Parts, g3Any))
		else
			--Gets rid of all of the spatial data under that parent
			pointLookup[g3Any.Model] = nil
			
			--Clear the data from the global object tracker
			local allG3Gui = _G.G3.allG3Gui
			table.remove(allG3Gui, table.find(allG3Gui, g3Any))
			
			--Only removes it from the top level object table if it is in the top-level table
			local objectIndex = table.find(_G.G3.Objects, g3Any)
			if objectIndex ~= nil then 
				table.remove(_G.G3.Objects, objectIndex)
			end
			
			--Clear the data from the parent's part tracker if it is not a top-level part
			if g3Any.Parent ~= lib.main then
				table.remove(g3Any.Parent.Children, table.find(g3Any.Parent.Children, g3Any))
			end
			
			--Recursively destroys all parts / children if it is a g3Gui
			for index, child in pairs(g3Any.Parts) do
				lib.destroy(child)
			end

			for index, child in pairs(g3Any.Children) do
				lib.destroy(child)
			end
		end
		
		--Checks if the instance exists, if so then destroy it
		for index, instance in pairs(g3Any) do
			if index ~= "__internal" and typeof(instance) ~= "function" then
				g3Any[index]:Destroy()
			end
		end
		
		
		
		--Destroy the table when finished
		g3Any = nil
		
		
		return
	end
	

	

	--Ensure that the given config is valid within bounds

	--get camera (parent of main folder)
	local cam: Camera = workspace.CurrentCamera

	


	--create base folders for all data (importantly global vars so they dont get duplicated if this module is required twice)
	--check if g3 data exists in either guis or workspace
	local StarterGui = game:GetService("StarterGui")
	local main: Folder = cam:FindFirstChild("G3 Data")



	--folder for all created parts (global variable)
	if main == nil then 
		main = Instance.new("Folder", cam)
			main.Name = "G3 Data"
	else
		main = cam["G3 Data"]
	end

	

	--useful parents for new objects
	lib.cam = workspace.CurrentCamera
	
	--main folder for g3 stuff
	lib.main = main

	-- [[ run, a nice library to make control flow less infuriating ]] --

	--index run as a table
	lib.run = {}
	local run = lib.run
	
	--Run a function only once
	run.once = function(key: string, callback: () -> ())
		--if the key is not true, aka code hasnt run, then run the callback and index the key
		if run.data[key] ~= true then
			
			run.data[key] = true
			
			callback()
		end
	end

	--stores data of running stuff
	run.data = {}
		--nil = not indexed / reset
		--number = times ran
		--true = stopped running
	
	
	--Reset an already ran function so it can run again
	run.reset = function (key:string)
		--nil keeps the table small and reduces mem use to only ones needed
		run.once.data[key] = nil
	end
	
	--Run a function only a limited amount of times (x times)
	run.x = function (key: string, max: number, callback: () -> ())
		--if the key is nil, index it  so it exists in the table
		if run.data[key] == nil then
			run.data[key] = 0
		end
		
		
		--if the key is below the max, increment by one. Else, set the value to true
		if run.data[key] < max then
			run.data[key] += 1
			
			--run callback
			callback()
		else
			run.data[key] = true
		end
		
	end
	
	--Returns true if the function has capped out, returns false otherwise
	run.isStillRunning = function (key: string)
		if run.data[key] == true then
			return false
		else
			return true
		end
	end
	
	--Run a function every x seconds for a certain amount of repetitions
	--If max is 0 or below, then it will run until reset
	run.timed = function (key: string, max: number, Time:number, callback: () -> ())
		--Works like a buffed up task.delay
		
		--infinite timed loop
		if(max <= 0) then
			while run.data[key] ~= true do
				callback()
				task.wait(Time)
			end
		
		--capped timed loop
		else
			for i = 1, max do
				callback()
				task.wait(Time)
			end
			run.data[key] = true
		end
	end
	
	--Runs every x times it is called (essentially the inverse of run.x)
	run.every = function (key: string, every: number, callback: () -> ())
		--if the key is nil, index it  so it exists in the table
		if run.data[key] == nil then
			run.data[key] = 1
		end


		--if the key is below the modulus, increment by one. Else, callback the function and reset the key
		if run.data[key] < every then
			run.data[key] += 1
		else
			run.data[key] = 1
			
			--run callback
			callback()
		end
	end
	
	--	[[ CLoops - Control Loops ]] --
	
	lib.CLoopData = {} :: T.array
	
	@native
	--Special for loop that can use special control functions like skip or detour
	--Control functions must be in the control callback (2nd parameter)
	--Returns true when the CLoop is finished
	function lib.CLoop (cap: number, control: (number?) -> never, callback: (number?) -> any)
		local CLoopID = tostring(control)
		
		--ID the CLoop
		table.insert(lib.CLoopData, CLoopID)
		
		for i = 1, cap do
			local CIndex = table.find(lib.CLoopData, CLoopID)
			control(i)
			
			--Makes sure it hasnt halted
			if lib.CLoopData[CIndex] == 0 then
				break
			end
			
			if table.find(lib.CLoopData, CLoopID) == nil then
				table.insert(lib.CLoopData, CLoopID)
				continue
			end
			callback(i)
		end
		
		--Remove its ID from the cloop data when its finished
		table.remove(lib.CLoopData, table.find(lib.CLoopData, CLoopID))
		
		return true
	end
	
	@native
	--Like a CLoop, but iterates over a dictionary / array
	--Returns true when the CLoop is finished
	function lib.CLoopIterative (Table: T.table, control: (T.key, any?) -> never, callback: (T.key, any?) -> any)
		local CLoopID = tostring(control)
		table.insert(lib.CLoopData, CLoopID)
		for index, child in pairs(Table) do
			local CIndex = table.find(lib.CLoopData, CLoopID)
			control(index, child)
			
			--Makes sure it hasnt halted (0 = halt)
			if lib.CLoopData[CIndex] == 0 then
				break
			end
			--Not sure why, but halting breaks if CIndex is defined after the control function, so this is the way for now
			CIndex = table.find(lib.CLoopData, CLoopID)
			--Removing the CLoop ID from the table is equivalent to skipping the iteration
			if CIndex == nil then
				table.insert(lib.CLoopData, CLoopID)
				continue
			end
			
			callback(index, child)
		end
		--Remove its ID from the cloop data when its finished
		table.remove(lib.CLoopData, table.find(lib.CLoopData, CLoopID))
		return true
	end
	
	
	--Skips the current CLoop iteration if the condition is true
	--Returns a boolean based off of if it has skipped or not
	lib.skip = function (condition: boolean): boolean
		local CLoopID = tostring(debug.info(2, "f"))

		if condition then
			table.remove(lib.CLoopData, table.find(lib.CLoopData, CLoopID))
			return true
		end
		return false
	end
	
	--Detours the current CLoop iteration to a custom callback if the condition is true
	--Skips the current CLoop iteration if the condition is true
	--Returns a boolean based off of if it has triggered or not
	lib.detour = function (condition: boolean, callback: T.callback)
		local CLoopID = tostring(debug.info(2, "f"))

		if condition then
			table.remove(lib.CLoopData, table.find(lib.CLoopData, CLoopID))
			callback()
			return true
		end
		return false
	end
	
	--Piggybacks the current CLoop iteration to call a function if the condition is true
	--This happens before the actual CLoop iteration code is called
	--Returns a boolean based off of if it has triggered
	lib.piggyback = function (condition: boolean, callback: T.callback): boolean
		if condition then
			callback()
			return true
		end
		return false
	end
	
	--Halts the current CLoop if the condition is true
	--Optionally run a function when it halts
	--Returns a boolean based off of if it has halted or not
	lib.halt = function (condition: boolean, callback: T.callback?): boolean
		local CLoopID = tostring(debug.info(2, "f"))

		local CIndex = table.find(lib.CLoopData, CLoopID)

		if condition then
			lib.CLoopData[CIndex] = 0
			callback()
			return true
		end
		return false
	end
	
	
	

		
	--Example CLoops
	--[[
	lib.CLoop(6, 
		function (i)
			lib.skip(i == 3)
		end,
		
		function (i) 
			print("ran " .. i)
		end)
		
	Table = {"a", "b", "c", "d"}
	
	lib.CLoopIterative(Table, 
		function(index, value) 
			--lib.skip(index == "d")
			--lib.detour(index == "c", function () print("hi") end)
			--lib.halt(value == "d")
			--lib.piggyback(value == "c", function () print("piggybacked") end)
			
		end, 
		function(index, value) 
			print(value)
		end)
	]]
	
	-- [[ Property Search functions ]] --
	
	@native
	--Helper function 1 for findAllInstancesOfProperty
	function shallowPropertySearch(Table: T.table, property:string, result: string, ignoredPaths: T.array)
		--This is the end result 
		local returnTables = {}
		local returnKeys = {}
		
		--Only used to save on the costly length operation
		local succeeded = false
		
		--Since there can only be one of any given name per table, there is only one success per search
		local success
		
		for key, value in pairs(Table) do
			
			if not succeeded then 
				--Checks if it is a match
				if key == property then
					--Catch if it caught the property in the first pass through (removes unneccesary periods like "".property)
					if result == "" then
						success = property
					else
						--Whats more common to find
						success = result .. "." .. property
					end
					succeeded = true
					continue
				end
			end
			
			--Checks if the path is not in the ignored path table
			if table.find(ignoredPaths, key) ~= nil then
				continue
			end
			

			--If the check has failed, then it gathers tables and table names to be used if the loop doesn't return
			--Also leaves out empty tables as an optimization
			if lib.isFilledTable(value) then
				
				table.insert(returnTables, value)
				
				--The result is empty on the first iteration
				if result ~= "" then
					table.insert(returnKeys, result .. "." .. key)
				else
					table.insert(returnKeys, key)
				end
			end
		end
		
		--Returns string path if it found a match
		if success ~= nil then
			return returnTables, returnKeys, success
		end
		
		--If it found eligible tables, then return those
		if succeeded == false then
			return returnTables, returnKeys
		end
		
		
		
		--This table is a dead end and you should search for other tables
		return false, nil
	end

	@native
	--Helper function 2 for findAllInstancesOfProperty
	function deepPropertySearch(eligibleTables: T.table, property: string, ignoredPaths: T.array, pathMemory: T.table?, foundValues: T.array?, readIndex: number?, tableLen: number?): T.array	

		--Used for only the first iteration
		--please don't add a pathMemory to the search, it would forget to pack eligibleTables
		if pathMemory == nil then
			
			--Sets default values to be recursed over
			pathMemory = {""}
			foundValues = {}
			readIndex = 1
			tableLen = 0
			
			--Packs the given table into an array of 1 table to search through
			--This is because I am lazy and the shallowPropertySearch is already pretty lean and clean
			eligibleTables = {[1] = eligibleTables}
		end
		
		--The current path that the search is going through
		--It always grabs from the bottom of the "stack"
		local currentPath = pathMemory[readIndex]

		
		--Result of the shallow search
		local returnedValue, paths, success = shallowPropertySearch(eligibleTables[readIndex], property, currentPath, ignoredPaths)
		
		--Increment the readIndex by 1 (essentially the same as removing the table it just searched)
		readIndex += 1
		
		
		
		--If the result yielded tables, then add those to the search
		if typeof(returnedValue) == "table" then
			for i in returnedValue do
				
				--Also adds the path to the table to the path memory so
				--it can remember path names in the middle of the search process
				table.insert(eligibleTables, returnedValue[i])
				table.insert(pathMemory, paths[i])
				
				--Only used to save time on the costly table length operation by just shoving it in here
				tableLen += 1
			end
		end
		

		--If the search yielded success, append the result table to the return table
		if success ~= nil then
			table.insert(foundValues, success)
		end

		local searchFinished = readIndex >= tableLen

		--If it has ran out of tables, and has found values, print those
		if foundValues[1] ~= nil and searchFinished then
			return foundValues
		end

		
		--If it ran out of eligible tables to search, then the property was not found
		if searchFinished then
			return false
		end
		
		--Recurse through the rest of the eligible tables
		return deepPropertySearch(eligibleTables, property, ignoredPaths, pathMemory, foundValues, readIndex, tableLen)
	end
	
	--Runs a deep linear search through a table to find the full path of the property (for nested tables)
	--Suprisingly fast function (roughly 200 ns for a heavy nested table), but don't spam it
	--ignoredPaths is an array of values to skip over during a search
	function lib.findAllInstancesOfProperty (Table: T.table, property: string, ignoredPaths: T.array)

		--Searches through the table for the property
		local returnValue = deepPropertySearch(Table, property, ignoredPaths)
		
		--If it was a success, then return the value
		if typeof(returnValue) == "table" then
			return returnValue
		end
		
		--If it was a failure, return nil
		return nil
	end
	
	

	--[[ Movement Operations ]]--
	
	--Change a part's spatial data by a specific amount (Move)
	lib.velocity = function(g3Any: T.g3Any, point: T.g3Point)
		g3Any.Position = g3Any.Position + point.Position
		g3Any.Offset = g3Any.Offset + point.Offset
		g3Any.Rotation = g3Any.Rotation + point.Rotation
	end
	
	--Changes a g3Gui's spatial data, that also moves all of its children by the same amount
	lib.velocityIterative = function(g3Gui: T.g3Gui, point: T.g3Point)
		lib.velocity(g3Gui, point)
		for _, child in pairs(g3Gui.Children) do
			lib.velocityIterative(child, point)
		end
	end
	
	--"Calculates" the true pivot (center) of the object as a Vector3, even if there is already a preset pivot
	--Also returns the bounding box of the object so you can calculate faces, edges, and corners
	lib.getTruePivot = function (Object: Model | BasePart): (CFrame, Vector3)
		--Get pivot of a model or a part
		if Object:IsA("Model") then
			return Object:GetBoundingBox()
		elseif Object:IsA("BasePart") then
			return Object.CFrame, Object.ExtentsSize
		end
		--I know there are instances other than models and baseparts that have pivots, but g3 only operates on 
		--  parts and models and leaves the rest of the instances alone
		error("Failed to calculate pivot of object")
	end
	
	-- [[ Relative scaling operations ]] --
	
	--Calculates the screen aspect ratio
	lib.getScreenAspectRatio = function(): number
		--Returns a locked 16 / 9 aspect ratio
		if lib.config.lockTo16by9 then
			return 16/9
		else
			--Returns the screen safe aspect ratio (Doesnt work for now, will be fixed in a future update)
			if lib.config.relativeScalingUsesScreenSafeSpace then
				--local screenSafe = script.Parent.ScreenSafeSize
				
				--return screenSafe.AbsoluteSize.X / screenSafe.AbsoluteSize.Y
			end
			
			--Returns the true screen aspect ratio
			local fullScreen = script.Parent.FullScreenSize
			
			return fullScreen.AbsoluteSize.X / fullScreen.AbsoluteSize.Y
		end
	end
	
	--Calculates the size of the screen at any given offset taking into account camera FOV
	lib.getScreenSizeInStuds = function (offset: number): Vector2
		--Gets camera FOV
		local fov = math.rad(lib.cam.FieldOfView)
		
		--Gets the aspect ratio
		local aspectRatio = lib.getScreenAspectRatio()
		
		--Use trig to get the screen Y size
		local screenY = math.tan(fov/2) * offset * 2
		
		--Calculate the screen X size from the aspect ratio
		local screenX = screenY * aspectRatio
		
		--Return the screen size
		return Vector2.new(screenX, screenY)
	end
	
	-- [[ Rotation operations ]] --
	
	--Combine rotation 2 with rotation 1
	lib.combineRotations = function (rotation1: Vector3, rotation2: Vector3): Vector3
		
		--Convert the rotations to cframes
		local rotation1CFrame = CFrame.Angles(math.rad(rotation1.X), math.rad(rotation1.Y), math.rad(rotation1.Z))
		local rotation2CFrame = CFrame.Angles(math.rad(rotation2.X), math.rad(rotation2.Y), math.rad(rotation2.Z))
		
		--Combine the rotations
		local combinedCFrame = rotation1CFrame * rotation2CFrame
		
		--Convert the cframe back to a rotation
		local x, y, z = combinedCFrame:ToEulerAnglesXYZ()
		
		--Return the rotation
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end
	
	--Subtract rotation 2 from rotation 1
	lib.subtractRotations = function (rotation1: Vector3, rotation2: Vector3): Vector3
		--Convert the rotations to cframes
		local rotation1CFrame = CFrame.Angles(math.rad(rotation1.X), math.rad(rotation1.Y), math.rad(rotation1.Z))
		local rotation2CFrame = CFrame.Angles(math.rad(rotation2.X), math.rad(rotation2.Y), math.rad(rotation2.Z))
		
		--Subtract the rotations
		local subtractedCFrame = rotation1CFrame * rotation2CFrame:Inverse()
		
		--Convert the cframe back to a rotation
		local x, y, z = subtractedCFrame:ToEulerAnglesXYZ()
		
		--Return the rotation
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end
	
	--Converts a CFrames rotation to a Vector3 Euler Angles rotation in degrees
	lib.convertToEuler = function (cframe: CFrame): Vector3
		local x, y, z = cframe:ToEulerAnglesXYZ()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end
	
return lib
