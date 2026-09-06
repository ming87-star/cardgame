extends Control

const ENEMY_PANEL_SCENE := preload("res://scenes/enemy_panel/EnemyPanel.tscn")
const CARD_SCENE := preload("res://scenes/card/Card.tscn")

const MAX_ENERGY := 3
const HAND_SIZE := 5

const DAMAGE_COLOR := Color(0.7, 0.16, 0.12)
const BLOCK_COLOR := Color(0.2, 0.33, 0.5)
const HEAL_COLOR := Color(0.24, 0.45, 0.26)

@onready var background: TextureRect = %Background
@onready var player_figure: PlayerFigureUI = %PlayerFigure
@onready var enemy_row: HBoxContainer = %EnemyRow
@onready var fx_layer: Control = %FxLayer
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

var combat_over: bool = false
var combat_victory: bool = false

## True while an action is animating. Input stays locked for the whole
## sequence so the player can follow who acted, in what order.
var is_busy: bool = false

func _ready() -> void:
	player_max_hp = GameManager.player_max_hp
	player_hp = GameManager.player_hp
	character_id = GameManager.current_character.id if GameManager.current_character else ""

	if GameManager.next_background:
		background.texture = GameManager.next_background

	player_figure.combat = self
	if GameManager.current_character:
		player_figure.set_portrait(GameManager.current_character.portrait)

	_spawn_enemies()

	draw_pile = GameManager.deck.duplicate()
	draw_pile.shuffle()

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
		panel.combat = self
		panel.set_enemy(instance)
		enemy_panels.append(panel)

func start_player_turn() -> void:
	# 보부상: sturdy travel gear keeps half of whatever block survived the enemies' turn.
	player_block = int(floor(player_block * 0.5)) if character_id == "merchant" else 0
	energy = MAX_ENERGY
	if player_weak > 0:
		player_weak -= 1
	draw_cards(HAND_SIZE)
	end_turn_button.disabled = false
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
	hand.append(card_ui)

# --- targeting rules -------------------------------------------------------

## True when the card does something to an enemy, so it must be dropped on one.
func card_can_target_enemy(data: CardData) -> bool:
	if data.target_type != CardData.TargetType.ENEMY:
		return false
	return data.damage > 0 or data.apply_vulnerable > 0 or data.apply_weak > 0

## Anything with no enemy-directed effect is played on the player themselves.
func card_can_target_self(data: CardData) -> bool:
	return not card_can_target_enemy(data)

## 선비's debuffs land on the whole group no matter which enemy is picked.
func card_hits_all_enemies(data: CardData) -> bool:
	if character_id != "scholar":
		return false
	return data.apply_vulnerable > 0 or data.apply_weak > 0

## 무사's attacks splash onto one other enemy.
func card_splashes(data: CardData) -> bool:
	return character_id == "warrior" and data.damage > 0 and _alive_enemy_count() > 1

# --- card play -------------------------------------------------------------

## Called by PlayerFigureUI._drop_data (self cards) and EnemyPanelUI._drop_data
## (enemy cards). Returns false without side effects when the play isn't legal,
## so a rejected drop just leaves the card in hand with nothing to undo.
func try_play_card(card_ui: CardUI, preferred_target: EnemyInstance) -> bool:
	if combat_over or is_busy or not hand.has(card_ui):
		return false
	var data: CardData = card_ui.card_data
	if energy < data.cost:
		return false

	var target: EnemyInstance = null
	if card_can_target_enemy(data):
		if preferred_target == null or not preferred_target.is_alive():
			return false
		target = preferred_target

	_resolve_card(card_ui, target)
	return true

