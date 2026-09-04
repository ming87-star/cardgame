# Card Crawler (prototype)

Android-first card-collecting deckbuilding roguelike, built in **Godot 4**
(GDScript). Turn-based 1:1 combat in the style of Slay the Spire. World/theme
is not decided yet — this is the systems skeleton.

## What's here

A playable vertical slice: main menu → start a run → turn-based combat
against one enemy → win/lose → back to menu.

- `scripts/data/card_data.gd` — `CardData` resource (cost, damage, block,
  heal, vulnerable/weak/strength). New cards are just new `.tres` files, no
  code changes needed.
- `scripts/data/enemy_data.gd` — `EnemyData` resource with a cyclic move
  pattern (attack / defend / buff), shown to the player as an "intent".
- `resources/cards/`, `resources/enemies/` — sample content (Strike, Defend,
  Bash, Iron Wave, Inflame; Acid Slime).
- `scripts/autoload/game_manager.gd` — run state (HP, deck) and scene
  transitions. Registered as the `GameManager` autoload singleton.
- `scenes/combat/`, `scenes/card/`, `scenes/main_menu/` — the three screens.

Combat implements: energy (3/turn), draw/hand/discard piles with reshuffle,
block, Vulnerable (+50% damage taken) and Weak (-25% damage dealt) status
effects, Strength (flat damage buff), and a telegraphed enemy intent.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (Godot 4, not 3.x)
- For Android builds: Android Studio's command-line SDK tools + the Godot
  Android build template/export templates (Project menu → Install Android
  Build Template, and Editor → Manage Export Templates). `export_presets.cfg`
  is intentionally not committed since it stores machine-local SDK paths —
  set up your own Android export preset under Project → Export.

## Running it

Open `project.godot` in the Godot editor and press Play, or headless:

```
godot --path . 
```

## Roadmap (not built yet)

- Node-map run structure (branching path, elites, rest sites, shops) instead
  of a single fixed fight
- Card rewards after combat + a larger card pool / rarities
- Meta-progression: unlocking new cards/characters between runs, persistent
  save data
- Enemy variety + a boss
- Art, SFX, and juice (card play animations, damage numbers, particles)
- World/theme once decided — the systems above are setting-agnostic on
  purpose

## Porting to desktop later

This is exactly what Godot is good at: the same project exports to Windows/
macOS/Linux from the same codebase (Project → Export → add a Desktop
preset). The touch-first UI (`ScrollContainer` hand, big tap targets) also
works fine with mouse input as-is; the only desktop-specific work later is
input polish (hover states, keyboard shortcuts) and picking a bigger
resolution/UI scale for a mouse-driven layout.
