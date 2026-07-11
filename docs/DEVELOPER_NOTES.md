# Developer Notes

## Balancing suggestions

- **Grind curve check**: a fresh player earns roughly 50-80 coins per Easy/
  Medium maze (see `docs/examples.json`). A Bronze Egg (150) takes ~2 runs,
  Silver (500) ~7-10 runs, Gold (1500) ~25+ runs. If playtesting shows the
  Silver→Gold gap drags, either raise Bronze/Silver egg `difficultyWeights`
  toward Medium/Hard, or add a small "daily bonus maze" with an inflated
  `potentialBaseCoins` to smooth the curve rather than cutting egg prices
  (cutting prices devalues the coin economy long-term more than a one-off
  bonus does).
- **Mutation odds are global, scaled by luckMultiplier** — double-check the
  effective Emerald chance on the Emerald Egg (0.2% × 4.0 = 0.8%) still
  feels rare enough at scale; if players report frequent Emeralds, lower
  `luckMultiplier` before touching the global `baseChance` (the global
  values are meant to stay stable reference points across all eggs).
  Watch the combined mutation probability mass on Emerald Egg (~60.8% of
  *some* mutation) — that egg is intentionally mutation-forward; if it
  starts feeling like the "no mutation" case never happens, tighten
  `luckMultiplier` down from 4.0.
- **Rarity weight tables are relative, not normalized to 10,000** — when
  adding a new egg, weights just need to be *internally consistent* (higher
  weight = more common relative to that egg's other rarities); they don't
  need to sum to a fixed total.
- **Timer floor headroom** — worst case today (Easy + Emerald) still leaves
  25s, well above the 10s `MinimumTimerSeconds` floor. If a future
  difficulty/mutation combo gets close to the floor, that maze becomes
  nearly unplayable regardless of skill — treat the floor as a hard
  design constraint, not just a safety net.
- **Coin rounding**: `CoinCalculator.CalculateCoins` rounds to the nearest
  whole coin (`floor(x + 0.5)`). Keep base coin values as whole numbers so
  the only source of fractional rewards is the rarity/mutation multipliers.

## Future update ideas

- **Maze mutation stacking visuals in the maze itself** (e.g. Emerald mazes
  get particle-lit walls) so mutation is legible during the run, not just on
  the reveal screen.
- **Leaderboards** per difficulty/rarity combo (fastest clear, most coins in
  a single run) using `OrderedDataStore`.
- **Trading/gifting mazes** between players before they're played — the
  `MazeRecord` already carries everything needed (seed, rolls) to hand off
  cleanly; would need a trade-request RemoteFunction pair and a hold on the
  record during negotiation.
- **Seasonal eggs** — same `EggData` shape, time-limited availability flag,
  reuses 100% of `EggSystem`/`ShopService` with no core changes.
- **Co-op mazes** — multiple players racing (or cooperating) inside one
  maze instance; `MazeService` already isolates instances per owner, so
  this would mean keying `activeRuns`/`activeMazesFolder` slots by party
  instead of by single player.
- **Checkpoints inside long (Hard/Extreme) mazes** so a disconnect or death
  doesn't force a full restart — store the last checkpoint CFrame server-side
  per active run.

## UI/UX suggestions

- Add a small egg-cost affordability indicator in `ShopUI` (gray out /
  red-tint the buy button when `coins < cost`) instead of only surfacing the
  failure after a click.
- Surface the rolled maze's rarity color as a border/glow on its
  `InventoryUI` row at a glance, not just the text color, for faster
  scanning once a player has 10+ mazes queued up.
- Add a confirmation step before spending on Silver+ eggs (misclicks on a
  15,000-coin Emerald Egg are expensive) — a simple "Confirm Purchase" modal
  reusing `UIBuilder` is enough.
- Show a persistent "best pending maze" badge (highest rarity currently in
  inventory) near the Inventory hotkey so players know they're sitting on
  something good without opening the panel.

## Sound/FX suggestions

- Egg opening: rising pitch/tempo tick per shake step (`EggOpeningUI.shakeEgg`
  already has a natural per-step hook to fire a sound), then a distinct
  crack/pop SFX synced to `crackPop`'s tween, layered with a rarity-tiered
  jingle (short chime for Common/Uncommon, a fuller fanfare for
  Legendary/Mythic).
- Mutation reveal: a short particle burst colored per `UITheme.MutationColors`
  behind the result panel when `mutation ~= "None"`.
- Timer: a soft tick per second once under the 10s red-zone threshold,
  distinct "time's up" stinger on `MazeFailed`.
- Maze completion: coin-counter tick-up sound matched to the `CoinsUI` tween
  duration (0.4s) so the audio and the animated number finish together.
- Footsteps/jump SFX tied to `Humanoid` state changes for basic movement
  feedback, especially useful once sprinting is added since it currently has
  no distinct audio cue.
