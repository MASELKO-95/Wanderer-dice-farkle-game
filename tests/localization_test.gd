extends SceneTree

const REQUIRED_NEW_KEYS: Array[String] = [
	"setup_lobby", "save_delete", "save_delete_confirm",
	"wager_title", "wager_play", "wager_cancel", "wager_hint", "wager_payout", "wager_won", "wager_lost",
	"menu_campaign", "menu_profile", "menu_quit", "menu_peasant",
	"campaign_shop", "silver_balance", "silver_reward", "shop_hint", "shop_owned",
	"shop_full", "shop_buy", "shop_buy_hint", "shop_no_silver", "shop_equipped",
	"shop_equip", "shop_bought",
	"theme_label", "character_creator", "character_creator_title", "creator_procedural_hint",
	"skin_tone", "tunic_color", "hair_color", "save_character", "bot_profile", "bot_name_label",
	"theme_tavern", "theme_royal", "theme_forest",
	"difficulty_easy", "difficulty_normal", "difficulty_hard", "difficulty_expert",
	"skin_fair", "skin_warm", "skin_olive", "skin_dark",
	"color_brown", "color_moss", "color_wine", "color_navy", "color_gold",
	"hair_brown", "hair_black", "hair_auburn", "hair_gray",
	"bot_rookie_name", "bot_rookie_desc", "bot_gambler_name", "bot_gambler_desc",
	"bot_tactician_name", "bot_tactician_desc", "bot_champion_name", "bot_champion_desc",
	"bot_mirror_name", "bot_mirror_desc",
	"model_woman", "model_innkeeper", "model_king", "model_thief", "model_homeless",
	"model_princess", "model_madman", "model_knight", "model_monk", "model_merchant",
	"model_bard", "model_witch",
	"campaign_btn", "quick_match_btn", "campaign_title", "campaign_lore", "campaign_progress",
	"campaign_goal_princess", "campaign_goal_king", "campaign_goal_emperor",
	"campaign_goal_world_champion", "campaign_complete_story", "campaign_chapter_format",
	"campaign_chapter_victory", "campaign_chapter_defeat", "campaign_milestone_unlocked",
	"continue_campaign", "retry_chapter",
	"dialogue_next", "dialogue_skip", "dialogue_end", "dialogue_narrator",
	"dialogue_challenge", "dialogue_opponent_defeated", "dialogue_opponent_wins",
	"dialogue_final_choice_prompt", "dialogue_choice_princess", "dialogue_choice_emperor",
	"dialogue_choice_champion", "campaign_ending_princess", "campaign_ending_emperor",
	"campaign_ending_world_champion",
	"campaign_opponent_1", "campaign_opponent_2", "campaign_opponent_3", "campaign_opponent_4",
	"campaign_opponent_5", "campaign_opponent_6", "campaign_opponent_7", "campaign_opponent_8",
	"campaign_opponent_9", "campaign_opponent_10", "campaign_opponent_11", "campaign_opponent_12",
	"campaign_story_1", "campaign_story_2", "campaign_story_3", "campaign_story_4",
	"campaign_story_5", "campaign_story_6", "campaign_story_7", "campaign_story_8",
	"campaign_story_9", "campaign_story_10", "campaign_story_11", "campaign_story_12",
	"bot_turn_dynamic", "bot_shaking_dynamic", "bot_rolls_dynamic", "bot_farkle_dynamic",
	"bot_keeps_dynamic", "bot_hot_dice_dynamic", "bot_banks_dynamic", "bot_ends_turn_dynamic",
	"bot_wins_match_dynamic", "match_score_dynamic"
]


func _init() -> void:
	var file := FileAccess.open("res://translation/translations.json", FileAccess.READ)
	if file == null:
		_fail("nie można otworzyć pliku tłumaczeń")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("plik tłumaczeń nie jest poprawnym obiektem JSON")
		return
	var translations: Dictionary = parsed
	for locale: String in translations:
		var strings: Dictionary = translations[locale]
		for key: String in REQUIRED_NEW_KEYS:
			if not strings.has(key) or str(strings[key]).strip_edges().is_empty():
				_fail("język %s nie ma tłumaczenia klucza %s" % [locale, key])
				return
	if not FileAccess.file_exists("res://assets/ui/flag_belarus_historical.svg"):
		_fail("brakuje pliku historycznej flagi białoruskiej")
		return
	print("PASS: modele, kampania i fabuła mają komplet tłumaczeń, a flaga Białorusi jest dostępna")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
