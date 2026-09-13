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

func _ready() -> void:
	add_to_group("projectiles")
	VFX.sphere(self, 0.12, tint.lightened(0.5))
	shell = VFX.sphere(self, 0.3, tint, true)
	var orbit := VFX.ring(self, 0.22, tint)
	orbit.rotation.x = PI / 2
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
