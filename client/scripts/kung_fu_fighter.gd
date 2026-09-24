extends CharacterBody3D

signal contact(fighter: CharacterBody3D, move: Dictionary)
signal throw_release(fighter: CharacterBody3D, target: CharacterBody3D)
signal strike_started(fighter: CharacterBody3D)
signal counter_impact(fighter: CharacterBody3D, victim: CharacterBody3D, stage: int)
signal counter_landed(fighter: CharacterBody3D, victim: CharacterBody3D)

const Visual := preload("res://scripts/kung_fu_visual.gd")
const Catalog := preload("res://scripts/combat_moves.gd")
const Counter := preload("res://scripts/counter_sequences.gd")
const MOVES := Catalog.MOVES
enum State { READY, ATTACK, EVADE, HIT, CLINCH, THROW, DOWN, GETUP, KO, COUNTER }

var visual: Node3D
var player := false
var state := State.READY
var health := 100.0
var stamina := 100.0
var blocking := false
var block_age := 0.0
var state_time := 0.0
var move: Dictionary = {}
var action_name := ""
var did_contact := false
var chain_index := 0
var combo_age := 0.0
var buffered := ""
var buffered_target: CharacterBody3D
var facing := Vector3.FORWARD
var drive := Vector3.ZERO
var evade_direction := Vector3.ZERO
var target: CharacterBody3D
var grabbed: CharacterBody3D
var held_by: CharacterBody3D
var pair_kind := "hold"
var pair_forward := Vector3.FORWARD
var ai_delay := 0.6
var last_result := ""
var last_hit_by: CharacterBody3D
var counter_target: CharacterBody3D
var hit_duration := 0.34
var last_contact_position := Vector3.ZERO
var successful_contacts := 0
var counter_stage := 0
var counter_incoming: Dictionary = {}
var counter_cue: Label3D
var counter_did_land := false
var attack_basis := Basis.IDENTITY
var attack_approach := Vector3.ZERO
var attack_step := Vector3.ZERO
var attack_start_yaw := 0.0
var attack_end_yaw := 0.0

func _ready() -> void:
	collision_layer = 2 if player else 4
	collision_mask = 7
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.55
	collider.shape = capsule
	collider.position.y = 0.79
	add_child(collider)
	visual = Visual.new()
	add_child(visual)
	visual.configure_fighter(player)
	face(Vector3.FORWARD)
	if not player:
		counter_cue = Label3D.new()
		counter_cue.position.y = 1.95
		counter_cue.font_size = 48
		counter_cue.pixel_size = 0.007
		counter_cue.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		counter_cue.no_depth_test = false
		counter_cue.outline_size = 8
		counter_cue.hide()
		add_child(counter_cue)

func face(direction: Vector3, delta: float = 1.0) -> void:
	direction.y = 0
	if direction.length_squared() < 0.001:
		return
	var desired := atan2(direction.x, direction.z)
	visual.rotation.y = rotate_toward(visual.rotation.y, desired, delta * 14.0)
	facing = Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))

func request_attack(kind: String = "light", aimed_target: CharacterBody3D = null) -> bool:
	if state == State.COUNTER and counter_stage == 3:
		buffered = kind
		buffered_target = aimed_target
		return true
	if state == State.THROW and pair_kind == "hold":
		pair_kind = "sweep" if kind in ["heavy", "kick"] else "knee"
		state_time = 0
		did_contact = false
		return true
	if state == State.ATTACK:
		buffered = kind
		buffered_target = aimed_target
		return true
	if state != State.READY:
		return false
	if aimed_target != null:
		target = aimed_target
	return _start_attack(kind)

