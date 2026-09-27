extends SceneTree


func _init() -> void:
	var lines: Array[String] = [
		"This game uses Godot Engine.",
		"https://godotengine.org/license",
		"",
		"GODOT ENGINE LICENSE",
		"",
		Engine.get_license_text(),
		"",
		"THIRD-PARTY COMPONENTS INCLUDED BY GODOT",
		""
	]
	for component: Dictionary in Engine.get_copyright_info():
		lines.append(str(component.get("name", "Unnamed component")))
		for part: Dictionary in component.get("parts", []):
			for copyright_line in part.get("copyright", []):
				lines.append("Copyright: %s" % copyright_line)
			lines.append("License: %s" % part.get("license", "Unknown"))
		lines.append("")
	var license_info: Dictionary = Engine.get_license_info()
	for license_name in license_info:
		lines.append("===== %s =====" % license_name)
		lines.append(str(license_info[license_name]))
		lines.append("")
	var file := FileAccess.open("res://GODOT_COPYRIGHT.txt", FileAccess.WRITE)
	if file == null:
		printerr("Nie można zapisać GODOT_COPYRIGHT.txt")
		quit(1)
		return
	file.store_string("\n".join(lines))
	file.close()
	print("Wygenerowano GODOT_COPYRIGHT.txt")
	quit(0)
