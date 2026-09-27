class_name VisualNovelDialogue
extends Control

signal finished
signal choice_selected(choice_id: String)
signal line_changed(line_index: int)

const ASSET_LIBRARY := preload("res://scripts/asset_library.gd")

@export var sequence: Resource

var _line_index := -1
var _full_text := ""
var _visible_characters := 0.0
var _characters_per_second := 42.0
var _typing := false
var _ending := false
var result_id := ""
var _current_lines: Array = []
var _section := "intro"

var story_gender := "male"
var _illustration: TextureRect
var _backdrop: ColorRect
var _title_label: Label
var _speaker_label: Label
var _text_label: Label
var _next_button: Button
var _skip_button: Button
var _portrait_container: SubViewportContainer
var _portrait_viewport: SubViewport
var _portrait_root: Node3D
var _dialogue_panel: PanelContainer
var _choice_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	if sequence != null:
		play(sequence)


func play(dialogue_sequence: Resource, section: String = "intro", start_line: int = 0) -> void:
	sequence = dialogue_sequence
	_section = section
	_line_index = start_line - 1
	_ending = false
	result_id = ""
	var section_property := "%s_lines" % section
	_current_lines = sequence.get(section_property) if sequence.get(section_property) is Array else []
	if _current_lines.is_empty():
		_current_lines = sequence.get("lines") if sequence.get("lines") is Array else []
	var title_key := str(sequence.get("title_key"))
	var raw_title := str(sequence.get("title"))
	_title_label.text = _translate(title_key) if not title_key.is_empty() else raw_title
	_skip_button.visible = bool(sequence.get("allow_skip"))
	_show_next_line()


func finish_dialogue(ending_id: String = "") -> void:
	if _ending:
		return
	if ending_id.is_empty():
		if not bool(sequence.get("allow_skip")):
			return
		for index in range(maxi(0, _line_index), _current_lines.size()):
			if not (_current_lines[index].get("choices") as Array).is_empty():
				_line_index = index - 1
				_show_next_line()
				_advance()
				return
	_ending = true
	_typing = false
	if not ending_id.is_empty():
		result_id = ending_id
	finished.emit()

func refresh_language() -> void:
	_skip_button.text = _translate("dialogue_skip")
	play(sequence, _section, _line_index)


func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_characters += delta * _characters_per_second
	_text_label.visible_characters = mini(int(_visible_characters), _full_text.length())
	if _text_label.visible_characters >= _full_text.length():
		_typing = false
		_after_text_revealed()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode in [KEY_SPACE, KEY_ENTER]:
		_advance()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE:
		if bool(sequence.get("allow_skip")):
			finish_dialogue()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _typing:
		_typing = false
		_text_label.visible_characters = -1
		_after_text_revealed()
		return
	if _choice_box.get_child_count() > 0:
		return
	if _is_last_line():
		finish_dialogue()
	else:
		var jump := int(_current_lines[_line_index].get("next_line_index"))
		if jump >= 0:
			_line_index = jump - 1
		_show_next_line()


func _show_next_line() -> void:
	_line_index += 1
	if _line_index >= _current_lines.size():
		finish_dialogue()
		return
	_clear_choices()
	var line := _current_lines[_line_index] as Resource
	_dialogue_panel.anchor_top = 0.25 if (line.get("choices") as Array).size() > 3 else 0.45
	_dialogue_panel.anchor_bottom = 0.95 if (line.get("choices") as Array).size() > 3 else 0.90
	var speaker_key := str(line.get("speaker_key"))
	var raw_speaker := str(line.get("speaker"))
	var speaker_text := _translate(speaker_key) if not speaker_key.is_empty() else raw_speaker
	_speaker_label.text = speaker_text if not speaker_text.is_empty() else _translate("dialogue_narrator")
	var text_key := str(line.get("text_key"))
	_full_text = _translate(text_key) if not text_key.is_empty() else str(line.get("text"))
	_full_text = _gender_text(_full_text)
	_speaker_label.text = _gender_text(_speaker_label.text)
	_illustration.texture = line.get("illustration")
	_illustration.visible = _illustration.texture != null
	_characters_per_second = maxf(10.0, float(line.get("characters_per_second")))
	_visible_characters = 0.0
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_typing = true
	_next_button.text = _translate("dialogue_next")
	_apply_backdrop(str(line.get("backdrop")))
	_show_portrait(str(line.get("portrait_id")), str(line.get("portrait_side")))
	line_changed.emit(_line_index)


func _is_last_line() -> bool:
	return _line_index >= _current_lines.size() - 1


func _after_text_revealed() -> void:
	var line := _current_lines[_line_index] as Resource
	var choices: Array = line.get("choices") if line.get("choices") is Array else []
	if not choices.is_empty():
		_next_button.visible = false
		for choice_resource in choices:
			var choice := choice_resource as Resource
			var choice_key := str(choice.get("text_key"))
			var choice_text := _translate(choice_key) if not choice_key.is_empty() else str(choice.get("text"))
			var button := Button.new()
			button.text = _gender_text(choice_text)
			button.custom_minimum_size.y = 36
			button.add_theme_color_override("font_color", Color("#f1e7cf"))
			button.add_theme_stylebox_override("normal", _panel_style(Color("#4b3827"), Color("#9b753f"), 2, 6))
			button.pressed.connect(_select_choice.bind(choice))
			_choice_box.add_child(button)
		return
	_next_button.visible = true
	_next_button.text = _translate("dialogue_end") if _is_last_line() else _translate("dialogue_next")


