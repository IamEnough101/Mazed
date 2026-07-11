--!strict
--[[
	TimerService.lua
	Runs a per-player countdown for their active maze run. Ticks once per
	second over TimerUpdate so the client UI can render a live countdown,
	and invokes an onExpire callback if the player runs out of time before
	finishing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage.Remotes.RemoteEvents)

local TimerService = {}

type TimerState = {
	remaining: number,
	active: boolean,
}

local timers: { [Player]: TimerState } = {}

-- Starts (or restarts) a countdown for `player`. `onExpire` fires exactly
-- once, only if the timer reaches 0 while still active (i.e. wasn't
-- stopped early by TimerService.Stop).
function TimerService.Start(player: Player, totalSeconds: number, onExpire: (() -> ())?)
	TimerService.Stop(player)

	local state: TimerState = { remaining = totalSeconds, active = true }
	timers[player] = state

	task.spawn(function()
		while state.active and state.remaining > 0 do
			RemoteEvents.TimerUpdate:FireClient(player, state.remaining)
			task.wait(1)
			if state.active then
				state.remaining -= 1
			end
		end

		if state.active then
			state.active = false
			RemoteEvents.TimerUpdate:FireClient(player, 0)
			if onExpire then
				onExpire()
			end
		end
	end)
end

-- Stops the countdown early (e.g. the player finished the maze) and
-- returns how many whole seconds were left.
function TimerService.Stop(player: Player): number
	local state = timers[player]
	if not state then
		return 0
	end
	state.active = false
	timers[player] = nil
	return math.max(0, state.remaining)
end

function TimerService.GetRemaining(player: Player): number
	local state = timers[player]
	return state and state.remaining or 0
end

return TimerService
