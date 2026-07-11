--!strict
--[[
	TimerUI.lua
	Top-center countdown bar shown while the player is inside a maze.
	Hidden by default; MazeService's TimerUpdate event drives visibility
	implicitly (first tick shows it, MazeCompleted/MazeFailed hide it).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local UIBuilder = require(script.Parent.UIBuilder)
local UITheme = require(script.Parent.UITheme)

local TimerUI = {}

local LOW_TIME_THRESHOLD = 10

function TimerUI.Mount(screenGui: ScreenGui)
	local container = UIBuilder.Frame({
		Name = "TimerContainer",
		Size = UDim2.new(0, 300, 0, 40),
		Position = UDim2.new(0.5, -150, 0, 20),
		BackgroundColor3 = UITheme.Panel,
		Visible = false,
	}, screenGui)
	UIBuilder.Corner(8, container)

	local barBackground = UIBuilder.Frame({
		Name = "BarBackground",
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	}, container)
	UIBuilder.Corner(6, barBackground)

	local barFill = UIBuilder.Frame({
		Name = "BarFill",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = UITheme.Accent,
	}, barBackground)
	UIBuilder.Corner(6, barFill)

	local label = UIBuilder.Label({
		Name = "TimerLabel",
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0s",
	}, container)
	label.ZIndex = 2

	local maxSeconds = 1

	RemoteEvents.TimerUpdate.OnClientEvent:Connect(function(secondsRemaining: number)
		if not container.Visible then
			container.Visible = true
			maxSeconds = math.max(secondsRemaining, 1)
		end

		label.Text = `{secondsRemaining}s`

		local fraction = math.clamp(secondsRemaining / maxSeconds, 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.3), { Size = UDim2.new(fraction, 0, 1, 0) }):Play()

		barFill.BackgroundColor3 = if secondsRemaining <= LOW_TIME_THRESHOLD then UITheme.Danger else UITheme.Accent

		if secondsRemaining <= 0 then
			task.delay(1, function()
				container.Visible = false
			end)
		end
	end)

	RemoteEvents.MazeCompleted.OnClientEvent:Connect(function()
		container.Visible = false
	end)

	RemoteEvents.MazeFailed.OnClientEvent:Connect(function()
		container.Visible = false
	end)

	return container
end

return TimerUI
