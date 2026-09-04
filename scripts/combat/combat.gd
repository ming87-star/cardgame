extends Control

const CARD_SCENE := preload("res://scenes/card/Card.tscn")

const MAX_ENERGY := 3
const HAND_SIZE := 5

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var intent_label: Label = %IntentLabel
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var energy_label: Label = %EnergyLabel
@onready var draw_count_label: Label = %DrawCountLabel
@onready var discard_count_label: Label = %DiscardCountLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var result_panel: Control = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var result_button: Button = %ResultButton

var player_hp: int
var player_max_hp: int
var player_block: int = 0
var player_strength: int = 0
var energy: int = 0

var enemy_data: EnemyData
var enemy_hp: int
var enemy_block: int = 0
var enemy_strength: int = 0
var enemy_weak: int = 0
var enemy_vulnerable: int = 0
var enemy_move_index: int = 0

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardUI] = []

var combat_over: bool = false
var combat_victory: bool = false

func _ready() -> void:
	player_max_hp = GameManager.player_max_hp
	player_hp = GameManager.player_hp
	enemy_data = GameManager.next_enemy
	enemy_hp = enemy_data.max_hp
	enemy_name_label.text = enemy_data.enemy_name

	draw_pile = GameManager.deck.duplicate()
	draw_pile.shuffle()

	result_panel.hide()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	result_button.pressed.connect(_on_result_button_pressed)

	start_player_turn()

func start_player_turn() -> void:
	player_block = 0
	energy = MAX_ENERGY
	draw_cards(HAND_SIZE)
	update_all_ui()

func draw_cards(count: int) -> void:
	for i in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		var data: CardData = draw_pile.pop_back()
		_add_card_to_hand(data)

func _add_card_to_hand(data: CardData) -> void:
	var card_ui: CardUI = CARD_SCENE.instantiate()
	hand_container.add_child(card_ui)
	card_ui.set_card(data)
	card_ui.played.connect(_on_card_played)
	hand.append(card_ui)

func _on_card_played(card_ui: CardUI) -> void:
	if combat_over:
		return
	var data: CardData = card_ui.card_data
	if energy < data.cost:
		return

	energy -= data.cost
	_apply_card(data)

	hand.erase(card_ui)
	card_ui.queue_free()
	discard_pile.append(data)

	update_all_ui()
	_check_combat_end()

func _apply_card(data: CardData) -> void:
	if data.damage > 0:
		_deal_damage_to_enemy(data.damage)
	if data.block > 0:
		player_block += data.block
	if data.heal > 0:
		player_hp = min(player_max_hp, player_hp + data.heal)
	if data.apply_vulnerable > 0:
		enemy_vulnerable += data.apply_vulnerable
	if data.apply_weak > 0:
		enemy_weak += data.apply_weak
	if data.apply_strength > 0:
		player_strength += data.apply_strength

func _deal_damage_to_enemy(base_damage: int) -> void:
	var dmg: int = base_damage + player_strength
	if enemy_vulnerable > 0:
		dmg = int(floor(dmg * 1.5))
	var remaining: int = dmg
	if enemy_block > 0:
		var absorbed: int = min(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = max(enemy_hp - remaining, 0)

func _deal_damage_to_player(base_damage: int) -> void:
	var dmg: int = base_damage
	if enemy_weak > 0:
		dmg = int(floor(dmg * 0.75))
	var remaining: int = dmg
	if player_block > 0:
		var absorbed: int = min(player_block, remaining)
		player_block -= absorbed
		remaining -= absorbed
	player_hp = max(player_hp - remaining, 0)

func _on_end_turn_pressed() -> void:
	if combat_over:
		return
	_discard_hand()
	_do_enemy_turn()

func _discard_hand() -> void:
	for card_ui in hand.duplicate():
		discard_pile.append(card_ui.card_data)
		card_ui.queue_free()
	hand.clear()

func _do_enemy_turn() -> void:
	enemy_block = 0
	var move: Dictionary = enemy_data.get_move(enemy_move_index)
	match move.get("type", ""):
		EnemyData.MOVE_TYPE_ATTACK:
			_deal_damage_to_player(int(move.get("value", 0)) + enemy_strength)
		EnemyData.MOVE_TYPE_DEFEND:
			enemy_block += int(move.get("value", 0))
		EnemyData.MOVE_TYPE_BUFF:
			enemy_strength += int(move.get("value", 0))
	enemy_move_index += 1

	if enemy_weak > 0:
		enemy_weak -= 1
	if enemy_vulnerable > 0:
		enemy_vulnerable -= 1

	update_all_ui()
	_check_combat_end()
	if not combat_over:
		start_player_turn()

func _check_combat_end() -> void:
	if enemy_hp <= 0:
		_show_result(true)
	elif player_hp <= 0:
		_show_result(false)

func _show_result(victory: bool) -> void:
	combat_over = true
	combat_victory = victory
	GameManager.player_hp = player_hp
	end_turn_button.disabled = true
	result_label.text = "Victory!" if victory else "Defeated..."
	result_panel.show()

func _on_result_button_pressed() -> void:
	GameManager.end_run(combat_victory)

func update_all_ui() -> void:
	enemy_hp_label.text = "HP: %d / %d%s" % [
		max(enemy_hp, 0), enemy_data.max_hp,
		("  (Block %d)" % enemy_block) if enemy_block > 0 else ""
	]
	intent_label.text = _get_intent_text()
	player_hp_label.text = "HP: %d / %d%s" % [
		max(player_hp, 0), player_max_hp,
		("  (Block %d)" % player_block) if player_block > 0 else ""
	]
	energy_label.text = "Energy: %d / %d" % [energy, MAX_ENERGY]
	draw_count_label.text = "Draw: %d" % draw_pile.size()
	discard_count_label.text = "Discard: %d" % discard_pile.size()
	for card_ui in hand:
		card_ui.set_playable(card_ui.card_data.cost <= energy)

func _get_intent_text() -> String:
	var move: Dictionary = enemy_data.get_move(enemy_move_index)
	var move_name: String = move.get("move_name", "???")
	match move.get("type", ""):
		EnemyData.MOVE_TYPE_ATTACK:
			return "Intent: %s — Attack %d" % [move_name, int(move.get("value", 0)) + enemy_strength]
		EnemyData.MOVE_TYPE_DEFEND:
			return "Intent: %s — Defend %d" % [move_name, int(move.get("value", 0))]
		EnemyData.MOVE_TYPE_BUFF:
			return "Intent: %s — Buff" % move_name
		_:
			return "Intent: %s" % move_name
