extends SceneTree

const LINKS := preload("res://scripts/invite_links.gd")
const PORT := 27995

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var role := OS.get_cmdline_user_args()[0]
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	if role == "host":
		assert(game.network_session.host_game("Host zaproszenia", PORT) == OK)
		print("INVITE_READY " + LINKS.make_link("127.0.0.1:%d" % PORT))
	var deadline := Time.get_ticks_msec() + 7000
	while game.network_session.players.size() != 2:
		assert(Time.get_ticks_msec() < deadline, "Invitation connection timeout")
		await process_frame
	if role == "client":
		assert(game.current_menu == "lobby")
		assert(not game.developer_console.unlocked)
	print("PASS: startup invitation ", role)
	await create_timer(0.3 if role == "client" else 0.8).timeout
	game.show_main_menu()
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit()
