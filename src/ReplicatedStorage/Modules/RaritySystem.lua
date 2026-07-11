--!strict
--[[
	RaritySystem.lua
	Rolls a maze rarity for a given egg and exposes the rarity multiplier
	table used by the coin formula.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local WeightedRandom = require(ReplicatedStorage.Modules.WeightedRandom)

local RaritySystem = {}

function RaritySystem.GetMultiplier(rarity: string): number
	local multiplier = GameConfig.RarityMultipliers[rarity]
	assert(multiplier, `RaritySystem.GetMultiplier: unknown rarity "{rarity}"`)
	return multiplier
end

-- Applies the egg's luckMultiplier to every rarity at or above
-- GameConfig.LuckBoostStartsAtRarity, then rolls against the adjusted weights.
function RaritySystem.Roll(eggName: string, rng: Random?): string
	local eggData = GameConfig.EggData[eggName]
	assert(eggData, `RaritySystem.Roll: unknown egg "{eggName}"`)

	local boostStartIndex = table.find(GameConfig.Rarities, GameConfig.LuckBoostStartsAtRarity) :: number
	local adjustedWeights = {}

	for index, rarity in ipairs(GameConfig.Rarities) do
		local baseWeight = eggData.rarityWeights[rarity]
		if index >= boostStartIndex then
			adjustedWeights[rarity] = baseWeight * eggData.luckMultiplier
		else
			adjustedWeights[rarity] = baseWeight
		end
	end

	return WeightedRandom.Pick(adjustedWeights, rng)
end

return RaritySystem
