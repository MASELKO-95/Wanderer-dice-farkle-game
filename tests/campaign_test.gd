extends SceneTree

const CAMPAIGN := preload("res://scripts/campaign_catalog.gd")


func _init() -> void:
	if CAMPAIGN.CHAPTERS.size() != 12:
		_fail("kampania nie ma 12 rozdziałów")
		return
	var previous_target := 0
	for index in range(CAMPAIGN.CHAPTERS.size()):
		var chapter: Dictionary = CAMPAIGN.chapter(index)
		if int(chapter.target) < previous_target:
			_fail("poziom turnieju nie rośnie w rozdziale %d" % (index + 1))
			return
		previous_target = int(chapter.target)
		if not AssetLibrary.has_model(str(chapter.avatar)):
			_fail("brakuje postaci dla rozdziału %d" % (index + 1))
			return
		if str(BotBrain.profile(str(chapter.profile)).id) != str(chapter.profile):
			_fail("brakuje profilu bota dla rozdziału %d" % (index + 1))
			return
		if not CAMPAIGN.can_play(index, index):
			_fail("bieżący rozdział powinien być dostępny")
			return
	if CAMPAIGN.advance(0, 0) != 1 or CAMPAIGN.advance(1, 0) != 1:
		_fail("postęp kampanii nie rozróżnia nowego zwycięstwa od powtórki")
		return
	if CAMPAIGN.milestone_key_for_progress(6) != "campaign_goal_princess":
		_fail("uratowanie księżniczki nie jest kamieniem milowym")
		return
	if CAMPAIGN.milestone_key_for_progress(12) != "campaign_goal_world_champion":
		_fail("finał nie przyznaje tytułu mistrza świata")
		return
	print("PASS: 12-rozdziałowa kampania, turniej, postacie i cztery cele fabularne")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
