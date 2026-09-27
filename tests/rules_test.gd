extends SceneTree

var failures := 0


func _init() -> void:
	_check_score([1], 100, "pojedyncza jedynka")
	_check_score([5], 50, "pojedyncza piątka")
	_check_score([1, 1, 1], 1000, "trzy jedynki")
	_check_score([4, 4, 4], 400, "trzy czwórki")
	_check_score([4, 4, 4, 4], 800, "cztery czwórki")
	_check_score([1, 1, 1, 1], 2000, "cztery jedynki")
	_check_score([1, 2, 3, 4, 5], 500, "strit 1–5")
	_check_score([2, 3, 4, 5, 6], 750, "strit 2–6")
	_check_score([1, 2, 3, 4, 5, 6], 1500, "strit 1–6")
	_check_score([1, 2, 3, 4, 5, 5], 550, "strit i piątka")
	_check_invalid([2, 2], "zwykła para")
	_check_invalid([2, 2, 3, 3, 4, 4], "trzy pary")
	_check_weighted_dice()

	if failures == 0:
		print("PASS: punktowanie i ważone kości (%d typów)" % DiceCatalog.TYPES.size())
	else:
		printerr("FAIL: %d testów" % failures)
	quit(1 if failures > 0 else 0)


func _typed(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result


func _check_score(values: Array, expected: int, description: String) -> void:
	var result := FarkleRules.score_dice(_typed(values))
	if not result.valid or result.score != expected:
		failures += 1
		printerr("%s: oczekiwano %d, otrzymano %s" % [description, expected, result])


func _check_invalid(values: Array, description: String) -> void:
	var result := FarkleRules.score_dice(_typed(values))
	if result.valid:
		failures += 1
		printerr("%s: zestaw nie powinien punktować" % description)


func _check_weighted_dice() -> void:
	for die: Dictionary in DiceCatalog.TYPES:
		if die.weights.size() != 6:
			failures += 1
			printerr("%s: nieprawidłowa liczba ścian" % die.name)
	var test_rng := RandomNumberGenerator.new()
	test_rng.seed = 20260914
	for index in range(3000):
		if DiceCatalog.roll(6, test_rng) == 2:
			failures += 1
			printerr("Szczęśliwa kość do gry wyrzuciła ścianę o wadze zero")
			return
