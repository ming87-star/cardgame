extends Control

const ENEMY_PANEL_SCENE := preload("res://scenes/enemy_panel/EnemyPanel.tscn")
const CARD_SCENE := preload("res://scenes/card/Card.tscn")

const MAX_ENERGY := 3
const HAND_SIZE := 5

## The road is a short line of standing places. The player walks up from lane
## 0; enemies come down from the far end. Distance between two figures is the
## difference of their lanes, and that number is what every card is measured
## against.
const LANE_COUNT := 6
## The player starts one lane in, not against the edge, so giving ground is a
## real option from the first turn.
const PLAYER_START_LANE := 1
const FIRST_ENEMY_LANE := 3
const LANE_MARGIN := 20.0
const FIGURE_WIDTH := 168.0

## 무사's 기세 stops climbing here, and cleaves once it reaches CLEAVE_AT.
const MAX_MOMENTUM := 3
const CLEAVE_AT := 2

## Armour a shouted-down enemy digs in for. Without this, 저지 would delete a
## whole enemy turn for one energy and the road could be held forever.
const ROOTED_BLOCK := 6

const DAMAGE_COLOR := Color(0.7, 0.16, 0.12)
const BLOCK_COLOR := Color(0.2, 0.33, 0.5)
const HEAL_COLOR := Color(0.24, 0.45, 0.26)

@onready var background: TextureRect = %Background
@onready var tray_art: TextureRect = %TrayArt
@onready var lanes_root: Control = %Lanes
@onready var player_figure: PlayerFigureUI = %PlayerFigure
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

## Where the player stands on the road.
var player_lane: int = PLAYER_START_LANE

## 선비: bonus damage that builds while he keeps the same enemy in his sights,
## and is lost the moment he moves or looks elsewhere.
var aim_stacks: int = 0
var aim_target: EnemyInstance = null

## 무사: bonus damage earned by walking into the fight, thrown away by
## giving ground.
var momentum: int = 0

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
		player_figure.set_character(GameManager.current_character)
		tray_art.texture = GameManager.current_character.card_tray

	_spawn_enemies()
	lanes_root.resized.connect(_layout_figures.bind(false))
	_layout_figures(false)

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

	var lane: int = FIRST_ENEMY_LANE
	for data in GameManager.next_enemies:
		var display: String = data.enemy_name
		if name_totals[display] > 1:
			var seen: int = name_seen.get(display, 0) + 1
			name_seen[display] = seen
			display = "%s %d" % [display, seen]

		var instance := EnemyInstance.new(data, display)
		instance.lane = mini(lane, LANE_COUNT - 1)
		lane += 1
		enemies.append(instance)

		var panel: EnemyPanelUI = ENEMY_PANEL_SCENE.instantiate()
		lanes_root.add_child(panel)
		panel.combat = self
		panel.set_enemy(instance)
		enemy_panels.append(panel)

# --- the road ---------------------------------------------------------------

func distance_to(enemy: EnemyInstance) -> int:
	return enemy.lane - player_lane

func is_lane_free(lane: int, mover: EnemyInstance = null) -> bool:
	if lane < 0 or lane >= LANE_COUNT:
		return false
	if lane == player_lane and mover != null:
		return false
	for e in enemies:
		if e != mover and e.is_alive() and e.lane == lane:
			return false
	return true

func _lane_x(lane: int) -> float:
	var usable: float = maxf(lanes_root.size.x - FIGURE_WIDTH - LANE_MARGIN * 2.0, 1.0)
	return LANE_MARGIN + usable * (float(lane) / float(LANE_COUNT - 1))

func _layout_figures(animate: bool = true) -> void:
	_place(player_figure, player_lane, animate)
	for i in enemies.size():
		_place(enemy_panels[i], enemies[i].lane, animate)

func _place(figure: Control, lane: int, animate: bool) -> void:
	figure.size = figure.custom_minimum_size
	var target := Vector2(_lane_x(lane), lanes_root.size.y - figure.custom_minimum_size.y)
	if not animate:
		figure.position = target
		return
	var tw := create_tween()
	tw.tween_property(figure, "position", target, 0.26) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Returns true if the player actually shifted. Movement stops at the ends of
