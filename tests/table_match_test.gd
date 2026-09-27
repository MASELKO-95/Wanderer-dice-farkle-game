extends SceneTree


func _init() -> void:
	var match_state := TableMatch.new()
	var seats := [
		{"peer_id": 1, "nickname": "Host", "is_bot": false, "loadout": [1, 1, 1, 1, 1, 1]},
		{"peer_id": 22, "nickname": "Gość", "is_bot": false, "loadout": [1, 1, 1, 1, 1, 1]},
		{"peer_id": -1, "nickname": "Bot A", "is_bot": true, "loadout": [1, 1, 1, 1, 1, 1]},
		{"peer_id": -2, "nickname": "Bot B", "is_bot": true, "loadout": [1, 1, 1, 1, 1, 1]}
	]
	match_state.setup(seats, 4000, 12345)
	_expect(match_state.seats.size() == 4, "stół przyjął 4 miejsca")
	_expect(match_state.can_control(1), "host kontroluje swoją turę")
	_expect(not match_state.can_control(22), "klient nie kontroluje cudzej tury")

	# Kontrolowany układ pozwala sprawdzić walidację odkładania bez zależności od RNG.
	match_state.phase = TableMatch.PHASE_SELECT
	match_state.current_dice = [1, 5, 2, 3, 4, 6]
	match_state.current_types = [1, 1, 1, 1, 1, 1]
	_expect(match_state.toggle_die(1, 0), "wybranie jedynki")
	_expect(match_state.toggle_die(1, 1), "wybranie piątki")
	_expect(match_state.selected_result().score == 150, "wynik zaznaczenia")
	_expect(match_state.bank(1), "zapis prawidłowego wyboru")
	_expect(match_state.seats[0].score == 150, "punkty przypisane do hosta")
	_expect(match_state.active_seat == 1, "tura przeszła do drugiego gracza")

	var endpoint := NetworkSession.parse_endpoint("example.gl.at.ply.gg:30123", 7777)
	_expect(endpoint.valid and endpoint.host == "example.gl.at.ply.gg" and endpoint.port == 30123, "adres playit.gg")
	var lan_endpoint := NetworkSession.parse_endpoint("192.168.1.20", 7777)
	_expect(lan_endpoint.valid and lan_endpoint.port == 7777, "adres LAN z domyślnym portem")

	print("PASS: stan stołu 4-osobowego, tury i adresy LAN/playit.gg")
	quit(0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		return
	printerr("FAIL: %s" % label)
	quit(1)
