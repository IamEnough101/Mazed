--!strict
--[[
	TeleportService.lua
	NOTE: this is in-place teleportation within a single place (CFrame
	moves), not Roblox's cross-place TeleportService API. Maze Eggs keeps
	the lobby and every active maze in the same place for instant transitions.
]]

local LOBBY_SPAWN_CFRAME = CFrame.new(0, 5, 0)

local TeleportService = {}

local function getHumanoidRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function TeleportService.TeleportTo(player: Player, cframe: CFrame)
	local root = getHumanoidRootPart(player)
	if not root then
		return
	end
	root.CFrame = cframe + Vector3.new(0, 3, 0)
	root.AssemblyLinearVelocity = Vector3.zero
end

function TeleportService.TeleportToMaze(player: Player, startCFrame: CFrame)
	TeleportService.TeleportTo(player, startCFrame)
end

function TeleportService.TeleportToLobby(player: Player)
	TeleportService.TeleportTo(player, LOBBY_SPAWN_CFRAME)
end

TeleportService.LobbySpawnCFrame = LOBBY_SPAWN_CFRAME

return TeleportService
