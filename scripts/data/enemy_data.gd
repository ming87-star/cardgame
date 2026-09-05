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

@export var id: String = ""
@export var enemy_name: String = "Unnamed"
@export var max_hp: int = 40

## Cycles in order, looping back to the start once exhausted.
@export var moves: Array[Dictionary] = []

func get_move(index: int) -> Dictionary:
	if moves.is_empty():
		return {}
	return moves[index % moves.size()]
