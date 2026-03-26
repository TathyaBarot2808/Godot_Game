# Game Architecture

## The Big Picture

```
GAME STARTS
     │
     ▼
game_sc.tscn (the level)
     ├── Player          ← the character you control
     ├── TileMapLayer    ← the floor/walls
     └── HUD             ← the screen UI
```

---

## GDScript Basics You Need

```gdscript
# var = a variable (stores data)
var speed = 600.0

# func = a function (does something)
func jump():
    velocity.y = -1000.0

# @export = shows in the Inspector panel in Godot editor (change without touching code)
@export var SPEED: float = 600.0

# @onready = wait until the scene is fully loaded, then get this node
@onready var sprite = $AnimatedSprite2D   # $ means "find child node named..."

# signal = an event you can fire, and other scripts can listen to
signal mana_changed(current, max)         # fired when mana updates
mana_changed.emit(50.0, 100.0)            # fire it
mana_changed.connect(_on_mana_changed)    # listen to it

# extends = this script IS a certain type of node
extends Node                  # plain node, no physics
extends CharacterBody2D       # a physics body (the player)

# class_name = gives this script a name so other scripts can reference it by type
class_name AbilitiesManager

# _ready()            = runs ONCE when the scene loads
# _process(delta)     = runs EVERY FRAME (60fps) — use for non-physics
# _physics_process(delta) = runs EVERY PHYSICS FRAME — use for movement/collisions
# delta = time since last frame (keeps speed consistent regardless of FPS)
```

---

## Scene Tree

```
game_sc.tscn
└── Scene1 (Node2D)                     ← game.gd
    ├── Player (CharacterBody2D)        ← player_move.gd
    │   ├── CollisionShape2D            ← hitbox
    │   ├── RayCastLeft                 ← corner correction sensor
    │   ├── RayCastRight                ← corner correction sensor
    │   ├── AnimatedSprite2D            ← sprite + all animations
    │   ├── Mana (Node2D)               ← mana.gd
    │   └── AbilitiesManager (Node)     ← abilities_manager.gd
    │       ├── recoil (Node)           ← recoil_component.gd
    │       ├── dash (Node)             ← dash_component.gd
    │       └── LoadoutManager (Node)   ← loadout.gd
    ├── Camera2D                        ← follows player
    ├── TileMapLayer                    ← the level tiles
    └── HUD (CanvasLayer)               ← hud.gd
        └── ManaContainer
            ├── ManaBar (ProgressBar)
            └── ManaLabel (Label)
```

---

## Every File Explained

---

### `ability_base.gd`

**What it is:** A template. Every ability MUST have these 3 functions.

```gdscript
extends Node
class_name AbilityBase

# "I need mana/input, do the thing, return result (e.g. a velocity)"
func trigger(_args: Dictionary) -> Variant

# "Am I currently available to use?" (not on cooldown, not already active)
func can_use() -> bool

# "Am I currently mid-execution?" (e.g. currently dashing)
func is_active() -> bool
```

**Why it exists:** Forces every ability (recoil, dash, future ones) to have the same interface.
`AbilitiesManager` can call `trigger()` on any ability without knowing what it is.

---

### `recoil_component.gd`

**What it is:** The shotgun recoil ability. Fires player away from mouse.

| Export | What it controls |
|---|---|
| `RECOIL_SPEED` | How fast the player flies |
| `RECOIL_DURATION` | How long the player has no control |
| `RECOIL_GRAVITY_RECOVERY` | How long gravity eases back in after |

**Flow:**
```
Right click pressed
  → trigger({direction: Vector2 away from mouse})
  → _recoil_timer starts
  → player velocity = direction * RECOIL_SPEED
  → gravity/movement are blocked while _recoil_timer > 0
  → timer hits 0 → _recovery_timer starts → gravity eases in
```

---

### `dash_component.gd`

**What it is:** The horizontal dash ability.

