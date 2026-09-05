extends Control

const CARD_SCENE := preload("res://scenes/card/Card.tscn")
const ENEMY_PANEL_SCENE := preload("res://scenes/enemy_panel/EnemyPanel.tscn")

const MAX_ENERGY := 3
const HAND_SIZE := 5

@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var motivation_label: Label = %MotivationLabel
@onready var enemy_row: HBoxContainer = %EnemyRow
@onready var target_hint_label: Label = %TargetHintLabel
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var energy_label: Label = %EnergyLabel
@onready var draw_count_label: Label = %DrawCountLabel
@onready var discard_count_label: Label = %DiscardCountLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var result_panel: Control = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var result_button: Button = %ResultButton
@onready var clue_label: Label = %ClueLabel

var player_hp: int
var player_max_hp: int
var player_block: int = 0
var player_strength: int = 0
var player_weak: int = 0
var energy: int = 0

var character_id: String = ""

var enemies: Array[EnemyInstance] = []
var enemy_panels: Array[EnemyPanelUI] = []

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardUI] = []

## The card waiting for the player to tap an enemy to target, or null.
var pending_card: CardUI = null

var combat_over: bool = false
var combat_victory: bool = false

func _ready() -> void:
	player_max_hp = GameManager.player_max_hp
	player_hp = GameManager.player_hp
	character_id = GameManager.current_character.id if GameManager.current_character else ""

	if GameManager.current_character:
		motivation_label.text = GameManager.current_character.motivation
		player_portrait.texture = GameManager.current_character.portrait
	else:
		motivation_label.text = ""

	_spawn_enemies()

	draw_pile = GameManager.deck.duplicate()
	draw_pile.shuffle()

	target_hint_label.hide()
	result_panel.hide()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	result_button.pressed.connect(_on_result_button_pressed)

	start_player_turn()

func _spawn_enemies() -> void:
	var name_totals: Dictionary = {}
	for data in GameManager.next_enemies:
		name_totals[data.enemy_name] = name_totals.get(data.enemy_name, 0) + 1
	var name_seen: Dictionary = {}

	for data in GameManager.next_enemies:
		var display: String = data.enemy_name
		if name_totals[display] > 1:
			var seen: int = name_seen.get(display, 0) + 1
			name_seen[display] = seen
			display = "%s %d" % [display, seen]

		var instance := EnemyInstance.new(data, display)
		enemies.append(instance)

		var panel: EnemyPanelUI = ENEMY_PANEL_SCENE.instantiate()
		enemy_row.add_child(panel)
		panel.set_enemy(instance)
		panel.targeted.connect(_on_enemy_targeted)
		enemy_panels.append(panel)

func start_player_turn() -> void:
	# 보부상: sturdy travel gear keeps half of whatever block survived the enemies' turn.
	player_block = int(floor(player_block * 0.5)) if character_id == "merchant" else 0
	energy = MAX_ENERGY
	if player_weak > 0:
		player_weak -= 1
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

	if card_ui == pending_card:
		_clear_pending_target()
		return

	# Only damage needs the player to pick a specific enemy -- every current
	# non-damage enemy-effect card (Talisman) is the scholar's group-wide
	# debuff, where the choice of target wouldn't change anything anyway.
	if data.target_type == CardData.TargetType.ENEMY and data.damage > 0 and _alive_enemy_count() > 1:
		_begin_targeting(card_ui)
		return

	var target: EnemyInstance = _first_alive_enemy() if data.target_type == CardData.TargetType.ENEMY else null
	_resolve_card(card_ui, target)

func _begin_targeting(card_ui: CardUI) -> void:
	pending_card = card_ui
	card_ui.set_selected(true)
	target_hint_label.show()
	for i in enemies.size():
		enemy_panels[i].set_targetable(enemies[i].is_alive())

func _clear_pending_target() -> void:
	if pending_card:
		pending_card.set_selected(false)
	pending_card = null
	target_hint_label.hide()
	for panel in enemy_panels:
		panel.set_targetable(false)

func _on_enemy_targeted(panel: EnemyPanelUI) -> void:
	if pending_card == null:
		return
	var idx: int = enemy_panels.find(panel)
	if idx == -1 or not enemies[idx].is_alive():
		return
	var card_ui: CardUI = pending_card
	_clear_pending_target()
	_resolve_card(card_ui, enemies[idx])

func _resolve_card(card_ui: CardUI, target: EnemyInstance) -> void:
	var data: CardData = card_ui.card_data
	energy -= data.cost
	_apply_card(data, target)

	hand.erase(card_ui)
	card_ui.queue_free()
	discard_pile.append(data)

	update_all_ui()
	_check_combat_end()

