@tool
class_name TavernWorld
extends Node3D

const DIE_COLORS := [
	Color("#777064"),
	Color("#ddd0aa"),
	Color("#a87951"),
	Color("#6d1f2a"),
	Color("#c99a45"),
	Color("#547f9d"),
	Color("#315e3e"),
	Color("#d6c293")
]
const PIP_COLORS := [
	Color("#251f1a"),
	Color("#241911"),
	Color("#2b160d"),
	Color("#ead379"),
	Color("#3b2410"),
	Color("#e8dcae"),
	Color("#ead379"),
	Color("#8e211e")
]
const PIP_PATTERNS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]
}
const AVATAR_HEIGHT := 3.2

var camera: Camera3D
var left_arm: Node3D
var right_arm: Node3D
var opponent: Node3D
var opponent_throw_arm: Node3D
var opponent_head: Node3D
var side_opponents: Array[Node3D] = []
var custom_avatars: Array[Node3D] = []
var custom_player_avatar: Node3D
var candle_lights: Array[OmniLight3D] = []
var dice_nodes: Array[Node3D] = []
var dice_rest_positions: Array[Vector3] = []
var look_offset := Vector2.ZERO
var flicker_time := 0.0
var rng := RandomNumberGenerator.new()
var random_decoration_count := 0
var scene_environment: Environment
var moon_light: DirectionalLight3D
var theme_id := "tavern"


func _ready() -> void:
	rng.randomize()
	_build_environment()
	if not _add_asset_model("tavern"):
		_build_room()
		_build_props()
		_build_random_medieval_decorations()
	if not _add_asset_model("table"):
		_build_table()
	_build_opponent()
	_build_player_arms()
	_build_camera()


func _process(delta: float) -> void:
	flicker_time += delta
	for index in range(candle_lights.size()):
		var light := candle_lights[index]
		light.light_energy = 2.25 + sin(flicker_time * 8.0 + index * 2.1) * 0.18 + sin(flicker_time * 17.0) * 0.07
	if is_instance_valid(opponent_head):
		opponent_head.rotation.y = sin(flicker_time * 0.55) * 0.025


func configure_player_count(count: int) -> void:
	var opponent_count := clampi(count - 1, 0, 3)
	if is_instance_valid(opponent):
		opponent.visible = opponent_count >= 1
	for index in range(side_opponents.size()):
		side_opponents[index].visible = index + 1 < opponent_count


func configure_theme(value: String) -> void:
	theme_id = value if value in ["tavern", "royal", "forest"] else "tavern"
	if not is_instance_valid(scene_environment) or not is_instance_valid(moon_light):
		return
	match theme_id:
		"royal":
			scene_environment.background_color = Color("#090d1b")
			scene_environment.ambient_light_color = Color("#6f7fa6")
			moon_light.light_color = Color("#9eb7e5")
			moon_light.light_energy = 0.48
		"forest":
			scene_environment.background_color = Color("#07110a")
			scene_environment.ambient_light_color = Color("#547357")
			moon_light.light_color = Color("#91b69a")
			moon_light.light_energy = 0.30
		_:
			scene_environment.background_color = Color("#100a08")
			scene_environment.ambient_light_color = Color("#8b6543")
			moon_light.light_color = Color("#8093ad")
			moon_light.light_energy = 0.35


func configure_solo_appearance(player_style: Dictionary, bot_style: Dictionary) -> void:
	_apply_arm_appearance(left_arm, player_style)
	_apply_arm_appearance(right_arm, player_style)
	_apply_avatar_appearance(opponent, bot_style)


func _apply_arm_appearance(arm: Node3D, style: Dictionary) -> void:
	if not is_instance_valid(arm):
		return
	var sleeve := arm.find_child("Sleeve", true, false) as MeshInstance3D
	var hand := arm.find_child("Hand", true, false) as MeshInstance3D
	if sleeve:
		sleeve.material_override = _material(_appearance_color("tunic", str(style.get("tunic", "brown"))), 0.92)
	if hand:
		hand.material_override = _material(_appearance_color("skin", str(style.get("skin", "fair"))), 0.88)


func _apply_avatar_appearance(avatar: Node3D, style: Dictionary) -> void:
	if not is_instance_valid(avatar):
		return
	for raw_mesh in avatar.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw_mesh as MeshInstance3D
		if mesh.name in ["Torso", "Sleeve"]:
			mesh.material_override = _material(_appearance_color("tunic", str(style.get("tunic", "brown"))), 0.94)
		elif mesh.name in ["Head", "Hand"]:
			mesh.material_override = _material(_appearance_color("skin", str(style.get("skin", "fair"))), 0.90)
		elif mesh.name == "Hair":
			mesh.material_override = _material(_appearance_color("hair", str(style.get("hair", "brown"))), 0.98)


func _appearance_color(category: String, value: String) -> Color:
	var colors := {
		"skin": {"fair": Color("#c58b68"), "warm": Color("#ad7350"), "olive": Color("#947052"), "dark": Color("#67452f")},
		"tunic": {"brown": Color("#68412a"), "moss": Color("#44543a"), "wine": Color("#6d2f3a"), "navy": Color("#31445c"), "gold": Color("#8a6b2d")},
		"hair": {"brown": Color("#2b1b12"), "black": Color("#111012"), "auburn": Color("#65311f"), "gray": Color("#77736d")}
	}
	var group: Dictionary = colors.get(category, {})
	return group.get(value, Color.WHITE)


