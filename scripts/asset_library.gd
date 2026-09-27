class_name AssetLibrary
extends RefCounted

const PACKAGED_ROOT := "res://assets"
const LEGACY_SOUND_ROOT := "res://sounds"
const MOD_MANIFEST := "mod.json"
const PROCEDURAL_AVATAR_FACTORY := preload("res://scripts/procedural_avatar_factory.gd")
const BUILTIN_AVATARS := [
	{"id": "builtin:woman", "label_key": "model_woman"},
	{"id": "builtin:innkeeper", "label_key": "model_innkeeper"},
	{"id": "builtin:king", "label_key": "model_king"},
	{"id": "builtin:thief", "label_key": "model_thief"},
	{"id": "builtin:homeless", "label_key": "model_homeless"},
	{"id": "builtin:princess", "label_key": "model_princess"},
	{"id": "builtin:madman", "label_key": "model_madman"},
	{"id": "builtin:knight", "label_key": "model_knight"},
	{"id": "builtin:monk", "label_key": "model_monk"},
	{"id": "builtin:merchant", "label_key": "model_merchant"},
	{"id": "builtin:bard", "label_key": "model_bard"},
	{"id": "builtin:witch", "label_key": "model_witch"}
]

static var active_sound_pack_id := "builtin"
static var mods_enabled := true  # NOWE: Flaga włączania/wyłączania modów
static var _catalog := {}
static var last_warnings: Array[String] = []

# NOWE: Funkcja do ustawiania stanu modów i odświeżania katalogu
static func set_mods_enabled(enabled: bool) -> void:
	mods_enabled = enabled
	refresh_mod_catalog()

static func external_root() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(PACKAGED_ROOT)
	return OS.get_executable_path().get_base_dir().path_join("assets")

static func mods_root() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://mods")
	return OS.get_executable_path().get_base_dir().path_join("mods")

static func refresh_mod_catalog() -> Dictionary:
	last_warnings.clear()
	var models: Array[Dictionary] = [
		{"id": "procedural", "label_key": "default_character", "path": "", "mod": "Gra"}
	]
	for builtin: Dictionary in BUILTIN_AVATARS:
		models.append({"id": builtin.id, "label_key": builtin.label_key, "path": "", "mod": "Gra"})
	var sound_packs: Array[Dictionary] = [
		{"id": "builtin", "label": "Domyślne dźwięki", "path": "", "mod": "Gra"}
	]
	var seen_models := {"procedural": true}
	for builtin: Dictionary in BUILTIN_AVATARS:
		seen_models[builtin.id] = true
	var seen_packs := {"builtin": true}
	
	_scan_asset_models(external_root().path_join("models"), "asset", "Własne assety", models, seen_models)
	if not OS.has_feature("editor"):
		_scan_asset_models(PACKAGED_ROOT.path_join("models"), "asset_packed", "Assety w PCK", models, seen_models)
	
	# NOWE: Skanuj mody tylko jeśli są włączone
	if mods_enabled:
		for root_path in [mods_root(), ProjectSettings.globalize_path("user://mods")]:
			_scan_mod_root(root_path, models, sound_packs, seen_models, seen_packs)
	else:
		last_warnings.append("Mody są wyłączone w ustawieniach głównych.")
		
	_catalog = {"models": models, "sound_packs": sound_packs, "warnings": last_warnings.duplicate()}
	return _catalog.duplicate(true)

static func available_player_models() -> Array:
	return refresh_mod_catalog().models

static func available_sound_packs() -> Array:
	return refresh_mod_catalog().sound_packs

static func has_model(model_id: String) -> bool:
	for entry: Dictionary in _ensure_catalog().models:
		if entry.id == model_id:
			return true
	return false

static func model_label(model_id: String) -> String:
	for entry: Dictionary in _ensure_catalog().models:
		if entry.id == model_id:
			return _translate(str(entry.label_key)) if entry.has("label_key") else str(entry.label)
	return _translate("default_character")

static func has_sound_pack(pack_id: String) -> bool:
	for entry: Dictionary in _ensure_catalog().sound_packs:
		if entry.id == pack_id:
			return true
	return false

