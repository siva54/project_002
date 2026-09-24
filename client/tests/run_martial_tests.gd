extends SceneTree

const Lab = preload("res://scenes/hero_lab.tscn")
const Martial = preload("res://scripts/martial_arts.gd")
var checks := 0
var failures := 0
var lab: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle(body: CharacterBody3D) -> void:
	for i in 15:
		await physics_frame
		body.velocity = Vector3.DOWN * 2
		body.move_and_slide()
	body.velocity = Vector3.ZERO

func prepare_target() -> CharacterBody3D:
	lab.reset_arena()
	await process_frame
	lab.start_play()
	lab.hero.enabled = false
	lab.hero.position = Vector3(0, 0.05, 6)
	var target = get_nodes_in_group("targets")[0]
	target.position = Vector3(0, 0.05, 4.65)
	await settle(lab.hero)
	await settle(target)
	lab.hero.camera.global_position = lab.hero.position + Vector3.UP * 1.3
	lab.hero.camera.look_at(target.position + Vector3.UP * 1.3)
	return target

func _run() -> void:
	lab = Lab.instantiate()
	root.add_child(lab)
	lab.set_physics_process(false)
	lab.loadout = ["bolt", "blink", "shield"]
	var target := await prepare_target()
	for strike in Martial.STRIKES + Martial.GRAPPLES:
		var clip: Animation = lab.hero.visual.body_animation.get_animation("martial/" + strike.clip)
		check(clip != null and clip.loop_mode == Animation.LOOP_NONE, strike.clip + " must be a non-looping skeletal animation")
	lab.hero.visual.body_animation.speed_scale = 1.5
	check(lab.melee_attack() and lab.melee_stage == 0, "First attack must be a jab")
	check(lab.hero.visual.body_animation.speed_scale == 1.0, "Sprinting must not accelerate the contact animation away from damage timing")
	lab._physics_process(0.14)
	check(target.health == 60, "No damage before jab contact")
	lab._physics_process(0.03)
	check(target.health == 30, "Jab contact applies one hit")
	lab._physics_process(0.12)
	lab.melee_attack()
	check(lab.melee_buffered, "Late input must buffer the next strike")
	lab._physics_process(0.20)
	check(lab.melee_stage == 1 and lab.hero.visual.active_clip == "Cross", "Buffered input chains into a cross")
	check(not lab.activate_slot(0), "A power cannot overwrite an active melee animation")
	lab.melee_windup = 0 # Test remaining combo without killing the fixture.
	lab._physics_process(0.57)
	check(lab.melee_attack() and lab.melee_stage == 2, "Third strike must be the front kick")
	lab.melee_windup = 0
	lab._physics_process(1.5)
	check(lab.melee_attack() and lab.melee_stage == 0, "Expired combo must restart at the jab")
	lab.show_menu()
	var windup: float = lab.melee_windup
	lab._physics_process(1)
	check(lab.melee_windup == windup, "Pause must preserve pending strike timing")
	target = await prepare_target()
	check(lab.grapple_attack(), "A close grounded enemy in front can be grabbed")
	check(target.get_meta("state") == "grappled" and target.shot_windup == 0, "Clinch must cancel enemy shooting")
	check(not lab.grapple_attack() and not lab.melee_attack(), "Clinch cannot start another grapple or strike")
	check(target.health == 60, "Grab must not deal damage before landing")
	for step in 21:
		await physics_frame
		lab._physics_process(1.0 / 60)
	check(target.get_meta("state") == "thrown" and target.velocity.y > 0, "Release must give the enemy physical launch velocity")
	var launch_velocity := target.velocity
	var launch_position := target.position
	lab.show_menu()
	for i in 8:
		await physics_frame
		target.update_brain(lab.hero, false, 1.0 / 60)
	check(target.position == launch_position and target.velocity == launch_velocity, "Pausing mid-throw must preserve position and momentum")
	lab.start_play()
	lab.hero.enabled = false
	for i in 70:
		await physics_frame
		target.update_brain(lab.hero, false, 1.0 / 60)
		if target.get_meta("state") == "getup":
			break
	check(target.get_meta("state") == "getup" and target.is_on_floor(), "A thrown enemy must collide with the floor and enter recovery")
	check(target.health == 30, "Landing applies exactly one grapple hit")
	check(target.position.distance_to(launch_position) > 1, "A throw must physically displace its target")
	for i in 48:
		await physics_frame
		target.update_brain(lab.hero, false, 1.0 / 60)
	check(target.health == 30 and target.get_meta("state") != "getup", "Recovery must resume AI without repeating damage")
	target = await prepare_target()
	lab.grapple_style = 1
	check(lab.grapple_attack() and lab.hero.visual.active_clip == "LegSweep", "The second grapple must play the leg sweep")
	for step in 21:
		await physics_frame
		lab._physics_process(1.0 / 60)
	check(target.velocity.y < 2.4 and target.throw_style == 1, "Sweep must use a lower physical launch than the throw")
	# A solid wall must stop the swept target rather than allowing a teleport.
	var wall = lab._box(lab.arena, Vector3(0, 1.5, 3.3), Vector3(4, 3, 0.2), Color.GRAY)
	for i in 50:
		await physics_frame
		target.update_brain(lab.hero, false, 1.0 / 60)
	check(target.position.z > 3.85 and target.health == 30, "Swept enemy must collide with cover and take only landing damage")
	wall.queue_free()
	target = await prepare_target()
	wall = lab._box(lab.arena, Vector3(0, 1.5, 5.3), Vector3(4, 3, 0.12), Color.GRAY)
	await physics_frame
	await physics_frame
	check(not lab.grapple_attack(), "Grapple acquisition must reject targets behind cover")
	wall.queue_free()
	await physics_frame
	lab.hero.camera.look_at(lab.hero.camera.global_position + Vector3.BACK)
	check(not lab.grapple_attack(), "Grapple acquisition must reject targets behind the hero")
	lab.hero.camera.look_at(target.position + Vector3.UP)
	lab.grapple_attack()
	lab.reset_arena()
	await process_frame
	check(lab.grapple_target == null and lab.grapple_windup == 0 and not lab.melee_buffered, "Reset must remove pending grabs and buffered attacks")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Martial arts: %d checks, %d failures" % [checks, failures])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)
