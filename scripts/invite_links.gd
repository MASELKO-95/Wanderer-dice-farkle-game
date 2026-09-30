extends RefCounted

const STORY_TEXT := preload("res://scripts/story_text.gd")

const PREFIX := "wanderer-farkle://join/"
const SCHEME := "wanderer-farkle"
const DESKTOP_FILE := "io.wanderer.Farkle.desktop"

static func make_link(address: String) -> String:
	var code := NetworkSession.make_room_code(address)
	return PREFIX + code if not code.is_empty() else ""

static func startup_invitation(arguments: PackedStringArray) -> String:
	for index in range(arguments.size()):
		var argument := arguments[index]
		if argument.to_lower().begins_with(SCHEME + ":"):
			return argument
		if argument == "--join" and index + 1 < arguments.size():
			return arguments[index + 1]
	return ""

static func desktop_entry(executable: String) -> String:
	# Escape the Exec argument, then the desktop-entry string value.
	var quoted := executable.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$").replace("`", "\\`").replace("%", "%%")
	quoted = quoted.replace("\\", "\\\\")
	return "[Desktop Entry]\nType=Application\nName=Wanderer Farkle\nNoDisplay=true\nTerminal=false\nExec=\"%s\" -- %%u\nMimeType=x-scheme-handler/%s;\n" % [quoted, SCHEME]

static func windows_command(executable: String) -> String:
	return '"' + executable.replace("/", "\\") + '" -- "%1"'

static func register_handler() -> String:
	if OS.has_feature("editor"):
		return STORY_TEXT.text("Uruchom wyeksportowaną grę, aby włączyć otwieranie zaproszeń.")
	var executable := OS.get_executable_path()
	if "\n" in executable or "\r" in executable:
		return STORY_TEXT.text("Nie można zarejestrować tej ścieżki gry.")
	match OS.get_name():
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			var data_dir := OS.get_environment("XDG_DATA_HOME")
			if not data_dir.is_absolute_path():
				data_dir = OS.get_environment("HOME").path_join(".local/share")
			var applications := data_dir.path_join("applications")
			if DirAccess.make_dir_recursive_absolute(applications) != OK:
				return STORY_TEXT.text("Nie można utworzyć katalogu aplikacji.")
			var file := FileAccess.open(applications.path_join(DESKTOP_FILE), FileAccess.WRITE)
			if file == null:
				return STORY_TEXT.text("Nie można zapisać obsługi zaproszeń.")
			file.store_string(desktop_entry(executable))
			file.close()
			var output: Array = []
			var result := OS.execute("xdg-mime", ["default", DESKTOP_FILE, "x-scheme-handler/" + SCHEME], output, true)
			if result != 0:
				return STORY_TEXT.text("Nie udało się ustawić obsługi linków (xdg-mime). Nadal możesz wkleić link w lobby.")
		"Windows":
			var key := "HKCU\\Software\\Classes\\" + SCHEME
			var commands := [
				["add", key, "/ve", "/t", "REG_SZ", "/d", "URL:Wanderer Farkle Invitation", "/f"],
				["add", key, "/v", "URL Protocol", "/t", "REG_SZ", "/d", "", "/f"],
				["add", key + "\\shell\\open\\command", "/ve", "/t", "REG_SZ", "/d", windows_command(executable), "/f"]
			]
			for arguments in commands:
				if OS.execute("reg.exe", PackedStringArray(arguments)) != 0:
					return STORY_TEXT.text("Nie można zarejestrować obsługi linków w Windows.")
		_:
			return STORY_TEXT.text("Na tym systemie wklej link w polu dołączania w lobby.")
	return STORY_TEXT.text("Obsługa zaproszeń włączona. Po przeniesieniu gry włącz ją ponownie.")
