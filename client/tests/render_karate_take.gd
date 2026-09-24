extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var take: String = args[0]
	var center := float(args[1])
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("253037")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.8
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	scene.add_child(light)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 5.0, 15)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10
	camera.current = true
	var source: AnimationLibrary = load("res://../artifacts/qa/" + take + "-study.res")
	var visual_class := preload("res://scripts/kung_fu_visual.gd")
	visual_class.COMBAT_LIBRARY.add_animation("Study", source.get_animation(source.get_animation_list()[0]))
	if args.size() > 2 and args[2] == "close":
		camera.position = Vector3(0.9, 1.85, 4.0)
		camera.look_at(Vector3(0, 0.9, 0))
		camera.size = 2.35
		var visual := visual_class.new()
		scene.add_child(visual)
		for i in 12:
			visual._sample_pose("Study", center + (i - 5) * 0.10)
			visual._close_hands()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/" + take + "-" + str(roundi(center * 100)) + "-%02d.png" % i))
		quit()
		return
	for i in 12:
		var visual := visual_class.new()
		scene.add_child(visual)
		visual.position = Vector3((i % 3 - 1) * 2.7, 0, (i / 3 - 1.5) * 2.55)
		var at := center + (i - 5) * 0.10
		visual._sample_pose("Study", at)
		visual._close_hands()
		var label := Label3D.new()
		label.text = "%s   %.2f" % [take, at]
		label.position = visual.position + Vector3.UP * 1.75
		label.font_size = 32
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		scene.add_child(label)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/" + take + "-" + str(roundi(center * 100)) + ".png"))
	quit()
