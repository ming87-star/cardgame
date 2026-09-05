extends Node

## Holds run-level state (character, player HP, current deck), persistent
## character-unlock progress, and hands off between scenes. Registered as
## the "GameManager" autoload singleton.

signal run_started
signal run_ended(victory: bool)

const COMBAT_SCENE := "res://scenes/combat/Combat.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/character_select/CharacterSelect.tscn"

const SAVE_PATH := "user://save.json"

## Unlock order: index 0 starts unlocked. Clearing a run with the character
## at index i unlocks the character at index i+1.
const CHARACTER_ORDER: Array[String] = ["scholar", "warrior", "merchant"]

const CHARACTER_PATHS := {
	"scholar": "res://resources/characters/scholar.tres",
	"warrior": "res://resources/characters/warrior.tres",
	"merchant": "res://resources/characters/merchant.tres",
}

const ENEMY_POOL: Array[String] = [
	"res://resources/enemies/dokkaebi.tres",
	"res://resources/enemies/bandit_chief.tres",
]

var unlocked_characters: Array[String] = [CHARACTER_ORDER[0]]

var current_character: CharacterData = null
var player_max_hp: int = 70
var player_hp: int = 70
var deck: Array[CardData] = []
var next_enemy: EnemyData = null

func _ready() -> void:
	_load_progress()

func get_character(id: String) -> CharacterData:
	return load(CHARACTER_PATHS[id]) as CharacterData

func is_unlocked(id: String) -> bool:
	return unlocked_characters.has(id)

func go_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func start_new_run(character_id: String) -> void:
	if not is_unlocked(character_id):
		return
	current_character = get_character(character_id)
	player_max_hp = current_character.starting_hp
	player_hp = player_max_hp
	deck.clear()
	for path in current_character.starting_deck:
		deck.append(load(path) as CardData)
	next_enemy = load(ENEMY_POOL.pick_random()) as EnemyData
	run_started.emit()
	get_tree().change_scene_to_file(COMBAT_SCENE)

func end_run(victory: bool) -> void:
	if victory and current_character:
		_unlock_next(current_character.id)
	run_ended.emit(victory)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _unlock_next(character_id: String) -> void:
	var idx: int = CHARACTER_ORDER.find(character_id)
	if idx == -1 or idx + 1 >= CHARACTER_ORDER.size():
		return
	var next_id: String = CHARACTER_ORDER[idx + 1]
	if not unlocked_characters.has(next_id):
		unlocked_characters.append(next_id)
		_save_progress()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("unlocked_characters") is Array:
		var result: Array[String] = [CHARACTER_ORDER[0]]
		for id in parsed["unlocked_characters"]:
			if id is String and CHARACTER_ORDER.has(id) and not result.has(id):
				result.append(id)
		unlocked_characters = result

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"unlocked_characters": unlocked_characters}))
