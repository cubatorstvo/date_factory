class_name PropFactory
extends RefCounted
## Primitive props. Origin = floor contact (y=0).


static func attach(parent: Node3D, kind: StringName, color: Color = Color(0.7, 0.7, 0.7)) -> void:
	match str(kind):
		"bed":
			_mesh(parent, BoxMesh.new(), Vector3(2.0, 0.35, 1.2), Vector3(0, 0.175, 0), Color(0.45, 0.35, 0.55))
			_mesh(parent, BoxMesh.new(), Vector3(0.5, 0.22, 1.1), Vector3(-0.7, 0.42, 0), Color(0.85, 0.85, 0.9))
		"wardrobe":
			_mesh(parent, BoxMesh.new(), Vector3(1.2, 2.0, 0.55), Vector3(0, 1.0, 0), Color(0.4, 0.28, 0.18))
			_mesh(parent, BoxMesh.new(), Vector3(0.05, 1.6, 0.02), Vector3(-0.25, 1.0, 0.28), Color(0.8, 0.7, 0.2))
			_mesh(parent, BoxMesh.new(), Vector3(0.05, 1.6, 0.02), Vector3(0.25, 1.0, 0.28), Color(0.8, 0.7, 0.2))
		"shelf":
			_mesh(parent, BoxMesh.new(), Vector3(1.1, 1.4, 0.35), Vector3(0, 0.7, 0), Color(0.5, 0.4, 0.3))
			_mesh(parent, BoxMesh.new(), Vector3(0.15, 0.35, 0.15), Vector3(-0.25, 0.95, 0.1), Color(1.0, 0.4, 0.55))
			_mesh(parent, BoxMesh.new(), Vector3(0.2, 0.2, 0.2), Vector3(0.2, 0.9, 0.1), Color(0.9, 0.7, 0.2))
		"phone_stand":
			_mesh(parent, BoxMesh.new(), Vector3(0.6, 0.55, 0.45), Vector3(0, 0.275, 0), Color(0.35, 0.3, 0.28))
			_mesh(parent, BoxMesh.new(), Vector3(0.12, 0.22, 0.06), Vector3(0, 0.68, 0.05), Color(0.1, 0.1, 0.12))
			_mesh(parent, BoxMesh.new(), Vector3(0.1, 0.02, 0.01), Vector3(0, 0.78, 0.08), Color(0.2, 0.8, 1.0))
		"door":
			_mesh(parent, BoxMesh.new(), Vector3(1.1, 2.2, 0.12), Vector3(0, 1.1, 0), Color(0.55, 0.4, 0.25))
			_mesh(parent, SphereMesh.new(), Vector3(0.08, 0.08, 0.08), Vector3(0.4, 1.0, 0.1), Color(0.85, 0.75, 0.2))
		"desk":
			_mesh(parent, BoxMesh.new(), Vector3(1.4, 0.08, 0.7), Vector3(0, 0.74, 0), Color(0.45, 0.35, 0.25))
			_mesh(parent, BoxMesh.new(), Vector3(0.08, 0.7, 0.08), Vector3(-0.55, 0.35, -0.25), Color(0.35, 0.25, 0.18))
			_mesh(parent, BoxMesh.new(), Vector3(0.08, 0.7, 0.08), Vector3(0.55, 0.35, -0.25), Color(0.35, 0.25, 0.18))
			_mesh(parent, BoxMesh.new(), Vector3(0.08, 0.7, 0.08), Vector3(-0.55, 0.35, 0.25), Color(0.35, 0.25, 0.18))
			_mesh(parent, BoxMesh.new(), Vector3(0.08, 0.7, 0.08), Vector3(0.55, 0.35, 0.25), Color(0.35, 0.25, 0.18))
			_mesh(parent, BoxMesh.new(), Vector3(0.35, 0.05, 0.25), Vector3(0, 0.82, 0), Color(0.15, 0.15, 0.18))
		"poster":
			_mesh(parent, BoxMesh.new(), Vector3(0.9, 1.1, 0.05), Vector3(0, 1.2, 0), color)
		"machine":
			_mesh(parent, BoxMesh.new(), Vector3(1.2, 1.5, 0.9), Vector3(0, 0.75, 0), Color(0.35, 0.4, 0.45))
			_mesh(parent, BoxMesh.new(), Vector3(0.5, 0.3, 0.05), Vector3(0, 1.15, 0.48), Color(0.2, 0.9, 0.4))
		"console":
			_mesh(parent, BoxMesh.new(), Vector3(1.6, 1.2, 0.6), Vector3(0, 0.6, 0), Color(0.2, 0.25, 0.35))
			_mesh(parent, BoxMesh.new(), Vector3(1.2, 0.5, 0.05), Vector3(0, 1.0, 0.32), Color(0.2, 0.6, 1.0))
		"table_set":
			build_table_set(parent)
		"chair":
			build_chair(parent, color)
		"gift_box":
			_mesh(parent, BoxMesh.new(), Vector3(0.35, 0.25, 0.35), Vector3(0, 0.125, 0), color)
		_:
			_mesh(parent, BoxMesh.new(), Vector3(0.7, 0.7, 0.7), Vector3(0, 0.35, 0), color)


