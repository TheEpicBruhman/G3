--[[
    fastOcclusion (LocalScript)
    Path: ReplicatedFirst → G3 → Parallel storage
    Parent: Parallel storage
    Properties:
        Disabled: true
    Exported: 2026-08-19 06:16:26 (web)
]]



--Get globals

--Get Service

local RunService = game:GetService("RunService")

--Main code

--Main code
--Mostly copied from the positionObjects script, but modified for occlusion checking

--If the parent of the script is not an actor, run setup
if not script.Parent:IsA("Actor") then
	--Get base data
	local lib = require("@self/../../Base/lib")
	local allG3Gui = {}
	
	--Used to imitate a return value
	local dataChannel = Instance.new("BindableEvent")

	--New parts returned from the fresh occlusion check this frame
	local currentlyOccludingParts = {}
	
	--Occluded parts from the last frame (used to check against currentlyOccludingParts to see if stuff has gone out of occlusion)
	local occludedParts = {}

	--When new G3Gui is created, clear out empty g3Guis from the table
	lib.newG3Gui.Event:Connect(function() 
		allG3Gui = _G.G3.allG3Gui
		
		--Clear empty g3Gui
		for i in allG3Gui do
			local g3Gui = allG3Gui[i]
			if #g3Gui.Parts == 0 then
				table.remove(allG3Gui, i)
			end
		end
	end)
	
	--Run occlusion checking
	RunService.PostSimulation:Connect(function()	

		--Creates a new overlap params that merges existing g3 parts with overlap params in lib.config
		local occlusionParams = {}
		local filter = occlusionParams.ExcludeInstances or {}

		
		--OcclusionParams cant be passed through messages, so it has to reconstruct it as a table
		--Dirty cloning as occlusion params dont work with table.clone
		local keys = {"ExcludeInstances", "IncludeInstances", "MaxParts", "CollisionGroup", "Tolerance", "RespectCanCollide", "BruteForceAllSlow", "FilterDescendantsInstances", "FilterType"}
		for i in keys do
			--Only applies if there is a value
			if lib.config[keys[i]] ~= nil then
				occlusionParams[keys[i]] = lib.config[keys[i]]
				print(keys[i])
			end
		end
		
		--Add all g3 parts to excluded filter
		table.insert(filter, workspace.CurrentCamera["G3 Data"])
		
		occlusionParams.ExcludeInstances = filter

		--Gives each actor one part to calculate
		for index, child in ipairs(allG3Gui) do
			--Skip through disabled parts
			if child.Enabled == false then
				continue
			end
			
			local actors = _G.G3.actors
			
			--If there is more parts than actors, then it goes back to the first actor
			--Pretty weird math, but it works
			local selectedActorIndex = ((index - 1) % lib.config.occlusionActors) + 1
			local selectedActor: Actor = actors[selectedActorIndex]
			
			--Get the true pivot and size of the model
			local pivot, size = lib.getTruePivot(child.Model)
			
			selectedActor:SendMessage("occlusionCheck", child.Model, occlusionParams, size, pivot, dataChannel)
		end

	end)
	
	--Grabs the data that was returned from the actors, and cleans it so that there are no duplicates
	dataChannel.Event:Connect(function(parts)
		--If it returned no parts, then skip
		if parts == nil then
			return
		end
		
		--Checks if a new part has been added
		for i, child in ipairs(parts) do
			if currentlyOccludingParts[child] == nil then
				
				--Sets the part as both the index and the value, makes this duplicate cleaning process O(n) instead of O(n^2) due to it being a set
				currentlyOccludingParts[child] = child
			end
		end	
	end)
	
	--Determines conclusions from the new occlusion checks
	RunService:BindToRenderStep("occlusion", -213, function() 
		
		--Checks if the part is occluding
		for i, child in pairs(currentlyOccludingParts) do

			--Makes sure not to overcount occluded parts
			if occludedParts[child] ~= nil then
				continue
			end

			--Store the new occluded part in the occluded parts table
			occludedParts[child] = child

			--Run the occlusion function
			lib.config.occlusionON(child)
		end
		
		--Check if the part is not occluding anymore
		for i, child in pairs(occludedParts) do

			--If an occluded part in the list is not found in the fresh check, then it is not occluded anymore
			if currentlyOccludingParts[child] == nil then

				occludedParts[child] = nil

				lib.config.occlusionOFF(child)
			end


		end
		
		--Refresh the list of currently occluding parts at the end of every frame
		table.clear(currentlyOccludingParts)
	end)
	
	return
end

--Get Module data

local lib = require("@self/../../../Base/lib")
local T = require("@self/../../../Base/types")

--Main code

local actor: Actor = script.Parent

--Run on occlusion check message
actor:BindToMessageParallel("occlusionCheck", function(model: Model, params: T.dict, boundingBox: Vector3, pivot: CFrame, dataChannel: BindableEvent)
	--Reassemble the params because overlapParams cant be sent through actor messages
	local overlapParams = OverlapParams.new()
	for key, value in params do
		overlapParams[key] = value
	end
	
	--Run occlusion check
	local parts = workspace:GetPartBoundsInBox(pivot, boundingBox, overlapParams)
	
	--Return the parts that it found
	dataChannel:Fire(parts)
end)

