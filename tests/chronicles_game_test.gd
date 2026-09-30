extends SceneTree

var game: Control
var plan := {"0:prologue":"female", "0:intro":"register", "12:intro":"praca", "13:intro":"sojusz", "13:victory":"wroce", "6:intro":"prawo", "7:coronation":"continue", "9:coronation":"continue", "11:coronation":"ending:shadow"}

func _init() -> void:
	call_deferred("_run")

func _dialogues() -> void:
	var steps := 0
	while is_instance_valid(game.active_dialogue):
		steps += 1
		assert(steps < 100, "Dialogue did not finish")
		var dialogue: Control = game.active_dialogue
		dialogue.finish_dialogue()
		if is_instance_valid(game.active_dialogue) and game.active_dialogue == dialogue:
			var line: Resource = dialogue._current_lines[dialogue._line_index]
			assert(not line.choices.is_empty())
			var key := "%d:%s" % [game.campaign_checkpoint.chapter,game.campaign_checkpoint.section]
			var desired := str(plan.get(key,"wager_0" if game.campaign_checkpoint.section == "wager" else ""))
			if game.campaign_checkpoint.section == "prologue" and dialogue._line_index == 1:
				desired = "laziness"
			var selected: Resource = line.choices[0]
			for choice in line.choices:
				if choice.id == desired:
					selected = choice
			dialogue._select_choice(selected)
		await process_frame

func _run() -> void:
	game = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var language := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "pl"
	root.get_node("I18n").set_language(language)
	game._apply_campaign_config(ConfigFile.new())
	game._show_campaign_screen()
	game._continue_campaign()
	await _dialogues()
	assert(game.campaign_tutorial and game.target_score == 500)
	assert(game.campaign_story.gender == "female" and game.campaign_story.powod == "lenistwo")
	game._show_winner(false)
	await _dialogues()
	assert(game.campaign_story.ticket and game.campaign_progress == 0)
	for index in [0,100,101,102,103,104,105,12,1,13,2,3,4,5,6,7,8,9,10,14,11]:
		assert(game.CHRONICLES.can_enter(index,game.campaign_progress,game.campaign_story),"Locked index %d" % index)
		assert(game.campaign_active and game.campaign_current_index == index, "Match did not start %d" % index)
		assert(game.target_score == game.CAMPAIGN_CATALOG.chapter(index).target)
		game.player_score = game.target_score
		game._show_winner(true)
		var silver: int = game.campaign_economy.silver
		game._show_winner(true)
		assert(game.campaign_economy.silver == silver,"Duplicate payout")
		await _dialogues()
	assert(game.campaign_progress == 12 and game.campaign_ending == "shadow")
	assert(game.campaign_story.finished and game.campaign_story.matka_pogodzona)
	assert(game.campaign_economy.silver == 3995, "Unexpected rewards: %d" % game.campaign_economy.silver)
	assert(game.achievements.unlocked.has("clean_run") and game.achievements.unlocked.has("shadow"))
	assert(game.campaign_story.liczba_zakladow == 0 and game.campaign_story.dice_purchases == 0)
	var save: ConfigFile = game._campaign_config()
	game._apply_campaign_config(save)
	assert(game.campaign_story.finished and game.campaign_story.sojusz_vespera and game.campaign_story.side_wins.size() == 6)
	game._show_achievements()
	await process_frame
	game.queue_free()
	await process_frame
	await create_timer(4.1).timeout
	print("PASS: linear campaign (%s), tutorial, 21 tables without chapter selection, secret ending, rewards and saves" % language)
	quit()