func _resolve_card(card_ui: CardUI, target: EnemyInstance) -> void:
	is_busy = true
	var data: CardData = card_ui.card_data
	energy -= data.cost

	hand.erase(card_ui)
	card_ui.queue_free()
	discard_pile.append(data)
	update_all_ui()

	if data.damage > 0 and target:
		await player_figure.play_attack()
		await _strike_enemy(target, data.damage, true)
		if character_id == "warrior":
			await _cleave(target, data.damage)
	else:
		await player_figure.play_pulse()

	if data.block > 0:
		player_block += data.block
		_popup(player_figure, "+%d 방어" % data.block, BLOCK_COLOR)
	if data.heal > 0:
		var healed: int = min(data.heal, player_max_hp - player_hp)
		player_hp += healed
		_popup(player_figure, "+%d" % healed, HEAL_COLOR)
	if data.apply_strength > 0:
		player_strength += data.apply_strength
		_popup(player_figure, "+%d 힘" % data.apply_strength, BLOCK_COLOR)
	if data.apply_vulnerable > 0:
		_apply_status(target, func(e: EnemyInstance) -> void: e.vulnerable += data.apply_vulnerable)
	if data.apply_weak > 0:
		_apply_status(target, func(e: EnemyInstance) -> void: e.weak += data.apply_weak)

	is_busy = false
	update_all_ui()
	_check_combat_end()

func _strike_enemy(target: EnemyInstance, base_damage: int, apply_strength: bool) -> void:
	var dealt: int = _deal_damage_to_enemy(target, base_damage, apply_strength)
	var panel: EnemyPanelUI = _panel_for(target)
	if panel:
		_popup(panel, str(dealt), DAMAGE_COLOR)
		await panel.take_hit()
	update_all_ui()

func _cleave(primary: EnemyInstance, base_damage: int) -> void:
	if _alive_enemy_count() <= 1:
		return
	for e in enemies:
		if e != primary and e.is_alive():
			await _strike_enemy(e, int(floor(base_damage * 0.5)), false)
			return

func _apply_status(target: EnemyInstance, apply_fn: Callable) -> void:
	# 선비: debuffs land on the whole group instead of a single enemy.
	if character_id == "scholar":
		for e in enemies:
			if e.is_alive():
				apply_fn.call(e)
	elif target:
		apply_fn.call(target)

func _deal_damage_to_enemy(target: EnemyInstance, base_damage: int, apply_strength: bool = true) -> int:
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
	return dmg

func _deal_damage_to_player(acting_enemy: EnemyInstance, base_damage: int) -> int:
	var dmg: int = base_damage
	if acting_enemy.weak > 0:
		dmg = int(floor(dmg * 0.75))
	var remaining: int = dmg
	if player_block > 0:
		var absorbed: int = min(player_block, remaining)
		player_block -= absorbed
		remaining -= absorbed
	player_hp = max(player_hp - remaining, 0)
	return dmg

# --- turn flow -------------------------------------------------------------

func _on_end_turn_pressed() -> void:
	if combat_over or is_busy:
		return
	_discard_hand()
	_do_enemy_turn()

func _discard_hand() -> void:
	for card_ui in hand.duplicate():
		discard_pile.append(card_ui.card_data)
		card_ui.queue_free()
	hand.clear()

## Enemies act one at a time with a beat between them, each one stepping in
## before its effect lands, so the order of play is visible rather than implied.
func _do_enemy_turn() -> void:
	is_busy = true
	end_turn_button.disabled = true
	update_all_ui()

	for e in enemies:
		if not e.is_alive():
			continue
		e.block = 0
		var move: Dictionary = e.get_move()
		var panel: EnemyPanelUI = _panel_for(e)
		await get_tree().create_timer(0.14).timeout

		match move.get("type", ""):
			EnemyData.MOVE_TYPE_ATTACK:
				if panel:
					await panel.play_attack()
				var dealt: int = _deal_damage_to_player(e, int(move.get("value", 0)) + e.strength)
				_popup(player_figure, str(dealt), DAMAGE_COLOR)
				await player_figure.take_hit()
			EnemyData.MOVE_TYPE_DEFEND:
				var block_gain: int = int(move.get("value", 0))
				if panel:
					await panel.play_pulse()
				e.block += block_gain
				if panel:
					_popup(panel, "+%d 방어" % block_gain, BLOCK_COLOR)
			EnemyData.MOVE_TYPE_BUFF:
				if panel:
					await panel.play_pulse()
				e.strength += int(move.get("value", 0))
				if panel:
					_popup(panel, "+힘", BLOCK_COLOR)
			EnemyData.MOVE_TYPE_WEAKEN:
				if panel:
					await panel.play_pulse()
				player_weak += int(move.get("value", 0))
				_popup(player_figure, "약화", DAMAGE_COLOR)

		e.move_index += 1
		if e.weak > 0:
			e.weak -= 1
		if e.vulnerable > 0:
			e.vulnerable -= 1
		update_all_ui()
		if player_hp <= 0:
			break

	is_busy = false
	_check_combat_end()
	if not combat_over:
		start_player_turn()

