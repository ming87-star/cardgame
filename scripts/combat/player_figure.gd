extends Control
class_name PlayerFigureUI

## The player standing on the left of the road, mirrored from the enemy
## figures: same slot sizes and the same info strip, so the two sides read as
## meeting at comparable scale.

const HIT_FLASH := Color(1.6, 0.62, 0.5, 1.0)

var combat: Control

@onready var hp_bar: HPBar = %PlayerHPBar
@onready var energy_bar: HPBar = %EnergyBar
@onready var status_row: HBoxContainer = %PlayerStatusRow
@onready var sprite: TextureRect = %Sprite
@onready var anim: FigureAnim = %Anim
@onready var ground_marker: GroundMarker = %GroundMarker
@onready var self_badge: Control = %SelfBadge

func _ready() -> void:
	hp_bar.set_fill_color(Color(0.478, 0.29, 0.2))
	energy_bar.set_fill_color(Color(0.29, 0.365, 0.51))
	self_badge.hide()

var _idle_texture: Texture2D = null
var _attack_texture: Texture2D = null

func set_character(data: CharacterData) -> void:
	_idle_texture = data.get_battle_idle()
	_attack_texture = data.battle_attack
	sprite.texture = _idle_texture

func set_stats(hp: int, max_hp: int, energy: int, max_energy: int,
		block: int, weak: int, strength: int) -> void:
	hp_bar.set_values(hp, max_hp)
	energy_bar.set_values(energy, max_energy)
	StatusBadges.build(status_row, [
		[StatIcon.Kind.BLOCK, block, StatusBadges.BLOCK_COLOR],
		[StatIcon.Kind.WEAK, weak, StatusBadges.WEAK_COLOR],
		[StatIcon.Kind.STRENGTH, strength, StatusBadges.STRENGTH_COLOR],
	])

func set_drag_state(state: GroundMarker.State) -> void:
	ground_marker.state = state
	self_badge.visible = state != GroundMarker.State.REST

## The player faces right, so they strike rightward and recoil leftward.
func play_attack() -> void:
	if _attack_texture:
		sprite.texture = _attack_texture
	await anim.lunge(1)
	sprite.texture = _idle_texture

func play_pulse() -> void:
	await anim.pulse()

func take_hit() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", HIT_FLASH, 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	await anim.hit_react(-1)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("card_ui")):
		return false
	return combat.card_can_target_self(data["card_ui"].card_data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	combat.try_play_card(data["card_ui"], null)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_drag_state(GroundMarker.State.REST)
