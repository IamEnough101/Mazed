--!strict
--[[
	GameConfig.lua
	Single source of truth for every tunable number in Maze Eggs.
	Server and client modules both read from this table so balance
	changes only ever happen in one place.
]]

export type RarityName = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
export type MutationName = "None" | "Silver" | "Gold" | "Diamond" | "Emerald"
export type DifficultyName = "Easy" | "Medium" | "Hard" | "Extreme"
export type EggName = "Basic" | "Bronze" | "Silver" | "Gold" | "Diamond" | "Emerald"

export type EggEntry = {
	cost: number,
	freeFirstEgg: boolean?,
	luckMultiplier: number,
	rarityWeights: { [string]: number },
	difficultyWeights: { [string]: number },
}

local GameConfig = {}

-- Ordered list matters for UI sorting and for luck-boost thresholds.
GameConfig.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local rarityMultipliers: { [string]: number } = {
	Common = 1.0,
	Uncommon = 1.1,
	Rare = 1.25,
	Epic = 1.5,
	Legendary = 2.0,
	Mythic = 3.0,
}
GameConfig.RarityMultipliers = rarityMultipliers

GameConfig.Mutations = { "None", "Silver", "Gold", "Diamond", "Emerald" }

-- baseChance values are the global odds documented in the design spec.
-- Egg luckMultiplier (see EggData) scales these per egg.
local mutationData: { [string]: { coinMultiplier: number, timePenalty: number, baseChance: number } } = {
	None = { coinMultiplier = 1.0, timePenalty = 0, baseChance = 0 },
	Silver = { coinMultiplier = 1.2, timePenalty = 5, baseChance = 0.10 },
	Gold = { coinMultiplier = 1.5, timePenalty = 10, baseChance = 0.04 },
	Diamond = { coinMultiplier = 2.0, timePenalty = 15, baseChance = 0.01 },
	Emerald = { coinMultiplier = 3.0, timePenalty = 20, baseChance = 0.002 },
}
GameConfig.MutationData = mutationData

GameConfig.Difficulties = { "Easy", "Medium", "Hard", "Extreme" }

local difficultyData: { [string]: { baseCoins: number, baseTimer: number } } = {
	Easy = { baseCoins = 10, baseTimer = 45 },
	Medium = { baseCoins = 25, baseTimer = 60 },
	Hard = { baseCoins = 50, baseTimer = 75 },
	Extreme = { baseCoins = 100, baseTimer = 90 },
}
GameConfig.DifficultyData = difficultyData

GameConfig.Eggs = { "Basic", "Bronze", "Silver", "Gold", "Diamond", "Emerald" }

-- rarityWeights / difficultyWeights are relative weights (not required to sum to
-- any fixed total) fed into a weighted-random picker. luckMultiplier scales the
-- global mutation baseChance values and boosts the weight of Epic+ rarities.
local eggData: { [string]: EggEntry } = {
	Basic = {
		cost = 50,
		freeFirstEgg = true,
		luckMultiplier = 1.0,
		rarityWeights = { Common = 7000, Uncommon = 2200, Rare = 700, Epic = 90, Legendary = 9, Mythic = 1 },
		difficultyWeights = { Easy = 80, Medium = 18, Hard = 2, Extreme = 0 },
	},
	Bronze = {
		cost = 150,
		luckMultiplier = 1.15,
		rarityWeights = { Common = 5500, Uncommon = 2800, Rare = 1400, Epic = 250, Legendary = 45, Mythic = 5 },
		difficultyWeights = { Easy = 60, Medium = 30, Hard = 9, Extreme = 1 },
	},
	Silver = {
		cost = 500,
		luckMultiplier = 1.35,
		rarityWeights = { Common = 3500, Uncommon = 3000, Rare = 2200, Epic = 1000, Legendary = 250, Mythic = 50 },
		difficultyWeights = { Easy = 35, Medium = 35, Hard = 22, Extreme = 8 },
	},
	Gold = {
		cost = 1500,
		luckMultiplier = 1.75,
		rarityWeights = { Common = 1800, Uncommon = 2500, Rare = 2800, Epic = 2000, Legendary = 750, Mythic = 150 },
		difficultyWeights = { Easy = 15, Medium = 30, Hard = 35, Extreme = 20 },
	},
	Diamond = {
		cost = 5000,
		luckMultiplier = 2.5,
		rarityWeights = { Common = 500, Uncommon = 1200, Rare = 2500, Epic = 3000, Legendary = 2200, Mythic = 600 },
		difficultyWeights = { Easy = 5, Medium = 20, Hard = 35, Extreme = 40 },
	},
	Emerald = {
		cost = 15000,
		luckMultiplier = 4.0,
		rarityWeights = { Common = 50, Uncommon = 250, Rare = 1200, Epic = 2800, Legendary = 3500, Mythic = 2200 },
		difficultyWeights = { Easy = 0, Medium = 10, Hard = 30, Extreme = 60 },
	},
}
GameConfig.EggData = eggData

-- Rarities at or above this index in GameConfig.Rarities get their weight
-- multiplied by the egg's luckMultiplier when rolling (see RaritySystem.lua).
GameConfig.LuckBoostStartsAtRarity = "Epic" :: RarityName

-- Absolute floor so a maze can never be rolled with an unplayable timer.
GameConfig.MinimumTimerSeconds = 10

-- Grid dimensions (cells wide x cells tall) fed to MazeGenerator, keyed by
-- difficulty. Higher difficulty = larger, more complex maze.
local gridSizeByDifficulty: { [string]: { width: number, height: number } } = {
	Easy = { width = 8, height = 8 },
	Medium = { width = 12, height = 12 },
	Hard = { width = 16, height = 16 },
	Extreme = { width = 20, height = 20 },
}
GameConfig.GridSizeByDifficulty = gridSizeByDifficulty

-- Physical size of one maze cell, in studs.
GameConfig.MazeCellSize = 12
GameConfig.MazeWallHeight = 12
GameConfig.MazeWallThickness = 1

GameConfig.Formulas = {
	Coins = "Coins = (BaseDifficultyCoins * RarityMultiplier * MutationMultiplier) + (TimeRemaining * 1)",
	Timer = "Timer = max(MinimumTimerSeconds, BaseDifficultyTimer - MutationPenalty)",
}

return GameConfig
