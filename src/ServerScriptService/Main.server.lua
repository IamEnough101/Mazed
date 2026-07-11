--!strict
--[[
	Main.server.lua
	Boots every server-side service in dependency order and wires up the
	PlayerAdded flow (profile load -> send initial state to client).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local ShopService = require(Services.ShopService)
local MazeService = require(Services.MazeService)

ShopService.Init()
MazeService.Init()

local function onPlayerAdded(player: Player)
	-- PlayerDataService.Load is already connected to PlayerAdded internally;
	-- WaitForProfile blocks here until that load finishes.
	PlayerDataService.WaitForProfile(player)

	RemoteEvents.CoinsUpdated:FireClient(player, PlayerDataService.GetCoins(player))
	RemoteEvents.InventoryUpdated:FireClient(player, PlayerDataService.GetInventory(player))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
