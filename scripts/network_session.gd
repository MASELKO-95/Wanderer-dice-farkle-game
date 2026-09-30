class_name NetworkSession
extends Node

const STORY_TEXT := preload("res://scripts/story_text.gd")

signal status_changed(message: String)
signal opponent_connected(peer_id: int, nickname: String)
signal opponent_disconnected(peer_id: int)
signal lobby_changed(seats: Array, target_score: int)
signal match_started(config: Dictionary)
signal game_action_received(peer_id: int, action: String, payload: Dictionary)
signal public_address_ready(address: String)
signal session_ended(reason: String)

const CODE_ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4
const BOT_NAMES := ["Kuba Kościarz", "Marta Szczęściara", "Wojtek Ryzykant"]

var is_host := false
var local_nickname := "Gracz"
var local_loadout: Array[int] = [1, 1, 1, 1, 1, 1]
var local_avatar_id := "procedural"
var public_address := ""
var target_score := 4000
var players: Dictionary = {}
var bots: Array[Dictionary] = []
var _next_bot_id := -1
var match_in_progress := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(nickname: String, port := DEFAULT_PORT, loadout: Array = [], avatar_id := "procedural") -> Error:
	disconnect_session()
	local_nickname = _clean_nickname(nickname)
	local_loadout = _clean_loadout(loadout)
	local_avatar_id = _clean_avatar_id(avatar_id)
	var peer := ENetMultiplayerPeer.new()
	# max_clients nie obejmuje hosta, więc stół 4-osobowy ma najwyżej 3 klientów.
	var error := peer.create_server(clampi(port, 1024, 65535), MAX_PLAYERS - 1)
	if error != OK:
		status_changed.emit(STORY_TEXT.text("Nie udało się uruchomić hosta: %s") % error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	is_host = true
	players = {1: _make_human_seat(1, local_nickname, local_loadout, local_avatar_id)}
	bots.clear()
	_next_bot_id = -1
	match_in_progress = false
	status_changed.emit(STORY_TEXT.text("Stół działa na porcie UDP %d. Oczekiwanie na graczy…") % port)
	_emit_lobby()
	return OK


func join_game(address_text: String, nickname: String, fallback_port := DEFAULT_PORT, loadout: Array = [], avatar_id := "procedural") -> Error:
	disconnect_session()
	local_nickname = _clean_nickname(nickname)
	local_loadout = _clean_loadout(loadout)
	local_avatar_id = _clean_avatar_id(avatar_id)
	var endpoint := parse_endpoint(address_text, fallback_port)
	if not endpoint.valid:
		status_changed.emit(str(endpoint.error))
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(str(endpoint.host), int(endpoint.port))
	if error != OK:
		status_changed.emit(STORY_TEXT.text("Nie udało się rozpocząć połączenia: %s") % error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	is_host = false
	match_in_progress = false
	players.clear()
	bots.clear()
	status_changed.emit(STORY_TEXT.text("Łączenie z %s:%d (UDP)…") % [endpoint.host, endpoint.port])
	return OK


func disconnect_session() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_host = false
	match_in_progress = false
	players.clear()
	bots.clear()
	public_address = ""


func is_connected_session() -> bool:
	return multiplayer.multiplayer_peer != null


func local_peer_id() -> int:
	return multiplayer.get_unique_id() if is_connected_session() else 1


func local_addresses() -> Array[String]:
	var result: Array[String] = []
	for address in IP.get_local_addresses():
		if ":" in address or address.begins_with("127.") or address == "0.0.0.0":
			continue
		result.append(address)
	result.sort()
	return result


func set_public_address(address_text: String, port := DEFAULT_PORT) -> void:
	var endpoint := parse_endpoint(address_text, port)
	if not endpoint.valid:
		status_changed.emit(str(endpoint.error))
		return
	public_address = format_endpoint(str(endpoint.host), int(endpoint.port))
	public_address_ready.emit(public_address)
	status_changed.emit(STORY_TEXT.text("Kod zaproszenia gotowy. Host musi być dostępny na podanym porcie UDP."))


func set_target_score(value: int) -> void:
	if not is_host:
		return
	target_score = clampi(value, 1000, 10000)
	_emit_lobby()


func add_bot(avatar_id := "procedural") -> bool:
	if not is_host or players.size() + bots.size() >= MAX_PLAYERS:
		return false
	var used_index := bots.size()
	bots.append({
		"seat": 0,
		"peer_id": _next_bot_id,
		"nickname": STORY_TEXT.text(BOT_NAMES[used_index % BOT_NAMES.size()]),
		"is_bot": true,
		"loadout": [1, 1, 1, 1, 2, 1],
		"avatar_id": _clean_avatar_id(str(avatar_id)),
		"score": 0
	})
	_next_bot_id -= 1
	_emit_lobby()
	return true


func remove_bot() -> bool:
	if not is_host or bots.is_empty():
		return false
	bots.pop_back()
	_emit_lobby()
	return true


func start_match() -> bool:
	if not is_host:
		return false
	var seats := _lobby_seats()
	if seats.size() < 2:
		status_changed.emit(STORY_TEXT.text("Dodaj bota albo poczekaj na co najmniej jednego gracza."))
		return false
	var config := {
		"seats": seats,
		"target_score": target_score,
		"seed": randi(),
		"host_peer_id": 1
	}
	match_in_progress = true
	_receive_match_start.rpc(config)
	match_started.emit(config)
	return true


func send_game_action(action: String, payload := {}) -> void:
	if not is_connected_session():
		return
	var clean_payload: Dictionary = payload if payload is Dictionary else {}
	if is_host:
		_deliver_game_action.rpc(action.left(48), clean_payload)
	else:
		_request_game_action.rpc_id(1, action.left(48), clean_payload)


func kick_peer(peer_id: int) -> void:
	if not is_host or peer_id <= 1:
		return
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer:
		peer.disconnect_peer(peer_id)


static func format_endpoint(host: String, port: int) -> String:
	return ("[%s]:%d" if ":" in host else "%s:%d") % [host, port]


static func make_room_code(address: String) -> String:
	var endpoint := parse_endpoint(address)
	if not endpoint.valid:
		return ""
	var host := str(endpoint.host)
	if host.is_valid_ip_address() and not ":" in host:
		var bytes := PackedByteArray()
		for octet in host.split("."):
			bytes.append(int(octet))
		if int(endpoint.port) != DEFAULT_PORT:
			bytes.append(int(endpoint.port) >> 8)
			bytes.append(int(endpoint.port) & 255)
		bytes.append(bytes.hex_encode().sha256_text().left(2).hex_to_int())
		var number: int = 0
		for byte in bytes:
			number = (number << 8) | byte
		var encoded := ""
		for index in range(8 if bytes.size() == 5 else 12):
			encoded = CODE_ALPHABET[number & 31] + encoded
			number >>= 5
		return "F2-" + encoded
	var normalized := format_endpoint(host, int(endpoint.port))
	var payload := Marshalls.raw_to_base64(normalized.to_utf8_buffer()).replace("+", "-").replace("/", "_").replace("=", "")
	return "FK1-%s-%s" % [payload, normalized.sha256_text().left(6)]


static func decode_short_room_code(code: String) -> String:
	var payload := code.substr(3).to_upper()
	if payload.length() not in [8, 12]:
		return ""
	var number: int = 0
	for character in payload:
		var digit := CODE_ALPHABET.find(character)
		if digit < 0:
			return ""
		number = (number << 5) | digit
	var bytes := PackedByteArray()
	bytes.resize(5 if payload.length() == 8 else 7)
	for index in range(bytes.size() - 1, -1, -1):
		bytes[index] = number & 255
		number >>= 8
	if number != 0:
		return ""
	var content := bytes.slice(0, bytes.size() - 1)
	if content.hex_encode().sha256_text().left(2).hex_to_int() != bytes[-1]:
		return ""
	var port := DEFAULT_PORT if bytes.size() == 5 else (int(bytes[4]) << 8) | int(bytes[5])
	if port < 1024 or port > 65535:
		return ""
	return "%d.%d.%d.%d:%d" % [bytes[0], bytes[1], bytes[2], bytes[3], port]


static func decode_room_code(code: String) -> String:
	if code.length() > 512:
		return ""
	var split_at := code.rfind("-")
	if split_at <= 4:
		return ""
	var payload := code.substr(4, split_at - 4).replace("-", "+").replace("_", "/")
	while payload.length() % 4 != 0:
		payload += "="
	var decoded := Marshalls.base64_to_raw(payload).get_string_from_utf8()
	if decoded.sha256_text().left(6) != code.substr(split_at + 1) or decoded.begins_with("FK1-"):
		return ""
	return decoded


static func parse_endpoint(address_text: String, fallback_port := DEFAULT_PORT) -> Dictionary:
	var text := address_text.strip_edges()
	if text.to_lower().begins_with("wanderer-farkle:"):
		var prefix := "wanderer-farkle://join/"
		if not text.to_lower().begins_with(prefix) or text.length() > 600:
			return {"valid": false, "error": STORY_TEXT.text("Nieprawidłowy link zaproszenia.")}
		text = text.substr(prefix.length())
		for character in text:
			if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-":
				return {"valid": false, "error": STORY_TEXT.text("Nieprawidłowy link zaproszenia.")}
		# Only room codes are accepted, never commands, arbitrary URLs or options.
		if not (text.to_upper().begins_with("F2-") or text.begins_with("FK1-")):
			return {"valid": false, "error": STORY_TEXT.text("Link nie zawiera kodu pokoju.")}
	if text.to_upper().begins_with("F2-") or text.begins_with("FK1-"):
		text = decode_short_room_code(text) if text.to_upper().begins_with("F2-") else decode_room_code(text)
		if text.is_empty():
			return {"valid": false, "error": STORY_TEXT.text("Nieprawidłowy kod pokoju. Skopiuj cały kod ponownie.")}
	for prefix in ["udp://", "enet://"]:
		if text.to_lower().begins_with(prefix):
			text = text.substr(prefix.length())
	if text.is_empty():
		return {"valid": false, "error": STORY_TEXT.text("Wpisz adres hosta.")}
	var host := text
	var port := clampi(fallback_port, 1024, 65535)
	# Nazwy playit.gg i IPv4 są w formie host:port. Nawiasy obsługują też IPv6.
	if text.begins_with("["):
		var closing := text.find("]")
		if closing < 0:
			return {"valid": false, "error": STORY_TEXT.text("Nieprawidłowy adres IPv6.")}
		host = text.substr(1, closing - 1)
		if closing + 1 < text.length():
			if text[closing + 1] != ":":
				return {"valid": false, "error": STORY_TEXT.text("Nieprawidłowy adres hosta.")}
			var port_text := text.substr(closing + 2)
			if not port_text.is_valid_int():
				return {"valid": false, "error": STORY_TEXT.text("Port musi być liczbą.")}
			port = int(port_text)
	elif text.count(":") == 1:
		var split_at := text.rfind(":")
		var port_text := text.substr(split_at + 1)
		if not port_text.is_valid_int():
			return {"valid": false, "error": STORY_TEXT.text("Port musi być liczbą.")}
		host = text.substr(0, split_at)
		port = int(port_text)
	if host.strip_edges().is_empty() or port < 1024 or port > 65535:
		return {"valid": false, "error": STORY_TEXT.text("Adres lub port jest nieprawidłowy (1024–65535).")}
	return {"valid": true, "host": host.strip_edges(), "port": port}


func _on_peer_connected(peer_id: int) -> void:
	if is_host:
		status_changed.emit(STORY_TEXT.text("Gracz %d łączy się ze stołem…") % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host:
		return
	if players.has(peer_id):
		players.erase(peer_id)
		opponent_disconnected.emit(peer_id)
		status_changed.emit(STORY_TEXT.text("Gracz rozłączył się."))
		if not match_in_progress:
			_emit_lobby()


func _on_connected_to_server() -> void:
	status_changed.emit(STORY_TEXT.text("Połączono. Rejestrowanie miejsca przy stole…"))
	_register_player.rpc_id(1, local_nickname, local_loadout, local_avatar_id)


func _on_connection_failed() -> void:
	status_changed.emit(STORY_TEXT.text("Połączenie nie powiodło się. Sprawdź adres, port UDP i tunel/zaporę."))
	disconnect_session()


func _on_server_disconnected() -> void:
	status_changed.emit(STORY_TEXT.text("Host zakończył sesję."))
	players.clear()
	bots.clear()
	is_host = false
	match_in_progress = false
	session_ended.emit(STORY_TEXT.text("Host zakończył sesję."))


@rpc("any_peer", "call_remote", "reliable")
func _register_player(nickname: String, loadout: Array, avatar_id: String) -> void:
	if not is_host:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if players.has(peer_id):
		return
	if match_in_progress:
		kick_peer(peer_id)
		return
	if players.size() + bots.size() >= MAX_PLAYERS:
		if not bots.is_empty():
			bots.pop_back()
		else:
			kick_peer(peer_id)
			return
	var seat := _make_human_seat(peer_id, _clean_nickname(nickname), loadout, _clean_avatar_id(avatar_id))
	players[peer_id] = seat
	opponent_connected.emit(peer_id, seat.nickname)
	status_changed.emit(STORY_TEXT.text("Dołączył: %s") % seat.nickname)
	_emit_lobby()


@rpc("authority", "call_remote", "reliable")
func _receive_lobby(seats: Array, new_target_score: int) -> void:
	target_score = new_target_score
	var known_peers := players.keys()
	players.clear()
	bots.clear()
	for raw_seat in seats:
		var seat := (raw_seat as Dictionary).duplicate(true)
		if bool(seat.get("is_bot", false)):
			bots.append(seat)
		else:
			var peer_id := int(seat.get("peer_id", 0))
			players[peer_id] = seat
			if peer_id != multiplayer.get_unique_id() and peer_id not in known_peers:
				opponent_connected.emit(peer_id, str(seat.get("nickname", "Gracz")))
	lobby_changed.emit(seats, target_score)


@rpc("authority", "call_remote", "reliable")
func _receive_match_start(config: Dictionary) -> void:
	match_started.emit(config)


@rpc("any_peer", "call_remote", "reliable", 1)
func _request_game_action(action: String, payload: Dictionary) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	if players.has(sender):
		game_action_received.emit(sender, action, payload)


@rpc("authority", "call_remote", "reliable", 1)
func _deliver_game_action(action: String, payload: Dictionary) -> void:
	game_action_received.emit(1, action, payload)


func _emit_lobby() -> void:
	if not is_host:
		return
	var seats := _lobby_seats()
	lobby_changed.emit(seats, target_score)
	_receive_lobby.rpc(seats, target_score)


func _lobby_seats() -> Array:
	var seats: Array = []
	var peer_ids: Array = players.keys()
	peer_ids.sort()
	for peer_id in peer_ids:
		seats.append(players[peer_id].duplicate(true))
	for bot in bots:
		seats.append(bot.duplicate(true))
	for index in range(seats.size()):
		seats[index].seat = index
		seats[index].score = 0
	return seats


func _make_human_seat(peer_id: int, nickname: String, loadout: Array, avatar_id := "procedural") -> Dictionary:
	var clean_loadout := _clean_loadout(loadout)
	return {
		"seat": 0,
		"peer_id": peer_id,
		"nickname": nickname,
		"is_bot": false,
		"loadout": clean_loadout,
		"avatar_id": _clean_avatar_id(avatar_id),
		"score": 0
	}


func _clean_loadout(loadout: Array) -> Array[int]:
	var result: Array[int] = []
	for value in loadout.slice(0, 6):
		result.append(clampi(int(value), 0, DiceCatalog.TYPES.size() - 1))
	while result.size() < 6:
		result.append(1)
	return result


func _clean_nickname(value: String) -> String:
	var cleaned := value.strip_edges().replace("\n", " ").replace("\r", " ").left(18)
	return cleaned if not cleaned.is_empty() else STORY_TEXT.text("Wędrowiec")


func _clean_avatar_id(value: String) -> String:
	var cleaned := value.strip_edges().left(96)
	return cleaned if AssetLibrary.has_model(cleaned) else "procedural"
