--!strict
--[[
	DifficultySystem.lua
	Rolls a maze difficulty for a given egg and exposes base coin/timer data.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local WeightedRandom = require(ReplicatedStorage.Modules.WeightedRandom)

local DifficultySystem = {}

function DifficultySystem.GetData(difficulty: string)
	local data = GameConfig.DifficultyData[difficulty]
	assert(data, `DifficultySystem.GetData: unknown difficulty "{difficulty}"`)
	return data
end

function DifficultySystem.Roll(eggName: string, rng: Random?): string
	local eggData = GameConfig.EggData[eggName]
	assert(eggData, `DifficultySystem.Roll: unknown egg "{eggName}"`)
	return WeightedRandom.Pick(eggData.difficultyWeights, rng)
end

return DifficultySystem