func _start_attack(kind: String) -> bool:
	var previous := action_name if combo_age > 0 else ""
	if combo_age <= 0:
		chain_index = 0
	var next := Catalog.next_move(previous, kind, drive.length() > 0.5)
	var data: Dictionary = MOVES[next].duplicate()
	if stamina < data.cost:
		return false
	if not player:
		data.rate *= 0.76
		for key in ["contact", "link", "duration"]:
			data[key] /= 0.76
		data.windup = 0.18
		for key in ["contact", "link", "duration"]:
			data[key] += data.windup
		data.damage *= 0.65
	data.finisher = next in ["Uppercut", "SideKick", "Roundhouse"] and chain_index >= 3
	stamina -= data.cost
	move = data
	state = State.ATTACK
	state_time = 0
	did_contact = false
	blocking = false
	action_name = next
	chain_index += 1
	attack_start_yaw = visual.rotation.y
	attack_end_yaw = attack_start_yaw
	if is_instance_valid(target) and target.is_available() and clear_to(target):
		var direction: Vector3 = target.position - position
		attack_end_yaw = atan2(direction.x, direction.z)
	attack_basis = Basis(Vector3.UP, attack_end_yaw)
	attack_approach = Vector3.ZERO
	attack_step = drive * (0.10 if data.shape.ends_with("kick") else 0.20)
	if is_instance_valid(target) and target.is_available() and clear_to(target):
		var gap: Vector3 = target.position - position
		gap.y = 0
		if gap.length() < 2.8 and drive.dot(facing) > -0.35:
			var source_at_contact: Vector3 = attack_basis * visual.root_offset(data.clip, (data.contact - float(data.get("windup", 0.0))) * data.rate)
			if data.get("captured", false):
				var aim_bone := "LeftLeg" if data.height < 0.7 else ("Spine" if data.height < 1.2 else "Neck")
				var aim: Vector3 = target.visual.bone_world(aim_bone)
				var drift: Vector3 = target.velocity * minf(data.contact, 0.2)
				drift.y = 0
				aim += drift.limit_length(0.22)
				aim -= gap.normalized() * 0.08
				var source_limb: Vector3 = attack_basis * visual.contact_offset(next, data.clip)
				var desired: Vector3 = aim - source_limb
				desired.y = position.y
				var separation: Vector3 = desired - target.position
				separation.y = 0
				if separation.length() < 0.58:
					desired = target.position + (separation.normalized() if separation.length() > 0.001 else -gap.normalized()) * 0.58
					desired.y = position.y
				attack_approach = (desired - position - source_at_contact).limit_length(0.55)
			else:
				attack_approach = gap.normalized() * clampf(gap.length() - data.spacing - source_at_contact.dot(gap.normalized()), 0, 0.55)
	# Let visible footwork cover distance before the source strike begins. A
	# half-meter warp during a jab makes a planted leg slide across the floor.
	if player and attack_approach.length() > 0.09:
		data.windup = clampf(0.13 + attack_approach.length() * 0.16, 0.14, 0.22)
		for key in ["contact", "link", "duration"]:
			data[key] += data.windup
	combo_age = data.duration + 0.7
	visual.play_move(data, 0.095)
	strike_started.emit(self)
	return true

func request_evade(direction: Vector3) -> bool:
	if state == State.ATTACK and state_time >= move.contact + 0.04:
		state = State.READY
	if state != State.READY or stamina < 10:
		return false
	state = State.EVADE
	state_time = 0
	stamina -= 10
	blocking = false
	buffered = ""
	evade_direction = direction.normalized() if direction.length() > 0.1 else -facing
	var side: float = evade_direction.dot(visual.basis.x)
	visual.play_clip("KarateSlipLeft" if side < -0.25 else "KarateSlipRight", 2.2, 0.07)
	return true

func request_throw(victim: CharacterBody3D) -> bool:
	if state == State.ATTACK and state_time >= move.link:
		state = State.READY
	if state != State.READY or stamina < 14 or not is_instance_valid(victim):
		return false
	if not victim.is_available() or victim.position.distance_to(position) > 1.3 or not clear_to(victim):
		return false
	state = State.THROW
	state_time = 0
	stamina -= 14
	blocking = false
	buffered = ""
	grabbed = victim
	pair_kind = "hold"
	did_contact = false
	face(victim.position - position)
	pair_forward = facing
	visual.play_clip("Guard", 1, 0.14)
	victim.state = State.CLINCH
	victim.state_time = 0
	victim.held_by = self
	victim.buffered = ""
	victim.blocking = false
	victim.velocity = Vector3.ZERO
	victim.face(position - victim.position)
	victim.visual.play_clip("Guard", 1, 0.14)
	add_collision_exception_with(victim)
	victim.add_collision_exception_with(self)
	return true

