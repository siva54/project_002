extends Node3D

const Fighter := preload("res://scripts/kung_fu_fighter.gd")
const Surfaces := preload("res://scripts/surface_library.gd")
var hero: CharacterBody3D
var rivals: Array[CharacterBody3D] = []
var actors: Node3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.25
var playing := false
var round_number := 1
var round_wait := 0.0
var hits := 0
var flow_time := 0.0
var hit_pause := 0.0
var shake := 0.0
var pause_panel: Control
var title: Label
var subtitle: Label
var start_button: Button
var round_label: Label
var notice: Label
var flow_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var enemy_bar: ProgressBar
var enemy_label: Label
var sound_players: Array[AudioStreamPlayer] = []
var sound_bank := {}
var audio_index := 0
var training_dummy := false
var camera_focus := Vector3.ZERO
var finisher_camera_weight := 0.0
var finisher_camera_offset := Vector3.ZERO
var impact_offset := Vector3.ZERO
var impact_velocity := Vector3.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input()
	_build_courtyard()
	_build_ui()
	_build_audio()
	reset_match()
	show_title()

func stop_audio() -> void:
	for voice in sound_players:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	stop_audio()
	sound_bank.clear()

func _register_input() -> void:
	for action in {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "guard": KEY_Q, "evade": KEY_SPACE, "throw": KEY_G, "retry": KEY_R}:
		var keys := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "guard": KEY_Q, "evade": KEY_SPACE, "throw": KEY_G, "retry": KEY_R}
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if playing and not get_tree().paused:
				pause_match()
			elif playing:
				resume_match()
			return
		if event.physical_keycode == KEY_R:
			reset_match()
			resume_match()
			return
		if event.physical_keycode == KEY_TAB and playing:
			if get_tree().paused:
				resume_match()
			else:
				pause_match()
				title.text = "MOVE LIST"
				subtitle.add_theme_font_size_override("font_size", 17)
				subtitle.text = "PUNCH CHAIN\nJab > Cross > Lead hook > Rear hook > Uppercut > Crane straight > Elbow\n\nMIX IN KICKS\nJab > Low kick > Shovel hook > Uppercut\nCross > Knee > Elbow   /   Hook > Roundhouse > Crane straight\nFront kick > Side kick > Stepping karate straight\n\nQ at the attack cue: intercept > body strike > finisher\nG: clinch, then LMB: knee takedown / RMB: sweep\nMove while striking. Aim WASD toward the next opponent."
			return
	if not playing or get_tree().paused or hero.health <= 0:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch - event.relative.y * 0.002, -0.55, 0.12)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack("light")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			attack("kick")
	if event.is_action_pressed("evade"):
		if hero.request_evade(_movement_direction()):
			_play_sound("swish")
	if event.is_action_pressed("throw"):
		grapple()

func _movement_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := -camera.global_basis.z
	forward.y = 0
	var right := camera.global_basis.x
	right.y = 0
	return (right.normalized() * input.x - forward.normalized() * input.y).limit_length(1.0)

func attack(kind: String) -> bool:
	return hero.request_attack(kind, _select_rival(_movement_direction()))

func grapple() -> bool:
	if hero.state == Fighter.State.THROW:
		return hero.request_attack("kick")
	var victim := _select_rival(_movement_direction())
	if victim == null or not _clear_line(hero, victim):
		return false
	var accepted: bool = hero.request_throw(victim)
	if accepted:
		notice.text = "CLINCH   /   LMB Knee     RMB Sweep"
		_play_sound("swish")
	return accepted

