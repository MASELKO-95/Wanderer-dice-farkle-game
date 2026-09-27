class_name TableMatch
extends RefCounted

const PHASE_AWAIT_ROLL := "await_roll"
const PHASE_SELECT := "select"
const PHASE_FARKLE := "farkle"
const PHASE_GAME_OVER := "game_over"

var seats: Array[Dictionary] = []
var target_score := 4000
var active_seat := 0
var turn_score := 0
var active_types: Array[int] = []
var current_types: Array[int] = []
var current_dice: Array[int] = []
var selected: Array[int] = []
var kept: Array[int] = []
var phase := PHASE_AWAIT_ROLL
var winner_seat := -1
var roll_id := 0
var revision := 0
var event_id := 0
var last_event := ""
var rng := RandomNumberGenerator.new()


func setup(initial_seats: Array, new_target_score: int, seed: int) -> void:
	seats.clear()
	for index in range(mini(initial_seats.size(), NetworkSession.MAX_PLAYERS)):
		var source: Dictionary = initial_seats[index]
		var loadout: Array[int] = []
		for value in source.get("loadout", []).slice(0, 6):
			loadout.append(clampi(int(value), 0, DiceCatalog.TYPES.size() - 1))
		while loadout.size() < 6:
			loadout.append(1)
		seats.append({
			"seat": index,
			"peer_id": int(source.get("peer_id", -1)),
			"nickname": str(source.get("nickname", "Gracz")).left(18),
			"is_bot": bool(source.get("is_bot", false)),
			"loadout": loadout,
			"avatar_id": str(source.get("avatar_id", "procedural")).left(96),
			"score": maxi(0, int(source.get("score", 0)))
		})
	target_score = clampi(new_target_score, 1000, 10000)
	rng.seed = seed
	active_seat = 0
	winner_seat = -1
	revision = 0
	event_id = 0
	roll_id = 0
	_start_turn("Rozpoczyna %s." % active_player().nickname)


func active_player() -> Dictionary:
	return seats[active_seat] if active_seat >= 0 and active_seat < seats.size() else {}


func can_control(peer_id: int) -> bool:
	if seats.is_empty() or phase in [PHASE_FARKLE, PHASE_GAME_OVER]:
		return false
	var seat := active_player()
	return not bool(seat.is_bot) and int(seat.peer_id) == peer_id


func roll(peer_id: int, force_bot := false) -> bool:
	if phase != PHASE_AWAIT_ROLL or (not force_bot and not can_control(peer_id)):
		return false
	current_types = active_types.duplicate()
	current_dice.clear()
	for die_type in current_types:
		current_dice.append(DiceCatalog.roll(die_type, rng))
	selected.clear()
	phase = PHASE_SELECT
	roll_id += 1
	_touch("%s rzuca: %s" % [active_player().nickname, _dice_text(current_dice)])
	if not FarkleRules.best_scoring_subset(current_dice).valid:
		phase = PHASE_FARKLE
		_touch("FARKLE! %s traci %d pkt z tej tury." % [active_player().nickname, turn_score])
	return true


func toggle_die(peer_id: int, index: int) -> bool:
	if phase != PHASE_SELECT or not can_control(peer_id) or index < 0 or index >= current_dice.size():
		return false
	if index in selected:
		selected.erase(index)
	else:
		selected.append(index)
	selected.sort()
	_touch("", false)
	return true


func set_bot_selection(indices: Array) -> bool:
	if phase != PHASE_SELECT or not bool(active_player().is_bot):
		return false
	selected.clear()
	for value in indices:
		var index := int(value)
		if index >= 0 and index < current_dice.size() and index not in selected:
			selected.append(index)
	selected.sort()
	_touch("", false)
	return true


func selected_result() -> Dictionary:
	var values: Array[int] = []
	for index in selected:
		if index >= 0 and index < current_dice.size():
			values.append(current_dice[index])
	return FarkleRules.score_dice(values)


func keep_and_continue(peer_id: int, force_bot := false) -> bool:
	if phase != PHASE_SELECT or (not force_bot and not can_control(peer_id)):
		return false
	var result := selected_result()
	if not result.valid:
		return false
	var values := _selected_values()
	turn_score += int(result.score)
	kept.append_array(values)
	var next_types: Array[int] = []
	for index in range(current_types.size()):
		if index not in selected:
			next_types.append(current_types[index])
	var hot_dice := next_types.is_empty()
	active_types = active_player().loadout.duplicate() if hot_dice else next_types
	if hot_dice:
		kept.clear()
	current_dice.clear()
	current_types.clear()
	selected.clear()
	phase = PHASE_AWAIT_ROLL
	_touch("%s odkłada %s (+%d)%s" % [
		active_player().nickname,
		_dice_text(values),
		result.score,
		" — gorące kości!" if hot_dice else "."
	])
	return true


