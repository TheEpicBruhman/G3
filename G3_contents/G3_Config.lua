--[[
    G3 Config (ModuleScript)
    Path: ReplicatedFirst → G3
    Parent: G3
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]


local c = {}

------------------------------ [[ Core behavior ]] ------------------------------

-- Determines the scaling factor of G3
-- This makes Position and Offset properties move smaller distances, keeping parts closer to camera 
-- Type: number, Range from 0.01 - 10, Default: 1
c.scalingFactor = 1

-- [[ CURRENTLY DISABLED AS IT IS NOT FULLY IMPLEMENTED ]] --
-- Determines if relative scaling (UDim / UDim2 scales) will be scaled relative to the full screen, or only the screen-safe space
-- This means that different devices will have different resulting scales based on screen notches, etc
-- Type: Boolean, Default: false
c.relativeScalingUsesScreenSafeSpace = true

-- Determines if all relative scaling uses 16 : 9, instead of the devices actual aspect ratio
-- This will make all relative scaling the same on all devices, although for screens such as 4 : 3 or devices with notches, it may not fully fit on screen
-- Overrides relativeScalingUsesScreenSafeSpace
-- Type: Boolean, Default: false
c.lockTo16by9 = false

------------------------------ [[ Occlusion behavior ]] ------------------------------

-- Determines if occlusion behaviour is on or off
-- Occlusion behavior makes parts transparent when the g3Gui is overlapping with it (this behavior can be customized)
-- Type: Boolean, Default: false
c.occlusion = true


--[[ 
Determines the accuracy of the occlusion check
	1 speed: Accounts for full precise volume of each part
	2 speed: Account for the bounding box for each part (doesnt account for shape of the part)
	3 speed: Accounts for the bounding box of each g3Gui (doesnt account for specific shape of g3Gui)
	4 speed: Accounts for the bounding box of only top-level g3Gui (doesnt account for shape of the children g3Gui and all of its children)
	
Given a trial on 2700 base parts nested in this pattern: 3 layer 1s | layer 1 = 3 layer 2s | layer 2 = 3 layer 3s | layer 3 = 100 basic parts
the approximate speedup is listed here

		1 speed: 1x
		2 speed: 1.03x --(Much bigger difference for unions / meshes)
		3 speed: 13.8x
		4 speed: 38.7x
		
Its important to try it out yourself and pick the option with the correct accuracy for your guis, weighing out the accuracy vs speed
]]
--Type: Integer, Range: 1 - 4, Default: 3
c.occlusionSpeedDial = 3



--If you want custom occlusion behavior, you can use the following as a function run on each occluding part
c.occlusionON = function (part: BasePart)
	--Update the transparency of the object
	--You can modify this transparency value to whatever you want from 0 - 1
	part.LocalTransparencyModifier = 0.6
end

c.occlusionOFF = function (part: BasePart)
	--Update the transparency of the object back to 0
	part.LocalTransparencyModifier = 0
end


-- Overlap parameters used in the occlusion check
-- Automatically includes all created g3 parts.
-- Type: OverlapParams
c.occlusionParams = OverlapParams.new()
	c.occlusionParams.FilterType = Enum.RaycastFilterType.Exclude
	
	

------------------------------ [[ Min zoom behavior ]] ------------------------------

-- Determines if min zoom behavior is active
-- If active, you can set a custom property minZoom in a g3Gui to set the minimum zoom while that g3Gui is Enabled
-- Type: Boolean, Default: true
c.minZoom = true

------------------------------ [[ Runtime code behavior ]] ------------------------------

-- Determines how many actors the current occlusion script will have
-- Higher numbers may spread out occlusion work more evenly, but too high may slow down the script
-- Range: Integer between 1 - 100, Default: 16
c.occlusionActors = 16




return c