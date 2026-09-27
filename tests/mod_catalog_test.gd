extends SceneTree


func _init() -> void:
	var mod_root := ProjectSettings.globalize_path("user://mods/test_pack_model")
	DirAccess.make_dir_recursive_absolute(mod_root.path_join("sounds"))
	DirAccess.make_dir_recursive_absolute(mod_root.path_join("models"))
	var manifest := FileAccess.open(mod_root.path_join("mod.json"), FileAccess.WRITE)
	manifest.store_string('{"name":"Testowa paczka","license":"CC0-1.0","enabled":true}')
	manifest.close()
	var source_sound := ProjectSettings.globalize_path("res://assets/sounds/ui_click.ogg")
	var target_sound := mod_root.path_join("sounds/ui_click.ogg")
	var source := FileAccess.open(source_sound, FileAccess.READ)
	var target := FileAccess.open(target_sound, FileAccess.WRITE)
	target.store_buffer(source.get_buffer(source.get_length()))
	source.close()
	target.close()
	var model_file := FileAccess.open(mod_root.path_join("models/test_hero.gltf"), FileAccess.WRITE)
	model_file.store_string('{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"TestHero"}]}')
	model_file.close()

	var catalog := AssetLibrary.refresh_mod_catalog()
	for builtin: Dictionary in AssetLibrary.BUILTIN_AVATARS:
		_expect(_contains_id(catalog.models, str(builtin.id)), "model wbudowany %s w katalogu" % builtin.id)
		var builtin_avatar := AssetLibrary.instantiate_avatar(str(builtin.id))
		_expect(builtin_avatar != null, "tworzenie modelu wbudowanego %s" % builtin.id)
		if builtin_avatar != null:
			_expect(str(builtin_avatar.get_meta("builtin_archetype", "")) == str(builtin.id).trim_prefix("builtin:"), "tożsamość modelu %s" % builtin.id)
			builtin_avatar.free()
	_expect(_contains_id(catalog.sound_packs, "mod:test_pack_model"), "wykrycie paczki OGG")
	_expect(_contains_id(catalog.models, "mod:test_pack_model:test_hero"), "wykrycie modelu GLTF")
	var avatar := AssetLibrary.instantiate_avatar("mod:test_pack_model:test_hero")
	_expect(avatar != null, "ładowanie modelu z moda")
	avatar.free()
	_expect(AssetLibrary.set_sound_pack("mod:test_pack_model") == "mod:test_pack_model", "wybór paczki")
	_expect(AssetLibrary.load_sound("ui_click") != null, "ładowanie OGG z moda")
	# Brakujący efekt ma wrócić do domyślnego assetu.
	_expect(AssetLibrary.load_sound("dice_roll") != null, "fallback brakującego dźwięku")
	AssetLibrary.set_sound_pack("builtin")
	print("PASS: 12 modeli wbudowanych, modele GLB i wymienne dźwięki OGG")
	quit(0)


func _contains_id(entries: Array, wanted_id: String) -> bool:
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) == wanted_id:
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	if condition:
		return
	printerr("FAIL: %s" % label)
	quit(1)
