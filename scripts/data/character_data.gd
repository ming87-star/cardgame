extends Resource
class_name CharacterData

@export var id: String = ""
@export var display_name: String = ""

## Why this character is on the road to Hanyang.
@export_multiline var motivation: String = ""

## The rumor about the incident brewing in Hanyang that this character
## overhears after their first fight. Each character hears a different
## angle on the same underlying event.
@export_multiline var clue_text: String = ""

@export var starting_hp: int = 70
@export var starting_deck: Array[String] = []
@export var portrait: Texture2D = null

## Battle sprites. `battle_idle` falls back to the portrait when unset.
@export var battle_idle: Texture2D = null
@export var battle_attack: Texture2D = null

## The surface the hand is laid out on: a scroll for 선비, an armoured war-belt
## for 무사, a pedlar's patchwork wrapping cloth for 보부상.
@export var card_tray: Texture2D = null

func get_battle_idle() -> Texture2D:
	return battle_idle if battle_idle else portrait
