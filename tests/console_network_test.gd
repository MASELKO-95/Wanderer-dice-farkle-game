extends SceneTree

const PORT := 27994
var game: Control
var role := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	role = OS.get_cmdline_user_args()[0]
	game = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.developer_console.unlocked = true
	if role == "host":
		assert(game.network_session.host_game("Host", PORT) == OK)
		print("HOST_READY")
		await _wait_for(func() -> bool: return game.network_session.players.size() == 2)
		assert(game.network_session.start_match())
		await process_frame
		await create_timer(0.3).timeout
		game.developer_console.execute("lose")
		assert(game.multiplayer_table.match_state.winner_seat == 1)
		await create_timer(1.0).timeout
	else:
		var code := NetworkSession.make_room_code("127.0.0.1:%d" % PORT)
		assert(game.developer_console.execute("join " + code) == "Łączenie z lobby…")
		await _wait_for(func() -> bool: return is_instance_valid(game.multiplayer_table))
		assert(game.developer_console.execute("win").contains("tylko host"))
		await _wait_for(func() -> bool: return game.multiplayer_table.match_state.phase == TableMatch.PHASE_GAME_OVER)
		assert(game.multiplayer_table.match_state.winner_seat == 1)
		assert(game.multiplayer_table.match_state.seats[1].score == game.multiplayer_table.match_state.target_score)
	print("PASS: console network ", role)
	game.show_main_menu()
	game.queue_free()
	await process_frame
	await create_timer(1.5).timeout
	quit()

func _wait_for(condition: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 7000
	while not condition.call():
		assert(Time.get_ticks_msec() < deadline, "Network test timeout")
		await process_frame
