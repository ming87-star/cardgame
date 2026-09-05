extends Control
class_name HPBar

@onready var bar: ProgressBar = %Bar
@onready var value_label: Label = %ValueLabel

func set_values(current: int, max_value: int) -> void:
	bar.max_value = max(max_value, 1)
	bar.value = clamp(current, 0, max_value)
	value_label.text = "%d/%d" % [max(current, 0), max_value]

func set_fill_color(color: Color) -> void:
	var style: StyleBoxFlat = bar.get_theme_stylebox("fill").duplicate()
	style.bg_color = color
	bar.add_theme_stylebox_override("fill", style)
