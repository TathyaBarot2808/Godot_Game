# Post-Merge Codebase Changes Summary
*Generated: 2026-03-27 — For resolving merge conflicts after pulling this branch*

---

## Context

This branch was merged with a collaborator's `main` branch that introduced a new **modular Ability System** (`AbilitiesManager`, `LoadoutManager`, `DashComponent`). After the merge, the codebase was debugged, refactored, and several bugs were fixed. This document details every file that changed, what it does, and why — so an AI can use it as ground truth when resolving future merge conflicts.

---

## Architecture Overview (Post-Merge)

The game now uses a **component-based ability architecture**:

```
Player (CharacterBody2D)  — player_move.gd
├── AbilitiesManager      — abilities_manager.gd
│   ├── LoadoutManager    — loadout.gd
│   ├── dash              — dash_component.gd
│   └── shoot             — shoot_component.gd
├── Mana                  — mana.gd  (instanced from mana_sc.tscn)
├── AnimatedSprite2D      (main body art)
├── ShootEffectSprite     (black hole overlay sprite)
├── FirePoint             (Node2D bullet spawn point)
├── RayCastLeft / Right   (corner correction raycasts)
└── CollisionShape2D
```

**Key design principle:** Dash and Shoot are **innate abilities** — always available to the player, bound to Shift and LMB. They do NOT go through the Loadout. The Loadout slots are reserved for future equippable special abilities.

---

## Files Changed

---

### `scripts/player_move.gd` ⚠️ HEAVILY REWRITTEN
This is the most important file. It was completely rewritten post-merge.

**Removed:**
- All old monolithic inline dash logic (`dash_timer`, `dash_cooldown_timer`, `dash_direction` variables).
- The old `_handle_ability_use()` function that routed LMB through the Loadout.
- Old gravity/movement code that referenced `AbilitiesManager.is_active("recoil")`.

**Added:**
- `@onready var abilities: AbilitiesManager = $AbilitiesManager`
- `@onready var loadout: LoadoutManager = $AbilitiesManager/LoadoutManager`
- `@onready var _dash_comp: Node = $AbilitiesManager/dash`
- `var jump_buffer_timer` and `var coyote_timer` (previously missing after refactor).

**Key new functions:**

#### `_handle_innate_dash()` — called every frame
- Fires on `Input.is_action_just_pressed("dash")` (Shift key).
- Completely independent of the Loadout system.
- Reads WASD to build a `Vector2` direction for **8-directional dashing**:
  - A/D → X axis, W/S → Y axis.
  - If no keys held → defaults to the direction the sprite is facing.
- Calls `_dash_comp.trigger({"direction": dir})` directly.
- Deducts `mana.dash_cost` from mana.

#### `_handle_innate_shoot()` — called every frame
- Fires on `Input.is_action_just_pressed("shoot")` (LMB).
- Completely independent of the Loadout system.
- Blocked if `is_dashing` or `is_shooting_action_active` is true.
- Deducts `mana.shoot_cost`, sets `is_shooting_action_active = true`.
- Snapshots `stored_shoot_direction` (mouse-to-firepoint vector).
- Shows and plays the `ShootEffectSprite` "default" animation from frame 0.

#### `_handle_loadout_ability()` — placeholder
- Currently a `pass` stub. Reserved for future equippable abilities bound to the Loadout.

#### `_on_dash_started()` / `_on_dash_ended()`
- Connected to signals from `DashComponent`.
- `_on_dash_started`: sets `is_dashing = true`, plays "Dash" animation.
- `_on_dash_ended`: does **nothing** — intentionally empty. Velocity ends but the animation is allowed to finish naturally on its own timeline.

