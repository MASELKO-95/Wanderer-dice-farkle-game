class_name FarkleRules
extends RefCounted

const STORY_TEXT := preload("res://scripts/story_text.gd")


static func score_dice(values: Array[int]) -> Dictionary:
	if values.is_empty():
		return {"valid": false, "score": 0, "label": ""}

	var counts: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for value in values:
		if value < 1 or value > 6:
			return {"valid": false, "score": 0, "label": ""}
		counts[value] += 1

	var total := 0
	var descriptions: Array[String] = []
	var full_straight := true
	for face in range(1, 7):
		if counts[face] == 0:
			full_straight = false
	if full_straight:
		return {"valid": true, "score": 1500, "label": STORY_TEXT.text("strit 1–6")}

	var low_straight := true
	for face in range(1, 6):
		if counts[face] == 0:
			low_straight = false
	if low_straight:
		total += 500
		descriptions.append(STORY_TEXT.text("strit 1–5"))
		for face in range(1, 6):
			counts[face] -= 1
	else:
		var high_straight := true
		for face in range(2, 7):
			if counts[face] == 0:
				high_straight = false
		if high_straight:
			total += 750
			descriptions.append(STORY_TEXT.text("strit 2–6"))
			for face in range(2, 7):
				counts[face] -= 1

	for face in range(1, 7):
		var amount: int = counts[face]
		if amount >= 3:
			var base: int = 1000 if face == 1 else face * 100
			var multiplier := 1 << (amount - 3)
			total += base * multiplier
			descriptions.append("%d×%d" % [amount, face])
		elif face == 1 and amount > 0:
			total += amount * 100
			descriptions.append(STORY_TEXT.text("%d×jedynka") % amount)
		elif face == 5 and amount > 0:
			total += amount * 50
			descriptions.append(STORY_TEXT.text("%d×piątka") % amount)
		elif amount > 0:
			return {"valid": false, "score": 0, "label": STORY_TEXT.text("Te kości nie tworzą punktowanego zestawu")}

	return {
		"valid": total > 0,
		"score": total,
		"label": ", ".join(descriptions)
	}


static func best_scoring_subset(values: Array[int]) -> Dictionary:
	var best := {"valid": false, "score": 0, "indices": PackedInt32Array(), "values": []}
	for mask in range(1, 1 << values.size()):
		var picked: Array[int] = []
		var indices := PackedInt32Array()
		for index in range(values.size()):
			if mask & (1 << index):
				picked.append(values[index])
				indices.append(index)
		var result := score_dice(picked)
		if result.valid and (result.score > best.score or (result.score == best.score and picked.size() > best.values.size())):
			best = {
				"valid": true,
				"score": result.score,
				"label": result.label,
				"indices": indices,
				"values": picked
			}
	return best
