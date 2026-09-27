class_name ProceduralAvatarFactory
extends RefCounted

const ARCHETYPES := {
	"woman": {"tunic": "#725064", "skin": "#bd835f", "hair": "#4a2418", "accent": "#b98a55", "body": 0.92, "hair_style": "long", "accessory": "satchel"},
	"innkeeper": {"tunic": "#6d3f25", "skin": "#ad7350", "hair": "#352016", "accent": "#d7c29a", "body": 1.16, "hair_style": "short", "accessory": "apron"},
	"king": {"tunic": "#6b2030", "skin": "#c58b68", "hair": "#704923", "accent": "#d6aa3f", "body": 1.05, "hair_style": "beard", "accessory": "crown"},
	"thief": {"tunic": "#26352f", "skin": "#947052", "hair": "#151515", "accent": "#3f4942", "body": 0.88, "hair_style": "hood", "accessory": "dagger"},
	"homeless": {"tunic": "#55483a", "skin": "#9c6848", "hair": "#4b433b", "accent": "#78644c", "body": 0.90, "hair_style": "wild", "accessory": "patches"},
	"princess": {"tunic": "#765080", "skin": "#d09a78", "hair": "#d0a14b", "accent": "#e5c46b", "body": 0.88, "hair_style": "long", "accessory": "tiara"},
	"madman": {"tunic": "#70402f", "skin": "#b77955", "hair": "#5b2b1e", "accent": "#89703e", "body": 0.94, "hair_style": "wild", "accessory": "bells"},
	"knight": {"tunic": "#4a5361", "skin": "#a96f4e", "hair": "#30231d", "accent": "#aeb5ba", "body": 1.12, "hair_style": "helmet", "accessory": "pauldrons"},
	"monk": {"tunic": "#493426", "skin": "#b87d59", "hair": "#4a3528", "accent": "#9b7746", "body": 1.00, "hair_style": "tonsure", "accessory": "rope"},
	"merchant": {"tunic": "#31546a", "skin": "#aa714e", "hair": "#3c251a", "accent": "#b68b3f", "body": 1.08, "hair_style": "cap", "accessory": "pouch"},
	"bard": {"tunic": "#733b35", "skin": "#c18662", "hair": "#3b2017", "accent": "#d29b43", "body": 0.94, "hair_style": "cap", "accessory": "feather"},
	"witch": {"tunic": "#34283f", "skin": "#907052", "hair": "#282128", "accent": "#67527a", "body": 0.90, "hair_style": "long", "accessory": "witch_hat"}
}


static func create(archetype_id: String) -> Node3D:
	if not ARCHETYPES.has(archetype_id):
		return null
	var style: Dictionary = ARCHETYPES[archetype_id]
	var root := Node3D.new()
	root.name = "Builtin%s" % archetype_id.capitalize()
	root.set_meta("builtin_archetype", archetype_id)
	var skin := Color(str(style.skin))
	var tunic := Color(str(style.tunic))
	var hair := Color(str(style.hair))
	var accent := Color(str(style.accent))
	var body_scale := float(style.body)

	_add_capsule(root, "Torso", Vector3(0, 1.78, 0), 0.56, 1.55, tunic, Vector3(body_scale, 1.0, 0.72))
	_add_box(root, "Belt", Vector3(0, 1.47, 0.02), Vector3(1.05 * body_scale, 0.13, 0.72), accent.darkened(0.28))
	_add_capsule(root, "Head", Vector3(0, 2.82, 0.04), 0.34, 0.68, skin)
	_add_sphere(root, "Nose", Vector3(0, 2.78, 0.36), 0.065, skin, Vector3(0.82, 1.0, 1.25))
	for eye_x in [-0.125, 0.125]:
		_add_sphere(root, "Eye", Vector3(eye_x, 2.89, 0.35), 0.032, Color("#171311"))
	_build_hair(root, str(style.hair_style), hair, accent)
	_build_arms(root, skin, tunic, body_scale, archetype_id)
	_build_legs(root, tunic.darkened(0.22), body_scale)
	_build_accessory(root, str(style.accessory), skin, tunic, hair, accent, body_scale)
	return root


