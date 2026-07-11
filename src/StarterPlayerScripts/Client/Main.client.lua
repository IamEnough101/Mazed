--!strict
--[[
	Main.client.lua
	Client entry point: starts the camera/movement controllers, builds the
	root ScreenGui, mounts every UI panel, and wires the Shop/Inventory
	toggle hotkeys (B and I).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local CameraController = require(script.Parent.CameraController)
local MovementController = require(script.Parent.MovementController)

local UI = script.Parent.UI
local CoinsUI = require(UI.CoinsUI)
local TimerUI = require(UI.TimerUI)
local EggOpeningUI = require(UI.EggOpeningUI)
local ShopUI = require(UI.ShopUI)
local InventoryUI = require(UI.InventoryUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

CameraController.Start()
MovementController.Start()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MazeEggsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

CoinsUI.Mount(screenGui)
TimerUI.Mount(screenGui)
EggOpeningUI.Mount(screenGui)
local _shopPanel, toggleShop = ShopUI.Mount(screenGui)
local _inventoryPanel, toggleInventory = InventoryUI.Mount(screenGui)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		toggleShop()
	elseif input.KeyCode == Enum.KeyCode.I then
		toggleInventory()
	end
end)
