--!strict
--[[
	CoinCalculator.lua
	Implements the two core formulas from the design spec:

		Coins = (BaseDifficultyCoins * RarityMultiplier * MutationMultiplier)
		        + (TimeRemaining * 1)

		Timer = max(MinimumTimerSeconds, BaseDifficultyTimer - MutationPenalty)

	Pure functions only -- no randomness, no state. Given the same inputs
	these always return the same outputs, which keeps rewards auditable.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local RaritySystem = require(ReplicatedStorage.Modules.RaritySystem)
local MutationSystem = require(ReplicatedStorage.Modules.MutationSystem)
local DifficultySystem = require(ReplicatedStorage.Modules.DifficultySystem)

local CoinCalculator = {}

-- Timer = BaseDifficultyTimer - MutationPenalty, floored at MinimumTimerSeconds.
function CoinCalculator.CalculateTimer(difficulty: string, mutation: string): number
	local difficultyData = DifficultySystem.GetData(difficulty)
	local mutationData = MutationSystem.GetData(mutation)
	local timer = difficultyData.baseTimer - mutationData.timePenalty
	return math.max(GameConfig.MinimumTimerSeconds, timer)
end

-- Coins = (BaseDifficultyCoins * RarityMultiplier * MutationMultiplier) + (TimeRemaining * 1)
function CoinCalculator.CalculateCoins(difficulty: string, rarity: string, mutation: string, timeRemaining: number): number
	local difficultyData = DifficultySystem.GetData(difficulty)
	local rarityMultiplier = RaritySystem.GetMultiplier(rarity)
	local mutationData = MutationSystem.GetData(mutation)

	local baseReward = difficultyData.baseCoins * rarityMultiplier * mutationData.coinMultiplier
	local timeBonus = math.max(0, timeRemaining) * 1

	return math.floor(baseReward + timeBonus + 0.5) -- round to nearest whole coin
end

return CoinCalculator
