--!strict
--[[
	RemoteEvents.lua
	Creates (or, on the client, waits for) every RemoteEvent/RemoteFunction
	used by Maze Eggs. Both server and client require this same module so
	there is one canonical list of remote names.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "MazeEggsRemotes"

local EVENT_NAMES = {
	"CoinsUpdated", -- server -> client: (coins: number)
	"InventoryUpdated", -- server -> client: (inventory: { MazeRecord })
	"EggOpened", -- server -> client: (mazeRecord) fired after purchase, drives egg-opening animation
	"TimerUpdate", -- server -> client: (secondsRemaining: number)
	"MazeCompleted", -- server -> client: (mazeRecord, coinsAwarded: number, timeRemaining: number)
	"MazeFailed", -- server -> client: (mazeRecord)
}

local FUNCTION_NAMES = {
	"BuyEgg", -- client -> server: (eggName: string) -> (success: boolean, message: string)
	"PlayMaze", -- client -> server: (mazeId: string) -> (success: boolean, message: string)
	"GetPlayerState", -- client -> server: () -> (coins: number, inventory: { MazeRecord })
}

local RemoteEvents = {}

local function getOrCreateFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		if RunService:IsServer() then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		else
			folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
		end
	end
	return folder :: Folder
end

local folder = getOrCreateFolder()

local function getOrCreate(className: string, name: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end

	if RunService:IsServer() then
		local instance = Instance.new(className)
		instance.Name = name
		instance.Parent = folder
		return instance
	end

	return folder:WaitForChild(name)
end

for _, name in ipairs(EVENT_NAMES) do
	RemoteEvents[name] = getOrCreate("RemoteEvent", name)
end

for _, name in ipairs(FUNCTION_NAMES) do
	RemoteEvents[name] = getOrCreate("RemoteFunction", name)
end

return RemoteEvents
