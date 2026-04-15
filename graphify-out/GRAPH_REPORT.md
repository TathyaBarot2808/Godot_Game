# Graph Report - .  (2026-04-11)

## Corpus Check
- Corpus is ~4,711 words - fits in a single context window. You may not need a graph.

## Summary
- 175 nodes · 220 edges · 18 communities detected
- Extraction: 88% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 25 edges (avg confidence: 0.77)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `ShotgunCeleste Project` - 21 edges
2. `Player Controller` - 13 edges
3. `Player (CharacterBody2D)` - 12 edges
4. `AbilityBase Class` - 10 edges
5. `HealthComponent` - 9 edges
6. `Mana System` - 7 edges
7. `Roadmap Tracker` - 7 edges
8. `AbilitiesManager (Node)` - 7 edges
9. `EnemySc (CharacterBody2D)` - 6 edges
10. `Dungeon Tile Set` - 6 edges

## Surprising Connections (you probably didn't know these)
- `EnemyBase Concept` --conceptually_related_to--> `EnemySc (CharacterBody2D)`  [INFERRED]
  ROADMAP_TRACKER.md → scenes/enemy_sc.tscn
- `PlayerProjectile (Area2D)` --references--> `Player Projectile Sprite`  [EXTRACTED]
  scenes/player_projectile_sc.tscn → assets/Player_Projectile_Sprite.png
- `Player AnimatedSprite2D` --references--> `Player Sprite Sheet`  [EXTRACTED]
  scenes/player_sc.tscn → assets/Player_Sprite-sheet.png
- `Input: slot_1 (1)` --conceptually_related_to--> `LoadoutManager (Node)`  [INFERRED]
  project.godot → scenes/player_sc.tscn
- `Input: slot_2 (2)` --conceptually_related_to--> `LoadoutManager (Node)`  [INFERRED]
  project.godot → scenes/player_sc.tscn

## Hyperedges (group relationships)
- **Modular Ability System** — ability_base_AbilityBase, abilities_manager_AbilitiesManager, loadout_LoadoutManager, dash_component_DashComponent, recoil_component_RecoilComponent, shoot_component_ShootComponent, walljump_WallJump [EXTRACTED 1.00]
- **HUD Signal-Driven Data Binding** — game_GameManager, hud_HUD, mana_ManaSystem, health_HealthComponent, loadout_LoadoutManager [EXTRACTED 1.00]
- **Player Combat Flow** — player_move_PlayerController, mana_ManaSystem, abilities_manager_AbilitiesManager, shoot_component_ShootComponent, player_projectile_PlayerProjectile [INFERRED 0.85]
- **Mana-Signal-HUD Data Flow** — script_mana, signal_mana_changed, script_hud, node_mana_bar, node_mana_label [EXTRACTED 1.00]
- **Ability Component System** — concept_ability_base, script_abilities_manager, script_dash_component, script_shoot_component, script_recoil_component, script_loadout [EXTRACTED 1.00]
- **Player Movement Feel Systems** — concept_coyote_time, concept_jump_buffer, concept_apex_modifiers, script_player_move [EXTRACTED 1.00]
- **Player Visual Identity** — player_sprite_character, blue_creature_design, blue_magenta_palette, pixel_art_style [EXTRACTED 0.90]
- **Game Enemy Roster** — flying_enemy_entity, slime_green_entity, enemy_category [EXTRACTED 1.00]
- **Dungeon Structural Tile Elements** — dungeon_stone_walls, dungeon_floor_tiles, dungeon_wooden_door, dungeon_ladder [EXTRACTED 1.00]

## Communities

### Community 0 - "Ability System Core"
Cohesion: 0.16
Nodes (24): AbilitiesManager, AbilityBase, Camera Follow (Look-Ahead), Dash Component, Signal: dash_ended, Signal: dash_started, Enemy AI, Enemy Projectile (+16 more)

### Community 1 - "Project Configuration"
Cohesion: 0.1
Nodes (23): 8-Directional Dashing, D3D12 Renderer (Windows), Godot 4.6 Engine, Jolt Physics Engine, Pixel Snap Settings, Input: dash (Shift), Input: jump (Space), Input: move_down (S) (+15 more)

### Community 2 - "Player Scene Nodes"
Cohesion: 0.1
Nodes (18): Player Projectile Sprite, Player Sprite Sheet, Player Shoot Animation, Camera2D, Enemy HealthComponent, FirePoint (Node2D), Player Health Component, Player (CharacterBody2D) (+10 more)

### Community 3 - "Architecture Docs"
Cohesion: 0.15
Nodes (17): Architecture Documentation, Post-Merge Changes Document, AbilityBase Class, Component-Based Ability Architecture, Innate Abilities Design Decision, recoil (Node), shoot (Node), Rationale: AbilityBase Uniform Interface (+9 more)

