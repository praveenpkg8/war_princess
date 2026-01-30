# Masked Escape

A 2D top-down stealth survival game built with Godot 4.

## Overview

Infiltrate a toxic military camp to rescue your partner. Your gas mask filter is degrading - when it runs out, you'll start coughing, alerting nearby guards.

## Controls

| Action | Key |
|--------|-----|
| Move | WASD / Arrow Keys |
| Sprint | Shift |
| Kill (from behind) | Space |
| Interact / Loot | Hold E |
| Restart | R (when game over) |
| Quit | Q (when game over) |

## How to Play

1. **Navigate the level** - Move quietly to avoid detection
2. **Watch your filter** - The green bar shows remaining filter life (~50 seconds)
3. **Sprint carefully** - Running depletes your filter faster and makes noise
4. **Avoid guards** - They patrol, investigate sounds, and will chase you if spotted
5. **Kill from behind** - Get behind a guard and press Space to eliminate them
6. **Loot filters** - Hold E near a dead guard to take their fresh filter
7. **Rescue your partner** - Reach the blue prisoner sprite to win

## Mechanics

### Filter System
- Filter depletes over ~50 seconds
- Sprinting uses filter 2.5x faster
- At 0 health, you start coughing (makes loud noise)
- Green vignette appears when filter is critical

### Enemy AI
- **Patrol**: Guards follow waypoint paths
- **Investigate**: Noise attracts guards to investigate
- **Chase**: Spotted guards pursue aggressively

### Detection
- **Vision**: 200px cone, 90 degrees
- **Hearing**: 150px radius for noise
- **Line of sight**: Walls block vision

## Project Structure

```
war_princess/
├── autoload/
│   ├── GameManager.gd          # Global state
│   └── AudioManager.gd         # Sound management
├── scenes/
│   ├── main.tscn               # Main game scene
│   ├── player/
│   │   ├── Player.tscn
│   │   └── Player.gd
│   ├── enemy/
│   │   ├── Enemy.tscn
│   │   └── Enemy.gd
│   ├── ui/
│   │   ├── MaskUI.tscn         # Filter health bar
│   │   └── GameOver.tscn
│   └── level/
│       ├── Level1.tscn
│       └── Level1.gd
├── scripts/
│   ├── StateMachine.gd         # Generic FSM
│   ├── State.gd                # Base state class
│   └── enemy_states/
│       ├── PatrolState.gd
│       ├── InvestigateState.gd
│       └── ChaseState.gd
└── assets/
    ├── audio/                  # Place sound files here
    └── sprites/
```

## Asset Requirements

For full audio experience, place these files in `assets/audio/`:
- `cough.wav` - Coughing sound
- `heartbeat.wav` - Low rhythmic beat
- `alert.wav` - Sharp detection sound
- `filter_swap.wav` - Gas hiss
- `footstep.wav` - Footstep sound

## Running the Game

1. Open Godot 4
2. Import project (select the `war_princess` folder)
3. Open `scenes/main.tscn`
4. Press F5 to run

## License

MIT License - Feel free to use and modify for your own projects.
