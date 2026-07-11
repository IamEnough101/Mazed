--!strict
--[[
	ShopService.lua
	Handles the "BuyEgg" RemoteFunction: validates the purchase, deducts
	coins (or grants the one-time free Basic Egg), opens the egg via
	EggSystem, stores the resulting maze in the player's inventory, and
	notifies the client so it can play the opening animation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local EggSystem = require(ReplicatedStorage.Modules.EggSystem)
local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local PlayerDataService = require(script.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)

local ShopService = {}

function ShopService.PurchaseEgg(player: Player, eggName: string): (boolean, string)
	if not table.find(GameConfig.Eggs, eggName) then
		return false, `Unknown egg: {eggName}`
	end

	local isFirstEgg = eggName == "Basic" and not PlayerDataService.HasReceivedFreeEgg(player)
	local cost = EggSystem.GetEggCost(eggName, isFirstEgg)

	if cost > 0 then
		local spent = PlayerDataService.SpendCoins(player, cost)
		if not spent then
			return false, "Not enough coins"
		end
	end

	if isFirstEgg then
		PlayerDataService.MarkFreeEggReceived(player)
	end

	local mazeRecord = EggSystem.Open(eggName)
	InventoryService.Add(player, mazeRecord)

	RemoteEvents.CoinsUpdated:FireClient(player, PlayerDataService.GetCoins(player))
	RemoteEvents.InventoryUpdated:FireClient(player, InventoryService.GetAll(player))
	RemoteEvents.EggOpened:FireClient(player, mazeRecord)

	return true, "Egg opened"
end

function ShopService.Init()
	RemoteEvents.BuyEgg.OnServerInvoke = function(player: Player, eggName: string)
		local ok, success, message = pcall(ShopService.PurchaseEgg, player, eggName)
		if not ok then
			warn(`ShopService.PurchaseEgg error: {success}`)
			return false, "Server error"
		end
		return success, message
	end

	RemoteEvents.GetPlayerState.OnServerInvoke = function(player: Player)
		return PlayerDataService.GetCoins(player), InventoryService.GetAll(player)
	end
end

return ShopService
