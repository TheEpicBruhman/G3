--[[
    Runtime Parallelizer (Script)
    Path: ReplicatedFirst → G3
    Parent: G3
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local storedCode = script.Parent["Parallel storage"]
local runningCode = script.Parent["Generated Actors"]
local lib = require("./Base/lib")
local T = require("./Base/types")




local function parralelize(actorCount: number, actorName: string, code: Script)
	
	--run the script before creating actors
	code.Enabled = true
	
	--Create actor table
	_G.G3.actors[actorName] = {} :: T.array
	
	for i = 1, actorCount do
		
		local actor: Actor
		
		--Create actor if it doesn't exist already
		if runningCode:FindFirstChild("Thread #" .. i, false) == nil then
			actor = Instance.new("Actor", runningCode)
				actor.Name = "Thread #" .. i
		else
			actor = runningCode["Thread #" .. i]
		end
		
		table.insert(_G.G3.actors, actor)
		
		--Clone script into the actor	
		local posScript = code:Clone()
			posScript.Parent = actor
	end
end

--Only creates occlusion code if occlusion is enabled
if lib.config.occlusion then
	
	local speed = lib.config.occlusionSpeedDial
	
	--Clones either slow, medium, or fast occlusion based on config
	if speed == 1 then
		parralelize(lib.config.occlusionActors, "slowOcclusionHandler", storedCode.slowOcclusion)
	elseif speed == 2 then
		parralelize(lib.config.occlusionActors, "mediumOcclusionHandler", storedCode.mediumOcclusion)
	elseif speed == 3 then
		parralelize(lib.config.occlusionActors, "fastOcclusionHandler", storedCode.fastOcclusion)
	else
		parralelize(lib.config.occlusionActors, "superfastOcclusionHandler", storedCode.superfastOcclusion)
	end
	
end