| Export | What it controls |
|---|---|
| `DASH_SPEED` | How fast the dash is |
| `DASH_DURATION` | How long the dash lasts (seconds) |
| `DASH_COOLDOWN` | Wait time before can dash again |

**Signals:**
- `dash_started` → `player_move.gd` plays the "Dash" animation
- `dash_ended` → animation system handles transition back to Idle

**Flow:**
```
Shoot pressed + dash in active slot
  → trigger({direction: -1.0 or 1.0})
  → dash_started signal fires → animation plays
  → _dash_timer starts, velocity = direction * DASH_SPEED
  → timer hits 0 → dash_ended signal fires
```

---

### `abilities_manager.gd`

**What it is:** The gatekeeper. Knows all abilities, controls which are unlocked, routes execute calls.

```gdscript
var _unlocked = {
    "recoil": true,   # true = player can use it
    "dash":   true,   # false = locked, can't use even if in loadout
}
```

**How abilities get registered:**
```
_ready() loops over all child nodes
→ finds nodes that extend AbilityBase
→ stores them: _components["recoil"] = recoil_node
                _components["dash"]   = dash_node
```

**Key functions:**

| Function | Does |
|---|---|
| `can_use("dash")` | checks unlocked + component.can_use() |
| `execute("dash", args)` | runs trigger() if can_use() passes |
| `is_active("dash")` | asks component if currently mid-dash |
| `unlock("dash")` | flips _unlocked["dash"] to true |
| `get_unlocked_abilities()` | returns `["recoil", "dash"]` |

---

### `loadout.gd` (class_name: LoadoutManager)

**What it is:** Tracks which 3 abilities the player has equipped and which slot is active.

```gdscript
var loadout = {
    0: "recoil",   # slot 1
    1: "dash",     # slot 2
    2: "",         # slot 3 — empty
}
var active_slot = 0   # player is on slot 1
```

**Key functions:**

| Function | Does |
|---|---|
| `set_active_slot(1)` | switch to slot 2 |
| `get_active_ability()` | returns `loadout[active_slot]` |
| `equip("dash", 1)` | put dash in slot 2 (checks unlock first) |
| `unequip(1)` | clear slot 2 |
| `get_available_abilities()` | asks AbilitiesManager for all unlocked abilities |

**Important:** LoadoutManager is a child of AbilitiesManager in the scene, so it calls `get_parent()` to check unlock state.

---

### `mana.gd`

**What it is:** The mana resource. Tracks value, handles regen, emits signal for HUD.

| Export | What it controls |
|---|---|
| `max_mana` | Maximum mana (default 100) |
| `regen_rate` | Mana restored per second (default 20) |
| `regen_delay` | Seconds before regen starts after spending (default 2) |
| `shoot_cost` | Cost per recoil use (default 25) |
| `dash_cost` | Cost per dash use (default 40) |

**Flow:**
```
mana.spend(25)
  → current_mana -= 25
  → regen_timer = 2.0 seconds
  → mana_changed signal fires → HUD updates

Every frame:
  → if regen_timer > 0: count down (no regen yet)
  → else: slowly add regen_rate * delta to current_mana
  → mana_changed signal fires → HUD updates
```

---

### `hud.gd`

**What it is:** The mana bar on screen. Listens to mana signal, updates UI.

```
game.gd calls hud.setup(player.mana)
  → connects mana_changed signal to _on_mana_changed
  → sets initial bar value

When mana_changed fires:
  → ManaBar.value = current
  → ManaLabel.text = "Mana: 75 / 100"
```

---

### `game.gd`

**What it is:** Glue script on the game scene root. Just wires systems together on startup.

```gdscript
func _ready():
    hud.setup(player.mana)   # connect HUD → player's mana node
```

That's it. One line.

---

### `player_move.gd`

**What it is:** The player controller. Reads input every frame, delegates to components.