static func set_sound_pack(pack_id: String) -> String:
	active_sound_pack_id = pack_id if has_sound_pack(pack_id) else "builtin"
	return active_sound_pack_id

static func load_sound(sound_name: String) -> AudioStream:
	var safe_name := sound_name.get_file().get_basename()
	if active_sound_pack_id != "builtin":
		for pack: Dictionary in _ensure_catalog().sound_packs:
			if pack.id == active_sound_pack_id:
				for extension in ["ogg", "mp3"]:
					var mod_path: String = str(pack.path).path_join("%s.%s" % [safe_name, extension])
					var mod_stream := _load_external_sound(mod_path)
					if mod_stream:
						return mod_stream
				break
	var external_path := external_root().path_join("sounds").path_join("%s.ogg" % safe_name)
	var external_stream := _load_external_sound(external_path)
	if external_stream:
		return external_stream
	for resource_path in [
		PACKAGED_ROOT.path_join("sounds").path_join("%s.ogg" % safe_name),
		LEGACY_SOUND_ROOT.path_join("%s.ogg" % safe_name)
	]:
		if ResourceLoader.exists(resource_path):
			return load(resource_path) as AudioStream
	return null

static func instantiate_model(model_name: String) -> Node3D:
	var safe_name := model_name.get_file().get_basename()
	for extension in ["glb", "gltf"]:
		var external_path := external_root().path_join("models").path_join("%s.%s" % [safe_name, extension])
		var external_model := _load_model_path(external_path)
		if external_model:
			return external_model
		var packaged_path := PACKAGED_ROOT.path_join("models").path_join("%s.%s" % [safe_name, extension])
		var packaged_model := _load_model_path(packaged_path)
		if packaged_model:
			return packaged_model
	return null

static func instantiate_avatar(model_id: String) -> Node3D:
	if model_id == "procedural":
		return null
	if model_id.begins_with("builtin:"):
		return PROCEDURAL_AVATAR_FACTORY.create(model_id.trim_prefix("builtin:"))
	for model: Dictionary in _ensure_catalog().models:
		if model.id == model_id:
			return _load_model_path(str(model.path))
	return null

static func _translate(key: String) -> String:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		var i18n := scene_tree.root.get_node_or_null("I18n")
		if i18n != null and i18n.has_method("translate"):
			return str(i18n.call("translate", key))
	return key

static func _ensure_catalog() -> Dictionary:
	return refresh_mod_catalog() if _catalog.is_empty() else _catalog

