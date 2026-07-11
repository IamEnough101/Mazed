--!strict
--[[
	UITheme.lua
	Shared color palette for rarities/mutations so every UI panel
	(egg opening, inventory, shop) renders them identically.
]]

local UITheme = {}

local rarityColors: { [string]: Color3 } = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 220, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
}
UITheme.RarityColors = rarityColors

local mutationColors: { [string]: Color3 } = {
	None = Color3.fromRGB(255, 255, 255),
	Silver = Color3.fromRGB(192, 192, 192),
	Gold = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(120, 220, 255),
	Emerald = Color3.fromRGB(40, 220, 120),
}
UITheme.MutationColors = mutationColors

UITheme.Background = Color3.fromRGB(24, 24, 28)
UITheme.Panel = Color3.fromRGB(36, 36, 42)
UITheme.Accent = Color3.fromRGB(90, 160, 255)
UITheme.Text = Color3.fromRGB(240, 240, 245)
UITheme.Danger = Color3.fromRGB(230, 70, 70)

return UITheme
