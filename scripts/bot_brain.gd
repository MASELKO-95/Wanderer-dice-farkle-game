class_name BotBrain
extends RefCounted

const DIFFICULTIES := ["easy", "normal", "hard", "expert"]
const PROFILES := [
	{
		"id": "rookie", "name_key": "bot_rookie_name", "description_key": "bot_rookie_desc", "difficulty": "easy",
		"loadout": [1, 1, 1, 1, 1, 1], "aggression": 0.72,
		"appearance": {"skin": "fair", "tunic": "moss", "hair": "brown"}
	},
	{
		"id": "gambler", "name_key": "bot_gambler_name", "description_key": "bot_gambler_desc", "difficulty": "normal",
		"loadout": [1, 2, 3, 1, 2, 3], "aggression": 1.18,
		"appearance": {"skin": "warm", "tunic": "wine", "hair": "black"}
	},
	{
		"id": "tactician", "name_key": "bot_tactician_name", "description_key": "bot_tactician_desc", "difficulty": "hard",
		"loadout": [4, 5, 3, 4, 5, 3], "aggression": 0.96,
		"appearance": {"skin": "olive", "tunic": "navy", "hair": "auburn"}
	},
	{
		"id": "champion", "name_key": "bot_champion_name", "description_key": "bot_champion_desc", "difficulty": "expert",
		"loadout": [6, 6, 6, 6, 6, 6], "aggression": 1.12,
		"appearance": {"skin": "warm", "tunic": "gold", "hair": "gray"}
	},
	{
		"id": "mirror", "name_key": "bot_mirror_name", "description_key": "bot_mirror_desc", "difficulty": "hard",
		"loadout": [], "aggression": 1.0, "clone_player": true,
		"appearance": {}
	}
]

static var _risk_cache: Dictionary = {}

static func profile(profile_id: String) -> Dictionary:
	for entry: Dictionary in PROFILES:
		if str(entry.id) == profile_id:
			return entry.duplicate(true)
	return (PROFILES[0] as Dictionary).duplicate(true)

static func choose_selection(values: Array[int], difficulty: String, rng: RandomNumberGenerator, turn_score: int, active_types: Array[int]) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for mask in range(1, 1 << values.size()):
		var picked: Array[int] = []
		var indices: Array[int] = []
		for index in range(values.size()):
			if mask & (1 << index):
				picked.append(values[index])
				indices.append(index)
		var result := FarkleRules.score_dice(picked)
		if bool(result.valid):
			candidates.append({"valid": true, "score": int(result.score), "values": picked, "indices": indices})
	if candidates.is_empty():
		return {"valid": false, "score": 0, "values": [], "indices": []}
	if difficulty == "easy" and candidates.size() > 1 and rng.randf() < 0.38:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	var best := candidates[0]
	var best_utility := -INF
	for candidate: Dictionary in candidates:
		var dice_left := values.size() - (candidate.indices as Array).size()
		if dice_left == 0:
			dice_left = 6
		var immediate := float(candidate.score)
		var utility := immediate + float(dice_left) * (18.0 if difficulty == "normal" else 32.0)
		if difficulty in ["hard", "expert"]:
			var next_types: Array[int] = []
			for index in range(active_types.size()):
				if index not in candidate.indices:
					next_types.append(active_types[index])
			if next_types.is_empty():
				next_types = active_types.duplicate()
			var risk := analyze_roll(next_types, 240 if difficulty == "expert" else 120)
			utility += float(risk.expected_score) * 0.32
			utility -= float(risk.farkle_probability) * float(turn_score + int(candidate.score)) * 0.55
		if utility > best_utility:
			best_utility = utility
			best = candidate
	return best

