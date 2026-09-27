extends SceneTree


func _init() -> void:
	var catalog := AssetLibrary.refresh_mod_catalog()
	var failures := 0
	for model: Dictionary in catalog.models:
		if model.id == "procedural":
			continue
		var instance := AssetLibrary.instantiate_avatar(str(model.id))
		if instance == null:
			failures += 1
			printerr("BŁĄD MODELU: %s (%s)" % [model.label, model.path])
		else:
			root.add_child(instance)
			var stats := _model_stats(instance)
			print("OK MODEL: %s — siatki: %d, rozmiar: %s" % [model.label, stats.meshes, stats.size])
			if int(stats.meshes) == 0:
				failures += 1
				printerr("BŁĄD MODELU: brak MeshInstance3D w %s" % model.path)
			root.remove_child(instance)
			instance.free()
	for pack: Dictionary in catalog.sound_packs:
		if pack.id == "builtin":
			continue
		AssetLibrary.set_sound_pack(str(pack.id))
		var loaded := 0
		for sound_name in ["dice_roll", "die_select", "coin_bank", "farkle", "win_fanfare", "ui_click", "ui_hover"]:
			if AssetLibrary.load_sound(sound_name) != null:
				loaded += 1
		print("OK DŹWIĘKI: %s (%d/7 z fallbackiem)" % [pack.label, loaded])
	AssetLibrary.set_sound_pack("builtin")
	for warning in AssetLibrary.last_warnings:
		print("OSTRZEŻENIE: %s" % warning)
	if failures > 0:
		quit(1)
		return
	print("PASS: wszystkie wykryte mody można wczytać")
	quit(0)


func _model_stats(node: Node3D) -> Dictionary:
	var result := {"bounds": AABB(), "has_bounds": false, "meshes": 0}
	_collect_model_stats(node, Transform3D.IDENTITY, result)
	var bounds: AABB = result.bounds
	return {"meshes": result.meshes, "size": bounds.size if result.has_bounds else Vector3.ZERO}


func _collect_model_stats(node: Node, parent_transform: Transform3D, result: Dictionary) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform *= (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			var transformed_box := current_transform * mesh_instance.get_aabb()
			result.bounds = result.bounds.merge(transformed_box) if result.has_bounds else transformed_box
			result.has_bounds = true
			result.meshes = int(result.meshes) + 1
	for child in node.get_children():
		_collect_model_stats(child, current_transform, result)
