class_name MultiplayerTable
extends Control

signal leave_requested
signal sfx_requested(name: String)

const GOLD := Color("#e3bd62")
const PALE_GOLD := Color("#f4dfaa")
const CREAM := Color("#f1e7cf")
const MUTED := Color("#b8a98e")
const GREEN := Color("#597a43")
const RED := Color("#9d493b")

var session: NetworkSession
var world: TavernWorld
var config: Dictionary
var match_state := TableMatch.new()
var _is_host := false
var _flow_token := 0
var _bot_running := false
var _rendered_roll_id := -1
var _rendered_event_id := -1

var seat_cards: Array[PanelContainer] = []
var seat_name_labels: Array[Label] = []
var seat_score_labels: Array[Label] = []
var status_label: Label
var turn_label: Label
var hint_label: Label
var kept_label: Label
var dice_row: HBoxContainer
var history_box: VBoxContainer
var roll_button: Button
var keep_button: Button
var bank_button: Button


func configure(network_session: NetworkSession, tavern_world: TavernWorld, match_config: Dictionary) -> void:
	session = network_session
	world = tavern_world
	config = match_config.duplicate(true)
	_is_host = session.is_host
	match_state.setup(
		config.get("seats", []),
		int(config.get("target_score", 4000)),
		int(config.get("seed", 1))
	)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	session.game_action_received.connect(_on_game_action_received)
	session.opponent_disconnected.connect(_on_peer_disconnected)
	if world.has_method("configure_table_seats"):
		world.configure_table_seats(match_state.seats, session.local_peer_id())
	_render_state()
	if _is_host:
		_publish_state()
		_schedule_bot()


