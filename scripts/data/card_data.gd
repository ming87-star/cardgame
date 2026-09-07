extends Resource
class_name CardData

enum CardType { ATTACK, SKILL, POWER }
enum TargetType { ENEMY, SELF, NONE }

@export var id: String = ""
@export var card_name: String = "Unnamed"
@export_multiline var description: String = ""
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var target_type: TargetType = TargetType.ENEMY
@export var art: Texture2D = null

## Reach, measured in lanes along the road. A bow is useless with something
## already on top of you; a sabre can't touch anything it hasn't closed on.
## Only checked for cards that act on an enemy.
@export var range_min: int = 1
@export var range_max: int = 99

## Steps the player takes when this card resolves: +1 walks up the road
## toward the enemies, -1 gives ground. Movement is a card play like any
## other, so spacing always costs a card and the energy on it.
@export var move_lanes: int = 0

## Core numbers. Not every card uses every field.
@export var damage: int = 0
@export var block: int = 0
@export var heal: int = 0

## Status effects this card applies to its target (attack/skill) or to
## the caster (power). 0 = no effect.
@export var apply_vulnerable: int = 0
@export var apply_weak: int = 0
@export var apply_strength: int = 0

## Turns of 저지: enemies held where they stand, unable to close. Applied to
## every living enemy, since a shout carries down the whole road.
@export var apply_root: int = 0

func get_display_description() -> String:
	if not description.is_empty():
		return description
	var parts: Array[String] = []
	if damage > 0:
		parts.append("Deal %d damage." % damage)
	if block > 0:
		parts.append("Gain %d Block." % block)
	if heal > 0:
		parts.append("Heal %d HP." % heal)
	if apply_vulnerable > 0:
		parts.append("Apply %d Vulnerable." % apply_vulnerable)
	if apply_weak > 0:
		parts.append("Apply %d Weak." % apply_weak)
	if apply_strength > 0:
		parts.append("Gain %d Strength." % apply_strength)
	if move_lanes > 0:
		parts.append("%d칸 나아간다." % move_lanes)
	elif move_lanes < 0:
		parts.append("%d칸 물러선다." % -move_lanes)
	return " ".join(parts)

## "근" / "중" / "원" / "근~중" -- reach shown on the card so the player never
## has to count lanes. Empty for cards that don't reach for an enemy at all.
func get_range_label() -> String:
	if target_type != TargetType.ENEMY:
		return ""
	if damage <= 0 and apply_vulnerable <= 0 and apply_weak <= 0:
		return ""
	var names := {1: "근", 2: "중", 3: "원"}
	var low: String = names.get(range_min, "원")
	var high: String = names.get(mini(range_max, 3), "원")
	return low if low == high else "%s~%s" % [low, high]