static func _load_external_sound(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_warn_once("Nie można otworzyć dźwięku: %s" % path)
		return null
	var header := file.get_buffer(4)
	if header.size() >= 4 and header[0] == 0x4f and header[1] == 0x67 and header[2] == 0x67 and header[3] == 0x53:
		return AudioStreamOggVorbis.load_from_file(path)
	var is_mp3 := header.size() >= 3 and header[0] == 0x49 and header[1] == 0x44 and header[2] == 0x33
	if not is_mp3 and header.size() >= 2:
		is_mp3 = header[0] == 0xff and (header[1] & 0xe0) == 0xe0
	if is_mp3:
		if path.get_extension().to_lower() != "mp3":
			_warn_once("%s zawiera MP3 mimo rozszerzenia .ogg; najlepiej zmień nazwę na .mp3." % path)
		file.seek(0)
		return AudioStreamMP3.load_from_buffer(file.get_buffer(file.get_length()))
	_warn_once("Nieobsługiwany lub uszkodzony plik audio: %s" % path)
	return null

static func _load_model_path(path: String) -> Node3D:
	if path.is_empty():
		return null
	var extension := path.get_extension().to_lower()
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		return scene.instantiate() as Node3D if scene else null
	if not FileAccess.file_exists(path):
		return null
	if extension == "fbx":
		var fbx_document := FBXDocument.new()
		var fbx_state := FBXState.new()
		if fbx_document.append_from_file(path, fbx_state) == OK:
			return fbx_document.generate_scene(fbx_state)
	elif extension in ["glb", "gltf"]:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		if document.append_from_file(path, state) == OK:
			return document.generate_scene(state)
	return null

static func _scan_mod_root(root_path: String, models: Array, sound_packs: Array, seen_models: Dictionary, seen_packs: Dictionary) -> void:
	var root := DirAccess.open(root_path)
	if root == null:
		return
	for folder in root.get_directories():
		if folder.begins_with("."):
			continue
		var mod_path := root_path.path_join(folder)
		var metadata := _read_manifest(mod_path.path_join(MOD_MANIFEST))
		if not bool(metadata.get("enabled", true)):
			continue
		var mod_name := str(metadata.get("name", folder)).left(48)
		_validate_manifest(metadata, mod_name)
		var mod_id := _safe_id(folder)
		var sounds_path := _find_named_directory(mod_path, "sounds")
		var pack_id := "mod:%s" % mod_id
		if not sounds_path.is_empty() and not seen_packs.has(pack_id) and _directory_has_extension(sounds_path, ["ogg", "mp3"]):
			sound_packs.append({"id": pack_id, "label": "%s — paczka moda" % mod_name, "path": sounds_path, "mod": mod_name})
			seen_packs[pack_id] = true
		var models_path := _find_named_directory(mod_path, "models")
		if not models_path.is_empty():
			_scan_asset_models(models_path, "mod:%s" % mod_id, mod_name, models, seen_models)
	for archive_name in root.get_files():
		if archive_name.get_extension().to_lower() == "zip":
			_warn_once("Archiwum %s trzeba najpierw rozpakować." % root_path.path_join(archive_name))

static func _scan_asset_models(path: String, id_prefix: String, mod_name: String, models: Array, seen_models: Dictionary) -> void:
	_scan_model_directory(path, path, id_prefix, mod_name, models, seen_models)

static func _scan_model_directory(root_path: String, path: String, id_prefix: String, mod_name: String, models: Array, seen_models: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension not in ["glb", "gltf", "fbx"]:
			continue
		var base_name := file_name.get_basename()
		var relative_name := path.path_join(base_name).trim_prefix(root_path.path_join(""))
		var model_id := "%s:%s" % [id_prefix, _safe_id(relative_name.replace("/", "_"))]
		if seen_models.has(model_id):
			continue
		models.append({
			"id": model_id,
			"label": "%s — %s" % [base_name.capitalize(), mod_name],
			"path": path.path_join(file_name),
			"mod": mod_name
		})
		seen_models[model_id] = true
	for child_directory in directory.get_directories():
		if not child_directory.begins_with("."):
			_scan_model_directory(root_path, path.path_join(child_directory), id_prefix, mod_name, models, seen_models)

static func _directory_has_extension(path: String, extensions: Array) -> bool:
	var directory := DirAccess.open(path)
	if directory == null:
		return false
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() in extensions:
			return true
	return false

static func _find_named_directory(parent_path: String, wanted_name: String) -> String:
	var directory := DirAccess.open(parent_path)
	if directory == null:
		return ""
	for child_name in directory.get_directories():
		if child_name.strip_edges().to_lower() == wanted_name:
			if child_name != wanted_name:
				_warn_once("Folder '%s' ma zbędne spacje; oczekiwano '%s'." % [child_name, wanted_name])
			return parent_path.path_join(child_name)
	return ""

static func _validate_manifest(metadata: Dictionary, mod_name: String) -> void:
	if metadata.is_empty():
		_warn_once("Mod '%s' nie ma pliku mod.json z informacją o licencji." % mod_name)
		return
	for field in ["author", "license", "source_url"]:
		if str(metadata.get(field, "")).strip_edges().is_empty():
			_warn_once("Mod '%s': uzupełnij pole '%s' przed publikacją." % [mod_name, field])

static func _warn_once(message: String) -> void:
	if message not in last_warnings:
		last_warnings.append(message)

static func _read_manifest(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _safe_id(value: String) -> String:
	var result := ""
	for character in value.to_lower():
		if character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			result += character
	return result if not result.is_empty() else "mod"
