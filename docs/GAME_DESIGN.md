# Maze Eggs — Game Design & System Reference

Maze Eggs is a Roblox (Luau) game. Players open eggs to receive procedurally
generated 3D mazes, then race a countdown timer to complete each maze for a
coin reward. Coins buy better eggs, which roll better rarities, mutations,
and difficulties.

This document is the full system explanation. Machine-readable versions of
the same data live in `docs/config.json` (all tiers/multipliers/formulas)
and `docs/examples.json` (example objects and a worked progression).

---

## 1. Architecture

The project is a [Rojo](https://rojo.space/) project (`default.project.json`)
so it maps 1:1 onto Roblox Studio's instance tree:

| Folder | Roblox service | Contents |
|---|---|---|
| `src/ReplicatedStorage` | `ReplicatedStorage` | Shared config + pure logic modules used by both server and client |
| `src/ServerScriptService` | `ServerScriptService` | Server-authoritative services (data, shop, maze runs) |
| `src/StarterPlayerScripts` | `StarterPlayer.StarterPlayerScripts` | Client controllers and UI |

Everything that determines a reward (egg rolls, coin math, timer math) runs
**only** on the server. The client only ever receives the *result* of a roll
over a `RemoteEvent`/`RemoteFunction` — it never rolls rarity/mutation itself,
which prevents client-side reward manipulation.

### Module map

```
ReplicatedStorage/
  Config/GameConfig.lua        -- single source of truth for every tunable number
  Modules/
    WeightedRandom.lua         -- generic weighted-random picker
    RaritySystem.lua           -- rolls + multiplier lookup for rarity
    MutationSystem.lua         -- rolls + multiplier/penalty lookup for mutation
    DifficultySystem.lua       -- rolls + base coin/timer lookup for difficulty
    CoinCalculator.lua         -- Coins/Timer formulas (pure functions)
    EggSystem.lua              -- ties the above into a "MazeRecord"
    MazeGenerator.lua          -- grid maze algorithm + 3D part instantiation
  Remotes/RemoteEvents.lua     -- creates/fetches every RemoteEvent/RemoteFunction

ServerScriptService/
  Main.server.lua              -- boot sequence
  Services/
    PlayerDataService.lua      -- DataStore-backed profile (coins, flags, inventory)
    InventoryService.lua       -- facade over inventory storage
    ShopService.lua            -- BuyEgg RemoteFunction handler
    MazeService.lua            -- PlayMaze RemoteFunction handler, run lifecycle
    TimerService.lua           -- per-player countdown + expiry callback
    TeleportService.lua        -- in-place CFrame teleport (lobby <-> maze)

StarterPlayerScripts/Client/
  Main.client.lua               -- boot sequence, hotkeys
  CameraController.lua          -- third-person camera
  MovementController.lua        -- sprint + humanoid tuning
  UI/
    UITheme.lua, UIBuilder.lua  -- shared style + instance helpers
    CoinsUI.lua, TimerUI.lua
    EggOpeningUI.lua
    ShopUI.lua, InventoryUI.lua
```

---

## 2. Core loop

1. Player spawns in the lobby with **0 coins** and receives one **free Basic
   Egg** on first join (`ShopService.PurchaseEgg` waives the cost when
   `freeFirstEgg` is true and the player hasn't claimed it yet).
2. Player opens an egg (`BuyEgg` RemoteFunction). The server rolls
   **rarity**, **mutation**, and **difficulty** independently, computes the
   maze's **timer**, and stores a `MazeRecord` in the player's inventory.
   The client plays an egg-opening animation and reveals the result.
3. Player selects a maze from their inventory (`PlayMaze` RemoteFunction).
   The server regenerates the maze's 3D geometry from its stored seed,
   teleports the player in, and starts the countdown.
4. Player navigates the maze in third person. Touching the `EndPoint` part
   before the timer hits 0 completes the maze; the server computes coins
   from the **Coins formula**, credits the player, removes the maze from
   inventory, and teleports the player back to the lobby.
5. If the timer expires first, the maze is marked failed, no reward is
   given, and the player is teleported back out.
6. Coins buy better eggs (Shop UI, hotkey **B**), which raises the odds of
   higher rarities/mutations/difficulties. Inventory UI (hotkey **I**) lists
   unplayed mazes.

---

## 3. Rarity, Mutation, Difficulty, Egg tables

See `docs/config.json` for the machine-readable version. Summary:

**Rarity multipliers** — Common x1.0, Uncommon x1.1, Rare x1.25, Epic x1.5,
Legendary x2.0, Mythic x3.0.

**Mutations** (order lowest→highest: Silver, Gold, Diamond, Emerald) — each
has a coin multiplier, a timer penalty in seconds, and a global base chance:

| Mutation | Coin multiplier | Timer penalty | Base chance |
|---|---|---|---|
| Silver | x1.2 | -5s | 10% |
| Gold | x1.5 | -10s | 4% |
| Diamond | x2.0 | -15s | 1% |
| Emerald | x3.0 | -20s | 0.2% |

**Difficulty tiers** — Easy (10 coins / 45s), Medium (25 coins / 60s), Hard
(50 coins / 75s), Extreme (100 coins / 90s). Difficulty also selects the
maze's grid size (`GameConfig.GridSizeByDifficulty`): 8x8 up to 20x20 cells.

**Eggs** — Basic (free first / 50), Bronze (150), Silver (500), Gold (1500),
Diamond (5000), Emerald (15000). Each egg has:
- `rarityWeights` — relative weights for the rarity roll.
- `difficultyWeights` — relative weights for the difficulty roll.
- `luckMultiplier` — multiplies the weight of Epic+ rarities *and* every
  mutation's base chance when this egg is opened. This is how "better eggs
  give better mutation/rarity odds" is implemented without hardcoding a
  second full odds table per egg for mutations.

---

## 4. Formulas

```
Coins = (BaseDifficultyCoins * RarityMultiplier * MutationMultiplier) + (TimeRemaining * 1)
Timer = max(MinimumTimerSeconds, BaseDifficultyTimer - MutationPenalty)
```

Both are pure functions in `CoinCalculator.lua` — same inputs always produce
the same output, which keeps rewards auditable and testable. `MinimumTimerSeconds`
(10s) exists purely as a safety floor; no current mutation/difficulty
combination actually reaches it (worst case is Easy + Emerald = 45 - 20 = 25s).

---

## 5. Maze generation

`MazeGenerator.lua` builds the logical maze with an **iterative
recursive-backtracker**: starting at cell (1,1), it repeatedly carves a
passage to a random unvisited neighbor, pushing onto an explicit stack (not
Lua's call stack, so grids up to 20x20 = 400 cells never risk a stack
overflow) and backtracking on dead ends until every cell has been visited.
This guarantees a **perfect maze** — exactly one path between any two cells,
no loops, no isolated regions.

The same function is seeded with `Random.new(seed)`, and the seed is stored
in the `MazeRecord` rather than the geometry itself. This means:
- Opening an egg is cheap (just roll + store a small record).
- Geometry is only built when a player actually enters that specific maze,
  and is destroyed again on completion/failure — no wasted parts sitting in
  `Workspace` for mazes nobody is currently playing.
- The exact same maze can be regenerated deterministically if needed (e.g.
  for a "replay" feature).

3D instantiation: one `Part` for the floor spanning the whole grid, one for
the ceiling at `MazeWallHeight` studs up, and individual wall `Part`s placed
only where the logical grid says a wall exists (interior walls are shared
between neighboring cells so they're only placed once). `StartPoint` and
`EndPoint` are non-collidable marker parts at cell (1,1) and (width,height);
`EndPoint` carries an `IsMazeEnd` attribute and its `Touched` event is what
`MazeService` listens to for completion.

Each player's active maze is offset along the X axis by
`player.UserId % 1000 * 1000` studs so multiple concurrent maze runs never
overlap in `Workspace`.

---

## 6. Player controller

- **Movement**: WASD walking and Space-bar jumping are left to Roblox's
  default `Humanoid`/`ControlModule` — `MovementController.lua` only tunes
  `WalkSpeed` (16 studs/s, 26 while sprinting) and `JumpPower` (50), and
  toggles sprint on Left Shift. Collision with maze walls is automatic:
  Roblox's physics engine collides any two parts with `CanCollide = true`,
  and every wall/floor/ceiling part `MazeGenerator` builds sets that flag.
- **Camera**: `CameraController.lua` implements a from-scratch third-person
  orbit camera (`Camera.CameraType = Scriptable`) — mouse movement drives
  yaw/pitch, the desired position is `focusPoint + backDirection * distance`,
  and a raycast from the focus point to that desired position pulls the
  camera closer whenever a wall would otherwise clip through it. The camera
  CFrame is eased toward the desired CFrame every frame using exponential
  damping (`1 - exp(-k * dt)`), which stays smooth regardless of frame rate.

---

## 7. UI

All UI is built procedurally in Luau (no manual Studio GUI construction
required) so the whole client is reproducible from source:

- **CoinsUI** — top-left counter, animates via a tweened `NumberValue`.
- **TimerUI** — top-center countdown bar, turns red under 10s, hidden
  outside of an active maze run.
- **EggOpeningUI** — full-screen overlay: the egg icon shakes with
  increasing intensity, "cracks" (a `Back`-eased scale pop), then reveals
  rarity (rarity-colored), mutation (mutation-colored, hidden if `None`),
  difficulty, timer, and potential base reward.
- **ShopUI** (hotkey **B**) — one row per egg, buy button invokes `BuyEgg`.
- **InventoryUI** (hotkey **I**) — one row per unplayed maze, Play button
  invokes `PlayMaze`.

`UITheme.lua` centralizes the rarity/mutation color palette so all three
panels render a given rarity/mutation identically.

---

## 8. Teleportation

Maze Eggs keeps the lobby and every active maze instance in the **same
place** — `TeleportService.lua` (server) is a small CFrame-teleport helper,
*not* Roblox's cross-place `TeleportService` API. `TeleportToMaze` moves the
player to the generated maze's `StartPoint`; `TeleportToLobby` returns them
to a fixed lobby spawn CFrame after completion, failure, or disconnect
cleanup.

---

## 9. Running the project

1. Install [Rojo](https://rojo.space/) (VS Code extension or CLI) and Roblox
   Studio.
2. Open this repo's folder in VS Code, run `rojo serve`, then connect from
   the Rojo Studio plugin (or run `rojo build -o MazeEggs.rbxlx` to produce
   a place file directly).
3. Press Play in Studio — `Main.server.lua` boots all services,
   `Main.client.lua` boots the camera/movement/UI.
