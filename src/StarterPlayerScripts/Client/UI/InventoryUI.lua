--!strict
--[[
	InventoryUI.lua
	Lists mazes the player owns but hasn't played yet. Clicking "Play"
	invokes the PlayMaze RemoteFunction, which teleports the player in
	server-side if the request is valid.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local UIBuilder = require(script.Parent.UIBuilder)
local UITheme = require(script.Parent.UITheme)

local InventoryUI = {}

function InventoryUI.Mount(screenGui: ScreenGui)
	local panel = UIBuilder.Frame({
		Name = "InventoryPanel",
		Size = UDim2.fromOffset(340, 420),
		Position = UDim2.new(0, 20, 0.5, -210),
		BackgroundColor3 = UITheme.Panel,
		Visible = false,
		ZIndex = 5,
	}, screenGui)
	UIBuilder.Corner(12, panel)

	UIBuilder.Label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 40),
		Text = "Maze Inventory",
		TextSize = 24,
	}, panel)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "MazeList"
	scroll.Size = UDim2.new(1, -20, 1, -60)
	scroll.Position = UDim2.new(0, 10, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.Parent = panel
	listLayout.Parent = scroll

	local statusLabel = UIBuilder.Label({
		Name = "StatusLabel",
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.new(0, 10, 1, -24),
		TextSize = 14,
		TextColor3 = UITheme.Danger,
		Text = "",
	}, panel)

	local function rebuild(inventory: { any })
		scroll:ClearAllChildren()
		listLayout.Parent = scroll
		scroll.CanvasSize = UDim2.new(0, 0, 0, #inventory * 76)

		for index, mazeRecord in ipairs(inventory) do
			local row = UIBuilder.Frame({
				Name = "Row" .. index,
				Size = UDim2.new(1, 0, 0, 68),
				LayoutOrder = index,
				BackgroundColor3 = Color3.fromRGB(46, 46, 54),
			}, scroll)
			UIBuilder.Corner(8, row)

			local rarityColor = UITheme.RarityColors[mazeRecord.rarity] or UITheme.Text
			UIBuilder.Label({
				Size = UDim2.new(0.6, 0, 0, 22),
				Position = UDim2.new(0, 12, 0, 6),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = rarityColor,
				Text = `{mazeRecord.rarity} {mazeRecord.difficulty}`,
			}, row)

			local mutationText = mazeRecord.mutation ~= "None" and `\u{2728} {mazeRecord.mutation}` or ""
			UIBuilder.Label({
				Size = UDim2.new(0.6, 0, 0, 18),
				Position = UDim2.new(0, 12, 0, 28),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = UITheme.MutationColors[mazeRecord.mutation] or UITheme.Text,
				TextSize = 14,
				Text = mutationText,
			}, row)

			UIBuilder.Label({
				Size = UDim2.new(0.6, 0, 0, 16),
				Position = UDim2.new(0, 12, 0, 46),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 13,
				TextColor3 = UITheme.Text,
				Text = `Timer: {mazeRecord.timerSeconds}s`,
			}, row)

			local playButton = UIBuilder.Button({
				Size = UDim2.new(0, 90, 0, 40),
				Position = UDim2.new(1, -100, 0.5, -20),
				BackgroundColor3 = UITheme.Accent,
				Text = "Play",
			}, row)
			UIBuilder.Corner(6, playButton)

			playButton.MouseButton1Click:Connect(function()
				playButton.Active = false
				local ok, success, message = pcall(function()
					return RemoteEvents.PlayMaze:InvokeServer(mazeRecord.id)
				end)
				playButton.Active = true

				if not ok then
					statusLabel.Text = "Network error, try again"
				elseif not success then
					statusLabel.Text = message
				else
					statusLabel.Text = ""
					panel.Visible = false
				end
			end)
		end
	end

	RemoteEvents.InventoryUpdated.OnClientEvent:Connect(rebuild)

	local function toggle()
		panel.Visible = not panel.Visible
	end

	return panel, toggle
end

return InventoryUI
