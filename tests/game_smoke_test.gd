extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_resource := load("res://main.tscn") as PackedScene
	var game := scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	game.player_name = "Tester"
	game.player_loadout.assign([1, 2, 3, 4, 5, 6])
	game.player_appearance = {"skin": "dark", "tunic": "wine", "hair": "black"}
	game.player_avatar_id = "builtin:king"
	game.bot_profile_id = "mirror"
	game.bot_difficulty = "hard"
	game.bot_name = "Klon Testera"
	game.theme_id = "forest"
	game.start_game()
	await process_frame
	if game.bot_loadout != game.player_loadout or game.bot_avatar_id != game.player_avatar_id:
		printerr("FAIL: Sobowtór nie skopiował modelu i kości gracza")
		quit(1)
		return
	if game.tavern_world.custom_avatars.size() != 2:
		printerr("FAIL: wybrany król i jego Sobowtór nie pojawili się przy stole")
		quit(1)
		return
	if game.tavern_world.theme_id != "forest":
		printerr("FAIL: motyw nie został zastosowany do świata 3D")
		quit(1)
		return
	game._player_roll()
	await create_timer(1.2).timeout

	if game.current_dice.size() != 6:
		printerr("FAIL: pierwszy rzut nie zawiera sześciu kości")
		quit(1)
		return
	if game.current_roll_types != game.player_loadout:
		printerr("FAIL: rzut nie zachował wybranego zestawu kości")
		quit(1)
		return
	if game.dice_row.get_child_count() != 6:
		printerr("FAIL: stół nie wyświetlił sześciu kości")
		quit(1)
		return
	if not game._audio_players.has("dice_roll"):
		printerr("FAIL: nie załadowano wymiennego efektu rzutu")
		quit(1)
		return
	var roll_player: AudioStreamPlayer = game._audio_players["dice_roll"]
	if not is_equal_approx(roll_player.volume_db, 12.0):
		printerr("FAIL: efekt rzutu nie otrzymał wzmocnienia głośności")
		quit(1)
		return
	if game.MEDIEVAL_MUSIC.size() != 4 or not is_instance_valid(game.music_player):
		printerr("FAIL: nie uruchomiono średniowiecznej playlisty")
		quit(1)
		return
	if AudioServer.get_bus_index("Music") < 0:
		printerr("FAIL: brakuje osobnej szyny głośności muzyki")
		quit(1)
		return
	if game.tavern_world.random_decoration_count != 7:
		printerr("FAIL: karczma nie utworzyła siedmiu losowych dekoracji")
		quit(1)
		return
	game.match_learning = {"bank_count": 2, "bank_total": 900, "continue_count": 3, "continue_total": 1200}
	game.player_score = game.target_score
	game.bot_score = 1200
	game._commit_winning_player_learning()
	if int(game.adaptive_learning.get("winning_matches", 0)) != 1 or not game.adaptive_learning.has("bank_ema"):
		printerr("FAIL: Sobowtór nie utrwalił stylu zwycięskiego gracza")
		quit(1)
		return
	game._save_progress()
	var saved_learning := ConfigFile.new()
	if saved_learning.load(game.SAVE_PATH) != OK or int(saved_learning.get_value("learning", "winning_matches", 0)) != 1:
		printerr("FAIL: nauka Sobowtóra nie została zapisana między uruchomieniami gry")
		quit(1)
		return
	game._show_campaign_screen()
	await process_frame
	if game.campaign_economy.silver != 0:
		printerr("FAIL: nowa kampania nie zaczyna się bez srebra")
		quit(1)
		return
	# Fund the purchase scenario independently of the penniless starting state.
	game.campaign_economy.silver = 200
	var quick_loadout: Array = game.player_loadout.duplicate()
	game.screen_layer.find_child("CampaignShopButton", true, false).pressed.emit()
	await process_frame
	if game.screen_layer.get_node_or_null("CampaignShop") == null:
		printerr("FAIL: sklep nie otworzył się z ekranu kampanii")
		quit(1)
		return
	game.screen_layer.find_child("ShopSlot2", true, false).pressed.emit()
	await process_frame
	game.screen_layer.find_child("ShopBuy3", true, false).pressed.emit()
	await process_frame
	if game.campaign_economy.silver != 60 or game.campaign_economy.loadout != [1, 1, 3, 1, 1, 1]:
		printerr("FAIL: zakup nie odjął srebra lub nie założył kości w wybrane miejsce")
		quit(1)
		return
	var saved_shop := ConfigFile.new()
	if saved_shop.load(game.SAVE_PATH) != OK or saved_shop.get_value("campaign", "silver") != 60 or saved_shop.get_value("campaign", "loadout") != [1, 1, 3, 1, 1, 1]:
		printerr("FAIL: zakup nie zapisał sakiewki i zestawu")
		quit(1)
		return
	game._show_campaign_screen()
	game._start_campaign_chapter(0)
	await process_frame
	if not is_instance_valid(game.active_dialogue):
		printerr("FAIL: rozdział kampanii nie uruchomił sceny dialogowej")
		quit(1)
		return
	game.active_dialogue.call("finish_dialogue")
	game.active_dialogue._select_choice(game.active_dialogue._current_lines[1].choices[0])
	game.active_dialogue.call("finish_dialogue")
	await process_frame
	if not game.campaign_active or game.target_score != 1500 or game.bot_avatar_id != "builtin:innkeeper":
		printerr("FAIL: pierwszy rozdział kampanii nie skonfigurował fabularnego przeciwnika")
		quit(1)
		return
	if game.player_loadout != [1, 1, 3, 1, 1, 1]:
		printerr("FAIL: kampania nie używa zakupionych kości")
		quit(1)
		return
	game.player_score = game.target_score
	game.bot_score = 0
	game.match_learning = {"bank_count": 1, "bank_total": 1500, "continue_count": 1, "continue_total": 500}
	game._show_winner(true)
	game._show_winner(true)
	if game.campaign_progress != 1 or game.campaign_economy.silver != 215:
		printerr("FAIL: zwycięstwo nie odblokowało kolejnego rozdziału kampanii")
		quit(1)
		return
	await process_frame
	if not is_instance_valid(game.active_dialogue):
		printerr("FAIL: po zwycięstwie nie uruchomił się osobny dialog fabularny")
		quit(1)
		return
	game.active_dialogue.call("finish_dialogue")
	await process_frame
	game._show_campaign_screen()
	await process_frame
	if game.player_loadout != quick_loadout:
		printerr("FAIL: kampania zmieniła zestaw szybkiej gry")
		quit(1)
		return
	game._begin_campaign_match(0)
	game._show_winner(false)
	if game.campaign_economy.silver != 215:
		printerr("FAIL: porażka zmieniła saldo srebra")
		quit(1)
		return
	await process_frame
	game.active_dialogue.call("finish_dialogue")
	await process_frame
	game._show_campaign_screen()
	game._begin_campaign_match(0)
	game.player_score = game.target_score
	game._show_winner(true)
	if game.campaign_economy.silver != 265 or game.campaign_progress != 1:
		printerr("FAIL: ponowne zwycięstwo nie przyznało mniejszej nagrody")
		quit(1)
		return
	await process_frame
	game.active_dialogue.call("finish_dialogue")
	await process_frame
	game.show_main_menu()
	game.start_game()
	game.player_score = game.target_score
	game._show_winner(true)
	if game.campaign_economy.silver != 265:
		printerr("FAIL: szybki pojedynek przyznał srebro kampanii")
		quit(1)
		return
	game._load_progress()
	if game.campaign_economy.silver != 265 or game.campaign_economy.loadout != [1, 1, 3, 1, 1, 1]:
		printerr("FAIL: wczytanie postępu nie przywróciło ekonomii kampanii")
		quit(1)
		return

	print("PASS: menu, sklep, zakupy, zestaw kampanii, nagrody, AI i trwały postęp")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	quit(0)
