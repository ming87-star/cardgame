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

## Where this enemy stands on the road. Higher is further from the player,
## who walks up from lane 0.
var lane: int = 0

## Turns of 저지 remaining: held where it stands and unable to close. It can
## still swing at anything already within reach.
var rooted: int = 0

## Set the turn after being shouted down. A second shout won't land on it, so
## 저지 can never hold the road more than every other turn -- they always get
## through eventually.
var root_immune: int = 0

func can_be_rooted() -> bool:
	return root_immune <= 0

func _init(p_data: EnemyData, p_display_name: String) -> void:
	data = p_data
	display_name = p_display_name
	hp = p_data.max_hp

func is_alive() -> bool:
	return hp > 0

func get_move() -> Dictionary:
	return data.get_move(move_index)

## What this enemy will actually do from `distance` lanes away. An attack it
## cannot reach becomes a step forward, so the telegraph never promises a
## blow that can't land.
func get_intent(distance: int) -> Dictionary:
	var move: Dictionary = get_move()
	if move.get("type", "") != EnemyData.MOVE_TYPE_ATTACK:
		return move
	var reach: int = int(move.get("range", EnemyData.DEFAULT_ATTACK_RANGE))
	if distance <= reach:
		return move
	if rooted > 0:
		return {"move_name": "저지됨", "type": EnemyData.MOVE_TYPE_ROOTED, "value": 0}
	return {"move_name": "다가온다", "type": EnemyData.MOVE_TYPE_ADVANCE, "value": 1}
