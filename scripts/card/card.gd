extends Button
class_name CardUI

## Fired when the player taps the card. Combat.gd listens and decides
## whether/how to play it.
signal played(card_ui: CardUI)

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

func set_selected(selected: bool) -> void:
	modulate = Color(1, 1, 0.55, modulate.a) if selected else Color(1, 1, 1, modulate.a)

func _pressed() -> void:
	played.emit(self)
