extends SceneTree

const TEST_PORT := 27991

var session: NetworkSession
var role := ""
var hello_sent := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	role = arguments[0] if not arguments.is_empty() else "host"
	session = NetworkSession.new()
	session.name = "NetworkSession"
	root.add_child(session)
	session.status_changed.connect(func(message: String) -> void:
		print("%s STATUS: %s" % [role, message])
	)
	session.opponent_connected.connect(_on_opponent_connected)
	session.game_action_received.connect(_on_action)
	session.match_started.connect(_on_match_started)
	await process_frame
	var result := session.host_game("Host testowy", TEST_PORT) if role == "host" else session.join_game("127.0.0.1", "Klient testowy", TEST_PORT)
	if result != OK:
		printerr("FAIL %s: %s" % [role, error_string(result)])
		quit(1)
		return
	await create_timer(7.0).timeout
	printerr("FAIL %s: przekroczono czas połączenia" % role)
	quit(1)


func _on_opponent_connected(_peer_id: int, _nickname: String) -> void:
	if role == "client" and not hello_sent:
		hello_sent = true
		session.send_game_action("hello", {"dice": [1, 5, 5]})


func _on_action(_peer_id: int, action: String, payload: Dictionary) -> void:
	if role == "host" and action == "hello" and payload.get("dice", []) == [1, 5, 5]:
		print("PASS host: odebrano niezawodną akcję klienta")
		session.add_bot()
		session.start_match()
	elif role == "host" and action == "match_ready":
		session.send_game_action("acknowledged")
		await create_timer(0.25).timeout
		quit(0)
	elif role == "client" and action == "acknowledged":
		print("PASS client: odebrano odpowiedź hosta")
		quit(0)


func _on_match_started(config: Dictionary) -> void:
	if role != "client":
		return
	var seats: Array = config.get("seats", [])
	if seats.size() != 3 or not bool(seats[2].get("is_bot", false)):
		printerr("FAIL client: niepoprawna konfiguracja stołu")
		quit(1)
		return
	print("PASS client: odebrano start meczu z botem")
	session.send_game_action("match_ready")