static func should_bank(context: Dictionary, profile_data: Dictionary, difficulty: String, learned: Dictionary) -> bool:
	var turn_score := int(context.get("turn_score", 0))
	var own_score := int(context.get("own_score", 0))
	var opponent_score := int(context.get("opponent_score", 0))
	var target_score := int(context.get("target_score", 4000))
	if own_score + turn_score >= target_score:
		return true
	if difficulty == "easy":
		return turn_score >= 450 or (turn_score >= 250 and randf() < 0.48)

	var next_types: Array[int] = []
	for type_index in context.get("next_types", []):
		next_types.append(int(type_index))
	var samples := 320 if difficulty == "expert" else 180 if difficulty == "hard" else 90
	var risk := analyze_roll(next_types, samples)
	var aggression := float(profile_data.get("aggression", 1.0))
	var threshold := 650.0 if difficulty == "normal" else 850.0 if difficulty == "hard" else 1150.0
	var learned_wins := int(learned.get("winning_matches", 0))
	var has_reliable_learning := learned_wins >= 1 and int(learned.get("bank_count", 0)) >= 1
	if not has_reliable_learning:
		has_reliable_learning = int(learned.get("bank_count", 0)) >= 3
	if bool(profile_data.get("clone_player", false)) and has_reliable_learning:
		var learned_bank_score := float(learned.get("bank_ema", 0.0))
		if learned_bank_score <= 0.0:
			learned_bank_score = float(learned.get("bank_total", 0)) / float(learned.bank_count)
		threshold = clampf(learned_bank_score, 250.0, 1800.0)
		var continues := float(learned.get("continue_count", 0))
		var banks := float(learned.get("bank_count", 0))
		aggression *= clampf(0.75 + continues / maxf(1.0, continues + banks) * 0.75, 0.75, 1.45)

	var score_gap := opponent_score - own_score
	if score_gap > 0:
		var chase_pressure := clampf(float(score_gap) / float(maxi(1, target_score)), 0.0, 0.85)
		aggression *= 1.0 + chase_pressure * 0.85
		threshold *= 1.0 + chase_pressure * 0.65
	elif own_score - opponent_score >= target_score * 0.25:
		aggression *= 0.88
		threshold *= 0.88
	# Nawet gdy bot jeszcze minimalnie prowadzi, gracz blisko mety stanowi
	# zagrożenie. Im bliżej zwycięstwa jest gracz, tym dalej bot przesuwa
	# bezpieczny próg bankowania.
	var opponent_threat := clampf((float(opponent_score) / float(maxi(1, target_score)) - 0.60) / 0.40, 0.0, 1.0)
	aggression *= 1.0 + opponent_threat * 0.20
	threshold *= 1.0 + opponent_threat * 0.22

	# Po zdobyciu wszystkich sześciu kości ekspert wykorzystuje świeży komplet
	# i próbuje zamknąć mecz w tej samej turze. Zatrzyma się dopiero po uzyskaniu
	# wyniku zwycięskiego albo po Farkle.
	var hot_dice_cycles := int(context.get("hot_dice_cycles", 0))
	if difficulty == "expert" and hot_dice_cycles > 0:
		return false

	if difficulty == "expert":
		aggression *= 1.12
		if score_gap > 0 and turn_score < mini(score_gap, target_score - own_score):
			threshold *= 1.18
	var expected_gain := float(risk.expected_score) * aggression
	var expected_loss := float(risk.farkle_probability) * float(turn_score)
	var stop_ratio := 1.30 if difficulty == "expert" else 1.12 if difficulty == "hard" else 0.95
	var calculated_stop := expected_loss > expected_gain * stop_ratio
	return float(turn_score) >= threshold or (turn_score >= 250 and calculated_stop)

static func analyze_roll(types: Array[int], samples: int = 160) -> Dictionary:
	if types.is_empty():
		return {"farkle_probability": 1.0, "expected_score": 0.0}
	var signature_types := types.duplicate()
	signature_types.sort()
	var key := "%s:%d" % [str(signature_types), samples]
	if _risk_cache.has(key):
		return (_risk_cache[key] as Dictionary).duplicate()
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = hash(key) & 0x7fffffff
	var farkles := 0
	var score_sum := 0.0
	for _sample in range(samples):
		var values: Array[int] = []
		for type_index in types:
			values.append(DiceCatalog.roll(type_index, local_rng))
		var result := FarkleRules.best_scoring_subset(values)
		if not bool(result.valid):
			farkles += 1
		else:
			score_sum += float(result.score)
	var analysis := {
		"farkle_probability": float(farkles) / float(samples),
		"expected_score": score_sum / float(samples)
	}
	_risk_cache[key] = analysis
	return analysis.duplicate()
