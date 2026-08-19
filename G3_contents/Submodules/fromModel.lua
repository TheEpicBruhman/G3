--[[
    fromModel (ModuleScript)
    Path: ReplicatedFirst → G3 → Submodules
    Parent: Submodules
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local g3Wrapper = require("../New Parts/g3Wrapper")
local lib = require("../Base/lib")
local T = require("../Base/types")
local pointLookup = _G.G3.pointLookup

--Clones and goes down recursively a model and converts it to a g3Gui with accurate positioning, offsets, etc.
local convert = {}
	
	--Converts a model normally
	local function recursiveConversionNormal (model: Model, parent: T.g3Gui | Folder, trueCenter: Vector3)
		
		--Gets the center of the model relative to the parent
		local modelPivot = lib.getTruePivot(model)
		local modelPosition = modelPivot.Position - trueCenter
		
		--Convert the model into a g3Gui
		local returnValue = g3Wrapper.bindGui(model)
		returnValue.Parent = parent
		
		--Apply spatial shifts
		returnValue.Position = -Vector2.new(modelPosition.X, modelPosition.Y)
		returnValue.Offset = -modelPosition.Z
		
		--Iterate through the model's children
		for _, part in model:GetChildren() do
			
			--Set it up as a g3 Part
			if part:IsA("BasePart") then
				
				--You may see some of the positioning / rotation code is negated / added 180deg, as otherwise the result would be flipped around
				--I'm not sure exactly why this happens, but I think its a conflict of positioning systems that needs to be converted like this
				
				--Set some basic properties
				part.CanQuery = true
				part.CanCollide = false
				part.AudioCanCollide = false
				part.CastShadow = false
				part.Massless = true
				
				--Get the part's center
				local partCenter = lib.getTruePivot(part)
				
				--Get part spatial data
				local partPosition = partCenter.Position - trueCenter - modelPosition
				
				--This is EXTREMELY sloppy, but it works to properly rotate the part how it should
				local partRotation = part.Rotation * Vector3.new(1, -1, -1) + Vector3.new(180, 0, 180)
				
				--Calculate translation shifts
				local pos = -Vector2.new(partPosition.X, partPosition.Y)
				local offset = partPosition.Z
				
				--Create G3 part
				local part = g3Wrapper.bindPart(part, returnValue)

				--add binded part to the parts table
				table.insert(_G.G3.allParts, part)
				rawset(returnValue.__internal.Parts, #returnValue.__internal.Parts + 1, part)
				
				--Apply the position and rotation
				part.Rotation = partRotation
				part.Offset = offset
				part.Position = pos
				
				--Add all of its first children to the top-level table
				for _, child in part.Part:GetChildren() do
					
					if child:IsA("BasePart") then
						error("Tried to add a part to a g3Part. All g3Parts must be parented to a model")
					end
					
					--If its any other instance, bind it to the top-level table
					part:BindPartToTable(child, child.Name)
				end
			
			end
			
			--Iterate through the model's children
			if part:IsA("Model") then
				recursiveConversionNormal(part, returnValue, trueCenter)
			end
		end
		
		return returnValue :: T.g3Gui
	end
	
	--Smartly sets the offset based off of the model's biggest size dimension
	local function smartOffset(g3Gui: T.g3Gui, size: Vector3)
		
		--Accounts for half the model size, alongside the scaling factor
		g3Gui.Offset += math.max(size.X, size.Y, size.Z) / (2 * lib.config.scalingFactor)
		
		for _, gui in g3Gui.Children do
			smartOffset(gui, size)
		end
	end
	
	--Converts a model to a g3Gui
	convert.normal = function(model: Model) 
		
		--Clones the model so that its client side only
		local newModel = model:Clone()
		
		--Gets the center of the full model's position
		local centerCFrame, size =  lib.getTruePivot(newModel)
		local trueCenter = centerCFrame.Position		
		
		--Flips it 180 degrees
		newModel:PivotTo(model.WorldPivot * CFrame.Angles(0, 0, math.rad(180)))
		
		--Convert normally, recursing through all of its children
		local returnValue = recursiveConversionNormal(newModel, lib.main, trueCenter) :: T.g3Gui
		
		--Scales it to the scalingFactor
		newModel:ScaleTo(newModel:GetScale() * lib.config.scalingFactor)
		
		--Get the new scaled size
		local _, size =  lib.getTruePivot(newModel)
		
		--Smartly offset the g3Guis so that it roughly fits the screen
		smartOffset(returnValue, size/2)
		
		return returnValue
	end
	
	
	--Eventually would convert its screen ui parts alongside the model to g3 versions (3d gui elements)
	convert.g3 = function() 
		
	end
return convert
