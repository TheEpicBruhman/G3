--[[
    G3 (ModuleScript)
    Path: ReplicatedFirst
    Parent: ReplicatedFirst
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]



print("Running G3 v0.1")

--Get Service

const GeometryService = game:GetService("GeometryService")

--Get Base data

local lib = require("@self/Base/lib")
local T = require("@self/Base/types")

--Main code

--load in all module data
local parts = require("@self/New Parts/partManager")
local wrapper = require("@self/New Parts/g3Wrapper")
local fromModel = require("@self/Submodules/fromModel")



local g3 = {}

--populates the g3 module with all the finished functions

--Bind a pre-existing part to a g3Gui
g3.BindPartToGui = function (g3Gui: T.g3Gui, part: BasePart)
	--Scale part to scalingFactor
	part.Size *=  lib.config.scalingFactor
	return parts.bind(g3Gui, part)
end

--Create a basic part and bind it to a g3Gui
g3.NewPartToGui = function (g3Gui: T.g3Gui, name: string)
	return parts.new(g3Gui, name)
end

--Create a new G3 Gui
g3.NewGui = function (name: string)
	return wrapper.newGui(name)
end

--Takes in an array of parts (such as g3Gui.Parts or _G.G3.allParts) and spits out the first part that matches the name
g3.FindFirstChild = function(source: T.array, name: string): T.g3Part
	for _, part in source do
		if part.Name == name then
			return part
		end
	end
	
	warn("FindFirstChild returned nil")
end

--Merges any number of parts together
--The first part is used as the base, and its data will be used for the final part
--IMPORTANT: You have to wait 1 frame (min 0.02s) for your parts to move until you can union them, otherwise
--they all crowd around the same point as they havent had time to move
g3.MergeParts = function (part: T.g3Part, mergedParts: {[number]: T.g3Part})
	
	--Clone main part
	local returnValue = part:Clone()
	local parts = {}
	local pointLookup = _G.G3.pointLookup
	
	--Grab all parts from the mergedParts array
	for _, part in mergedParts do
		table.insert(parts, part.Part)
	end
	--This part is the original clones instance, which will have to be destroyed when we replace it with a union instead
	local oldPart = returnValue.Part
	
	--Create a new union of the parts
	returnValue.Part = GeometryService:UnionAsync(returnValue.Part, parts, {SplitApart = false})[1]
	returnValue.Parent = part.Parent
	
	oldPart:Destroy()
	
	--Copy spatial data of the originating part
	pointLookup[part.Parent.Model][returnValue.Part] = pointLookup[part.Parent.Model][part.Part]
	
	--Destroy all old data
	pointLookup[part.Parent.Model][oldPart] = nil
	part:Destroy()
	for _, mergedPart in mergedParts do
		pointLookup[part.Parent.Model][mergedPart.Part] = nil
		mergedPart:Destroy()
	end

	return returnValue
end

	
--Converts a model and all of its children into functioning g3Gui
g3.FromModel = function(model: Model)
	
	return fromModel.normal(model) :: T.g3Gui
end

--The top level folder that all g3 parts inherit from
g3.MainFolder = lib.main

--Gets animator module
--g3.Animator = require("@self/Submodules/Animator")
	

--Important data types used in g3
export type gui = T.g3Gui
export type part = T.g3Part
export type any = T.g3Any
export type point = T.g3Point


		
	
	

return g3
