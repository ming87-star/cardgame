extends Button
class_name CardUI

var card_data: CardData

@onready var cost_label: Label = %CostLabel
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel

func set_card(data: CardData) -> void:
	card_data = data
	cost_label.text = str(data.cost)
	name_label.text = data.card_name
	desc_label.text = data.get_display_description()

func set_playable(playable: bool) -> void:
	disabled = not playable
	modulate.a = 1.0 if playable else 0.5

## Dragging is the only way to play a card now: drop it on an enemy panel
## to target damage, or anywhere in the battlefield for a self/buff card.
## Returning null here (e.g. when unaffordable) simply means the card
## doesn't pick up -- no partial/ambiguous play state to get stuck in.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or card_data == null:
		return null
	var preview: CardUI = duplicate()
	preview.modulate.a = 0.88
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.position = -size * 0.5
	set_drag_preview(preview)
	return {"card_ui": self}
