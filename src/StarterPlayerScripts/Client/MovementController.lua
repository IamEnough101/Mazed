--!strict
--[[
	MovementController.lua
	Sets baseline Humanoid movement stats and adds a sprint toggle.
	Walking/jumping input itself is left to Roblox's default character
	controller (WASD + Space) -- this module only tunes speed and layers
	sprint on top so the built-in collision/physics stack keeps working.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local MovementController = {}

local WALK_SPEED = 16
local SPRINT_SPEED = 26
local JUMP_POWER = 50

local player = Players.LocalPlayer
local connections: { RBXScriptConnection } = {}

local function getHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function setSprinting(isSprinting: boolean)
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = isSprinting and SPRINT_SPEED or WALK_SPEED
	end
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_POWER
end

function MovementController.Start()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == Enum.KeyCode.LeftShift then
				setSprinting(true)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.LeftShift then
				setSprinting(false)
			end
		end)
	)
end

function MovementController.Stop()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
end

return MovementController
