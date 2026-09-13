extends SceneTree

var lab: Node3D
var directory := ""

func _initialize() -> void:
	call_deferred("_capture")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func save_frame(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + filename + ".png")

func _capture() -> void:
	directory = ProjectSettings.globalize_path("res://../docs/qa/")
	lab = load("res://scenes/hero_lab.tscn").instantiate()
	root.add_child(lab)
	await frames(20)
	lab.loadout = ["bolt", "blink", "kinetic"]
	lab.start_play()
	Input.action_press("move_forward")
	await frames(16)
	await save_frame("walking")
	Input.action_press("sprint")
	await frames(14)
	await save_frame("running")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	lab.reset_arena()
	await frames(5)
	# Keep the normal aiming camera for gameplay; use a separate observer for QA.
	var observer := Camera3D.new()
	lab.add_child(observer)
	observer.position = Vector3(6, 3.5, 13)
	observer.look_at(Vector3(0, 1.2, 5))
	observer.current = true
	var target = get_nodes_in_group("targets")[0]
	lab.hero.camera.look_at(target.position + Vector3.UP * 1.4)
	lab._fire_bolt()
	await frames(10)
	await save_frame("energy-cast")
	await frames(22)
	await save_frame("energy-impact")
	lab.hero.camera.look_at(Vector3(-3, 0.8, 3))
	lab._grab_prop()
	await frames(10)
	await save_frame("telekinesis")
	lab._drop_prop()
	lab.loadout = ["cloak", "bolt", "blink"]
	lab.activate_slot(0)
	await frames(8)
	await save_frame("cloak")
	lab._reveal()
	lab.hero.position = Vector3(0, 0.05, -1.3)
	lab.hero.camera.look_at(target.position + Vector3.UP)
	observer.position = Vector3(4, 2.7, 3)
	observer.look_at(Vector3(0, 1, -2))
	lab.melee_attack()
	await frames(14)
	await save_frame("melee-impact")
	lab.reset_arena()
	lab.hero.camera.transform = Transform3D.IDENTITY
	lab.hero._update_camera()
	observer.position = Vector3(6, 3.5, 13)
	observer.look_at(Vector3(0, 1.2, 5))
	await frames(3)
	lab._blink()
	await frames(8)
	await save_frame("blink")
	lab.reset_arena()
	lab.loadout = ["shield", "shockwave", "blink"]
	lab.hero.position = Vector3(0, 0.05, 2)
	observer.position = Vector3(6, 4, 8)
	observer.look_at(Vector3(0, 1, -1))
	await frames(4)
	lab.activate_slot(0)
	await frames(8)
	await save_frame("energy-shield")
	lab.activate_slot(1)
	await frames(14)
	await save_frame("shockwave")
	lab.reset_arena()
	observer.position = Vector3(7, 4.5, -2)
	observer.look_at(Vector3(0, 1.5, -10.5))
	lab._energize_relay(70.0, "ENERGY BOLT")
	await frames(8)
	await save_frame("power-relay")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Captured movement, attacks, six power effects, and the relay objective.")
	quit()