func configure_table_seats(seats: Array, local_peer_id: int) -> void:
	for avatar in custom_avatars:
		if is_instance_valid(avatar):
			avatar.queue_free()
	custom_avatars.clear()
	custom_player_avatar = null
	if is_instance_valid(left_arm):
		left_arm.visible = true
	if is_instance_valid(right_arm):
		right_arm.visible = true
	var placeholders: Array[Node3D] = [opponent]
	placeholders.append_array(side_opponents)
	for placeholder in placeholders:
		placeholder.visible = false
	var opponents: Array[Dictionary] = []
	for raw_seat in seats:
		var seat := raw_seat as Dictionary
		if int(seat.get("peer_id", 0)) == local_peer_id:
			_configure_first_person_avatar(str(seat.get("avatar_id", "procedural")))
		else:
			opponents.append(seat)
	for index in range(mini(opponents.size(), placeholders.size())):
		var placeholder := placeholders[index]
		var model_id := str(opponents[index].get("avatar_id", "procedural"))
		var custom_model := AssetLibrary.instantiate_avatar(model_id)
		if custom_model == null:
			placeholder.visible = true
			continue
		var avatar_anchor := Node3D.new()
		avatar_anchor.name = "ModAvatar_%d" % index
		avatar_anchor.position = placeholder.position
		avatar_anchor.rotation = placeholder.rotation
		add_child(avatar_anchor)
		avatar_anchor.add_child(custom_model)
		_fit_avatar_to_seat(custom_model)
		_pose_table_avatar(custom_model)
		custom_avatars.append(avatar_anchor)


func _fit_avatar_to_seat(avatar: Node3D) -> void:
	var result := {"bounds": AABB(), "has_bounds": false}
	_collect_avatar_bounds(avatar, Transform3D.IDENTITY, result)
	if not result.has_bounds:
		return
	var bounds: AABB = result.bounds
	if bounds.size.y <= 0.001:
		return
	var factor := AVATAR_HEIGHT / bounds.size.y
	avatar.scale *= factor
	var center := bounds.get_center()
	avatar.position += Vector3(-center.x * factor, -bounds.position.y * factor, -center.z * factor)


