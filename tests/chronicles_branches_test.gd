extends SceneTree

var game: Control

func _init() -> void:
	call_deferred("_run")

func choose(id: String) -> void:
	var dialogue: Control = game.active_dialogue
	dialogue.finish_dialogue()
	var line: Resource = dialogue._current_lines[dialogue._line_index]
	for choice in line.choices:
		if choice.id == id:
			dialogue._select_choice(choice)
			return
	assert(false,"Missing " + id)

func _run() -> void:
	game = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game.campaign_progress = 1
	game.campaign_story.side_wins = [0,1,2,3,4,5]
	game.campaign_story.passed["12"] = true
	game.campaign_economy.silver = 200
	game._show_campaign_screen()
	game._offer_campaign_chapter(1)
	choose("targ")
	game.active_dialogue.finish_dialogue()
	choose("buy_seal")
	assert(game.campaign_economy.silver == 50 and game.campaign_story.pieczec and game.campaign_story.pomogl_zlodziejowi)
	var bought_save: ConfigFile = game._campaign_config()
	assert(game.campaign_checkpoint.section == "seal_route")
	choose("skip")
	assert(game.campaign_progress == 2)
	game._apply_campaign_config(bought_save)
	game._show_campaign_dialogue(1,"seal_route")
	choose("skip")
	assert(game.campaign_economy.silver == 50 and game.campaign_progress == 2)
	game._offer_campaign_chapter(13)
	choose("sojusz")
	var points: Dictionary = game.campaign_story.ending_points.duplicate()
	var saved: ConfigFile = game._campaign_config()
	var line: int = game.campaign_checkpoint.line
	game._show_campaign_screen()
	game._apply_campaign_config(saved)
	game._show_campaign_dialogue(13,"intro",Callable(),line)
	assert(game.active_dialogue._full_text.contains("Cienie nie śpią"))
	game.active_dialogue.finish_dialogue()
	choose("wager_0")
	game._show_winner(false)
	assert(game.campaign_progress == 2 and game.campaign_story.sojusz_vespera)
	game.active_dialogue.finish_dialogue()
	game._offer_campaign_chapter(13)
	assert(game.active_dialogue._current_lines[1].choices.is_empty(),"Committed intro must not offer contradictory options")
	game.active_dialogue.finish_dialogue()
	choose("wager_0")
	assert(game.campaign_story.ending_points.princess == points.princess)
	game._show_winner(true)
	choose("gra")
	game.active_dialogue.finish_dialogue()
	assert(game.campaign_story.sojusz_vespera)
	game._show_campaign_screen()
	# Shop purchases remain disqualifying after unequipping and save/reload.
	game.campaign_economy.silver = 500
	game._buy_campaign_die(2)
	assert(game.campaign_story.dice_purchases == 1)
	game.campaign_economy.equip(0,1)
	game._apply_campaign_config(game._campaign_config())
	assert(not game.CHRONICLES.clean_run(game.campaign_story))
	# Mercy does not grant victory money; it does release the next chapter.
	game._show_campaign_screen()
	game.campaign_progress = 3
	for attempt in range(2):
		game._begin_campaign_match(3)
		game._show_winner(false)
		game.active_dialogue.finish_dialogue()
	assert(game.campaign_progress == 4 and game.campaign_story.sekret)
	# Earlier endings are offered only when their conditions are met.
	game.campaign_story.ending_points = {"princess":0,"king":6,"emperor":0,"world_champion":0}
	game._show_campaign_dialogue(7,"coronation")
	choose("ending:king")
	assert(game.campaign_ending == "king" and game.campaign_story.finished)
	assert(not game.CHRONICLES.can_enter(8,8,game.campaign_story))
	game.active_dialogue.finish_dialogue()
	game._apply_campaign_config(ConfigFile.new())
	game._begin_campaign_match(0)
	game.console_finish_match(true)
	assert(game.campaign_story.console_used and not game.CHRONICLES.clean_run(game.campaign_story))
	game.active_dialogue.finish_dialogue()
	await process_frame
	game.queue_free()
	await create_timer(0.3).timeout
	print("PASS: seal purchase/skip, choice checkpoint, retry consistency, purchase tracking, mercy, early ending and console exclusion")
	quit()
