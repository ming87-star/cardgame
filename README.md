# 한양 가는 길 (prototype)

Android-first card-collecting deckbuilding roguelike, built in **Godot 4**
(GDScript). Turn-based 1:1 combat in the style of Slay the Spire, set in a
Joseon-era Korea where scholars, warriors, and traveling merchants share the
same road — and the same monsters, both folklore (도깨비) and mundane
(산적).

## Story

Three playable characters, each walking to Hanyang for their own reason,
each picking up a different rumor about the same thing brewing in the
capital:

- **선비 (Scholar)** — chasing the state examination and a government post.
  Hears it from officials: scholars are quietly going missing.
- **무사 (Warrior)**, unlocked after clearing a run as the Scholar —
  chasing the military exam to rebuild a fallen house. Hears it from
  soldiers: the ground shakes under the capital at night.
- **보부상 (Merchant)**, unlocked after clearing a run as the Warrior —
  delivering goods to pay off a debt. Hears it from traders: people vanish
  from a warehouse under the city wall.

All three threads point at the same final boss — something enormous
underneath Hanyang itself. `resources/enemies/hanyang_calamity.tres` is a
data stub for it (not in the random encounter pool yet — there's no map/
run-length system to place it at the end of yet).

## What's here

A playable vertical slice: main menu → character select (locked/unlocked)
→ turn-based combat against one enemy → win (see a clue) / lose → back to
menu. Character unlocks persist across launches (`user://save.json`).

- `scripts/data/character_data.gd` — `CharacterData` resource: display
  name, motivation, the clue heard on victory, starting HP/deck.
- `scripts/data/card_data.gd` — `CardData` resource (cost, damage, block,
  heal, vulnerable/weak/strength). New cards are just new `.tres` files, no
  code changes needed.
- `scripts/data/enemy_data.gd` — `EnemyData` resource with a cyclic move
  pattern (attack / defend / buff / weaken), shown to the player as an
  "intent".
- `resources/characters/` — scholar, warrior, merchant, each with their own
  starting deck (scholar leans debuff/control, warrior leans aggressive,
  merchant leans balanced/utility).
- `resources/cards/` — 베기, 방어 자세, 일도양단, 반격 자세, 기합, 부적,
  필사즉생.
- `resources/enemies/` — 도깨비 (applies Weak), 산적 두목 (buffs/blocks),
  plus the boss stub above.
- `resources/art/characters/` — each character's portrait (Korean ink-wash
  style, transparent background), shown on the character select row and as
  a small in-combat portrait next to the motivation line. Generated via the
  OpenAI Images API (`gpt-image-2`, high quality, transparent background,
  600x900 after resizing) with a single shared prompt template so all three
  match in pose, framing, stroke density, and seal placement — only the
  headwear/prop/accent-color slot differs per character. Regenerate by
  re-running the prompt template with a new role-details/accent pair; keep
  the shared constraints (faceless silhouette, 3/4 standing pose, head at
  ~15% / feet at ~90% of frame, transparent background, identical seal) so
  a new character still fits the set.
- `scripts/autoload/game_manager.gd` — run state, character-unlock chain +
  save/load, scene transitions. Registered as the `GameManager` autoload.
- `scenes/character_select/`, `scenes/combat/`, `scenes/card/`,
  `scenes/main_menu/` — the four screens.

Combat implements: energy (3/turn), draw/hand/discard piles with reshuffle,
block, Vulnerable (+50% damage taken), Weak (-25% damage dealt, now
inflictable on the player too, by 도깨비), and Strength (flat damage buff).

## Known follow-up: Korean font

Godot's bundled default UI font doesn't include Hangul glyphs, so Korean
text may render as blank boxes/tofu until a CJK-capable font (e.g. Noto
Sans KR, Pretendard) is set as the project's default theme font. Not done
yet — flagging it before anyone tests on a real device.

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

- Node-map run structure (branching path, elites, rest sites, shops) so a
  run has more than one fight — this is also where the final boss
  (`hanyang_calamity.tres`) gets placed at the end of the road
  - Sequenced storytelling: more clues per character across multiple
    fights, not just one on first victory
- Card rewards after combat + a larger card pool / rarities
- Korean-capable UI font (see above)
- Card illustrations and enemy art in the same ink-wash style as the
  character portraits
- SFX and juice (card play animations, damage numbers, particles)

## Porting to desktop later

This is exactly what Godot is good at: the same project exports to Windows/
macOS/Linux from the same codebase (Project → Export → add a Desktop
preset). The touch-first UI (`ScrollContainer` hand, big tap targets) also
works fine with mouse input as-is; the only desktop-specific work later is
input polish (hover states, keyboard shortcuts) and picking a bigger
resolution/UI scale for a mouse-driven layout.
