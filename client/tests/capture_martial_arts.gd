extends SceneTree

var lab: Node3D
var directory := "res://../docs/qa/"

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func save_frame(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(directory + name + ".png"))

func _run() -> void:
	lab = load("res://scenes/hero_lab.tscn").instantiate()
	root.add_child(lab)
	await frames(10)
	lab.loadout = ["bolt", "blink", "shield"]
	lab.start_play()
	lab.set_physics_process(false)
	lab.hero.enabled = false
	lab.hero.position = Vector3(0, 0.05, 6)
	lab.hero.visual.rotation.y = 0
	var camera := Camera3D.new()
	lab.add_child(camera)
	camera.position = Vector3(2.5, 1.9, 8.5)
	camera.look_at(Vector3(0, 1.05, 6.3))
	camera.current = true
	for i in 3:
		lab.hero.visual.strike(i)
		lab.hero.visual.body_animation.seek(lab.MartialArts.STRIKES[i].contact, true)
		lab.hero.visual.body_animation.pause()
		await frames(2)
		await save_frame("martial-" + lab.MartialArts.STRIKES[i].clip.to_lower())
	# Render actual grapple release and flight using the gameplay state machine.
	var target = get_nodes_in_group("targets")[0]
	camera.position = Vector3(5, 3.2, 11)
	camera.look_at(Vector3(0, 1.2, 7.2))
	for style in 2:
		target.position = Vector3(0, 0.05, 7.3)
		for step in 15:
			await physics_frame
			target.velocity = Vector3.DOWN * 2
			lab.hero.velocity = Vector3.DOWN * 2
			target.move_and_slide()
			lab.hero.move_and_slide()
		target.cancel_grapple()
		lab.hero.camera.global_position = lab.hero.position + Vector3.UP * 1.3
		lab.hero.camera.look_at(target.position + Vector3.UP)
		lab.grapple_cooldown = 0
		lab.grapple_style = style
		assert(lab.grapple_attack(), "Capture requires a real grapple")
		lab.hero.visual.body_animation.seek(0.18, true)
		lab.hero.visual.body_animation.pause()
		await save_frame("martial-clinch" if style == 0 else "martial-sweep-clinch")
		lab._release_grapple()
		lab.hero.visual.body_animation.seek(0.34, true)
		for step in 12:
			await physics_frame
			target.update_brain(lab.hero, false, 1.0 / 60.0)
		await save_frame("martial-throw" if style == 0 else "martial-sweep")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Captured martial arts strikes and grapples.")
	quit()
