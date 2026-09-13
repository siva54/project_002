extends CharacterBody3D

signal power_requested(slot: int)
signal menu_requested
signal melee_requested

const Avatar = preload("res://scripts/avatar_visual.gd")

var enabled := false
var yaw := 0.0
var pitch := -0.12
var arm: SpringArm3D
var camera: Camera3D
var visual: Node3D
var attack_lock := 0.0
var accent := Color("46dec6")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	visual = Avatar.new()
	add_child(visual)
	visual.rotation.y = PI
	arm = SpringArm3D.new()
	arm.position = Vector3(0.65, 1.65, 0)
	arm.spring_length = 5.5
	arm.collision_mask = 1
	arm.margin = 0.2
	add_child(arm)
	camera = Camera3D.new()
	camera.fov = 72
	arm.add_child(camera)
	camera.current = true
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch - event.relative.y * 0.003, -1.1, 0.8)
		_update_camera()
	if event.is_action_pressed("pause_lab"):
		menu_requested.emit()
		return
	if event.is_action_pressed("melee"):
		melee_requested.emit()
	for slot in range(3):
		if event.is_action_pressed("power_%d" % slot):
			power_requested.emit(slot)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		power_requested.emit(0)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	attack_lock = maxf(0, attack_lock - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move := Basis(Vector3.UP, yaw) * Vector3(direction.x, 0, direction.y)
	var speed := 6.8 if Input.is_action_pressed("sprint") else 3.2
	if attack_lock > 0:
		speed *= 0.45
	velocity.x = move_toward(velocity.x, move.x * speed, 22 * delta)
	velocity.z = move_toward(velocity.z, move.z * speed, 22 * delta)
	if move.length() > 0.05 and attack_lock <= 0:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(move.x, move.z), minf(1, delta * 14))
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 9.0
	move_and_slide()
	visual.locomotion(Vector2(velocity.x, velocity.z).length(), is_on_floor(), delta)
	if position.y < -10:
		position = Vector3(0, 1, 10)
		velocity = Vector3.ZERO

func _update_camera() -> void:
	arm.rotation = Vector3(pitch, yaw, 0)

func set_appearance(color: Color, cloaked: bool) -> void:
	accent = color
	visual.set_appearance(color, cloaked)

func play_attack() -> void:
	var direction := aim_direction()
	visual.rotation.y = atan2(direction.x, direction.z)
	attack_lock = 0.38
	visual.attack()

func muzzle_position() -> Vector3:
	return position + Vector3.UP * 1.25 + aim_direction() * 0.55

func aim_direction() -> Vector3:
	return -camera.global_basis.z

func aim_point(distance: float = 60.0) -> Vector3:
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_direction() * distance, 5)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else origin + aim_direction() * distance