## the road and never walks through anyone.
func _move_player(steps: int) -> bool:
	var step: int = signi(steps)
	var start: int = player_lane
	for i in absi(steps):
		var next: int = player_lane + step
		if next < 0 or next >= LANE_COUNT:
			break
		var blocked := false
		for e in enemies:
			if e.is_alive() and e.lane == next:
				blocked = true
				break
		if blocked:
			break
		player_lane = next

	# 선비 loses his sight-picture the moment he shifts his feet; 무사 trades
	# ground for 기세 in one direction only.
	aim_stacks = 0
	aim_target = null
	if character_id == "warrior":
		momentum = 0 if steps < 0 else mini(momentum + 1, MAX_MOMENTUM)
	_layout_figures()
	return player_lane != start

## Giving ground is 선비's whole game, so it must never be unavailable: with
## his back to the end of the road he shoves whatever has closed on him
## instead, and the gap opens either way.
func _shove_nearest() -> bool:
	var closest: EnemyInstance = null
	for e in enemies:
		if not e.is_alive():
			continue
		if closest == null or e.lane < closest.lane:
			closest = e
	if closest == null:
		return false
	var next: int = closest.lane + 1
	if not is_lane_free(next, closest):
		return false
	closest.lane = next
	_layout_figures()
	var panel: EnemyPanelUI = _panel_for(closest)
	if panel:
		_popup(panel, "밀려남", BLOCK_COLOR)
	return true

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

## Reach check: a bow can't be used on something in your face, and a sabre
## can't touch what you haven't closed on.
func card_in_range(data: CardData, enemy: EnemyInstance) -> bool:
	var d: int = distance_to(enemy)
	return d >= data.range_min and d <= data.range_max

func can_play_on_enemy(data: CardData, enemy: EnemyInstance) -> bool:
	return card_can_target_enemy(data) and enemy.is_alive() and card_in_range(data, enemy)

## 선비's debuffs land on the whole group no matter which enemy is picked.
func card_hits_all_enemies(data: CardData) -> bool:
	if character_id != "scholar":
		return false
	return data.apply_vulnerable > 0 or data.apply_weak > 0

## 무사 splashes only once he has built enough 기세 to carry the swing through.
func card_splashes(data: CardData) -> bool:
	return character_id == "warrior" and data.damage > 0 \
		and momentum >= CLEAVE_AT and _alive_enemy_count() > 1

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
		if preferred_target == null or not can_play_on_enemy(data, preferred_target):
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

	if data.move_lanes != 0:
		var stepped: bool = _move_player(data.move_lanes)
		if not stepped and data.move_lanes < 0:
			_shove_nearest()
		await player_figure.play_pulse()

	if data.damage > 0 and target:
		var bonus: int = _class_damage_bonus(target)
		await player_figure.play_attack()
		await _strike_enemy(target, data.damage + bonus, true)
		_advance_aim(target)
		if card_splashes(data):
			await _cleave(target, data.damage)
	elif data.move_lanes == 0:
		await player_figure.play_pulse()

	if data.block > 0:
		player_block += data.block
		_popup(player_figure, "+%d 방어" % data.block, BLOCK_COLOR)
	if data.heal > 0:
		var healed: int = mini(data.heal, player_max_hp - player_hp)
		player_hp += healed
		_popup(player_figure, "+%d" % healed, HEAL_COLOR)
	if data.apply_strength > 0:
		player_strength += data.apply_strength
		_popup(player_figure, "+%d 힘" % data.apply_strength, BLOCK_COLOR)
	if data.apply_root > 0:
		# A shout carries down the whole road, so it holds every enemy at once --
		# except any that shrugged off the last one.
		for e in enemies:
			if e.is_alive() and e.can_be_rooted():
				e.rooted += data.apply_root
				var panel: EnemyPanelUI = _panel_for(e)
				if panel:
					_popup(panel, "저지", BLOCK_COLOR)
	if data.apply_vulnerable > 0:
		_apply_status(target, func(e: EnemyInstance) -> void: e.vulnerable += data.apply_vulnerable)
	if data.apply_weak > 0:
		_apply_status(target, func(e: EnemyInstance) -> void: e.weak += data.apply_weak)

	is_busy = false
	update_all_ui()
	_check_combat_end()

