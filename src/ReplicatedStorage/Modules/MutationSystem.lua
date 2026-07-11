--!strict
--[[
	MutationSystem.lua
	Rolls a maze mutation independently of rarity. Mutation odds are the
	global baseChance values scaled by the egg's luckMultiplier, checked
	from rarest to most common so the probability bands never overlap.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local MutationSystem = {}

-- Highest rarity mutation first: this order is what makes a single roll
-- correct (each tier "claims" its slice of the 0-1 range before falling
-- through to the next, cheaper tier).
local ROLL_ORDER = { "Emerald", "Diamond", "Gold", "Silver" }

function MutationSystem.GetData(mutation: string)
	local data = GameConfig.MutationData[mutation]
	assert(data, `MutationSystem.GetData: unknown mutation "{mutation}"`)
	return data
end

function MutationSystem.Roll(eggName: string, rng: Random?): string
	local eggData = GameConfig.EggData[eggName]
	assert(eggData, `MutationSystem.Roll: unknown egg "{eggName}"`)

	local roll = if rng then rng:NextNumber() else math.random()

	local cumulative = 0
	for _, mutation in ipairs(ROLL_ORDER) do
		local chance = GameConfig.MutationData[mutation].baseChance * eggData.luckMultiplier
		cumulative += chance
		if roll < cumulative then
			return mutation
		end
	end

	return "None"
end

return MutationSystem
