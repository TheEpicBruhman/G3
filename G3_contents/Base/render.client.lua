--[[
    render (LocalScript)
    Path: ReplicatedFirst → G3 → Base
    Parent: Base
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

--!optimize 2


--Get Service

local RunService = game:GetService("RunService")
local lib = require("./lib")
local T = require("./types")

--Main code

--Important vectors and cframes predefined
local rightVector: Vector3, downVector: Vector3, lookVector: Vector3
local origin: CFrame

--Storage containers for g3 spatial data
local pointLookup: T.pointLookup = _G.G3.pointLookup
local parentPointLookup: T.parentPointLookup = _G.G3.parentPointLookup

--Used for BulkMoveTo
local parts = {}
local returnedCFrames = {}

--Shorthands, used for parent rotation
local sin = math.sin
local cos = math.cos
local cx: number, cy: number, cz: number, sx: number, sy: number, sz: number

--Shorthands
local Angles = CFrame.Angles
local clear = table.clear

--Stores the index of the number its currently calculating the position for
local index: number

--Covers all simple translations
@native
local function translate(origin:CFrame, point: T.g3Point, parentPoint: T.g3Point): CFrame
	
	--Translations
	local Position = point.Position + parentPoint.Position
	local Offset = point.Offset + parentPoint.Offset
	
	--Rotation (in radians)
	local Rotation = Angles(parentPoint.Rotation.X, parentPoint.Rotation.Y, parentPoint.Rotation.Z) * Angles(point.Rotation.X, point.Rotation.Y, point.Rotation.Z)
	
	--Merged equation of x translation, y translation, z translation, and rotation
	return ((origin * Rotation) + (Offset * lookVector) + (Position.Y * downVector) + (Position.X * rightVector))
end

--Covers for parential rotation
--Rotates a point around a parent's center
--Parent's center calculations are done before calculating the point rotations
@native
local function rotateAboutCenter(point: T.g3Point, parentRotationCenterShift: Vector3): T.g3Point
	
	--Get the part's position as a vector3
	local pos = Vector3.new(point.Position.X, point.Position.Y, point.Offset)
	
	--Apply the shift
	pos -= - parentRotationCenterShift


	--Due to the way G3 was set up with guis defining centers and parts defining offsets, this makes rotation
	--just a problem of 3 2d rotations instead of full 3d rotations (not intended but makes everything so much easier)
	--https://en.wikipedia.org/wiki/2D_rotation

	local x, y, z = pos.X, pos.Y, pos.Z
	
	--Rotates in reverse order (ZYX) because of some math that i dont understand and i just guess and checked
	
	--Apply the shift on z rotation
	pos = Vector3.new(
		x * cz + y * sz, 
		y * cz - x * sz, 
		z
	)
	
	--Update xyz values
	x, y, z = pos.X, pos.Y, pos.Z

	--Apply the shift on y rotation
	pos = Vector3.new(
		x * cy - z * sy, 
		y, 
		z * cy + x * sy
	)
	
	--Update xyz values
	x, y, z = pos.X, pos.Y, pos.Z


	--Apply the shift on x rotation
	pos = Vector3.new(
		x,
		y * cx - z * sx, 
		z * cx + y * sx
	)

	--Undo the shift
	pos += - parentRotationCenterShift
	
	--Update position and offset values
	point.Position = Vector2.new(pos.X, pos.Y)
	point.Offset = pos.Z
	
	--Return the rotated point
	return point
end

--Calculate new positions of parts
@native
local function calculate(parentPoint: T.g3Point, childrenPoints: T.array)
	--Copy the parent point
	local parentPoint = table.clone(parentPoint)

	--Convert parent rotations to radians
	parentPoint.Rotation *= 0.0174532925
	
	--Fixes the rotation so that it rotates in the same direction as other 3d visualizers like https://www.toolsrail.com/maths/3d-shape-rotator.php
	parentPoint.Rotation = Vector3.new(-parentPoint.Rotation.X, parentPoint.Rotation.Y, -parentPoint.Rotation.Z)
	
	--Calculate cosine and sine values used for parent rotation
	cx, cy, cz = cos(parentPoint.Rotation.X), cos(parentPoint.Rotation.Y), cos(parentPoint.Rotation.Z)
	sx, sy, sz = sin(parentPoint.Rotation.X), sin(parentPoint.Rotation.Y), sin(parentPoint.Rotation.Z)
	
	for part, point: T.g3Point in childrenPoints do
		--Copy the child point
		local point = table.clone(point)
		
		index += 1
		
		--Convert child rotation into radians
		point.Rotation = point.Rotation * 0.0174532925
		
		--Fixes the rotation so that it rotates in the same direction as other 3d visualizers like https://www.toolsrail.com/maths/3d-shape-rotator.php
		point.Rotation = Vector3.new(-point.Rotation.X, point.Rotation.Y, -point.Rotation.Z)
		
		--Get rotated point
		point = rotateAboutCenter(point, parentPoint.RotationCenter)
		
		--Translate point and store
		rawset(returnedCFrames, index, translate(origin, point, parentPoint))
		rawset(parts, index, part)
	end
end


	
--Binding to render step is faster than prerender:connect as it happens before resuming parallel threads
--Because of this, it can send messages to the actors to queue them up, instead of having to send
--it all when resuming parallel threads, which each actor has to wait before they get their selected message
--This is a suprising performance boost of 40% in some cases
RunService:BindToRenderStep("G3 Update Service", 1000000000, function()

	--Every part originates from the camera, get its new position
	origin = workspace.CurrentCamera.CFrame
		rightVector = origin.RightVector
		downVector = -origin.UpVector
		lookVector = origin.LookVector
	
	--Creates fresh data containers
	clear(returnedCFrames)
	clear(parts)
	
	--Reset the write index
	index = 0
	
	--Runs the calculations
	for parent, children in pairs(pointLookup) do
		calculate(parentPointLookup[parent], children)
	end
	
	--Apply the resulting cframes
	workspace:BulkMoveTo(parts, returnedCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end)

--[[ Original functions used to construct the transform and calculate functions ]]

--[[
--Only used to save time
local function fastRadians (degrees: number)
	return degrees * 0.0174532925
end
local function applyPosition (cframe: CFrame, position: Vector2)
	--Rightwards and downwards movements are positive

	local downVector: Vector3 = -cframe.UpVector
	local rightVector: Vector3 = cframe.RightVector
	return cframe + (position.X * rightVector) + (position.Y * downVector)
	
end

--Apply a camera offset to the CFrame
@native
local function applyOffset (cframe: CFrame, offset: number)
	--Slides the position along the camera's lookVector
	local lookVector: Vector3 = workspace.CurrentCamera.CFrame.LookVector
	
	return cframe + (offset * lookVector)
end

--Apply a 3d rotation to the cframe
@native
local function applyRotation (cframe: CFrame, rot: Vector3)
	--Applies the rotation in degrees

	local rotX = fastRadians(rot.X)
	local rotY = fastRadians(rot.Y)
	local rotZ = fastRadians(rot.Z)
	
	--Apply the rotation
	local rotation = CFrame.Angles(rotX, rotY, rotZ)
	
	return cframe * rotation
end

--Rotates a g3Gui's parts upon its center by a given rotation
--Optionally define a shift in the center of rotation
--IMPORTANT: Only apply once per frame otherwise it becomes incredibly innacurate
@native
function lib.axialVelocity(g3Gui: T.g3Gui, Rotation: Vector3, Shift: Vector3?)
	Shift = Shift or Vector3.new(0, 0, 0)
	
	--Convert rotation to radians
	--Accurate pi/180 approximation to minimize drift
	local RotationRadians = Rotation * 0.017453292519943295
	
	--Rotate the model (does the same thing as rotating all of the parts)
	--For some reason, Z and Y directions are flipped
	g3Gui:Velocity({Rotation = Vector3.new(Rotation.X, Rotation.Z, Rotation.Y)})
	
	
	
	--Operate on each g3 part
	for _, part: T.g3Part in pairs(g3Gui.Parts) do
		
		--Get the part's position as a vector3
		local pos = Vector3.new(part.Position.X, part.Position.Y, part.Offset)
		
		
		--Due to the way G3 was set up with guis defining centers and parts defining offsets, this makes rotation
		--just a problem of 3 2d rotations instead of full 3d rotations
		--https://en.wikipedia.org/wiki/2D_rotation
		
		local x, y, z = pos.X, pos.Y, pos.Z
		
		--Apply the shift on x rotation
		pos = Vector3.new(
			x,
			y * cx - z * sx, 
			z * cx + y * sx
		)
		
		--Update xyz values
		x, y, z = pos.X, pos.Y, pos.Z
		
		--Apply the shift on y rotation
		pos = Vector3.new(
			x * cy - z * sy, 
			y, 
			z * cy + x * sy
		)
		
		--Update xyz values
		x, y, z = pos.X, pos.Y, pos.Z
		
		--Apply the shift on z rotation
		pos = Vector3.new(
			x * cz - y * sz, 
			y * cz + x * sz, 
			z
		)
		
		
		
		--Apply the resulting transformation
		part.Position = Vector2.new(pos.X, pos.Y)
		part.Offset = pos.Z
	end
end
]]