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
		button.custom_minimum_size = Vector2(0, 100)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not unlocked
		if unlocked:
			button.text = "%s\n%s" % [data.display_name, data.motivation]
			button.pressed.connect(_on_character_pressed.bind(id))
		else:
			button.text = "%s (잠김)\n이전 인물의 이야기를 먼저 끝내야 한다." % data.display_name
		character_list.add_child(button)

func _on_character_pressed(id: String) -> void:
	GameManager.start_new_run(id)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
