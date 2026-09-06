extends Control
class_name EnemyPanelUI

## One enemy standing on the road: pose sprite, ground marker, floating intent
## above its head and a compact info strip at its feet.

const HIT_FLASH := Color(1.6, 0.62, 0.5, 1.0)

var enemy: EnemyInstance
var combat: Control

## Lanes between this enemy and the player, pushed in by combat before each
## refresh. The intent depends on it: an enemy too far to swing walks instead.
var distance: int = 0

func set_distance(value: int) -> void:
	distance = value

@onready var name_label: Label = %NameLabel
@onready var hp_bar: HPBar = %HPBar
@onready var status_row: HBoxContainer = %StatusRow
@onready var intent_icon: StatIcon = %IntentIcon
@onready var intent_value_label: Label = %IntentValueLabel
@onready var sprite: TextureRect = %Sprite
@onready var anim: FigureAnim = %Anim
@onready var ground_marker: GroundMarker = %GroundMarker
@onready var aoe_badge: Control = %AoeBadge
@onready var aoe_label: Label = %AoeLabel

func set_enemy(e: EnemyInstance) -> void:
	enemy = e
	hp_bar.set_fill_color(Color(0.6, 0.24, 0.18))
	intent_icon.icon_color = Color(0.149, 0.133, 0.114)
	aoe_badge.hide()
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
		ground_marker.hide()
		sprite.texture = enemy.data.art_idle
		return

	ground_marker.show()
	intent_icon.show()
	var move: Dictionary = enemy.get_intent(distance)
	var move_type: String = move.get("type", "")

	# The enemy physically stands in the pose it is about to use, so the board
	# is readable without decoding the intent icons.
	sprite.texture = enemy.data.get_pose_art(move_type)

	match move_type:
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
		EnemyData.MOVE_TYPE_ADVANCE:
			intent_icon.kind = StatIcon.Kind.ADVANCE
			intent_value_label.text = "접근"

## Drag-time affordance. REST = not a legal drop, TARGET = droppable here,
## AFFECTED = this card hits every enemy, including this one, wherever it lands.
## `badge` labels *why* (전체 for a group debuff, 여파 for splash damage).
func set_drag_state(state: GroundMarker.State, badge: String = "") -> void:
	if not enemy.is_alive():
		return
	ground_marker.state = state
	aoe_badge.visible = state != GroundMarker.State.REST and not badge.is_empty()
	if not badge.is_empty():
		aoe_label.text = badge

## Enemies stand on the right facing left, so they strike leftward and get
## knocked rightward.
func play_attack() -> void:
	await anim.lunge(-1)

func play_pulse() -> void:
	await anim.pulse()

func take_hit() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", HIT_FLASH, 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	await anim.hit_react(1)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("card_ui")):
		return false
	# A card that only affects the player, or one whose reach falls short of
	# this lane, must not be consumed by an enemy.
	return combat.can_play_on_enemy(data["card_ui"].card_data, enemy)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	combat.try_play_card(data["card_ui"], enemy)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and enemy:
		set_drag_state(GroundMarker.State.REST)