func _exit_tree() -> void:
	_flow_token += 1
	if is_instance_valid(session) and session.game_action_received.is_connected(_on_game_action_received):
		session.game_action_received.disconnect(_on_game_action_received)
	if is_instance_valid(session) and session.opponent_disconnected.is_connected(_on_peer_disconnected):
		session.opponent_disconnected.disconnect(_on_peer_disconnected)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE and is_instance_valid(roll_button) and not roll_button.disabled:
		_request_action("roll")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_E and match_state.phase == TableMatch.PHASE_SELECT:
		_toggle_hovered_die()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F and is_instance_valid(keep_button) and not keep_button.disabled:
		_request_action("keep")
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_Q, KEY_ENTER] and is_instance_valid(bank_button) and not bank_button.disabled:
		_request_action("bank")
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)
	add_child(outer)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	outer.add_child(layout)

	var seats_row := HBoxContainer.new()
	seats_row.add_theme_constant_override("separation", 9)
	seats_row.custom_minimum_size.y = 94
	layout.add_child(seats_row)
	for index in range(NetworkSession.MAX_PLAYERS):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _panel_style(Color("#20140ddd"), Color("#654c30"), 2, 10))
		seats_row.add_child(card)
		seat_cards.append(card)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		var name_label := _label("Wolne miejsce", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		var score_label := _label("—", 22, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(name_label)
		box.add_child(score_label)
		seat_name_labels.append(name_label)
		seat_score_labels.append(score_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)

	var play_panel := PanelContainer.new()
	play_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_panel.add_theme_stylebox_override("panel", _panel_style(Color("#160d0859"), Color("#86633aaa"), 1, 14))
	body.add_child(play_panel)
	var play := VBoxContainer.new()
	play.add_theme_constant_override("separation", 8)
	play_panel.add_child(play)

	status_label = _label("STÓŁ SIECIOWY", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	turn_label = _label("", 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	play.add_child(status_label)
	play.add_child(turn_label)

	var dice_center := CenterContainer.new()
	dice_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_center.custom_minimum_size.y = 150
	play.add_child(dice_center)
	dice_row = HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 9)
	dice_center.add_child(dice_row)

	hint_label = _label("", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	kept_label = _label("Odłożone: —", 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	play.add_child(hint_label)
	play.add_child(kept_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	play.add_child(actions)
	roll_button = _button("RZUĆ  [SPACJA]", Color("#6f5430"), 180)
	keep_button = _button("ODŁÓŻ I RZUĆ  [F]", Color("#6f5430"), 190)
	bank_button = _button("ZAPISZ  [Q]", GREEN, 170)
	roll_button.pressed.connect(_request_action.bind("roll", {}))
	keep_button.pressed.connect(_request_action.bind("keep", {}))
	bank_button.pressed.connect(_request_action.bind("bank", {}))
	actions.add_child(roll_button)
	actions.add_child(keep_button)
	actions.add_child(bank_button)

	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size.x = 280
	log_panel.add_theme_stylebox_override("panel", _panel_style(Color("#17100cdd"), Color("#5f4930"), 2, 12))
	body.add_child(log_panel)
	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 7)
	log_panel.add_child(log_box)
	log_box.add_child(_label("PRZEBIEG GRY", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	history_box = VBoxContainer.new()
	history_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_child(history_box)
	var leave := Button.new()
	leave.text = "Opuść stół"
	leave.flat = true
	leave.add_theme_color_override("font_color", MUTED)
	leave.pressed.connect(func() -> void: leave_requested.emit())
	log_box.add_child(leave)


func _request_action(action: String, payload := {}) -> void:
	if _is_host:
		_handle_host_action(session.local_peer_id(), action, payload)
	else:
		session.send_game_action(action, payload)


func _on_die_pressed(index: int) -> void:
	sfx_requested.emit("die_select")
	_request_action("toggle", {"index": index})


func _toggle_hovered_die() -> void:
	if not match_state.can_control(session.local_peer_id()):
		return
	var table_index := world.die_at_screen_position(
		get_viewport().get_mouse_position(),
		get_viewport_rect().size
	)
	if table_index >= 0 and table_index < match_state.current_dice.size():
		_on_die_pressed(table_index)
		return
	var fallback := -1
	for child in dice_row.get_children():
		if child is DieView and not child.locked:
			if fallback < 0:
				fallback = child.die_index
			if child.hovered:
				_on_die_pressed(child.die_index)
				return
	if fallback >= 0:
		_on_die_pressed(fallback)


func _on_game_action_received(peer_id: int, action: String, payload: Dictionary) -> void:
	if _is_host:
		if action != "state":
			_handle_host_action(peer_id, action, payload)
	elif action == "state":
		var old_roll := match_state.roll_id
		if match_state.apply_snapshot(payload):
			_render_state(old_roll != match_state.roll_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if not _is_host:
		return
	for seat in match_state.seats:
		if int(seat.peer_id) == peer_id:
			seat.peer_id = -1000 - int(seat.seat)
			seat.is_bot = true
			seat.nickname = "%s (bot)" % seat.nickname
			match_state.revision += 1
			match_state.event_id += 1
			match_state.last_event = "%s rozłączył się — miejsce przejmuje bot." % seat.nickname
			_publish_state()
			_schedule_bot()
			return


func _handle_host_action(peer_id: int, action: String, payload: Dictionary) -> void:
	var changed := false
	match action:
		"roll":
			changed = match_state.roll(peer_id)
			if changed:
				sfx_requested.emit("dice_roll")
		"toggle":
			changed = match_state.toggle_die(peer_id, int(payload.get("index", -1)))
			if changed:
				sfx_requested.emit("die_select")
		"keep":
			changed = match_state.keep_and_continue(peer_id)
		"bank":
			changed = match_state.bank(peer_id)
			if changed:
				sfx_requested.emit("coin_bank")
	if not changed:
		return
	_publish_state()
	if match_state.phase == TableMatch.PHASE_FARKLE:
		sfx_requested.emit("farkle")
		_resolve_farkle_later()
	else:
		_schedule_bot()


func _publish_state() -> void:
	_render_state()
	if _is_host:
		session.send_game_action("state", match_state.snapshot())


func _resolve_farkle_later() -> void:
	var token := _flow_token
	await get_tree().create_timer(1.35).timeout
	if token != _flow_token or not _is_host or match_state.phase != TableMatch.PHASE_FARKLE:
		return
	match_state.resolve_farkle()
	_publish_state()
	_schedule_bot()


func _schedule_bot() -> void:
	if not _is_host or _bot_running or match_state.phase == TableMatch.PHASE_GAME_OVER:
		return
	if match_state.active_player().is_bot:
		_run_bot(_flow_token)


func _run_bot(token: int) -> void:
	_bot_running = true
	while token == _flow_token and _is_host and match_state.active_player().is_bot:
		if match_state.phase == TableMatch.PHASE_AWAIT_ROLL:
			await get_tree().create_timer(0.7).timeout
			if token != _flow_token:
				break
			match_state.roll(0, true)
			sfx_requested.emit("dice_roll")
			_publish_state()
			if match_state.phase == TableMatch.PHASE_FARKLE:
				sfx_requested.emit("farkle")
				await get_tree().create_timer(1.25).timeout
				if token == _flow_token:
					match_state.resolve_farkle()
					_publish_state()
				continue
		await get_tree().create_timer(0.75).timeout
		if token != _flow_token or match_state.phase != TableMatch.PHASE_SELECT:
			break
		var best := match_state.bot_best_selection()
		match_state.set_bot_selection(best)
		sfx_requested.emit("die_select")
		_publish_state()
		await get_tree().create_timer(0.65).timeout
		if token != _flow_token:
			break
		if match_state.bot_should_bank():
			match_state.bank(0, true)
			sfx_requested.emit("coin_bank")
		else:
			match_state.keep_and_continue(0, true)
		_publish_state()
		if match_state.phase == TableMatch.PHASE_GAME_OVER:
			sfx_requested.emit("win_fanfare")
			break
	_bot_running = false
	if token == _flow_token:
		_schedule_bot()


func _render_state(force_throw := false) -> void:
	for index in range(NetworkSession.MAX_PLAYERS):
		var occupied := index < match_state.seats.size()
		seat_cards[index].visible = true
		if occupied:
			var seat := match_state.seats[index]
			seat_name_labels[index].text = ("%s 🤖" % seat.nickname) if seat.is_bot else str(seat.nickname)
			seat_score_labels[index].text = "%d pkt" % int(seat.score)
			var active := index == match_state.active_seat and match_state.phase != TableMatch.PHASE_GAME_OVER
			seat_cards[index].add_theme_stylebox_override("panel", _panel_style(
				Color("#2c1c12ee") if active else Color("#20140ddd"),
				GOLD if active else Color("#654c30"),
				3 if active else 2,
				10
			))
		else:
			seat_name_labels[index].text = "Wolne miejsce"
			seat_score_labels[index].text = "—"

	if match_state.seats.is_empty():
		return
	var active := match_state.active_player()
	status_label.text = ("ZWYCIĘŻA %s!" % match_state.seats[match_state.winner_seat].nickname) if match_state.phase == TableMatch.PHASE_GAME_OVER else "TURA: %s" % active.nickname
	turn_label.text = "Punkty w turze: %d  •  Cel: %d" % [match_state.turn_score, match_state.target_score]
	kept_label.text = "Odłożone: %s" % _dice_text(match_state.kept)

	var local_can_play := match_state.can_control(session.local_peer_id())
	var selection := match_state.selected_result()
	roll_button.disabled = not local_can_play or match_state.phase != TableMatch.PHASE_AWAIT_ROLL
	keep_button.disabled = not local_can_play or match_state.phase != TableMatch.PHASE_SELECT or not selection.valid
	bank_button.disabled = keep_button.disabled
	match match_state.phase:
		TableMatch.PHASE_AWAIT_ROLL:
			hint_label.text = "Rzuć kośćmi." if local_can_play else ("Bot myśli…" if active.is_bot else "Czekaj na ruch gracza.")
		TableMatch.PHASE_SELECT:
			if local_can_play:
				hint_label.text = "+%d pkt • %s" % [selection.score, selection.label] if selection.valid else "Wybierz punktujące kości."
			else:
				hint_label.text = "Wybieranie kości…"
		TableMatch.PHASE_FARKLE:
			hint_label.text = "FARKLE — punkty z tury przepadają."
		TableMatch.PHASE_GAME_OVER:
			hint_label.text = "Mecz zakończony."

	_render_dice()
	if (force_throw or _rendered_roll_id != match_state.roll_id) and not match_state.current_dice.is_empty():
		_rendered_roll_id = match_state.roll_id
		world.throw_dice(match_state.current_dice, match_state.current_types, not local_can_play)
	elif match_state.current_dice.is_empty():
		world.clear_dice()

	if match_state.event_id != _rendered_event_id:
		_rendered_event_id = match_state.event_id
		_add_history(match_state.last_event, RED if match_state.phase == TableMatch.PHASE_FARKLE else CREAM)


func _render_dice() -> void:
	for child in dice_row.get_children():
		child.queue_free()
	for index in range(match_state.current_dice.size()):
		var die := DieView.new()
		var locked := not match_state.can_control(session.local_peer_id()) or match_state.phase != TableMatch.PHASE_SELECT
		die.configure(index, match_state.current_dice[index], match_state.current_types[index], locked)
		die.set_selected(index in match_state.selected)
		die.die_pressed.connect(_on_die_pressed)
		die.custom_minimum_size = Vector2(70, 70)
		dice_row.add_child(die)
	world.set_dice_selected(match_state.selected)


func _add_history(message: String, color: Color) -> void:
	if message.is_empty():
		return
	var item := _label(message, 13, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_box.add_child(item)
	if history_box.get_child_count() > 12:
		history_box.get_child(0).queue_free()


func _dice_text(values: Array) -> String:
	if values.is_empty():
		return "—"
	var glyphs := ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
	var parts: Array[String] = []
	for value in values:
		parts.append(glyphs[clampi(int(value) - 1, 0, 5)])
	return " ".join(parts)


func _label(text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, color: Color, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.x = width
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", _panel_style(color, color.lightened(0.2), 2, 7))
	return button


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
