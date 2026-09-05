extends Button
class_name EnemyPanelUI

## Fired when the player taps this enemy while a card is awaiting a target.
signal targeted(panel: EnemyPanelUI)

var enemy: EnemyInstance

@onready var name_label: Label = %NameLabel
@onready var hp_label: Label = %HPLabel
@onready var intent_label: Label = %IntentLabel

func set_enemy(e: EnemyInstance) -> void:
	enemy = e
	update_display()

func update_display() -> void:
	name_label.text = enemy.display_name
	if not enemy.is_alive():
		hp_label.text = "쓰러짐"
		intent_label.text = ""
		modulate = Color(0.45, 0.45, 0.48, 0.8)
	else:
		hp_label.text = "체력: %d/%d%s" % [
			enemy.hp, enemy.data.max_hp,
			("  (방어 %d)" % enemy.block) if enemy.block > 0 else ""
		]
		intent_label.text = _intent_text()
		modulate = Color(1, 1, 1, 1)
	disabled = not enemy.is_alive()

func set_targetable(can_target: bool) -> void:
	disabled = not (can_target and enemy.is_alive())

func _intent_text() -> String:
	var move: Dictionary = enemy.get_move()
	var move_name: String = move.get("move_name", "???")
	match move.get("type", ""):
		EnemyData.MOVE_TYPE_ATTACK:
			return "%s — 공격 %d" % [move_name, int(move.get("value", 0)) + enemy.strength]
		EnemyData.MOVE_TYPE_DEFEND:
			return "%s — 방어 %d" % [move_name, int(move.get("value", 0))]
		EnemyData.MOVE_TYPE_BUFF:
			return "%s — 강화" % move_name
		EnemyData.MOVE_TYPE_WEAKEN:
			return "%s — 약화 부여" % move_name
		_:
			return move_name

func _pressed() -> void:
	targeted.emit(self)