func _apply_card(data: CardData, target: EnemyInstance) -> void:
	if data.damage > 0 and target:
		_deal_damage_to_enemy(target, data.damage)
		# 무사: attacks splash to one other enemy in the fight.
		if character_id == "warrior":
			_cleave(target, data.damage)
	if data.block > 0:
		player_block += data.block
	if data.heal > 0:
		player_hp = min(player_max_hp, player_hp + data.heal)
	if data.apply_vulnerable > 0:
		_apply_status_to_target_or_all(target, func(e): e.vulnerable += data.apply_vulnerable)
	if data.apply_weak > 0:
		_apply_status_to_target_or_all(target, func(e): e.weak += data.apply_weak)
	if data.apply_strength > 0:
		player_strength += data.apply_strength

func _apply_status_to_target_or_all(target: EnemyInstance, apply_fn: Callable) -> void:
	# 선비: debuffs land on the whole group instead of a single enemy.
	if character_id == "scholar":
		for e in enemies:
			if e.is_alive():
				apply_fn.call(e)
	elif target:
		apply_fn.call(target)

func _cleave(primary: EnemyInstance, base_damage: int) -> void:
	if _alive_enemy_count() <= 1:
		return
	for e in enemies:
		if e != primary and e.is_alive():
			_deal_damage_to_enemy(e, int(floor(base_damage * 0.5)), false)
			break

func _deal_damage_to_enemy(target: EnemyInstance, base_damage: int, apply_strength: bool = true) -> void:
	var dmg: int = base_damage + (player_strength if apply_strength else 0)
	if player_weak > 0:
		dmg = int(floor(dmg * 0.75))
	if target.vulnerable > 0:
		dmg = int(floor(dmg * 1.5))
	var remaining: int = dmg
	if target.block > 0:
		var absorbed: int = min(target.block, remaining)
		target.block -= absorbed
		remaining -= absorbed
	target.hp = max(target.hp - remaining, 0)

func _deal_damage_to_player(acting_enemy: EnemyInstance, base_damage: int) -> void:
	var dmg: int = base_damage
	if acting_enemy.weak > 0:
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
	_clear_pending_target()
	_discard_hand()
	_do_enemy_turn()

func _discard_hand() -> void:
	for card_ui in hand.duplicate():
		discard_pile.append(card_ui.card_data)
		card_ui.queue_free()
	hand.clear()

func _do_enemy_turn() -> void:
	for e in enemies:
		if not e.is_alive():
			continue
		e.block = 0
		var move: Dictionary = e.get_move()
		match move.get("type", ""):
			EnemyData.MOVE_TYPE_ATTACK:
				_deal_damage_to_player(e, int(move.get("value", 0)) + e.strength)
			EnemyData.MOVE_TYPE_DEFEND:
				e.block += int(move.get("value", 0))
			EnemyData.MOVE_TYPE_BUFF:
				e.strength += int(move.get("value", 0))
			EnemyData.MOVE_TYPE_WEAKEN:
				player_weak += int(move.get("value", 0))
		e.move_index += 1
		if e.weak > 0:
			e.weak -= 1
		if e.vulnerable > 0:
			e.vulnerable -= 1
		if player_hp <= 0:
			break

	update_all_ui()
	_check_combat_end()
	if not combat_over:
		start_player_turn()

func _alive_enemy_count() -> int:
	var n := 0
	for e in enemies:
		if e.is_alive():
			n += 1
	return n

func _first_alive_enemy() -> EnemyInstance:
	for e in enemies:
		if e.is_alive():
			return e
	return null

func _check_combat_end() -> void:
	if _alive_enemy_count() == 0:
		_show_result(true)
	elif player_hp <= 0:
		_show_result(false)

func _show_result(victory: bool) -> void:
	combat_over = true
	combat_victory = victory
	GameManager.player_hp = player_hp
	end_turn_button.disabled = true
	_clear_pending_target()
	result_label.text = "승리!" if victory else "패배..."
	if victory and GameManager.current_character:
		clue_label.text = GameManager.current_character.clue_text
		clue_label.show()
	else:
		clue_label.hide()
	result_panel.show()

func _on_result_button_pressed() -> void:
	GameManager.end_run(combat_victory)

func update_all_ui() -> void:
	player_hp_label.text = "체력: %d / %d%s%s" % [
		max(player_hp, 0), player_max_hp,
		("  (방어 %d)" % player_block) if player_block > 0 else "",
		("  (약화 %d)" % player_weak) if player_weak > 0 else ""
	]
	energy_label.text = "기력: %d / %d" % [energy, MAX_ENERGY]
	draw_count_label.text = "덱: %d" % draw_pile.size()
	discard_count_label.text = "버림패: %d" % discard_pile.size()
	for panel in enemy_panels:
		panel.update_display()
	for card_ui in hand:
		card_ui.set_playable(card_ui.card_data.cost <= energy)
