extends Node3D

signal impacted(body: Node, at: Vector3)
const VFX = preload("res://scripts/power_vfx.gd")
var direction := Vector3.FORWARD
var speed := 24.0
var collision_mask := 5
var excluded: Array[RID] = []
var tint := Color("46dec6")
var lifespan := 3.0
var age := 0.0
var shell: MeshInstance3D
var homing_target: Node3D
var homing_turn_rate := 7.0
var target_check_time := 0.0
var launch_delay := 0.0
var is_missile := false

func _ready() -> void:
	add_to_group("projectiles")
	VFX.sphere(self, 0.12, tint.lightened(0.5))
	shell = VFX.sphere(self, 0.3, tint, true)
	var orbit := VFX.ring(self, 0.22, tint)
	orbit.rotation.x = PI / 2
	if is_missile:
		name = "SeekerMissile"
		var body := MeshInstance3D.new()
		var body_mesh := CylinderMesh.new()
		body_mesh.top_radius = 0.055
		body_mesh.bottom_radius = 0.13
		body_mesh.height = 0.48
		body.mesh = body_mesh
		body.rotation.x = PI * 0.5
		body.material_override = VFX.glow(tint.lightened(0.35), 2.0)
		add_child(body)
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = 0.75
	light.omni_range = 2.4
	add_child(light)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifespan:
		queue_free()
		return
	if launch_delay > 0:
		launch_delay = maxf(0, launch_delay - delta)
		shell.scale = Vector3.ONE * (1.0 + sin(age * 18) * 0.12)
		return
	_update_homing(delta)
	var next := global_position + direction * speed * delta
	# Continuous travel query prevents fast projectiles skipping thin cover.
	var query := PhysicsRayQueryParameters3D.create(global_position, next, collision_mask)
	query.exclude = excluded
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		impacted.emit(hit.collider, hit.position)
		queue_free()
		return
	global_position = next
	shell.scale = Vector3.ONE * (1.0 + sin(age * 25) * 0.1)
	shell.rotate_y(delta * 5)
	if is_missile and direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _update_homing(delta: float) -> void:
	if not is_instance_valid(homing_target) or homing_target.is_queued_for_deletion():
		homing_target = null
		return
	target_check_time -= delta
	if target_check_time <= 0:
		target_check_time = 0.12
		var ray := PhysicsRayQueryParameters3D.create(global_position, homing_target.global_position + Vector3.UP, collision_mask)
		ray.exclude = excluded
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.collider != homing_target:
			homing_target = null
			return
	var desired := (homing_target.global_position + Vector3.UP * 1.1 - global_position).normalized()
	direction = direction.lerp(desired, minf(1.0, homing_turn_rate * delta)).normalized()
