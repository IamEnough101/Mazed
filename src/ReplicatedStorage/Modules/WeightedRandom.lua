--!strict
--[[
	WeightedRandom.lua
	Generic weighted-random picker shared by RaritySystem, MutationSystem
	and DifficultySystem so there is exactly one implementation of the
	"roll against a weight table" primitive.
]]

local WeightedRandom = {}

-- Picks a key from `weights` proportionally to its value.
-- `rng` optionally lets callers pass a seeded Random for deterministic tests.
function WeightedRandom.Pick(weights: { [string]: number }, rng: Random?): string
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end

	assert(total > 0, "WeightedRandom.Pick: weight table sums to 0")

	local roll = if rng then rng:NextNumber() * total else math.random() * total
	local cumulative = 0

	for key, weight in pairs(weights) do
		cumulative += weight
		if roll <= cumulative then
			return key
		end
	end

	-- Floating point edge case: return the last-seen key rather than nil.
	local fallback
	for key in pairs(weights) do
		fallback = key
	end
	return fallback :: string
end

return WeightedRandom
