# Repository Guidelines

## Project Structure & Module Organization
- `scenes/` holds the main Godot scenes (`main.tscn`, player, enemy, UI, and level scenes).
- `scripts/` contains reusable gameplay logic and state machines (e.g., `StateMachine.gd`, enemy state scripts).
- `autoload/` stores global singletons like `GameManager.gd` and `AudioManager.gd`.
- `assets/` is the home for game content such as `assets/audio/` and `assets/sprites/`.
- `icon/` contains the project icon assets.
- Root files: `project.godot` (Godot project), `README.md` (game overview), `game_design_docs.md`.

## Build, Test, and Development Commands
- Open the project in Godot 4 and run the main scene:
  - Godot Editor: open `scenes/main.tscn` and press F5.
- CLI (if you prefer):
  - `godot4 --path . --editor` (open editor)
  - `godot4 --path . --main-pack scenes/main.tscn` (run)

## Coding Style & Naming Conventions
- Use GDScript with 4-space indentation.
- Scene and script names use PascalCase (e.g., `Player.tscn`, `Enemy.gd`).
- State scripts use descriptive suffixes (e.g., `PatrolState.gd`, `ChaseState.gd`).

## Testing Guidelines
- No automated tests are currently configured. If you add tests, document the framework and commands here.

## Commit & Pull Request Guidelines
- No commit or PR conventions are documented in this repo. Keep messages concise and descriptive (e.g., "Add guard investigate state").
- PRs should include: a short summary, relevant screenshots for visual changes, and any gameplay testing notes.

## Assets & Content Tips
- Place audio in `assets/audio/` and sprites in `assets/sprites/`.
- Keep filenames lowercase with underscores for raw assets (e.g., `guard_footstep.wav`) to avoid import conflicts.
