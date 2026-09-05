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

A playable vertical slice: main menu → character select (locked/unlocked,
motivation shown here only) → turn-based combat against 2-3 enemies at once
→ win (see a clue) / lose → back to menu. Landscape is the default
orientation (960x540). Character unlocks persist across launches
(`user://save.json`).

- `scripts/data/character_data.gd` — `CharacterData` resource: display
  name, motivation, the clue heard on victory, starting HP/deck.
- `scripts/data/card_data.gd` — `CardData` resource (cost, damage, block,
  heal, vulnerable/weak/strength). New cards are just new `.tres` files, no
  code changes needed.
- `scripts/data/enemy_data.gd` — `EnemyData` resource with a cyclic move
  pattern (attack / defend / buff / weaken), shown to the player as an
  "intent".
- `scripts/combat/enemy_instance.gd` — runtime combat state (HP/block/
  status/move index) for one enemy in the fight; `EnemyData` stays a shared
  template so two of the same enemy in one encounter don't share state.
  `game_manager.gd`'s `ENCOUNTER_POOL` picks 2-3 enemies per run.
- **Cards are played by dragging, not tapping.** `CardUI._get_drag_data`
  starts a drag; drop it on a specific `EnemyPanelUI` to target that enemy,
  or drop it anywhere else in the fight for a self/buff card (or a damage
  card when only one enemy is left). `Combat._can_drop_data`/`_drop_data`
  is the generic fallback -- every purely decorative container in between
  has to stay `mouse_filter = IGNORE` or it swallows the drop before it
  gets there. A drop that doesn't resolve (no target chosen while 2+
  enemies are alive, not enough energy) just leaves the card in hand;
  there's no intermediate "armed" state left over to get stuck in, which
  is what caused cards to vanish under the old tap-to-target flow.
- **Stats read as gauges/icons, not sentences.** `HPBar` (a `ProgressBar` +
  label) for HP/energy; `StatIcon` (`scripts/ui/stat_icon.gd`) draws small
  flat vector icons -- shield/chevron-down/chevron-up/burst/crossed-blade --
  for block, weak, vulnerable, strength, and enemy intent, so no image
  assets were needed for this pass.
- **Each character fights differently, not just a different deck:**
  - 선비 (Scholar): Weak/Vulnerable from his cards hit every enemy in the
    fight, not just one — a knowledge-is-leverage, control-the-crowd feel.
  - 무사 (Warrior): attack cards splash 50% of their damage onto one other
    enemy — built for melee against a group.
  - 보부상 (Merchant): keeps half of whatever Block is left over into his
    next turn instead of losing it all — built to outlast chip damage from
    several small attackers.
- `resources/characters/` — scholar, warrior, merchant, each with their own
  starting deck and its own card set/theme (see below), not just numbers.
- `resources/cards/` — 무사/보부상 share 베기, 방어 자세, 일도양단, 반격
  자세, 기합. 선비 has his own archery-themed set instead of reusing those:
  정곡(正鵠)/관혁(貫革)/부동심(不動心)/호연지기(浩然之氣)/명찰추호(明察秋毫)/
  반구저기(反求諸己), each named after an actual Analects/Mencius line about
  archery or self-cultivation — 활쏘기(archery) was one of the Six Arts
  (六藝) a Confucian scholar was expected to know, so a bow (not a sword)
  is his weapon. His portrait still shows a folding fan, not a bow — that
  regeneration is still pending, tracked in the roadmap below.
- `resources/enemies/` — 도깨비 (applies Weak), 산적 두목 (buffs/blocks),
  plus the boss stub above.
- `resources/art/characters/` — each character's portrait (Korean ink-wash
  style, transparent background), shown on the character select row and as
  a small in-combat HUD icon (no description text in combat -- that only
  shows on the select screen now). Generated via the OpenAI Images API
  (`gpt-image-2`, high quality, transparent background, 600x900 after
  resizing) with a single shared prompt template so all three match in
  pose, framing, stroke density, and seal placement — only the
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

## Korean font

Godot's bundled default UI font has no Hangul glyphs (text renders as blank
boxes without this). `resources/fonts/Pretendard-Regular.otf` (OFL-1.1,
license text alongside it) is set as `gui/theme/custom_font` in
`project.godot`, which applies it project-wide without needing a Theme
resource on every scene.

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
  (`hanyang_calamity.tres`) gets placed at the end of the road.
  Recommendation when this gets built: don't just add lots of nodes and
  drop enemy HP everywhere -- the per-character passives above need a
  fight to run 3-5 turns to actually show up, so a fight-in-one-turn map
  would flatten them out. Keep normal fights roughly at today's HP, add
  a distinct "elite" (harder, longer) encounter type, and vary node
  density/composition rather than uniformly lowering difficulty.
  - Sequenced storytelling: more clues per character across multiple
    fights, not just one on first victory
- Card rewards after combat + a larger card pool / rarities
- Scholar portrait regeneration (bow instead of the fan, to match his new
  archery kit)
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
