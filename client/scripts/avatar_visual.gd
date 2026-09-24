extends Node3D

const BODY_SCENE := preload("res://assets/characters/vitruvian/vitruvian_body.glb")
const HEAD_SCENE := preload("res://assets/characters/vitruvian/vitruvian_head.glb")
const BODY_ALBEDO := preload("res://assets/characters/vitruvian/vit_body_bc.png")
const BODY_NORMAL := preload("res://assets/characters/vitruvian/vit_body_n.png")
const FACE_ALBEDO := preload("res://assets/characters/vitruvian/vit_face_bc.png")
const FACE_NORMAL := preload("res://assets/characters/vitruvian/vit_face_n.png")
const HEAD_BONE := "mixamorig_Head"
const MartialArts = preload("res://scripts/martial_arts.gd")

var active_clip := ""
var frozen := false
var attack_remaining := 0.0
var guard_remaining := 0.0
var body_animation: AnimationPlayer
var body_skeleton: Skeleton3D
var clothing_materials: Array[StandardMaterial3D] = []
var all_materials: Array[StandardMaterial3D] = []
var accent_material: StandardMaterial3D

func _ready() -> void:
	_load_character()
	_build_team_marker()
	set_appearance(Color("46dec6"), false)
	reset_pose()

func _load_character() -> void:
	var body := BODY_SCENE.instantiate()
	body.name = "HumanBody"
	add_child(body)
	body_skeleton = _find_first(body, "Skeleton3D") as Skeleton3D
	body_animation = _find_first(body, "AnimationPlayer") as AnimationPlayer
	if body_animation:
		for clip_name in body_animation.get_animation_list():
			body_animation.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
		MartialArts.install(body_animation, body_skeleton)
	for mesh in _collect_meshes(body):
		for surface in mesh.mesh.get_surface_count():
			var source_material := mesh.get_active_material(surface)
			var material_name := source_material.resource_name if source_material else ""
			mesh.set_surface_override_material(surface, _body_material(material_name))
	_attach_head()

func _attach_head() -> void:
	if body_skeleton == null:
		return
	var head_bone := body_skeleton.find_bone(HEAD_BONE)
	if head_bone < 0:
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "HeadAttachment"
	body_skeleton.add_child(attachment)
	attachment.bone_idx = head_bone
	var head_rig := Node3D.new()
	head_rig.name = "HeadRig"
	attachment.add_child(head_rig)
	head_rig.global_transform = Transform3D.IDENTITY
	var head := HEAD_SCENE.instantiate()
	head.name = "HumanHead"
	head_rig.add_child(head)
	for mesh in _collect_meshes(head):
		if mesh.name == "cm_vitruvian":
			for surface in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(surface, _make_skin_material(FACE_ALBEDO, FACE_NORMAL))

func _body_material(material_name: String) -> StandardMaterial3D:
	match material_name:
		"VitShirt":
			var shirt := _make_material(Color("1b252d"), 0.0, 0.79)
			clothing_materials.append(shirt)
			return shirt
		"VitPants":
			var pants := _make_material(Color("151a20"), 0.0, 0.86)
			clothing_materials.append(pants)
			return pants
		"VitShoes":
			return _make_material(Color("0b0e12"), 0.0, 0.62)
		_:
			return _make_skin_material(BODY_ALBEDO, BODY_NORMAL)

func _make_skin_material(albedo_texture: Texture2D, normal_texture: Texture2D) -> StandardMaterial3D:
	var material := _make_material(Color.WHITE, 0.0, 0.78)
	material.albedo_texture = albedo_texture
	material.normal_enabled = true
	material.normal_texture = normal_texture
	material.normal_scale = 0.7
	return material

func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	all_materials.append(material)
	return material

func _build_team_marker() -> void:
	# A compact chest patch identifies friend or foe without recoloring realistic skin and clothing.
	var marker := MeshInstance3D.new()
	marker.name = "TeamPatch"
	var patch := BoxMesh.new()
	patch.size = Vector3(0.13, 0.07, 0.012)
	marker.mesh = patch
	marker.position = Vector3(0.0, 1.27, 0.194)
	accent_material = StandardMaterial3D.new()
	accent_material.metallic = 0.1
	accent_material.roughness = 0.42
	all_materials.append(accent_material)
	marker.material_override = accent_material
	add_child(marker)

func _find_first(root: Node, node_type: String) -> Node:
	var matches := root.find_children("*", node_type, true, false)
	return matches.front() if not matches.is_empty() else null

func _collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		result.append(node as MeshInstance3D)
	return result

func locomotion(speed: float, grounded: bool, delta: float) -> void:
	if frozen:
		return
	attack_remaining = maxf(0.0, attack_remaining - delta)
	guard_remaining = maxf(0.0, guard_remaining - delta)
	if attack_remaining > 0.0:
		return
	rotation.x = lerpf(rotation.x, 0.0, minf(1, delta * 12))
	if not grounded:
		active_clip = "WalkJump" if speed > 1.0 else "Jump"
		_play("Walk" if speed > 1.0 else "Idle", 1.0)
	elif speed > 0.15:
		active_clip = "Running" if speed > 4.5 else "Walking"
		_play("Walk", 1.5 if speed > 4.5 else 1.0)
	else:
		active_clip = "Guard" if guard_remaining > 0 else "Idle"
		_play("martial/Guard" if guard_remaining > 0 else "Idle")

func attack() -> void:
	# Power casts use a short palm strike; melee selects its own combo stage.
	strike(0)

func strike(index: int) -> void:
	var data: Dictionary = MartialArts.STRIKES[index]
	_play_action(data)

func grapple(index: int) -> void:
	_play_action(MartialArts.GRAPPLES[index])

func _play_action(data: Dictionary) -> void:
	attack_remaining = data.duration
	guard_remaining = data.duration + MartialArts.COMBO_GRACE
	active_clip = data.clip
	body_animation.stop()
	body_animation.speed_scale = 1.0
	body_animation.play("martial/" + data.clip, 0.07)
	body_animation.advance(0)

func react_to_hit() -> void:
	attack_remaining = 0.38
	active_clip = "Stagger"
	_play("martial/Guard")
	rotation.x = -0.16

func _play(clip: String, speed: float = 1.0) -> void:
	if body_animation == null or not body_animation.has_animation(clip):
		return
	body_animation.speed_scale = speed
	if body_animation.current_animation != clip:
		body_animation.play(clip, 0.16)

func set_frozen(value: bool) -> void:
	frozen = value
	if body_animation:
		body_animation.pause() if value else body_animation.play()

func set_appearance(color: Color, cloaked: bool) -> void:
	if accent_material:
		accent_material.albedo_color = color.darkened(0.18)
		accent_material.emission_enabled = true
		accent_material.emission = color.darkened(0.4) * 0.22
	for material in clothing_materials:
		material.albedo_color = material.albedo_color.lerp(color.darkened(0.70), 0.04)
	for material in all_materials:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if cloaked else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = 0.26 if cloaked else 1.0
	if accent_material:
		accent_material.albedo_color = color.darkened(0.18)

func reset_pose() -> void:
	attack_remaining = 0.0
	guard_remaining = 0.0
	rotation.x = 0
	rotation.z = 0
	active_clip = "Idle"
	_play("Idle")
