# ShotgunCeleste Roadmap Tracker

Last updated: 2026-03-27
Source: `C:\Users\Pranshul Soni\Downloads\shotgun_celeste_game_plan.html`

## Current Snapshot

- [x] `Phase 0 / Null overrides in game_sc.tscn` appears resolved (no `= null` found in `scenes/game_sc.tscn`).
- [x] `Shoot as ability component` wired through `AbilitiesManager` into `shoot_component`.
- [ ] `Loadout intent` still unresolved: `scripts/loadout.gd` defaults to `{0:"recoil",1:"dash",2:""}`.
- [ ] `Docs sync` pending: `ARCHITECTURE.md` and `CHANGES.md` still drift from current behavior.

## Phase 0 - Fix & Stabilise

### Must finish before new features
- [ ] Decide and lock control model:
  - Option A: Dash and shoot are innate, loadout only for special abilities.
  - Option B: Dash/recoil are loadout-driven and only active by slot.
- [ ] Update `scripts/loadout.gd` defaults to match chosen model.
- [ ] Align docs with actual code:
  - `ARCHITECTURE.md`
  - `CHANGES.md`
- [ ] Add a short "Input & ability truth table" section in docs:
  - LMB behavior
  - Shift behavior
  - RMB behavior
  - Slot 1/2/3 behavior

### Exit criteria
- [ ] No contradictions between code and docs.
- [ ] Fresh contributor can read docs and predict controls correctly.

## Phase 1 - Core Feel (2-3 weeks)

### Movement & feel
- [ ] Wall slide
- [ ] Wall jump
- [ ] Recoil screen shake
- [ ] Dash particle burst
- [ ] Core SFX: jump, land, dash, shoot, recoil
- [ ] Death + respawn checkpoint loop

### Exit criteria
- [ ] 10-minute playtest with no major frustration spikes.
- [ ] Movement feels reliable and expressive.

## Phase 2 - First Enemy (1-2 weeks)

### Combat foundation
- [ ] `EnemyBase` with `health`, `take_damage()`, `die()`
- [ ] Implement `Stalker`
- [ ] Hit flash + death animation
- [ ] First combat room

### Exit criteria
- [ ] Player can clear a room without cheap deaths.
- [ ] Recoil has a meaningful combat use-case.

## Phase 3 - Level Design (2-4 weeks)

### First real level
- [ ] Room-based layout
- [ ] Checkpoint system
- [ ] Tutorial rooms (teach by geometry)
- [ ] Mana puzzle room
- [ ] Ability unlock orb flow
- [ ] Goal/exit door win condition

### Exit criteria
- [ ] 10-15 rooms, 5-8 minute clear time.
- [ ] Start-to-finish playable demo.

## Phase 4 - Enemy Roster (2-3 weeks)

- [ ] Anchor
- [ ] Charger
- [ ] Reflector
- [ ] Bouncer
- [ ] Ranged enemy
- [ ] Optional boss (only after base enemies feel great)

## Phase 5 - New Abilities (3-4 weeks)

- [ ] Pick top 3 for v1 loadout
- [ ] Implement one at a time with isolated test room
- [ ] Rebalance mana economy after each new ability

Candidate abilities:
- [ ] Blink
- [ ] Time slow
- [ ] Gravity flip
- [ ] Shield bash

## Phase 6 - Polish & Ship (2-3 weeks)

- [ ] Music pass
- [ ] Parallax background layers
- [ ] HUD visual overhaul
- [ ] Main menu
- [ ] Pause menu
- [ ] Save system (checkpoint + unlocked abilities)
- [ ] Web export (itch.io)

### Shipping checklist
- [ ] Full run possible without crashes.
- [ ] New player can infer controls without tutorial text.
- [ ] At least 3 cold playtests observed and notes captured.

## Next 5 Tasks (Recommended)

- [ ] Finalize ability/control model decision.
- [ ] Update `scripts/loadout.gd` to match decision.
- [ ] Sync `ARCHITECTURE.md` + `CHANGES.md`.
- [ ] Implement wall slide.
- [ ] Implement wall jump.
