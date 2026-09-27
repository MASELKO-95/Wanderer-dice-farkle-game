class_name TavernBackdrop
extends Control

var theme_id := "tavern"

func set_theme_id(value: String) -> void:
	theme_id = value if value in ["tavern", "royal", "forest"] else "tavern"
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var palette := {
		"background": Color("#160d09"), "wall_a": Color("#332016"),
		"wall_b": Color("#2b1a12"), "beam": Color("#160e0a"),
		"table": Color("#432718"), "edge": Color("#704226"), "glow": Color(0.93, 0.52, 0.18, 0.01)
	}
	if theme_id == "royal":
		palette = {"background": Color("#0b1020"), "wall_a": Color("#26304a"), "wall_b": Color("#1c263d"), "beam": Color("#171320"), "table": Color("#4b2a22"), "edge": Color("#a6813f"), "glow": Color(0.45, 0.62, 1.0, 0.01)}
	elif theme_id == "forest":
		palette = {"background": Color("#09130d"), "wall_a": Color("#263326"), "wall_b": Color("#1d291f"), "beam": Color("#101a12"), "table": Color("#30351f"), "edge": Color("#596137"), "glow": Color(0.55, 0.85, 0.48, 0.01)}
	draw_rect(Rect2(Vector2.ZERO, size), palette.background)
	var wall_height := size.y * 0.57
	for strip in range(12):
		var y := float(strip) * wall_height / 12.0
		var shade: Color = palette.wall_a if strip % 2 == 0 else palette.wall_b
		draw_rect(Rect2(0, y, size.x, wall_height / 12.0 + 1), shade)
	for beam_x in [0.08, 0.50, 0.92]:
		draw_rect(Rect2(size.x * beam_x - 15, 0, 30, wall_height), palette.beam)

	for radius in range(240, 20, -20):
		var alpha := 0.004 + float(240 - radius) / 50000.0
		var glow: Color = palette.glow
		glow.a = alpha
		draw_circle(Vector2(size.x * 0.5, size.y * 0.24), radius, glow)

	var table_top := wall_height - 12.0
	draw_rect(Rect2(0, table_top, size.x, size.y - table_top), palette.table)
	for plank in range(9):
		var plank_y := table_top + float(plank) * (size.y - table_top) / 9.0
		draw_line(Vector2(0, plank_y), Vector2(size.x, plank_y), Color(0.10, 0.05, 0.02, 0.65), 2.0)
	for grain in range(18):
		var gx := fmod(float(grain * 173), size.x)
		var gy := table_top + fmod(float(grain * 67), maxf(1.0, size.y - table_top))
		draw_line(Vector2(gx, gy), Vector2(minf(size.x, gx + 110), gy + sin(float(grain)) * 4), Color(0.20, 0.10, 0.05, 0.32), 2.0)

	draw_rect(Rect2(0, table_top - 8, size.x, 13), palette.edge)
	draw_line(Vector2(0, table_top - 7), Vector2(size.x, table_top - 7), Color("#a16b37"), 2.0)
