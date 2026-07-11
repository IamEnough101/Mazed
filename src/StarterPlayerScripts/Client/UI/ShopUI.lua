--!strict
--[[
	ShopUI.lua
	Egg shop panel. Each row invokes the BuyEgg RemoteFunction and reports
	the server's success/failure message back to the player.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local UIBuilder = require(script.Parent.UIBuilder)
local UITheme = require(script.Parent.UITheme)

local ShopUI = {}

function ShopUI.Mount(screenGui: ScreenGui)
	local panel = UIBuilder.Frame({
		Name = "ShopPanel",
		Size = UDim2.fromOffset(340, 420),
		Position = UDim2.new(1, -360, 0.5, -210),
		BackgroundColor3 = UITheme.Panel,
		Visible = false,
		ZIndex = 5,
	}, screenGui)
	UIBuilder.Corner(12, panel)

	UIBuilder.Label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 40),
		Text = "Egg Shop",
		TextSize = 24,
	}, panel)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "EggList"
	scroll.Size = UDim2.new(1, -20, 1, -60)
	scroll.Position = UDim2.new(0, 10, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.Eggs * 66)
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

	for index, eggName in ipairs(GameConfig.Eggs) do
		local eggData = GameConfig.EggData[eggName]

		local row = UIBuilder.Frame({
			Name = eggName .. "Row",
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = index,
			BackgroundColor3 = Color3.fromRGB(46, 46, 54),
		}, scroll)
		UIBuilder.Corner(8, row)

		UIBuilder.Label({
			Size = UDim2.new(0.6, 0, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = `{eggName} Egg{eggData.freeFirstEgg and "  (first: FREE)" or ""}`,
		}, row)

		local buyButton = UIBuilder.Button({
			Size = UDim2.new(0, 110, 0, 40),
			Position = UDim2.new(1, -120, 0.5, -20),
			BackgroundColor3 = UITheme.Accent,
			Text = `\u{1FA99} {eggData.cost}`,
		}, row)
		UIBuilder.Corner(6, buyButton)

		buyButton.MouseButton1Click:Connect(function()
			buyButton.Text = "..."
			buyButton.Active = false
			local ok, success, message = pcall(function()
				return RemoteEvents.BuyEgg:InvokeServer(eggName)
			end)
			buyButton.Active = true
			buyButton.Text = `\u{1FA99} {eggData.cost}`

			if not ok then
				statusLabel.Text = "Network error, try again"
			elseif not success then
				statusLabel.Text = message
			else
				statusLabel.Text = ""
			end
		end)
	end

	local function toggle()
		panel.Visible = not panel.Visible
	end

	return panel, toggle
end

return ShopUI
