extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)

func _run() -> void:
	for address in ["127.0.0.1:27991", "203.0.113.9:7777", "example.playit.gg:32123", "[::1]:7777"]:
		var code := NetworkSession.make_room_code(address)
		var endpoint := NetworkSession.parse_endpoint(code)
		assert(endpoint.valid)
		assert(NetworkSession.format_endpoint(endpoint.host, endpoint.port) == address)
		assert(not NetworkSession.parse_endpoint(code + "x").valid)
	assert(NetworkSession.make_room_code("203.0.113.9:7777").length() == 11)
	assert(NetworkSession.make_room_code("203.0.113.9:27991").length() == 15)
	for index in range(128):
		var address := "%d.%d.%d.%d:%d" % [index, 255 - index, index * 2, 255, 1024 + index * 503]
		var code := NetworkSession.make_room_code(address)
		var endpoint := NetworkSession.parse_endpoint(code.to_lower())
		assert(endpoint.valid and NetworkSession.format_endpoint(endpoint.host, endpoint.port) == address)
		var altered := code.substr(0, code.length() - 1) + ("0" if not code.ends_with("0") else "1")
		assert(not NetworkSession.parse_endpoint(altered).valid)
	var legacy_address := "203.0.113.9:7777"
	var legacy := "FK1-" + Marshalls.raw_to_base64(legacy_address.to_utf8_buffer()).replace("=", "") + "-" + legacy_address.sha256_text().left(6)
	assert(NetworkSession.parse_endpoint(legacy).valid)
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	await process_frame
	game.current_dice.assign([1, 5, 2])
	game.current_roll_types.assign([1, 1, 1])
	game.dice_rolled = true
	game.current_is_player = true
	game._render_dice(false)
	await process_frame
	# Focused buttons must not consume Enter or Space during dice selection.
	game.roll_button.grab_focus()
	_key(KEY_RIGHT)
	await process_frame
	_key(KEY_Z)
	await process_frame
	assert(game.selected_indices == [1])
	_key(KEY_SPACE)
	await process_frame
	assert(game.selected_indices.is_empty())
	_key(KEY_ENTER)
	await process_frame
	assert(game.selected_indices == [1])
	_key(KEY_LEFT)
	await process_frame
	_key(KEY_UP)
	await process_frame
	assert(game.keyboard_die == 2)
	_key(KEY_DOWN)
	await process_frame
	assert(game.keyboard_die == 0)
	game.current_is_player = false
	_key(KEY_Z)
	await process_frame
	assert(game.selected_indices == [1])
	game.queue_free()
	await process_frame
	await create_timer(1.5).timeout
	print("PASS: room code round trips, corrupt codes, keyboard selection and turn guard")
	quit()
