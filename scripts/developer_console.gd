extends CanvasLayer

const STORY_TEXT := preload("res://scripts/story_text.gd")

const SEQUENCE := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
var unlocked := false
var sequence_keys: Array[int] = []
var panel: PanelContainer
var output: RichTextLabel
var entry: LineEdit
var game: Control
var exit_timer: Timer

func _ready() -> void:
	layer = 100
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 280
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.05, 0.97)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	output = RichTextLabel.new()
	output.custom_minimum_size.y = 205
	output.scroll_following = true
	column.add_child(output)
	entry = LineEdit.new()
	entry.placeholder_text = STORY_TEXT.text('help | win | lose | quickbattle | join adres/kod | exit(5) | setlang "pl"')
	column.add_child(entry)
	entry.text_submitted.connect(func(command: String) -> void:
		entry.clear()
		log_line("> " + command)
		log_line(execute(command))
	)
	exit_timer = Timer.new()
	exit_timer.one_shot = true
	add_child(exit_timer)
	exit_timer.timeout.connect(func() -> void:
		game._save_progress()
		get_tree().quit()
	)
	panel.hide()

func is_open() -> bool:
	return is_instance_valid(panel) and panel.visible

func log_line(message: String) -> void:
	output.add_text(message + "\n")

func handle_key(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:
		return is_open()
	if unlocked and (event.keycode == KEY_QUOTELEFT or event.physical_keycode == KEY_QUOTELEFT):
		panel.visible = not panel.visible
		if panel.visible:
			entry.grab_focus()
		else:
			entry.release_focus()
		get_viewport().set_input_as_handled()
		return true
	if is_open():
		if event.keycode == KEY_ESCAPE:
			panel.hide()
			entry.release_focus()
			get_viewport().set_input_as_handled()
		return true
	if unlocked:
		return false
	sequence_keys.append(event.keycode)
	if sequence_keys.size() > SEQUENCE.size():
		sequence_keys.pop_front()
	if sequence_keys == SEQUENCE:
		unlocked = true
		panel.show()
		entry.grab_focus()
		log_line(STORY_TEXT.text("Konsola odblokowana. Klawisz ` otwiera/zamyka. Wpisz help."))
		get_viewport().set_input_as_handled()
		return true
	return false

func execute(command: String) -> String:
	if not unlocked:
		return STORY_TEXT.text("Konsola jest zablokowana.")
	var text := command.strip_edges()
	var regex := RegEx.new()
	regex.compile("^([a-zA-Z]+)(?:\\s+(.*)|\\((.*)\\))?$")
	var parsed := regex.search(text)
	if parsed == null:
		return STORY_TEXT.text("Nieprawidłowa komenda. Wpisz help.")
	var name := parsed.get_string(1).to_lower()
	var argument := (parsed.get_string(2) + parsed.get_string(3)).strip_edges()
	if argument.begins_with('"') and argument.ends_with('"') and argument.length() >= 2:
		argument = argument.substr(1, argument.length() - 2)
	if name in ["win", "lose", "quickbattle", "help"] and not argument.is_empty():
		return STORY_TEXT.text("Ta komenda nie przyjmuje argumentów.")
	match name:
		"help":
			return STORY_TEXT.text('win / lose: zakończ mecz (w sieci tylko host)\nquickbattle: szybka bitwa\njoin IP:port / kod: dołącz do lobby\nexit(sekundy): wyjdź po czasie; exit: od razu\nsetlang "pl": język; dostępne: ') + ", ".join(I18n.get_available_languages())
		"win", "lose":
			return game.console_finish_match(name == "win")
		"quickbattle":
			game.show_main_menu()
			game.start_game()
			return STORY_TEXT.text("Rozpoczęto szybką bitwę.")
		"join":
			var endpoint := NetworkSession.parse_endpoint(argument)
			if not endpoint.valid:
				return str(endpoint.error)
			game.show_main_menu()
			game._show_multiplayer_lobby()
			var result: Error = game.network_session.join_game(argument, game.player_name, NetworkSession.DEFAULT_PORT, game.player_loadout, game.player_avatar_id)
			return STORY_TEXT.text("Łączenie z lobby…") if result == OK else STORY_TEXT.text("Błąd połączenia: ") + error_string(result)
		"exit":
			if not argument.is_empty() and not argument.is_valid_float():
				return STORY_TEXT.text("Użycie: exit(5) — czas w sekundach.")
			var seconds := 0.0 if argument.is_empty() else argument.to_float()
			if not is_finite(seconds) or seconds < 0 or seconds > 86400:
				return STORY_TEXT.text("Czas musi mieścić się w zakresie 0–86400 sekund.")
			exit_timer.start(maxf(seconds, 0.01))
			return STORY_TEXT.text("Wyjście za %.2f s.") % seconds
		"setlang":
			if argument not in I18n.get_available_languages():
				return STORY_TEXT.text("Dostępne języki: ") + ", ".join(I18n.get_available_languages())
			I18n.set_language(argument)
			return STORY_TEXT.text("Język: ") + argument
	return STORY_TEXT.text("Nieznana komenda. Wpisz help.")
