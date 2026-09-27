extends SceneTree

const TEST_PORT := 27992


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_model_id := _create_test_bot_model()
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	var session: NetworkSession = game.network_session
	if session.host_game("Host integracyjny", TEST_PORT) != OK:
		_fail("nie udało się uruchomić hosta")
		return
	session.add_bot(test_model_id)
	session.add_bot()
	session.add_bot()
	if str(session.bots[0].avatar_id) != test_model_id:
		_fail("wybrany model bota nie trafił do lobby")
		return
	if not session.start_match():
		_fail("nie udało się rozpocząć meczu")
		return
	await process_frame
	await process_frame
	var table: MultiplayerTable = game.multiplayer_table
	if not is_instance_valid(table):
		_fail("nie utworzono ekranu stołu")
		return
	if table.match_state.seats.size() != 4:
		_fail("stół nie ma czterech miejsc")
		return
	if str(table.match_state.seats[1].avatar_id) != test_model_id:
		_fail("model bota nie został zsynchronizowany ze stołem")
		return
	table._request_action("roll")
	await create_timer(1.15).timeout
	if table.match_state.current_dice.size() != 6:
		_fail("autorytatywny host nie wykonał rzutu")
		return
	print("PASS: lobby host + 3 boty, start stołu i autorytatywny rzut")
	session.disconnect_session()
	table._flow_token += 1
	game.queue_free()
	await process_frame
	await create_timer(1.5).timeout
	quit(0)


func _create_test_bot_model() -> String:
	var mod_root := ProjectSettings.globalize_path("user://mods/test_bot_avatar")
	DirAccess.make_dir_recursive_absolute(mod_root.path_join("models"))
	var manifest := FileAccess.open(mod_root.path_join("mod.json"), FileAccess.WRITE)
	manifest.store_string('{"name":"Testowy bot","author":"Test","license":"CC0-1.0","source_url":"local-test","enabled":true}')
	manifest.close()
	var model := FileAccess.open(mod_root.path_join("models/bot.gltf"), FileAccess.WRITE)
	model.store_string('{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"Bot"}]}')
	model.close()
	AssetLibrary.refresh_mod_catalog()
	return "mod:test_bot_avatar:bot"


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
