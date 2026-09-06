extends RefCounted
class_name StatusBadges

## Darkened enough to hold contrast against the game's hanji-paper
## background; the earlier pastel set was tuned for a dark background.
const BLOCK_COLOR := Color(0.23, 0.35, 0.5)
const WEAK_COLOR := Color(0.42, 0.28, 0.5)
const VULNERABLE_COLOR := Color(0.7, 0.28, 0.16)
const STRENGTH_COLOR := Color(0.55, 0.4, 0.08)
## 선비's 조준 and 무사's 기세 -- the two class resources the road system runs on.
const AIM_COLOR := Color(0.16, 0.36, 0.46)
const MOMENTUM_COLOR := Color(0.66, 0.26, 0.14)

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