func bank(peer_id: int, force_bot := false) -> bool:
	if phase != PHASE_SELECT or (not force_bot and not can_control(peer_id)):
		return false
	var result := selected_result()
	if not result.valid:
		return false
	turn_score += int(result.score)
	seats[active_seat].score = int(seats[active_seat].score) + turn_score
	var name: String = active_player().nickname
	var banked := turn_score
	if int(seats[active_seat].score) >= target_score:
		winner_seat = active_seat
		phase = PHASE_GAME_OVER
		_touch("%s wygrywa z wynikiem %d pkt!" % [name, seats[active_seat].score])
	else:
		_advance_turn("%s zapisuje %d pkt." % [name, banked])
	return true


func resolve_farkle() -> bool:
	if phase != PHASE_FARKLE:
		return false
	_advance_turn("")
	return true


func bot_best_selection() -> Array:
	if phase != PHASE_SELECT or not bool(active_player().is_bot):
		return []
	var best := FarkleRules.best_scoring_subset(current_dice)
	return Array(best.indices) if best.valid else []


func bot_should_bank() -> bool:
	var result := selected_result()
	if not result.valid:
		return false
	var projected := turn_score + int(result.score)
	var score := int(active_player().score)
	var dice_left := current_dice.size() - selected.size()
	return (
		score + projected >= target_score
		or projected >= 750
		or (projected >= 400 and rng.randf() < 0.62)
		or (dice_left <= 2 and projected >= 250 and rng.randf() < 0.72)
	)


func snapshot() -> Dictionary:
	return {
		"seats": seats.duplicate(true),
		"target_score": target_score,
		"active_seat": active_seat,
		"turn_score": turn_score,
		"active_types": active_types.duplicate(),
		"current_types": current_types.duplicate(),
		"current_dice": current_dice.duplicate(),
		"selected": selected.duplicate(),
		"kept": kept.duplicate(),
		"phase": phase,
		"winner_seat": winner_seat,
		"roll_id": roll_id,
		"revision": revision,
		"event_id": event_id,
		"last_event": last_event
	}


func apply_snapshot(data: Dictionary) -> bool:
	var incoming_revision := int(data.get("revision", -1))
	if incoming_revision < revision:
		return false
	seats.clear()
	for raw_seat in data.get("seats", []):
		seats.append((raw_seat as Dictionary).duplicate(true))
	target_score = int(data.get("target_score", target_score))
	active_seat = int(data.get("active_seat", 0))
	turn_score = int(data.get("turn_score", 0))
	active_types = _int_array(data.get("active_types", []))
	current_types = _int_array(data.get("current_types", []))
	current_dice = _int_array(data.get("current_dice", []))
	selected = _int_array(data.get("selected", []))
	kept = _int_array(data.get("kept", []))
	phase = str(data.get("phase", PHASE_AWAIT_ROLL))
	winner_seat = int(data.get("winner_seat", -1))
	roll_id = int(data.get("roll_id", 0))
	revision = incoming_revision
	event_id = int(data.get("event_id", 0))
	last_event = str(data.get("last_event", ""))
	return true


func _advance_turn(prefix: String) -> void:
	if seats.is_empty():
		return
	active_seat = (active_seat + 1) % seats.size()
	_start_turn(("%s " % prefix) if not prefix.is_empty() else "")


func _start_turn(prefix: String) -> void:
	turn_score = 0
	current_dice.clear()
	current_types.clear()
	selected.clear()
	kept.clear()
	phase = PHASE_AWAIT_ROLL
	active_types = active_player().loadout.duplicate()
	var message := "%sTura: %s." % [prefix, active_player().nickname]
	_touch(message.strip_edges())


func _selected_values() -> Array[int]:
	var values: Array[int] = []
	for index in selected:
		values.append(current_dice[index])
	return values


func _touch(event_text: String, add_event := true) -> void:
	revision += 1
	if add_event and not event_text.is_empty():
		event_id += 1
		last_event = event_text


func _int_array(source: Array) -> Array[int]:
	var result: Array[int] = []
	for value in source:
		result.append(int(value))
	return result


func _dice_text(values: Array) -> String:
	var glyphs := ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
	var parts: Array[String] = []
	for value in values:
		parts.append(glyphs[clampi(int(value) - 1, 0, 5)])
	return " ".join(parts)
