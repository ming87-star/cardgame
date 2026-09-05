extends RefCounted
class_name StatusBadges

## Rebuilds a row of small icon+number chips (block, weak, vulnerable,
## strength...) inside an existing HBoxContainer. Call every time the
## underlying values change; it just clears and redraws.
static func build(container: HBoxContainer, entries: Array) -> void:
	for child in container.get_children():
		child.queue_free()
	for entry in entries:
		var kind: int = entry[0]
		var value: int = entry[1]
		var color: Color = entry[2]
		if value == 0:
			continue
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 2)

		var icon := StatIcon.new()
		icon.kind = kind
		icon.icon_color = color
		icon.custom_minimum_size = Vector2(16, 16)
		chip.add_child(icon)

		var label := Label.new()
		label.text = str(value)
		label.add_theme_font_size_override("font_size", 13)
		chip.add_child(label)

		container.add_child(chip)