## 선비 adds whatever 조준 he has built on this target; 무사 adds his 기세.
func _class_damage_bonus(target: EnemyInstance) -> int:
	if character_id == "scholar":
		return aim_stacks if aim_target == target else 0
	if character_id == "warrior":
		return momentum
	return 0

func _advance_aim(target: EnemyInstance) -> void:
	if character_id != "scholar":
		return
	aim_stacks = aim_stacks + 1 if aim_target == target else 1
	aim_target = target

func _strike_enemy(target: EnemyInstance, base_damage: int, apply_strength: bool) -> void:
	var dealt: int = _deal_damage_to_enemy(target, base_damage, apply_strength)
	var panel: EnemyPanelUI = _panel_for(target)
	if panel:
		_popup(panel, str(dealt), DAMAGE_COLOR)
		await panel.take_hit()
	update_all_ui()

func _cleave(primary: EnemyInstance, base_damage: int) -> void:
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
		var absorbed: int = mini(target.block, remaining)
		target.block -= absorbed
		remaining -= absorbed
	target.hp = maxi(target.hp - remaining, 0)
	return dmg

func _deal_damage_to_player(acting_enemy: EnemyInstance, base_damage: int) -> int:
	var dmg: int = base_damage
	if acting_enemy.weak > 0:
		dmg = int(floor(dmg * 0.75))
	var remaining: int = dmg
	if player_block > 0:
		var absorbed: int = mini(player_block, remaining)
		player_block -= absorbed
		remaining -= absorbed
	player_hp = maxi(player_hp - remaining, 0)
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
## An enemy that wants to attack from too far away walks instead, and keeps its
## attack queued -- giving ground buys time, it never cancels the blow.
func _do_enemy_turn() -> void:
	is_busy = true
	end_turn_button.disabled = true
	update_all_ui()

	for e in enemies:
		if not e.is_alive():
			continue
		e.block = 0
		var move: Dictionary = e.get_intent(distance_to(e))
		var panel: EnemyPanelUI = _panel_for(e)
		await get_tree().create_timer(0.14).timeout

		var executed := true
		match move.get("type", ""):
			EnemyData.MOVE_TYPE_ROOTED:
				# Shouted down rather than stopped dead: it plants itself and
				# braces, so holding the line repeatedly hands the enemy armour.
				# That is what keeps 일갈 from being a free lock.
				if panel:
					await panel.play_pulse()
				e.block += ROOTED_BLOCK
				if panel:
					_popup(panel, "+%d 방어" % ROOTED_BLOCK, BLOCK_COLOR)
				executed = false # held in place, and its attack is still coming
			EnemyData.MOVE_TYPE_ADVANCE:
				var next: int = e.lane - 1
				if is_lane_free(next, e):
					e.lane = next
					_layout_figures()
					await get_tree().create_timer(0.3).timeout
				else:
					# Stuck behind whoever is in front of it.
					if panel:
						await panel.play_pulse()
				executed = false # the queued attack is still waiting
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

		if executed:
			e.move_index += 1
		if e.weak > 0:
			e.weak -= 1
		if e.vulnerable > 0:
			e.vulnerable -= 1
		if e.rooted > 0:
			e.rooted -= 1
			e.root_immune = 1
		elif e.root_immune > 0:
			e.root_immune -= 1
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
		player_block, player_weak, player_strength, aim_stacks, momentum)
	draw_count_label.text = "덱 %d" % draw_pile.size()
	discard_count_label.text = "버림패 %d" % discard_pile.size()

	for panel in enemy_panels:
		panel.set_distance(distance_to(panel.enemy))
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

## Lighting up only the figures a card can actually reach doubles as the range
## indicator: an enemy too far up the road simply stays dark.
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
		if not can_play_on_enemy(card_data, panel.enemy):
			panel.set_drag_state(GroundMarker.State.REST)
		elif hits_all:
			panel.set_drag_state(GroundMarker.State.AFFECTED, "전체")
		elif splashes:
			panel.set_drag_state(GroundMarker.State.TARGET, "여파")
		else:
			panel.set_drag_state(GroundMarker.State.TARGET)

func _clear_drag_hints() -> void:
	player_figure.set_drag_state(GroundMarker.State.REST)
	for panel in enemy_panels:
		panel.set_drag_state(GroundMarker.State.REST)
