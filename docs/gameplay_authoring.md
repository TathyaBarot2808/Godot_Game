# Gameplay Authoring Guide

## Add a new projectile
1. Duplicate either `scenes/player_projectile_sc.tscn` or `scenes/enemy_projectile_sc.tscn` in the Godot editor.
2. Swap the sprite, collision shape, particles, and scale to match the new projectile.
3. Change the root `Area2D` exports on `ProjectileBase`:
   - `speed`
   - `damage`
   - `target_groups`
   - `ignored_groups`
   - `projectile_group_name`
   - `rotation_offset` if the art points in a different direction
4. Use the new projectile scene from a shooter node or enemy scene.

## Add a new ranged enemy
1. Duplicate `scenes/enemy_sc.tscn` in the Godot editor.
2. Keep the child node roles the same: `AnimatedSprite2D`, `ShootPoint`, `HealthComponent`, `CollisionShape2D`, and `HitParticles`.
3. Change the root `EnemyBase` exports:
   - `move_speed`
   - `detection_range`
   - `shooting_range`
   - `stop_distance`
   - `shoot_cooldown`
   - `projectile_scene`
4. Replace the sprite frames and tune the collision shape if the silhouette changes.
5. Only write a new enemy script if the behavior is not a ranged chase-and-shoot variant anymore.

## Shared rules
- `ProjectileBase` owns movement, target filtering, damage lookup, and cleanup.
- `EnemyBase` owns player tracking, chase movement, shooting cadence, hit feedback, and death cleanup.
- `player_move.gd` owns movement state. Shot timing, muzzle effect playback, and projectile spawning live in `player_shoot_controller.gd`.
