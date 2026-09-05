extends Control

const CHARACTER_IDS: Array[String] = ["scholar", "warrior", "merchant"]

@onready var character_list: VBoxContainer = %CharacterList
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate()

func _populate() -> void:
	for child in character_list.get_children():
		child.queue_free()
	for id in CHARACTER_IDS:
		var data: CharacterData = GameManager.get_character(id)
		var unlocked: bool = GameManager.is_unlocked(id)

		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.disabled = not unlocked
		if unlocked:
			button.pressed.connect(_on_character_pressed.bind(id))

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 14)
		button.add_child(row)

		if data.portrait:
			var portrait := TextureRect.new()
			portrait.texture = data.portrait
			portrait.custom_minimum_size = Vector2(88, 128)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_SCALE
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not unlocked:
				portrait.modulate = Color(0.5, 0.5, 0.55, 0.8)
			row.add_child(portrait)

		var text_box := VBoxContainer.new()
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		text_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(text_box)

		var name_label := Label.new()
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.text = data.display_name if unlocked else "%s (잠김)" % data.display_name
		text_box.add_child(name_label)

		var desc_label := Label.new()
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.text = data.motivation if unlocked else "이전 인물의 이야기를 먼저 끝내야 한다."
		text_box.add_child(desc_label)

		character_list.add_child(button)

func _on_character_pressed(id: String) -> void:
	GameManager.start_new_run(id)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
