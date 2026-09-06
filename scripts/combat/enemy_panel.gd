extends Control
class_name EnemyPanelUI

var enemy: EnemyInstance
var combat: Control

@onready var name_label: Label = %NameLabel
@onready var hp_bar: HPBar = %HPBar
@onready var status_row: HBoxContainer = %StatusRow
@onready var intent_icon: StatIcon = %IntentIcon
@onready var intent_value_label: Label = %IntentValueLabel

func set_enemy(e: EnemyInstance) -> void:
	enemy = e
	hp_bar.set_fill_color(Color(0.6, 0.24, 0.18))
	intent_icon.icon_color = Color(0.149, 0.133, 0.114)
	update_display()

func update_display() -> void:
	name_label.text = enemy.display_name
	hp_bar.set_values(enemy.hp, enemy.data.max_hp)
	modulate = Color(1, 1, 1, 1) if enemy.is_alive() else Color(0.6, 0.58, 0.54, 0.75)

	StatusBadges.build(status_row, [
		[StatIcon.Kind.BLOCK, enemy.block, StatusBadges.BLOCK_COLOR],
		[StatIcon.Kind.WEAK, enemy.weak, StatusBadges.WEAK_COLOR],
		[StatIcon.Kind.VULNERABLE, enemy.vulnerable, StatusBadges.VULNERABLE_COLOR],
		[StatIcon.Kind.STRENGTH, enemy.strength, StatusBadges.STRENGTH_COLOR],
	])

	if not enemy.is_alive():
		intent_icon.hide()
		intent_value_label.text = "쓰러짐"
		return
	intent_icon.show()
	var move: Dictionary = enemy.get_move()
	match move.get("type", ""):
		EnemyData.MOVE_TYPE_ATTACK:
			intent_icon.kind = StatIcon.Kind.ATTACK
			intent_value_label.text = str(int(move.get("value", 0)) + enemy.strength)
		EnemyData.MOVE_TYPE_DEFEND:
			intent_icon.kind = StatIcon.Kind.BLOCK
			intent_value_label.text = str(int(move.get("value", 0)))
		EnemyData.MOVE_TYPE_BUFF:
			intent_icon.kind = StatIcon.Kind.BUFF
			intent_value_label.text = ""
		EnemyData.MOVE_TYPE_WEAKEN:
			intent_icon.kind = StatIcon.Kind.WEAKEN
			intent_value_label.text = ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("card_ui")):
		return false
	if not enemy.is_alive():
		return false
	modulate = Color(1.25, 1.2, 1.05, 1)
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	combat.try_play_card(data["card_ui"], enemy)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and enemy:
		update_display()