#### `_update_animation_and_sync()`
- Now guards on `animated_sprite.animation == "Dash"` rather than `is_dashing`.
- If the Dash animation is still playing → returns early (don't interrupt it).
- When the animation finishes → `is_dashing = false` is set here, not in `_on_dash_ended`.
- After dash: plays Jump/Fall/Walk/Idle based on normal state.
- Reads `chest_y_offsets` dictionary to sync `FirePoint.position.y` and `ShootEffectSprite.position.y` with each frame of each animation (prevents the black hole effect from floating when the character bobs up and down).

#### `_on_shoot_effect_frame_changed()`
- Fires on frame 4 of the "default" shoot animation → calls `_fire_projectile()`.
- **Critically**: resets `is_shooting_action_active = false` immediately after firing so subsequent shots work.
- On frame 7 → hides and stops the shoot effect.

#### `_apply_gravity()`, `_handle_jump()`, `_handle_movement()`, `_tick_coyote()`, `_tick_jump_buffer()`
- Extracted into individual named functions (previously all inline in `_physics_process`).
- Gravity is now skipped when `is_dashing == true`.
- Movement is also skipped when `is_dashing == true` (velocity set by dash component directly).

#### `chest_y_offsets` dictionary
- Maps animation name → array of Y pixel offsets per frame.
- Used to dynamically move the black hole effect and FirePoint to match the player's body art bobbing in each animation.
- Example: `"Idle": [0, 1, 4, 5, 4, 1, 0]` — 7 frames.

---

### `scripts/dash_component.gd` ✏️ MODIFIED
Extends `AbilityBase`. Handles all dash timing and signals.

**Changed:**
- `DASH_SPEED` default: `1800.0` → `1200.0` (user tuned for feel).
- `trigger()` function signature changed from taking a `float` to a **`Vector2`**:
  - Old: `args.get("direction", 1.0)` → returned `Vector2(direction * DASH_SPEED, 0.0)` (horizontal only).
  - New: `args.get("direction", Vector2.RIGHT)` → normalizes the vector → returns `dir * DASH_SPEED` (full 8-direction support, including diagonal).
- Emits `dash_started` signal when triggered, `dash_ended` when `_dash_timer` runs out.
- `DASH_DURATION = 0.12s` and `DASH_COOLDOWN = 0.5s` are unchanged.

---

### `scripts/shoot_component.gd` ✨ NEW FILE
A new `AbilityBase` subclass. Registered in the `AbilitiesManager` as the "shoot" skill.

- In `trigger()`: shows the `ShootEffectSprite` and plays the "default" animation from frame 0.
- `is_active()`: returns `player.is_shooting_action_active`.
- `can_use()`: returns `not player.is_dashing`.
- Note: actual projectile spawning is still handled by `player_move.gd`'s `_fire_projectile()`, triggered by the frame signal.

---

### `scripts/abilities_manager.gd` ✏️ MODIFIED
**Changed:**
- `"recoil"` key renamed to `"shoot"` in the `_unlocked` dictionary.
- Added a **public** `is_unlocked(ability_name)` method (the old one was private `_is_unlocked`). This was needed because `LoadoutManager` was calling `manager.is_unlocked()` which didn't exist publicly, causing a crash.
- Private `_is_unlocked` now delegates to the public version.

---

### `scripts/loadout.gd` ✏️ MODIFIED
**Changed:**
- Default loadout cleared — all 3 slots set to `""` (empty):
  ```gdscript
  # Before:
  0: "dash", 1: "shoot", 2: ""
  # After:
  0: "",     1: "",       2: ""
  ```
  Rationale: Dash and Shoot are innate abilities. The loadout is now reserved for future equippable skills that haven't been designed yet.

---

### `scripts/hud.gd` ✏️ MODIFIED
**Added:**
- `@onready var _slots: Array` — array of the 3 `Slot0/1/2` Panel nodes from `LoadoutContainer`.
- `setup_loadout(loadout_node: Node)` — connects the HUD to the `LoadoutManager`'s `loadout_changed` signal.
- `_refresh_loadout(loadout_node)` — iterates all 3 slots, updates the `AbilityLabel` text and the `Highlight` panel's visibility based on which slot is active.

---

### `scripts/mana.gd` ✏️ MODIFIED (minor)
- `shoot_cost` set to `5.0`, `dash_cost` set to `15.0`.
- Added comprehensive inline documentation.

---

### `scripts/player_projectile.gd` ✨ NEW FILE
Attached to the `player_projectile_sc.tscn` (`Area2D`).
- `@export var speed: float = 800.0`
- `var direction: Vector2 = Vector2.RIGHT` (set by `player_move.gd` at spawn time).
- Moves forward via `position += direction * speed * delta`.
- `_on_body_entered()`: ignores the Player itself, calls `body.take_damage(10)` if the body has that method, then `queue_free()`.
- `_on_visible_on_screen_notifier_2d_screen_exited()`: `queue_free()` to prevent memory leaks.

---

### `scenes/player_sc.tscn` ✏️ MODIFIED
**Added ext_resource references:**
```
[ext_resource type="Script" path="res://scripts/abilities_manager.gd" id="10_abilities"]
[ext_resource type="Script" path="res://scripts/loadout.gd" id="11_loadout"]
[ext_resource type="Script" path="res://scripts/dash_component.gd" id="12_dash"]
[ext_resource type="Script" path="res://scripts/shoot_component.gd" id="13_shoot"]
```

**Added node hierarchy under Player:**
```
[node name="AbilitiesManager" type="Node" parent="."]
    script = ExtResource("10_abilities")
[node name="LoadoutManager" type="Node" parent="AbilitiesManager"]
    script = ExtResource("11_loadout")
[node name="dash" type="Node" parent="AbilitiesManager"]
    script = ExtResource("12_dash")
[node name="shoot" type="Node" parent="AbilitiesManager"]
    script = ExtResource("13_shoot")
```

---

### `scenes/game_sc.tscn` ✏️ MODIFIED
Fixed corrupted `null` overrides on the Player node that were left by the merge:
```
# Before (corrupted):
APEX_THRESHOLD = null
APEX_GRAVITY_MULTIPLIER = null
APEX_SPEED_BOOST = null
CORNER_CORRECTION_AMOUNT = null

# After (correct):
APEX_THRESHOLD = 15.0
APEX_GRAVITY_MULTIPLIER = 0.6
APEX_SPEED_BOOST = 50.0
CORNER_CORRECTION_AMOUNT = 4.0
```

---

### `project.godot` ✏️ MODIFIED
**Added two new input actions** required for 8-directional dashing:
- `move_up` → **W key** (physical_keycode 87)
- `move_down` → **S key** (physical_keycode 83)

These exist alongside the existing `move_left` (A) and `move_right` (D) actions.

> ⚠️ **Merge conflict note:** If your friend's branch also defines `move_up` and `move_down`, keep theirs if they point to the same keys. If they don't exist in their branch, add these entries.

---

## Quick Merge Conflict Priority Guide

| File | Priority | Rule |
|---|---|---|
| `player_move.gd` | 🔴 Critical | Use **this branch's version**. It is a complete rewrite. |
| `dash_component.gd` | 🔴 Critical | Use **this branch's version** (Vector2 direction, 1200 speed). |
| `scenes/player_sc.tscn` | 🔴 Critical | Must include the `AbilitiesManager` node tree. |
| `project.godot` | 🟡 Important | Merge both. Preserve `move_up` and `move_down` actions. |
| `scenes/game_sc.tscn` | 🟡 Important | Ensure `APEX_*` values are floats, not `null`. |
| `scripts/hud.gd` | 🟡 Important | Must include `setup_loadout()` function. |
| `loadout.gd` | 🟢 Safe | All slots should be `""`. Overwrite safely. |
| `abilities_manager.gd` | 🟢 Safe | Must have public `is_unlocked()` method and `"shoot"` key (not `"recoil"`). |
| `shoot_component.gd` | 🟢 Safe | New file — no conflict expected. |
| `player_projectile.gd` | 🟢 Safe | New file — no conflict expected. |