func clear_to(other: CharacterBody3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, other.global_position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func is_available() -> bool:
	return state in [State.READY, State.ATTACK, State.HIT, State.EVADE] and health > 0

func set_guard(value: bool) -> void:
	if value and state == State.ATTACK and state_time >= move.contact + 0.06:
		buffered = ""
		_ready_stance()
	var next := value and state == State.READY and stamina > 0
	if next and not blocking:
		block_age = 0
	blocking = next

func take_hit(amount: float, attacker: CharacterBody3D, force: float = 0.7, knockdown: bool = false, reaction: String = "head") -> String:
	if state in [State.KO, State.DOWN, State.GETUP, State.CLINCH] or (state == State.EVADE and state_time < 0.35):
		return "miss"
	var toward := (attacker.position - position).normalized()
	if blocking and toward.dot(facing) > 0.1:
		stamina = maxf(0, stamina - amount * 0.55)
		if block_age < 0.18 and stamina > 0:
			_begin_counter(attacker)
			return "parry"
		if stamina > 0:
			visual.play_clip("Guard", 1, 0.045)
			return "block"
	health = maxf(0, health - amount)
	last_hit_by = attacker
	buffered = ""
	blocking = false
	if health <= 0 or knockdown:
		knock_down(-toward * minf(force, 1.1))
	else:
		stagger(0.31 if player else 0.43, -toward * minf(force, 0.75), reaction)
	return "hit"

func stagger(duration: float, impulse: Vector3, reaction: String = "body") -> void:
	if state in [State.KO, State.DOWN]:
		return
	_cancel_clinch()
	counter_target = null
	state = State.HIT
	state_time = 0
	hit_duration = duration
	buffered = ""
	velocity = impulse
	visual.play_clip("HitHead" if reaction in ["head", "left", "right"] else "Hit", 1, 0.025)
	visual.reaction = reaction
	visual.reaction_duration = duration

func _ready_stance() -> void:
	state = State.READY
	state_time = 0
	visual.play_clip("FightIdle", 1, 0.16)

func step(delta: float) -> void:
	state_time += delta
	if counter_cue != null:
		counter_cue.visible = state == State.ATTACK and state_time < move.contact
		if counter_cue.visible:
			var ready_to_counter: bool = move.contact - state_time < 0.17
			counter_cue.text = "Q" if ready_to_counter else "!"
			counter_cue.modulate = Color("fff0bb") if ready_to_counter else Color("c39056")
	combo_age = maxf(0, combo_age - delta)
	stamina = minf(100, stamina + delta * (9 if blocking else 20))
	block_age += delta
	if state == State.CLINCH:
		if not is_instance_valid(held_by):
			_ready_stance()
		return
	if state == State.COUNTER:
		_step_counter(delta)
		return
	if state == State.THROW:
		_step_pair(delta)
		return
	match state:
		State.READY:
			var wanted := drive * (2.1 if blocking else 4.1)
			velocity.x = move_toward(velocity.x, wanted.x, delta * 25)
			velocity.z = move_toward(velocity.z, wanted.z, delta * 25)
			if is_instance_valid(target) and target.is_available() and position.distance_to(target.position) < 3.0:
				face(target.position - position, delta)
			elif drive.length() > 0.1:
				face(drive, delta)
		State.ATTACK:
			var foot_strike: bool = move.shape.ends_with("kick") or move.shape == "knee"
			var anticipation: float = float(move.get("windup", 0.0))
			var time: float = maxf(0, state_time - anticipation)
			var previous_time: float = maxf(0, state_time - delta - anticipation)
			var contact_time: float = move.contact - anticipation
			var plant_time := maxf(0.07, contact_time - 0.065)
			visual.rotation.y = lerp_angle(attack_start_yaw, attack_end_yaw, smoothstep(0, anticipation if anticipation > 0 else plant_time, state_time))
			facing = Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))
			if state_time < anticipation:
				attack_step = drive * (0.10 if foot_strike else 0.20)
			var step_delta := smoothstep(0, anticipation, state_time) - smoothstep(0, anticipation, maxf(0, state_time - delta)) if anticipation > 0 else 0.0
			var motion := (attack_approach + attack_step) * step_delta / maxf(delta, 0.001)
			if time > contact_time + 0.14:
				motion += drive * (0.45 if foot_strike else 0.85) * smoothstep(contact_time + 0.14, move.duration, time)
			if move.get("captured", false):
				var now: Vector3 = visual.root_offset(move.clip, time * move.rate)
				var before: Vector3 = visual.root_offset(move.clip, previous_time * move.rate)
				motion += attack_basis * (now - before) / maxf(delta, 0.001)
			velocity.x = motion.x
			velocity.z = motion.z
		State.EVADE:
			var now: Vector3 = visual.root_offset(visual.active_clip, state_time * visual.motion_rate)
			var before: Vector3 = visual.root_offset(visual.active_clip, maxf(0, state_time - delta) * visual.motion_rate)
			var displacement: Vector3 = visual.basis * (now - before)
			var assist := smoothstep(0, 0.30, state_time) - smoothstep(0, 0.30, maxf(0, state_time - delta))
			displacement += evade_direction * assist * 0.34
			velocity.x = displacement.x / maxf(delta, 0.001)
			velocity.z = displacement.z / maxf(delta, 0.001)
			if state_time >= 0.49:
				_ready_stance()
		State.HIT:
			velocity.x = move_toward(velocity.x, 0, delta * 9)
			velocity.z = move_toward(velocity.z, 0, delta * 9)
			if state_time >= hit_duration:
				_ready_stance()
		State.DOWN, State.KO:
			velocity.x = move_toward(velocity.x, 0, delta * 8)
			velocity.z = move_toward(velocity.z, 0, delta * 8)
			if state == State.DOWN and state_time >= 1.75:
				state = State.GETUP
				state_time = 0
				visual.play_clip("Rise", 1, 0.10)
		State.GETUP:
			velocity = Vector3.ZERO
			if state_time >= 1.42:
				collision_layer = 2 if player else 4
				collision_mask = 7
				_ready_stance()
	velocity.y = -1 if is_on_floor() else velocity.y - delta * 20
	move_and_slide()
	var planar := Vector3(velocity.x, 0, velocity.z)
	var travel_angle := facing.signed_angle_to(planar.normalized(), Vector3.UP) if planar.length() > 0.1 else 0.0
	if state == State.ATTACK and state_time <= move.contact and is_instance_valid(target) and target.is_available() and position.distance_to(target.position) < 1.8:
		var toward := (target.position - position).normalized()
		var aim: Vector3 = target.visual.bone_world("Neck")
		if move.height < 0.7:
			aim = target.visual.bone_world("LeftLeg")
		elif move.height < 1.2:
			aim = target.visual.bone_world("Spine")
		visual.strike_goal = aim - toward * 0.08
		visual.strike_has_goal = true
	visual.tick(delta, planar.length(), travel_angle)
	if state == State.ATTACK:
		if not did_contact and state_time >= move.contact:
			contact.emit(self, move)
			if state_time >= move.contact + 0.07:
				did_contact = true
		if state != State.ATTACK:
			return
		if not buffered.is_empty() and state_time >= move.link:
			var next := buffered
			buffered = ""
			if is_instance_valid(buffered_target):
				target = buffered_target
			buffered_target = null
			if _start_attack(next):
				return
		if state_time >= move.duration:
			_ready_stance()