func reset_match() -> void:
	get_tree().paused = false
	if is_instance_valid(actors):
		remove_child(actors)
		actors.queue_free()
	actors = Node3D.new()
	actors.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actors)
	rivals.clear()
	hero = Fighter.new()
	hero.player = true
	actors.add_child(hero)
	hero.position = Vector3(0, 0.03, 2.5)
	hero.contact.connect(_contact)
	hero.throw_release.connect(_throw_release)
	hero.counter_impact.connect(_counter_impact)
	hero.counter_landed.connect(_counter_landed)
	hero.strike_started.connect(func(_fighter): _play_sound("swish"))
	round_number = 1
	round_wait = 0
	hits = 0
	flow_time = 0
	hit_pause = 0
	_spawn_rivals(2)
	yaw = 0
	pitch = -0.25
	camera.position = hero.position + Vector3(0, 3.2, 5.8)
	camera.look_at(hero.position + Vector3.UP)
	camera_focus = hero.position + Vector3.UP
	finisher_camera_weight = 0
	impact_offset = Vector3.ZERO
	impact_velocity = Vector3.ZERO
	notice.text = "Punch and kick while moving. TAB: move list."
	_refresh_hud()

func _spawn_rivals(count: int) -> void:
	for i in count:
		var rival := Fighter.new()
		actors.add_child(rival)
		rival.position = Vector3(-1.7 + i * 3.4 if count > 1 else 0, 0.03, -1.3 - i * 0.5)
		rival.face(hero.position - rival.position)
		rival.ai_delay = 0.9 + i * 0.55
		rival.contact.connect(_contact)
		rival.throw_release.connect(_throw_release)
		rival.counter_impact.connect(_counter_impact)
		rival.counter_landed.connect(_counter_landed)
		rival.strike_started.connect(func(_fighter): _play_sound("swish"))
		rivals.append(rival)

func show_title() -> void:
	playing = false
	get_tree().paused = true
	title.text = "FLOW STATE"
	subtitle.text = "CONNECTED COMBAT\n\nFourteen strikes. Branching combinations.\nTwo counter finishers. Clinch knees and sweeps."
	start_button.text = "ENTER THE COURTYARD"
	pause_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func pause_match() -> void:
	get_tree().paused = true
	subtitle.add_theme_font_size_override("font_size", 20)
	title.text = "TAKE A BREATH"
	subtitle.text = "Your bout is paused."
	start_button.text = "CONTINUE SPARRING"
	pause_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_match() -> void:
	if hero.health <= 0 or round_number > 3:
		reset_match()
	playing = true
	get_tree().paused = false
	pause_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not playing or get_tree().paused:
		return
	if hit_pause > 0:
		hit_pause -= delta
		_update_camera(delta)
		return
	flow_time = maxf(0, flow_time - delta)
	if flow_time <= 0:
		hits = 0
	hero.drive = _movement_direction()
	if hero.state == Fighter.State.READY:
		hero.target = _select_rival(hero.drive)
	hero.set_guard(Input.is_action_pressed("guard"))
	if hero.blocking:
		var near := _nearest_rival()
		if near != null:
			hero.face(near.position - hero.position)
	hero.step(delta)
	var active_attacker: bool = hero.state in [Fighter.State.THROW, Fighter.State.COUNTER]
	for rival in rivals:
		if is_instance_valid(rival) and rival.state in [Fighter.State.ATTACK, Fighter.State.COUNTER]:
			active_attacker = true
	for rival in rivals:
		if not is_instance_valid(rival):
			continue
		rival.drive = Vector3.ZERO
		if not training_dummy and rival.is_available() and hero.health > 0:
			var offset: Vector3 = hero.position - rival.position
			offset.y = 0
			rival.target = hero
			rival.ai_delay = maxf(0, rival.ai_delay - delta)
			if rival.state == Fighter.State.READY:
				rival.face(offset)
				if active_attacker and offset.length() < 2.4:
					var side := Vector3(offset.z, 0, -offset.x).normalized()
					rival.drive = side * (0.32 if rivals.find(rival) % 2 else -0.32) - offset.normalized() * 0.20
				elif offset.length() > 1.35:
					rival.drive = offset.normalized() * (0.47 if active_attacker else 0.7)
				elif not active_attacker and rival.ai_delay <= 0:
					rival.request_attack("kick" if rival.chain_index % 3 == 2 else "light")
					rival.ai_delay = 0.85
					active_attacker = true
				elif offset.length() < 1.0:
					rival.drive = -offset.normalized() * 0.3
			rival.blocking = false
		rival.step(delta)
	_update_camera(delta)
	_refresh_hud()
	if hero.health <= 0:
		round_wait += delta
		if round_wait > 1.2:
			_end_match(false)
		return
	var alive := rivals.any(func(rival): return is_instance_valid(rival) and rival.health > 0)
	if not alive and hero.state not in [Fighter.State.COUNTER, Fighter.State.THROW]:
		round_wait += delta
		notice.text = "BOUT COMPLETE"
		if round_wait > 2.0:
			round_number += 1
			round_wait = 0
			if round_number > 3:
				_end_match(true)
			else:
				hero.health = minf(100, hero.health + 25)
				hero.stamina = 100
				for rival in rivals:
					rival.queue_free()
				rivals.clear()
				hero.position = Vector3(0, 0.03, 2.5)
				_spawn_rivals(round_number + 1)
				notice.text = "BOUT %d  /  Stay in motion" % round_number

