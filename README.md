# Mazed — Maze Eggs

A Roblox (Luau) game: open eggs to receive procedurally generated 3D mazes,
race a countdown timer to complete each one, earn coins, and buy better eggs.

Full write-up: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)
Balancing / future ideas / UX / sound notes: [`docs/DEVELOPER_NOTES.md`](docs/DEVELOPER_NOTES.md)
Machine-readable config (tiers, multipliers, formulas): [`docs/config.json`](docs/config.json)
Example objects and a worked progression: [`docs/examples.json`](docs/examples.json)

## Quick facts

- **Rarities**: Common, Uncommon, Rare, Epic, Legendary, Mythic (x1.0 → x3.0 coin multiplier)
- **Mutations**: Silver, Gold, Diamond, Emerald (bonus coins, less time)
- **Difficulties**: Easy, Medium, Hard, Extreme (base coins + base timer + grid size)
- **Eggs**: Basic (free first) → Bronze → Silver → Gold → Diamond → Emerald
- **Coins** = `(BaseDifficultyCoins * RarityMultiplier * MutationMultiplier) + TimeRemaining`
- **Timer** = `max(MinimumTimerSeconds, BaseDifficultyTimer - MutationPenalty)`

## Project layout

```
default.project.json            -- Rojo project file
src/
  ReplicatedStorage/
    Config/GameConfig.lua       -- single source of truth for every tier/multiplier
    Modules/                    -- rarity/mutation/difficulty rolls, coin math, maze generation
    Remotes/RemoteEvents.lua    -- shared RemoteEvent/RemoteFunction definitions
  ServerScriptService/
    Main.server.lua             -- server boot sequence
    Services/                   -- player data, shop, inventory, maze runs, timer, teleport
  StarterPlayerScripts/
    Client/
      Main.client.lua           -- client boot sequence
      CameraController.lua      -- custom third-person camera
      MovementController.lua    -- sprint + humanoid tuning
      UI/                       -- coins, timer, egg-opening, shop, inventory panels
docs/
  GAME_DESIGN.md                -- full system explanation
  DEVELOPER_NOTES.md            -- balancing, future ideas, UI/UX, sound/FX
  config.json                   -- all tiers/multipliers/timers/formulas as JSON
  examples.json                 -- example maze/egg objects + a worked player progression
```

## Running it in Roblox Studio

1. Install [Rojo](https://rojo.space/) (CLI + the Studio plugin, or the VS Code extension).
2. From this repo's root, run:
   ```
   rojo serve
   ```
3. In Roblox Studio, connect via the Rojo plugin (or run
   `rojo build -o MazeEggs.rbxlx` to produce a place file you can open directly).
4. Press Play. `Main.server.lua` boots every service; `Main.client.lua` boots
   the camera, movement, and UI.

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Space | Jump |
| Left Shift (hold) | Sprint |
| Mouse | Look / orbit camera |
| B | Toggle Shop |
| I | Toggle Inventory |
