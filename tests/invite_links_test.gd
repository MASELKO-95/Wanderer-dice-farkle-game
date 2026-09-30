extends SceneTree

const LINKS := preload("res://scripts/invite_links.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for address in ["203.0.113.9:7777", "127.0.0.1:27995", "example.playit.gg:32123", "[::1]:7777"]:
		var link := LINKS.make_link(address)
		assert(link.begins_with(LINKS.PREFIX))
		var parsed := NetworkSession.parse_endpoint(link)
		assert(parsed.valid and NetworkSession.format_endpoint(parsed.host, parsed.port) == address)
		assert(LINKS.startup_invitation([link]) == link)
		assert(LINKS.startup_invitation(["--join", link]) == link)
		for suffix in ["?x=1", "#fragment", "/extra", "%20--quit", " --quit"]:
			assert(not NetworkSession.parse_endpoint(link + suffix).valid)
	for link in ["wanderer-farkle://exit/0", "wanderer-farkle://join/", "wanderer-farkle://join/--quit", "wanderer-farkle://join/F2-INVALID"]:
		assert(not NetworkSession.parse_endpoint(link).valid)
	assert(LINKS.startup_invitation(["--join"]) == "")
	assert(LINKS.startup_invitation(["unrelated"]) == "")
	var desktop := LINKS.desktop_entry('/tmp/A game/$cash%/game')
	assert('Exec="/tmp/A game/\\\\$cash%%/game" -- %u' in desktop)
	assert("MimeType=x-scheme-handler/wanderer-farkle;" in desktop)
	assert(LINKS.windows_command("C:/A game/game.exe") == '"C:\\A game\\game.exe" -- "%1"')
	var file := FileAccess.open("/tmp/farkle-invite-test.desktop", FileAccess.WRITE)
	file.store_string(desktop)
	file.close()
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._join_invitation("wanderer-farkle://join/invalid")
	await process_frame
	assert(game.current_menu == "lobby")
	assert(not game.network_session.is_connected_session())
	assert(game.network_status_label.text.contains("kod"))
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("PASS: invitation URLs, launch arguments, malformed links, registration templates and invalid invitation UI")
	quit()
