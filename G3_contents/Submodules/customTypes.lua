--[[
    customTypes (ModuleScript)
    Path: ReplicatedFirst → G3 → Submodules
    Parent: Submodules
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local T = require("../Base/types")
local cT = {}

------ [[  Animator module  ]] ------
--The top-level animation type, used to create the animation
export type animationInfo = {
	--Describes the easing style of the animation
	easingStyle: Enum.EasingStyle,
	
	--Describes the easing direction
	easingDirection: Enum.EasingDirection,
	
	--Determines what type of movement (path) the animation will have
	movement: "Linear" | "Bezier2" | "Bezier3" | "CenteredRotation",
	
	--Describes the object this is animating
	object: T.g3Any,
	
	--Stores the end point of the animation (Start point is the current position, offset, rotation, and rotationcenter?)
	--If a part of the end state is left out, defaults to the origins values
	endPoint: T.g3Point,
	
	--Only used if using nonlinear movement
	--Importantly relative to the starting point (its position and offset data)
	controlPoints: {
		bezierFirst: Vector3?,
		bezierSecond: Vector3?,
		rotationCenter: Vector3?
	}?,
	
	--Describes the repititions of the animation
	--If set to true, then it will loop infinitely (Can be stopped if set to nil / a number)
	--If set to nil, then defaults to 0 repetitions
	repetitions: number | true?,
	
	--Determines if it reverses after it finishes
	reverses: boolean,
	
	-- [[ Read-Only values ]] --
	
	--Describes the object's starting point
	startPoint: T.g3Point,
	
	--Describes the duration in seconds of the animation
	duration: number,
	
	--Describes if the animation is currently playing
	playing: "Playing" | "Paused" | "Finished" | "Stopped",
	
	--Describes the elapsed time of the animation
	elapsedTime: UDim
}


-- Describes a collection of all animations happening on all instances
export type animations = {
	[Instance]: {[number]: animationInfo}
}

return cT
