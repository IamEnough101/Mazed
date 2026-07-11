--!strict
--[[
	InventoryService.lua
	Thin, purpose-named facade over PlayerDataService's inventory storage.
	Other services depend on InventoryService rather than reaching into
	PlayerDataService directly, so "where mazes are stored" can change
	(e.g. moving to its own DataStore) without touching callers.
]]

local PlayerDataService = require(script.Parent.PlayerDataService)

local InventoryService = {}

function InventoryService.GetAll(player: Player): { any }
	return PlayerDataService.GetInventory(player)
end

function InventoryService.Add(player: Player, mazeRecord: any)
	PlayerDataService.AddMazeToInventory(player, mazeRecord)
end

function InventoryService.Remove(player: Player, mazeId: string): any?
	return PlayerDataService.RemoveMazeFromInventory(player, mazeId)
end

function InventoryService.Find(player: Player, mazeId: string): any?
	return PlayerDataService.FindMazeInInventory(player, mazeId)
end

return InventoryService
