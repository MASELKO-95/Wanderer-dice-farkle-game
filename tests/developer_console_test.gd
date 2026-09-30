extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var console = game.developer_console
	assert(not console.unlocked)
	assert(console.execute("quickbattle") == "Konsola jest zablokowana.")
	await _press(KEY_QUOTELEFT)
	assert(not console.is_open())
	for key in [KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]:
		await _press(key)
	assert(not console.unlocked)
	for key in console.SEQUENCE:
		await _press(key)
	assert(console.unlocked and console.is_open())
	await _press(KEY_QUOTELEFT)
	assert(not console.is_open())
	await _press(KEY_QUOTELEFT)
	assert(console.is_open())
	assert(console.execute("win") == "Brak aktywnego meczu.")
	console.execute("quickbattle")
	await process_frame
	assert(game.current_menu == "game" and not game.campaign_active)
	game.current_dice.assign([1, 5, 2])
	game.current_roll_types.assign([1, 1, 1])
	game.dice_rolled = true
	game._render_dice(false)
	await process_frame
	await _press(KEY_RIGHT)
	await _press(KEY_Z)
	assert(game.selected_indices.is_empty())
	assert(console.execute("win") == "Wygrana.")
	assert(game.player_score == game.target_score and game.match_recorded)
	assert(console.execute("win") == "Brak aktywnego meczu.")
	console.execute("quickbattle")
	await process_frame
	assert(console.execute("lose") == "Przegrana.")
	assert(game.bot_score == game.target_score and game.match_recorded)
	console.execute('setlang "en"')
	assert(root.get_node("I18n").current_locale == "en")
	console.execute('setlang "invalid"')
	assert(root.get_node("I18n").current_locale == "en")
	console.execute('setlang "pl"')
	console.execute("exit(-1)")
	assert(console.exit_timer.is_stopped())
	console.execute("exit(nan)")
	assert(console.exit_timer.is_stopped())
	console.execute("exit(30)")
	assert(console.exit_timer.time_left > 29)
	console.exit_timer.stop()
	assert(console.execute("join F2-invalid").contains("Nieprawidłowy"))
	assert(game.current_menu == "game")
	assert(console.execute("unknown").contains("Nieznana"))
	game.queue_free()
	await process_frame
	await create_timer(1.5).timeout
	print("PASS: console unlock, toggle, input isolation, win/lose, quickbattle, language, exit timer and invalid join")
	quit()