**Every physics frame runs in this order:**
```
1. _tick_coyote        → update coyote time window (forgiveness for late jumps)
2. _tick_jump_buffer   → update jump buffer (jump pressed just before landing)
3. _apply_gravity      → apply gravity (skipped during recoil/dash)
4. _handle_slot_switch → 1/2/3 keys → change active loadout slot
5. _handle_shoot       → right click → ask loadout what ability → execute it
6. _handle_jump        → Space → jump if buffer + coyote match
7. _handle_movement    → A/D → move left/right (skipped during recoil/dash)
8. _update_animation   → pick correct animation based on state
9. move_and_slide()    → Godot moves player, handles collisions
```

**Why shoot is split into 3 functions:**
```gdscript
_handle_shoot()      # just reads slot and routes
    → "recoil" → _execute_recoil()   # recoil-specific gates + logic
    → "dash"   → _execute_dash()     # dash-specific gates + logic
    → ""       → do nothing
```

**Coyote time:** Player can still jump for 0.1 seconds after walking off a ledge.  
**Jump buffer:** If you press jump 0.1 seconds before landing, the jump still fires.  
**Apex modifiers:** Near the top of a jump, gravity is weaker and speed is higher — makes jumping feel floaty and responsive.

---

## Full Request Flow — Right Click (Recoil)

```
Player right-clicks
        │
player_move._handle_shoot()
        │
loadout.get_active_ability()  →  "recoil"
        │
abilities.can_use("recoil")
    → _unlocked["recoil"] == true?  ✓
    → recoil.can_use() — not already recoiling?  ✓
        │
mana.can_spend(25.0)?  ✓
        │
abilities.execute("recoil", {direction: Vector2 away from mouse})
    → recoil.trigger(args)
    → _recoil_timer = 0.2, returns velocity impulse
        │
mana.spend(25.0)
    → mana_changed signal fires
    → HUD updates bar
        │
player velocity = impulse  →  player flies away from mouse
        │
(next frames)
_apply_gravity skips    — recoil.is_active() == true
_handle_movement skips  — same
_update_animation skips — same
        │
0.2s later — _recoil_timer hits 0
    → _recovery_timer starts (0.15s)
    → gravity eases back in smoothly
    → control restored
```

---

## Adding a New Ability

```
1. Create new_ability.gd extending AbilityBase
   → implement trigger(), can_use(), is_active()

2. Add a Node inside AbilitiesManager in player_sc.tscn
   → attach new_ability.gd to it
   → name it "newability" (lowercase, no spaces)

3. Add to _unlocked dict in abilities_manager.gd
   → "newability": false  (locked by default)

4. Add _execute_newability() in player_move.gd
   → add it to the match block in _handle_shoot()

5. To unlock: abilities.unlock("newability")
   → call this from a pickup, cutscene, etc.
```

Nothing else needs to change.

---

## Input Map (project.godot)

| Action | Key/Button |
|---|---|
| `move_left` | A |
| `move_right` | D |
| `jump` | Space |
| `dash` | Shift |
| `shoot` | Right Mouse Button |
| `slot_1` | 1 |
| `slot_2` | 2 |
| `slot_3` | 3 |

---

## Quick Reference — Where to Change Things

| I want to... | Go to... |
|---|---|
| Change movement speed/jump height | `player_move.gd` exports or Inspector |
| Change mana costs | `mana.gd` exports or Inspector |
| Change dash speed/duration | `dash_component.gd` exports or Inspector |
| Change recoil strength | `recoil_component.gd` exports or Inspector |
| Unlock an ability | `abilities_manager.gd` → set `_unlocked["x"] = true` |
| Add a new ability | See "Adding a New Ability" section above |
| Change what's in loadout at start | `loadout.gd` → `var loadout = {0: "recoil", ...}` |
| Change HUD appearance | `hud.tscn` in Godot editor |
| Change mana bar position | `hud.tscn` → ManaContainer anchor settings |
