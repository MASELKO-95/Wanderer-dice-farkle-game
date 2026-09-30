extends Control

const STORY_TEXT := preload("res://scripts/story_text.gd")

var target_score := 4000
const GOLD := Color("#e3bd62")
const PALE_GOLD := Color("#f4dfaa")
const CREAM := Color("#f1e7cf")
const MUTED := Color("#b8a98e")
const GREEN := Color("#597a43")
const RED := Color("#9d493b")
const DIE_GLYPHS := ["1", "2", "3", "4", "5", "6"]
const INVITE_LINKS := preload("res://scripts/invite_links.gd")
const SAVE_PATH := "user://farkle_progress.cfg"
const TAVERN_WORLD_SCENE := preload("res://scenes/tavern_world.tscn")
const CAMPAIGN_CATALOG := preload("res://scripts/campaign_catalog.gd")
const CAMPAIGN_ECONOMY := preload("res://scripts/campaign_economy.gd")
const CHRONICLES := preload("res://scripts/campaign_chronicles.gd")
const ACHIEVEMENTS := preload("res://scripts/campaign_achievements.gd")
const CAMPAIGN_OPENING := preload("res://scripts/campaign_opening.gd")
const CAMPAIGN_SAVES := preload("res://scripts/campaign_saves.gd")
const WAGER_DIALOGUE := preload("res://scripts/wager_dialogue.gd")
const VISUAL_NOVEL_DIALOGUE_SCENE := preload("res://scenes/visual_novel_dialogue.tscn")
const MEDIEVAL_MUSIC := [
	preload("res://sounds/music/Medival Theme/ebunny-medieval-dance-357912.mp3"),
	preload("res://sounds/music/Medival Theme/kiravale-medieval-music-593694.mp3"),
	preload("res://sounds/music/Medival Theme/tunetank-medieval-happy-music-412790.mp3"),
	preload("res://sounds/music/Medival Theme/vifotofreesounds-playful-medieval-war-486717.mp3")
]
const THEMES := [
	{"id": "tavern", "label_key": "theme_tavern"},
	{"id": "royal", "label_key": "theme_royal"},
	{"id": "forest", "label_key": "theme_forest"}
]
const SKIN_TONES := [
	{"id": "fair", "label_key": "skin_fair"}, {"id": "warm", "label_key": "skin_warm"},
	{"id": "olive", "label_key": "skin_olive"}, {"id": "dark", "label_key": "skin_dark"}
]
const TUNIC_COLORS := [
	{"id": "brown", "label_key": "color_brown"}, {"id": "moss", "label_key": "color_moss"},
	{"id": "wine", "label_key": "color_wine"}, {"id": "navy", "label_key": "color_navy"},
	{"id": "gold", "label_key": "color_gold"}
]
const HAIR_COLORS := [
	{"id": "brown", "label_key": "hair_brown"}, {"id": "black", "label_key": "hair_black"},
	{"id": "auburn", "label_key": "hair_auburn"}, {"id": "gray", "label_key": "hair_gray"}
]

var rng := RandomNumberGenerator.new()
var bot_rng := RandomNumberGenerator.new()
var screen_layer: Control
var tavern_background: TavernBackdrop
var world_container: SubViewportContainer
var world_viewport: SubViewport
var tavern_world: TavernWorld
var network_session: NetworkSession

var player_name := "Henryk"
var player_loadout: Array[int] = [1, 1, 1, 1, 1, 1]
var bot_loadout: Array[int] = [1, 1, 1, 1, 2, 1]
var active_dice_types: Array[int] = []
var current_roll_types: Array[int] = []
var player_score := 0
var bot_score := 0
var turn_score := 0
var remaining_dice := 6
var current_is_player := true
var dice_rolled := false
var current_dice: Array[int] = []
var selected_indices: Array[int] = []
var kept_dice: Array[int] = []
var game_token := 0
var matches_played := 0
var matches_won := 0
var match_recorded := false
var master_volume := 0.85
var music_volume := 0.42
var sfx_volume := 0.90
var audio_muted := false
var player_avatar_id := "procedural"
var bot_avatar_id := "procedural"
var theme_id := "tavern"
var bot_profile_id := "rookie"
var bot_difficulty := "easy"
var bot_name := ""
var player_appearance := {"skin": "fair", "tunic": "brown", "hair": "brown"}
var adaptive_learning := {"bank_count": 0, "bank_total": 0, "continue_count": 0, "continue_total": 0}
var match_learning := {"bank_count": 0, "bank_total": 0, "continue_count": 0, "continue_total": 0}
var bot_hot_dice_cycles := 0
var sound_pack_id := "builtin"
var mods_enabled := true
var campaign_progress := 0
var campaign_economy := CAMPAIGN_ECONOMY.new()
var shop_selected_slot := 0
var campaign_active := false
var campaign_current_index := -1
var quick_match_settings: Dictionary = {}
var campaign_ending := ""
var campaign_slot := 0
var campaign_story: Dictionary = {}
var achievements := ACHIEVEMENTS.new()
var campaign_tutorial := false
var campaign_choices: Array = []
var campaign_checkpoint: Dictionary = {}
var current_menu := "main"
var setup_mode := "profile"
var language_select: OptionButton
var active_dialogue: Control

var multiplayer_table: MultiplayerTable
var lobby_seats_label: Label
var lobby_start_button: Button
var lobby_add_bot_button: Button
var lobby_remove_bot_button: Button
var player_score_label: Label
var bot_score_label: Label
var player_progress: ProgressBar
var bot_progress: ProgressBar
var turn_label: Label
var status_label: Label
var hint_label: Label
var kept_label: Label
var dice_row: HBoxContainer
var history_box: VBoxContainer
var roll_button: Button
var keep_button: Button
var bank_button: Button
var dice_slot_buttons: Array[Button] = []
var dice_detail_label: Label
var progress_label: Label
var network_status_label: Label

var _audio_players: Dictionary = {}
var music_player: AudioStreamPlayer
var _music_queue: Array[int] = []
var _last_music_index := -1
var _belarus_historical_flag: ImageTexture

func _get_belarus_historical_flag() -> Texture2D:
	if _belarus_historical_flag == null:
		var flag_image := Image.create(36, 20, false, Image.FORMAT_RGBA8)
		flag_image.fill(Color("#f8f7ef"))
		flag_image.fill_rect(Rect2i(0, 7, 36, 6), Color("#c92033"))
		_belarus_historical_flag = ImageTexture.create_from_image(flag_image)
	return _belarus_historical_flag

func _play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var gain_db: float = float({
		"dice_roll": 12.0,
		"die_select": 7.0,
		"coin_bank": 5.0,
		"farkle": 5.0,
		"win_fanfare": 7.0,
		"ui_click": 4.0,
		"ui_hover": 5.0
	}.get(sound_name, 0.0))
	if not _audio_players.has(sound_name):
		var stream := AssetLibrary.load_sound(sound_name)
		if stream == null:
			return
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "SFX"
		add_child(player)
		_audio_players[sound_name] = player
	
	var p: AudioStreamPlayer = _audio_players[sound_name]
	p.volume_db = volume_db + gain_db
	if p.playing:
		p.stop()
	p.play()

func _reload_audio_players() -> void:
	for player in _audio_players.values():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_audio_players.clear()

func _start_medieval_music() -> void:
	if MEDIEVAL_MUSIC.is_empty():
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "MedievalMusic"
	music_player.bus = "Music"
	music_player.finished.connect(_play_next_music_track)
	add_child(music_player)
	_play_next_music_track()

func _play_next_music_track() -> void:
	if not is_instance_valid(music_player) or MEDIEVAL_MUSIC.is_empty():
		return
	if _music_queue.is_empty():
		for index in range(MEDIEVAL_MUSIC.size()):
			_music_queue.append(index)
		_shuffle_music_queue()
		if _music_queue.size() > 1 and _music_queue[0] == _last_music_index:
			var first: int = _music_queue.pop_front()
			_music_queue.append(first)
	var next_index: int = _music_queue.pop_front()
	_last_music_index = next_index
	music_player.stream = MEDIEVAL_MUSIC[next_index]
	music_player.play()

func _shuffle_music_queue() -> void:
	for index in range(_music_queue.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := _music_queue[index]
		_music_queue[index] = _music_queue[swap_index]
		_music_queue[swap_index] = value

func _ready() -> void:
	rng.randomize()
	bot_rng.randomize()
	_ensure_audio_buses()
	AssetLibrary.refresh_mod_catalog()
	_load_progress()
	CHRONICLES.initialize(campaign_story, campaign_progress)
	achievements.read_save()
	if bot_name.is_empty():
		bot_name = I18n.translate(str(BotBrain.profile(bot_profile_id).name_key))
	_apply_audio_settings()
	_start_medieval_music()
	
	network_session = NetworkSession.new()
	network_session.name = "NetworkSession"
	add_child(network_session)
	network_session.status_changed.connect(_on_network_status_changed)
	network_session.opponent_connected.connect(_on_network_opponent_connected)
	network_session.lobby_changed.connect(_on_network_lobby_changed)
	network_session.match_started.connect(_on_network_match_started)
	network_session.session_ended.connect(_on_network_session_ended)
	
	tavern_background = TavernBackdrop.new()
	tavern_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tavern_background)
	
	_build_3d_view()
	tavern_background.set_theme_id(theme_id)
	tavern_world.configure_theme(theme_id)
	
	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_layer)
	
	show_main_menu()
	_build_language_selector()
	developer_console = preload("res://scripts/developer_console.gd").new()
	developer_console.game = self
	add_child(developer_console)
	var invitation := INVITE_LINKS.startup_invitation(OS.get_cmdline_user_args())
	if not invitation.is_empty():
		_join_invitation.call_deferred(invitation)

var developer_console: CanvasLayer
var keyboard_die := 0


func _input(event: InputEvent) -> void:
	if is_instance_valid(developer_console) and developer_console.handle_key(event):
		return
	if current_menu != "game" or is_instance_valid(active_dialogue) or not current_is_player or not dice_rolled:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed:
		return
	var count := current_dice.size()
	if count == 0:
		return
	keyboard_die = clampi(keyboard_die, 0, count - 1)
	if event.keycode in [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]:
		keyboard_die = posmod(keyboard_die + (-1 if event.keycode in [KEY_LEFT, KEY_UP] else 1), count)
	elif event.keycode in [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_on_die_pressed(keyboard_die)
	else:
		return
	for child in dice_row.get_children():
		if child is DieView and not child.is_queued_for_deletion():
			child.keyboard_cursor = child.die_index == keyboard_die
			child.queue_redraw()
	get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(developer_console) and developer_console.is_open():
		return
	if is_instance_valid(active_dialogue):
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.is_pressed() or key_event.is_echo():
		return
	
	if key_event.keycode == KEY_SPACE and is_instance_valid(roll_button) and roll_button.visible and not roll_button.disabled:
		_player_roll()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_E and current_is_player and dice_rolled:
		_toggle_hovered_solo_die()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_F and is_instance_valid(keep_button) and keep_button.visible and not keep_button.disabled:
		_on_keep_and_roll()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_Q] and is_instance_valid(bank_button) and not bank_button.disabled:
		_on_bank_pressed()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if world_container.visible and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		tavern_world.nudge_look(event.relative)
		get_viewport().set_input_as_handled()

func _build_3d_view() -> void:
	world_container = SubViewportContainer.new()
	world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_container.stretch = true
	world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_container.visible = false
	add_child(world_container)
	
	world_viewport = SubViewport.new()
	world_viewport.own_world_3d = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.msaa_3d = Viewport.MSAA_4X
	world_container.add_child(world_viewport)
	
	tavern_world = TAVERN_WORLD_SCENE.instantiate() as TavernWorld
	world_viewport.add_child(tavern_world)

