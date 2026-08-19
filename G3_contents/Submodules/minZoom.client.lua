--[[
    minZoom (LocalScript)
    Path: ReplicatedFirst → G3 → Submodules
    Parent: Submodules
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local lib = require("../Base/lib")
local RunService = game:GetService("RunService")

if lib.config.minZoom then
	local zoom: number
	local player: Player = game.Players.LocalPlayer
	
	--Yes while this is incredibly inefficient and sluggish, 
	--improving it any further wouldnt matter as it only takes ~300 ns for almost 3000 searches
	RunService:BindToSimulation(function()
		
		local guis = _G.G3.allG3Gui
		
		--Resets the min zoom every frame
		zoom = 0.5
		
		--Rechecks if there is a bigger zoom value in the global part tracker
		for i, child in guis do
			--Only runs on enabled GUI
			if rawget(child.__internal, "Enabled") == true then
				
				if rawget(child.__internal.customPropertyData, "minZoom") ~= nil then
					--Gets the bigger minzoom value
					zoom = math.max(zoom, child.minZoom)
				end
			end
		end
	end, Enum.StepFrequency.Hz60, 1555)
	
	RunService.PostSimulation:Connect(function() 
		--Sets the min zoom
		player.CameraMinZoomDistance = zoom
	end)
end