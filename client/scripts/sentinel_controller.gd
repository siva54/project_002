extends CharacterBody3D

signal projectile_requested(origin: Vector3, destination: Vector3, source: CollisionObject3D)
signal alerted(position: Vector3, radius: float, source: Node)

const Avatar = preload("res://scripts/avatar_visual.gd")

enum State { PATROL, INVESTIGATE, ENGAGE, SEARCH, STAGGER, SHUTDOWN }

const BASE_COLOR := Color("ca5366")
const PATROL_SPEED := 2.0
const INVESTIGATE_SPEED := 3.0
const ENGAGE_SPEED := 3.6
const DESIRED_RANGE := 9.0
const SHOOT_INTERVAL := 2.6

var state := State.PATROL
var health := 60.0
var patrol_points: Array[Vector3] = []
var patrol_index := 0
var last_known_position := Vector3.ZERO
var investigate_time := 0.0
var search_time := 0.0
var stagger_time := 0.0
var shot_timer := 1.5
var strafe_sign := 1.0
var visual: Node3D
var state_label: Label3D
var frozen := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 3
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 2.1
	collision.shape = capsule
	collision.position.y = 1.1
	add_child(collision)
	visual = Avatar.new()
	visual.name = "Avatar"
	add_child(visual)
	visual.set_appearance(BASE_COLOR, false)
	state_label = Label3D.new()
	state_label.name = "StateLabel"
	state_label.position.y = 2.5
	state_label.font_size = 30
	state_label.pixel_size = 0.009
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(state_label)
	_sync_metadata()
	_refresh_label()

func setup(spawn: Vector3, points: Array, initial_shot_delay: float) -> void:
	position = spawn
	patrol_points.clear()
	for point in points:
		patrol_points.append(point)
	shot_timer = initial_shot_delay
	last_known_position = spawn
	if patrol_points.is_empty():
		patrol_points = [spawn]

func set_frozen(value: bool) -> void:
	frozen = value
	visual.set_frozen(value)
	velocity = Vector3.ZERO

func hear_noise(at: Vector3, radius: float) -> void:
	if state == State.SHUTDOWN or position.distance_to(at) > radius:
		return
	last_known_position = at
	investigate_time = maxf(investigate_time, 4.5)
	if state != State.ENGAGE and state != State.STAGGER:
		state = State.INVESTIGATE
	_refresh_label()
	_sync_metadata()

func take_damage(amount: float, attacker_position: Vector3) -> bool:
	if state == State.SHUTDOWN:
		return false
	health = maxf(0, health - amount)
	last_known_position = attacker_position
	investigate_time = 6.0
	if health <= 0:
		state = State.SHUTDOWN
		velocity = Vector3.ZERO
		visual.attack()
		visual.set_appearance(Color("f6bb66"), false)
		_refresh_label()
		_sync_metadata()
		return true
	state = State.STAGGER
	stagger_time = 0.38
	visual.attack()
	visual.set_appearance(Color("ffb072"), false)
	alerted.emit(attacker_position, 18.0, self)
	_refresh_label()
	_sync_metadata()
	return false

func update_brain(hero: CharacterBody3D, visible: bool, delta: float) -> void:
	if frozen or state == State.SHUTDOWN:
		return
	if has_meta("shot_timer"):
		shot_timer = minf(shot_timer, float(get_meta("shot_timer")))
	if visible:
		last_known_position = hero.position
		investigate_time = 5.0
		if state != State.STAGGER and state != State.ENGAGE:
			state = State.ENGAGE
			alerted.emit(hero.position, 22.0, self)
	elif state == State.ENGAGE:
		state = State.SEARCH
		search_time = 4.0
	if state == State.STAGGER:
		stagger_time = maxf(0, stagger_time - delta)
		velocity = Vector3.ZERO
		if stagger_time <= 0:
			state = State.ENGAGE if visible else State.INVESTIGATE
			visual.set_appearance(BASE_COLOR, false)
	elif state == State.PATROL:
		_patrol(delta)
	elif state == State.INVESTIGATE:
		investigate_time = maxf(0, investigate_time - delta)
		_move_to(last_known_position, INVESTIGATE_SPEED, delta)
		if position.distance_to(last_known_position) < 1.2 or investigate_time <= 0:
			state = State.SEARCH
			search_time = 3.5
	elif state == State.SEARCH:
		search_time = maxf(0, search_time - delta)
		var orbit := last_known_position + Vector3(cos(search_time * 2.0) * 2.0, 0, sin(search_time * 2.0) * 2.0)
		_move_to(orbit, INVESTIGATE_SPEED, delta)
		if search_time <= 0:
			state = State.PATROL
	elif state == State.ENGAGE:
		_engage(hero, visible, delta)
	visual.locomotion(Vector2(velocity.x, velocity.z).length(), is_on_floor(), delta)
	_refresh_label()
	_sync_metadata()

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	var destination: Vector3 = patrol_points[patrol_index]
	_move_to(destination, PATROL_SPEED, delta)
	if position.distance_to(destination) < 0.65:
		patrol_index = (patrol_index + 1) % patrol_points.size()

func _engage(hero: CharacterBody3D, visible: bool, delta: float) -> void:
	var offset: Vector3 = hero.position - position
	offset.y = 0
	var distance := offset.length()
	var forward := offset.normalized() if distance > 0.01 else Vector3.FORWARD
	var side := Vector3(-forward.z, 0, forward.x) * strafe_sign
	var desired := Vector3.ZERO
	if distance > DESIRED_RANGE + 1.4:
		desired += forward
	elif distance < DESIRED_RANGE - 2.2:
		desired -= forward
	desired += side * 0.55
	_move_direction(desired, ENGAGE_SPEED, delta)
	if distance > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(forward.x, forward.z), minf(1, delta * 9.0))
	shot_timer = maxf(0, shot_timer - delta)
	if visible and shot_timer <= 0:
		shot_timer = SHOOT_INTERVAL
		strafe_sign *= -1.0
		visual.attack()
		projectile_requested.emit(position + Vector3.UP * 1.45, hero.position + Vector3.UP, self)

func _move_to(destination: Vector3, speed: float, delta: float) -> void:
	var direction := destination - position
	direction.y = 0
	_move_direction(direction, speed, delta)

func _move_direction(direction: Vector3, speed: float, delta: float) -> void:
	if direction.length() < 0.05:
		velocity.x = move_toward(velocity.x, 0, speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 7.0 * delta)
		move_and_slide()
		return
	var planar := direction.normalized()
	velocity.x = move_toward(velocity.x, planar.x * speed, speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, planar.z * speed, speed * 8.0 * delta)
	velocity.y = -2.0
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(planar.x, planar.z), minf(1, delta * 8.0))
	move_and_slide()

func _refresh_label() -> void:
	var state_text: String = ["PATROL", "INVESTIGATE", "ENGAGE", "SEARCH", "STAGGERED", "SHUTDOWN"][state]
	state_label.text = "%s  /  %d" % [state_text, int(health)]
	state_label.modulate = Color("ff8e9c") if state == State.ENGAGE else (Color("f6bb66") if state == State.STAGGER else Color("9bb3c4"))

func _sync_metadata() -> void:
	set_meta("health", health)
	set_meta("last_seen", last_known_position)
	set_meta("search_time", search_time if state == State.SEARCH else investigate_time)
	set_meta("shot_timer", shot_timer)
	set_meta("state", ["patrol", "investigate", "engage", "search", "stagger", "shutdown"][state])