func _alive_enemy_count() -> int:
	var n := 0
	for e in enemies:
		if e.is_alive():
			n += 1
	return n

func _panel_for(target: EnemyInstance) -> EnemyPanelUI:
	var idx: int = enemies.find(target)
	return enemy_panels[idx] if idx != -1 else null

func _check_combat_end() -> void:
	if combat_over:
		return
	if _alive_enemy_count() == 0:
		_show_result(true)
	elif player_hp <= 0:
		_show_result(false)

func _show_result(victory: bool) -> void:
	combat_over = true
	combat_victory = victory
	GameManager.player_hp = player_hp
	end_turn_button.disabled = true
	result_label.text = "승리!" if victory else "패배..."
	if victory and GameManager.current_character:
		clue_label.text = GameManager.current_character.clue_text
		clue_label.show()
	else:
		clue_label.hide()
	result_panel.show()

func _on_result_button_pressed() -> void:
	GameManager.end_run(combat_victory)

# --- presentation ----------------------------------------------------------

func update_all_ui() -> void:
	player_figure.set_stats(player_hp, player_max_hp, energy, MAX_ENERGY,
		player_block, player_weak, player_strength)
	draw_count_label.text = "덱 %d" % draw_pile.size()
	discard_count_label.text = "버림패 %d" % discard_pile.size()

	for panel in enemy_panels:
		panel.update_display()
	for card_ui in hand:
		card_ui.set_playable(not is_busy and card_ui.card_data.cost <= energy)

## Floating number over a figure, so every point of damage or block is
## attached to whoever it happened to.
func _popup(figure: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.976, 0.961, 0.925, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(label)

	var anchor: Vector2 = figure.global_position - fx_layer.global_position
	label.position = anchor + Vector2(figure.size.x * 0.5 - 16, figure.size.y * 0.35)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position", label.position + Vector2(0, -46), 0.75) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.75).set_delay(0.2)
	tw.chain().tween_callback(label.queue_free)

# --- drag affordances ------------------------------------------------------

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			_show_drag_hints(get_viewport().gui_get_drag_data())
		NOTIFICATION_DRAG_END:
			_clear_drag_hints()

func _show_drag_hints(data: Variant) -> void:
	if not (data is Dictionary and data.has("card_ui")):
		return
	var card_data: CardData = data["card_ui"].card_data
	if card_data == null:
		return

	if card_can_target_self(card_data):
		player_figure.set_drag_state(GroundMarker.State.TARGET)
		return

	var hits_all: bool = card_hits_all_enemies(card_data)
	var splashes: bool = card_splashes(card_data)
	for panel in enemy_panels:
		if hits_all:
			panel.set_drag_state(GroundMarker.State.AFFECTED, "전체")
		elif splashes:
			panel.set_drag_state(GroundMarker.State.TARGET, "여파")
		else:
			panel.set_drag_state(GroundMarker.State.TARGET)

func _clear_drag_hints() -> void:
	player_figure.set_drag_state(GroundMarker.State.REST)
	for panel in enemy_panels:
		panel.set_drag_state(GroundMarker.State.REST)
