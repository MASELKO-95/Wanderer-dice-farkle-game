extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game._show_campaign_screen()
	game._offer_campaign_chapter(0)
	var dialogue: Control = game.active_dialogue
	dialogue._select_choice(dialogue._current_lines[0].choices[1])
	assert(dialogue.story_gender == "female" and "chłopka" in dialogue._full_text)
	dialogue._select_choice(dialogue._current_lines[1].choices[2])
	assert(game.campaign_story.powod == "lenistwo")
	assert(game.campaign_story.ending_points.world_champion == -2)
	assert("Matylda" in dialogue._full_text)
	assert("księżniczki Elary" in dialogue._current_lines[3].text and "księcia" not in dialogue._current_lines[3].text)
	dialogue.finish_dialogue()
	await process_frame
	assert(game.campaign_tutorial and game.target_score == 500)
	game._show_winner(false)
	assert(game.campaign_story.ticket and game.campaign_story.porridge and game.campaign_progress == 0)
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._offer_campaign_chapter(0)
	dialogue = game.active_dialogue
	dialogue.finish_dialogue()
	assert(dialogue._line_index == 1 and dialogue._current_lines[1].choices.size() == 3)
	dialogue._select_choice(dialogue._current_lines[1].choices[0])
	assert("Stanowisko trzecie" in dialogue._full_text)
	dialogue.finish_dialogue()
	await process_frame
	game._show_winner(true)
	game._show_winner(true)
	assert(game.campaign_economy.silver == 155 and game.campaign_progress == 1)
	assert(game.campaign_story.ending_points.king == 1)
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game.campaign_story.prologue_done = true
	game._begin_campaign_match(0)
	game._show_winner(false)
	assert(game.campaign_progress == 1 and game.campaign_economy.silver == 0)
	assert(game.campaign_story.ending_points == {"princess":1,"king":0,"emperor":-1,"world_champion":-2})
	game.active_dialogue.finish_dialogue()
	await process_frame
	game.queue_free()
	await create_timer(0.2).timeout
	print("PASS: gender, Elara, reason points, mother memory, tutorial, registration and first match outcomes")
	quit()
