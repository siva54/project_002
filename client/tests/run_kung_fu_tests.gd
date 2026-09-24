extends SceneTree

const Dojo := preload("res://scenes/kung_fu_dojo.tscn")
const Fighter := preload("res://scripts/kung_fu_fighter.gd")
const Catalog := preload("res://scripts/combat_moves.gd")
var dojo: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func steps(count: int) -> void:
	for i in count:
		await physics_frame
		dojo._physics_process(1.0 / 60.0)

func fixture(distance: float = 1.12) -> CharacterBody3D:
	Input.action_release("guard")
	Input.action_release("move_right")
	dojo.reset_match()
	dojo.resume_match()
	dojo.training_dummy = true
	for extra in dojo.rivals.slice(1):
		dojo.rivals.erase(extra)
		extra.queue_free()
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	var enemy: CharacterBody3D = dojo.rivals[0]
	enemy.position = dojo.hero.position + Vector3.FORWARD * distance
	dojo.hero.face(Vector3.FORWARD)
	enemy.face(Vector3.BACK)
	await steps(4)
	return enemy

func _run() -> void:
	dojo = Dojo.instantiate()
	root.add_child(dojo)
	dojo.set_physics_process(false)
	check(paused and dojo.pause_panel.visible, "Normal launch must open the combat entry screen")
	check(dojo.rivals.size() == 2, "First bout must support switching between multiple melee opponents")
	check(dojo.find_children("*", "PhysicalBone3D", true, false).is_empty(), "The active game must have no physical ragdoll bodies")
	var enemy := await fixture()
	# Every move must be reachable through the actual input graph and connect once.
	for name in Catalog.MOVES:
		enemy = await fixture()
		var kind := "light"
		var previous := ""
		if name == "LungePunch":
			dojo.hero.drive = Vector3.FORWARD
		elif name != "Jab":
			for key in Catalog.PUNCH_NEXT:
				if Catalog.PUNCH_NEXT[key] == name:
					previous = key
					break
			if previous.is_empty():
				kind = "kick"
				for key in Catalog.KICK_NEXT:
					if Catalog.KICK_NEXT[key] == name:
						previous = key
			dojo.hero.action_name = previous
			dojo.hero.combo_age = 1
		check(dojo.hero.request_attack(kind, enemy) and dojo.hero.action_name == name, name + " must be reachable through punch/kick input")
		await steps(ceili(Catalog.MOVES[name].duration * 60) + 12)
		check(is_equal_approx(enemy.health, 100.0 - Catalog.MOVES[name].damage), name + " must connect exactly once at the animated limb; health=" + str(enemy.health))
		check(dojo.hero.successful_contacts == 1, name + " must not repeat damage through its contact window")
	for name in ["Backfist", "LungePunch"]:
		enemy = await fixture(1.35)
		enemy.position += Vector3.RIGHT * 0.26
		dojo.hero.target = enemy
		if name == "Backfist":
			dojo.hero.action_name = "Uppercut"
			dojo.hero.combo_age = 1
		else:
			dojo.hero.drive = Vector3.FORWARD
		check(dojo.hero.request_attack("light", enemy), name + " must start from an angled target")
		await steps(ceili(dojo.hero.move.duration * 60) + 8)
		check(enemy.health == 100.0 - Catalog.MOVES[name].damage, name + " must align the actual karate limb with an angled opponent")
	# Grounding is measured in world space after approach, including the actual
	# collision controller. Passing damage checks alone cannot catch foot skating.
	for name in ["Jab", "FrontKick", "Roundhouse", "SideKick"]:
		enemy = await fixture(4.0)
		var kind := "light" if name == "Jab" else "kick"
		if name == "Roundhouse" or name == "SideKick":
			dojo.hero.action_name = "LeadHook" if name == "Roundhouse" else "FrontKick"
			dojo.hero.combo_age = 1
		dojo.hero.target = null
		dojo.hero.request_attack(kind)
		var support := "RightFoot" if name in ["Jab", "FrontKick"] else "LeftFoot"
		await steps(ceili((dojo.hero.move.contact - 0.04) * 60))
		var anchor: Vector3 = dojo.hero.visual.bone_world(support)
		var drift := 0.0
		for frame in 7:
			await steps(1)
			var offset: Vector3 = dojo.hero.visual.bone_world(support) - anchor
			offset.y = 0
			drift = maxf(drift, offset.length())
		check(drift < 0.025, name + " supporting foot must stay within 2.5 cm through impact; drift=" + str(drift))
	enemy = await fixture(1.35)
	dojo.hero.request_attack("light", enemy)
	var prep: float = dojo.hero.move.get("windup", 0.0)
	check(prep > 0.14, "A target outside the jab's captured reach must trigger visible range footwork")
	await steps(ceili(prep * 60) + 7)
	var planted: Vector3 = dojo.hero.visual.bone_world("RightFoot")
	await steps(ceili((dojo.hero.move.contact - prep) * 60) - 7)
	var planted_drift: Vector3 = dojo.hero.visual.bone_world("RightFoot") - planted
	planted_drift.y = 0
	check(planted_drift.length() < 0.06, "After the guarded approach, the jab's supporting foot must stay planted through impact: " + str(planted_drift.length()))
	check(enemy.health == 91, "The range step must still deliver the jab at animated contact")
	enemy = await fixture()
	var probe: Node3D = dojo.hero.visual
	probe._sample_pose("MocapJab", 39.0 / 120.0)
	var outgoing_points := []
	for bone in ["LeftHand", "RightHand", "Head", "LeftFoot", "RightFoot"]:
		outgoing_points.append(probe.bone_world(bone))
	probe._sample_pose("MocapCross", 0)
	var joint_jump := 0.0
	var point_index := 0
	for bone in ["LeftHand", "RightHand", "Head", "LeftFoot", "RightFoot"]:
		joint_jump = maxf(joint_jump, probe.bone_world(bone).distance_to(outgoing_points[point_index]))
		point_index += 1
	check(joint_jump < 0.015, "The one-two cut must preserve hands, head and stance within 1.5 cm: " + str(joint_jump))
	# Early input queues a link before the outgoing clip has to finish.
	enemy = await fixture()
	dojo.attack("light")
	await steps(3)
	dojo.attack("light")
	await steps(ceili(dojo.hero.move.link * 60))
	check(dojo.hero.action_name == "Cross", "Early buffered input must link to Cross during recovery, without idle")
	await steps(5)
	dojo.attack("kick")
	await steps(ceili(dojo.hero.move.link * 60))
	check(dojo.hero.action_name == "Knee", "Punch-punch-kick must branch to a knee")
	check(dojo.hero.visual.active_clip != "FightIdle", "A linked combination must preserve its animated transition")
	# Render-pose regression: transition continuity and immediate body compression.
	enemy = await fixture()
	dojo.attack("light")
	var previous_head: Vector3 = dojo.hero.visual.bone_world("Head")
	var previous_hand: Vector3 = dojo.hero.visual.bone_world("RightHand")
	var head_jump := 0.0
	var hand_jump := 0.0
	for frame in 90:
		if frame in [3, 35]:
			dojo.attack("light")
		await steps(1)
		var head: Vector3 = dojo.hero.visual.bone_world("Head")
		var hand: Vector3 = dojo.hero.visual.bone_world("RightHand")
		head_jump = maxf(head_jump, head.distance_to(previous_head))
		hand_jump = maxf(hand_jump, hand.distance_to(previous_hand))
		previous_head = head
		previous_hand = hand
	check(head_jump < 0.18 and hand_jump < 0.35, "Linked strikes must not pop the torso or wrist between frames: " + str([head_jump, hand_jump]))
	check(enemy.health == 65, "The continuous three-punch sequence must connect all three contacts")
	enemy = await fixture()
	enemy.visual.play_clip("Guard", 1, 0)
	enemy.visual.tick(0)
	var neutral_torso: Vector3 = enemy.visual.bone_world("Neck") - enemy.visual.bone_world("Hips")
	enemy.take_hit(12, dojo.hero, 0.65, false, "body")
	await steps(4)
	var early_recoil: float = (enemy.visual.bone_world("Neck") - enemy.visual.bone_world("Hips")).distance_to(neutral_torso)
	await steps(15)
	var late_recoil: float = (enemy.visual.bone_world("Neck") - enemy.visual.bone_world("Hips")).distance_to(neutral_torso)
	check(early_recoil > late_recoil * 1.5, "Hit compression must happen at contact rather than build up late: " + str([early_recoil, late_recoil]))
	enemy = await fixture()
	dojo.attack("light")
	await steps(ceili(dojo.hero.move.contact * 60) + 2)
	var contact_goal: Vector3 = dojo.hero.visual.strike_goal
	enemy.position += Vector3.RIGHT * 0.25
	await steps(4)
	check(dojo.hero.visual.strike_goal == contact_goal, "A hand must follow through its original contact point instead of chasing the recoiling victim")
	enemy = await fixture()
	dojo.attack("light")
	Input.action_press("move_right")
	await steps(ceili((dojo.hero.move.get("windup", 0.0) + 0.12) * 60))
	Input.action_release("move_right")
	var rig: Skeleton3D = dojo.hero.visual.body_skeleton
	var source: Animation = dojo.hero.visual.COMBAT_LIBRARY.get_animation(dojo.hero.move.clip)
	for name in ["Hips", "LeftUpLeg", "RightUpLeg"]:
		var bone := rig.find_bone("mixamorig_" + name)
		var captured := source.rotation_track_interpolate(bone, (dojo.hero.visual.motion_time - dojo.hero.move.get("windup", 0.0)) * dojo.hero.move.rate)
		var error := rig.get_bone_pose_rotation(bone).normalized().angle_to(captured.normalized())
		check(error < 0.002, "Moving punches must preserve captured " + name + " motion rather than replacing it with a run cycle: " + str(error))
	enemy = await fixture()
	dojo.hero.target = null
	dojo.hero.request_attack("light")
	var root_start: Vector3 = dojo.hero.position
	await steps(28)
	check(dojo.hero.position.distance_to(root_start) > 0.05, "Captured footwork must move the collision body even without approach assistance")
	# Movement remains effective inside the strike, with directional target selection.
	enemy = await fixture()
	dojo.attack("light")
	var start: Vector3 = dojo.hero.position
	Input.action_press("move_right")
	await steps(ceili(dojo.hero.move.contact * 60) + 2)
	Input.action_release("move_right")
	check(Vector2(dojo.hero.position.x - start.x, dojo.hero.position.z - start.z).length() > 0.2, "WASD must move the actor during a punch")
	check(enemy.health == 91, "A moving jab must still connect with the tracked opponent")
	var other := Fighter.new()
	dojo.actors.add_child(other)
	other.position = dojo.hero.position + Vector3.RIGHT * 1.4
	dojo.rivals.append(other)
	check(dojo._select_rival(Vector3.RIGHT) == other, "Movement direction must select the opponent for the next strike")
	enemy = await fixture()
	other = Fighter.new()
	dojo.actors.add_child(other)
	other.position = dojo.hero.position + Vector3.RIGHT
	other.face(dojo.hero.position - other.position)
	dojo.rivals.append(other)
	dojo.hero.request_attack("light", enemy)
	await steps(3)
	dojo.hero.request_attack("light", other)
	await steps(75)
	check(enemy.health == 91 and other.health == 88, "A queued direction change must connect the first punch to one rival and the follow-up to the second")
	enemy = await fixture()
	dojo.hero.stamina = 0
	check(not dojo.attack("kick") and not dojo.hero.request_evade(Vector3.RIGHT), "Exhaustion must reject new costly actions")
	# Real incoming strike, timed input, counter, held guard, and rear vulnerability.
	for incoming in ["light", "kick"]:
		enemy = await fixture()
		var contact_gaps: Array[float] = []
		var landing_heights: Array[float] = []
		dojo.hero.counter_landed.connect(func(_actor, victim): landing_heights.append(victim.visual.bone_world("Hips").y))
		dojo.hero.counter_impact.connect(func(actor, victim, stage):
			var bone: String = (["LeftLeg", "RightHand", "RightFoot"] if incoming == "kick" else ["RightHand", "RightForeArm", "RightFoot"])[stage - 1]
			var limb: Vector3 = actor.visual.bone_world(bone)
			var low: Vector3 = victim.visual.bone_world("Hips")
			var high: Vector3 = victim.visual.bone_world("Head")
			if incoming == "light" and stage == 3:
				low = victim.visual.bone_world("LeftFoot")
				high = victim.visual.bone_world("LeftLeg")
			contact_gaps.append(limb.distance_to(Geometry3D.get_closest_point_to_segment(limb, low, high)))
		)
		enemy.request_attack(incoming, dojo.hero)
		await steps(maxi(1, floori((enemy.move.contact - 0.1) * 60)))
		Input.action_press("guard")
		for attempt in 15:
			await steps(1)
			if dojo.hero.state == Fighter.State.COUNTER:
				break
		Input.action_release("guard")
		check(dojo.hero.state == Fighter.State.COUNTER and enemy.state == Fighter.State.CLINCH, "Timed guard must bind both actors into a counter finisher")
		check(dojo.hero.pair_kind == ("kick_counter" if incoming == "kick" else "hand_counter"), "Incoming punches and kicks must select distinct counter choreography")
		check(enemy.health == 100 and dojo.hero.health == 100, "Interception must prevent damage without applying the finisher early")
		await steps(23)
		check(enemy.health == 85 and dojo.hero.counter_stage == 1, "First counter contact must apply its body strike exactly once")
		dojo.pause_match()
		var counter_head: Vector3 = enemy.visual.bone_world("Head")
		await steps(10)
		check(enemy.visual.bone_world("Head").distance_to(counter_head) < 0.001 and enemy.health == 85, "Pause must freeze counter animation and damage together")
		dojo.resume_match()
		await steps(20)
		check(enemy.health == 65 and dojo.hero.counter_stage == 2, "Second counter strike must connect before the final blow")
		await steps(29)
		check(enemy.health == 0 and dojo.hero.counter_stage == 3 and enemy.state == Fighter.State.CLINCH, "Third counter contact must finish a full-health opponent while retaining landing ownership")
		check(dojo.hero.successful_contacts == 3, "Counter contact stages must each happen once")
		check(contact_gaps.size() == 3 and contact_gaps.all(func(gap): return gap < 0.42), "Counter damage must coincide with close limb contact, gaps=" + str(contact_gaps))
		await steps(56)
		check(dojo.hero.state == Fighter.State.READY and enemy.state == Fighter.State.KO, "Finisher must return control after the paired landing")
		check(enemy.held_by == null and dojo.hero.grabbed == null and enemy.get_collision_exceptions().is_empty(), "Counter completion must clear ownership and collision exceptions")
		check(dojo.hero.health == 100, "The intercepted strike must not resume and damage the player")
		check(landing_heights.size() == 1 and landing_heights[0] < 0.18, "Landing feedback must happen once, when the body reaches the floor: " + str(landing_heights))
	enemy = await fixture()
	dojo.hero.set_guard(true)
	dojo.hero.take_hit(9, enemy)
	await steps(32)
	dojo.hero.stagger(0.4, Vector3.ZERO)
	check(enemy.health == 85 and enemy.state == Fighter.State.READY and enemy.held_by == null, "Interrupting a counter before the final contact must release a living partner")
	check(enemy.get_collision_exceptions().is_empty(), "Interrupted counter must restore physical separation")
	await steps(90)
	check(enemy.health == 85, "An interrupted finisher must not deliver delayed damage")
	enemy = await fixture()
	dojo.hero.set_guard(true)
	dojo.hero.take_hit(9, enemy)
	await steps(73)
	other = Fighter.new()
	dojo.actors.add_child(other)
	other.position = dojo.hero.position + Vector3.RIGHT * 1.05
	other.face(dojo.hero.position - other.position)
	dojo.rivals.append(other)
	check(dojo.hero.request_attack("light", other), "Final counter recovery must accept the next attack input")
	await steps(90)
	check(other.health == 91, "A buffered attack after a counter must turn and connect with the next opponent")
	check(enemy.health == 0 and enemy.held_by == null, "Chaining away from a counter must leave the finished opponent released")
	enemy = await fixture()
	dojo.hero.set_guard(true)
	dojo.hero.block_age = 0.3
	check(dojo.hero.take_hit(20, enemy) == "block" and dojo.hero.health == 100, "Held guard must protect the front")
	dojo.hero.face(Vector3.BACK)
	check(dojo.hero.take_hit(20, enemy) == "hit" and dojo.hero.health == 80, "Guard must leave the rear vulnerable")
	enemy = await fixture()
	check(dojo.hero.request_evade(Vector3.RIGHT), "Grounded sidestep must be available from neutral")
	check(dojo.hero.take_hit(10, enemy) == "miss", "The active sidestep window must evade a strike")
	start = dojo.hero.position
	await steps(30)
	check(dojo.hero.position.x > start.x + 0.55 and dojo.hero.position.y < 0.1, "Captured sidestep must clear a strike along the floor without a flip or launch")
	check(dojo.hero.state == Fighter.State.READY, "Sidestep must return control quickly")
	enemy = await fixture()
	check(dojo.hero.request_evade(Vector3.LEFT), "The left karate slip must be available")
	start = dojo.hero.position
	await steps(30)
	check(dojo.hero.position.x < start.x - 0.40 and dojo.hero.position.y < 0.1, "The left slip must step away on its captured footwork")
	# Cover and missed limb contacts must remain misses despite approach assistance.
	enemy = await fixture()
	var wall: Node3D = dojo._box(Vector3(0, 1, -0.1), Vector3(3, 2, 0.12), Color.GRAY)
	await steps(2)
	check(not dojo.grapple(), "A wall must block a grapple")
	dojo.attack("light")
	await steps(30)
	check(enemy.health == 100 and dojo.hero.position.z > 0.2, "Attacks cannot deal damage or pull the actor through cover")
	wall.queue_free()
	# Both grappling branches hold two animated actors until a controlled landing.
	for kind in ["light", "kick"]:
		enemy = await fixture(0.85)
		check(dojo.grapple(), "A close opponent must enter a clinch")
		await steps(12)
		check(enemy.state == Fighter.State.CLINCH and enemy.health == 100, "Clinch must hold without premature damage")
		check(dojo.hero.request_attack(kind), "Punch/kick must select a distinct clinch follow-up")
		await steps(41)
		var expected := 70.0 if kind == "light" else 76.0
		check(enemy.health == expected and enemy.state == Fighter.State.CLINCH, "Grapple contact must occur once while both actors remain in the paired animation")
		dojo.pause_match()
		var pose: Vector3 = enemy.visual.bone_world("Head")
		await steps(12)
		check(enemy.visual.bone_world("Head").distance_to(pose) < 0.001, "Pause must freeze both sides of a paired takedown")
		dojo.resume_match()
		await steps(45)
		check(enemy.state == Fighter.State.DOWN and enemy.health == expected, "Takedown must finish in an animated down state without repeat damage")
		check(enemy.held_by == null and dojo.hero.grabbed == null, "Pair completion must release both references")
		await steps(120)
		check(enemy.state == Fighter.State.READY and enemy.collision_layer == 4, "A surviving opponent must recover through animation and regain normal collision")
		dojo.hero.position = enemy.position + Vector3.BACK * 0.8
		check(dojo.grapple(), "A recovered opponent can be grabbed again")
		dojo.hero.stagger(0.4, Vector3.ZERO)
		check(enemy.state == Fighter.State.READY and enemy.get_collision_exceptions().is_empty(), "An interrupted clinch must release its partner and collision exceptions")
	enemy = await fixture(0.85)
	dojo.grapple()
	await steps(110)
	check(enemy.state == Fighter.State.READY and dojo.hero.grabbed == null, "An unused clinch must time out rather than trap either fighter")
	enemy = await fixture(0.85)
	dojo.grapple()
	enemy.health = 0
	dojo.hero.stagger(0.4, Vector3.ZERO)
	check(enemy.state == Fighter.State.KO and enemy.held_by == null, "Interrupting a lethal paired move must still animate the victim's defeat")
	enemy = await fixture()
	dojo.hero.stamina = 1
	dojo.hero.set_guard(true)
	check(dojo.hero.take_hit(1, enemy) == "parry", "A guard with enough stamina for the interception must begin the counter")
	await steps(130)
	check(enemy.state == Fighter.State.KO, "A successful counter must finish without a second stamina payment")
	# Authored defeat and recovery replace every previous ragdoll path.
	enemy = await fixture()
	enemy.health = 1
	enemy.take_hit(10, dojo.hero)
	await steps(65)
	check(enemy.state == Fighter.State.KO and enemy.visual.active_clip == "Down", "Defeat must use the controlled fall animation")
	check(enemy.position.y < 0.1 and enemy.velocity.length() < 1.1, "Defeat must never launch a floppy body")
	await steps(70)
	check(dojo.round_number == 2 and dojo.rivals.size() == 3, "Completing a bout must advance to the next group")
	enemy = await fixture()
	dojo.training_dummy = false
	await steps(180)
	check(dojo.hero.health < 100, "Live opponents must approach and connect melee attacks")
	check(get_nodes_in_group("projectiles").is_empty(), "The active game must remain martial arts only")
	dojo.reset_match()
	check(dojo.hero.health == 100 and dojo.rivals.size() == 2 and dojo.hero.buffered.is_empty(), "Restart must replace all combat state and queued input")
	check(dojo.find_children("*", "PhysicalBone3D", true, false).is_empty(), "No move, defeat or reset may create a ragdoll")
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Connected combat: %d checks, %d failures" % [checks, failures])
	dojo.stop_audio()
	# Let the audio mixing thread release stopped playback before immediate test exit.
	OS.delay_msec(60)
	dojo.queue_free()
	await process_frame
	quit(1 if failures else 0)
