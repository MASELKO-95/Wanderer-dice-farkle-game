extends SceneTree

const SAVES := preload("res://scripts/campaign_saves.gd")
var failures := 0

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	# A legacy single-save campaign must be imported without losing its purse.
	var legacy := ConfigFile.new()
	legacy.set_value("campaign", "progress", 2)
	legacy.set_value("campaign", "silver", 123)
	legacy.save(game.SAVE_PATH)
	root.add_child(game)
	await process_frame
	check(game.campaign_progress == 2 and game.campaign_economy.silver == 123 and SAVES.read_slot(0) != null, "legacy campaign migrated into first slot")
	check(game.language_select != null, "persistent language selector exists")
	game._activate_campaign_slot(0)
	game.campaign_progress = 12
	game.campaign_economy.silver = 300
	game._show_campaign_dialogue(11, "coronation")
	var dialogue: Control = game.active_dialogue
	dialogue.finish_dialogue()
	check(not dialogue._ending, "final choice cannot be skipped")
	check(game._copy_campaign_slot(1), "copy before ending decision")
	check(not game._copy_campaign_slot(1), "copy never overwrites existing slot")
	dialogue._select_choice(dialogue._current_lines[0].choices[2])
	await process_frame
	check(game.campaign_ending == "emperor" and game.campaign_choices.size() == 1, "choice and ending recorded")
	game._activate_campaign_slot(1)
	await process_frame
	check(is_instance_valid(game.active_dialogue) and game.campaign_ending.is_empty(), "branch resumes at unresolved dialogue")
	check(game.campaign_choices.is_empty() and game.campaign_economy.silver == 300, "branch retains independent inventory and decisions")
	root.get_node("I18n").set_language("en")
	check(game.active_dialogue._line_index == 0 and game.campaign_choices.is_empty(), "language switch preserves dialogue and decisions")
	dialogue = game.active_dialogue
	dialogue._select_choice(dialogue._current_lines[0].choices[0])
	await process_frame
	check(game.campaign_ending == "princess", "alternate ending chosen")
	check(str(SAVES.read_slot(0).get_value("campaign", "ending")) == "emperor", "original ending intact")
	check(str(SAVES.read_slot(1).get_value("campaign", "ending")) == "princess", "alternate ending saved")
	game._activate_campaign_slot(2)
	await process_frame
	check(game.campaign_progress == 0 and game.campaign_ending.is_empty() and game.campaign_economy.silver == 0 and game.campaign_choices.is_empty(), "fresh slot has no inherited decisions or money")
	game._activate_campaign_slot(0)
	await process_frame
	check(game.campaign_ending == "emperor" and game.campaign_economy.silver == 300, "load original campaign")
	game._load_progress()
	check(game.campaign_slot == 0 and game.campaign_ending == "emperor", "active slot restored on restart")
	game._show_campaign_saves()
	await process_frame
	check(game.screen_layer.get_node_or_null("CampaignSaves") != null, "save selection UI")
	var language_before: String = root.get_node("I18n").current_locale
	game._show_multiplayer_lobby()
	root.get_node("I18n").set_language("pl" if language_before != "pl" else "en")
	check(game.current_menu == "lobby" and game.screen_layer.get_node_or_null("MultiplayerLobby") != null, "language selection keeps multiplayer lobby open")
	game._show_campaign_saves()
	await process_frame
	game._confirm_delete_campaign_slot(1)
	await process_frame
	var confirmation: ConfirmationDialog = game.screen_layer.get_node("DeleteSaveConfirmation")
	confirmation.canceled.emit()
	await process_frame
	check(SAVES.read_slot(1) != null, "cancelled deletion preserves save")
	game._confirm_delete_campaign_slot(1)
	await process_frame
	confirmation = game.screen_layer.get_node("DeleteSaveConfirmation")
	confirmation.confirmed.emit()
	await process_frame
	check(SAVES.read_slot(1) == null and SAVES.read_slot(0) != null, "confirmed deletion removes only selected save")
	check(game._delete_campaign_slot(0), "delete active save")
	game._load_progress()
	game._save_progress()
	check(game.campaign_slot == -1 and SAVES.read_slot(0) == null and game.campaign_progress == 0, "deleted active save is not recreated by reload or autosave")
	check(not game._delete_campaign_slot(-1) and not game._delete_campaign_slot(6), "reject invalid deletion targets")
	game._activate_campaign_slot(1)
	check(game.campaign_slot == 1 and game.campaign_economy.silver == 0, "deleted slot can start fresh")
	game.queue_free()
	await create_timer(0.2).timeout
	if failures == 0:
		print("PASS: independent saves, branching endings, dialogue checkpoint, language switch and reload")
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: " + message)
		failures += 1
