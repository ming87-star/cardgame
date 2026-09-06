extends Resource
class_name EnemyData

## A single entry in the enemy's move pattern.
## type: "attack" | "defend" | "buff" | "weaken"
## value: damage amount, block amount, strength amount, or weak turns
## move_name: label shown in the intent UI
const MOVE_TYPE_ATTACK := "attack"
const MOVE_TYPE_DEFEND := "defend"
const MOVE_TYPE_BUFF := "buff"
const MOVE_TYPE_WEAKEN := "weaken"
## Not authored in `moves`: substituted at runtime when an enemy wants to
## attack but is still too far up the road to reach.
const MOVE_TYPE_ADVANCE := "advance"

## How close an enemy must be for an attack move that doesn't state its own
## `range`. Most things on this road have to be next to you to hurt you.
const DEFAULT_ATTACK_RANGE := 1

@export var id: String = ""
@export var enemy_name: String = "Unnamed"
@export var max_hp: int = 40

## Cycles in order, looping back to the start once exhausted.
@export var moves: Array[Dictionary] = []

## Battlefield poses. The enemy stands in the pose matching its *telegraphed*
## next move, so the player can read the whole board without checking icons.
## Only art_idle is required; the others fall back to it.
@export var art_idle: Texture2D = null
@export var art_attack: Texture2D = null
@export var art_guard: Texture2D = null

func get_move(index: int) -> Dictionary:
	if moves.is_empty():
		return {}
	return moves[index % moves.size()]

func get_pose_art(move_type: String) -> Texture2D:
	match move_type:
		MOVE_TYPE_ATTACK, MOVE_TYPE_ADVANCE:
			if art_attack:
				return art_attack
		MOVE_TYPE_DEFEND, MOVE_TYPE_BUFF, MOVE_TYPE_WEAKEN:
			if art_guard:
				return art_guard
	return art_idle
