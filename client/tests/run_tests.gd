extends SceneTree

const Catalog = preload("res://scripts/power_catalog.gd")
const Lab = preload("res://scenes/hero_lab.tscn")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	check(Catalog.validate_loadout(["blink", "cloak", "kinetic"]), "Mixed powers must form a valid loadout")
	check(not Catalog.validate_loadout(["blink", "blink", "bolt"]), "Duplicate powers must be rejected")
	check(not Catalog.validate_loadout(["blink", "cloak"]), "The hero must equip exactly three powers")
	check(not Catalog.validate_loadout(["blink", "cloak", "unknown"]), "Unknown powers must be rejected")
	check(Catalog.can_activate("blink", 25, 0), "Exact energy cost must permit activation")
	check(not Catalog.can_activate("blink", 24, 0), "Insufficient energy must reject activation")
	check(not Catalog.can_activate("blink", 100, 0.1), "Cooldown must prevent repeat activation")
	var lab = Lab.instantiate()
	root.add_child(lab)
	lab.set_physics_process(false)
	for i in range(4):
		await physics_frame
	check(get_nodes_in_group("targets").size() == 5, "Arena starts with five targets")
	check(get_nodes_in_group("props").size() == 4, "Arena starts with four props")
	check(not lab.running and lab.menu.visible, "The prototype starts in hero creation")
	check(lab.loadout.is_empty() and lab.start_button.disabled, "Opening must require the player to choose their three powers")
	check(lab.power_buttons.size() == 6, "All six powers must be available in hero creation")
	lab.start_play()
	check(not lab.running, "An empty build must not enter gameplay")
	lab._toggle_power("blink")
	lab._toggle_power("kinetic")
	lab.start_play()
	check(not lab.running and lab.start_button.disabled, "Two powers must not satisfy the three-power requirement")
	lab._toggle_power("cloak")
	check(not lab.start_button.disabled, "Exactly three powers must enable entry")
	lab._toggle_power("shield")
	check(lab.loadout.size() == 3 and not lab.loadout.has("shield"), "Selecting a fourth power must not alter a full build")
	check(lab.loadout == ["blink", "kinetic", "cloak"], "Power swaps preserve selected slot order")
	lab.start_play()
	lab.hero.enabled = false
	check(lab.running and lab.hud.visible and not lab.menu.visible, "Entering the playground must switch UI and gameplay state")
	lab.energy = 100
	check(lab.activate_slot(2), "Equipped cloak must activate")
	check(is_equal_approx(lab.energy, 70), "Cloak consumes its energy cost")
	check(lab.cloak_time == 5, "Cloak must start with a five-second duration")
	check(not lab.activate_slot(2), "Cloak must respect cooldown")
	var target = get_nodes_in_group("targets")[0]
	lab.hero.camera.look_at(target.position + Vector3.UP * 1.5)
	lab._fire_bolt()
	check(lab.cloak_time == 0, "An offensive power must break cloak")
	check(target.get_meta("health") == 60, "Energy damage must wait for projectile travel")
	for i in range(45):
		await physics_frame
	check(target.get_meta("health") == 30, "A traveling orb must damage its target on impact")
	lab._fire_bolt()
	for i in range(45):
		await physics_frame
	check(lab.score == 1, "Two bolts must disable a sentinel and award one score")
	for i in range(40):
		await physics_frame
	check(get_nodes_in_group("targets").size() == 4, "A disabled sentinel must finish its visible shutdown before leaving the arena")
	var origin := Vector3(19, 0.05, 10)
	var safe: Vector3 = lab.find_blink_destination(origin, Vector3.RIGHT, 8)
	check(safe.x < 21.2 and safe.x >= origin.x, "Blink body sweep must stop before the perimeter wall")
	var clear: Vector3 = lab.find_blink_destination(Vector3(0, 0.05, 10), Vector3(0, 0, -1), 8)
	check(clear.z < 2.2, "Blink must traverse clear space at useful range")
	var downward: Vector3 = lab.find_blink_destination(Vector3(0, 0.05, 10), Vector3(0, -0.2, -1), 8)
	check(downward.z < 2.2, "Looking slightly downward must not make ground-level Blink unusable")
	lab.loadout = ["kinetic", "blink", "cloak"]
	lab.energy = 100
	var prop = get_nodes_in_group("props")[0]
	lab.hero.camera.look_at(prop.position)
	check(lab.activate_slot(0), "Aimed telekinesis must grab a nearby crate")
	check(lab.held_prop == prop and prop.freeze, "A held prop must be identified and frozen")
	var saved_position: Vector3 = lab.hero.position
	lab.hero.position = Vector3(19, 0.05, 10)
	lab.hero.camera.global_position = lab.hero.position + Vector3.UP * 1.6
	lab.hero.camera.look_at(lab.hero.camera.global_position + Vector3.RIGHT * 5)
	lab._physics_process(1.0 / 60.0)
	check(prop.position.x < 21 and prop.position.x > 19, "Holding a crate near a wall must keep its body on the playable side")
	lab.hero.position = saved_position
	var second = get_nodes_in_group("targets")[0]
	prop.global_position = second.position + Vector3(0, 1.5, 4)
	lab.hero.camera.global_position = second.position + Vector3(0, 1.5, 8)
	lab.hero.camera.look_at(second.position + Vector3.UP * 1.5)
	lab.energy = 0
	check(lab.activate_slot(0), "Throwing an already-held crate must work without more energy")
	check(lab.held_prop == null and not prop.freeze and prop.linear_velocity.length() > 20, "Throw must release physics with launch velocity")
	for i in range(30):
		await physics_frame
	check(lab.score == 2, "A thrown crate must physically collide with and disable a sentinel")
	for i in range(40):
		await physics_frame
	check(get_nodes_in_group("targets").size() == 3, "A crate-disabled sentinel must complete its shutdown")
	lab.reset_arena()
	for i in range(3):
		await physics_frame
	check(lab.score == 0 and lab.health == 100 and lab.energy == 100, "Reset restores hero resources and score")
	check(get_nodes_in_group("targets").size() == 5 and get_nodes_in_group("props").size() == 4, "Reset must rebuild without duplicate entities")
	check(get_nodes_in_group("relay").size() == 1 and get_nodes_in_group("pickups").size() == 4, "Reset must rebuild the relay objective and four power cells")
	var energy_cell = get_nodes_in_group("pickups").filter(func(pickup): return pickup.get_meta("kind") == "energy")[0]
	lab.energy = 40
	lab.hero.position = energy_cell.position
	lab._update_pickups(0.1)
	check(lab.energy == 70 and energy_cell.is_queued_for_deletion(), "An Energy Cell must restore energy when the hero reaches it")
	var vital_cell = get_nodes_in_group("pickups").filter(func(pickup): return pickup.get_meta("kind") == "vitality")[0]
	lab.health = 50
	lab.hero.position = vital_cell.position
	lab._update_pickups(0.1)
	check(lab.health == 75 and vital_cell.is_queued_for_deletion(), "A Vital Cell must restore vitality when the hero reaches it")
	lab.energy = 25
	lab._orb_impact(lab.relay, lab.relay.position + Vector3.UP, false, Color.CYAN, Vector3.FORWARD)
	check(lab.relay.get_meta("charge") == 25 and not lab.relay.get_meta("complete"), "An Energy Bolt impact must build visible relay charge")
	lab._energize_relay(75.0, "TEST")
	check(lab.relay_complete and lab.energy == 100 and lab.health == 100, "Completing the relay must restore energy and grant vitality")
	lab.reset_arena()
	for i in range(3):
		await physics_frame
	var reacting_sentinel = get_nodes_in_group("targets")[0]
	var patrol_start: Vector3 = reacting_sentinel.position
	for i in range(15):
		reacting_sentinel.update_brain(lab.hero, false, 1.0 / 60.0)
		await physics_frame
	check(reacting_sentinel.position.distance_to(patrol_start) > 0.1, "Sentinels must walk their patrol routes when unaware")
	reacting_sentinel.hear_noise(reacting_sentinel.position + Vector3(3, 0, 0), 6.0)
	check(reacting_sentinel.get_meta("state") == "investigate", "Nearby powers must put a sentinel into investigation")
	reacting_sentinel.take_damage(30, lab.hero.position)
	check(reacting_sentinel.get_meta("state") == "stagger" and reacting_sentinel.get_meta("health") == 30, "A nonlethal hit must stagger a sentinel and preserve its remaining health")
	var alerted_allies := 0
	for sentinel in get_nodes_in_group("targets"):
		if sentinel != reacting_sentinel and sentinel.get_meta("state") == "investigate":
			alerted_allies += 1
	check(alerted_allies > 0, "A hit sentinel must alert nearby allies to the attacker position")
	reacting_sentinel.update_brain(lab.hero, true, 0.5)
	reacting_sentinel.set_meta("shot_timer", 0.0)
	var projectile_count := get_nodes_in_group("projectiles").size()
	reacting_sentinel.update_brain(lab.hero, true, 0.1)
	check(get_nodes_in_group("projectiles").size() == projectile_count + 1, "An engaged sentinel must fire a traveling energy shot")
	lab._update_sentinels(0.1)
	var seen_count := 0
	for sentinel in get_nodes_in_group("targets"):
		if sentinel.get_meta("search_time") > 0:
			seen_count += 1
	check(seen_count > 0, "Visible hero must be detected by nearby sentinels")
	lab.cloak_time = 5
	lab.health = 100
	lab._update_sentinels(2.1)
	check(lab.health == 100, "Cloaked hero must not take automatically tracking sentinel fire")
	lab.cloak_time = 0
	lab.health = 1
	for sentinel in get_nodes_in_group("targets"):
		sentinel.set_meta("shot_timer", 0.0)
	lab._update_sentinels(0.1)
	for i in range(100):
		await physics_frame
	check(lab.health == 0 and not lab.running and lab.menu.visible, "Defeat must return to hero creation and stop play")
	check(lab.start_button.disabled, "A defeated hero must reset before re-entering")
	lab.reset_arena()
	lab._update_loadout_ui()
	check(not lab.start_button.disabled, "Reset must permit another run with the same loadout")
	lab.start_play()
	var before: Vector3 = lab.hero.position
	Input.action_press("move_forward")
	for i in range(15):
		await physics_frame
	check(lab.hero.visual.active_clip == "Walking", "Ground travel must use the imported walking animation")
	Input.action_release("move_forward")
	check(lab.hero.position.z < before.z - 0.5, "Movement input must move the actual hero body")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	check(lab.hero.velocity.y > 0, "Jump input must lift a grounded hero")
	check(lab.hero.visual.active_clip in ["Jump", "WalkJump"], "Jump must play an imported airborne animation")
	lab.show_menu()
	before = lab.hero.position
	Input.action_press("move_forward")
	for i in range(5):
		await physics_frame
	Input.action_release("move_forward")
	check(lab.hero.position.is_equal_approx(before), "Opening hero creation must suspend player movement")
	# Melee has a windup and only damages nearby targets in front with clear sight.
	lab.reset_arena()
	for i in range(3):
		await physics_frame
	lab.start_play()
	lab.hero.enabled = false
	var melee_target = get_nodes_in_group("targets")[0]
	lab.hero.position = melee_target.position + Vector3(0, 0.05, 1.5)
	lab.hero.camera.global_position = lab.hero.position + Vector3.UP * 1.3
	lab.hero.camera.look_at(melee_target.position + Vector3.UP * 1.3)
	check(lab.melee_attack(), "Melee input must begin an attack")
	check(lab.hero.visual.active_clip == "Punch", "Melee must use the imported Punch clip")
	check(melee_target.get_meta("health") == 60, "Melee damage must wait for the strike windup")
	check(not lab.melee_attack(), "Melee cooldown must prevent duplicate strikes")
	lab._physics_process(0.19)
	check(melee_target.get_meta("health") == 30, "A nearby target in the punch arc must take damage")
	lab.melee_cooldown = 0
	lab.hero.camera.look_at(lab.hero.camera.global_position + Vector3.BACK)
	lab.melee_attack()
	lab._physics_process(0.19)
	check(melee_target.get_meta("health") == 30, "Punching away from a target must not damage it")
	lab.hero.camera.look_at(melee_target.position + Vector3.UP)
	var wall = lab._box(lab.arena, melee_target.position + Vector3(0, 1.5, 0.8), Vector3(3, 3, 0.1), Color.GRAY)
	for i in range(3):
		await physics_frame
	lab.melee_cooldown = 0
	lab.melee_attack()
	lab._physics_process(0.19)
	check(melee_target.get_meta("health") == 30, "Melee must not reach a target through cover")
	lab._launch_orb(melee_target.position + Vector3(0, 1.1, 3), melee_target.position + Vector3.UP, Color.CYAN, false, lab.hero)
	for i in range(30):
		await physics_frame
	check(melee_target.get_meta("health") == 30, "Traveling energy must stop at thin cover before reaching a target")
	wall.queue_free()
	# Pause must freeze in-flight projectiles as well as hero movement.
	var orb = lab._launch_orb(Vector3(0, 3, 10), Vector3(0, 3, -10), Color.CYAN, false, lab.hero)
	lab.show_menu()
	var orb_position: Vector3 = orb.position
	for i in range(5):
		await physics_frame
	check(orb.position.is_equal_approx(orb_position), "Pause must freeze projectile travel")
	lab.reset_arena()
	await process_frame
	check(get_nodes_in_group("projectiles").is_empty(), "Reset must remove all in-flight attacks")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Hero Lab: %d checks, %d failures" % [checks, failures])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)