func _select_rival(direction: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D
	var best_score := -100.0
	for rival in rivals:
		if not is_instance_valid(rival) or not rival.is_available() or not _clear_line(hero, rival):
			continue
		var offset: Vector3 = rival.position - hero.position
		if offset.length() > 4.5:
			continue
		var score := -offset.length()
		if direction.length() > 0.1:
			score += direction.normalized().dot(offset.normalized()) * 4.0
		elif rival == hero.target:
			score += 0.65
		if score > best_score:
			best_score = score
			best = rival
	return best

func _nearest_rival() -> CharacterBody3D:
	var nearest: CharacterBody3D
	var distance := 5.0
	for rival in rivals:
		if not is_instance_valid(rival) or not rival.is_available():
			continue
		var next := hero.position.distance_to(rival.position)
		if next < distance:
			distance = next
			nearest = rival
	return nearest

func _clear_line(from: CharacterBody3D, to: CharacterBody3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(from.position + Vector3.UP, to.position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _contact(attacker: CharacterBody3D, move: Dictionary) -> void:
	var victims: Array = rivals.duplicate() if attacker == hero else [hero]
	if is_instance_valid(attacker.target) and attacker.target in victims:
		victims.erase(attacker.target)
		victims.push_front(attacker.target)
	for victim in victims:
		if not is_instance_valid(victim) or victim == attacker or not victim.is_available():
			continue
		var offset: Vector3 = victim.position - attacker.position
		offset.y = 0
		if offset.length() > 1.65 or offset.normalized().dot(attacker.facing) < 0.25 or not _clear_line(attacker, victim):
			continue
		var limb: Vector3 = attacker.visual.bone_world(move.bone)
		var lower: Vector3 = victim.visual.bone_world("Hips")
		var upper: Vector3 = victim.visual.bone_world("Head")
		if move.reaction == "leg":
			lower = victim.position + Vector3.UP * 0.28
			upper = victim.position + Vector3.UP * 0.65
		var body_point := Geometry3D.get_closest_point_to_segment(limb, lower, upper)
		var radius := 0.42 if move.shape in ["knee", "elbow"] else 0.36
		if limb.distance_to(body_point) > radius:
			continue
		var result: String = victim.take_hit(move.damage, attacker, 0.65, move.get("finisher", false), move.reaction)
		if result == "miss":
			continue
		attacker.did_contact = true
		attacker.successful_contacts += 1
		attacker.last_contact_position = limb.lerp(body_point, 0.5)
		_play_sound("block" if result in ["block", "parry"] else ("kick" if move.shape.ends_with("kick") else "hit"))
		shake = 0.045 if result == "hit" else 0.018
		if result == "hit":
			impact_velocity += (victim.position - attacker.position).normalized() * (0.25 if move.damage < 15 else 0.4)
		# Regular contacts never stop either fighter's animation clock.
		hit_pause = 0.025 if move.get("finisher", false) else 0.0
		_impact(attacker.last_contact_position, result == "parry")
		if result == "parry":
			notice.text = "COUNTER / INTERCEPT"
		elif result == "block":
			notice.text = "GUARD"
		elif attacker == hero:
			hits += 1
			flow_time = 2.5
			notice.text = move.label
		else:
			hits = 0
			notice.text = "Q Counter    SPACE Sidestep"
		break

func _throw_release(attacker: CharacterBody3D, victim: CharacterBody3D) -> void:
	if victim.state != Fighter.State.CLINCH or not _clear_line(attacker, victim):
		return
	victim.health = maxf(0, victim.health - (30 if attacker.pair_kind == "knee" else 24))
	victim.last_hit_by = attacker
	_play_sound("hit")
	shake = 0.04
	hits += 1
	flow_time = 2.5
	notice.text = "CLINCH KNEE" if attacker.pair_kind == "knee" else "LEG SWEEP"

func _counter_impact(attacker: CharacterBody3D, victim: CharacterBody3D, stage: int) -> void:
	_play_sound("finish" if stage == 3 else "hit")
	shake = 0.025 if stage < 3 else 0.04
	impact_velocity += attacker.pair_forward * (0.4 if stage < 3 else 1.0) + Vector3.UP * 0.15
	var data: Dictionary = Fighter.Counter.attack(attacker.pair_kind, stage - 1)
	var point: Vector3 = attacker.visual.bone_world(data.bone)
	_impact(point, false)
	if attacker == hero:
		hits += 1
		flow_time = 3.0
		notice.text = "COUNTER / " + data.label if stage < 3 else ("COUNTER FINISHER / DRIVING SIDE KICK" if attacker.pair_kind == "kick_counter" else "COUNTER FINISHER / SWEEP & DRIVE")

func _counter_landed(_attacker: CharacterBody3D, victim: CharacterBody3D) -> void:
	_play_sound("landing")
	impact_velocity += Vector3.DOWN * 0.55
	var at: Vector3 = victim.visual.bone_world("Hips")
	at.y = 0.04
	for i in 10:
		var dust := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.035
		mesh.height = 0.045
		mesh.radial_segments = 8
		mesh.rings = 4
		dust.mesh = mesh
		var material := _material(Color(0.65, 0.65, 0.59, 0.22))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dust.material_override = material
		actors.add_child(dust)
		dust.position = at
		var radial := Vector3(sin(i * TAU / 10), 0.1, cos(i * TAU / 10))
		var tween := dust.create_tween().set_parallel()
		tween.tween_property(dust, "position", at + radial * 0.5, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(dust, "scale", Vector3(2.0, 0.5, 2.0), 0.28)
		tween.tween_property(material, "albedo_color:a", 0.0, 0.28)
		tween.chain().tween_callback(dust.queue_free)

func _end_match(won: bool) -> void:
	get_tree().paused = true
	title.text = "FIND YOUR FLOW" if won else "RISE AGAIN"
	subtitle.text = "Three bouts complete." if won else "Every exchange is practice.\nTime a guard or evade, then answer with a combination."
	start_button.text = "SPAR AGAIN"
	pause_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _update_camera(delta: float) -> void:
	var focus: Vector3 = hero.position + Vector3.UP * 1.05
	var paired: bool = is_instance_valid(hero.grabbed)
	var rival: CharacterBody3D = hero.grabbed if paired else _nearest_rival()
	if rival != null:
		focus += (rival.position - hero.position).limit_length(2.5) * 0.35
	var counter_active: bool = hero.state == Fighter.State.COUNTER
	if counter_active:
		var side := Vector3(hero.pair_forward.z, 0, -hero.pair_forward.x)
		if hero.state_time < 0.10:
			var sign_side := 1.0 if (camera.position - hero.position).dot(side) > 0 else -1.0
			finisher_camera_offset = side * sign_side * 3.2 - hero.pair_forward * 1.6 + Vector3.UP * 1.65
		focus.y -= smoothstep(1.16, 1.90, hero.state_time) * 0.2
	var framing := 1.0 if counter_active and hero.state_time < 1.80 else 0.0
	finisher_camera_weight = move_toward(finisher_camera_weight, framing, delta * 2.0)
	camera_focus = camera_focus.lerp(focus, 1.0 - exp(-delta * 9))
	camera.fov = lerpf(camera.fov, 47.0 if counter_active else (49.0 if paired else 54.0), 1.0 - exp(-delta * 4))
	var offset := Basis(Vector3.UP, yaw) * Vector3(2.8, 1.45 - pitch * 0.8, 2.8)
	offset = offset.lerp(finisher_camera_offset, finisher_camera_weight)
	var desired := hero.position + offset
	var ray := PhysicsRayQueryParameters3D.create(focus, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		desired = hit.position + hit.normal * 0.25
	camera.position = camera.position.lerp(desired, 1.0 - exp(-delta * 10))
	shake = move_toward(shake, 0, delta * 0.4)
	impact_velocity += (-impact_offset * 95.0 - impact_velocity * 18.0) * delta
	impact_offset += impact_velocity * delta
	camera.look_at(camera_focus + impact_offset)

func _impact(at: Vector3, parry: bool) -> void:
	# Small short-lived contact marks, with no energy-orb presentation.
	for i in 5:
		var mote := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.009
		sphere.height = 0.018
		sphere.radial_segments = 6
		sphere.rings = 3
		mote.mesh = sphere
		mote.material_override = _material(Color("e9be78") if parry else Color("dfd3b9"))
		actors.add_child(mote)
		mote.position = at
		var tween := mote.create_tween().set_parallel()
		tween.tween_property(mote, "position", at + Vector3(sin(i * 2.4), cos(i * 1.8), cos(i)) * 0.3, 0.15)
		tween.tween_property(mote, "scale", Vector3.ZERO, 0.15)
		tween.chain().tween_callback(mote.queue_free)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material

func _box(at: Vector3, dimensions: Vector3, color: Color, solid: bool = true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	add_child(body)
	body.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.material_override = _material(color)
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dimensions
		collision.shape = box
		body.add_child(collision)
	return body

func _build_courtyard() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var env := environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202b30")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b9cbd0")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0d7")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	for setup in [
		{"position": Vector3(2.5, 3.2, 3.4), "color": Color("fff0dd"), "energy": 1.2},
		{"position": Vector3(-2.7, 3.0, -3.2), "color": Color("dce9ed"), "energy": 1.5},
	]:
		var fill := OmniLight3D.new()
		fill.position = setup.position
		fill.light_color = setup.color
		fill.light_energy = setup.energy
		fill.omni_range = 7.0
		fill.shadow_enabled = false
		add_child(fill)
	var floor := _box(Vector3(0, -0.22, 0), Vector3(20, 0.4, 20), Color("7a8176"))
	floor.get_child(0).material_override = Surfaces.pbr("concrete", Color("a5a799"), 0.45)
	# Inlaid training square and fine stone joints keep distance readable.
	var mat := _box(Vector3(0, 0.0, 0), Vector3(10.5, 0.025, 10.5), Color("293b3a"), false)
	mat.get_child(0).material_override = Surfaces.pbr("concrete", Color("465a56"), 1.2)
	for axis in [-5.3, 5.3]:
		_box(Vector3(axis, 0.02, 0), Vector3(0.07, 0.015, 10.7), Color("c2ad7a"), false)
		_box(Vector3(0, 0.02, axis), Vector3(10.7, 0.015, 0.07), Color("c2ad7a"), false)
	for i in range(-4, 5):
		_box(Vector3(i * 2, 0.004, 0), Vector3(0.018, 0.008, 19), Color("596059"), false)
		_box(Vector3(0, 0.004, i * 2), Vector3(19, 0.008, 0.018), Color("596059"), false)
	for x in [-10, 10]:
		_box(Vector3(x, 2.5, 0), Vector3(0.4, 5, 20), Color("505954"))
	for z in [-10, 10]:
		_box(Vector3(0, 2.5, z), Vector3(20, 5, 0.4), Color("60665b"))
	for x in [-8, -4, 0, 4, 8]:
		_box(Vector3(x, 2.6, -9.7), Vector3(0.26, 5.2, 0.4), Color("362f28"))
		_box(Vector3(x, 4.9, -9.6), Vector3(4.1, 0.28, 0.6), Color("3f352b"))
		if x != 0:
			_box(Vector3(x + 1.7, 2.5, -9.5), Vector3(2.4, 3.6, 0.08), Color("c1b69a"), false)
			for slat in range(6):
				_box(Vector3(x + 0.7 + slat * 0.4, 2.5, -9.4), Vector3(0.06, 3.8, 0.06), Color("484036"), false)
	var sign := Label3D.new()
	sign.text = "F L O W\n\nS T A T E"
	sign.font_size = 70
	sign.pixel_size = 0.012
	sign.position = Vector3(0, 3, -9.3)
	sign.modulate = Color("e4d7b6")
	add_child(sign)
	for x in [-8, 8]:
		_box(Vector3(x, 0.5, -7.5), Vector3(1.7, 1, 1.7), Color("373f39"))
		for stem in 7:
			_box(Vector3(x - 0.55 + stem * 0.18, 1.8, -7.5 + sin(stem) * 0.3), Vector3(0.05, 3.1 + sin(stem) * 0.5, 0.05), Color("566b48"), false)
	camera = Camera3D.new()
	camera.fov = 54
	add_child(camera)
	camera.current = true

func _label(text: String, size: int, color: Color = Color("ece3cf")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.02, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _bar(color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 6)
	bar.show_percentage = false
	bar.value = 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.12, 0.12, 0.8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var stats := VBoxContainer.new()
	stats.position = Vector2(38, 30)
	stats.add_theme_constant_override("separation", 10)
	ui.add_child(stats)
	stats.add_child(_label("F L O W   S T A T E", 20))
	round_label = _label("BOUT 01 / 03", 12, Color("d1bf94"))
	stats.add_child(round_label)
	health_bar = _bar(Color("ded0ac"), 245)
	stats.add_child(health_bar)
	stamina_bar = _bar(Color("7fa8a0"), 245)
	stats.add_child(stamina_bar)
	var enemy_stats := VBoxContainer.new()
	enemy_stats.position = Vector2(990, 36)
	ui.add_child(enemy_stats)
	enemy_label = _label("SPARRING PARTNER", 12)
	enemy_stats.add_child(enemy_label)
	enemy_bar = _bar(Color("b97360"), 250)
	enemy_stats.add_child(enemy_bar)
	flow_label = _label("", 28, Color("ebc17b"))
	flow_label.position = Vector2(38, 160)
	ui.add_child(flow_label)
	notice = _label("", 16)
	notice.position = Vector2(300, 680)
	notice.size.x = 680
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(notice)
	var controls := _label("LMB  Punch     RMB  Kick     Q  Counter / Guard     SPACE  Sidestep     G  Clinch", 14, Color("ddd2bd"))
	controls.position = Vector2(160, 740)
	controls.size.x = 960
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(controls)
	var small := _label("WASD  Move / Aim    MOUSE  Orbit    TAB  Moves    ESC  Pause    R  Restart", 12, Color("aebbb2"))
	small.position = Vector2(360, 766)
	ui.add_child(small)
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(pause_panel)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.055, 0.075, 0.07, 0.9)
	pause_panel.add_child(shade)
	var content := VBoxContainer.new()
	content.position = Vector2(260, 150)
	content.size = Vector2(760, 520)
	content.add_theme_constant_override("separation", 26)
	pause_panel.add_child(content)
	var eyebrow := _label("P R O J E C T   0 0 2   /   M A R T I A L   A R T S", 13, Color("bd9861"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	title = _label("FLOW STATE", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	subtitle = _label("", 20, Color("bdc9be"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)
	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(760, 64)
	start_button.add_theme_font_size_override("font_size", 19)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("bd9861")
	style.set_corner_radius_all(3)
	start_button.add_theme_stylebox_override("normal", style)
	start_button.add_theme_color_override("font_color", Color("151e1a"))
	start_button.pressed.connect(resume_match)
	content.add_child(start_button)
	var guide := _label("Mix punches and kicks to branch the combination. Move while attacking.\nTime Q to counter. G grabs, then LMB knees or RMB sweeps.\nTAB opens the move list. SPACE slips away and keeps you grounded.", 16, Color("acb9ae"))
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(guide)

func _refresh_hud() -> void:
	health_bar.value = hero.health
	stamina_bar.value = hero.stamina
	round_label.text = "BOUT %02d / 03  /  VITALITY & STAMINA" % mini(round_number, 3)
	flow_label.text = "%d HIT FLOW" % hits if hits > 1 else ""
	var near: CharacterBody3D = hero.grabbed if is_instance_valid(hero.grabbed) else _nearest_rival()
	enemy_bar.visible = near != null
	enemy_label.visible = near != null
	if near != null:
		enemy_bar.value = near.health
		if hero.state == Fighter.State.COUNTER:
			enemy_label.text = "COUNTER FINISHER"
		elif near.state == Fighter.State.ATTACK:
			var until_contact: float = near.move.contact - near.state_time
			enemy_label.text = "Q  /  COUNTER NOW" if until_contact > 0 and until_contact < 0.17 else "INCOMING"
		else:
			enemy_label.text = "SPARRING PARTNER"

func _build_audio() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 87
	for key in ["swish", "hit", "block", "kick", "finish", "landing"]:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var data := PackedByteArray()
		var count := 9000 if key == "landing" else (6600 if key == "finish" else (4400 if key == "kick" else (3300 if key == "swish" else 2400)))
		data.resize(count * 2)
		var smooth_noise := 0.0
		for i in count:
			var t := float(i) / count
			smooth_noise = lerpf(smooth_noise, random.randf_range(-1, 1), 0.35)
			var envelope := sin(t * PI) * (1 - t) if key == "swish" else exp(-t * 8) * minf(1, t * 45)
			var tone := sin(i * 0.035) * 0.6 if key == "hit" else sin(i * 0.065) * 0.3
			var value := (smooth_noise + tone) * envelope * (0.5 if key == "swish" else 0.85)
			if key in ["kick", "finish", "landing"]:
				var seconds := float(i) / 22050.0
				var frequency := 62.0 if key == "landing" else (78.0 if key == "finish" else 110.0)
				var thump := sin(TAU * frequency * seconds) * exp(-seconds * 19) * minf(1, seconds * 500)
				var snap := random.randf_range(-1, 1) * exp(-seconds * 90) * 0.45
				value = thump * 0.85 + snap + smooth_noise * exp(-seconds * 13) * 0.3
			data.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
		stream.data = data
		sound_bank[key] = stream
	for i in 4:
		var audio := AudioStreamPlayer.new()
		audio.volume_db = -8
		add_child(audio)
		sound_players.append(audio)

func _play_sound(key: String) -> void:
	var audio := sound_players[audio_index % sound_players.size()]
	audio_index += 1
	audio.stream = sound_bank[key]
	audio.pitch_scale = [0.96, 1.02, 0.99, 1.04][audio_index % 4]
	audio.volume_db = -5 if key in ["finish", "landing"] else -8
	audio.play()
