class_name DiceCatalog
extends RefCounted

# Zamiast tekstów przechowujemy klucze tłumaczeń nazw.
const TYPES := [
	{"name_key": "die_unlucky", "short_key": "short_unlucky", "weights": [1, 5, 5, 5, 5, 1], "unlock": 0},
	{"name_key": "die_normal", "short_key": "short_normal", "weights": [1, 1, 1, 1, 1, 1], "unlock": 0},
	{"name_key": "die_unpopular", "short_key": "short_unpopular", "weights": [1, 3, 2, 2, 2, 1], "unlock": 2},
	{"name_key": "die_odd", "short_key": "short_odd", "weights": [4, 1, 4, 1, 4, 1], "unlock": 4},
	{"name_key": "die_lucky", "short_key": "short_lucky", "weights": [6, 1, 2, 3, 4, 6], "unlock": 7},
	{"name_key": "die_heavenly", "short_key": "short_heavenly", "weights": [7, 2, 2, 2, 2, 4], "unlock": 10},
	{"name_key": "die_gambling", "short_key": "short_gambling", "weights": [6, 0, 1, 1, 6, 4], "unlock": 14},
	{"name_key": "die_trinity", "short_key": "short_trinity", "weights": [4, 5, 10, 1, 1, 1], "unlock": 18}
]

static func roll(type_index: int, rng: RandomNumberGenerator) -> int:
	var die: Dictionary = TYPES[clampi(type_index, 0, TYPES.size() - 1)]
	var weights: Array = die.weights
	var total := 0
	for weight: int in weights:
		total += weight
	var draw := rng.randi_range(1, total)
	var running := 0
	for side in range(6):
		running += int(weights[side])
		if draw <= running:
			return side + 1
	return 6

# Funkcje zwracające przetłumaczony tekst
static func type_name(type_index: int) -> String:
	var key: String = TYPES[clampi(type_index, 0, TYPES.size() - 1)].name_key
	return _translate(key)

static func type_short(type_index: int) -> String:
	var key: String = TYPES[clampi(type_index, 0, TYPES.size() - 1)].short_key
	return _translate(key)

static func type_hint(type_index: int) -> String:
	var weights: Array = TYPES[clampi(type_index, 0, TYPES.size() - 1)].weights
	var parts: Array[String] = []
	for weight: int in weights:
		parts.append(str(weight))
	return "1–6: %s" % " · ".join(parts)

static func _translate(key: String) -> String:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		var i18n := scene_tree.root.get_node_or_null("I18n")
		if i18n != null and i18n.has_method("translate"):
			return str(i18n.call("translate", key))
	return key

static func is_unlocked(type_index: int, matches_played: int) -> bool:
	return matches_played >= int(TYPES[clampi(type_index, 0, TYPES.size() - 1)].unlock)
