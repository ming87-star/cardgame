extends Control

@onready var new_run_button: Button = %NewRunButton

func _ready() -> void:
	new_run_button.pressed.connect(_on_new_run_pressed)

func _on_new_run_pressed() -> void:
	GameManager.start_new_run()
