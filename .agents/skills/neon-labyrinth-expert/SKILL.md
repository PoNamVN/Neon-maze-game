---
name: neon-labyrinth-expert
description: >-
  Master developer cheatsheet and runbook for NEON LABYRINTH (Godot 4.3 stable).
  Contains architectural rules, procedural synth audio system, shader pipelines,
  testing procedures, gotchas, and feature inventory. Use this skill whenever
  working on, modifying, debugging, or adding features to NEON LABYRINTH.
---

# NEON LABYRINTH - Master Developer Guide & Knowledge Base

## 1. Project Specifications
- **Engine**: Godot Engine 4.3.stable (Win64 console executable: `D:\Game\godot_editor\Godot_v4.3-stable_win64_console.exe`).
- **Art Style**: Pure Minimalist Cyberpunk Neon (Geometric nodes only: `Polygon2D`, `Line2D`, `ColorRect`, Shaders, Particle Systems). No hand-drawn sprites or pixel art.
- **Render Mode**: Forward+ / Mobile (GLSL Shaders with CRT Scanlines, Vignette, Chromatic Aberration).

---

## 2. Autoload Architecture & Critical Gotchas
- **`GameManager` (`res://scripts/autoload/game_manager.gd`)**:
  - Handles level lifecycle, timer, core collection, best records (`user://records.json`).
  - **CRITICAL RULE**: Do **NOT** declare `class_name GameManager` in this file. Godot 4 throws `Parse Error: Class "GameManager" hides an autoload singleton` if both are defined.
  - **God Mode**: Controlled globally by `GameManager.is_god_mode`. It must never be reset by dashes, scene transitions, or respawns.
  - **Timer Standby**: `level_timer = 0.0`, `is_timer_running = false`, `has_player_moved = false`. The stopwatch stays frozen at `TIME: 00.00 [READY]` until the player inputs their first move.
- **`SoundManager` (`res://scripts/autoload/sound_manager.gd`)**:
  - 100% Procedural PCM Synthesis (`AudioStreamWAV` generated in memory via math formulas). Zero external `.wav`/`.mp3` files needed.
  - **Melodic Dash**: 8-note A-Minor Pentatonic scale (`A4 -> C5 -> D5 -> E5 -> G5 -> A5 -> C6 -> D6`). Successive dashes within 3.2s progress up the scale.
  - Procedural sound library: Sonar ping, Crystal bell pickups, Crunch death, Predator alarm, Level win arpeggio.

---

## 3. Player & Hazard Mechanics
- **Player Movement**:
  - Uses `CircleShape2D` (radius 11.5) with `motion_mode = MotionMode.MOTION_MODE_FLOATING` to slide frictionlessly around maze wall corners.
  - Dashing spawns up to 12 wireframe RGB chromatic hologram ghost echoes (`GhostEcho` scene).
  - Emits Sonar wave on dash (`dashed.emit(pos)`), expanding up to 520px radius.
- **Hazards & EMP Disruption**:
  - `LaserHazard`: Multi-beam rotating laser with `force_raycast_update()` for zero tunneling. Disabled during EMP.
  - `SeekerHazard`: Autonomous drone enraged by Sonar ping. Stunned during EMP.
  - `PillarHazard`: Spike pillar driven by delta state machine (`OFF` -> `WARN` -> `ON`). Disabled during EMP.
  - `SliderHazard`: Sliding spike block oscillating back and forth. Frozen during EMP.
- **Cyber Pickups (`CyberPickup`)**:
  - `OVERCLOCK`: 3.0s zero cooldown infinite dashes.
  - `EMP`: 4.0s global disruption paralyzing all hazards.
  - `PHASE_SHIFT`: 1 dash phases frictionlessly through a maze wall.
- **Minimap Radar (`Minimap`)**:
  - High performance vector rendering in top-right HUD. Shows maze walls, entity blips (Player, Cores, Pickups, Hazards, Exit).
  - Emits Sonar wave sweep across the radar whenever the player dashes.

---

## 4. In-Game Controls & Debug Suite
- `WASD` / `Arrow Keys`: Move player block.
- `Space`: Melodic Dash & Sonar Pulse.
- `ESC`: Pause Menu (Sound FX toggle, CRT Scanlines toggle, Screen Shake toggle, Sector Restart, Best Records, Quit).
- `F1` / `~`: Toggle Debug Console.
- `F2`: Toggle Absolute God Mode (turns player block to Golden God aura).
- `F3`: Toggle Full Light / Fog of War.
- `F4`: Instantly collect 1 Energy Core.
- `F5`: Test Suicide & Full Reset (`force_kill()`).
- `F6`: Skip to next Sector.
- `F7`: Toggle 0.25x Slow-Motion.
- `F8`: Test Sonar Wave trigger.

---

## 5. Verification & Testing Workflow
Whenever modifying code in this project, **ALWAYS** execute the automated test suite before reporting completion:
```powershell
& "D:\Game\godot_editor\Godot_v4.3-stable_win64_console.exe" --headless res://tests/test_scene.tscn
```
- Must report `TEST RESULTS: N PASSED, 0 FAILED` and exit with code `0`.
- To test game loop stability:
```powershell
& "D:\Game\godot_editor\Godot_v4.3-stable_win64_console.exe" --headless --quit-after 200 res://scenes/main.tscn
```
