--!strict
--[[
	CoinsUI.lua
	Top-left coin counter. Listens for RemoteEvents.CoinsUpdated and
	animates the displayed number counting up/down toward the new total.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local UIBuilder = require(script.Parent.UIBuilder)
local UITheme = require(script.Parent.UITheme)

local CoinsUI = {}

function CoinsUI.Mount(screenGui: ScreenGui)
	local container = UIBuilder.Frame({
		Name = "CoinsContainer",
		Size = UDim2.new(0, 200, 0, 50),
		Position = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = UITheme.Panel,
	}, screenGui)
	UIBuilder.Corner(10, container)

	local label = UIBuilder.Label({
		Name = "CoinsLabel",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 22,
		Text = "\u{1FA99} 0",
	}, container)

	-- NumberValue gives TweenService a real tweenable Instance property to
	-- animate; the label text just mirrors its current value every frame.
	local displayedValue = Instance.new("NumberValue")
	displayedValue.Value = 0
	displayedValue.Parent = container

	RemoteEvents.CoinsUpdated.OnClientEvent:Connect(function(coins: number)
		local tween = TweenService:Create(displayedValue, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Value = coins })
		tween:Play()
	end)

	game:GetService("RunService").Heartbeat:Connect(function()
		label.Text = `\u{1FA99} {math.floor(displayedValue.Value)}`
	end)

	return container
end

return CoinsUI
