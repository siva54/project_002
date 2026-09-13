extends Node3D

const MODEL = preload("res://assets/characters/RobotExpressive.glb")
const Surfaces = preload("res://scripts/surface_library.gd")
var model: Node3D
var animator: AnimationPlayer
var materials: Array[StandardMaterial3D] = []
var paint_materials: Array[StandardMaterial3D] = []
var attack_remaining := 0.0
var active_clip := ""
var frozen := false

func _ready() -> void:
	model = MODEL.instantiate()
	model.scale = Vector3.ONE * 0.41
	add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0]
	# Duplicate libraries so loop settings cannot modify another actor's clips.
	for library_name in animator.get_animation_library_list():
		var library: AnimationLibrary = animator.get_animation_library(library_name).duplicate(true)
		animator.remove_animation_library(library_name)
		animator.add_animation_library(library_name, library)
	for clip in ["Idle", "Walking", "Running"]:
		animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: StandardMaterial3D = mesh.get_active_material(surface)
			var material: StandardMaterial3D = original.duplicate()
			material.roughness = 0.5
			if original.resource_name != "Black":
				material.albedo_texture = load(Surfaces.METAL + "Color.jpg")
				material.roughness_texture = load(Surfaces.METAL + "Roughness.jpg")
				material.uv1_triplanar = true
				material.uv1_scale = Vector3.ONE * 80
				material.metallic = 0.35
			if original.resource_name == "Main":
				paint_materials.append(material)
			materials.append(material)
			mesh.set_surface_override_material(surface, material)
	play("Idle")

func play(clip: String, speed: float = 1.0) -> void:
	if active_clip != clip:
		active_clip = clip
		animator.play(clip, 0.14, speed)
	else:
		animator.speed_scale = speed

func locomotion(speed: float, grounded: bool, delta: float) -> void:
	if frozen:
		return
	attack_remaining = maxf(0, attack_remaining - delta)
	if attack_remaining > 0:
		return
	if not grounded:
		play("WalkJump" if speed > 1 else "Jump")
	elif speed > 4.5:
		play("Running", clampf(speed / 6.8, 0.8, 1.35))
	elif speed > 0.15:
		play("Walking", clampf(speed / 3.2, 0.45, 1.6))
	else:
		play("Idle")

func attack() -> void:
	attack_remaining = 0.46
	active_clip = "Punch"
	animator.speed_scale = 1.0
	animator.play("Punch", 0.06, 1.8)
	animator.seek(0, true)

func set_frozen(value: bool) -> void:
	frozen = value
	animator.set_active(not value)

func set_appearance(color: Color, cloaked: bool) -> void:
	for material in paint_materials:
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.12
	for material in materials:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if cloaked else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = 0.2 if cloaked else 1.0

func reset_pose() -> void:
	attack_remaining = 0
	active_clip = ""
	play("Idle")