static func _build_arms(root: Node3D, skin: Color, tunic: Color, body_scale: float, archetype_id: String) -> void:
	for side in [-1.0, 1.0]:
		var sleeve_color := tunic
		if archetype_id == "madman" and side > 0:
			sleeve_color = Color("#31555b")
		var arm := Node3D.new()
		arm.name = "ArmLeft" if side < 0 else "ArmRight"
		arm.position = Vector3(side * 0.60 * body_scale, 1.93, 0.10)
		arm.rotation_degrees = Vector3(58, 0, side * -24)
		root.add_child(arm)
		_add_capsule(arm, "Sleeve", Vector3(0, -0.25, 0), 0.16, 0.72, sleeve_color)
		_add_sphere(arm, "Hand", Vector3(0, -0.66, 0), 0.15, skin, Vector3(0.88, 1.15, 0.88))


static func _build_legs(root: Node3D, color: Color, body_scale: float) -> void:
	for side in [-1.0, 1.0]:
		_add_capsule(root, "Leg", Vector3(side * 0.22 * body_scale, 0.67, 0), 0.18, 1.18, color, Vector3(1.0, 1.0, 0.86))
		_add_box(root, "Boot", Vector3(side * 0.22 * body_scale, 0.14, 0.10), Vector3(0.34, 0.24, 0.55), Color("#2a211c"))


static func _build_hair(root: Node3D, hair_style: String, hair: Color, accent: Color) -> void:
	match hair_style:
		"hood":
			_add_sphere(root, "Hair", Vector3(0, 2.88, -0.02), 0.42, accent.darkened(0.32), Vector3(1.08, 1.10, 1.03))
			_add_sphere(root, "FaceOpening", Vector3(0, 2.83, 0.30), 0.31, Color("#181b19"), Vector3(0.90, 0.92, 0.25))
		"helmet":
			_add_sphere(root, "Helmet", Vector3(0, 2.91, 0), 0.405, accent, Vector3(1.05, 0.90, 1.05))
			_add_box(root, "HelmetNoseGuard", Vector3(0, 2.78, 0.39), Vector3(0.07, 0.35, 0.06), accent.darkened(0.10))
		"tonsure":
			for angle in range(0, 360, 45):
				var radians := deg_to_rad(float(angle))
				_add_sphere(root, "Hair", Vector3(cos(radians) * 0.27, 3.08, sin(radians) * 0.25), 0.105, hair)
		"wild":
			for offset in [Vector3(-0.25, 3.13, 0), Vector3(0.03, 3.22, -0.04), Vector3(0.27, 3.10, 0.02), Vector3(-0.10, 3.07, -0.27)]:
				_add_sphere(root, "Hair", offset, 0.18, hair, Vector3(0.70, 1.40, 0.70))
		"cap":
			_add_sphere(root, "Hair", Vector3(0, 3.05, -0.03), 0.37, hair, Vector3(1.02, 0.52, 1.02))
			_add_cylinder(root, "Cap", Vector3(0, 3.16, -0.01), 0.34, 0.30, 0.16, accent)
		_:
			_add_sphere(root, "Hair", Vector3(0, 3.05, -0.04), 0.37, hair, Vector3(1.03, 0.62, 1.03))
	if hair_style in ["long", "beard"]:
		for side in [-1.0, 1.0]:
			_add_capsule(root, "Hair", Vector3(side * 0.29, 2.75, -0.04), 0.12, 0.72, hair)
	if hair_style == "beard":
		_add_capsule(root, "Beard", Vector3(0, 2.58, 0.30), 0.20, 0.55, hair, Vector3(1.25, 1.0, 0.55))