func _select_choice(choice: Resource) -> void:
	var choice_id := str(choice.get("id"))
	if choice_id in ["male", "female"]:
		story_gender = choice_id
	choice_selected.emit(choice_id)
	var ending_id := str(choice.get("ending_id"))
	if not ending_id.is_empty():
		finish_dialogue(ending_id)
		return
	var next_index := int(choice.get("next_line_index"))
	if next_index >= 0 and next_index < _current_lines.size():
		_line_index = next_index - 1
	_clear_choices()
	_show_next_line()


func _clear_choices() -> void:
	for child in _choice_box.get_children():
		_choice_box.remove_child(child)
		child.queue_free()
	_next_button.visible = true


func _apply_backdrop(backdrop_id: String) -> void:
	match backdrop_id:
		"royal":
			_backdrop.color = Color("#10172deF")
		"forest":
			_backdrop.color = Color("#0b1d12ef")
		_:
			_backdrop.color = Color("#1d100bef")


func _show_portrait(model_id: String, side: String) -> void:
	if is_instance_valid(_portrait_root):
		_portrait_root.queue_free()
		_portrait_root = null
	var show_portrait := not model_id.is_empty() and side != "narrator"
	_portrait_container.visible = show_portrait
	if not show_portrait:
		return
	_portrait_container.anchor_left = 0.68 if side == "right" else 0.06
	_portrait_container.anchor_right = 0.94 if side == "right" else 0.32
	var avatar := ASSET_LIBRARY.instantiate_avatar(model_id)
	if avatar == null:
		_portrait_container.visible = false
		return
	_portrait_root = avatar
	_portrait_viewport.add_child(avatar)


func _build_interface() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color("#1d100bef")
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_illustration = TextureRect.new()
	_illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_illustration)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.015, 0.01, 0.34)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	_title_label = Label.new()
	_title_label.anchor_left = 0.12
	_title_label.anchor_right = 0.88
	_title_label.offset_top = 22
	_title_label.offset_bottom = 66
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color("#e3bd62"))
	add_child(_title_label)

	_portrait_container = SubViewportContainer.new()
	_portrait_container.anchor_left = 0.06
	_portrait_container.anchor_top = 0.09
	_portrait_container.anchor_right = 0.32
	_portrait_container.anchor_bottom = 0.68
	_portrait_container.stretch = true
	_portrait_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_container)
	_portrait_viewport = SubViewport.new()
	_portrait_viewport.size = Vector2i(360, 430)
	_portrait_viewport.transparent_bg = true
	_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_portrait_container.add_child(_portrait_viewport)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.75, 5.2)
	camera.fov = 38
	camera.current = true
	_portrait_viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.72, 0))
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-32, -28, 0)
	key_light.light_color = Color("#f2d5a0")
	key_light.light_energy = 1.45
	_portrait_viewport.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2.2, 2.5, 2.7)
	fill_light.light_color = Color("#8298c4")
	fill_light.light_energy = 3.2
	fill_light.omni_range = 8.0
	_portrait_viewport.add_child(fill_light)

	var dialogue_panel := PanelContainer.new()
	_dialogue_panel = dialogue_panel
	dialogue_panel.anchor_left = 0.07
	dialogue_panel.anchor_top = 0.45
	dialogue_panel.anchor_right = 0.93
	dialogue_panel.anchor_bottom = 0.90
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color("#21150ff2"), Color("#a77a3e"), 3, 14))
	add_child(dialogue_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	dialogue_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 20)
	_speaker_label.add_theme_color_override("font_color", Color("#e3bd62"))
	box.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", Color("#f1e7cf"))
	box.add_child(_text_label)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 5)
	box.add_child(_choice_box)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 12)
	box.add_child(button_row)
	_skip_button = Button.new()
	_skip_button.text = _translate("dialogue_skip")
	_skip_button.flat = true
	_skip_button.add_theme_color_override("font_color", Color("#b8a98e"))
	_skip_button.pressed.connect(finish_dialogue)
	button_row.add_child(_skip_button)
	_next_button = Button.new()
	_next_button.text = _translate("dialogue_next")
	_next_button.custom_minimum_size.x = 150
	_next_button.add_theme_color_override("font_color", Color("#f1e7cf"))
	_next_button.add_theme_stylebox_override("normal", _panel_style(Color("#6f5430"), Color("#b58a48"), 2, 7))
	_next_button.pressed.connect(_advance)
	button_row.add_child(_next_button)


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


func _translate(key: String) -> String:
	var i18n := get_node_or_null("/root/I18n")
	if i18n != null and i18n.has_method("translate"):
		return str(i18n.call("translate", key))
	return key

func _gender_text(value: String) -> String:
	var pattern := RegEx.new()
	pattern.compile("\\[([^|\\]]+)\\|([^\\]]+)\\]")
	for found in pattern.search_all(value):
		value = value.replace(found.get_string(), found.get_string(2 if story_gender == "female" else 1))
	return value
