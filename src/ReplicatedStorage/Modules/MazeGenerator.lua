--!strict
--[[
	MazeGenerator.lua
	Grid-based procedural maze generation using an iterative recursive-
	backtracker, then instantiated as real 3D parts (floor, ceiling, walls).

	Fully deterministic: the same seed + difficulty always produces the
	exact same maze, so a maze record stored in an inventory can be
	regenerated on demand instead of being persisted as raw geometry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local MazeGenerator = {}

type Cell = { visited: boolean, N: boolean, S: boolean, E: boolean, W: boolean }
type Grid = { [number]: { [number]: Cell } }

local OPPOSITE = { N = "S", S = "N", E = "W", W = "E" }
local DELTA = {
	N = { dx = 0, dy = -1 },
	S = { dx = 0, dy = 1 },
	E = { dx = 1, dy = 0 },
	W = { dx = -1, dy = 0 },
}

-- Builds the logical grid: every cell starts with all four walls up, then an
-- iterative backtracker carves passages until every cell has been visited.
local function buildGrid(width: number, height: number, rng: Random): Grid
	local grid: Grid = {}
	for y = 1, height do
		grid[y] = {}
		for x = 1, width do
			grid[y][x] = { visited = false, N = true, S = true, E = true, W = true }
		end
	end

	local stack = { { x = 1, y = 1 } }
	grid[1][1].visited = true
	local visitedCount = 1
	local totalCells = width * height

	while visitedCount < totalCells do
		local current = stack[#stack]
		local directions = { "N", "S", "E", "W" }
		-- Fisher-Yates shuffle using the seeded RNG for determinism.
		for i = #directions, 2, -1 do
			local j = rng:NextInteger(1, i)
			directions[i], directions[j] = directions[j], directions[i]
		end

		local carved = false
		for _, dir in ipairs(directions) do
			local delta = DELTA[dir]
			local nx, ny = current.x + delta.dx, current.y + delta.dy
			if nx >= 1 and nx <= width and ny >= 1 and ny <= height and not grid[ny][nx].visited then
				grid[current.y][current.x][dir] = false
				grid[ny][nx][OPPOSITE[dir]] = false
				grid[ny][nx].visited = true
				visitedCount += 1
				table.insert(stack, { x = nx, y = ny })
				carved = true
				break
			end
		end

		if not carved then
			table.remove(stack) -- dead end, backtrack
		end
	end

	return grid
end

local function newPart(size: Vector3, cframe: CFrame, parent: Instance, name: string, material: Enum.Material, color: Color3, canCollide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = canCollide
	part.Material = material
	part.Color = color
	part.Parent = parent
	return part
end

export type GeneratedMaze = {
	model: Model,
	startCFrame: CFrame,
	endCFrame: CFrame,
	width: number,
	height: number,
}

-- Builds a full 3D maze Model anchored at `origin` (the world CFrame of the
-- maze's bottom-front-left corner) for the given difficulty and seed.
function MazeGenerator.Generate(difficulty: string, seed: number, origin: CFrame): GeneratedMaze
	local gridSize = GameConfig.GridSizeByDifficulty[difficulty]
	assert(gridSize, `MazeGenerator.Generate: unknown difficulty "{difficulty}"`)

	local width, height = gridSize.width, gridSize.height
	local cellSize = GameConfig.MazeCellSize
	local wallHeight = GameConfig.MazeWallHeight
	local wallThickness = GameConfig.MazeWallThickness

	local rng = Random.new(seed)
	local grid = buildGrid(width, height, rng)

	local model = Instance.new("Model")
	model.Name = `Maze_{difficulty}_{seed}`

	local floorWidth = width * cellSize
	local floorDepth = height * cellSize

	-- Floor spans the whole grid as a single part for performance.
	local floorCFrame = origin * CFrame.new(floorWidth / 2, 0, floorDepth / 2)
	newPart(Vector3.new(floorWidth, 1, floorDepth), floorCFrame, model, "Floor", Enum.Material.Concrete, Color3.fromRGB(120, 120, 120), true)

	-- Ceiling mirrors the floor at wall height so players can't see/escape over the top.
	local ceilingCFrame = origin * CFrame.new(floorWidth / 2, wallHeight, floorDepth / 2)
	newPart(Vector3.new(floorWidth, 1, floorDepth), ceilingCFrame, model, "Ceiling", Enum.Material.Concrete, Color3.fromRGB(60, 60, 60), true)

	local wallsFolder = Instance.new("Folder")
	wallsFolder.Name = "Walls"
	wallsFolder.Parent = model

	local wallColor = Color3.fromRGB(150, 90, 60)

	-- Cell (x, y) center, local to `origin`.
	local function cellCenter(x: number, y: number): Vector3
		return Vector3.new((x - 0.5) * cellSize, wallHeight / 2, (y - 0.5) * cellSize)
	end

	for y = 1, height do
		for x = 1, width do
			local cell = grid[y][x]
			local center = cellCenter(x, y)

			-- North wall (also covers the outer border on row 1).
			if cell.N then
				local cframe = origin * CFrame.new(center.X, wallHeight / 2, (y - 1) * cellSize)
				newPart(Vector3.new(cellSize + wallThickness, wallHeight, wallThickness), cframe, wallsFolder, `Wall_N_{x}_{y}`, Enum.Material.Brick, wallColor, true)
			end
			-- West wall (also covers the outer border on column 1).
			if cell.W then
				local cframe = origin * CFrame.new((x - 1) * cellSize, wallHeight / 2, center.Z)
				newPart(Vector3.new(wallThickness, wallHeight, cellSize + wallThickness), cframe, wallsFolder, `Wall_W_{x}_{y}`, Enum.Material.Brick, wallColor, true)
			end
			-- Only the last column/row need to close off the East/South border;
			-- interior East/South walls are already covered by the neighbor's West/North wall.
			if cell.E and x == width then
				local cframe = origin * CFrame.new(x * cellSize, wallHeight / 2, center.Z)
				newPart(Vector3.new(wallThickness, wallHeight, cellSize + wallThickness), cframe, wallsFolder, `Wall_E_{x}_{y}`, Enum.Material.Brick, wallColor, true)
			end
			if cell.S and y == height then
				local cframe = origin * CFrame.new(center.X, wallHeight / 2, y * cellSize)
				newPart(Vector3.new(cellSize + wallThickness, wallHeight, wallThickness), cframe, wallsFolder, `Wall_S_{x}_{y}`, Enum.Material.Brick, wallColor, true)
			end
		end
	end

	-- Start point: cell (1,1). End point: cell (width,height).
	local startCenter = cellCenter(1, 1)
	local endCenter = cellCenter(width, height)

	local startCFrame = origin * CFrame.new(startCenter.X, 3, startCenter.Z)
	local endCFrame = origin * CFrame.new(endCenter.X, 3, endCenter.Z)

	local startPart = newPart(Vector3.new(cellSize * 0.6, 0.2, cellSize * 0.6), startCFrame * CFrame.new(0, -2.8, 0), model, "StartPoint", Enum.Material.Neon, Color3.fromRGB(0, 200, 0), false)
	startPart.Transparency = 0.3

	local endPart = newPart(Vector3.new(cellSize * 0.6, 0.2, cellSize * 0.6), endCFrame * CFrame.new(0, -2.8, 0), model, "EndPoint", Enum.Material.Neon, Color3.fromRGB(200, 170, 0), false)
	endPart.Transparency = 0.3
	endPart:SetAttribute("IsMazeEnd", true)

	model.PrimaryPart = model.Floor :: Part

	return {
		model = model,
		startCFrame = startCFrame,
		endCFrame = endCFrame,
		width = width,
		height = height,
	}
end

return MazeGenerator
