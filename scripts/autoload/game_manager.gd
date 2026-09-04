extends Node

## Holds run-level state (player HP, current deck) and hands off between
## scenes. Registered as the "GameManager" autoload singleton.

signal run_started
signal run_ended(victory: bool)

const COMBAT_SCENE := "res://scenes/combat/Combat.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

const STARTING_DECK: Array[String] = [
	"res://resources/cards/strike.tres",
	"res://resources/cards/strike.tres",
	"res://resources/cards/strike.tres",
	"res://resources/cards/strike.tres",
	"res://resources/cards/defend.tres",
	"res://resources/cards/defend.tres",
	"res://resources/cards/defend.tres",
	"res://resources/cards/defend.tres",
	"res://resources/cards/bash.tres",
]

const STARTING_ENEMY := "res://resources/enemies/slime.tres"

var player_max_hp: int = 70
var player_hp: int = 70
var deck: Array[CardData] = []
var next_enemy: EnemyData = null

func start_new_run() -> void:
	player_max_hp = 70
	player_hp = player_max_hp
	deck.clear()
	for path in STARTING_DECK:
		deck.append(load(path) as CardData)
	next_enemy = load(STARTING_ENEMY) as EnemyData
	run_started.emit()
	get_tree().change_scene_to_file(COMBAT_SCENE)

func end_run(victory: bool) -> void:
	run_ended.emit(victory)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
