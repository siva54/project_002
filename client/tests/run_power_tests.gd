extends SceneTree

const Catalog = preload("res://scripts/power_catalog.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _run() -> void:
	var combinations := 0
	for a in range(6):
		for b in range(a + 1, 6):
			for c in range(b + 1, 6):
				check(Catalog.validate_loadout([Catalog.POWER_IDS[a], Catalog.POWER_IDS[b], Catalog.POWER_IDS[c]]), "Every three-power combination must be selectable")
				combinations += 1
	check(combinations == 20, "Six powers must offer twenty distinct three-power builds")
	var lab = load("res://scenes/hero_lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_physics_process(false)
	await frames(3)
	for id in ["shield", "shockwave", "blink"]:
		lab.power_buttons[id].pressed.emit()
	check(lab.loadout == ["shield", "shockwave", "blink"], "The new power cards must wire into the three-slot build in selection order")
	check(lab.build_slots[0].text.contains("Energy Shield") and lab.build_slots[1].text.contains("Shockwave"), "Build preview must show the selected names")
	lab.start_play()
	lab.hero.enabled = false
	lab.hero.position = Vector3(0, 0.05, 2)
	await frames(3)
	check(lab.activate_slot(0), "Equipped Shield must activate")
	check(lab.shield_time == 5 and is_instance_valid(lab.shield_aura), "Shield must create a five-second protective volume")
	check(lab.energy == 70 and lab.cooldowns["shield"] == 8, "Shield must charge energy and enter cooldown")
	check(not lab.activate_slot(0), "Shield cooldown must reject repeat activation")
	# Exercise actual enemy-projectile travel into the player's collider.
	var target = get_nodes_in_group("targets")[0]
	lab._launch_orb(lab.hero.position + Vector3(0, 1, -3), lab.hero.position + Vector3.UP, Color.RED, true, target)
	await frames(25)
	check(lab.health == 100 and get_nodes_in_group("projectiles").is_empty(), "Shield must consume an incoming projectile without losing health")
	lab.show_menu()
	lab._physics_process(2.0)
	check(lab.shield_time == 5, "Shield duration must not elapse while paused")
	lab.start_play()
	lab.hero.enabled = false
	lab.energy = 100
	var far_target = get_nodes_in_group("targets")[1]
	var prop = get_nodes_in_group("props")[0]
	lab.cloak_time = 5
	check(lab.activate_slot(1), "Equipped Shockwave must activate")
	check(lab.energy == 65 and lab.cooldowns["shockwave"] == 3, "Shockwave must charge energy and enter cooldown")
	check(lab.cloak_time == 0, "Offensive Shockwave must break cloak")
	check(target.get_meta("health") == 30, "Shockwave must damage an exposed target within six metres")
	check(far_target.get_meta("health") == 60, "Shockwave must not damage distant targets")
	await frames(2)
	check(prop.linear_velocity.length() > 1, "Shockwave must physically propel nearby crates")
	check(lab.shield_time > 0, "Using an offensive power must preserve active Shield protection")
	lab._physics_process(5.1)
	check(lab.shield_time == 0 and not is_instance_valid(lab.shield_aura), "Shield must expire and remove its visual volume")
	lab._orb_impact(lab.hero, lab.hero.position + Vector3.UP, true, Color.RED, Vector3.FORWARD)
	check(lab.health == 94, "Incoming energy must damage the hero after Shield expires")
	lab.show_menu()
	lab.cooldowns.clear()
	lab.energy = 100
	lab.start_play()
	lab.hero.enabled = false
	lab.activate_slot(0)
	lab.show_menu()
	lab.power_buttons["shield"].pressed.emit()
	check(lab.shield_time == 0 and lab.start_button.disabled, "Unequipping Shield must end protection and require a replacement third power")
	lab.power_buttons["cloak"].pressed.emit()
	check(lab.loadout == ["shockwave", "blink", "cloak"], "Removing a power must compact key order and append the replacement")
	lab.reset_arena()
	await frames(3)
	lab.start_play()
	lab.hero.enabled = false
	lab.hero.position = Vector3(0, 0.05, 2)
	target = get_nodes_in_group("targets")[0]
	var wall = lab._box(lab.arena, Vector3(0, 1.5, 0), Vector3(4, 3, 0.2), Color.GRAY)
	await frames(3)
	lab.activate_slot(0)
	check(target.get_meta("health") == 60, "Solid cover must block Shockwave damage")
	wall.queue_free()
	lab.show_menu()
	lab.power_buttons["cloak"].pressed.emit()
	lab.power_buttons["shield"].pressed.emit()
	lab.start_play()
	lab.hero.enabled = false
	lab.energy = 100
	lab.activate_slot(2)
	lab.reset_arena()
	check(lab.shield_time == 0 and not is_instance_valid(lab.shield_aura), "Reset must clear Shield protection and its effect")
	check(lab.loadout == ["shockwave", "blink", "shield"], "Arena reset must preserve the chosen three-power build")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Power selection and abilities: %d checks, %d failures" % [checks, failures])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)
