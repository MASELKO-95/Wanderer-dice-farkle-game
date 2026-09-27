extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.screen_layer.find_child("quick_match_btn", true, false).pressed.emit()
	await process_frame
	check(game.current_menu == "setup" and game.setup_mode == "quick" and not game.world_container.visible, "quick match opens preparation, not gameplay")
	var score: SpinBox = game.screen_layer.find_child("SetupTargetScore", true, false)
	score.value = 6500
	var difficulty: OptionButton = game.screen_layer.find_child("SetupDifficulty", true, false)
	difficulty.select(2)
	difficulty.item_selected.emit(2)
	root.get_node("I18n").set_language("en")
	await process_frame
	check(game.setup_mode == "quick" and game.current_menu == "setup" and game.target_score == 6500, "language switch preserves setup and score")
	game.screen_layer.find_child("SetupStartQuick", true, false).pressed.emit()
	await process_frame
	check(game.current_menu == "game" and game.target_score == 6500 and game.bot_difficulty == "hard", "explicit start uses selected settings")
	game.show_main_menu()
	await process_frame
	game.screen_layer.find_child("multiplayer_btn", true, false).pressed.emit()
	await process_frame
	check(game.current_menu == "setup" and game.setup_mode == "multiplayer" and game.screen_layer.get_node_or_null("MultiplayerLobby") == null, "multiplayer opens preparation before lobby")
	check(not game.screen_layer.find_child("SetupBotProfile", true, false).is_visible_in_tree(), "solo bot options hidden in multiplayer")
	score = game.screen_layer.find_child("SetupTargetScore", true, false)
	score.value = 8000
	game.screen_layer.find_child("SetupOpenLobby", true, false).pressed.emit()
	await process_frame
	check(game.current_menu == "lobby" and game.screen_layer.get_node_or_null("MultiplayerLobby") != null and game.target_score == 8000, "explicit continue opens lobby with prepared target")
	check(not game.network_session.is_connected_session(), "preparation does not create a connection")
	game.queue_free()
	await create_timer(0.2).timeout
	if failures == 0:
		print("PASS: quick and multiplayer preparation, settings, localization and explicit start")
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: " + message)
		failures += 1