static func _build_accessory(root: Node3D, accessory: String, skin: Color, tunic: Color, hair: Color, accent: Color, body_scale: float) -> void:
	match accessory:
		"apron":
			_add_box(root, "Apron", Vector3(0, 1.62, 0.53), Vector3(0.88 * body_scale, 1.18, 0.055), accent)
			_add_cylinder(root, "Mug", Vector3(0.72, 1.30, 0.42), 0.16, 0.19, 0.34, Color("#80522e"), Vector3(0.85, 1.0, 0.85))
		"crown":
			_add_cylinder(root, "Crown", Vector3(0, 3.28, 0), 0.34, 0.29, 0.24, accent)
			for side in [-0.23, 0.0, 0.23]:
				_add_sphere(root, "CrownPoint", Vector3(side, 3.47, 0.03), 0.075, accent)
		"dagger":
			_add_box(root, "Dagger", Vector3(0.56, 1.30, 0.20), Vector3(0.08, 0.62, 0.12), Color("#aeb3b1"), Vector3.ONE, Vector3(0, 0, -18))
		"patches":
			_add_box(root, "Patch", Vector3(-0.22, 1.82, 0.52), Vector3(0.28, 0.32, 0.05), accent)
			_add_box(root, "Patch", Vector3(0.24, 1.42, 0.51), Vector3(0.22, 0.27, 0.05), tunic.lightened(0.16))
		"tiara":
			_add_cylinder(root, "Tiara", Vector3(0, 3.27, 0), 0.30, 0.26, 0.10, accent)
			_add_sphere(root, "Gem", Vector3(0, 3.37, 0.25), 0.07, Color("#5f9bc7"))
		"bells":
			for side in [-0.25, 0.25]:
				_add_sphere(root, "Bell", Vector3(side, 3.30, 0), 0.10, accent)
		"pauldrons":
			for side in [-1.0, 1.0]:
				_add_sphere(root, "Pauldron", Vector3(side * 0.63 * body_scale, 2.18, 0), 0.25, accent, Vector3(1.35, 0.62, 1.0))
			_add_box(root, "ChestPlate", Vector3(0, 1.91, 0.51), Vector3(0.94 * body_scale, 0.95, 0.08), accent.darkened(0.08))
		"rope":
			_add_cylinder(root, "RopeBelt", Vector3(0, 1.43, 0), 0.55 * body_scale, 0.55 * body_scale, 0.08, accent, Vector3(1, 1, 0.74))
		"pouch":
			_add_box(root, "Pouch", Vector3(0.52, 1.38, 0.36), Vector3(0.38, 0.42, 0.22), Color("#704727"))
		"feather":
			_add_capsule(root, "Feather", Vector3(0.30, 3.42, 0), 0.045, 0.56, Color("#d6c26a"), Vector3(1, 1, 0.45), Vector3(0, 0, -28))
			_add_box(root, "Lute", Vector3(-0.55, 1.55, -0.18), Vector3(0.33, 0.78, 0.15), Color("#9b632f"), Vector3.ONE, Vector3(0, 0, -24))
		"satchel":
			_add_box(root, "Satchel", Vector3(0.53, 1.36, 0.28), Vector3(0.40, 0.46, 0.20), accent.darkened(0.18))
		"witch_hat":
			_add_cylinder(root, "HatBrim", Vector3(0, 3.22, 0), 0.48, 0.48, 0.08, accent.darkened(0.32))
			_add_cylinder(root, "HatCone", Vector3(0, 3.56, -0.03), 0.035, 0.34, 0.68, accent.darkened(0.20))


static func _add_capsule(parent: Node3D, name_value: String, position: Vector3, radius: float, height: float, color: Color, scale_value := Vector3.ONE, rotation_degrees_value := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 5
	return _add_mesh(parent, name_value, mesh, position, color, scale_value, rotation_degrees_value)


static func _add_sphere(parent: Node3D, name_value: String, position: Vector3, radius: float, color: Color, scale_value := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _add_mesh(parent, name_value, mesh, position, color, scale_value)


static func _add_box(parent: Node3D, name_value: String, position: Vector3, size: Vector3, color: Color, scale_value := Vector3.ONE, rotation_degrees_value := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(parent, name_value, mesh, position, color, scale_value, rotation_degrees_value)


static func _add_cylinder(parent: Node3D, name_value: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, scale_value := Vector3.ONE) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	return _add_mesh(parent, name_value, mesh, position, color, scale_value)


static func _add_mesh(parent: Node3D, name_value: String, mesh: PrimitiveMesh, position: Vector3, color: Color, scale_value := Vector3.ONE, rotation_degrees_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_value
	node.mesh = mesh
	node.position = position
	node.scale = scale_value
	node.rotation_degrees = rotation_degrees_value
	node.material_override = _material(color)
	parent.add_child(node)
	return node


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
