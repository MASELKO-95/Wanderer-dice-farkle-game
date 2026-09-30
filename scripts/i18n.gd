extends Node

const STORY_TEXT := preload("res://scripts/story_text.gd")

signal language_changed

var current_locale: String = "pl"
var _translations: Dictionary = {}
var _fallback_chain: Array[String] = ["en", "pl"]

func _ready() -> void:
	_migrate_previous_game_saves()
	_load_translations()
	var saved: String = _load_setting("locale", "pl")
	set_language(saved)

func _migrate_previous_game_saves() -> void:
	var marker := "user://wanderer_save_migration.done"
	if FileAccess.file_exists(marker):
		return
	var previous_dir := OS.get_user_data_dir().get_base_dir().path_join("Farkle Dice game")
	var succeeded := true
	if DirAccess.dir_exists_absolute(previous_dir):
		for filename in DirAccess.get_files_at(previous_dir):
			if not filename.ends_with(".cfg") and not ".cfg.deleted-" in filename:
				continue
			var destination := "user://" + filename
			if FileAccess.file_exists(destination):
				continue
			var result := DirAccess.copy_absolute(previous_dir.path_join(filename), ProjectSettings.globalize_path(destination))
			if result != OK:
				succeeded = false
				push_warning("Could not migrate save: %s (error %d)" % [filename, result])
	if succeeded:
		var file := FileAccess.open(marker, FileAccess.WRITE)
		if file != null:
			file.store_string("Migrated from Farkle Dice game\n")

func set_language(locale: String) -> void:
	current_locale = locale
	STORY_TEXT.locale = "pl" if locale == "pl" else "en"
	_save_setting("locale", locale)
	language_changed.emit()

func translate(key: String, args: Array = []) -> String:
	var text: String = _lookup(key, "pl" if current_locale == "pl" else "en")
	if text.is_empty():
		for fb: String in _fallback_chain:
			text = _lookup(key, fb)
			if not text.is_empty():
				break
	if text.is_empty():
		text = key
	
	# Bezpieczne formatowanie - tylko jeśli są argumenty
	if not args.is_empty():
		var arg_count := args.size()
		var placeholder_count := _count_placeholders(text)
		
		if placeholder_count > 0:
			# Jeśli liczba argumentów nie pasuje, użyj tylko tylu, ile jest placeholderów
			var args_to_use: Array = []
			for i in range(mini(arg_count, placeholder_count)):
				args_to_use.append(args[i])
			
			# Jeśli nadal nie pasuje, zwróć tekst bez formatowania
			if args_to_use.size() == placeholder_count:
				text = text % args_to_use
	
	return text

func _count_placeholders(text: String) -> int:
	var count := 0
	var i := 0
	while i < text.length():
		if text[i] == "%":
			if i + 1 < text.length():
				var next_char := text[i + 1]
				if next_char in ["d", "s", "f", "i"]:
					count += 1
					i += 2
					continue
		i += 1
	return count

func _lookup(key: String, locale: String) -> String:
	if _translations.has(locale):
		var lang_dict: Dictionary = _translations[locale]
		if lang_dict.has(key):
			return str(lang_dict[key])
	return ""

func _load_translations() -> void:
	var path: String = "res://translation/translations.json"
	print("DEBUG: Sprawdzam ścieżkę: ", path)
	print("DEBUG: Czy plik istnieje? ", FileAccess.file_exists(path))
	
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file:
			var json := JSON.new()
			var text := file.get_as_text()
			print("DEBUG: Długość pliku: ", text.length(), " znaków")
			var error: int = json.parse(text)
			if error == OK:
				_translations = json.data
				print("DEBUG: Pomyślnie załadowano języki: ", _translations.keys())
			else:
				print("DEBUG: Błąd parsowania JSON w linii ", json.get_error_line(), ": ", json.get_error_message())
		else:
			print("DEBUG: Nie udało się otworzyć pliku do odczytu (brak uprawnień?).")
	else:
		print("DEBUG: Plik NIE ISTNIEJE pod ścieżką: ", path)
		if FileAccess.file_exists("res://translations.json"):
			print("DEBUG: UWAGA! Plik istnieje jako 'translations.json' (z 's' na końcu) w głównym folderze!")
			
func get_available_languages() -> Array[String]:
	var result: Array[String] = []
	for key: String in _translations.keys():
		result.append(key)
	return result

func get_language_name(locale: String) -> String:
	var names := {
		"pl": "🇵🇱 Polski", 
		"en": "🇬🇧 English", 
		"it": "🇮🇹 Italiano",
		"cs": "🇨🇿 Čeština", 
		"sk": "🇸🇰 Slovenčina", 
		"hu": "🇭🇺 Magyar",
		"lt": "🇱🇹 Lietuvių", 
		"be": "Беларуская (БЧБ)", # Ikona biało-czerwono-białej flagi jest ustawiana w menu.
		"ga": "🇮🇪 Gaeilge",
		"pt": "🇵🇹 Português", 
		"fr": "🇫🇷 Français", 
		"ja": "🇯🇵 日本語", 
		"zh": "🇨🇳 中文"
	}
	return str(names.get(locale, locale)) + (" (English)" if locale not in ["pl", "en"] else "")

func _save_setting(key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("i18n", key, value)
	cfg.save("user://settings.cfg")

func _load_setting(key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		return cfg.get_value("i18n", key, default)
	return default
