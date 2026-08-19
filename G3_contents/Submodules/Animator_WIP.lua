--[[
    Animator (WIP) (ModuleScript)
    Path: ReplicatedFirst → G3 → Submodules
    Parent: Submodules
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

--Gets base data
local T = require("../Base/types")
local cT = require("./customTypes")
local lib = require("../Base/lib")

local animator = {}

--im not gonna lie i dont really understand this math but this should work
@native
local function bezier3(t: number, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3)
	local x = 1 - t
	local cubic = x * x * x * p0
	local quadratic = 3 * x * x * t * p1
	local linear = 3 * x * t * t * p2
	local constant = t * t * t * p3
	return cubic + quadratic + linear + constant
end

@native
local function bezier2(t: number, p0: Vector2, p1: Vector2, p2: Vector2)
	local x = 1 - t
	local quadratic = x * x * p0
	local linear = 2 * x * t * p1
	local constant = t * t * p2
	return quadratic + linear + constant
end

--[[
for i = 1, 100 do
	
	local t = i / 100
	local x = bezier2(t, 0, 0.)
end
]]

--Applies an animation info to an object
--Optionally define whether to apply the animation to all of the objects children (if it is a g3Gui)
animator.Apply = function (object: T.g3Any, info: cT.animationInfo, iterative: boolean)
	
end

--Removes all animations from an object
--Snaps the object back to its startPoint
animator.Remove = function (object: T.g3Any)
	
end

--Create a new animationInfo
animator.New = function (easingStyle: Enum.EasingStyle, easingDirection: Enum.EasingDirection, movement: "Linear" | "Bezier2" | "Bezier3" | "CenteredRotation", duration: number, endPoint: T.g3Point, controlPoints: {bezierFirst: Vector3?, bezierSecond: Vector3?, rotationCenter: Vector3?}?, repetitions: number?, reverses: boolean?): cT.animationInfo
	--Returns an unfinished animationInfo, it only is fully completed when applied to an object
	return {
		easingStyle = easingStyle, 
		easingDirection = easingDirection, 
		movement = movement, 
		duration = duration, 
		repetitions = repetitions, 
		reverses = reverses, 
		endPoint = endPoint,
		controlPoints = controlPoints
		--object, startingPoint, playing, elapsed time etc will be added when the animation is applied to the object
	}
end
return animator
