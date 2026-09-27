extends SceneTree

var failures := 0
func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game._show_campaign_screen()
	game._offer_campaign_chapter(0)
	var d: Control = game.active_dialogue
	d._select_choice(d._current_lines[0].choices[1])
	check(d.story_gender == "female" and "chłopka" in d._full_text, "gender affects following text")
	d._select_choice(d._current_lines[1].choices[2])
	check(game.campaign_economy.silver == 0, "flavour choices have no economy effect")
	var save: ConfigFile = game._campaign_config()
	game._apply_campaign_config(save)
	check(game.campaign_story.gender == "female", "gender survives save")
	check(d._gender_text("[księżniczki|księcia]") == "księcia", "female protagonist seeks prince")
	d.finish_dialogue()
	await process_frame
	check(game.campaign_tutorial and game.bot_name == "Staruszek" and game.target_score == 500, "prologue starts playable tutorial")
	game._show_winner(false)
	check(game.campaign_story.ticket and game.campaign_story.porridge, "losing tutorial still grants both gifts")
	check(game.campaign_progress == 0 and game.campaign_economy.silver == 0, "tutorial is separate from tournament rewards")
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._offer_campaign_chapter(0)
	d = game.active_dialogue
	d.finish_dialogue()
	check(d._line_index == 1, "skip stops at registration choice")
	d._select_choice(d._current_lines[1].choices[0])
	d._advance()
	d._advance()
	check(d._line_index == 7, "polite registration bypasses flirt branch")
	d.finish_dialogue()
	await process_frame
	game._show_winner(true)
	game._show_winner(true)
	check(game.campaign_economy.silver == 155, "150 standard plus 5 extra paid exactly once")
	check(game.campaign_story.ending_points.king == 1 and game.campaign_story.ending_points.world_champion == 1, "victory awards ending points")
	await process_frame
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game.campaign_story.prologue_done = true
	game._begin_campaign_match(0)
	game._show_winner(false)
	check(game.campaign_progress == 1, "first defeat unlocks next opponent")
	check(game.campaign_story.ending_points.king == 0 and game.campaign_story.ending_points.world_champion == 0 and game.campaign_story.ending_points.emperor == 1, "defeat awards only other ending points")
	check(game.campaign_economy.silver == 0, "defeat gives no silver")
	check(not game.CAMPAIGN_OPENING.record_first_result(game.campaign_story, true), "replay cannot farm or rewrite ending points")

	await process_frame
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._show_campaign_screen()
	game._show_campaign_dialogue(0, "intro")
	d = game.active_dialogue
	d.finish_dialogue()
	d._select_choice(d._current_lines[1].choices[1])
	check(d._line_index == 3, "flirt takes its own branch")
	d.finish_dialogue()
	await process_frame
	game._begin_campaign_tutorial()
	game._show_winner(true)
	check(game.campaign_story.ticket and game.campaign_story.porridge and game.campaign_economy.silver == 0, "winning tutorial gives same gifts without silver")
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._begin_campaign_tutorial()
	game.show_main_menu()
	check(not game.campaign_tutorial, "leaving tutorial clears temporary match mode")
	game.queue_free()
	await create_timer(0.2).timeout
	if failures == 0:
		print("PASS: opening, gender, tutorial, registration, rewards, endings and defeat progression")
	quit(0 if failures == 0 else 1)