func knock_down(impulse: Vector3, settled: bool = false) -> void:
	_cancel_clinch()
	counter_target = null
	state = State.KO if health <= 0 else State.DOWN
	state_time = 1.15 if settled else 0.0
	blocking = false
	buffered = ""
	velocity = Vector3(impulse.x, 0, impulse.z).limit_length(1.1)
	collision_layer = 0
	collision_mask = 1
	visual.play_clip("Down", 2.1, 0.13)
	if settled:
		visual.motion_time = 2.4 / 2.1
		visual.blend_time = 0
		visual.tick(0)

func _step_pair(delta: float) -> void:
	if not is_instance_valid(grabbed) or grabbed.state != State.CLINCH or not clear_to(grabbed):
		_cancel_clinch()
		_ready_stance()
		return
	velocity = Vector3.ZERO
	var side := Vector3(pair_forward.z, 0, -pair_forward.x)
	var curve := sin(clampf(state_time / 1.28, 0, 1) * PI) * (0.22 if pair_kind == "sweep" else 0.07)
	var desired := position + pair_forward * 0.60 + side * curve
	var shift := desired - grabbed.position
	shift.y = 0
	grabbed.velocity = (shift * 12).limit_length(2.8)
	grabbed.velocity.y = -1
	grabbed.move_and_slide()
	grabbed.face(position - grabbed.position, delta)
	var time := minf(state_time, 0.16) if pair_kind == "hold" else state_time
	grabbed.visual.pair_pose(time, pair_kind, true, visual)
	visual.pair_pose(time, pair_kind, false, grabbed.visual)
	if pair_kind == "hold":
		if state_time > 1.6:
			_cancel_clinch()
			_ready_stance()
		return
	if not did_contact and state_time >= (0.46 if pair_kind == "knee" else 0.43):
		did_contact = true
		throw_release.emit(self, grabbed)
	if state_time >= 1.28:
		var victim := grabbed
		_detach_pair()
		victim.knock_down(Vector3.ZERO, true)
		_ready_stance()

