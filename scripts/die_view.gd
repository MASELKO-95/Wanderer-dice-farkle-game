class_name DieView
extends Control

signal die_pressed(index: int)

var die_index := 0
var value := 1
var selected := false
var locked := false
var style_id := 0
var hovered := false

const PALETTES := [
	{"face": Color("#777064"), "edge": Color("#403b34"), "pip": Color("#251f1a"), "shine": Color("#999184")},
	{"face": Color("#eee0bb"), "edge": Color("#9f7d47"), "pip": Color("#352719"), "shine": Color("#fff6da")},
	{"face": Color("#a87951"), "edge": Color("#5b3c28"), "pip": Color("#2a1810"), "shine": Color("#c69a70")},
	{"face": Color("#5a2028"), "edge": Color("#d0a94a"), "pip": Color("#f4d985"), "shine": Color("#843641")},
	{"face": Color("#c99a45"), "edge": Color("#f0cf72"), "pip": Color("#3b2410"), "shine": Color("#f6d986")},
	{"face": Color("#547f9d"), "edge": Color("#b9d3de"), "pip": Color("#ecdfac"), "shine": Color("#87acc3")},
	{"face": Color("#46634c"), "edge": Color("#d0a94a"), "pip": Color("#f4e4aa"), "shine": Color("#709477")},
	{"face": Color("#ebe1ca"), "edge": Color("#a83e36"), "pip": Color("#7f241e"), "shine": Color("#fff8e9")}
]

const PIP_POSITIONS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.30, 0.30), Vector2(0.70, 0.70)],
	3: [Vector2(0.28, 0.28), Vector2(0.50, 0.50), Vector2(0.72, 0.72)],
	4: [Vector2(0.30, 0.30), Vector2(0.70, 0.30), Vector2(0.30, 0.70), Vector2(0.70, 0.70)],
	5: [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.50, 0.50), Vector2(0.28, 0.72), Vector2(0.72, 0.72)],
	6: [Vector2(0.30, 0.25), Vector2(0.70, 0.25), Vector2(0.30, 0.50), Vector2(0.70, 0.50), Vector2(0.30, 0.75), Vector2(0.70, 0.75)]
}


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	custom_minimum_size = Vector2(88, 88)


func configure(new_index: int, new_value: int, new_style: int, is_locked := false) -> void:
	die_index = new_index
	value = new_value
	style_id = new_style
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	queue_redraw()


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	queue_redraw()


func _on_mouse_entered() -> void:
	if not locked:
		hovered = true
		queue_redraw()


func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if not locked and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		die_pressed.emit(die_index)
		accept_event()


func _draw() -> void:
	var palette: Dictionary = PALETTES[clampi(style_id, 0, PALETTES.size() - 1)]
	var lift := 5.0 if selected else (2.0 if hovered else 0.0)
	var rect := Rect2(5, 7 - lift, size.x - 10, size.y - 13)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.07, 0.035, 0.015, 0.55)
	shadow.corner_radius_top_left = 14
	shadow.corner_radius_top_right = 14
	shadow.corner_radius_bottom_left = 14
	shadow.corner_radius_bottom_right = 14
	draw_style_box(shadow, Rect2(rect.position + Vector2(2, 7), rect.size))

	var face := StyleBoxFlat.new()
	face.bg_color = palette.face.lightened(0.08) if hovered else palette.face
	face.border_color = Color("#e0bc54") if selected else palette.edge
	face.set_border_width_all(4 if selected else 3)
	face.corner_radius_top_left = 14
	face.corner_radius_top_right = 14
	face.corner_radius_bottom_left = 14
	face.corner_radius_bottom_right = 14
	draw_style_box(face, rect)

	draw_line(rect.position + Vector2(13, 8), rect.position + Vector2(rect.size.x - 13, 8), palette.shine, 2.0, true)
	if style_id > 0:
		var mark_color: Color = palette.edge.lightened(0.18)
		if style_id == 1:
			draw_arc(rect.get_center(), rect.size.x * 0.34, -2.4, -0.7, 12, mark_color, 1.5)
		elif style_id == 2:
			draw_circle(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5), rect.size.x * 0.39, Color.TRANSPARENT, false, 1.4)
		elif style_id == 3:
			draw_line(rect.position + Vector2(11, rect.size.y - 9), rect.end - Vector2(11, rect.size.y - 9), mark_color, 1.4)
		elif style_id == 4:
			draw_arc(rect.get_center(), rect.size.x * 0.39, 0.0, TAU, 24, mark_color, 1.5)
		elif style_id >= 5:
			draw_line(rect.position + Vector2(rect.size.x * 0.5, 7), rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 7), mark_color, 1.5)
			draw_line(rect.position + Vector2(rect.size.x * 0.34, rect.size.y * 0.33), rect.position + Vector2(rect.size.x * 0.66, rect.size.y * 0.33), mark_color, 1.5)
	var radius := clampf(minf(rect.size.x, rect.size.y) * 0.067, 4.0, 7.0)
	for pip_position: Vector2 in PIP_POSITIONS[value]:
		var point := rect.position + Vector2(rect.size.x * pip_position.x, rect.size.y * pip_position.y)
		draw_circle(point + Vector2(1.5, 2.0), radius, Color(0.05, 0.02, 0.01, 0.30))
		draw_circle(point, radius, palette.pip)
		draw_circle(point - Vector2(radius * 0.25, radius * 0.25), radius * 0.25, palette.pip.lightened(0.30))
