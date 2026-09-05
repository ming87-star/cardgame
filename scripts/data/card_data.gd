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

## Core numbers. Not every card uses every field.
@export var damage: int = 0
@export var block: int = 0
@export var heal: int = 0

## Status effects this card applies to its target (attack/skill) or to
## the caster (power). 0 = no effect.
@export var apply_vulnerable: int = 0
@export var apply_weak: int = 0
@export var apply_strength: int = 0

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
	return " ".join(parts)