func _detach_pair() -> void:
	if is_instance_valid(grabbed):
		remove_collision_exception_with(grabbed)
		grabbed.remove_collision_exception_with(self)
		grabbed.held_by = null
	grabbed = null
	counter_target = null

func _begin_counter(attacker: CharacterBody3D) -> void:
	# Both fighters share one timeline from interception through the landing.
	_cancel_clinch()
	counter_incoming = attacker.move.duplicate()
	pair_kind = "kick_counter" if str(counter_incoming.get("shape", "")).ends_with("kick") else "hand_counter"
	grabbed = attacker
	counter_target = attacker
	counter_stage = 0
	counter_did_land = false
	state = State.COUNTER
	state_time = 0
	blocking = false
	buffered = ""
	velocity = Vector3.ZERO
	face(attacker.position - position)
	pair_forward = facing
	visual.play_clip("Guard", 1, 0.08)
	attacker.state = State.CLINCH
	attacker.state_time = 0
	attacker.held_by = self
	attacker.buffered = ""
	attacker.blocking = false
	attacker.velocity = Vector3.ZERO
	attacker.visual.play_clip("Guard", 1, 0.08)
	add_collision_exception_with(attacker)
	attacker.add_collision_exception_with(self)

func _step_counter(delta: float) -> void:
	if not is_instance_valid(grabbed) or grabbed.state != State.CLINCH or not clear_to(grabbed):
		_cancel_clinch()
		_ready_stance()
		return
	velocity = Vector3.ZERO
	var side := Vector3(pair_forward.z, 0, -pair_forward.x)
	var turn := smoothstep(0.88, 1.60, state_time)
	var distance := 0.60
	if pair_kind == "kick_counter":
		distance += smoothstep(0.83, 1.10, state_time) * 0.33
		distance += smoothstep(1.16, 1.65, state_time) * 0.40
	else:
		distance += turn * 0.17
	var desired := position + pair_forward * distance + side * turn * 0.20
	var shift := desired - grabbed.position
	shift.y = 0
	grabbed.velocity = (shift * 14).limit_length(2.8)
	grabbed.velocity.y = -1
	grabbed.move_and_slide()
	grabbed.face(position - grabbed.position, delta)
	grabbed.visual.counter_pose(state_time, pair_kind, true, visual, counter_incoming)
	visual.counter_pose(state_time, pair_kind, false, grabbed.visual, counter_incoming)
	for stage in [1, 2, 3]:
		var impact: float = Counter.CONTACTS[stage - 1]
		if counter_stage < stage and state_time >= impact:
			counter_stage = stage
			grabbed.health = maxf(0, grabbed.health - Counter.DAMAGE[stage - 1])
			grabbed.last_hit_by = self
			successful_contacts += 1
			counter_impact.emit(self, grabbed, stage)
	if not counter_did_land and state_time >= Counter.LANDING:
		counter_did_land = true
		counter_landed.emit(self, grabbed)
	if state_time >= Counter.DURATION:
		var victim := grabbed
		_detach_pair()
		victim.knock_down(Vector3.ZERO, true)
		_ready_stance()
		if not buffered.is_empty():
			var next := buffered
			buffered = ""
			target = buffered_target if is_instance_valid(buffered_target) else null
			buffered_target = null
			_start_attack(next)

func _cancel_clinch() -> void:
	var victim := grabbed
	_detach_pair()
	if is_instance_valid(victim) and victim.state == State.CLINCH:
		if victim.health <= 0:
			victim.knock_down(Vector3.ZERO)
		else:
			victim._ready_stance()
