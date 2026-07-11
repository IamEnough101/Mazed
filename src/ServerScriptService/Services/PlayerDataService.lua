--!strict
--[[
	PlayerDataService.lua
	Owns each player's persisted profile: coins, free-egg flag and maze
	inventory. All other server services go through this module instead of
	touching DataStores directly, so save/retry logic lives in one place.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataService = {}

local store = DataStoreService:GetDataStore("MazeEggsPlayerData_v1")

export type Profile = {
	coins: number,
	hasReceivedFreeEgg: boolean,
	inventory: { any }, -- EggSystem.MazeRecord[]
}

local DEFAULT_PROFILE: Profile = {
	coins = 0,
	hasReceivedFreeEgg = false,
	inventory = {},
}

local profiles: { [number]: Profile } = {}
local loadingComplete: { [number]: boolean } = {}

local MAX_RETRIES = 3

local function attemptWithRetry<T>(fn: () -> T): (boolean, T?)
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`PlayerDataService: attempt {attempt} failed: {result}`)
		task.wait(2 ^ attempt * 0.5)
	end
	return false, nil
end

local function deepCopyDefault(): Profile
	return {
		coins = DEFAULT_PROFILE.coins,
		hasReceivedFreeEgg = DEFAULT_PROFILE.hasReceivedFreeEgg,
		inventory = {},
	}
end

function PlayerDataService.Load(player: Player)
	local key = `Player_{player.UserId}`
	local ok, data = attemptWithRetry(function()
		return store:GetAsync(key)
	end)

	if ok and data then
		profiles[player.UserId] = data
	else
		profiles[player.UserId] = deepCopyDefault()
	end

	loadingComplete[player.UserId] = true
end

function PlayerDataService.Save(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	local key = `Player_{player.UserId}`
	attemptWithRetry(function()
		store:SetAsync(key, profile)
	end)
end

function PlayerDataService.Release(player: Player)
	PlayerDataService.Save(player)
	profiles[player.UserId] = nil
	loadingComplete[player.UserId] = nil
end

-- Blocks (via task.wait) until PlayerDataService.Load has finished for this player.
-- Safe to call from remote handlers that might fire before loading completes.
function PlayerDataService.WaitForProfile(player: Player): Profile
	while not loadingComplete[player.UserId] do
		task.wait(0.1)
	end
	return profiles[player.UserId]
end

function PlayerDataService.GetCoins(player: Player): number
	return PlayerDataService.WaitForProfile(player).coins
end

function PlayerDataService.AddCoins(player: Player, amount: number)
	assert(amount >= 0, "AddCoins: amount must be non-negative")
	local profile = PlayerDataService.WaitForProfile(player)
	profile.coins += amount
end

-- Returns false without mutating state if the player can't afford `amount`.
function PlayerDataService.SpendCoins(player: Player, amount: number): boolean
	local profile = PlayerDataService.WaitForProfile(player)
	if profile.coins < amount then
		return false
	end
	profile.coins -= amount
	return true
end

function PlayerDataService.HasReceivedFreeEgg(player: Player): boolean
	return PlayerDataService.WaitForProfile(player).hasReceivedFreeEgg
end

function PlayerDataService.MarkFreeEggReceived(player: Player)
	PlayerDataService.WaitForProfile(player).hasReceivedFreeEgg = true
end

function PlayerDataService.GetInventory(player: Player): { any }
	return PlayerDataService.WaitForProfile(player).inventory
end

function PlayerDataService.AddMazeToInventory(player: Player, mazeRecord: any)
	local profile = PlayerDataService.WaitForProfile(player)
	table.insert(profile.inventory, mazeRecord)
end

-- Removes and returns the maze record with the given id, or nil if not found.
function PlayerDataService.RemoveMazeFromInventory(player: Player, mazeId: string): any?
	local profile = PlayerDataService.WaitForProfile(player)
	for index, record in ipairs(profile.inventory) do
		if record.id == mazeId then
			table.remove(profile.inventory, index)
			return record
		end
	end
	return nil
end

function PlayerDataService.FindMazeInInventory(player: Player, mazeId: string): any?
	local profile = PlayerDataService.WaitForProfile(player)
	for _, record in ipairs(profile.inventory) do
		if record.id == mazeId then
			return record
		end
	end
	return nil
end

Players.PlayerAdded:Connect(PlayerDataService.Load)
Players.PlayerRemoving:Connect(PlayerDataService.Release)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService.Save(player)
	end
end)

return PlayerDataService