func _collect_avatar_bounds(node: Node, parent_transform: Transform3D, result: Dictionary) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform *= (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			var transformed_box := current_transform * mesh_instance.get_aabb()
			result.bounds = result.bounds.merge(transformed_box) if result.has_bounds else transformed_box
			result.has_bounds = true
	for child in node.get_children():
		_collect_avatar_bounds(child, current_transform, result)


func _configure_first_person_avatar(model_id: String) -> void:
	var avatar := AssetLibrary.instantiate_avatar(model_id)
	if avatar == null:
		return
	var anchor := Node3D.new()
	anchor.name = "FirstPersonAvatar"
	# Punkt bazowy jest dokładnie pod kamerą; właściwe odsunięcie zależy od
	# głębokości konkretnego modelu i jest liczone poniżej.
	# Osiem centymetrów przed środkiem kamery kompensuje jej near plane:
	# nos nadal jest odcinany, ale prawidłowo ustawione dłonie wychodzą w kadr.
	anchor.position = Vector3(camera.position.x, 0, camera.position.z - 0.10)
	anchor.rotation_degrees.y = 180.0
	add_child(anchor)
	anchor.add_child(avatar)
	_fit_avatar_to_seat(avatar)
	_hide_first_person_head(avatar)
	_pose_first_person_arms(avatar)
	_place_avatar_behind_camera(avatar)
	var visible_custom_hands := _custom_hands_in_front(avatar)
	left_arm.visible = not bool(visible_custom_hands.left)
	right_arm.visible = not bool(visible_custom_hands.right)
	custom_player_avatar = anchor
	custom_avatars.append(anchor)


func _place_avatar_behind_camera(avatar: Node3D) -> void:
	var result := {"bounds": AABB(), "has_bounds": false}
	_collect_avatar_bounds(avatar, Transform3D.IDENTITY, result)
	if not result.has_bounds:
		return
	var bounds: AABB = result.bounds
	# Model źródłowy patrzy w +Z. Po obrocie kotwicy o 180° jego +Z wskazuje
	# w stronę stołu. Cofnięcie całej bryły o jej przednią krawędź umieszcza
	# kamerę tuż przed nosem niezależnie od proporcji FBX/GLTF.
	avatar.position.z -= bounds.end.z + 0.08


func _custom_hands_in_front(avatar: Node3D) -> Dictionary:
	var result := {"left": false, "right": false}
	if not is_instance_valid(camera):
		return result
	for raw_skeleton in avatar.find_children("*", "Skeleton3D", true, false):
		var skeleton := raw_skeleton as Skeleton3D
		for side in ["left", "right"]:
			var candidates: Array = (
				["Wrist_L", "Hand_L", "LeftHand", "mixamorig:LeftHand"]
				if side == "left"
				else ["Wrist_R", "Hand_R", "RightHand", "mixamorig:RightHand"]
			)
			for candidate in candidates:
				var bone_index := skeleton.find_bone(candidate)
				if bone_index < 0:
					continue
				var wrist_world := skeleton.to_global(skeleton.get_bone_global_pose(bone_index).origin)
				result[side] = camera.to_local(wrist_world).z < -0.12
				break
	return result


func _hide_first_person_head(avatar: Node3D) -> void:
	for raw_mesh in avatar.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw_mesh as MeshInstance3D
		var lower_name := mesh.name.to_lower()
		if (
			"face" in lower_name
			or "eye" in lower_name
			or "hair" in lower_name
			or "mayu" in lower_name
			or "head" in lower_name
		):
			mesh.visible = false


func _pose_first_person_arms(avatar: Node3D) -> void:
	for raw_skeleton in avatar.find_children("*", "Skeleton3D", true, false):
		var skeleton := raw_skeleton as Skeleton3D
		_pose_bone(skeleton, ["Arm_L", "UpperArm_L", "upper_arm.L"], Vector3(0, -80, 10))
		_pose_bone(skeleton, ["Elbow_L", "ForeArm_L", "forearm.L"], Vector3.ZERO)
		_pose_bone(skeleton, ["Arm_R", "UpperArm_R", "upper_arm.R"], Vector3(0, 80, -10))
		_pose_bone(skeleton, ["Elbow_R", "ForeArm_R", "forearm.R"], Vector3.ZERO)


func _pose_table_avatar(avatar: Node3D) -> void:
	for raw_skeleton in avatar.find_children("*", "Skeleton3D", true, false):
		var skeleton := raw_skeleton as Skeleton3D
		_pose_bone(skeleton, ["Arm_L", "UpperArm_L", "upper_arm.L"], Vector3(0, -72, -42))
		_pose_bone(skeleton, ["Elbow_L", "ForeArm_L", "forearm.L"], Vector3(0, -12, 0))
		_pose_bone(skeleton, ["Arm_R", "UpperArm_R", "upper_arm.R"], Vector3(0, 72, 42))
		_pose_bone(skeleton, ["Elbow_R", "ForeArm_R", "forearm.R"], Vector3(0, 12, 0))


func _pose_bone(skeleton: Skeleton3D, names: Array[String], degrees: Vector3) -> void:
	var bone_index := -1
	for candidate in names:
		bone_index = skeleton.find_bone(candidate)
		if bone_index >= 0:
			break
	if bone_index < 0:
		return
	var rotation := Quaternion.from_euler(Vector3(
		deg_to_rad(degrees.x),
		deg_to_rad(degrees.y),
		deg_to_rad(degrees.z)
	))
	skeleton.set_bone_pose_rotation(bone_index, rotation)


func _add_asset_model(model_name: String) -> bool:
	var model := AssetLibrary.instantiate_model(model_name)
	if model == null:
		return false
	model.name = "Custom%s" % model_name.capitalize()
	add_child(model)
	return true


func nudge_look(relative: Vector2) -> void:
	look_offset.x = clampf(look_offset.x - relative.x * 0.0028, -0.42, 0.42)
	look_offset.y = clampf(look_offset.y - relative.y * 0.0024, -0.20, 0.22)
	_update_camera_look()


func reset_look() -> void:
	var tween := create_tween()
	tween.tween_method(func(value: Vector2) -> void:
		look_offset = value
		_update_camera_look()
	, look_offset, Vector2.ZERO, 0.35)


func clear_dice() -> void:
	for die in dice_nodes:
		if is_instance_valid(die):
			die.queue_free()
	dice_nodes.clear()
	dice_rest_positions.clear()


func throw_dice(values: Array[int], types: Array[int], by_opponent := false) -> void:
	clear_dice()
	reset_look()
	if by_opponent:
		_animate_opponent_throw()
	else:
		_animate_arms()
	var count := values.size()
	for index in range(count):
		var type_index := types[index] if index < types.size() else 0
		var die := _create_die(type_index)
		add_child(die)
		dice_nodes.append(die)
		var row_offset := -0.34 if index % 2 == 0 else 0.34
		var final_position := Vector3((float(index) - float(count - 1) * 0.5) * 0.72, 1.09, row_offset + rng.randf_range(-0.10, 0.10))
		dice_rest_positions.append(final_position)
		var throw_origin_z := -1.42 if by_opponent else 2.45
		die.position = Vector3((-0.42 if index % 2 == 0 else 0.42) + rng.randf_range(-0.12, 0.12), 1.38, throw_origin_z + rng.randf_range(-0.12, 0.12))
		die.rotation = Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))

		var delay := index * 0.035
		var flight := die.create_tween()
		flight.tween_interval(delay)
		var arc_z := -0.45 if by_opponent else 0.85
		flight.tween_property(die, "position", Vector3(final_position.x * 0.55, 2.25 + rng.randf_range(0.0, 0.35), arc_z), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(die, "position", final_position, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_property(die, "position", final_position + Vector3(0, 0.10, 0), 0.08).set_trans(Tween.TRANS_SINE)
		flight.tween_property(die, "position", final_position, 0.10).set_trans(Tween.TRANS_SINE)

		var final_rotation := _rotation_for_top_value(values[index])
		final_rotation.y += rng.randf_range(-PI, PI)
		var spin_rotation := final_rotation + Vector3(TAU * rng.randi_range(1, 3), TAU * rng.randi_range(1, 3), TAU * rng.randi_range(1, 3))
		var spin := die.create_tween()
		spin.tween_interval(delay)
		spin.tween_property(die, "rotation", spin_rotation, 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spin.tween_property(die, "rotation", final_rotation, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.05).timeout


func set_dice_selected(indices: Array[int]) -> void:
	for index in range(dice_nodes.size()):
		var die := dice_nodes[index]
		var picked := index in indices
		var target_position := dice_rest_positions[index] + (Vector3(0, 0.16, 0) if picked else Vector3.ZERO)
		var target_scale := Vector3.ONE * (1.12 if picked else 1.0)
		var tween := die.create_tween().set_parallel(true)
		tween.tween_property(die, "position", target_position, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(die, "scale", target_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func die_at_screen_position(screen_position: Vector2, source_viewport_size: Vector2) -> int:
	if not is_instance_valid(camera) or source_viewport_size.x <= 0.0 or source_viewport_size.y <= 0.0:
		return -1
	var own_size := camera.get_viewport().get_visible_rect().size
	var scaled_position := Vector2(
		screen_position.x * own_size.x / source_viewport_size.x,
		screen_position.y * own_size.y / source_viewport_size.y
	)
	var closest_index := -1
	var closest_distance := 82.0
	for index in range(dice_nodes.size()):
		var die := dice_nodes[index]
		if not is_instance_valid(die) or camera.is_position_behind(die.global_position):
			continue
		var projected := camera.unproject_position(die.global_position)
		var distance := projected.distance_to(scaled_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	return closest_index


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	scene_environment = Environment.new()
	scene_environment.background_mode = Environment.BG_COLOR
	scene_environment.background_color = Color("#100a08")
	scene_environment.background_energy_multiplier = 0.55
	scene_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	scene_environment.ambient_light_color = Color("#8b6543")
	scene_environment.ambient_light_energy = 0.38
	scene_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	scene_environment.glow_enabled = true
	world_environment.environment = scene_environment
	add_child(world_environment)

	moon_light = DirectionalLight3D.new()
	moon_light.rotation_degrees = Vector3(-48, -32, 0)
	moon_light.light_color = Color("#8093ad")
	moon_light.light_energy = 0.35
	moon_light.shadow_enabled = true
	add_child(moon_light)
	configure_theme(theme_id)


func _build_room() -> void:
	var plaster := _material(Color("#4a3428"), 0.94)
	var dark_wood := _wood_material(Color("#2a160d"), Color("#4c2b17"))
	_add_box("Floor", Vector3(12, 0.25, 11), Vector3(0, -0.18, 0), _wood_material(Color("#2e1b12"), Color("#55331d")))
	_add_box("BackWall", Vector3(12, 6, 0.28), Vector3(0, 2.8, -4.5), plaster)
	_add_box("LeftWall", Vector3(0.28, 6, 9), Vector3(-6, 2.8, 0), plaster)
	_add_box("RightWall", Vector3(0.28, 6, 9), Vector3(6, 2.8, 0), plaster)
	for x in [-5.4, -2.7, 0.0, 2.7, 5.4]:
		_add_box("WallBeam", Vector3(0.22, 6, 0.42), Vector3(x, 2.8, -4.32), dark_wood)
	for y in [0.35, 3.25, 5.55]:
		_add_box("CrossBeam", Vector3(12, 0.24, 0.42), Vector3(0, y, -4.31), dark_wood)
	_add_box("CeilingBeam", Vector3(0.35, 0.35, 9), Vector3(-2.7, 5.45, 0), dark_wood)
	_add_box("CeilingBeam", Vector3(0.35, 0.35, 9), Vector3(2.7, 5.45, 0), dark_wood)


func _build_table() -> void:
	var table_wood := _wood_material(Color("#4b2916"), Color("#83502a"))
	_add_box("TableTop", Vector3(7.2, 0.34, 4.0), Vector3(0, 0.72, 0.25), table_wood)
	_add_box("TableEdge", Vector3(7.35, 0.18, 0.20), Vector3(0, 0.78, 2.24), _material(Color("#2a140b"), 0.8))
	_add_box("TableEdge", Vector3(7.35, 0.18, 0.20), Vector3(0, 0.78, -1.74), _material(Color("#2a140b"), 0.8))
	for x in [-3.0, 3.0]:
		for z in [-1.25, 1.75]:
			_add_box("TableLeg", Vector3(0.38, 1.55, 0.38), Vector3(x, -0.02, z), table_wood)

	# Drewniana tacka do gry, widoczna z perspektywy gracza.
	var rail_wood := _wood_material(Color("#2a130a"), Color("#70401f"))
	_add_box("DiceRailBack", Vector3(5.7, 0.17, 0.16), Vector3(0, 0.98, -1.18), rail_wood)
	_add_box("DiceRailFront", Vector3(5.7, 0.17, 0.16), Vector3(0, 0.98, 1.32), rail_wood)
	_add_box("DiceRailLeft", Vector3(0.16, 0.17, 2.65), Vector3(-2.77, 0.98, 0.07), rail_wood)
	_add_box("DiceRailRight", Vector3(0.16, 0.17, 2.65), Vector3(2.77, 0.98, 0.07), rail_wood)

	# Ławy i dalsze stoły tworzą sylwetki karczmy w tle.
	var bench_wood := _wood_material(Color("#301a10"), Color("#5b341d"))
	for x in [-4.4, 4.4]:
		_add_box("Bench", Vector3(1.5, 0.20, 4.0), Vector3(x, 0.55, -0.4), bench_wood)
		for z in [-1.5, 0.8]:
			_add_box("BenchLeg", Vector3(0.28, 1.0, 0.28), Vector3(x, 0.05, z), bench_wood)


func _build_props() -> void:
	var pottery := _material(Color("#6d4a32"), 0.78)
	var metal := _material(Color("#5b5548"), 0.38, 0.65)
	for position in [Vector3(-2.75, 1.12, -1.0), Vector3(2.65, 1.12, -0.75)]:
		var mug := MeshInstance3D.new()
		var mug_mesh := CylinderMesh.new()
		mug_mesh.top_radius = 0.16
		mug_mesh.bottom_radius = 0.13
		mug_mesh.height = 0.42
		mug_mesh.radial_segments = 12
		mug.mesh = mug_mesh
		mug.material_override = pottery
		mug.position = position
		add_child(mug)

	for x in [-4.7, 4.7]:
		var barrel := MeshInstance3D.new()
		var barrel_mesh := CylinderMesh.new()
		barrel_mesh.top_radius = 0.52
		barrel_mesh.bottom_radius = 0.52
		barrel_mesh.height = 1.25
		barrel_mesh.radial_segments = 14
		barrel.mesh = barrel_mesh
		barrel.material_override = _wood_material(Color("#382014"), Color("#6a3c20"))
		barrel.position = Vector3(x, 0.63, -3.65)
		add_child(barrel)
		for ring_y in [0.22, 0.63, 1.03]:
			var ring := MeshInstance3D.new()
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = 0.49
			ring_mesh.outer_radius = 0.545
			ring_mesh.rings = 12
			ring_mesh.ring_segments = 6
			ring.mesh = ring_mesh
			ring.material_override = metal
			ring.position = Vector3(x, ring_y, -3.65)
			add_child(ring)

	_add_candle(Vector3(-2.25, 1.02, -1.15))
	_add_candle(Vector3(2.15, 1.02, -1.05))
	_add_candle(Vector3(-4.8, 2.55, -4.0))
	_add_candle(Vector3(4.8, 2.55, -4.0))


func _build_random_medieval_decorations() -> void:
	# Każde wejście do karczmy układa nieco inną kolekcję średniowiecznych
	# rekwizytów. To lekkie modele proceduralne, więc działają też w eksporcie.
	var wall_slots := [
		Vector3(-4.35, 2.55, -4.12),
		Vector3(-2.65, 3.05, -4.11),
		Vector3(2.75, 2.85, -4.11),
		Vector3(4.35, 2.45, -4.12)
	]
	for slot_index in range(wall_slots.size()):
		var prop := Node3D.new()
		prop.name = "RandomWallDecoration%d" % slot_index
		prop.position = wall_slots[slot_index]
		prop.rotation_degrees.z = rng.randf_range(-7.0, 7.0)
		add_child(prop)
		match rng.randi_range(0, 2):
			0:
				_build_shield(prop)
			1:
				_build_sword(prop)
			_:
				_build_banner(prop)
		random_decoration_count += 1

	var floor_slots := [
		Vector3(-5.15, 0.0, -2.65),
		Vector3(5.10, 0.0, -2.55),
		Vector3(rng.randf_range(-4.8, 4.8), 0.0, -3.55)
	]
	for slot_index in range(floor_slots.size()):
		var prop := Node3D.new()
		prop.name = "RandomFloorDecoration%d" % slot_index
		prop.position = floor_slots[slot_index]
		prop.rotation_degrees.y = rng.randf_range(-180.0, 180.0)
		add_child(prop)
		match rng.randi_range(0, 2):
			0:
				_build_crate(prop)
			1:
				_build_sack(prop)
			_:
				_build_clay_jug(prop)
		random_decoration_count += 1


func _build_shield(parent: Node3D) -> void:
	var shield := MeshInstance3D.new()
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.45
	shield_mesh.bottom_radius = 0.45
	shield_mesh.height = 0.10
	shield_mesh.radial_segments = 12
	shield.mesh = shield_mesh
	var shield_colors := [Color("#704025"), Color("#6b2727"), Color("#324b58"), Color("#6b5b2e")]
	shield.material_override = _material(shield_colors[rng.randi_range(0, shield_colors.size() - 1)], 0.76, 0.05)
	shield.rotation_degrees.x = 90.0
	parent.add_child(shield)
	var boss := MeshInstance3D.new()
	var boss_mesh := SphereMesh.new()
	boss_mesh.radius = 0.14
	boss_mesh.height = 0.16
	boss.mesh = boss_mesh
	boss.material_override = _material(Color("#6d6659"), 0.32, 0.75)
	boss.position.z = 0.08
	parent.add_child(boss)


func _build_sword(parent: Node3D) -> void:
	var metal := _material(Color("#a8a397"), 0.26, 0.86)
	_add_prop_box(parent, "Blade", Vector3(0.075, 1.18, 0.035), Vector3(0, 0.17, 0), metal)
	_add_prop_box(parent, "Crossguard", Vector3(0.50, 0.075, 0.09), Vector3(0, -0.43, 0), metal)
	_add_prop_box(parent, "Grip", Vector3(0.12, 0.40, 0.10), Vector3(0, -0.66, 0), _material(Color("#3a2117"), 0.92))


func _build_banner(parent: Node3D) -> void:
	var colors := [Color("#762d2a"), Color("#28485b"), Color("#52602d"), Color("#6b4a25")]
	_add_prop_box(parent, "Banner", Vector3(0.82, 1.32, 0.04), Vector3.ZERO, _material(colors[rng.randi_range(0, colors.size() - 1)], 0.92))
	_add_prop_box(parent, "BannerRail", Vector3(1.05, 0.07, 0.08), Vector3(0, 0.70, 0), _wood_material(Color("#24140c"), Color("#5a351d")))


func _build_crate(parent: Node3D) -> void:
	var wood := _wood_material(Color("#382015"), Color("#704324"))
	_add_prop_box(parent, "Crate", Vector3(0.86, 0.72, 0.82), Vector3(0, 0.36, 0), wood)
	var dark_wood := _material(Color("#29170f"), 0.90)
	_add_prop_box(parent, "CrateBand", Vector3(0.96, 0.10, 0.90), Vector3(0, 0.16, 0), dark_wood)
	_add_prop_box(parent, "CrateBand", Vector3(0.96, 0.10, 0.90), Vector3(0, 0.56, 0), dark_wood)


func _build_sack(parent: Node3D) -> void:
	var sack := MeshInstance3D.new()
	var sack_mesh := SphereMesh.new()
	sack_mesh.radius = 0.48
	sack_mesh.height = 1.05
	sack_mesh.radial_segments = 12
	sack.mesh = sack_mesh
	sack.material_override = _material(Color("#79664a"), 1.0)
	sack.position.y = 0.49
	sack.scale = Vector3(0.80, 1.0, 0.68)
	parent.add_child(sack)
	var tie := MeshInstance3D.new()
	var tie_mesh := TorusMesh.new()
	tie_mesh.inner_radius = 0.10
	tie_mesh.outer_radius = 0.14
	tie.mesh = tie_mesh
	tie.material_override = _material(Color("#3b2a1b"), 0.95)
	tie.position.y = 0.94
	parent.add_child(tie)


func _build_clay_jug(parent: Node3D) -> void:
	var clay := _material(Color("#75462f"), 0.82)
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.37
	body_mesh.height = 0.68
	body_mesh.radial_segments = 12
	body.mesh = body_mesh
	body.material_override = clay
	body.position.y = 0.34
	parent.add_child(body)
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.16
	neck_mesh.bottom_radius = 0.20
	neck_mesh.height = 0.34
	neck_mesh.radial_segments = 12
	neck.mesh = neck_mesh
	neck.material_override = clay
	neck.position.y = 0.76
	parent.add_child(neck)


func _add_prop_box(parent: Node3D, node_name: String, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = position
	parent.add_child(mesh_instance)
	return mesh_instance


func _build_player_arms() -> void:
	left_arm = _create_arm(Color("#68412a"))
	right_arm = _create_arm(Color("#68412a"))
	left_arm.position = Vector3(-0.72, 0.84, 3.42)
	right_arm.position = Vector3(0.72, 0.84, 3.42)
	left_arm.rotation_degrees = Vector3(67, 0, -8)
	right_arm.rotation_degrees = Vector3(67, 0, 8)
	add_child(left_arm)
	add_child(right_arm)


func _build_opponent() -> void:
	opponent = Node3D.new()
	opponent.name = "Opponent"
	opponent.position = Vector3(0, 0, -2.62)
	add_child(opponent)

	var tunic := _material(Color("#343638"), 0.96)
	var leather := _material(Color("#4b2d1d"), 0.88)
	var skin := _material(Color("#a86e4c"), 0.9)
	var hair := _material(Color("#211711"), 0.98)

	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.68
	torso_mesh.height = 1.72
	torso_mesh.radial_segments = 14
	torso.mesh = torso_mesh
	torso.material_override = tunic
	torso.position = Vector3(0, 2.04, 0)
	torso.scale = Vector3(1.10, 1.0, 0.68)
	opponent.add_child(torso)

	opponent_head = Node3D.new()
	opponent_head.position = Vector3(0, 3.12, 0.08)
	opponent.add_child(opponent_head)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.39
	head_mesh.height = 0.78
	head_mesh.radial_segments = 16
	head.mesh = head_mesh
	head.material_override = skin
	opponent_head.add_child(head)
	var hair_cap := MeshInstance3D.new()
	hair_cap.name = "Hair"
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.405
	hair_mesh.height = 0.62
	hair_mesh.radial_segments = 14
	hair_cap.mesh = hair_mesh
	hair_cap.material_override = hair
	hair_cap.position = Vector3(0, 0.15, -0.035)
	hair_cap.scale = Vector3(1.02, 0.72, 1.02)
	opponent_head.add_child(hair_cap)
	var nose := MeshInstance3D.new()
	var nose_mesh := SphereMesh.new()
	nose_mesh.radius = 0.075
	nose_mesh.height = 0.18
	nose_mesh.radial_segments = 8
	nose.mesh = nose_mesh
	nose.material_override = skin
	nose.position = Vector3(0, -0.03, 0.37)
	opponent_head.add_child(nose)
	for eye_x in [-0.14, 0.14]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.035
		eye_mesh.height = 0.07
		eye_mesh.radial_segments = 8
		eye.mesh = eye_mesh
		eye.material_override = hair
		eye.position = Vector3(eye_x, 0.07, 0.36)
		opponent_head.add_child(eye)

	for side in [-1.0, 1.0]:
		var arm := _create_opponent_arm(tunic, skin, leather)
		arm.position = Vector3(side * 0.62, 2.18, 0.18)
		arm.rotation_degrees = Vector3(58, 0, side * -29)
		opponent.add_child(arm)
		if side < 0:
			opponent_throw_arm = arm

	# Dwa boczne miejsca pozwalają obejrzeć pełny, czteroosobowy stół także
	# po otwarciu scenes/tavern_world.tscn bezpośrednio w edytorze Godot.
	side_opponents.append(_create_side_opponent(Vector3(-3.25, 0, 0.1), -90.0, Color("#4b3a48")))
	side_opponents.append(_create_side_opponent(Vector3(3.25, 0, 0.1), 90.0, Color("#3d4b3a")))


func _create_side_opponent(at: Vector3, yaw: float, tunic_color: Color) -> Node3D:
	var avatar := Node3D.new()
	avatar.name = "SideOpponent"
	avatar.position = at
	avatar.rotation_degrees.y = yaw
	add_child(avatar)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.58
	torso_mesh.height = 1.55
	torso.mesh = torso_mesh
	torso.material_override = _material(tunic_color, 0.94)
	torso.position.y = 1.82
	torso.scale = Vector3(1.0, 1.0, 0.68)
	avatar.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	head.material_override = _material(Color("#a86e4c"), 0.9)
	head.position = Vector3(0, 2.78, 0)
	avatar.add_child(head)
	return avatar


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.08, 5.28)
	camera.fov = 62
	camera.current = true
	add_child(camera)
	_update_camera_look()


func _update_camera_look() -> void:
	if is_instance_valid(camera):
		camera.look_at(Vector3(look_offset.x * 5.0, 1.28 + look_offset.y * 4.0, -0.12))


func _animate_arms() -> void:
	for arm_node in [left_arm, right_arm]:
		var arm := arm_node as Node3D
		var base_position: Vector3 = arm.position
		var tween: Tween = arm.create_tween()
		tween.tween_property(arm, "position", base_position + Vector3(0, 0.46, -1.10), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(arm, "position", base_position + Vector3(0, 0.08, -0.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(arm, "position", base_position, 0.28).set_trans(Tween.TRANS_SINE)


func _animate_opponent_throw() -> void:
	if not is_instance_valid(opponent_throw_arm):
		return
	var base_position := opponent_throw_arm.position
	var base_rotation := opponent_throw_arm.rotation
	var tween := opponent_throw_arm.create_tween()
	tween.tween_property(opponent_throw_arm, "position", base_position + Vector3(0.18, -0.34, 1.02), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(opponent_throw_arm, "rotation", base_rotation + Vector3(-0.55, 0.1, 0.18), 0.26)
	tween.tween_property(opponent_throw_arm, "position", base_position, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(opponent_throw_arm, "rotation", base_rotation, 0.45)


func _create_opponent_arm(tunic: Material, skin: Material, leather: Material) -> Node3D:
	var arm := Node3D.new()
	var sleeve := MeshInstance3D.new()
	sleeve.name = "Sleeve"
	var sleeve_mesh := CapsuleMesh.new()
	sleeve_mesh.radius = 0.18
	sleeve_mesh.height = 1.12
	sleeve_mesh.radial_segments = 12
	sleeve.mesh = sleeve_mesh
	sleeve.material_override = tunic
	arm.add_child(sleeve)
	var hand := MeshInstance3D.new()
	hand.name = "Hand"
	var hand_mesh := SphereMesh.new()
	hand_mesh.radius = 0.19
	hand_mesh.height = 0.38
	hand_mesh.radial_segments = 12
	hand.mesh = hand_mesh
	hand.material_override = skin
	hand.position.y = -0.61
	arm.add_child(hand)
	var cuff := MeshInstance3D.new()
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.21
	cuff_mesh.bottom_radius = 0.21
	cuff_mesh.height = 0.16
	cuff_mesh.radial_segments = 10
	cuff.mesh = cuff_mesh
	cuff.material_override = leather
	cuff.position.y = -0.45
	arm.add_child(cuff)
	return arm


func _create_arm(sleeve_color: Color) -> Node3D:
	var arm := Node3D.new()
	var sleeve := MeshInstance3D.new()
	sleeve.name = "Sleeve"
	var sleeve_mesh := CapsuleMesh.new()
	sleeve_mesh.radius = 0.20
	sleeve_mesh.height = 1.28
	sleeve_mesh.radial_segments = 12
	sleeve.mesh = sleeve_mesh
	sleeve.material_override = _material(sleeve_color, 0.92)
	arm.add_child(sleeve)
	var hand := MeshInstance3D.new()
	hand.name = "Hand"
	var hand_mesh := SphereMesh.new()
	hand_mesh.radius = 0.22
	hand_mesh.height = 0.44
	hand_mesh.radial_segments = 12
	hand.mesh = hand_mesh
	hand.material_override = _material(Color("#b47b58"), 0.88)
	hand.position.y = -0.69
	arm.add_child(hand)
	return arm


func _create_die(type_index: int) -> Node3D:
	type_index = clampi(type_index, 0, DIE_COLORS.size() - 1)
	var die := Node3D.new()
	var cube := MeshInstance3D.new()
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(0.58, 0.58, 0.58)
	cube.mesh = cube_mesh
	cube.material_override = _material(DIE_COLORS[type_index], 0.64, 0.08 if type_index in [3, 4, 5, 6] else 0.0)
	die.add_child(cube)
	var pip_material := _material(PIP_COLORS[type_index], 0.48, 0.10 if type_index in [3, 4, 6] else 0.0)
	_add_face_pips(die, 1, Vector3.UP, Vector3.RIGHT, Vector3.BACK, pip_material)
	_add_face_pips(die, 6, Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD, pip_material)
	_add_face_pips(die, 2, Vector3.BACK, Vector3.RIGHT, Vector3.UP, pip_material)
	_add_face_pips(die, 5, Vector3.FORWARD, Vector3.LEFT, Vector3.UP, pip_material)
	_add_face_pips(die, 3, Vector3.RIGHT, Vector3.FORWARD, Vector3.UP, pip_material)
	_add_face_pips(die, 4, Vector3.LEFT, Vector3.BACK, Vector3.UP, pip_material)
	return die


func _add_face_pips(die: Node3D, value: int, normal: Vector3, axis_x: Vector3, axis_y: Vector3, material: Material) -> void:
	for spot: Vector2 in PIP_PATTERNS[value]:
		var pip := MeshInstance3D.new()
		var pip_mesh := CylinderMesh.new()
		pip_mesh.top_radius = 0.052
		pip_mesh.bottom_radius = 0.052
		pip_mesh.height = 0.018
		pip_mesh.radial_segments = 12
		pip.mesh = pip_mesh
		pip.material_override = material
		pip.position = normal * 0.299 + axis_x * spot.x * 0.15 + axis_y * spot.y * 0.15
		pip.quaternion = Quaternion(Vector3.UP, normal)
		die.add_child(pip)


func _rotation_for_top_value(value: int) -> Vector3:
	match value:
		1:
			return Vector3.ZERO
		2:
			return Vector3(-PI * 0.5, 0, 0)
		3:
			return Vector3(0, 0, PI * 0.5)
		4:
			return Vector3(0, 0, -PI * 0.5)
		5:
			return Vector3(PI * 0.5, 0, 0)
		6:
			return Vector3(PI, 0, 0)
	return Vector3.ZERO


func _add_candle(position: Vector3) -> void:
	var wax := MeshInstance3D.new()
	var wax_mesh := CylinderMesh.new()
	wax_mesh.top_radius = 0.055
	wax_mesh.bottom_radius = 0.07
	wax_mesh.height = 0.30
	wax_mesh.radial_segments = 10
	wax.mesh = wax_mesh
	wax.material_override = _material(Color("#d9c58d"), 0.86)
	wax.position = position + Vector3(0, 0.15, 0)
	add_child(wax)
	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.045
	flame_mesh.height = 0.15
	flame_mesh.radial_segments = 8
	flame.mesh = flame_mesh
	var flame_material := _material(Color("#ffb13e"), 0.2)
	flame_material.emission_enabled = true
	flame_material.emission = Color("#ff8a24")
	flame_material.emission_energy_multiplier = 4.0
	flame.material_override = flame_material
	flame.position = position + Vector3(0, 0.38, 0)
	add_child(flame)
	var light := OmniLight3D.new()
	light.position = position + Vector3(0, 0.48, 0)
	light.light_color = Color("#ff9b45")
	light.light_energy = 2.2
	light.omni_range = 4.0
	light.shadow_enabled = true
	add_child(light)
	candle_lights.append(light)


func _add_box(node_name: String, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = position
	add_child(mesh_instance)
	return mesh_instance


func _material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _wood_material(dark: Color, light: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform vec3 dark_color : source_color;
uniform vec3 light_color : source_color;
void fragment() {
	float grain = sin(UV.y * 72.0 + sin(UV.x * 13.0) * 2.6) * 0.5 + 0.5;
	float broad = sin(UV.x * 8.0 + UV.y * 3.0) * 0.5 + 0.5;
	ALBEDO = mix(dark_color, light_color, grain * 0.25 + broad * 0.17);
	ROUGHNESS = 0.82;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("dark_color", Vector3(dark.r, dark.g, dark.b))
	material.set_shader_parameter("light_color", Vector3(light.r, light.g, light.b))
	return material
