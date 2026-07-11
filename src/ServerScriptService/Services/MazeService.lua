--!strict
--[[
	MazeService.lua
	Orchestrates a single maze run end-to-end:
	  1. Validate the player owns the requested maze and isn't already playing one.
	  2. Regenerate the maze's 3D geometry from its stored seed (MazeGenerator).
	  3. Teleport the player in and start the countdown (TimerService).
	  4. Detect maze completion via the EndPoint part's Touched event.
	  5. Award coins (CoinCalculator), remove the maze from inventory, teleport
	     the player back out, and clean up the generated geometry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MazeGenerator = require(ReplicatedStorage.Modules.MazeGenerator)
local CoinCalculator = require(ReplicatedStorage.Modules.CoinCalculator)
local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)

local PlayerDataService = require(script.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)
local TimerService = require(script.Parent.TimerService)
local TeleportService = require(script.Parent.TeleportService)

local MazeService = {}

-- Active mazes live in their own instanced Folder per player so multiple
-- players can be inside a maze simultaneously without geometry collisions.
local activeMazesFolder = Instance.new("Folder")
activeMazesFolder.Name = "ActiveMazes"
activeMazesFolder.Parent = Workspace

-- Lay out each player's maze far apart on the X axis so instances never overlap.
local MAZE_SLOT_SPACING = 1000

type ActiveRun = {
	model: Model,
	mazeRecord: any,
	connection: RBXScriptConnection,
}

local activeRuns: { [Player]: ActiveRun } = {}

local function getMazeOrigin(player: Player): CFrame
	return CFrame.new(player.UserId % 1000 * MAZE_SLOT_SPACING, 0, 0)
end

local function cleanupRun(player: Player)
	local run = activeRuns[player]
	if not run then
		return
	end
	run.connection:Disconnect()
	run.model:Destroy()
	activeRuns[player] = nil
end

local function failMaze(player: Player, mazeRecord: any)
	if not activeRuns[player] then
		return
	end
	cleanupRun(player)
	TeleportService.TeleportToLobby(player)
	RemoteEvents.MazeFailed:FireClient(player, mazeRecord)
end

local function completeMaze(player: Player, mazeRecord: any)
	if not activeRuns[player] then
		return
	end

	local timeRemaining = TimerService.Stop(player)
	cleanupRun(player)

	local coinsAwarded = CoinCalculator.CalculateCoins(mazeRecord.difficulty, mazeRecord.rarity, mazeRecord.mutation, timeRemaining)

	InventoryService.Remove(player, mazeRecord.id)
	PlayerDataService.AddCoins(player, coinsAwarded)

	TeleportService.TeleportToLobby(player)

	RemoteEvents.CoinsUpdated:FireClient(player, PlayerDataService.GetCoins(player))
	RemoteEvents.InventoryUpdated:FireClient(player, InventoryService.GetAll(player))
	RemoteEvents.MazeCompleted:FireClient(player, mazeRecord, coinsAwarded, timeRemaining)
end

function MazeService.StartMaze(player: Player, mazeId: string): (boolean, string)
	if activeRuns[player] then
		return false, "You are already inside a maze"
	end

	local mazeRecord = InventoryService.Find(player, mazeId)
	if not mazeRecord then
		return false, "Maze not found in inventory"
	end

	local origin = getMazeOrigin(player)
	local generated = MazeGenerator.Generate(mazeRecord.difficulty, mazeRecord.seed, origin)
	generated.model.Parent = activeMazesFolder

	local endPoint = generated.model:FindFirstChild("EndPoint") :: BasePart
	local connection = endPoint.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		if character and Players:GetPlayerFromCharacter(character) == player then
			completeMaze(player, mazeRecord)
		end
	end)

	activeRuns[player] = { model = generated.model, mazeRecord = mazeRecord, connection = connection }

	TeleportService.TeleportToMaze(player, generated.startCFrame)
	TimerService.Start(player, mazeRecord.timerSeconds, function()
		failMaze(player, mazeRecord)
	end)

	return true, "Maze started"
end

function MazeService.Init()
	RemoteEvents.PlayMaze.OnServerInvoke = function(player: Player, mazeId: string)
		local ok, success, message = pcall(MazeService.StartMaze, player, mazeId)
		if not ok then
			warn(`MazeService.StartMaze error: {success}`)
			return false, "Server error"
		end
		return success, message
	end

	Players.PlayerRemoving:Connect(function(player)
		if activeRuns[player] then
			cleanupRun(player)
		end
		TimerService.Stop(player)
	end)
end

return MazeService
