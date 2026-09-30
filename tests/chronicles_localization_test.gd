extends SceneTree

const RULES := preload("res://scripts/campaign_chronicles.gd")
const TEXT := preload("res://scripts/story_text.gd")
const OPENING := preload("res://scripts/campaign_opening.gd")
var polish := RegEx.new()

func _init() -> void:
	polish.compile("[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]")
	call_deferred("run")

func english(value: String) -> void:
	assert(polish.search(value) == null, "Untranslated text: " + value)

func sequence_english(sequence: Resource) -> void:
	english(sequence.title)
	for line in sequence.lines:
		english(line.text)
		english(line.speaker)
		for choice in line.choices:
			english(choice.text)

func run() -> void:
	var i18n := root.get_node("I18n")
	i18n.set_language("pl")
	var source: Dictionary = RULES.data(14)
	i18n.set_language("en")
	var translated: Dictionary = RULES.data(14)
	assert(source.speech != translated.speech)
	for index in range(source.choices.size()):
		assert(source.choices[index].id == translated.choices[index].id)
		assert(source.choices[index].points == translated.choices[index].points)
		assert(source.choices[index].flags == translated.choices[index].flags)
	var state := {}
	RULES.initialize(state,0)
	state.merge({"powod":"lenistwo", "elara":"wygoda", "sojusz_vespera":true, "pomogl_zlodziejowi":true, "przegral_z_cieniem":true, "matka_pogodzona":true, "brudne_rece":true, "magnus_los":"wygnany", "aldryk_los":"oszczedzony", "mercy_3":true, "mercy_14":true, "piesn_cienia":true},true)
	for chapter in RULES.CATALOG.ROUTE + [100,101,102,103,104,105]:
		for section in ["intro","victory","defeat"]:
			sequence_english(RULES.build(chapter,section,state))
	for ending in RULES.ROUTES + ["shadow"]:
		for wagers in [0,2]:
			state.liczba_zakladow = wagers
			sequence_english(RULES.epilogue(ending,state))
	for section in ["prologue","tutorial_victory","tutorial_defeat"]:
		sequence_english(OPENING.build(section))
	assert(RULES.build(14,"intro",state).lines[1].text.contains("laziness"))
	assert(RULES.option(state,14,"intro","pokoj").flags.matka == "pokoj")
	assert(FarkleRules.score_dice([1,5]).label == "1×one, 1×five")
	# Placeholder languages use English for every existing menu key and story.
	for locale in i18n.get_available_languages():
		if locale == "pl":
			continue
		i18n.set_language(locale)
		for key in i18n._translations.en:
			assert(i18n.translate(key) == str(i18n._translations.en[key]), locale + ": " + key)
		assert(RULES.data(14).speech == translated.speech)
	# A receiving peer formats network events in its own language.
	i18n.set_language("pl")
	var host := TableMatch.new()
	host.setup([{"peer_id":1,"nickname":"Alice"},{"peer_id":2,"nickname":"Bob"}],1500,42)
	var saved_event := host.snapshot()
	i18n.set_language("en")
	var client := TableMatch.new()
	assert(client.apply_snapshot(saved_event))
	assert(client.event_text() == "Alice starts. Turn: Alice.")
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._apply_campaign_config(ConfigFile.new())
	game._show_campaign_screen()
	game._continue_campaign()
	var dialogue: Control = game.active_dialogue
	dialogue._select_choice(dialogue._current_lines[0].choices[1])
	dialogue._select_choice(dialogue._current_lines[1].choices[2])
	assert(dialogue._full_text.contains("porridge won't cook itself"))
	var points: Dictionary = game.campaign_story.ending_points.duplicate(true)
	var line: int = dialogue._line_index
	i18n.set_language("pl")
	assert(dialogue._full_text.contains("kasza sama się nie ugotuje"))
	assert(dialogue._line_index == line)
	i18n.set_language("ja")
	assert(dialogue._full_text.contains("porridge won't cook itself"))
	assert(dialogue._line_index == line and game.campaign_story.ending_points == points)
	# Pausing and loading use the same checkpoint, with no repeated choice points.
	var saved: ConfigFile = game._campaign_config()
	game._show_campaign_screen()
	await process_frame
	assert(game.screen_layer.find_child("CampaignContinueButton",true,false) != null)
	assert(game.screen_layer.find_child("SideTable0",true,false) == null)
	game._apply_campaign_config(saved)
	game._continue_campaign()
	assert(game.active_dialogue._line_index == line)
	assert(game.campaign_story.ending_points == points and game.campaign_story.powod == "lenistwo")
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("PASS: complete English story, flags unchanged, all language fallbacks, live language switching, pause/resume and per-peer event language")
	quit()
