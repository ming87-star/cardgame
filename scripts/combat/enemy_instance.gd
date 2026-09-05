extends RefCounted
class_name EnemyInstance

## Runtime combat state for one enemy in the encounter. EnemyData is just
## the shared template (name/HP/moves); everything mutable during a fight
## lives here so two enemies of the same EnemyData don't share state.

var data: EnemyData
var display_name: String
var hp: int
var block: int = 0
var strength: int = 0
var weak: int = 0
var vulnerable: int = 0
var move_index: int = 0

func _init(p_data: EnemyData, p_display_name: String) -> void:
	data = p_data
	display_name = p_display_name
	hp = p_data.max_hp

func is_alive() -> bool:
	return hp > 0

func get_move() -> Dictionary:
	return data.get_move(move_index)
