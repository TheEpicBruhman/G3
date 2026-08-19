--[[
    partManager (ModuleScript)
    Path: ReplicatedFirst → G3 → New Parts
    Parent: New Parts
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local lib = require("../Base/lib")
local T = require("../Base/types")
local g3Wrapper = require("./g3Wrapper")
local pointLookup: T.pointLookup = _G.G3.pointLookup

local partManager = {}

	--Bind a part to a g3Gui, making it attached to the g3Gui (part of the main model)
	partManager.bind = function (g3Gui: T.g3Gui, part: BasePart)
		local parts = g3Gui.Parts
		
		--Create a wrapper for the new part
		local bindedPart = g3Wrapper.bindPart(part, g3Gui)		
		
		--add binded part to the parts table
		table.insert(parts, bindedPart)

		--Set its spatial data to a default
		pointLookup[g3Gui.Model][part] = {Position = Vector2.new(0,0), Offset = lib.config.scalingFactor, Rotation = Vector3.new(0,0,0)}	
		
		--Return the binded part
		return bindedPart
	end
	
	--Creates a new part, and bind it
	partManager.new = function(g3Gui: T.g3Gui, name: string)
		local parts = g3Gui.Parts
		
		--Create the new part
		local newPart = g3Wrapper.newPart(name, g3Gui)
		
		--Add the new part to the parts table
		table.insert(parts, newPart)
		
		--Set its spatial data to a default
		pointLookup[g3Gui.Model][newPart.Part] = {Position = Vector2.new(0,0), Offset = lib.config.scalingFactor, Rotation = Vector3.new(0,0,0)}	
		
		--Return the new part
		return newPart
	end

return partManager