func show_main_menu() -> void:
	campaign_tutorial = false
	current_menu = "main"
	_prepare_menu_screen()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "MainMenuPanel"
	panel.custom_minimum_size = Vector2(410, 580)
	var frame := _panel_style(Color("#151714fa"), Color("#737267"), 3, 3)
	frame.shadow_color = Color(0, 0, 0, 0.65)
	frame.shadow_size = 12
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)
	var title := _label(I18n.translate("game_title"), 27, Color("#dfd6bc"), HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	column.add_child(_label(I18n.translate("menu_peasant"), 13, Color("#a4a596"), HORIZONTAL_ALIGNMENT_CENTER))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	column.add_child(spacer)
	var entries := [
		["quick_match_btn", _show_setup_menu.bind("quick")],
		["multiplayer_btn", _show_setup_menu.bind("multiplayer")],
		["menu_campaign", _show_campaign_saves],
		["menu_profile", _show_setup_menu],
		["achievements", _show_achievements],
		["sound_settings", _show_audio_settings],
		["rules_btn", _show_rules]
	]
	for entry: Array in entries:
		var button := _main_menu_button(I18n.translate(str(entry[0])).to_upper())
		button.name = str(entry[0])
		button.pressed.connect(entry[1])
		column.add_child(button)
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_space.custom_minimum_size.y = 24
	column.add_child(bottom_space)
	var leave := _main_menu_button(I18n.translate("menu_quit"))
	leave.pressed.connect(func() -> void:
		_save_progress()
		get_tree().quit()
	)
	column.add_child(leave)
	column.add_child(_label(I18n.translate("matches_stats", [matches_played, matches_won]), 12, Color("#96998c"), HORIZONTAL_ALIGNMENT_CENTER))
	var github := LinkButton.new()
	github.name = "GitHubLink"
	github.text = "GitHub • MASELKO-95"
	github.uri = "https://github.com/MASELKO-95"
	github.tooltip_text = github.uri
	github.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	github.add_theme_font_size_override("font_size", 14)
	column.add_child(github)

func _main_menu_button(text: String) -> Button:
	var button := _button(text, Color("#30372e"))
	button.custom_minimum_size.y = 43
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#e0e1d5"))
	button.add_theme_color_override("font_hover_color", Color("#fff0c1"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("#30372e"), Color("#4f5648"), 1, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#454e3b"), Color("#a99868"), 1, 1))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#20261f"), Color("#a99868"), 1, 1))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0, 0, 0, 0), GOLD, 2, 1))
	return button

func _prepare_menu_screen() -> void:
	game_token += 1
	active_dialogue = null
	_restore_quick_match_settings()
	campaign_active = false
	campaign_current_index = -1
	if is_instance_valid(multiplayer_table):
		multiplayer_table.queue_free()
		multiplayer_table = null
	if is_instance_valid(network_session) and network_session.is_connected_session():
		network_session.disconnect_session()
	
	tavern_background.visible = true
	world_container.visible = false
	tavern_world.clear_dice()
	_clear_screen()
	
	roll_button = null
	bank_button = null
	dice_slot_buttons.clear()

func _show_setup_menu(mode: String = "profile") -> void:
	setup_mode = mode
	current_menu = "setup"
	_prepare_menu_screen()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	screen_layer.add_child(margin)
	
	var center := CenterContainer.new()
	margin.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 660)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#241711e8"), Color("#8d6939"), 3, 18))
	center.add_child(panel)
	
	var frame := VBoxContainer.new()
	panel.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	frame.add_child(scroll)
	
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 700
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	content.add_theme_constant_override("margin_left", 0)
	scroll.add_child(content)
	
	var title_key := "quick_match_btn" if mode == "quick" else "multiplayer_btn" if mode == "multiplayer" else "menu_profile"
	var title := _label(I18n.translate(title_key), 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color("#160b06"))
	content.add_child(title)
	if mode == "multiplayer":
		var host_hint := _label(I18n.translate("setup_multiplayer_hint"), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		host_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(host_hint)
	var back := _button(I18n.translate("back_to_menu"), Color("#4b4238"), 240)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_main_menu)
	content.add_child(back)
	
	content.add_child(_label(I18n.translate("game_subtitle"), 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	
	progress_label = _label(I18n.translate("matches_stats", [matches_played, matches_won]), 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(progress_label)
	content.add_child(_separator())
	
	var settings_row := HBoxContainer.new()
	settings_row.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_row.add_theme_constant_override("separation", 24)
	content.add_child(settings_row)

	settings_row.add_child(_label(I18n.translate("language_label"), 15, PALE_GOLD))
	var lang_select := OptionButton.new()
	lang_select.custom_minimum_size = Vector2(240, 40)
	var langs := I18n.get_available_languages()
	for i in range(langs.size()):
		lang_select.add_item(I18n.get_language_name(langs[i]), i)
		lang_select.set_item_metadata(i, langs[i])
		if langs[i] == "be":
			lang_select.set_item_icon(i, _get_belarus_historical_flag())
		if langs[i] == I18n.current_locale:
			lang_select.select(i)

	lang_select.item_selected.connect(func(idx: int) -> void:
		var selected_profile: Dictionary = BotBrain.profile(bot_profile_id)
		var used_default_name: bool = bot_name == I18n.translate(str(selected_profile.name_key))
		I18n.set_language(lang_select.get_item_metadata(idx))
		if used_default_name:
			bot_name = I18n.translate(str(selected_profile.name_key))
	)
	settings_row.add_child(lang_select)
	settings_row.visible = mode == "profile"

	var separator_v := VSeparator.new()
	separator_v.custom_minimum_size.x = 2
	settings_row.add_child(separator_v)

	var mods_check := CheckButton.new()
	mods_check.text = I18n.translate("mods_toggle")
	mods_check.button_pressed = mods_enabled
	mods_check.add_theme_font_size_override("font_size", 15)
	mods_check.add_theme_color_override("font_color", CREAM)
	mods_check.toggled.connect(func(enabled: bool) -> void:
		mods_enabled = enabled
		AssetLibrary.set_mods_enabled(enabled)
		_save_progress()
		_show_setup_menu(setup_mode)
	)
	settings_row.add_child(mods_check)
	
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 14)
	content.add_child(name_row)
	name_row.add_child(_label(I18n.translate("your_nick"), 15, PALE_GOLD))
	
	var name_edit := LineEdit.new()
	name_edit.text = player_name
	name_edit.placeholder_text = I18n.translate("nick_placeholder")
	name_edit.max_length = 18
	name_edit.custom_minimum_size = Vector2(330, 44)
	name_edit.add_theme_font_size_override("font_size", 18)
	name_edit.add_theme_color_override("font_color", CREAM)
	name_edit.add_theme_stylebox_override("normal", _panel_style(Color("#120c09"), Color("#765a38"), 2, 8))
	name_row.add_child(name_edit)
	name_edit.text_changed.connect(func(value: String) -> void:
		player_name = value.strip_edges().left(18)
		if player_name.is_empty():
			player_name = I18n.translate("default_name")
		_save_progress()
	)
	
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 14)
	content.add_child(score_row)
	score_row.add_child(_label(I18n.translate("target_score"), 15, PALE_GOLD))
	
	var score_spin := SpinBox.new()
	score_spin.min_value = 1000
	score_spin.max_value = 10000
	score_spin.step = 500
	score_spin.value = target_score
	score_spin.name = "SetupTargetScore"
	score_spin.custom_minimum_size = Vector2(120, 44)
	score_spin.add_theme_font_size_override("font_size", 18)
	score_spin.add_theme_color_override("font_color", CREAM)
	score_spin.add_theme_stylebox_override("normal", _panel_style(Color("#120c09"), Color("#765a38"), 2, 8))
	score_row.add_child(score_spin)
	score_spin.value_changed.connect(func(value: float) -> void: target_score = int(value))

	var theme_row := HBoxContainer.new()
	theme_row.alignment = BoxContainer.ALIGNMENT_CENTER
	theme_row.add_theme_constant_override("separation", 14)
	content.add_child(theme_row)
	theme_row.add_child(_label(I18n.translate("theme_label"), 15, PALE_GOLD))
	var theme_select := OptionButton.new()
	theme_select.custom_minimum_size = Vector2(330, 40)
	for index in range(THEMES.size()):
		var theme: Dictionary = THEMES[index]
		theme_select.add_item(I18n.translate(str(theme.label_key)), index)
		theme_select.set_item_metadata(index, str(theme.id))
		if str(theme.id) == theme_id:
			theme_select.select(index)
	theme_select.item_selected.connect(func(index: int) -> void:
		theme_id = str(theme_select.get_item_metadata(index))
		tavern_background.set_theme_id(theme_id)
		tavern_world.configure_theme(theme_id)
		_save_progress()
	)
	theme_row.add_child(theme_select)
	
	var model_row := HBoxContainer.new()
	model_row.alignment = BoxContainer.ALIGNMENT_CENTER
	model_row.add_theme_constant_override("separation", 10)
	content.add_child(model_row)
	model_row.add_child(_label(I18n.translate("player_model"), 15, PALE_GOLD))
	
	var model_select := OptionButton.new()
	model_select.custom_minimum_size = Vector2(300, 40)
	model_row.add_child(model_select)
	
	var refresh_mods := _button(I18n.translate("refresh_mods"), Color("#4b4238"), 145)
	model_row.add_child(refresh_mods)
	var creator := _button(I18n.translate("character_creator"), Color("#5b4533"), 150)
	creator.tooltip_text = I18n.translate("creator_procedural_hint")
	creator.pressed.connect(_show_character_creator)
	model_row.add_child(creator)
	
	var mod_catalog := AssetLibrary.refresh_mod_catalog()
	player_avatar_id = _populate_option_button(model_select, mod_catalog.models, player_avatar_id)
	
	var bot_row := HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 10)
	content.add_child(bot_row)
	bot_row.add_child(_label(I18n.translate("bot_profile"), 15, PALE_GOLD))
	var bot_profile_select := OptionButton.new()
	bot_profile_select.custom_minimum_size = Vector2(310, 40)
	for index in range(BotBrain.PROFILES.size()):
		var profile: Dictionary = BotBrain.PROFILES[index]
		bot_profile_select.add_item(I18n.translate(str(profile.name_key)), index)
		bot_profile_select.set_item_metadata(index, str(profile.id))
		if str(profile.id) == bot_profile_id:
			bot_profile_select.select(index)
	bot_row.add_child(bot_profile_select)
	bot_profile_select.name = "SetupBotProfile"
	bot_row.visible = mode != "multiplayer"

	var difficulty_select := OptionButton.new()
	difficulty_select.custom_minimum_size = Vector2(150, 40)
	var difficulty_labels := ["difficulty_easy", "difficulty_normal", "difficulty_hard", "difficulty_expert"]
	for index in range(BotBrain.DIFFICULTIES.size()):
		difficulty_select.add_item(I18n.translate(difficulty_labels[index]), index)
		difficulty_select.set_item_metadata(index, BotBrain.DIFFICULTIES[index])
		if BotBrain.DIFFICULTIES[index] == bot_difficulty:
			difficulty_select.select(index)
	bot_row.add_child(difficulty_select)
	difficulty_select.name = "SetupDifficulty"

	var bot_name_row := HBoxContainer.new()
	bot_name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_name_row.add_theme_constant_override("separation", 14)
	content.add_child(bot_name_row)
	bot_name_row.visible = mode != "multiplayer"
	bot_name_row.add_child(_label(I18n.translate("bot_name_label"), 15, PALE_GOLD))
	var bot_name_edit := LineEdit.new()
	bot_name_edit.text = bot_name
	bot_name_edit.max_length = 28
	bot_name_edit.custom_minimum_size = Vector2(330, 40)
	bot_name_edit.add_theme_color_override("font_color", CREAM)
	bot_name_edit.add_theme_stylebox_override("normal", _panel_style(Color("#120c09"), Color("#765a38"), 2, 8))
	bot_name_row.add_child(bot_name_edit)
	bot_name_edit.text_changed.connect(func(value: String) -> void:
		bot_name = value.strip_edges().left(28)
		if bot_name.is_empty():
			bot_name = I18n.translate(str(BotBrain.profile(bot_profile_id).name_key))
		_save_progress()
	)
	var bot_description := _label(I18n.translate(str(BotBrain.profile(bot_profile_id).description_key)), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	bot_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(bot_description)
	bot_description.visible = mode != "multiplayer"
	
	var mod_status := _label(_mod_catalog_status(mod_catalog), 12, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	mod_status.tooltip_text = "\n".join(mod_catalog.warnings)
	content.add_child(mod_status)
	
	model_select.item_selected.connect(func(index: int) -> void:
		player_avatar_id = str(model_select.get_item_metadata(index))
		_save_progress()
	)
	
	bot_profile_select.item_selected.connect(func(index: int) -> void:
		bot_profile_id = str(bot_profile_select.get_item_metadata(index))
		var profile := BotBrain.profile(bot_profile_id)
		bot_name = I18n.translate(str(profile.name_key))
		bot_difficulty = str(profile.difficulty)
		bot_name_edit.text = bot_name
		bot_description.text = I18n.translate(str(profile.description_key))
		for difficulty_index in range(BotBrain.DIFFICULTIES.size()):
			if BotBrain.DIFFICULTIES[difficulty_index] == bot_difficulty:
				difficulty_select.select(difficulty_index)
				break
		_save_progress()
	)

	difficulty_select.item_selected.connect(func(index: int) -> void:
		bot_difficulty = str(difficulty_select.get_item_metadata(index))
		_save_progress()
	)
	
	refresh_mods.pressed.connect(func() -> void:
		var refreshed_catalog := AssetLibrary.refresh_mod_catalog()
		player_avatar_id = _populate_option_button(model_select, refreshed_catalog.models, player_avatar_id)
		mod_status.text = _mod_catalog_status(refreshed_catalog)
		mod_status.tooltip_text = "\n".join(refreshed_catalog.warnings)
	)
	
	content.add_child(_label(I18n.translate("choose_6_dice"), 15, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 7)
	content.add_child(choices)
	
	for slot_index in range(6):
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(96, 92)
		choice.add_theme_font_size_override("font_size", 13)
		choice.pressed.connect(_on_dice_slot_pressed.bind(slot_index))
		choices.add_child(choice)
		dice_slot_buttons.append(choice)
	
	dice_detail_label = _label("", 13, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	dice_detail_label.custom_minimum_size.y = 24
	content.add_child(dice_detail_label)
	_refresh_dice_slots(0)
	
	var collection := Button.new()
	collection.text = I18n.translate("dice_collection_btn", [_unlocked_dice_count(), DiceCatalog.TYPES.size()])
	collection.flat = true
	collection.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	collection.add_theme_font_size_override("font_size", 13)
	collection.add_theme_color_override("font_color", GOLD)
	collection.pressed.connect(_show_dice_collection)
	content.add_child(collection)
	
	var info := _label(I18n.translate("dice_slot_hint"), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info)
	content.add_child(_separator())
	
	var campaign := _button(I18n.translate("campaign_btn"), Color("#8a6128"), 360)
	campaign.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	campaign.tooltip_text = I18n.translate("campaign_lore")
	campaign.pressed.connect(func() -> void:
		var entered_name := name_edit.text.strip_edges()
		player_name = entered_name.left(18) if not entered_name.is_empty() else I18n.translate("default_name")
		_save_progress()
		_show_campaign_screen()
	)
	content.add_child(campaign)
	campaign.visible = mode == "profile"

	var start := _button(I18n.translate("start_game"), GREEN, 300)
	start.name = "SetupStartQuick"
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func() -> void:
		campaign_active = false
		var entered_name := name_edit.text.strip_edges()
		player_name = entered_name.left(18) if not entered_name.is_empty() else I18n.translate("default_name")
		var entered_bot_name := bot_name_edit.text.strip_edges()
		bot_name = entered_bot_name.left(28) if not entered_bot_name.is_empty() else I18n.translate(str(BotBrain.profile(bot_profile_id).name_key))
		target_score = int(score_spin.value)
		_save_progress()
		start_game()
	)
	if mode == "quick":
		frame.add_child(start)
	else:
		content.add_child(start)
	start.visible = mode != "multiplayer"
	
	var multiplayer_btn := _button(I18n.translate("setup_lobby"), GREEN, 360)
	multiplayer_btn.name = "SetupOpenLobby"
	multiplayer_btn.tooltip_text = I18n.translate("multiplayer_tooltip")
	multiplayer_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	multiplayer_btn.pressed.connect(func() -> void:
		var entered_name := name_edit.text.strip_edges()
		player_name = entered_name.left(18) if not entered_name.is_empty() else I18n.translate("default_name")
		target_score = int(score_spin.value)
		_save_progress()
		_show_multiplayer_lobby()
	)
	if mode == "multiplayer":
		frame.add_child(multiplayer_btn)
	else:
		content.add_child(multiplayer_btn)
	multiplayer_btn.visible = mode != "quick"
	
	var settings := Button.new()
	settings.text = I18n.translate("sound_settings")
	settings.flat = true
	settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings.add_theme_font_size_override("font_size", 14)
	settings.add_theme_color_override("font_color", PALE_GOLD)
	settings.pressed.connect(_show_audio_settings)
	content.add_child(settings)
	
	var rules := Button.new()
	rules.text = I18n.translate("rules_btn")
	rules.flat = true
	rules.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rules.add_theme_font_size_override("font_size", 14)
	rules.add_theme_color_override("font_color", PALE_GOLD)
	rules.pressed.connect(_show_rules)
	content.add_child(rules)

func start_game() -> void:
	current_menu = "game"
	game_token += 1
	match_recorded = false
	match_learning = {"bank_count": 0, "bank_total": 0, "continue_count": 0, "continue_total": 0}
	tavern_background.visible = false
	world_container.visible = true
	player_score = 0
	bot_score = 0
	var profile := BotBrain.profile(bot_profile_id)
	var clone_player := bool(profile.get("clone_player", false))
	bot_loadout.assign(player_loadout if clone_player else profile.get("loadout", [1, 1, 1, 1, 1, 1]))
	if campaign_active:
		var campaign_chapter: Dictionary = CAMPAIGN_CATALOG.chapter(campaign_current_index)
		bot_avatar_id = "builtin:monk" if campaign_tutorial else str(campaign_chapter.get("avatar", "procedural"))
	else:
		bot_avatar_id = player_avatar_id if clone_player else "procedural"
	var bot_appearance: Dictionary = player_appearance.duplicate(true) if clone_player else (profile.get("appearance", {}) as Dictionary).duplicate(true)
	tavern_world.configure_theme(theme_id)
	
	tavern_world.configure_table_seats([
		{"peer_id": 1, "nickname": player_name, "is_bot": false, "avatar_id": player_avatar_id},
		{"peer_id": -1, "nickname": bot_name, "is_bot": true, "avatar_id": bot_avatar_id}
	], 1)
	tavern_world.configure_solo_appearance(player_appearance, bot_appearance)
	
	_build_game_screen()
	_add_history(I18n.translate("first_to_wins", [target_score]), GOLD)
	_begin_player_turn()

func _build_game_screen() -> void:
	_clear_screen()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_top", 22)
	outer.add_theme_constant_override("margin_bottom", 20)
	screen_layer.add_child(outer)
	
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	outer.add_child(layout)
	
	var hud := HBoxContainer.new()
	hud.custom_minimum_size.y = 116
	hud.add_theme_constant_override("separation", 14)
	layout.add_child(hud)
	
	var player_card := _make_player_card(true)
	hud.add_child(player_card)
	
	var centre_card := PanelContainer.new()
	centre_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre_card.add_theme_stylebox_override("panel", _panel_style(Color("#1b110c35"), Color("#6c512f70"), 1, 12))
	var centre_v := VBoxContainer.new()
	centre_v.alignment = BoxContainer.ALIGNMENT_CENTER
	centre_card.add_child(centre_v)
	
	centre_v.add_child(_label(I18n.translate("match_target"), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	centre_v.add_child(_label(I18n.translate("points_target", [target_score]), 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	centre_v.add_child(_label(I18n.translate("controls_hint"), 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	
	var menu_button := Button.new()
	menu_button.text = I18n.translate("back_to_menu")
	menu_button.flat = true
	menu_button.add_theme_color_override("font_color", MUTED)
	menu_button.pressed.connect(show_main_menu)
	centre_v.add_child(menu_button)
	
	hud.add_child(centre_card)
	hud.add_child(_make_player_card(false))
	
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)
	
	var play_panel := PanelContainer.new()
	play_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_panel.add_theme_stylebox_override("panel", _panel_style(Color("#160d0838"), Color("#86633aaa"), 1, 15))
	body.add_child(play_panel)
	
	var play := VBoxContainer.new()
	play.add_theme_constant_override("separation", 8)
	play_panel.add_child(play)
	
	status_label = _label(I18n.translate("your_turn"), 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	play.add_child(status_label)
	
	turn_label = _label(I18n.translate("turn_points_zero"), 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	play.add_child(turn_label)
	
	var dice_center := CenterContainer.new()
	dice_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_center.custom_minimum_size.y = 150
	play.add_child(dice_center)
	
	dice_row = HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 10)
	dice_center.add_child(dice_row)
	
	hint_label = _label(I18n.translate("press_roll"), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.custom_minimum_size.y = 26
	play.add_child(hint_label)
	
	kept_label = _label(I18n.translate("kept_none"), 15, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	kept_label.custom_minimum_size.y = 28
	play.add_child(kept_label)
	
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	play.add_child(actions)
	
	roll_button = _button(I18n.translate("roll_btn"), Color("#6f5430"), 190)
	roll_button.pressed.connect(_player_roll)
	actions.add_child(roll_button)
	
	keep_button = _button(I18n.translate("keep_roll_btn"), Color("#6f5430"), 210)
	keep_button.pressed.connect(_on_keep_and_roll)
	keep_button.visible = false
	actions.add_child(keep_button)
	
	bank_button = _button(I18n.translate("bank_btn"), GREEN, 170)
	bank_button.pressed.connect(_on_bank_pressed)
	bank_button.disabled = true
	actions.add_child(bank_button)
	
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size.x = 260
	log_panel.add_theme_stylebox_override("panel", _panel_style(Color("#17100cd9"), Color("#5f4930"), 2, 12))
	body.add_child(log_panel)
	
	var log_v := VBoxContainer.new()
	log_v.add_theme_constant_override("separation", 7)
	log_panel.add_child(log_v)
	log_v.add_child(_label(I18n.translate("game_log"), 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	log_v.add_child(_separator())
	
	history_box = VBoxContainer.new()
	history_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation", 8)
	log_v.add_child(history_box)

func _make_player_card(is_player: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 112)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#21150ee6"), GOLD if is_player else Color("#765a38"), 3 if is_player else 2, 12))
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	
	var crest := Label.new()
	crest.text = "♞" if is_player else "♜"
	crest.custom_minimum_size.x = 54
	crest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest.add_theme_font_size_override("font_size", 38)
	crest.add_theme_color_override("font_color", GOLD if is_player else MUTED)
	row.add_child(crest)
	
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(details)
	
	details.add_child(_label(player_name if is_player else bot_name, 20, CREAM))
	
	var score := _label(STORY_TEXT.text("0 pkt"), 24, GOLD if is_player else PALE_GOLD)
	details.add_child(score)
	
	var progress := ProgressBar.new()
	progress.max_value = target_score
	progress.value = 0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(190, 9)
	progress.add_theme_stylebox_override("background", _panel_style(Color("#100b08"), Color("#443421"), 1, 4))
	progress.add_theme_stylebox_override("fill", _panel_style(GOLD if is_player else Color("#9f8053"), Color.TRANSPARENT, 0, 4))
	details.add_child(progress)
	
	if is_player:
		player_score_label = score
		player_progress = progress
	else:
		bot_score_label = score
		bot_progress = progress
	
	return card

func _begin_player_turn() -> void:
	current_is_player = true
	turn_score = 0
	remaining_dice = 6
	dice_rolled = false
	current_dice.clear()
	selected_indices.clear()
	kept_dice.clear()
	active_dice_types = player_loadout.duplicate()
	current_roll_types.clear()
	tavern_world.clear_dice()
	_clear_dice_row()
	
	status_label.text = I18n.translate("your_turn")
	status_label.add_theme_color_override("font_color", GOLD)
	hint_label.text = I18n.translate("press_roll")
	hint_label.add_theme_color_override("font_color", MUTED)
	
	roll_button.visible = true
	roll_button.disabled = false
	keep_button.visible = false
	bank_button.disabled = true
	_update_game_ui()

func _player_roll() -> void:
	if not current_is_player or dice_rolled:
		return
	_play_sfx("dice_roll")
	dice_rolled = true
	roll_button.disabled = true
	current_roll_types = active_dice_types.duplicate()
	current_dice = _roll_values(current_roll_types)
	selected_indices.clear()
	
	hint_label.text = I18n.translate("rolling")
	var token := game_token
	await tavern_world.throw_dice(current_dice, current_roll_types)
	if token != game_token or not current_is_player:
		return
	
	_render_dice(false)
	roll_button.visible = false
	keep_button.visible = true
	_add_history(I18n.translate("player_rolls", [player_name, _dice_text(current_dice)]), CREAM)
	
	if not FarkleRules.best_scoring_subset(current_dice).valid:
		_resolve_player_farkle()
	else:
		hint_label.text = I18n.translate("click_to_keep")
		_update_selection_ui()

func _resolve_player_farkle() -> void:
	var token := game_token
	_play_sfx("farkle")
	keep_button.disabled = true
	bank_button.disabled = true
	hint_label.text = I18n.translate("farkle_msg")
	hint_label.add_theme_color_override("font_color", Color("#e47b61"))
	_add_history(I18n.translate("farkle_player_loses", [player_name, turn_score]), RED)
	
	await get_tree().create_timer(1.5).timeout
	if token == game_token:
		_begin_bot_turn()

func _on_die_pressed(index: int) -> void:
	if not current_is_player or not dice_rolled:
		return
	_play_sfx("die_select")
	if index in selected_indices:
		selected_indices.erase(index)
	else:
		selected_indices.append(index)
		selected_indices.sort()
	
	for child in dice_row.get_children():
		if child is DieView:
			child.set_selected(child.die_index in selected_indices)
	tavern_world.set_dice_selected(selected_indices)
	_update_selection_ui()

func _toggle_hovered_solo_die() -> void:
	if not is_instance_valid(dice_row):
		return
	var table_index := tavern_world.die_at_screen_position(get_viewport().get_mouse_position(), get_viewport_rect().size)
	if table_index >= 0 and table_index < current_dice.size():
		_on_die_pressed(table_index)
		return
	
	var fallback := -1
	for child in dice_row.get_children():
		if child is DieView and not child.locked:
			if fallback < 0:
				fallback = child.die_index
			if child.hovered:
				_on_die_pressed(child.die_index)
				return
	if fallback >= 0:
		_on_die_pressed(fallback)

func _update_selection_ui() -> void:
	var result := FarkleRules.score_dice(_selected_values())
	var valid: bool = result.valid
	keep_button.disabled = not valid
	bank_button.disabled = not valid
	
	if selected_indices.is_empty():
		hint_label.text = I18n.translate("select_at_least_one")
		hint_label.add_theme_color_override("font_color", MUTED)
	elif valid:
		hint_label.text = I18n.translate("points_and_label", [result.score, result.label])
		hint_label.add_theme_color_override("font_color", Color("#acd58c"))
	else:
		hint_label.text = I18n.translate("invalid_selection")
		hint_label.add_theme_color_override("font_color", Color("#e47b61"))

func _on_keep_and_roll() -> void:
	if not current_is_player:
		return
	var values := _selected_values()
	var result := FarkleRules.score_dice(values)
	if not result.valid:
		return
	
	turn_score += result.score
	_record_player_decision(false, turn_score)
	kept_dice.append_array(values)
	var next_types: Array[int] = []
	for index in range(current_roll_types.size()):
		if index not in selected_indices:
			next_types.append(current_roll_types[index])
	
	active_dice_types = next_types
	remaining_dice = active_dice_types.size()
	_add_history(I18n.translate("kept_dice_points", [_dice_text(values), result.score]), Color("#b6d99c"))
	
	var hot_dice := remaining_dice == 0
	if hot_dice:
		remaining_dice = 6
		active_dice_types = player_loadout.duplicate()
		kept_dice.clear()
		_add_history(I18n.translate("hot_dice"), GOLD)
	
	current_dice.clear()
	selected_indices.clear()
	tavern_world.clear_dice()
	dice_rolled = false
	_update_game_ui()
	
	kept_label.text = I18n.translate("kept_hot_dice") if hot_dice else I18n.translate("kept_dice_list", [_dice_text(kept_dice)])
	hint_label.text = I18n.translate("rolling_remaining")
	keep_button.disabled = true
	bank_button.disabled = true
	
	var token := game_token
	await get_tree().create_timer(0.45).timeout
	if token == game_token and current_is_player:
		_player_roll()

func _on_bank_pressed() -> void:
	if not current_is_player:
		return
	var values := _selected_values()
	var result := FarkleRules.score_dice(values)
	if not result.valid:
		return
	
	_play_sfx("coin_bank")
	turn_score += result.score
	_record_player_decision(true, turn_score)
	player_score += turn_score
	_add_history(I18n.translate("player_banks", [player_name, turn_score]), GOLD)
	_update_game_ui()
	
	if player_score >= target_score:
		_show_winner(true)
		return
	
	current_is_player = false
	keep_button.disabled = true
	bank_button.disabled = true
	hint_label.text = I18n.translate("points_banked_opponent_turn")
	
	var token := game_token
	await get_tree().create_timer(1.0).timeout
	if token == game_token:
		_begin_bot_turn()

func _begin_bot_turn() -> void:
	current_is_player = false
	turn_score = 0
	bot_hot_dice_cycles = 0
	remaining_dice = 6
	dice_rolled = false
	current_dice.clear()
	selected_indices.clear()
	kept_dice.clear()
	active_dice_types = bot_loadout.duplicate()
	current_roll_types.clear()
	tavern_world.clear_dice()
	
	status_label.text = I18n.translate("bot_turn_dynamic", [bot_name])
	status_label.add_theme_color_override("font_color", PALE_GOLD)
	roll_button.visible = false
	keep_button.visible = true
	keep_button.disabled = true
	bank_button.disabled = true
	kept_label.text = I18n.translate("kept_none")
	_update_game_ui()
	
	_run_bot_turn(game_token)

func _run_bot_turn(token: int) -> void:
	while token == game_token and not current_is_player:
		hint_label.text = I18n.translate("bot_shaking_dynamic", [bot_name])
		_clear_dice_row()
		await get_tree().create_timer(0.75).timeout
		if token != game_token:
			return
		
		_play_sfx("dice_roll")
		current_roll_types = active_dice_types.duplicate()
		current_dice = _roll_values(current_roll_types)
		selected_indices.clear()
		await tavern_world.throw_dice(current_dice, current_roll_types, true)
		if token != game_token:
			return
		
		_render_dice(true)
		_add_history(I18n.translate("bot_rolls_dynamic", [bot_name, _dice_text(current_dice)]), CREAM)
		
		var best := BotBrain.choose_selection(current_dice, bot_difficulty, bot_rng, turn_score, current_roll_types)
		if not best.valid:
			_play_sfx("farkle")
			hint_label.text = I18n.translate("bot_farkle_dynamic", [bot_name, turn_score])
			hint_label.add_theme_color_override("font_color", Color("#e47b61"))
			_add_history(I18n.translate("bot_farkle_dynamic", [bot_name, turn_score]), RED)
			await get_tree().create_timer(1.35).timeout
			if token == game_token:
				_begin_player_turn()
			return
		
		await get_tree().create_timer(0.65).timeout
		if token != game_token:
			return
		
		selected_indices.clear()
		for picked_index: int in best.indices:
			selected_indices.append(picked_index)
		for child in dice_row.get_children():
			if child is DieView:
				child.set_selected(child.die_index in selected_indices)
		tavern_world.set_dice_selected(selected_indices)
		_play_sfx("die_select")
		
		hint_label.text = I18n.translate("bot_keeps_dynamic", [bot_name, _dice_text(best.values), best.score])
		hint_label.add_theme_color_override("font_color", Color("#acd58c"))
		await get_tree().create_timer(0.75).timeout
		if token != game_token:
			return
		
		turn_score += best.score
		kept_dice.append_array(best.values)
		var next_types: Array[int] = []
		for index in range(current_roll_types.size()):
			if index not in selected_indices:
				next_types.append(current_roll_types[index])
		
		active_dice_types = next_types
		remaining_dice = active_dice_types.size()
		var hot_dice := remaining_dice == 0
		if hot_dice:
			bot_hot_dice_cycles += 1
			remaining_dice = 6
			active_dice_types = bot_loadout.duplicate()
			kept_dice.clear()
			_add_history(I18n.translate("bot_hot_dice_dynamic", [bot_name]), GOLD)
		
		kept_label.text = I18n.translate("kept_hot_dice") if hot_dice else I18n.translate("kept_dice_list", [_dice_text(kept_dice)])
		_update_game_ui()
		
		var should_bank := BotBrain.should_bank({
			"turn_score": turn_score,
			"own_score": bot_score,
			"opponent_score": player_score,
			"target_score": target_score,
			"next_types": active_dice_types,
			"hot_dice_cycles": bot_hot_dice_cycles
		}, BotBrain.profile(bot_profile_id), bot_difficulty, adaptive_learning)
		
		if should_bank:
			_play_sfx("coin_bank")
			bot_score += turn_score
			_add_history(I18n.translate("bot_banks_dynamic", [bot_name, turn_score]), PALE_GOLD)
			_update_game_ui()
			hint_label.text = I18n.translate("bot_ends_turn_dynamic", [bot_name, turn_score])
			if bot_score >= target_score:
				_show_winner(false)
				return
			await get_tree().create_timer(1.1).timeout
			if token == game_token:
				_begin_player_turn()
			return
		
		await get_tree().create_timer(0.55).timeout

func _show_winner(player_won: bool) -> void:
	if campaign_active:
		_finish_chronicles_match(player_won)
		return
	if match_recorded:
		return
	_play_sfx("win_fanfare")
	game_token += 1
	var unlock_message := ""
	
	if not match_recorded:
		var previous_matches := matches_played
		matches_played += 1
		if player_won:
			matches_won += 1
			_commit_winning_player_learning()
		match_recorded = true
		_save_progress()
		
		var unlocked_names: Array[String] = []
		for die: Dictionary in DiceCatalog.TYPES:
			if int(die.unlock) > previous_matches and int(die.unlock) <= matches_played:
				unlocked_names.append(DiceCatalog.type_name(DiceCatalog.TYPES.find(die)))
		if not unlocked_names.is_empty() and not campaign_active:
			unlock_message = I18n.translate("new_die_unlocked", [", ".join(unlocked_names)])
	
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.015, 0.008, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_layer.add_child(shade)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(510, 360)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#281912"), GOLD, 4, 18))
	center.add_child(panel)
	
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	
	box.add_child(_label(I18n.translate("victory") if player_won else I18n.translate("game_over"), 38, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(I18n.translate("player_wins_match", [player_name]) if player_won else I18n.translate("bot_wins_match_dynamic", [bot_name]), 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(I18n.translate("match_score_dynamic", [player_name, player_score, bot_score, bot_name]), 24, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if not unlock_message.is_empty():
		box.add_child(_label(unlock_message, 17, Color("#acd58c"), HORIZONTAL_ALIGNMENT_CENTER))
	
	var again := _button(I18n.translate("rematch"), GREEN, 240)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(start_game)
	box.add_child(again)

	var menu := _button(I18n.translate("back_to_menu"), Color("#6f5430"), 240)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func _show_campaign_screen() -> void:
	active_dialogue = null
	campaign_tutorial = false
	if campaign_slot < 0:
		_show_campaign_saves()
		return
	current_menu = "campaign"
	game_token += 1
	_restore_quick_match_settings()
	campaign_active = false
	campaign_current_index = -1
	if is_instance_valid(multiplayer_table):
		multiplayer_table.queue_free()
		multiplayer_table = null
	tavern_background.visible = true
	world_container.visible = false
	tavern_world.clear_dice()
	_clear_screen()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	screen_layer.add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#21150fe8"), Color("#b18442"), 3, 18))
	center.add_child(panel)
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 20)
	outer.add_theme_constant_override("margin_bottom", 20)
	var overview_scroll := ScrollContainer.new()
	overview_scroll.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 50, 320, 675))
	overview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(overview_scroll)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_scroll.add_child(outer)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	outer.add_child(layout)
	layout.add_child(_label(STORY_TEXT.text("KRONIKI KOSTEK"), 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var saves := _button(I18n.translate("campaign_saves") + " • " + str(campaign_slot + 1), Color("#4b4238"), 300)
	saves.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	saves.pressed.connect(_show_campaign_saves)
	layout.add_child(saves)
	var lore := _label(I18n.translate("campaign_lore"), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.y = 38
	layout.add_child(lore)
	layout.add_child(_label(I18n.translate("campaign_progress", [campaign_progress, CAMPAIGN_CATALOG.CHAPTERS.size()]), 16, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var shop := _button(I18n.translate("campaign_shop") + " • " + I18n.translate("silver_balance", [campaign_economy.silver]), Color("#79552b"), 380)
	shop.name = "CampaignShopButton"
	shop.disabled = bool(campaign_story.get("finished",false))
	shop.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shop.pressed.connect(_show_campaign_shop)
	layout.add_child(shop)

	var goals := HBoxContainer.new()
	goals.alignment = BoxContainer.ALIGNMENT_CENTER
	goals.add_theme_constant_override("separation", 18)
	layout.add_child(goals)
	for milestone: Dictionary in CAMPAIGN_CATALOG.MILESTONES:
		var achieved := campaign_progress >= int(milestone.required)
		var prefix := "✓ " if achieved else "○ "
		goals.add_child(_label(prefix + I18n.translate(str(milestone.key)) + STORY_TEXT.text(" • %d pkt") % int(campaign_story.get("ending_points", {}).get(str(milestone.key).trim_prefix("campaign_goal_"), 0)), 12, Color("#9fd08a") if achieved else MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var clean_status := STORY_TEXT.text("Czyste przejście: aktywne") if CHRONICLES.clean_run(campaign_story) else STORY_TEXT.text("Czyste przejście: niedostępne w tym zapisie")
	layout.add_child(_label(clean_status + STORY_TEXT.text(" • zakupy: %d • zakłady: %d") % [int(campaign_story.get("dice_purchases",0)), int(campaign_story.get("liczba_zakladow",0))], 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if not campaign_ending.is_empty():
		var epilogue := _button(STORY_TEXT.text("CZYTAJ EPILOG — ") + STORY_TEXT.text(str(CHRONICLES.TITLES.get(campaign_ending,campaign_ending))), GREEN, 450)
		epilogue.pressed.connect(func() -> void: _show_campaign_dialogue(11,"epilogue"))
		layout.add_child(epilogue)
	var current_story := _label("", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	current_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_story.custom_minimum_size = Vector2(800, 58)
	if campaign_progress >= CAMPAIGN_CATALOG.CHAPTERS.size():
		current_story.text = I18n.translate("campaign_complete_story")
		if not campaign_ending.is_empty():
			current_story.text += "\n" + STORY_TEXT.text(str(CHRONICLES.TITLES.get(campaign_ending,campaign_ending)))
		current_story.add_theme_color_override("font_color", GOLD)
	else:
		var next_chapter: Dictionary = CAMPAIGN_CATALOG.chapter(CAMPAIGN_CATALOG.next_index(campaign_progress))
		current_story.text = STORY_TEXT.text("Z biletem od staruszka ruszasz na turniej. Przy pierwszym stoliku czeka Tomek Brzuch.") if campaign_progress == 0 and campaign_story.get("prologue_done", false) else STORY_TEXT.text("Bez grosza i bez śniadania wyruszasz w świat. Rozpocznij pierwszy rozdział, aby zagrać prolog.") if campaign_progress == 0 else I18n.translate(str(next_chapter.story_key))
		if campaign_progress == 1:
			if campaign_story.get("side_wins",[]).size() < 6:
				current_story.text = STORY_TEXT.text("Na dziedzińcu czeka sześć pobocznych stołów. Wygraj pojedynki, zarób srebro i rusz do gospody Gromka.")
			elif not CHRONICLES.passed(campaign_story,12):
				current_story.text = str(CHRONICLES.data(12).narrator)
		elif campaign_progress == 2 and not CHRONICLES.passed(campaign_story,13):
			current_story.text = str(CHRONICLES.data(13).narrator)
		elif campaign_progress == 11 and not CHRONICLES.passed(campaign_story,14):
			current_story.text = str(CHRONICLES.data(14).narrator)
	layout.add_child(current_story)
	layout.add_child(_separator())

	if not campaign_story.get("finished",false):
		var next_index := CHRONICLES.next_encounter(campaign_progress,campaign_story)
		var proceed := _button(I18n.translate("continue_campaign"),GREEN,450)
		proceed.name = "CampaignContinueButton"
		proceed.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		proceed.pressed.connect(_continue_campaign)
		layout.add_child(proceed)
		var next_label := _label(CHRONICLES.name(int(campaign_checkpoint.get("chapter",next_index))) if next_index >= 0 else STORY_TEXT.text("WYBIERZ ZAKOŃCZENIE"),18,PALE_GOLD,HORIZONTAL_ALIGNMENT_CENTER)
		layout.add_child(next_label)

	var back := _button(I18n.translate("back_to_menu"), Color("#4b4238"), 240)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_main_menu)
	layout.add_child(back)

func _show_campaign_shop(message: String = "") -> void:
	if campaign_active:
		return
	var previous := screen_layer.get_node_or_null("CampaignShop")
	if previous != null:
		screen_layer.remove_child(previous)
		previous.queue_free()
	var shade := ColorRect.new()
	shade.name = "CampaignShop"
	shade.color = Color(0.03, 0.015, 0.008, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 650)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#281912"), GOLD, 3, 18))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	layout.add_child(_label(I18n.translate("campaign_shop"), 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	layout.add_child(_label(I18n.translate("silver_balance", [campaign_economy.silver]), 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER))
	var hint := _label(I18n.translate("shop_hint"), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(slots)
	for slot in range(6):
		var choice := _button("%d: %s" % [slot + 1, DiceCatalog.type_short(campaign_economy.loadout[slot])], GREEN if slot == shop_selected_slot else Color("#4b4238"), 130)
		choice.name = "ShopSlot%d" % slot
		choice.tooltip_text = DiceCatalog.type_name(campaign_economy.loadout[slot])
		choice.pressed.connect(func() -> void:
			shop_selected_slot = slot
			_show_campaign_shop()
		)
		slots.add_child(choice)
	var feedback := _label(message, 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	feedback.custom_minimum_size.y = 24
	layout.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var offers := VBoxContainer.new()
	offers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offers.add_theme_constant_override("separation", 8)
	scroll.add_child(offers)
	for type_index in range(DiceCatalog.TYPES.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		offers.add_child(row)
		var details := _label("%s • %s\n%s" % [DiceCatalog.type_name(type_index), I18n.translate("shop_owned", [campaign_economy.owned[type_index], campaign_economy.loadout.count(type_index)]), DiceCatalog.type_hint(type_index)], 14, CREAM)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var full: bool = campaign_economy.owned[type_index] >= 6
		var buy := _button(I18n.translate("shop_full") if full else I18n.translate("shop_buy", [CAMPAIGN_ECONOMY.PRICES[type_index]]), Color("#79552b"), 180)
		buy.name = "ShopBuy%d" % type_index
		buy.disabled = not campaign_economy.can_buy(type_index)
		buy.tooltip_text = I18n.translate("shop_full") if full else I18n.translate("shop_buy_hint") if not buy.disabled else I18n.translate("shop_no_silver")
		buy.pressed.connect(_buy_campaign_die.bind(type_index))
		row.add_child(buy)
		var equipped: bool = campaign_economy.loadout[shop_selected_slot] == type_index
		var equip := _button(I18n.translate("shop_equipped") if equipped else I18n.translate("shop_equip", [shop_selected_slot + 1]), GREEN, 160)
		equip.name = "ShopEquip%d" % type_index
		equip.disabled = equipped or not campaign_economy.can_equip(shop_selected_slot, type_index)
		equip.pressed.connect(func() -> void:
			if campaign_economy.equip(shop_selected_slot, type_index):
				_save_progress()
				_show_campaign_shop()
		)
		row.add_child(equip)
	var close := _button(I18n.translate("continue_campaign"), GREEN, 300)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_show_campaign_screen)
	layout.add_child(close)

func _buy_campaign_die(type_index: int) -> void:
	if campaign_active or campaign_story.get("finished",false) or not campaign_economy.buy(type_index):
		return
	campaign_story["dice_purchases"] = int(campaign_story.get("dice_purchases", 0)) + 1
	campaign_economy.equip(shop_selected_slot, type_index)
	_save_progress()
	_play_sfx("coin_bank")
	_show_campaign_shop(I18n.translate("shop_bought", [DiceCatalog.type_name(type_index), shop_selected_slot + 1]))

func _continue_campaign() -> void:
	if not campaign_checkpoint.is_empty():
		var section := str(campaign_checkpoint.get("section",""))
		if section == "tutorial_match":
			_begin_campaign_tutorial()
		else:
			_show_campaign_dialogue(int(campaign_checkpoint.chapter),section,Callable(),int(campaign_checkpoint.get("line",0)))
		return
	if campaign_story.get("finished",false):
		_show_campaign_screen()
		return
	var stage := str(campaign_story.get("pending_ending",""))
	if not stage.is_empty() or campaign_progress >= 12:
		_show_campaign_dialogue(7 if stage == "king" else 9 if stage == "emperor" else 11,"coronation")
		return
	var next_index := CHRONICLES.next_encounter(campaign_progress,campaign_story)
	if next_index >= 0:
		_offer_campaign_chapter(next_index)


func _offer_campaign_chapter(index: int) -> void:
	if not CHRONICLES.can_enter(index, campaign_progress, campaign_story):
		return
	campaign_checkpoint.clear()
	if index == 1 and campaign_story.get("przegral_z_cieniem",false) and not campaign_story.get("pieczec",false):
		_show_campaign_dialogue(index,"seal")
		return
	if index == 0 and not bool(campaign_story.get("prologue_done", campaign_progress > 0)):
		_show_campaign_dialogue(0, "prologue", _begin_campaign_tutorial)
		return
	_start_campaign_chapter(index)

func _start_campaign_chapter(index: int, _wager: int = 0) -> void:
	if not CHRONICLES.can_enter(index, campaign_progress, campaign_story):
		return
	_capture_quick_match_settings()
	_show_campaign_dialogue(index, "intro")

func _begin_campaign_match(index: int, wager: int = 0) -> void:
	if not CHRONICLES.can_enter(index, campaign_progress, campaign_story) or not campaign_economy.place_wager(index, wager):
		_show_campaign_screen()
		return
	CHRONICLES.record_wager(campaign_story, wager)
	if index == 12 and wager == 0:
		CHRONICLES.points_once(campaign_story, "gromek_honor", [0,1,0,0])
	campaign_checkpoint.clear()
	var chapter: Dictionary = CAMPAIGN_CATALOG.chapter(index)
	_capture_quick_match_settings()
	player_loadout.assign(campaign_economy.loadout)
	campaign_active = true
	campaign_current_index = index
	bot_profile_id = str(chapter.profile)
	bot_difficulty = str(chapter.difficulty)
	bot_name = CHRONICLES.name(index)
	theme_id = str(chapter.theme)
	target_score = int(chapter.target)
	_save_progress()
	start_game()

func _show_campaign_dialogue(index: int, section: String, after_dialogue: Callable = Callable(), start_line: int = 0) -> void:
	if is_instance_valid(active_dialogue):
		active_dialogue.queue_free()
	var context: Dictionary = campaign_story.duplicate(true)
	context["silver"] = campaign_economy.silver
	if campaign_checkpoint.get("chapter",-1) == index and campaign_checkpoint.get("section","") == section and campaign_checkpoint.has("context"):
		context = campaign_checkpoint.context.duplicate(true)
	var resource := _chronicle_resource(index, section, context)
	var dialogue := VISUAL_NOVEL_DIALOGUE_SCENE.instantiate() as Control
	screen_layer.add_child(dialogue)
	active_dialogue = dialogue
	dialogue.set("story_gender", str(campaign_story.get("gender", "male")))
	dialogue.line_changed.connect(func(line_index: int) -> void:
		campaign_checkpoint = {"chapter": index, "section": section, "line": line_index, "context": context}
		_save_progress()
	)
	dialogue.choice_selected.connect(func(choice_id: String) -> void:
		_apply_chronicle_choice(index, section, choice_id, context)
		campaign_choices.append({"chapter": index, "section": section, "choice": choice_id})
		_save_progress()
	)
	var copy_save := _button(I18n.translate("save_branch"), Color("#4b4238"), 230)
	copy_save.name = "SaveBranch"
	copy_save.position = Vector2(24, 78)
	copy_save.pressed.connect(_show_campaign_saves.bind(true))
	dialogue.add_child(copy_save)
	var pause := _button(I18n.translate("campaign_pause"),Color("#4b4238"),230)
	pause.name = "CampaignPause"
	pause.position = Vector2(270,78)
	pause.pressed.connect(_show_campaign_screen)
	dialogue.add_child(pause)
	dialogue.finished.connect(func() -> void:
		var result := str(dialogue.get("result_id"))
		campaign_checkpoint.clear()
		active_dialogue = null
		dialogue.queue_free()
		_save_progress()
		if after_dialogue.is_valid():
			after_dialogue.call()
		else:
			_after_chronicle_dialogue(index, section, result)
	, CONNECT_ONE_SHOT)
	dialogue.call("play", resource, "intro", start_line)

func _campaign_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("campaign", "progress", campaign_progress)
	config.set_value("campaign", "ending", campaign_ending)
	config.set_value("campaign", "story", campaign_story.duplicate(true))
	config.set_value("campaign", "choices", campaign_choices.duplicate(true))
	config.set_value("campaign", "checkpoint", campaign_checkpoint.duplicate(true))
	config.set_value("campaign", "name", player_name)
	campaign_economy.write_save(config)
	return config

func _apply_campaign_config(config: ConfigFile) -> void:
	campaign_tutorial = false
	var saved_story: Variant = config.get_value("campaign", "story", {})
	var legacy_story: bool = not saved_story is Dictionary or int(saved_story.get("chronicles_version",0)) < 2
	campaign_story = saved_story.duplicate(true) if saved_story is Dictionary else {}
	campaign_progress = CAMPAIGN_CATALOG.clamped_progress(int(config.get_value("campaign", "progress", 0)))
	campaign_ending = str(config.get_value("campaign", "ending", ""))
	CHRONICLES.initialize(campaign_story, campaign_progress, config.has_section("campaign"))
	if not campaign_ending.is_empty():
		campaign_story["finished"] = true
	campaign_economy = CAMPAIGN_ECONOMY.new()
	campaign_economy.read_save(config, campaign_progress)
	var choices: Variant = config.get_value("campaign", "choices", [])
	campaign_choices = choices.duplicate(true) if choices is Array else []
	var checkpoint: Variant = config.get_value("campaign", "checkpoint", {})
	campaign_checkpoint = checkpoint.duplicate(true) if checkpoint is Dictionary else {}
	if legacy_story:
		if campaign_checkpoint.get("section", "") != "tutorial_match":
			campaign_checkpoint.clear()
		for event in campaign_choices:
			if event is Dictionary and CHRONICLES.REASONS.has(str(event.get("choice",""))):
				campaign_story["powod"] = CHRONICLES.REASONS[str(event.choice)]
	player_name = str(config.get_value("campaign", "name", player_name))

func _activate_campaign_slot(slot: int) -> void:
	if slot < 0 or slot >= CAMPAIGN_SAVES.SLOT_COUNT:
		return
	var config := CAMPAIGN_SAVES.read_slot(slot)
	if config == null and FileAccess.file_exists(CAMPAIGN_SAVES.path(slot)):
		return
	if FileAccess.file_exists(CAMPAIGN_SAVES.path(campaign_slot)):
		_save_progress()
	_restore_quick_match_settings()
	campaign_active = false
	campaign_slot = slot
	_apply_campaign_config(config if config != null else ConfigFile.new())
	_save_progress()
	_show_campaign_screen()
	if not campaign_checkpoint.is_empty():
		var index := int(campaign_checkpoint.get("chapter", -1))
		var section := str(campaign_checkpoint.get("section", ""))
		var line := maxi(0, int(campaign_checkpoint.get("line", 0)))
		if section == "tutorial_match":
			_begin_campaign_tutorial()
		elif not CAMPAIGN_CATALOG.chapter(index).is_empty() and section in ["intro", "victory", "defeat", "prologue", "tutorial_victory", "tutorial_defeat", "wager", "wager_reply", "seal", "seal_route", "coronation", "epilogue"]:
			_show_campaign_dialogue(index, section, Callable(), line)
	elif not str(campaign_story.get("pending_ending", "")).is_empty():
		_show_campaign_dialogue(11 if campaign_story.pending_ending == "final" else 7 if campaign_story.pending_ending == "king" else 9, "coronation")

func _copy_campaign_slot(slot: int) -> bool:
	if slot < 0 or slot >= CAMPAIGN_SAVES.SLOT_COUNT or FileAccess.file_exists(CAMPAIGN_SAVES.path(slot)):
		return false
	return CAMPAIGN_SAVES.write_slot(slot, _campaign_config()) == OK

func _delete_campaign_slot(slot: int) -> bool:
	if slot < 0 or slot >= CAMPAIGN_SAVES.SLOT_COUNT:
		return false
	var source: String = CAMPAIGN_SAVES.path(slot)
	if not FileAccess.file_exists(source):
		return false
	# Preserve an archive so an accidental confirmed deletion is recoverable.
	var archive := source + ".deleted-" + str(Time.get_unix_time_from_system())
	if DirAccess.rename_absolute(source, archive) != OK:
		return false
	if campaign_slot == slot:
		campaign_slot = -1
		_apply_campaign_config(ConfigFile.new())
		_save_progress()
	return true

func _confirm_delete_campaign_slot(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.name = "DeleteSaveConfirmation"
	dialog.title = I18n.translate("save_delete")
	dialog.dialog_text = I18n.translate("save_delete_confirm", [slot + 1])
	dialog.ok_button_text = I18n.translate("save_delete")
	dialog.cancel_button_text = I18n.translate("wager_cancel")
	dialog.confirmed.connect(func() -> void:
		if _delete_campaign_slot(slot):
			dialog.queue_free()
			_show_campaign_saves()
	)
	dialog.canceled.connect(dialog.queue_free)
	screen_layer.add_child(dialog)
	dialog.popup_centered(Vector2i(470, 180))

func _show_campaign_saves(copy_only: bool = false) -> void:
	if copy_only and is_instance_valid(active_dialogue):
		active_dialogue.set_process_unhandled_key_input(false)
	if not copy_only:
		_prepare_menu_screen()
		current_menu = "saves"
	var shade := ColorRect.new()
	shade.name = "CampaignSaves"
	shade.set_meta("copy_only", copy_only)
	shade.tree_exiting.connect(func() -> void:
		if copy_only and is_instance_valid(active_dialogue):
			active_dialogue.set_process_unhandled_key_input(true)
	)
	shade.color = Color("#100d0af5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 610)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#21150f"), GOLD, 2, 10))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	box.add_child(_label(I18n.translate("save_branch" if copy_only else "campaign_saves"), 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var hint := _label(I18n.translate("saves_hint"), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	for slot in range(CAMPAIGN_SAVES.SLOT_COUNT):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 66
		box.add_child(row)
		var config := CAMPAIGN_SAVES.read_slot(slot)
		var exists := FileAccess.file_exists(CAMPAIGN_SAVES.path(slot))
		var description := I18n.translate("save_empty", [slot + 1])
		if config != null:
			var ending := str(config.get_value("campaign", "ending", ""))
			description = I18n.translate("save_summary", [slot + 1, int(config.get_value("campaign", "progress", 0)), int(config.get_value("campaign", "silver", 0))])
			description += "\n" + (STORY_TEXT.text(str(CHRONICLES.TITLES.get(ending,ending))) if not ending.is_empty() else str(config.get_value("campaign", "updated", "")))
		elif exists:
			description = I18n.translate("save_unreadable", [slot + 1])
		var label := _label(description, 14, CREAM)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var action := _button(I18n.translate("save_copy" if copy_only else "save_load" if exists else "save_new"), GREEN, 150)
		action.disabled = exists if copy_only else exists and config == null
		action.pressed.connect(func() -> void:
			if copy_only:
				if _copy_campaign_slot(slot):
					shade.queue_free()
			else:
				_activate_campaign_slot(slot)
		)
		row.add_child(action)
		if exists and not copy_only:
			var remove := _button(I18n.translate("save_delete"), RED, 90)
			remove.name = "DeleteSave%d" % slot
			remove.pressed.connect(_confirm_delete_campaign_slot.bind(slot))
			row.add_child(remove)
	var back := _button(I18n.translate("wager_cancel"), Color("#4b4238"), 200)
	back.pressed.connect(func() -> void:
		if copy_only:
			shade.queue_free()
		else:
			show_main_menu()
	)
	box.add_child(back)

func _capture_quick_match_settings() -> void:
	if not quick_match_settings.is_empty():
		return
	quick_match_settings = {
		"bot_profile": bot_profile_id,
		"bot_difficulty": bot_difficulty,
		"bot_name": bot_name,
		"bot_avatar": bot_avatar_id,
		"theme": theme_id,
		"loadout": player_loadout.duplicate(),
		"target": target_score
	}

func _restore_quick_match_settings() -> void:
	if campaign_active:
		campaign_economy.settle_wager(false)
	if quick_match_settings.is_empty():
		return
	bot_profile_id = str(quick_match_settings.bot_profile)
	bot_difficulty = str(quick_match_settings.bot_difficulty)
	bot_name = str(quick_match_settings.bot_name)
	bot_avatar_id = str(quick_match_settings.bot_avatar)
	theme_id = str(quick_match_settings.theme)
	target_score = int(quick_match_settings.target)
	player_loadout.assign(quick_match_settings.loadout)
	quick_match_settings.clear()

func _show_multiplayer_lobby() -> void:
	var previous_menu := current_menu
	current_menu = "lobby"
	var shade := ColorRect.new()
	shade.name = "MultiplayerLobby"
	shade.color = Color(0.03, 0.015, 0.008, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_layer.add_child(shade)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#281912"), Color("#977241"), 3, 16))
	center.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 48, 320, 680))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	
	box.add_child(_label(I18n.translate("mp_table_title"), 27, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	
	var explanation := _label("%s\n%s" % [I18n.translate("campaign_lore"), I18n.translate("mp_explanation")], 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size.y = 60
	box.add_child(explanation)
	
	var addresses: Array = network_session.local_addresses()
	var lan_text := I18n.translate("your_lan", [", ".join(addresses) if not addresses.is_empty() else I18n.translate("lan_not_found")])
	box.add_child(_label(lan_text, 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	
	var port_row := HBoxContainer.new()
	port_row.alignment = BoxContainer.ALIGNMENT_CENTER
	port_row.add_theme_constant_override("separation", 10)
	box.add_child(port_row)
	port_row.add_child(_label(I18n.translate("udp_port"), 14, PALE_GOLD))
	
	var port_edit := LineEdit.new()
	port_edit.text = str(NetworkSession.DEFAULT_PORT)
	port_edit.custom_minimum_size = Vector2(100, 38)
	port_edit.add_theme_font_size_override("font_size", 15)
	port_row.add_child(port_edit)
	
	var host_button := _button(I18n.translate("host_game"), GREEN, 250)
	port_row.add_child(host_button)
	
	var public_row := HBoxContainer.new()
	public_row.alignment = BoxContainer.ALIGNMENT_CENTER
	public_row.add_theme_constant_override("separation", 10)
	box.add_child(public_row)
	public_row.add_child(_label(I18n.translate("playit_label"), 13, PALE_GOLD))
	
	var public_edit := LineEdit.new()
	public_edit.placeholder_text = I18n.translate("playit_placeholder")
	public_edit.custom_minimum_size = Vector2(280, 38)
	public_edit.add_theme_font_size_override("font_size", 14)
	public_edit.add_theme_color_override("font_color", CREAM)
	public_edit.add_theme_stylebox_override("normal", _panel_style(Color("#120c09"), Color("#765a38"), 2, 8))
	public_row.add_child(public_edit)
	
	var set_public_btn := _button(I18n.translate("invite"), Color("#6f5430"), 130)
	public_row.add_child(set_public_btn)
	
	var public_display := _label("", 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	public_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(public_display)
	var copy_code := _button(I18n.translate("copy_room_code"), Color("#6f5430"), 190)
	copy_code.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	copy_code.pressed.connect(func() -> void:
		if not network_session.public_address.is_empty():
			DisplayServer.clipboard_set(NetworkSession.make_room_code(network_session.public_address))
	)
	var invitation_buttons := HBoxContainer.new()
	invitation_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(invitation_buttons)
	invitation_buttons.add_child(copy_code)
	var copy_link := _button(I18n.translate("copy_invite_link"), Color("#6f5430"), 190)
	copy_link.pressed.connect(func() -> void:
		if not network_session.public_address.is_empty():
			DisplayServer.clipboard_set(INVITE_LINKS.make_link(network_session.public_address))
	)
	invitation_buttons.add_child(copy_link)
	var enable_links := _button(I18n.translate("enable_invite_links"), Color("#6f5430"), 230)
	enable_links.tooltip_text = I18n.translate("enable_invite_links_hint")
	enable_links.pressed.connect(func() -> void:
		network_status_label.text = INVITE_LINKS.register_handler()
	)
	invitation_buttons.add_child(enable_links)
	copy_code.disabled = network_session.public_address.is_empty()
	copy_link.disabled = copy_code.disabled
	box.add_child(_separator())
	
	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	join_row.add_theme_constant_override("separation", 10)
	box.add_child(join_row)
	
	var address_edit := LineEdit.new()
	address_edit.placeholder_text = I18n.translate("address_placeholder")
	address_edit.text = ""
	address_edit.custom_minimum_size = Vector2(410, 42)
	address_edit.add_theme_font_size_override("font_size", 15)
	join_row.add_child(address_edit)
	
	var join_button := _button(I18n.translate("join_game"), Color("#6f5430"), 190)
	join_row.add_child(join_button)
	
	lobby_seats_label = _label(I18n.translate("seats_will_appear"), 16, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	lobby_seats_label.custom_minimum_size.y = 70
	lobby_seats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lobby_seats_label)
	
	var lobby_bot_model_row := HBoxContainer.new()
	lobby_bot_model_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lobby_bot_model_row.add_theme_constant_override("separation", 10)
	box.add_child(lobby_bot_model_row)
	lobby_bot_model_row.add_child(_label(I18n.translate("bot_model_to_add"), 13, PALE_GOLD))
	
	var lobby_bot_model_select := OptionButton.new()
	lobby_bot_model_select.custom_minimum_size = Vector2(300, 38)
	lobby_bot_model_row.add_child(lobby_bot_model_select)
	bot_avatar_id = _populate_option_button(lobby_bot_model_select, AssetLibrary.available_player_models(), bot_avatar_id)
	
	lobby_bot_model_select.item_selected.connect(func(index: int) -> void:
		bot_avatar_id = str(lobby_bot_model_select.get_item_metadata(index))
		_save_progress()
	)
	
	var bot_row := HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 10)
	box.add_child(bot_row)
	
	lobby_remove_bot_button = _button(I18n.translate("remove_bot"), Color("#6f5430"), 120)
	lobby_add_bot_button = _button(I18n.translate("add_bot"), Color("#6f5430"), 120)
	lobby_start_button = _button(I18n.translate("start_game"), GREEN, 220)
	
	lobby_remove_bot_button.disabled = true
	lobby_add_bot_button.disabled = true
	lobby_start_button.disabled = true
	
	bot_row.add_child(lobby_remove_bot_button)
	bot_row.add_child(lobby_add_bot_button)
	bot_row.add_child(lobby_start_button)
	
	network_status_label = _label(I18n.translate("not_connected"), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_status_label.custom_minimum_size.y = 42
	box.add_child(network_status_label)
	
	host_button.pressed.connect(func() -> void:
		var port := clampi(port_edit.text.to_int(), 1024, 65535)
		network_session.target_score = target_score
		network_session.host_game(player_name, port, player_loadout, player_avatar_id)
	)
	
	set_public_btn.pressed.connect(func() -> void:
		network_session.set_public_address(public_edit.text, clampi(port_edit.text.to_int(), 1024, 65535))
	)
	
	var on_public_ready := func(addr: String) -> void:
		public_display.text = I18n.translate("send_to_friends", [NetworkSession.make_room_code(addr)])
		copy_code.disabled = false
		copy_link.disabled = false
	network_session.public_address_ready.connect(on_public_ready)
	
	join_button.pressed.connect(func() -> void:
		var port := clampi(port_edit.text.to_int(), 1024, 65535)
		network_session.join_game(address_edit.text, player_name, port, player_loadout, player_avatar_id)
	)
	
	lobby_add_bot_button.pressed.connect(func() -> void: network_session.add_bot(bot_avatar_id))
	lobby_remove_bot_button.pressed.connect(func() -> void: network_session.remove_bot())
	lobby_start_button.pressed.connect(func() -> void: network_session.start_match())
	
	var back := Button.new()
	back.text = I18n.translate("back")
	back.flat = true
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_color_override("font_color", PALE_GOLD)
	
	var close_lobby := func() -> void:
		if network_session.public_address_ready.is_connected(on_public_ready):
			network_session.public_address_ready.disconnect(on_public_ready)
		network_session.disconnect_session()
		shade.queue_free()
		current_menu = previous_menu
	
	back.pressed.connect(close_lobby)
	box.add_child(back)

func _render_dice(locked: bool) -> void:
	keyboard_die = clampi(keyboard_die, 0, maxi(0, current_dice.size() - 1))
	_clear_dice_row()
	for index in range(current_dice.size()):
		var die := DieView.new()
		var die_type := current_roll_types[index] if index < current_roll_types.size() else 0
		die.configure(index, current_dice[index], die_type, locked)
		die.tooltip_text = DiceCatalog.type_name(die_type)
		die.keyboard_cursor = index == keyboard_die
		die.die_pressed.connect(_on_die_pressed)
		dice_row.add_child(die)
		die.custom_minimum_size = Vector2(70, 70)
		die.modulate.a = 0.0
		var tween := die.create_tween()
		tween.tween_property(die, "modulate:a", 1.0, 0.18).set_delay(index * 0.055)

func _selected_values() -> Array[int]:
	var values: Array[int] = []
	for index in selected_indices:
		if index >= 0 and index < current_dice.size():
			values.append(current_dice[index])
	return values

func _roll_values(types: Array[int]) -> Array[int]:
	var values: Array[int] = []
	for die_type in types:
		values.append(DiceCatalog.roll(die_type, rng))
	return values

func _dice_text(values: Array) -> String:
	if values.is_empty():
		return "—"
	var parts: Array[String] = []
	for value in values:
		parts.append(DIE_GLYPHS[int(value) - 1])
	return " ".join(parts)

func _update_game_ui() -> void:
	if is_instance_valid(player_score_label):
		player_score_label.text = STORY_TEXT.text("%d pkt") % player_score
		bot_score_label.text = STORY_TEXT.text("%d pkt") % bot_score
		player_progress.value = player_score
		bot_progress.value = bot_score
		turn_label.text = I18n.translate("turn_points", [turn_score])

func _add_history(message: String, color: Color) -> void:
	if not is_instance_valid(history_box):
		return
	var item := _label(message, 13, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_box.add_child(item)
	if history_box.get_child_count() > 10:
		history_box.get_child(0).queue_free()

func _clear_dice_row() -> void:
	if not is_instance_valid(dice_row):
		return
	for child in dice_row.get_children():
		child.queue_free()

func _clear_screen() -> void:
	if is_instance_valid(screen_layer):
		for child in screen_layer.get_children():
			child.queue_free()

func _on_dice_slot_pressed(slot_index: int) -> void:
	var next_type := player_loadout[slot_index]
	for attempt in range(DiceCatalog.TYPES.size()):
		next_type = (next_type + 1) % DiceCatalog.TYPES.size()
		if DiceCatalog.is_unlocked(next_type, matches_played):
			break
	player_loadout[slot_index] = next_type
	_refresh_dice_slots(slot_index)

func _refresh_dice_slots(focused_slot: int) -> void:
	for index in range(dice_slot_buttons.size()):
		var button := dice_slot_buttons[index]
		var type_index: int = player_loadout[index]
		button.text = DiceCatalog.type_short(type_index)
		var active := type_index > 0
		button.tooltip_text = "%s\n%s" % [DiceCatalog.type_name(type_index), DiceCatalog.type_hint(type_index)]
		button.add_theme_color_override("font_color", GOLD if active else CREAM)
		button.add_theme_color_override("font_hover_color", GOLD)
		button.add_theme_stylebox_override("normal", _panel_style(Color("#3a2118") if active else Color("#1a120e"), GOLD if active else Color("#5d4933"), 3 if active else 1, 10))
		button.add_theme_stylebox_override("hover", _panel_style(Color("#43291d"), Color("#c49a50"), 2, 10))
		button.add_theme_stylebox_override("pressed", _panel_style(Color("#261710"), GOLD, 3, 10))
	
	if is_instance_valid(dice_detail_label):
		var focused_type: int = player_loadout[focused_slot]
		dice_detail_label.text = "%s — %s • %s" % [DiceCatalog.type_name(focused_type), DiceCatalog.type_hint(focused_type), I18n.translate("click_to_change")]

func _unlocked_dice_count() -> int:
	var amount := 0
	for type_index in range(DiceCatalog.TYPES.size()):
		if DiceCatalog.is_unlocked(type_index, matches_played):
			amount += 1
	return amount

func _show_dice_collection() -> void:
	var lines: Array[String] = []
	for type_index in range(DiceCatalog.TYPES.size()):
		if DiceCatalog.is_unlocked(type_index, matches_played):
			lines.append("✓ %s — %s" % [DiceCatalog.type_name(type_index), DiceCatalog.type_hint(type_index)])
		else:
			lines.append(I18n.translate("unlocked_after", [DiceCatalog.type_name(type_index), DiceCatalog.TYPES[type_index].unlock]))
	
	var dialog := AcceptDialog.new()
	dialog.title = I18n.translate("collection_title")
	dialog.dialog_text = I18n.translate("collection_stats_full", [matches_played, matches_won, "\n\n".join(lines)])
	dialog.min_size = Vector2i(650, 590)
	dialog.add_theme_font_size_override("font_size", 15)
	screen_layer.add_child(dialog)
	dialog.popup_centered()
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)

func _show_character_creator() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.015, 0.008, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 430)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#281912"), GOLD, 3, 16))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(_label(I18n.translate("character_creator_title"), 27, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var explanation := _label(I18n.translate("creator_procedural_hint"), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)
	var skin_select := OptionButton.new()
	var tunic_select := OptionButton.new()
	var hair_select := OptionButton.new()
	player_appearance.skin = _populate_option_button(skin_select, SKIN_TONES, str(player_appearance.skin))
	player_appearance.tunic = _populate_option_button(tunic_select, TUNIC_COLORS, str(player_appearance.tunic))
	player_appearance.hair = _populate_option_button(hair_select, HAIR_COLORS, str(player_appearance.hair))
	for setting in [
		{"label": I18n.translate("skin_tone"), "control": skin_select},
		{"label": I18n.translate("tunic_color"), "control": tunic_select},
		{"label": I18n.translate("hair_color"), "control": hair_select}
	]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 18)
		row.add_child(_label(str(setting.label), 15, PALE_GOLD))
		var control := setting.control as OptionButton
		control.custom_minimum_size = Vector2(260, 40)
		row.add_child(control)
		box.add_child(row)
	var save := _button(I18n.translate("save_character"), GREEN, 230)
	save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	save.pressed.connect(func() -> void:
		player_appearance.skin = str(skin_select.get_item_metadata(skin_select.selected))
		player_appearance.tunic = str(tunic_select.get_item_metadata(tunic_select.selected))
		player_appearance.hair = str(hair_select.get_item_metadata(hair_select.selected))
		_save_progress()
		shade.queue_free()
	)
	box.add_child(save)

func _record_player_decision(banked: bool, score: int) -> void:
	if score <= 0:
		return
	if banked:
		match_learning.bank_count = int(match_learning.bank_count) + 1
		match_learning.bank_total = int(match_learning.bank_total) + score
	else:
		match_learning.continue_count = int(match_learning.continue_count) + 1
		match_learning.continue_total = int(match_learning.continue_total) + score

func _commit_winning_player_learning() -> void:
	var bank_count := int(match_learning.bank_count)
	var continue_count := int(match_learning.continue_count)
	if bank_count + continue_count == 0:
		return
	var previous_wins := int(adaptive_learning.get("winning_matches", 0))
	var margin_ratio := clampf(float(player_score - bot_score) / float(maxi(1, target_score)), 0.0, 1.0)
	var learning_rate := clampf(0.22 + margin_ratio * 0.23, 0.22, 0.45)
	if bank_count > 0:
		var match_bank_average := float(match_learning.bank_total) / float(bank_count)
		var old_bank_average := float(adaptive_learning.get("bank_ema", match_bank_average))
		adaptive_learning.bank_ema = match_bank_average if previous_wins == 0 else lerpf(old_bank_average, match_bank_average, learning_rate)
	if continue_count > 0:
		var match_continue_average := float(match_learning.continue_total) / float(continue_count)
		var old_continue_average := float(adaptive_learning.get("continue_ema", match_continue_average))
		adaptive_learning.continue_ema = match_continue_average if previous_wins == 0 else lerpf(old_continue_average, match_continue_average, learning_rate)
	adaptive_learning.bank_count = int(adaptive_learning.get("bank_count", 0)) + bank_count
	adaptive_learning.bank_total = int(adaptive_learning.get("bank_total", 0)) + int(match_learning.bank_total)
	adaptive_learning.continue_count = int(adaptive_learning.get("continue_count", 0)) + continue_count
	adaptive_learning.continue_total = int(adaptive_learning.get("continue_total", 0)) + int(match_learning.continue_total)
	adaptive_learning.winning_matches = previous_wins + 1

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		mods_enabled = bool(config.get_value("general", "mods_enabled", true))
		AssetLibrary.set_mods_enabled(mods_enabled)
		matches_played = maxi(0, int(config.get_value("progress", "matches", 0)))
		matches_won = clampi(int(config.get_value("progress", "wins", 0)), 0, matches_played)
		master_volume = clampf(float(config.get_value("audio", "master", 0.85)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value("audio", "music", 0.42)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("audio", "sfx", 0.90)), 0.0, 1.0)
		audio_muted = bool(config.get_value("audio", "muted", false))
		player_avatar_id = str(config.get_value("mods", "player_avatar", "procedural"))
		bot_avatar_id = str(config.get_value("mods", "bot_avatar", "procedural"))
		sound_pack_id = str(config.get_value("mods", "sound_pack", "builtin"))
		theme_id = str(config.get_value("game", "theme", "tavern"))
		bot_profile_id = str(config.get_value("bot", "profile", "rookie"))
		bot_difficulty = str(config.get_value("bot", "difficulty", "easy"))
		bot_name = str(config.get_value("bot", "name", I18n.translate(str(BotBrain.profile(bot_profile_id).name_key)))).left(28)
		player_appearance = {
			"skin": str(config.get_value("appearance", "skin", "fair")),
			"tunic": str(config.get_value("appearance", "tunic", "brown")),
			"hair": str(config.get_value("appearance", "hair", "brown"))
		}
		adaptive_learning = {
			"bank_count": maxi(0, int(config.get_value("learning", "bank_count", 0))),
			"bank_total": maxi(0, int(config.get_value("learning", "bank_total", 0))),
			"continue_count": maxi(0, int(config.get_value("learning", "continue_count", 0))),
			"continue_total": maxi(0, int(config.get_value("learning", "continue_total", 0))),
			"bank_ema": maxf(0.0, float(config.get_value("learning", "bank_ema", 0.0))),
			"continue_ema": maxf(0.0, float(config.get_value("learning", "continue_ema", 0.0))),
			"winning_matches": maxi(0, int(config.get_value("learning", "winning_matches", 0)))
		}
		campaign_progress = CAMPAIGN_CATALOG.clamped_progress(int(config.get_value("campaign", "progress", 0)))
		campaign_ending = str(config.get_value("campaign", "ending", ""))
		campaign_economy.read_save(config, campaign_progress)
		player_name = str(config.get_value("general", "player_name", player_name)).left(18)
		
		if not AssetLibrary.has_model(player_avatar_id):
			player_avatar_id = "procedural"
		if not AssetLibrary.has_model(bot_avatar_id):
			bot_avatar_id = "procedural"
		
		sound_pack_id = AssetLibrary.set_sound_pack(sound_pack_id)
	campaign_slot = clampi(int(config.get_value("campaign", "active_slot", 0)), -1, CAMPAIGN_SAVES.SLOT_COUNT - 1)
	if not config.has_section_key("campaign", "active_slot") and config.has_section("campaign") and not FileAccess.file_exists(CAMPAIGN_SAVES.path(0)):
		CHRONICLES.initialize(campaign_story, campaign_progress, true)
		CAMPAIGN_SAVES.write_slot(0, _campaign_config())
	var slot_config := CAMPAIGN_SAVES.read_slot(campaign_slot)
	if slot_config != null:
		_apply_campaign_config(slot_config)
	elif campaign_slot < 0:
		_apply_campaign_config(ConfigFile.new())

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "matches", matches_played)
	config.set_value("progress", "wins", matches_won)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "muted", audio_muted)
	config.set_value("mods", "player_avatar", player_avatar_id)
	config.set_value("mods", "bot_avatar", bot_avatar_id)
	config.set_value("mods", "sound_pack", sound_pack_id)
	config.set_value("general", "mods_enabled", mods_enabled)
	var saved_theme := str(quick_match_settings.get("theme", theme_id)) if campaign_active else theme_id
	var saved_bot_profile := str(quick_match_settings.get("bot_profile", bot_profile_id)) if campaign_active else bot_profile_id
	var saved_bot_difficulty := str(quick_match_settings.get("bot_difficulty", bot_difficulty)) if campaign_active else bot_difficulty
	var saved_bot_name := str(quick_match_settings.get("bot_name", bot_name)) if campaign_active else bot_name
	config.set_value("game", "theme", saved_theme)
	config.set_value("bot", "profile", saved_bot_profile)
	config.set_value("bot", "difficulty", saved_bot_difficulty)
	config.set_value("bot", "name", saved_bot_name)
	config.set_value("general", "player_name", player_name)
	config.set_value("campaign", "progress", campaign_progress)
	config.set_value("campaign", "ending", campaign_ending)
	config.set_value("campaign", "active_slot", campaign_slot)
	campaign_economy.write_save(config)
	config.set_value("appearance", "skin", str(player_appearance.skin))
	config.set_value("appearance", "tunic", str(player_appearance.tunic))
	config.set_value("appearance", "hair", str(player_appearance.hair))
	config.set_value("learning", "bank_count", int(adaptive_learning.bank_count))
	config.set_value("learning", "bank_total", int(adaptive_learning.bank_total))
	config.set_value("learning", "continue_count", int(adaptive_learning.continue_count))
	config.set_value("learning", "continue_total", int(adaptive_learning.continue_total))
	config.set_value("learning", "bank_ema", float(adaptive_learning.get("bank_ema", 0.0)))
	config.set_value("learning", "continue_ema", float(adaptive_learning.get("continue_ema", 0.0)))
	config.set_value("learning", "winning_matches", int(adaptive_learning.get("winning_matches", 0)))
	config.save(SAVE_PATH)
	var save_error := CAMPAIGN_SAVES.write_slot(campaign_slot, _campaign_config()) if campaign_slot >= 0 else OK
	if save_error != OK:
		push_error("Campaign save failed: %s" % error_string(save_error))

func _build_language_selector() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	language_select = OptionButton.new()
	language_select.name = "LanguageSelector"
	language_select.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	language_select.offset_left = 16
	language_select.offset_right = 216
	language_select.offset_top = -42
	language_select.offset_bottom = -10
	language_select.add_theme_stylebox_override("normal", _panel_style(Color("#20251f"), Color("#767764"), 1, 3))
	language_select.add_theme_color_override("font_color", CREAM)
	for locale: String in I18n.get_available_languages():
		language_select.add_item(I18n.get_language_name(locale))
		var index := language_select.item_count - 1
		language_select.set_item_metadata(index, locale)
		if locale == "be":
			language_select.set_item_icon(index, _get_belarus_historical_flag())
		if locale == I18n.current_locale:
			language_select.select(index)
	overlay.add_child(language_select)
	language_select.item_selected.connect(func(index: int) -> void:
		I18n.set_language(str(language_select.get_item_metadata(index)))
	)
	I18n.language_changed.connect(_refresh_language)

func _refresh_language() -> void:
	for index in range(language_select.item_count):
		if str(language_select.get_item_metadata(index)) == I18n.current_locale:
			language_select.select(index)
	var saves := screen_layer.get_node_or_null("CampaignSaves")
	if is_instance_valid(active_dialogue):
		if active_dialogue.has_meta("wager_index"):
			var resource := WAGER_DIALOGUE.build(int(active_dialogue.get_meta("wager_index")), campaign_economy.silver, I18n.translate)
			active_dialogue.call("play", resource, "intro", int(active_dialogue.get("_line_index")))
		else:
			if not campaign_checkpoint.is_empty():
				var context: Dictionary = campaign_checkpoint.get("context",campaign_story).duplicate(true)
				context["silver"] = context.get("silver",campaign_economy.silver)
				var resource := _chronicle_resource(int(campaign_checkpoint.chapter),str(campaign_checkpoint.section),context)
				active_dialogue.call("play",resource,"intro",int(active_dialogue.get("_line_index")))
			else:
				active_dialogue.call("refresh_language")
			var pause := active_dialogue.get_node_or_null("CampaignPause") as Button
			if pause != null:
				pause.text = I18n.translate("campaign_pause")
			var branch := active_dialogue.get_node_or_null("SaveBranch") as Button
			if branch != null:
				branch.text = I18n.translate("save_branch")
		if saves != null:
			screen_layer.remove_child(saves)
			saves.queue_free()
			_show_campaign_saves(true)
		return
	match current_menu:
		"main": show_main_menu()
		"setup": _show_setup_menu(setup_mode)
		"campaign": _show_campaign_screen()
		"saves": _show_campaign_saves()
		"achievements": _show_achievements()
		"game": _update_game_ui()

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")

func _apply_audio_settings() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	var music_index := AudioServer.get_bus_index("Music")
	var sfx_index := AudioServer.get_bus_index("SFX")
	if master_index >= 0:
		AudioServer.set_bus_volume_db(master_index, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master_index, audio_muted)
	if music_index >= 0:
		AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_volume, 0.0001)))
	if sfx_index >= 0:
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(maxf(sfx_volume, 0.0001)))

func _show_audio_settings() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.015, 0.008, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_layer.add_child(shade)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 590)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#281912"), GOLD, 3, 16))
	center.add_child(panel)
	
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	
	box.add_child(_label(I18n.translate("sound_settings_title"), 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	
	var master_value := _label("%d%%" % roundi(master_volume * 100.0), 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_label(I18n.translate("master_volume"), 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var master_slider := HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 1
	master_slider.value = master_volume * 100.0
	master_slider.custom_minimum_size.x = 420
	box.add_child(master_slider)
	box.add_child(master_value)

	var music_value := _label("%d%%" % roundi(music_volume * 100.0), 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_label(I18n.translate("music_volume"), 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var music_slider := HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = music_volume * 100.0
	box.add_child(music_slider)
	box.add_child(music_value)
	
	var sfx_value := _label("%d%%" % roundi(sfx_volume * 100.0), 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_label(I18n.translate("sfx_volume"), 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = sfx_volume * 100.0
	box.add_child(sfx_slider)
	box.add_child(sfx_value)
	
	box.add_child(_label(I18n.translate("sound_pack"), 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var sound_pack_select := OptionButton.new()
	sound_pack_select.custom_minimum_size = Vector2(420, 40)
	sound_pack_select.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(sound_pack_select)
	
	sound_pack_id = _populate_option_button(sound_pack_select, AssetLibrary.available_sound_packs(), sound_pack_id)
	AssetLibrary.set_sound_pack(sound_pack_id)
	
	var refresh_packs := Button.new()
	refresh_packs.text = I18n.translate("refresh_mod_catalog")
	refresh_packs.flat = true
	refresh_packs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	refresh_packs.add_theme_color_override("font_color", PALE_GOLD)
	box.add_child(refresh_packs)
	
	var mute := CheckButton.new()
	mute.text = I18n.translate("mute_all")
	mute.button_pressed = audio_muted
	mute.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(mute)
	
	var close := _button(I18n.translate("save_and_back"), GREEN, 220)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(close)
	
	master_slider.value_changed.connect(func(value: float) -> void:
		master_volume = value / 100.0
		master_value.text = "%d%%" % roundi(value)
		_apply_audio_settings()
	)

	music_slider.value_changed.connect(func(value: float) -> void:
		music_volume = value / 100.0
		music_value.text = "%d%%" % roundi(value)
		_apply_audio_settings()
	)
	
	sfx_slider.value_changed.connect(func(value: float) -> void:
		sfx_volume = value / 100.0
		sfx_value.text = "%d%%" % roundi(value)
		_apply_audio_settings()
	)
	
	sound_pack_select.item_selected.connect(func(index: int) -> void:
		sound_pack_id = AssetLibrary.set_sound_pack(str(sound_pack_select.get_item_metadata(index)))
		_reload_audio_players()
		_play_sfx("ui_click")
	)
	
	refresh_packs.pressed.connect(func() -> void:
		AssetLibrary.refresh_mod_catalog()
		sound_pack_id = _populate_option_button(sound_pack_select, AssetLibrary.available_sound_packs(), sound_pack_id)
		AssetLibrary.set_sound_pack(sound_pack_id)
		_reload_audio_players()
	)
	
	mute.toggled.connect(func(enabled: bool) -> void:
		audio_muted = enabled
		_apply_audio_settings()
	)
	
	close.pressed.connect(func() -> void:
		_save_progress()
		shade.queue_free()
	)

func _show_rules() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = I18n.translate("scoring_rules_title")
	dialog.dialog_text = I18n.translate("scoring_rules_text")
	dialog.min_size = Vector2i(550, 420)
	dialog.add_theme_font_size_override("font_size", 15)
	screen_layer.add_child(dialog)
	dialog.popup_centered()
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)

func _on_network_status_changed(msg: String) -> void:
	if is_instance_valid(developer_console) and developer_console.unlocked:
		developer_console.log_line(msg)
	if is_instance_valid(network_status_label):
		network_status_label.text = msg

func _on_network_opponent_connected(_peer_id: int, opponent_name: String) -> void:
	if is_instance_valid(network_status_label):
		network_status_label.text = I18n.translate("connected_to", [opponent_name])

func _on_network_lobby_changed(seats: Array, _network_target_score: int) -> void:
	if not is_instance_valid(lobby_seats_label):
		return
	var lines: Array[String] = []
	for index in range(NetworkSession.MAX_PLAYERS):
		if index < seats.size():
			var seat: Dictionary = seats[index]
			var suffix := ""
			if seat.is_bot:
				suffix = I18n.translate("bot_seat_suffix", [AssetLibrary.model_label(str(seat.get("avatar_id", "procedural")))])
			lines.append("%d. %s%s" % [index + 1, seat.nickname, suffix])
		else:
			lines.append(I18n.translate("free_seat_formatted", [index + 1, I18n.translate("free_seat")]))
	
	lobby_seats_label.text = "   •   ".join(lines)
	var host_controls := network_session.is_host
	lobby_add_bot_button.disabled = not host_controls or seats.size() >= NetworkSession.MAX_PLAYERS
	lobby_remove_bot_button.disabled = not host_controls or network_session.bots.is_empty()
	lobby_start_button.disabled = not host_controls or seats.size() < 2

func _on_network_match_started(config: Dictionary) -> void:
	current_menu = "network"
	game_token += 1
	tavern_background.visible = false
	world_container.visible = true
	tavern_world.clear_dice()
	_clear_screen()
	
	multiplayer_table = MultiplayerTable.new()
	multiplayer_table.developer_console = developer_console
	multiplayer_table.configure(network_session, tavern_world, config)
	multiplayer_table.leave_requested.connect(show_main_menu)
	multiplayer_table.sfx_requested.connect(_play_sfx)
	screen_layer.add_child(multiplayer_table)

func _on_network_session_ended(reason: String) -> void:
	if not is_instance_valid(multiplayer_table):
		return
	show_main_menu()
	if is_instance_valid(network_status_label):
		network_status_label.text = reason

func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String, color: Color, width: float = 0.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", CREAM)
	btn.add_theme_stylebox_override("normal", _panel_style(color, color.lightened(0.2), 2, 6))
	if width > 0.0:
		btn.custom_minimum_size.x = width
	btn.mouse_entered.connect(func() -> void: _play_sfx("ui_hover"))
	btn.pressed.connect(func() -> void: _play_sfx("ui_click"))
	return btn

func _panel_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.set_corner_radius_all(corner_radius)
	return style

func _populate_option_button(button: OptionButton, entries: Array, selected_id: String) -> String:
	button.clear()
	var selected_index := 0
	for index in range(entries.size()):
		var entry := entries[index] as Dictionary
		var label_text := I18n.translate(str(entry.label_key)) if entry.has("label_key") else str(entry.get("label", entry.get("id", "")))
		if label_text == STORY_TEXT.text("Domyślna postać") or label_text == "Default character":
			label_text = I18n.translate("default_character")
		button.add_item(label_text if not label_text.is_empty() else I18n.translate("option"))
		button.set_item_metadata(index, str(entry.get("id", "")))
		if str(entry.get("id", "")) == selected_id:
			selected_index = index
	
	if button.item_count == 0:
		button.add_item(I18n.translate("none"))
		button.set_item_metadata(0, "")
	
	button.select(selected_index)
	return str(button.get_item_metadata(selected_index))

func _mod_catalog_status(catalog: Dictionary) -> String:
	var model_count := maxi(0, (catalog.get("models", []) as Array).size() - 1)
	var pack_count := maxi(0, (catalog.get("sound_packs", []) as Array).size() - 1)
	var warning_count := (catalog.get("warnings", []) as Array).size()
	var status := I18n.translate("mods_detected", [model_count, pack_count])
	if warning_count > 0:
		status += I18n.translate("mods_warnings", [warning_count])
	return status

func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _panel_style(Color.TRANSPARENT, Color("#5a442e"), 1, 0))
	return sep

func _begin_campaign_tutorial() -> void:
	_capture_quick_match_settings()
	campaign_tutorial = true
	campaign_active = true
	campaign_current_index = 0
	campaign_checkpoint = {"chapter": 0, "section": "tutorial_match", "line": 0}
	player_loadout.assign([1, 1, 1, 1, 1, 1])
	bot_profile_id = "rookie"
	bot_difficulty = "easy"
	bot_name = STORY_TEXT.text("Staruszek")
	theme_id = "forest"
	target_score = 500
	_save_progress()
	start_game()
	var help := _label(STORY_TEXT.text("Staruszek: wybierz punktujące kości (1 = 100, 5 = 50, trójki).\nBankuj, by zachować punkty, lub rzuć pozostałymi. Farkle zabiera punkty tury. Cel: 500."), 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	help.position = Vector2(180, 80)
	help.size.x = 850
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(help)


func console_finish_match(player_won: bool) -> String:
	if current_menu == "network" and is_instance_valid(multiplayer_table):
		return multiplayer_table.console_finish_match(player_won)
	if current_menu != "game" or match_recorded:
		return STORY_TEXT.text("Brak aktywnego meczu.")
	if campaign_active:
		campaign_story["console_used"] = true
	if player_won:
		player_score = target_score
	else:
		bot_score = target_score
	dice_rolled = false
	_update_game_ui()
	_show_winner(player_won)
	return STORY_TEXT.text("Wygrana.") if player_won else STORY_TEXT.text("Przegrana.")


func _join_invitation(invitation: String) -> void:
	var endpoint := NetworkSession.parse_endpoint(invitation)
	show_main_menu()
	_show_multiplayer_lobby()
	if not endpoint.valid:
		network_status_label.text = str(endpoint.error)
		return
	network_session.join_game(invitation, player_name, NetworkSession.DEFAULT_PORT, player_loadout, player_avatar_id)


func _chronicle_resource(index: int, section: String, context: Dictionary) -> Resource:
	if section in ["prologue", "tutorial_victory", "tutorial_defeat"]:
		var sequence := CAMPAIGN_OPENING.build(section)
		if section == "prologue":
			var memory := _mother_memory()
			if not memory.is_empty():
				sequence.lines[2].text = memory + "\n" + sequence.lines[2].text
		return sequence
	if section == "epilogue":
		return CHRONICLES.epilogue(campaign_ending, context)
	if section in ["intro", "victory", "defeat"]:
		var sequence := CHRONICLES.build(index,section,context)
		if section in ["victory","defeat"]:
			var summary := STORY_TEXT.text("Nagroda: %d srebra. Sakiewka: %d.") % [int(context.get("last_reward",0)),int(context.get("silver",0))]
			if int(context.get("last_wager",0)) > 0:
				summary += STORY_TEXT.text(" Zwrot zakładu: %d (stawka: %d).") % [int(context.get("last_payout",0)),int(context.get("last_wager",0))]
			sequence.lines.append(CAMPAIGN_OPENING.line(summary))
		return sequence
	var sequence := DialogueSequence.new()
	sequence.title = STORY_TEXT.text("Kroniki Kostek — ") + CHRONICLES.name(index)
	var words := STORY_TEXT.text("Stawka czy czysta gra? Masz %d srebra.") % int(context.get("silver",0))
	if section == "seal":
		words = STORY_TEXT.text("Nie masz pięciuset. Masz brudne sto pięćdziesiąt i głodne oczy. Lubię to. Za tyle oddam pieczęć.") if int(context.get("silver",0)) >= 150 else STORY_TEXT.text("Nie zawracaj mi dupy, jak nie masz pieniędzy, [gołodupcu|gołodupico]. Albo grasz, albo idziesz do domu bez biletu na dwór.")
	elif section == "seal_route":
		words = STORY_TEXT.text("Trzymaj pieczęć. Miło było robić z tobą interesy. Możesz ruszyć dalej albo zostać przy stole i zagrać o honor.")
	elif section == "coronation":
		words = STORY_TEXT.text("Wybierz, kim jesteś, gdy kości milczą.") if index == 11 else STORY_TEXT.text("Możesz zakończyć tę kronikę albo ruszyć dalej. Korona nie musi być ostatnim stołem.")
	elif section == "wager_reply":
		words = STORY_TEXT.text("Stawka przyjęta. Siadaj, kości czekają.")
		if index == 1:
			words = STORY_TEXT.text("Hazard. Pachniesz mi cesarzem albo trupem. Lubię oba zapachy.")
		elif index == 4:
			words = STORY_TEXT.text("Hazard przy kluczu do wieży! Król by zemdlał. Dlatego stawiam.")
		elif index == 8 and int(context.get("pending_wager",0)) >= 500:
			words = STORY_TEXT.text("Pięćset. To już nie gra, to wojna w srebrze. Dobrze.")
	elif index == 12:
		words = STORY_TEXT.text("Gram o gulasz i 20 srebra albo o honor kotła. Możesz też ruszyć dalej.")
	var line := CAMPAIGN_OPENING.line(words,CHRONICLES.name(index))
	line.portrait_id = CAMPAIGN_CATALOG.chapter(index).get("avatar","procedural")
	line.portrait_side = "left"
	line.backdrop = CAMPAIGN_CATALOG.chapter(index).get("theme","tavern")
	for item in _chronicle_actions(index,section,context):
		var choice := CAMPAIGN_OPENING.choice(str(item.id),str(item.text))
		choice.ending_id = str(item.id)
		line.choices.append(choice)
	sequence.lines.append(line)
	return sequence

func _chronicle_actions(index: int, section: String, context: Dictionary) -> Array:
	var choices: Array = []
	if section == "seal":
		if int(context.get("silver",0)) >= 150:
			choices.append({"id":"buy_seal","text":STORY_TEXT.text("Zapłacę 150 srebra. Oddaj pieczęć."),"points":[0,-1,2,0],"flags":{"pieczec":true,"brudne_rece":true,"pomogl_zlodziejowi":true,"bought_seal":true},"silver":-150})
		choices.append({"id":"play","text":STORY_TEXT.text("Zagram o pieczęć."),"points":[0,0,0,1] if int(context.get("silver",0)) < 150 else [0,0,0,0]})
		choices.append({"id":"leave","text":STORY_TEXT.text("Wrócę później.")})
	elif section == "seal_route":
		choices = [{"id":"skip","text":STORY_TEXT.text("Pieczęć mam. Ruszam dalej.")},{"id":"play","text":STORY_TEXT.text("Zostanę. Zagram o honor.")}]
	elif section == "wager":
		var limit := mini(CAMPAIGN_CATALOG.wager_limit(index),int(context.get("silver",0)))
		if limit > 0:
			for amount in [mini(25,limit),limit]:
				var id := "wager_%d" % amount
				if choices.is_empty() or choices[0].id != id:
					choices.append({"id":id,"text":STORY_TEXT.text("Stawiam %d srebra. Wygrana: zwrot %d.") % [amount,amount * 2]})
		choices.append({"id":"wager_0","text":STORY_TEXT.text("Gram o honor kotła.") if index == 12 else STORY_TEXT.text("Gram bez stawki.")})
		choices.append({"id":"leave","text":STORY_TEXT.text("Może innym razem. Ruszam dalej.") if index == 12 else STORY_TEXT.text("Odejdę. Wrócę do stołu później.")})
	elif section == "coronation":
		var stage := "king" if index == 7 else "emperor" if index == 9 else "final"
		var descriptions := {"princess":STORY_TEXT.text("Koronę weźmie Elara. Ja wezmę fotel, miskę i zakaz budzenia przed południem."),"king":STORY_TEXT.text("Zostać [królem|królową]. Uczciwie, pracowicie, bez trupów na schodach."),"emperor":STORY_TEXT.text("Objąć cesarski tron. Cel uświęcił stół."),"world_champion":STORY_TEXT.text("Odrzucić tron. Iść od stołu do stołu. Nie przegrać."),"shadow":STORY_TEXT.text("Zejść z galerii. Teraz.")}
		for ending in CHRONICLES.endings(context,stage):
			choices.append({"id":"ending:" + ending,"text":descriptions[ending]})
		if stage != "final":
			choices.append({"id":"continue","text":STORY_TEXT.text("Korona to dopiero początek.") if stage == "king" else STORY_TEXT.text("To wciąż nie ten stół."),"points":[0,0,1,1] if stage == "king" else [0,0,0,2]})
			if stage == "king" and context.get("sojusz_vespera",false):
				choices.append({"id":"continue_shadow","text":STORY_TEXT.text("Koronę włożę. Cienie zostawię pod nią."),"points":[0,-1,1,0]})
	return choices

func _mother_memory() -> String:
	return {"kradziez":STORY_TEXT.text("Matylda: «W domu nie kradnie się od swoich.»"), "pobicie":STORY_TEXT.text("Matylda: «Pięściami nie naprawisz głodu. Wynocha.»"), "lenistwo":STORY_TEXT.text("Matylda: «Do południa chrapiesz, a kasza sama się nie ugotuje.»"), "obzarstwo":STORY_TEXT.text("Matylda: «Spiżarnia to nie twoja żona. Won.»"), "chciwosc":STORY_TEXT.text("Matylda: «[Liczyłeś|Liczyłaś] moje grosze głośniej niż pacierz.»")}.get(campaign_story.get("powod",""),"")

func _apply_chronicle_choice(index: int, section: String, id: String, context: Dictionary) -> void:
	if section == "prologue":
		if id in ["male","female"]:
			campaign_story["gender"] = id
		elif CHRONICLES.REASONS.has(id):
			if CHRONICLES.points_once(campaign_story,"prologue_reason",CHRONICLES.REASON_POINTS[id]):
				campaign_story["powod"] = CHRONICLES.REASONS[id]
			if is_instance_valid(active_dialogue):
				var line: Resource = active_dialogue.sequence.lines[2]
				line.text = _mother_memory() + "\n" + CAMPAIGN_OPENING.build("prologue").lines[2].text
		return
	var item := CHRONICLES.option(context,index,section,id) if section in ["intro","victory"] else {}
	if item.is_empty():
		for action in _chronicle_actions(index,section,context):
			if action.id == id:
				item = action
				break
	if item.is_empty() or section in ["wager","seal_route"] or id.begins_with("ending:") or id == "leave":
		return
	if id == "buy_seal":
		if campaign_story.get("bought_seal",false) or campaign_economy.silver < 150:
			return
		if CHRONICLES.points_once(campaign_story,"seal_purchase",[0,-1,2,0]):
			campaign_economy.silver -= 150
			campaign_story.merge({"pieczec":true,"brudne_rece":true,"pomogl_zlodziejowi":true,"bought_seal":true},true)
		return
	campaign_economy.silver += CHRONICLES.apply_choice(campaign_story,index,section,item)

func _after_chronicle_dialogue(index: int, section: String, result: String) -> void:
	match section:
		"prologue": _begin_campaign_tutorial()
		"tutorial_victory", "tutorial_defeat": _continue_campaign()
		"epilogue": _show_campaign_screen()
		"intro":
			if index == 1 and campaign_story.get("cien_rozmowa","") == "targ" and not campaign_story.get("bought_seal",false):
				_show_campaign_dialogue(index,"seal")
			elif index == 1 and campaign_story.get("bought_seal",false):
				_show_campaign_dialogue(index,"seal_route")
			elif CAMPAIGN_CATALOG.wager_limit(index) > 0:
				_show_campaign_dialogue(index,"wager")
			else:
				_begin_campaign_match(index)
		"seal":
			if result == "buy_seal" and campaign_story.get("bought_seal",false):
				_show_campaign_dialogue(index,"seal_route")
			elif result == "play":
				_show_campaign_dialogue(index,"wager")
			else:
				_show_campaign_screen()
		"seal_route":
			if result == "skip" and campaign_story.get("pieczec",false):
				campaign_progress = CAMPAIGN_CATALOG.advance(campaign_progress,1)
				campaign_story.passed["1"] = true
				_save_progress()
				_continue_campaign()
			else:
				_show_campaign_dialogue(index,"wager")
		"wager":
			if result.begins_with("wager_"):
				var amount := int(result.trim_prefix("wager_"))
				if amount > 0:
					campaign_story["pending_wager"] = amount
					_show_campaign_dialogue(index,"wager_reply")
				else:
					_begin_campaign_match(index)
			else:
				if index == 12:
					campaign_story.passed["12"] = true
					CHRONICLES.points_once(campaign_story,"gromek_leave",[1,0,-1,-1])
					_save_progress()
					_continue_campaign()
				else:
					_show_campaign_screen()
		"wager_reply":
			var amount := int(campaign_story.get("pending_wager",0))
			campaign_story.erase("pending_wager")
			_begin_campaign_match(index,amount)
		"victory", "defeat":
			if section == "victory" and index in [7,9,11] and not campaign_story.get("finished",false):
				campaign_story["pending_ending"] = "king" if index == 7 else "emperor" if index == 9 else "final"
				_save_progress()
				_show_campaign_dialogue(index,"coronation")
			else:
				_continue_campaign()
		"coronation":
			if result.begins_with("ending:"):
				var ending := result.trim_prefix("ending:")
				var stage := "king" if index == 7 else "emperor" if index == 9 else "final"
				if ending in CHRONICLES.endings(campaign_story,stage):
					campaign_ending = ending
					campaign_story["finished"] = true
					campaign_story.erase("pending_ending")
					_check_achievements()
					_save_progress()
					_show_campaign_dialogue(index,"epilogue")
			else:
				campaign_story.erase("pending_ending")
				_save_progress()
				_continue_campaign()

func _finish_chronicles_match(won: bool) -> void:
	if match_recorded:
		return
	match_recorded = true
	game_token += 1
	dice_rolled = false
	if campaign_tutorial:
		campaign_tutorial = false
		campaign_story.merge({"prologue_done":true,"porridge":true,"ticket":true},true)
		CHRONICLES.points_once(campaign_story,"tutorial",[0,0,1,1] if won else [1,0,0,0])
		campaign_checkpoint.clear()
		_show_campaign_dialogue(0,"tutorial_victory" if won else "tutorial_defeat")
		return
	matches_played += 1
	if won:
		matches_won += 1
		_commit_winning_player_learning()
	var wager := campaign_economy.active_wager
	var payout := campaign_economy.settle_wager(won)
	var outcome := CHRONICLES.record_result(campaign_story,campaign_current_index,won)
	campaign_economy.silver += int(outcome.reward)
	if outcome.advance and campaign_current_index < 12:
		campaign_progress = CAMPAIGN_CATALOG.advance(campaign_progress,campaign_current_index)
	campaign_story["last_reward"] = int(outcome.reward)
	campaign_story["last_payout"] = payout
	campaign_story["last_wager"] = wager
	_check_achievements()
	campaign_checkpoint.clear()
	_save_progress()
	_show_campaign_dialogue(campaign_current_index,"victory" if won else "defeat")

func _check_achievements() -> void:
	var added := achievements.evaluate(campaign_story,campaign_ending)
	if added.is_empty():
		return
	var names: Array[String] = []
	for item in ACHIEVEMENTS.ITEMS:
		if item.id in added:
			names.append(STORY_TEXT.text(str(item.name)))
	var overlay := CanvasLayer.new()
	overlay.layer = 110
	add_child(overlay)
	var message := _label(STORY_TEXT.text("OSIĄGNIĘCIE: ") + ", ".join(names),18,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message.offset_top = 12
	message.offset_bottom = 48
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(message)
	var timer := Timer.new()
	timer.one_shot = true
	overlay.add_child(timer)
	timer.timeout.connect(overlay.queue_free)
	timer.start(4.0)

func _show_achievements() -> void:
	_prepare_menu_screen()
	current_menu = "achievements"
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + side,40)
	screen_layer.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	box.add_child(_label(STORY_TEXT.text("OSIĄGNIĘCIA • %d / %d") % [achievements.unlocked.size(),ACHIEVEMENTS.ITEMS.size()],28,GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",18)
	scroll.add_child(list)
	for item in ACHIEVEMENTS.ITEMS:
		var unlocked := achievements.unlocked.has(item.id)
		var hidden: bool = item.get("hidden",false) and not unlocked
		var title: String = STORY_TEXT.text("Ukryte osiągnięcie") if hidden else STORY_TEXT.text(item.name)
		var description: String = STORY_TEXT.text("W kronikach pozostało jeszcze coś do odkrycia.") if hidden else STORY_TEXT.text(item.description)
		var line := _label(("✓ " if unlocked else "○ ") + title + "\n" + description,18,GOLD if unlocked else MUTED)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(line)
	var back := _button(I18n.translate("back_to_menu"),GREEN,240)
	back.pressed.connect(show_main_menu)
	box.add_child(back)
