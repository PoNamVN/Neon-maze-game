# AGENTS.md - NEON LABYRINTH PROJECT RULES & GUIDELINES

## Project Overview
- **Game**: NEON LABYRINTH (Godot 4.3 stable, 2D top-down geometric minimalist neon labyrinth).
- **Godot Console Executable**: `D:\Game\godot_editor\Godot_v4.3-stable_win64_console.exe`

## Core Development Rules
1. **Visual Style**:
   - Strictly minimalist geometric aesthetics (`Polygon2D`, `Line2D`, `ColorRect`, GLSL Shaders, `CPUParticles2D`).
   - NO pixel art, NO hand-drawn sprite textures, NO external image assets.
2. **Mandatory Testing Requirement**:
   - Before completing any task or replying to the user with code updates, ALWAYS run the automated test suite headless:
     ```powershell
     & "D:\Game\godot_editor\Godot_v4.3-stable_win64_console.exe" --headless res://tests/test_scene.tscn
     ```
   - Ensure `Exit Code 0` and all tests pass.
3. **Autoload Singletons**:
   - `GameManager` and `SoundManager` are registered autoloads in `project.godot`.
   - NEVER add `class_name GameManager` or `class_name SoundManager` to their scripts (causes autoload shadowing collision in Godot 4).
4. **Procedural Audio Architecture**:
   - 100% procedural sound synthesis using `AudioStreamWAV` generated via math formulas in `SoundManager`. Do not introduce static sound asset files.
   - Dash sound features an 8-note Synthwave A-Minor Pentatonic progression with 3.2s combo timeout.
5. **God Mode Persistence**:
   - God Mode (`GameManager.is_god_mode`) is controlled via `F2`.
   - It MUST remain active across dashes, respawns, sector transitions, and pause menus.
   - `Player.kill()` must immediately return if `GameManager.is_god_mode` is true.
6. **Speedrun Stopwatch Lifecycle**:
   - Stopwatch stays at `00.00 [READY]` until the player's first movement input.
   - Full reset on death: all collected cores restore, exit locks, hazards reset, and timer returns to `00.00`.
