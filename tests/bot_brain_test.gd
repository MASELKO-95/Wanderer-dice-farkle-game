extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var champion := BotBrain.profile("champion")
	if champion.loadout != [6, 6, 6, 6, 6, 6] or champion.difficulty != "expert":
		_fail("mistrz nie ma najlepszego zestawu i poziomu ekspert")
		return
	var mirror := BotBrain.profile("mirror")
	if not bool(mirror.clone_player):
		_fail("Sobowtór nie kopiuje gracza")
		return
	var normal_risk := BotBrain.analyze_roll([1, 1, 1, 1, 1, 1], 240)
	if float(normal_risk.farkle_probability) <= 0.0 or float(normal_risk.farkle_probability) >= 1.0:
		_fail("analiza ryzyka zwróciła nieprawidłowe prawdopodobieństwo")
		return
	var test_rng := RandomNumberGenerator.new()
	test_rng.seed = 12345
	var selection := BotBrain.choose_selection([1, 5, 2, 2, 2, 6], "expert", test_rng, 450, [6, 6, 6, 6, 6, 6])
	if not bool(selection.valid) or int(selection.score) <= 0:
		_fail("ekspert nie znalazł punktującego wyboru")
		return
	var learned := {"bank_count": 5, "bank_total": 1500, "continue_count": 2, "continue_total": 600}
	var should_stop := BotBrain.should_bank({"turn_score": 500, "own_score": 1200, "opponent_score": 900, "target_score": 4000, "next_types": [1]}, mirror, "hard", learned)
	if not should_stop:
		_fail("Sobowtór nie zastosował wyuczonego ostrożnego progu")
		return
	var first_win_learning := {"bank_count": 1, "bank_total": 700, "bank_ema": 700.0, "continue_count": 3, "continue_total": 900, "winning_matches": 1}
	var learns_after_first_win := BotBrain.should_bank({"turn_score": 750, "own_score": 500, "opponent_score": 500, "target_score": 4000, "next_types": [1]}, mirror, "hard", first_win_learning)
	if not learns_after_first_win:
		_fail("Sobowtór nie użył stylu zapisanego po pierwszym zwycięstwie gracza")
		return
	var chases_hot_streak := not BotBrain.should_bank({"turn_score": 1500, "own_score": 0, "opponent_score": 0, "target_score": 4000, "next_types": champion.loadout, "hot_dice_cycles": 1}, champion, "expert", {})
	if not chases_hot_streak:
		_fail("mistrz przerwał turę po zdobyciu gorących kości")
		return
	var takes_winning_score := BotBrain.should_bank({"turn_score": 500, "own_score": 3600, "opponent_score": 3900, "target_score": 4000, "next_types": champion.loadout, "hot_dice_cycles": 2}, champion, "expert", {})
	if not takes_winning_score:
		_fail("mistrz nie zapisał wyniku kończącego mecz")
		return
	print("PASS: profile botów, kalkulacja ryzyka, pogoń mistrza i uczenie Sobowtóra")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
