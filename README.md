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
  is his weapon, and his portrait now draws one instead of holding a fan.
  Each also has small square card art (`resources/art/cards/`, 400x400,
  transparent) generated the same way; shared cards use a neutral warm
  ink-red wash since no one class owns them, 선비's own cards use his
  indigo.
- `resources/enemies/` — 도깨비 (applies Weak), 산적 두목 (buffs/blocks),
  plus the boss stub above.
- `resources/art/characters/` — each character's portrait (Korean ink-wash
  style, transparent background), shown on the character select row and as
  a small in-combat HUD icon (no description text in combat -- that only
  shows on the select screen now). Generated via the OpenAI Images API
  (`gpt-image-2`, high quality, transparent background, 600x900 after
  resizing) with a single shared prompt template so all three match in
  pose, framing, stroke density, and seal placement — only the
  headwear/prop/accent-color slot differs per character. Facing direction
  matters here: Combat puts the player panel on the left and enemies on
  the right, so the portraits face right (not showing their back to the
  fight) rather than the left-facing first draft. Regenerate by re-running
  the prompt template with a new role-details/accent pair; keep the shared
  constraints (faceless silhouette, 3/4 standing pose facing right, head
  at ~15% / feet at ~90% of frame, transparent background, identical seal)
  so a new character still fits the set.
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

## Battlefield combat

Combat is staged as an encounter on the road rather than a stat panel: a
landscape background fills the screen, the player stands on the left facing
right, and the enemies stand on the right facing left, all drawn at
comparable scale from the same 168x290 figure slot (`PlayerFigure.tscn` and
`EnemyPanel.tscn` mirror each other deliberately).

- **Idle motion** (`scripts/combat/figure_anim.gd`) is synthesised, not
  frame-based: a bob plus a slight vertical squash about the feet, with a
  randomised phase per figure. Per-frame sprite sheets were rejected because
  AI-generated frames jitter in this hand-painted ink style and read as
  flicker; discrete *pose* swaps are used instead, where a wobble between
  frames doesn't show.
- **Enemy poses telegraph intent.** `EnemyData` carries `art_idle`,
  `art_attack` and `art_guard`, and `get_pose_art(move_type)` picks the one
  matching the move the enemy has queued, so the board is readable from the
  figures alone rather than from the intent icons.
- **Actions are sequenced.** Playing a card and the enemy turn are both
  coroutines: the actor lunges, damage lands, the target flashes and recoils,
  a floating number pops, and only then does the next actor move. Input stays
  locked (`is_busy`) for the whole sequence so turn order is legible.
- **Backgrounds** live in `resources/art/backgrounds/` and are chosen per
  encounter by `GameManager._pick_background()`. That indirection is the seam
  for the future map: a node will name its own background instead of rolling
  one at random.

### Targeting

Cards are dropped on whoever they affect, and the drag itself explains where
they may land (`combat.gd::_show_drag_hints`):

- A card with no enemy-directed effect is played on the player: their ground
  marker lights up and a 자신 badge appears. Enemy figures refuse the drop.
- An attacking or debuffing card must be dropped on an enemy; dropping it on
  open ground is rejected and the card simply stays in hand.
- 선비's group debuffs mark every living enemy with a 전체 badge, and 무사's
  splash attacks mark them 여파, so a card that reaches more than one target
  says so before it is committed.

## Visual theme

Bright hanji-paper + hanok-wood palette (replaced an earlier dark-navy
theme that made the ink-wash art look muddy and low-contrast on mobile).
`resources/theme/GameTheme.tres` is the single global Theme resource
(registered via `gui/theme/custom` in `project.godot`):

- Paper (`#f6efe0` family) fills scene backgrounds, card faces, and enemy
  panels; dark ink (`#262119`) is the default `Label` font color.
- Wood-brown (`#6b4a30` family) is the chrome for real action buttons
  (end turn, menu buttons) via the default `Button` styles.
- A `CardButton` theme type variation gives `CardUI` (in `Card.tscn`) a
  paper fill with a wood border instead of the wood-button look, so cards
  read as paper objects sitting on the table. `EnemyPanel.tscn` reuses the
  same style through a plain `Panel` background node (`Panel/styles/panel`
  in the theme), so cards and enemy panels visually match.
- Status icons (block/weak/vulnerable/strength/intent) and the result screen
  were re-tuned for contrast against the paper background — see the color
  constants in `scripts/ui/status_badges.gd`.
- Gauges are not boxes. `scripts/ui/hp_bar.gd` draws each one as a single
  brush stroke: tapered to a point at both ends, its edge wavering on a
  per-instance phase so neighbouring bars don't ripple in unison, and a
  partial bar stops bluntly like ink that ran out mid-sweep. Nothing sits
  behind them, so the value text carries an outline instead.

## Art direction

Two styles, split by what the thing *is*:

- **민화 (Joseon folk painting) for people and their belongings** — the three
  player characters, their card illustrations, and the tray each one lays
  their hand out on. Bold dark outlines over flat 오방색 mineral color, which
  stays punchy at the ~170px the sprites actually render at.
- **수묵화 (ink wash) for the world and what lives in it** — the road
  backgrounds and every enemy. Enemies are near-flat black silhouettes with
  one restrained accent wash, which makes them read as a nameless dark mass
  against the single clearly-drawn figure the player controls.

Clothing is a deliberate constraint, not an oversight: none of the three has
rank, so the garments carry no embroidery, gold thread, or 흉배 rank badge.
선비 in particular is a 포의 — plain undyed white 도포, one indigo 세조대 —
because he is travelling to *sit* the examination, not returning from
passing it. The same logic puts a 패랭이 on 보부상 rather than a 삿갓.

선비's archery follows 국궁 form: he shoots standing upright with the spine
vertical, never from a low martial crouch. Archery was one of the 육예 a
scholar studied as self-cultivation, which is also where his card names come
from, so drawing him as a fighter would contradict the character.

Per-character art lives in `resources/art/`: `characters/` (select-screen
portraits, waist-up, with a seal stamp), `battle/` (full-body idle and
attack sprites, no seal, framed tight), `trays/`, `cards/`, `enemies/` and
`backgrounds/`. Generation prompts are kept out of the repo; regenerate by
matching the constraints above.

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
- Enemy art in the same ink-wash style as the character portraits and cards
- SFX and juice (card play animations, damage numbers, particles)

## Porting to desktop later

This is exactly what Godot is good at: the same project exports to Windows/
macOS/Linux from the same codebase (Project → Export → add a Desktop
preset). The touch-first UI (`ScrollContainer` hand, big tap targets) also
works fine with mouse input as-is; the only desktop-specific work later is
input polish (hover states, keyboard shortcuts) and picking a bigger
resolution/UI scale for a mouse-driven layout.
