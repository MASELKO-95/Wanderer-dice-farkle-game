extends SceneTree

func _init() -> void:
	call_deferred("run")

func choose(game: Node, id: String, finish_reply := true) -> void:
	var dialogue: Control = game.active_dialogue
	dialogue.finish_dialogue()
	var line: Resource = dialogue._current_lines[dialogue._line_index]
	for choice: Resource in line.choices:
		if choice.id == id:
			dialogue._select_choice(choice)
			if finish_reply and game.campaign_checkpoint.get("section", "") == "wager_reply":
				game.active_dialogue.finish_dialogue()
			return
	assert(false, "missing choice: " + id)

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game.campaign_progress = 1
	game.campaign_story.side_wins = [0,1,2,3,4,5]
	game.campaign_story.passed["12"] = true
	game._show_campaign_screen()
	game._offer_campaign_chapter(1)
	choose(game,"wyzwanie")
	game.active_dialogue.finish_dialogue()
	assert(game.active_dialogue._current_lines[0].choices.size() == 2)
	choose(game,"leave")
	await process_frame
	game.campaign_economy.silver = 100
	game._offer_campaign_chapter(1)
	game.active_dialogue.finish_dialogue()
	assert(not game.active_dialogue._full_text.contains("Hazard"), "Free play must not be described as gambling")
	choose(game,"wager_25",false)
	assert(game.campaign_checkpoint.section == "wager_reply")
	assert(game.active_dialogue._full_text.contains("Hazard"))
	assert(game.campaign_economy.silver == 100 and game.campaign_story.liczba_zakladow == 0)
	var saved: ConfigFile = game._campaign_config()
	game._show_campaign_screen()
	game._apply_campaign_config(saved)
	game._show_campaign_dialogue(1,"wager_reply")
	game.active_dialogue.finish_dialogue()
	assert(game.campaign_economy.silver == 75 and game.campaign_economy.active_wager == 25)
	assert(game.campaign_story.liczba_zakladow == 1)
	assert(game.campaign_story.ending_points.king == -2)
	game._show_winner(true)
	game._show_winner(true)
	assert(game.campaign_economy.silver == 300)
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._begin_campaign_match(1,50)
	game._show_winner(false)
	assert(game.campaign_economy.silver == 250 and game.campaign_story.liczba_zakladow == 2)
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._begin_campaign_match(1,25)
	game.show_main_menu()
	game._load_progress()
	assert(game.campaign_economy.silver == 225 and game.campaign_economy.active_wager == 0)
	assert(game.campaign_story.liczba_zakladow == 3 and not game.CHRONICLES.clean_run(game.campaign_story))
	assert(not game._chronicle_resource(8,"wager",{"silver":500}).lines[0].text.contains("Pięćset"))
	assert(not game._chronicle_resource(8,"wager_reply",{"pending_wager":25}).lines[0].text.contains("Pięćset"))
	assert(game._chronicle_resource(8,"wager_reply",{"pending_wager":500}).lines[0].text.contains("Pięćset"))
	game.queue_free()
	await create_timer(0.2).timeout
	print("PASS: wager offer, free play, refusal, payout, route penalties and abandoned-stake persistence")
	quit()
