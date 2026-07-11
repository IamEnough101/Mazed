--!strict
--[[
	UIBuilder.lua
	Small helpers for procedurally creating GuiObjects so each UI module
	doesn't repeat the same Instance.new/property boilerplate.
]]

local UIBuilder = {}

function UIBuilder.Frame(props: { [string]: any }, parent: Instance?): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(36, 36, 42)
	frame.BorderSizePixel = 0
	for key, value in pairs(props) do
		(frame :: any)[key] = value
	end
	frame.Parent = parent
	return frame
end

function UIBuilder.Corner(radius: number, parent: Instance): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function UIBuilder.Label(props: { [string]: any }, parent: Instance?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(240, 240, 245)
	label.TextScaled = false
	label.TextSize = 18
	for key, value in pairs(props) do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

function UIBuilder.Button(props: { [string]: any }, parent: Instance?): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(240, 240, 245)
	button.TextSize = 16
	for key, value in pairs(props) do
		(button :: any)[key] = value
	end
	button.Parent = parent
	return button
end

return UIBuilder
