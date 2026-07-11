--!strict
--[[
	EggSystem.lua
	Opens an egg: rolls rarity, mutation and difficulty, then packages the
	result into a "maze record" -- the data structure stored in a player's
	inventory until they walk into the maze and play it.

	Server-authoritative: only ServerScriptService/Services/EggOpeningService
	should call EggSystem.Open. The client only ever receives the resulting
	record over a RemoteEvent for display purposes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local RaritySystem = require(ReplicatedStorage.Modules.RaritySystem)
local MutationSystem = require(ReplicatedStorage.Modules.MutationSystem)
local DifficultySystem = require(ReplicatedStorage.Modules.DifficultySystem)
local CoinCalculator = require(ReplicatedStorage.Modules.CoinCalculator)

export type MazeRecord = {
	id: string,
	seed: number,
	eggName: string,
	rarity: string,
	mutation: string,
	difficulty: string,
	timerSeconds: number,
	potentialBaseCoins: number, -- coins if the maze were completed with 0 time remaining
	createdAt: number,
}

local EggSystem = {}

function EggSystem.GetEggCost(eggName: string, isPlayersFirstEgg: boolean): number
	local eggData = GameConfig.EggData[eggName]
	assert(eggData, `EggSystem.GetEggCost: unknown egg "{eggName}"`)
	if eggData.freeFirstEgg and isPlayersFirstEgg then
		return 0
	end
	return eggData.cost
end

-- Rolls a brand new maze from the given egg. `rng` is optional and lets the
-- server pass a Random seeded from a verified source for reproducible tests.
function EggSystem.Open(eggName: string, rng: Random?): MazeRecord
	assert(GameConfig.EggData[eggName], `EggSystem.Open: unknown egg "{eggName}"`)

	local rarity = RaritySystem.Roll(eggName, rng)
	local mutation = MutationSystem.Roll(eggName, rng)
	local difficulty = DifficultySystem.Roll(eggName, rng)
	local timerSeconds = CoinCalculator.CalculateTimer(difficulty, mutation)
	local potentialBaseCoins = CoinCalculator.CalculateCoins(difficulty, rarity, mutation, 0)

	return {
		id = HttpService:GenerateGUID(false),
		seed = (rng and rng:NextInteger(1, 2 ^ 31 - 1)) or math.random(1, 2 ^ 31 - 1),
		eggName = eggName,
		rarity = rarity,
		mutation = mutation,
		difficulty = difficulty,
		timerSeconds = timerSeconds,
		potentialBaseCoins = potentialBaseCoins,
		createdAt = os.time(),
	}
end

return EggSystem
