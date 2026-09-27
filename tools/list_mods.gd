extends SceneTree


func _init() -> void:
	var catalog := AssetLibrary.refresh_mod_catalog()
	print("MODELE (%d):" % catalog.models.size())
	for model: Dictionary in catalog.models:
		print("  %s -> %s" % [model.id, model.path])
	print("PACZKI DŹWIĘKÓW (%d):" % catalog.sound_packs.size())
	for pack: Dictionary in catalog.sound_packs:
		print("  %s -> %s" % [pack.id, pack.path])
	for warning in catalog.warnings:
		print("UWAGA: %s" % warning)
	quit(0)