### Community 4 - "Enemy & Environment"
Cohesion: 0.12
Nodes (15): Dungeon Tile Set, Enemy Projectile Sprite, Flying Enemy Sprite, EnemySc (CharacterBody2D), EnemyProjectile (Area2D), Enemy ShootPoint (Node2D), Enemy AnimatedSprite2D, EnemySc Instance in Game (+7 more)

### Community 5 - "HUD & UI System"
Cohesion: 0.12
Nodes (14): HealthBar (ProgressBar), HealthContainer (Control), HealthLabel (Label), HUD (CanvasLayer), LoadoutContainer (HBoxContainer), Mana (Node2D), ManaBar (ProgressBar), ManaContainer (Control) (+6 more)

### Community 6 - "Movement Mechanics"
Cohesion: 0.17
Nodes (11): Apex Modifiers, Chest Y Offsets Dictionary, Coyote Time, Jump Buffer, AbilitiesManager (Node), dash (Node), walljump (Node), Rationale: Empty _on_dash_ended (+3 more)

### Community 7 - "Dungeon Tileset Props"
Cohesion: 0.18
Nodes (13): Dark Blue-Purple Dungeon Palette, Chandelier Light Fixture, Treasure Chest, Dungeon Environment Theme, Dungeon Floor Tiles, Dark Stone Wall Tiles, Dungeon Tile Set, Wooden Dungeon Door (+5 more)

### Community 8 - "Development Roadmap"
Cohesion: 0.22
Nodes (9): Roadmap Tracker, EnemyBase Concept, Phase 1: Core Feel, Phase 2: First Enemy, Phase 3: Level Design, Phase 4: Enemy Roster, Phase 6: Polish & Ship, Wall Jump Feature (+1 more)

### Community 9 - "Combat Visual Assets"
Cohesion: 0.29
Nodes (7): Enemy Projectile Sprite Sheet, Energy Projectile, Pixel Art Style, Player Combat System, Player Projectile Sprite, Player Character Sprite, Player Sprite Sheet

### Community 10 - "Shoot Effect Sprites"
Cohesion: 1.0
Nodes (2): Muzzle Flash Effect Frames, Player Shoot Animation

### Community 11 - "Project README"
Cohesion: 1.0
Nodes (1): README

### Community 12 - "Mana Resource System"
Cohesion: 1.0
Nodes (1): Mana Resource System

### Community 13 - "Player Character Design"
Cohesion: 1.0
Nodes (1): Blue Creature Character Design

### Community 14 - "Walk Animation"
Cohesion: 1.0
Nodes (1): Walk Cycle Animation Frames

### Community 15 - "Player Color Palette"
Cohesion: 1.0
Nodes (1): Blue-Magenta-Black Color Palette

### Community 16 - "Dungeon Ladder"
Cohesion: 1.0
Nodes (1): Wooden Ladder

### Community 17 - "Dungeon Cage"
Cohesion: 1.0
Nodes (1): Prison Cage

## Ambiguous Edges - Review These
- `dash_component.gd` → `Input: vdash (Ctrl)`  [AMBIGUOUS]
  project.godot · relation: conceptually_related_to

## Knowledge Gaps
- **65 isolated node(s):** `Camera Follow (Look-Ahead)`, `Signal: damaged`, `Signal: healed`, `Signal: died`, `README` (+60 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Shoot Effect Sprites`** (2 nodes): `Muzzle Flash Effect Frames`, `Player Shoot Animation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Project README`** (1 nodes): `README`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Mana Resource System`** (1 nodes): `Mana Resource System`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Player Character Design`** (1 nodes): `Blue Creature Character Design`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Walk Animation`** (1 nodes): `Walk Cycle Animation Frames`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Player Color Palette`** (1 nodes): `Blue-Magenta-Black Color Palette`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dungeon Ladder`** (1 nodes): `Wooden Ladder`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dungeon Cage`** (1 nodes): `Prison Cage`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `dash_component.gd` and `Input: vdash (Ctrl)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Player (CharacterBody2D)` connect `Player Scene Nodes` to `Enemy & Environment`, `HUD & UI System`, `Movement Mechanics`?**
  _High betweenness centrality (0.155) - this node is a cross-community bridge._
- **Why does `ShotgunCeleste Project` connect `Project Configuration` to `Enemy & Environment`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Why does `Game Scene` connect `Enemy & Environment` to `Project Configuration`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `AbilityBase Class` (e.g. with `Candidate Ability: Blink` and `Candidate Ability: Time Slow`) actually correct?**
  _`AbilityBase Class` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Camera Follow (Look-Ahead)`, `Signal: damaged`, `Signal: healed` to the rest of the system?**
  _65 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Configuration` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._