--[[
    g3Wrapper (ModuleScript)
    Path: ReplicatedFirst → G3 → New Parts
    Parent: New Parts
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

--get base data
local lib = require("../Base/lib")
local T = require("../Base/types")
local pointLookup: T.pointLookup = _G.G3.pointLookup
local parentPointLookup: T.parentPointLookup = _G.G3.parentPointLookup

local g3Wrapper = {}
	
	--Determines which folders are always protected at all times
	--It is organized like this instead of a list for O(1) lookups (only checking if there is a value at one index)
	local protectedFolders = {}
		protectedFolders.Children = true
		protectedFolders.Parts = true
		protectedFolders.customPropertyData = true
		protectedFolders.readOnly = true
		protectedFolders.__internal = true
	
	local function isAProtectedTable (index: string)
		return protectedFolders[index] ~= nil
	end
	
	
	--Determines which properties are a base part of g3
	--Any properties not in this list have to be set using [name].custom()
	local base = {}
		base.Name = true
		base.Enabled = true
		base.Parent = true
		base.Position = true
		base.Rotation = true
		base.Size = true
		base.Type = true
		base.Thickness = true
		base.Offset = true
		base.RotationCenter = true
		base.Parts = true
		base.Children = true
		base.customPropertyData = true
		base.readOnly = true
		base.__internal = true

		
		
	--Also accounts for newly indexed custom properties
	local function isAValidProperty (Table: T.g3Gui, index: string)
		return base[index] ~= nil or Table.customPropertyData[index] ~= nil
	end
	
	--Handles cloning parts
	local function clonePart(g3Part: T.g3Part)
		--Temporarily disable the metatable
		local metatable = getmetatable(g3Part)
		setmetatable(g3Part, nil)
		
		--Create important values
		local otherObjects = {}
		local mainObject: BasePart
		
		--Clone the main instances and grab its main object along the way
		lib.CLoopIterative(g3Part, 
			function(key, value) 
				--Grab the main part
				lib.detour(key == "Part", function() 
					--Shallow copy of the new part
					mainObject = Instance.fromExisting(value)
					mainObject.Parent = g3Part.Parent
					mainObject.Name = g3Part.__internal.Name
				end)
								
				--Skips over internal data, that will be handled later
				lib.skip(key == "__internal")
				
				--Skips over function objects
				lib.skip(type(value) == "function")
			end, 
			--Grab other binded objects
			function(key, value: Instance)
				--Clones all of its children too
				otherObjects[key] = value:Clone()
			end)

		--Create the binding for the new object
		local returnValue = g3Wrapper.bindPart(mainObject, g3Part.__internal.Parent)

		--Bind the other objects to the top level table
		for index, value in pairs(otherObjects) do
			returnValue:BindPartToTable(value, index)
			
			otherObjects[index].Parent = mainObject
		end

		--Copy the internal data over
		for index, value in pairs(g3Part.__internal) do
			--These are handled seperately
			if index == "readOnly" or index == "customPropertyData" or index == "Parent" then
				continue
			end
			returnValue[index] = value
		end
		
		--Add it in the parents part tracker
		rawset(g3Part.__internal.Parent.__internal.Parts, #g3Part.__internal.Parent.__internal.Parts + 1, returnValue)
		
		--Copy over the readOnly data
		rawset(returnValue.__internal, "readOnly", table.clone(g3Part.__internal.readOnly))
		
		--Deep clone custom property data
		for index, value in pairs(g3Part.__internal.customPropertyData) do
			rawset(returnValue.__internal, "customPropertyData", lib.deepClone(g3Part.__internal.customPropertyData))
		end
		
		--Re-enable the metatable
		setmetatable(g3Part, metatable)
		
		--Return the new object
		return returnValue
	end	

	local function cloneModel(g3Gui: T.g3Gui)
		
		--Temporarily disable the metatable
		local metatable = getmetatable(g3Gui)
		setmetatable(g3Gui, nil)
		
		--Create important values
		local otherObjects = {}
		local mainModel: Model
		
		--Clone the main instances and grab its main object along the way
		lib.CLoopIterative(g3Gui, 
			function(key, value) 
				--Grab the main part
				lib.detour(key == "Model", function() 
					--Shallow copy of the new part
					mainModel = Instance.fromExisting(value)
					mainModel.Parent = g3Gui.Parent
					mainModel.Name = g3Gui.__internal.Name
				end)
								
				--Skips over internal data, that will be handled later
				lib.skip(key == "__internal")
				
				--Skips over function objects
				lib.skip(type(value) == "function")
			end, 
			function(key, value: Instance) 
				--Clones all of its children too
				otherObjects[key] = value:Clone()
			end)
		
		
		--Create the new g3Gui
		local returnValue = g3Wrapper.newGui(g3Gui.__internal.Name)
		
		--Create a container for the g3Gui's child parts
		pointLookup[returnValue.Model] = {}
		
		--Bind the other objects to the top level table
		for index, value in pairs(otherObjects) do
			returnValue:BindPartToTable(value, index)
			value.Parent = returnValue.Model
		end
		
		--Copy the internal data over
		for index, value in pairs(g3Gui.__internal) do
			--These are handled seperately
			if index == "readOnly" or index == "customPropertyData" or index == "Parent" or index == "Children" or index == "Parts" then
				continue
			end

			returnValue[index] = value
		end
		
		--Add it in the parents part tracker if it has a parent
		if g3Gui.__internal.Parent ~= lib.main then
			rawset(g3Gui.__internal.Parent.__internal.Children, #g3Gui.__internal.Parent.__internal.Children + 1, returnValue)
		end
		
		--Copy the parts from the original g3Gui's parts array
		for index, value: T.g3Part in pairs(table.clone(g3Gui.__internal.Parts)) do
			local part = value:Clone()
			--Parent the new part to the new model
			part.Parent = returnValue
			
			--Add it to the g3Guis part tracker
			table.insert(returnValue.__internal.Parts, part)
		end
		
		--Re-enable the metatable
		setmetatable(g3Gui, metatable)
		
		--Return the new object
		return returnValue
	end

	--Creates a new g3 wrapper based off of its binding Model
	--Returns only the g3Gui
	g3Wrapper.bindGui = function (model: Model)
		--Gets the name of the model to be used
		local name = model.Name
		
		--Ensures that the model won't be unloaded at far zooms
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		
		
		--makes the base property table that will be used
		local g3Gui =  {

			--locations of important objects
			Model = model, 

			--actual location of stored data
			__internal = {
				Name = name, Enabled = true, Parent = lib.main, Offset = 3,
				Position = Vector2.new(0, 0), Rotation = Vector3.new(0, 0, 0), RotationCenter = Vector3.new(0, 0, 0), 
				customPropertyData = {customCallbacks = {}}, readOnly = {"Parts", "Children", "Type", "customProperyData"}, 
				Type = "BasicGui", Children = {} :: T.array, Parts = {}
			}
		}
		
		--makes a metatable so custom code can be run when a property changes
		local change = {}
		setmetatable(g3Gui, change)



	--[[
	Add a custom property (string) with a default value and optionally a custom callback when that property changes
	You can also assign _readOnly to the end of the name to make it read-only (removes "_readOnly" automatically)
	]]
		function g3Gui:CustomProperty(key: string, value: any, callback: () -> (T.g3Gui, T.key, any)?)
			--Useful shorthands
			local __internal = self.__internal
			local propertyData = __internal.customPropertyData
			
			--if _readOnly is at the end, remove _readOnly and add it to the readonly table
			if key:sub(-9) == "_readOnly" then
				key = key:sub(1, -10)
				rawset(__internal.readOnly, #__internal.readOnly + 1, key)
			end

			--make sure the name is unique
			assert(propertyData[key] == nil, "Property " .. key .. " already exists")
			assert(__internal[key] == nil, "Property " .. key .. " already exists")
			assert(self[key] == nil, "Property " .. key .. " already exists")


			--store value
			rawset(propertyData, key, value)

			--store callback too if it exists
			if not (callback == nil) then
				rawset(propertyData.customCallbacks, key,  callback)
			end
		end
		
		--Internal G3 function, binds an instance to the top level of the table
		--These should only be parts in the workspace, as they
		--wont work with customProperties or customCallbacks
		function g3Gui:BindPartToTable(object: Instance, nameOfValue: string)
			
			--Automatically puts the parent's name onto the child
			local partName = self.Name .. "'s " .. nameOfValue

			--Update binded part's name (Renames it if the name was already taken)
			if self.Part:FindFirstChild(partName) ~= nil then
				for i = 1, math.huge do
					local nextName = partName .. " " .. i
					--Indexing searches through all 3 main tables (custom properties, internal, and top level)
					if self.Part:FindFirstChild(nextName) == nil then
						--If it is a valid name, use it and break
						object.Name = nextName
						break
					end
				end
			else
				--If the name is cleared from the get-go, set it to that
				object.Name = self.Name .. "'s " .. nameOfValue
			end

			--Does the same thing as above, but for the table's values instead
			if self[nameOfValue] ~= nil then
				for i = 1, math.huge do

					local nextName = nameOfValue .. "_" .. i

					if self[nextName] == nil then
						rawset(self, nextName, object)
						break
					end
				end
			else
				rawset(self, nameOfValue, object)
			end

			--Set the parent to the part
			object.Parent = self.Part
		end

		--Destroys the part and all of its children
		function g3Gui:Destroy()
			lib.destroy(self)
		end
		--btw these function annotations dont appear in the actual instances, so writing these is kinda useless
		--you can go look at the raw functions in the g3 lib to get a better description, or you can just go
		--to the types module to get a better view of the whole thing
		function g3Gui:Clone()
			return cloneModel(self)
		end
		
		--Changes a g3Gui's spatial data by a given point
		--Think of this as defining a temporary velocity for the given object for 1 frame
		function g3Gui:Velocity (point: T.g3Point)
			--Covers for unset values
			if point.Position == nil then
				point.Position = Vector2.new(0, 0)
			end
			if point.Offset == nil then
				point.Offset = 0
			end
			if point.Rotation == nil then
				point.Rotation = Vector3.new(0, 0, 0)
			end
			lib.velocity(self, point)
		end
		
		--Recursively goes down the children of a g3Gui to apply a relative movement to the g3Gui and all of its children
		--Think of this as defining a temporary velocity for the gui for 1 frame
		function g3Gui:VelocityIterative (point: T.g3Point)
			--Covers for unset values
			if point.Position == nil then
				point.Position = Vector2.new(0, 0)
			end
			if point.Offset == nil then
				point.Offset = 0
			end
			if point.Rotation == nil then
				point.Rotation = Vector3.new(0, 0, 0)
			end
			lib.velocityIterative(self, point)
		end

		
		--return actual values when a property is read
		change.__index = function(g3Gui: T.g3Gui, index: string)
			
			--Returns either a property, a custom property, or a binded part
			return g3Gui.__internal[index] or g3Gui.__internal.customPropertyData[index] or rawget(g3Gui, index)
		end





		--code when a property is changed
		change.__newindex = function(g3Gui: T.g3Gui, index: string, value: any?)


			--Useful shorthands
			local internal = g3Gui.__internal
			local customPropertyData = internal.customPropertyData

			--Makes sure the property isnt read-only
			assert(internal.readOnly[index] == nil, "Property " .. index .. "' is read-only!")

			--Makes sure the index being changed isnt a protected table
			assert(isAProtectedTable(index) ~= true, "Cannot change property " .. index .. " as it is a protected table")

			--Makes sure the index is either a base property or set as a custom property
			assert(isAValidProperty(g3Gui, index) == true, index .. " is not a valid property")
			
			
			--basic enable disable function
			if (index == "Enabled") then
				rawset(internal, index, value)

				if value then
					g3Gui.Model.Parent = g3Gui.Parent
				else
					g3Gui.Model.Parent = nil	
				end

				
			elseif index == "Name" then
				lib.setName(g3Gui, value)
				
			elseif index == "Parent" then
				lib.setParent(g3Gui, value)
			
			--Spatial data handling
			elseif index == "Position" or index == "Rotation" or index == "Offset" or index == "RotationCenter" then
				--Saves the new spatial data
				rawset(internal, index, value)
				
				--Sets the updated spatial data point
				local point = {
					--Scaled values
					--Position could still be a UDim2, so dont scale for now
					Position = rawget(internal, "Position"),
					Offset = rawget(internal, "Offset") * lib.config.scalingFactor,
					RotationCenter = rawget(internal, "RotationCenter") * lib.config.scalingFactor,
					
					--Rotation doesnt get scaled
					Rotation = rawget(internal, "Rotation")
				}

				--Convert UDim2 positions to scaled Vector2 values
				if typeof(point.Position) == "UDim2" then
					local pos = point.Position
					local offset = Vector2.new(pos.X.Offset * lib.config.scalingFactor, pos.Y.Offset * lib.config.scalingFactor)
					
					--Scalars dont scale with lib.config.scalingFactor
					local scalars = Vector2.new(pos.X.Scale, pos.Y.Scale)
					
					--Width and height get converted to scalars for the relative screen size in studs at a given FOV and offset
					point.Position = offset + scalars * lib.getScreenSizeInStuds(point.Offset)
				end
				
				--Now that Position is guarenteed a vector2, scale the position
				point.Position *= lib.config.scalingFactor
				
				--Set finished point
				parentPointLookup[g3Gui.Model] = point
				
			--checks if it is a custom property
			elseif customPropertyData[index] ~= nil then


				--runs through any other properties added by .custom
				lib.CLoopIterative(customPropertyData, 

					--Control section
					function(key, property)
						--Skip the customCallbacks table
						lib.skip(key == "customCallbacks")

						--if the property has a callback, run its callback
						lib.piggyback(customPropertyData.customCallbacks[key] ~= nil, 
							function() 
								customPropertyData.customCallbacks[key](g3Gui, property, value)
							end
						)
					end, 

					--Base code
					function()
						--print(value)
						--Writes the new value to the table
						customPropertyData[index] = value

					end)
				
			else

				--Store the property as normal
				rawset(internal, index, value)
			end

			--reset the new index so its reusable
			rawset(g3Gui, index, nil)
		end

		--Sets a default spatial data point
		parentPointLookup[g3Gui.Model] = {
			Position = Vector2.new(0, 0),
			Offset = 3 * lib.config.scalingFactor,
			Rotation = Vector3.new(0, 0, 0),
			RotationCenter = Vector3.new(0, 0, 0)
		}
		
		--Creates container for child points
		pointLookup[g3Gui.Model] = {}
		
		--Initializes core values
		lib.setName(g3Gui, name)

		--Insert in global object trackers
		table.insert(_G.G3.allG3Gui, g3Gui)
		table.insert(_G.G3.Objects, g3Gui)
		
		--Fires the new g3 gui event
		lib.newG3Gui:Fire()
		
		--return the instance
		return g3Gui :: T.g3Gui
	end

	--Creates a new g3 wrapper based off of its binding Part
	--Returns only the g3Part
	g3Wrapper.bindPart = function (part: BasePart, parent: T.g3Gui)
		--Gets the name of the part to be used
		local name = part.Name
		

		

		--makes the base property table that will be used
		--This excludes sideParts as 
		local g3Part =  {

			--locations of important objects
			Part = part, 

			--actual location of stored data
			__internal = {
				Name = name, Enabled = true, Offset = 1, Parent = parent,
				Position = Vector2.new(0, 0), Rotation = Vector3.new(0, 0, 0), Size = Vector2.new(part.Size.X, part.Size.Y), Thickness = part.Size.Z,
				customPropertyData = {customCallbacks = {}}, readOnly = {"Type", "customProperyData"}, 
				Type = "Basic"
			}
		}

		
		
		
		--makes a metatable so custom code can be run when a property changes
		local change = {}
		setmetatable(g3Part, change)
	


		--[[
		Add a custom property (string) with a default value and optionally a custom callback when that property changes
		You can also assign _readOnly to the end of the name to make it read-only (removes "_readOnly" automatically)
		]]
		function g3Part:CustomProperty(key: string, value: any, callback: () -> (T.g3Part, T.key, any)?)
			--Useful shorthands
			local __internal = g3Part.__internal
			local propertyData = __internal.customPropertyData

			--if _readOnly is at the end, remove _readOnly and add it to the readonly table
			if key:sub(-9) == "_readOnly" then
				key = key:sub(1, -10)
				rawset(__internal.readOnly, #__internal.readOnly + 1, key)
			end

			--make sure the name is unique
			assert(propertyData[key] == nil, "Property " .. key .. " already exists")
			assert(__internal[key] == nil, "Property " .. key .. " already exists")
			assert(self[key] == nil, "Property " .. key .. " already exists")


			--store value
			rawset(propertyData, key, value)

			--store callback too if it exists
			if not (callback == nil) then
				rawset(propertyData.customCallbacks, key,  callback)
			end
			
		end

		--Internal G3 function, binds an instance to the top level of the table
		--These should only be parts in the workspace, as they
		--wont work with customProperties or customCallbacks
		function g3Part:BindPartToTable(object: Instance, nameOfValue: string)
			
			--Automatically puts the parent's name onto the child
			local partName = self.Name .. "'s " .. nameOfValue
			
			--Update binded part's name (Renames it if the name was already taken)
			if self.Part:FindFirstChild(partName) ~= nil then
				for i = 1, math.huge do
					local nextName = partName .. " " .. i
					--Indexing searches through all 3 main tables (custom properties, internal, and top level)
					if self.Part:FindFirstChild(nextName) == nil then
						--If it is a valid name, use it and break
						object.Name = nextName
						break
					end
				end
			else
				--If the name is cleared from the get-go, set it to that
				object.Name = self.Name .. "'s " .. nameOfValue
			end
			
			--Does the same thing as above, but for the table's values instead
			if self[nameOfValue] ~= nil then
				for i = 1, math.huge do
					
					local nextName = nameOfValue .. "_" .. i
					
					if self[nextName] == nil then
						rawset(self, nextName, object)
						break
					end
				end
			else
				rawset(self, nameOfValue, object)
			end
			
			--Set the parent to the part
			object.Parent = self.Part
		end

		--Destroys the part and all of its resulting data(including its parts and children)
		function g3Part:Destroy()
			lib.destroy(self)
		end
		
		--Clones a g3 part
		function g3Part:Clone()
			return clonePart(self)
		end
		
		--Changes a g3Part's spatial data by a given point
		--Think of this as defining a temporary velocity for the given object for 1 frame
		function g3Part:Velocity (point: T.g3Point)
			--Covers for unset values
			if point.Position == nil then
				point.Position = Vector2.new(0, 0)
			end
			if point.Offset == nil then
				point.Offset = 0
			end
			if point.Rotation == nil then
				point.Rotation = Vector3.new(0, 0, 0)
			end
			lib.velocity(self, point)
		end
		
		function g3Part:AttachSurfaceGUI (name: string?)
			--Covers for unset values
			if name == nil then
				name = "SurfaceGui"
			end
			local surfaceGUI = Instance.new("SurfaceGui", g3Part.Part)
			
			surfaceGUI.Name = name
			surfaceGUI.Adornee = g3Part.Part
			surfaceGUI.Face = Enum.NormalId.Back
			surfaceGUI.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			surfaceGUI.PixelsPerStud = 100
			
			return surfaceGUI
		end
		
		--return actual values when a property is read
		change.__index = function(g3Part: T.g3Part, index: string)
			--Returns either a property, a custom property, or a binded part
			return g3Part.__internal[index] or g3Part.__internal.customPropertyData[index] or rawget(g3Part, index)
		end





		--code when a property is changed
		change.__newindex = function(g3Part: T.g3Part, index: string, value: any?)
			
			--Useful shorthands
			local internal = g3Part.__internal
			local propertyData = internal.customPropertyData

			--Makes sure the property isnt read-only
			assert(internal.readOnly[index] == nil, "Property " .. index .. "' is read-only!")

			--Makes sure the index being changed isnt a protected table
			assert(isAProtectedTable(index) ~= true, "Cannot change property " .. index .. " as it is a protected table")

			--Makes sure the index is either a base property or set as a custom property
			assert(isAValidProperty(g3Part, index) == true, index .. " is not a valid property")
			
			--basic enable disable function
			if (index == "Enabled") then
				rawset(g3Part, index, value)

				if value then
					--Set its parent to its parent g3Gui
					g3Part.Part.Parent = g3Part.__internal.Parent.Model
				else
					--Hides the part
					g3Part.Part.Parent = nil	
				end


			elseif index == "Name" then
				lib.setName(g3Part, value)
				
			elseif index == "Parent" then
				lib.setParent(g3Part, value)

			--Spatial data handling
			elseif index == "Position" or index == "Rotation" or index == "Offset" then
				--Saves the new spatial data
				rawset(internal, index, value)
				
				--Sets the updated spatial data point
				local point = {
					--Scaled values
					--Position could still be a UDim2, so dont scale for now
					Position = rawget(internal, "Position"),
					Offset = rawget(internal, "Offset") * lib.config.scalingFactor,

					--Rotation doesnt get scaled
					Rotation = rawget(internal, "Rotation")
				}

				--Convert UDim2 positions to scaled Vector2 values
				if typeof(point.Position) == "UDim2" then
					local pos = point.Position
					local offset = Vector2.new(pos.X.Offset * lib.config.scalingFactor, pos.Y.Offset * lib.config.scalingFactor)
					
					--Scalars dont scale with lib.config.scalingFactor
					local scalars = Vector2.new(pos.X.Scale, pos.Y.Scale)

					--Width and height get converted to scalars for the relative screen size in studs at a given FOV and offset (parent + child offset)
					point.Position = offset + scalars * lib.getScreenSizeInStuds(point.Offset + g3Part.Parent.Offset)
				end
				
				--Now that Position is guarenteed a vector2, scale the position
				point.Position *= lib.config.scalingFactor
				
				--Sets the updated spatial data point
				pointLookup[g3Part.Parent.Model][part] = point
				
			--2D resizing 
			elseif index == "Size" then
				rawset(internal, index, value)
				
				local size = value
				
				--Convert UDim2 sizes to scaled values
				if typeof(size) == "UDim2" then
					local offset = Vector2.new(size.X.Offset * lib.config.scalingFactor, size.Y.Offset * lib.config.scalingFactor)
					
					--Scalars dont scale with lib.config.scalingFactor
					local scalars = Vector2.new(size.X.Scale, size.Y.Scale)
					
					--Width and height get converted to scalars for the relative screen size in studs at a given FOV and offset (parent + child offset)
					size = offset + (scalars * lib.getScreenSizeInStuds(g3Part.Offset + g3Part.Parent.Offset))
				else
					--Scale the size
					size *= lib.config.scalingFactor
				end
				
				g3Part.Part.Size = Vector3.new(size.X, size.Y, g3Part.Part.Size.Z)
			
			--3D thickness resizing
			elseif index == "Thickness" then
				rawset(internal, index, value)
				g3Part.Part.Size = Vector3.new(g3Part.Part.Size.X, g3Part.Part.Size.Y, value * lib.config.scalingFactor)
				
			--checks if it is a custom property
			elseif propertyData[index] ~= nil then


				--runs through any other properties added by .custom
				lib.CLoopIterative(propertyData, 

					--Control section
					function(key, property)
						--Skip the customCallbacks table
						lib.skip(key == "customCallbacks")

						--if the property has a callback, run its callback
						lib.piggyback(propertyData.customCallbacks[key] ~= nil, 
							function() 
								propertyData.customCallbacks[key](g3Part, property, value)
							end
						)
					end, 

					--Base code
					function()
						--Writes the new value to the table
						propertyData[index] = value

					end)
			else

				--Store the value
				rawset(g3Part.__internal, index, value)
			end
			
			

			--reset the new index so its reusable
			rawset(g3Part, index, nil)
		end
		
		--Inserts it in the global part tracker
		table.insert(_G.G3.allParts, g3Part)
		
		--Fires the new g3 part event
		lib.newG3Part:Fire()
		
		--Initializes core values
		lib.setParent(g3Part, parent)
		lib.setName(g3Part, name)
		
		--return the instance
		return g3Part :: T.g3Part
	end
	
	--Creates a new G3 wrapper with all of its standard functions
	--Returns the created g3Gui
	g3Wrapper.newGui = function(name: string)

		--Defaults to being added to the top level folder
		local newModel = Instance.new("Model", lib.main)
			newModel.Name = name
			newModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

		local g3Gui = g3Wrapper.bindGui(newModel)
		
		--return the instances
		return g3Gui :: T.g3Gui
	end
	
	--Creates a new G3 wrapper with all of its standard functions
	--Returns the created g3 wrapper
	g3Wrapper.newPart = function(name: string, parent: T.g3Gui)

		--Defaults to being added to the top level folder
		local newPart = Instance.new("Part", lib.main)
			newPart.Name = name
			newPart.Size = Vector3.new(lib.config.scalingFactor, lib.config.scalingFactor, lib.config.scalingFactor)
			newPart.Anchored = true
			newPart.CanCollide = false
			newPart.CanTouch = false
			newPart.CanQuery = true
			newPart.Massless = true
			newPart.CastShadow = false
			newPart.AudioCanCollide = false

		local g3Part = g3Wrapper.bindPart(newPart, parent)
		
		--return the instances
		return g3Part :: T.g3Part

	end
	

return g3Wrapper