static func build_table_set(parent: Node3D) -> void:
	# Table top ~0.75 high, origin on floor.
	_mesh(parent, CylinderMesh.new(), Vector3(1.2, 0.08, 1.2), Vector3(0, 0.75, 0), Color(0.55, 0.4, 0.28))
	var top := parent.get_child(parent.get_child_count() - 1) as MeshInstance3D
	if top and top.mesh is CylinderMesh:
		var c := top.mesh as CylinderMesh
		c.top_radius = 0.65
		c.bottom_radius = 0.65
		c.height = 0.08
	_mesh(parent, CylinderMesh.new(), Vector3(0.2, 0.7, 0.2), Vector3(0, 0.35, 0), Color(0.4, 0.3, 0.2))
	var leg := parent.get_child(parent.get_child_count() - 1) as MeshInstance3D
	if leg and leg.mesh is CylinderMesh:
		var c2 := leg.mesh as CylinderMesh
		c2.top_radius = 0.08
		c2.bottom_radius = 0.1
		c2.height = 0.7
	# Player chair (+Z): face table (-Z) → yaw 180.
	var chair_player := Node3D.new()
	chair_player.name = "ChairPlayer"
	chair_player.position = Vector3(0, 0, 0.9)
	chair_player.rotation_degrees.y = 180.0
	parent.add_child(chair_player)
	build_chair(chair_player, Color(0.45, 0.35, 0.25))
	# Girl chair (-Z): face table (+Z) → yaw 0.
	var chair_girl := Node3D.new()
	chair_girl.name = "ChairGirl"
	chair_girl.position = Vector3(0, 0, -0.9)
	parent.add_child(chair_girl)
	build_chair(chair_girl, Color(0.45, 0.35, 0.25))


static func build_chair(parent: Node3D, color: Color) -> void:
	# Seat ~0.45 high; back on local -Z so facing is +Z.
	_mesh(parent, BoxMesh.new(), Vector3(0.45, 0.08, 0.45), Vector3(0, 0.45, 0), color)
	_mesh(parent, BoxMesh.new(), Vector3(0.45, 0.55, 0.08), Vector3(0, 0.75, -0.18), color)
	_mesh(parent, BoxMesh.new(), Vector3(0.06, 0.45, 0.06), Vector3(-0.16, 0.225, -0.16), color.darkened(0.2))
	_mesh(parent, BoxMesh.new(), Vector3(0.06, 0.45, 0.06), Vector3(0.16, 0.225, -0.16), color.darkened(0.2))
	_mesh(parent, BoxMesh.new(), Vector3(0.06, 0.45, 0.06), Vector3(-0.16, 0.225, 0.16), color.darkened(0.2))
	_mesh(parent, BoxMesh.new(), Vector3(0.06, 0.45, 0.06), Vector3(0.16, 0.225, 0.16), color.darkened(0.2))


static func build_girl(parent: Node3D, body_color: Color) -> Dictionary:
	var packed := load("res://scenes/characters/girl.tscn") as PackedScene
	var girl: Node3D = packed.instantiate() as Node3D if packed else Node3D.new()
	parent.add_child(girl)
	if girl.has_method("apply_profile"):
		girl.call("apply_profile", {"skin": body_color, "outfit_tint": body_color.darkened(0.2), "hair_style": "bob", "hair_color": body_color.darkened(0.5)})
	if girl.has_method("get_parts"):
		return girl.call("get_parts")
	return {}


static func apply_emotion(parts: Dictionary, emotion: StringName) -> void:
	var host: Node = null
	for key in ["body", "head", "mouth"]:
		var n: Variant = parts.get(key)
		if n is Node and is_instance_valid(n):
			host = (n as Node).get_parent()
			break
	if host != null and host.has_method("set_emotion"):
		host.call("set_emotion", emotion)
		return
	var mouth: MeshInstance3D = parts.get("mouth")
	var brow: MeshInstance3D = parts.get("brow")
	if mouth == null:
		return
	match str(emotion):
		"happy":
			mouth.scale = Vector3(1.4, 1.0, 1.0)
			if brow:
				brow.rotation_degrees.z = -8
		"annoyed":
			mouth.scale = Vector3(0.9, 1.0, 1.0)
			if brow:
				brow.rotation_degrees.z = 12
		"delighted":
			mouth.scale = Vector3(1.6, 1.3, 1.0)
			if brow:
				brow.rotation_degrees.z = -14
		_:
			mouth.scale = Vector3.ONE
			if brow:
				brow.rotation_degrees.z = 0


static func _face_dot(parent: Node3D, pos: Vector3, color: Color, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	mi.mesh = s
	mi.position = pos
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _mesh(parent: Node3D, mesh: Mesh, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radius = maxf(size.x, 0.05)
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m
