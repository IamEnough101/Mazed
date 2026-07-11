--!strict
--[[
	CameraController.lua
	Custom Roblox-style third-person camera:
	  - Mouse-driven yaw/pitch orbit around the character
	  - Framerate-independent smooth follow (exponential damping, not lerp-per-frame)
	  - Wall collision: a raycast from the character to the desired camera
	    position pulls the camera closer if something is in the way
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera :: Camera

local DEFAULT_DISTANCE = 14
local MIN_DISTANCE = 3
local MOUSE_SENSITIVITY = 0.0035
local MIN_PITCH = math.rad(-70)
local MAX_PITCH = math.rad(70)
local FOLLOW_DAMPING = 12 -- higher = snappier

local yaw = 0
local pitch = math.rad(-15)
local connections: { RBXScriptConnection } = {}

local function getHumanoidRootPart(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function onInputChanged(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		yaw -= input.Delta.X * MOUSE_SENSITIVITY
		pitch = math.clamp(pitch - input.Delta.Y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
	end
end

local function computeDesiredCFrame(rootPart: BasePart): CFrame
	local focusPoint = rootPart.Position + Vector3.new(0, 2, 0)
	local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local backDirection = rotation.LookVector

	-- Raycast from the focus point outward to the ideal camera spot; if we
	-- hit a wall, clamp the distance so the camera never clips through it.
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { player.Character }

	local idealPosition = focusPoint + backDirection * DEFAULT_DISTANCE
	local result = Workspace:Raycast(focusPoint, backDirection * DEFAULT_DISTANCE, rayParams)

	local distance = DEFAULT_DISTANCE
	if result then
		distance = math.max(MIN_DISTANCE, (result.Position - focusPoint).Magnitude - 1)
	end

	local cameraPosition = focusPoint + backDirection * distance
	return CFrame.lookAt(cameraPosition, focusPoint)
end

function CameraController.Start()
	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(deltaTime: number)
			local rootPart = getHumanoidRootPart()
			if not rootPart then
				return
			end

			local desired = computeDesiredCFrame(rootPart)
			local alpha = 1 - math.exp(-FOLLOW_DAMPING * deltaTime)
			camera.CFrame = camera.CFrame:Lerp(desired, alpha)
		end)
	)
end

function CameraController.Stop()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	camera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return CameraController
