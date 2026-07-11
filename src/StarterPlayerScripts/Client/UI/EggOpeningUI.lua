--!strict
--[[
	EggOpeningUI.lua
	Full-screen egg-opening animation: the egg icon shakes with increasing
	intensity, "cracks" open (a quick scale pop), then reveals the rolled
	rarity / mutation / difficulty / timer, color-coded via UITheme.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)
local UIBuilder = require(script.Parent.UIBuilder)
local UITheme = require(script.Parent.UITheme)

local EggOpeningUI = {}

local SHAKE_DURATION = 1.2
local SHAKE_STEPS = 14

function EggOpeningUI.Mount(screenGui: ScreenGui)
	local overlay = UIBuilder.Frame({
		Name = "EggOpeningOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.35,
		Visible = false,
		ZIndex = 10,
	}, screenGui)

	local eggIcon = UIBuilder.Label({
		Name = "EggIcon",
		Size = UDim2.fromOffset(160, 160),
		Position = UDim2.new(0.5, -80, 0.5, -140),
		BackgroundTransparency = 1,
		Text = "\u{1F95A}",
		TextSize = 120,
		ZIndex = 11,
	}, overlay)

	local resultPanel = UIBuilder.Frame({
		Name = "ResultPanel",
		Size = UDim2.fromOffset(360, 220),
		Position = UDim2.new(0.5, -180, 0.5, 40),
		BackgroundColor3 = UITheme.Panel,
		Visible = false,
		ZIndex = 11,
	}, overlay)
	UIBuilder.Corner(12, resultPanel)

	local rarityLabel = UIBuilder.Label({
		Name = "RarityLabel",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 10),
		TextSize = 28,
		Text = "",
	}, resultPanel)

	local mutationLabel = UIBuilder.Label({
		Name = "MutationLabel",
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 0, 55),
		TextSize = 20,
		Text = "",
	}, resultPanel)

	local difficultyLabel = UIBuilder.Label({
		Name = "DifficultyLabel",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 90),
		TextColor3 = UITheme.Text,
		TextSize = 18,
		Text = "",
	}, resultPanel)

	local timerLabel = UIBuilder.Label({
		Name = "TimerLabel",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 116),
		TextColor3 = UITheme.Text,
		TextSize = 18,
		Text = "",
	}, resultPanel)

	local continueButton = UIBuilder.Button({
		Name = "ContinueButton",
		Size = UDim2.new(0, 160, 0, 40),
		Position = UDim2.new(0.5, -80, 1, -55),
		BackgroundColor3 = UITheme.Accent,
		Text = "Continue",
	}, resultPanel)
	UIBuilder.Corner(8, continueButton)

	local function shakeEgg(): ()
		for step = 1, SHAKE_STEPS do
			local intensity = (step / SHAKE_STEPS) * 12
			local offsetX = math.random(-1, 1) * intensity
			local offsetY = math.random(-1, 1) * intensity
			eggIcon.Position = UDim2.new(0.5, -80 + offsetX, 0.5, -140 + offsetY)
			task.wait(SHAKE_DURATION / SHAKE_STEPS)
		end
	end

	local function crackPop(): ()
		local popTween = TweenService:Create(eggIcon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(220, 220),
			TextTransparency = 1,
		})
		popTween:Play()
		popTween.Completed:Wait()
	end

	local function showResult(mazeRecord: any)
		local rarityColor = UITheme.RarityColors[mazeRecord.rarity] or UITheme.Text
		rarityLabel.Text = mazeRecord.rarity
		rarityLabel.TextColor3 = rarityColor

		if mazeRecord.mutation ~= "None" then
			mutationLabel.Text = `\u{2728} {mazeRecord.mutation} Mutation`
			mutationLabel.TextColor3 = UITheme.MutationColors[mazeRecord.mutation] or UITheme.Text
		else
			mutationLabel.Text = ""
		end

		difficultyLabel.Text = `Difficulty: {mazeRecord.difficulty}`
		timerLabel.Text = `Timer: {mazeRecord.timerSeconds}s  |  Base Reward: {mazeRecord.potentialBaseCoins}`

		resultPanel.Visible = true
	end

	RemoteEvents.EggOpened.OnClientEvent:Connect(function(mazeRecord: any)
		overlay.Visible = true
		resultPanel.Visible = false
		eggIcon.Size = UDim2.fromOffset(160, 160)
		eggIcon.TextTransparency = 0
		eggIcon.Position = UDim2.new(0.5, -80, 0.5, -140)

		task.spawn(function()
			shakeEgg()
			crackPop()
			showResult(mazeRecord)
		end)
	end)

	continueButton.MouseButton1Click:Connect(function()
		overlay.Visible = false
	end)

	return overlay
end

return EggOpeningUI
