extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func choose(game: Node, id: String) -> void:
	var dialogue: Control = game.active_dialogue
	var line: Resource = dialogue.get("_current_lines")[dialogue.get("_line_index")]
	for choice: Resource in line.get("choices"):
		if str(choice.get("id")) == id:
			dialogue.call("_select_choice", choice)
			return
	check(false, "missing dialogue choice: " + id)

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.campaign_progress = 1
	game._show_campaign_screen()
	await process_frame
	game._offer_campaign_chapter(1)
	check(game.active_dialogue.sequence.lines[0].choices.size() == 2, "penniless player can play free or leave")
	game.active_dialogue.finish_dialogue()
	check(is_instance_valid(game.active_dialogue), "negotiation cannot be skipped")
	choose(game, "leave")
	await process_frame
	game.campaign_economy.silver = 100
	game._offer_campaign_chapter(1)
	choose(game, "propose_25")
	check(game.active_dialogue._line_index == 1 and game.campaign_economy.silver == 100, "opponent answers before charging")
	choose(game, "negotiate")
	choose(game, "propose_25")
	choose(game, "wager_25")
	await process_frame
	check(game.campaign_economy.silver == 100, "intro has not charged yet")
	game.active_dialogue.finish_dialogue()
	await process_frame
	check(game.campaign_economy.silver == 75 and game.campaign_economy.active_wager == 25, "agreed stake charged at start")
	game.player_score = game.target_score
	game._show_winner(true)
	game._show_winner(true)
	check(game.campaign_economy.silver == 300, "payout and reward applied once")
	await process_frame
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._show_campaign_screen()
	game._begin_campaign_match(1, 50)
	game._show_winner(false)
	check(game.campaign_economy.silver == 250, "loss forfeits stake")
	await process_frame
	game.active_dialogue.finish_dialogue()
	await process_frame
	game._offer_campaign_chapter(1)
	choose(game, "leave")
	await process_frame
	check(game.campaign_economy.silver == 250, "leaving negotiation does not charge")
	game._show_campaign_screen()
	game._begin_campaign_match(1, 25)
	game.show_main_menu()
	game._load_progress()
	check(game.campaign_economy.silver == 225 and game.campaign_economy.active_wager == 0, "abandoned match forfeits stake")
	game.campaign_progress = 2
	game._show_campaign_screen()
	game._offer_campaign_chapter(2)
	check(not game.active_dialogue.has_meta("wager_index"), "ordinary opponent goes to story")
	game.active_dialogue.finish_dialogue()
	await process_frame
	check(game.campaign_economy.silver == 225, "ordinary opponent does not charge")
	game.queue_free()
	await create_timer(0.2).timeout
	if failures == 0:
		print("PASS: wager conversation, proposals, confirmation, refusal, free play and payout")
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: " + message)
		failures += 1
