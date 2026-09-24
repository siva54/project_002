extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("253037")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.75
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -20, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 7, 17)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13
	var source: AnimationLibrary = load("res://../artifacts/qa/boxing-study.res")
	var visual_class := preload("res://scripts/kung_fu_visual.gd")
	visual_class.COMBAT_LIBRARY.add_animation("BoxingStudy", source.get_animation("BoxingStudy"))
	var base := 0.0
	if not OS.get_cmdline_user_args().is_empty():
		base = float(OS.get_cmdline_user_args()[0])
	for i in 24:
		var visual := visual_class.new()
		stage.add_child(visual)
		visual.position = Vector3((i % 6 - 2.5) * 2.0, 0, (i / 6 - 1.5) * 2.6)
		visual.rotation.y = -0.65
		var at := base + i * 0.20
		visual._sample_pose("BoxingStudy", at)
		visual._close_hands()
		var label := Label3D.new()
		label.text = "%.2f / %d" % [at, roundi(at * 120)]
		label.position = visual.position + Vector3.UP * 1.9
		label.font_size = 28
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/source-study-%d.png" % roundi(base)))
	var probe := visual_class.new()
	stage.add_child(probe)
	var samples := []
	for frame in 2401:
		probe._sample_pose("BoxingStudy", frame / 120.0)
		var sample := {}
		for name in ["LeftHand", "RightHand", "LeftForeArm", "RightForeArm", "Hips", "Head", "LeftFoot", "RightFoot"]:
			var point: Vector3 = probe.to_local(probe.bone_world(name))
			sample[name] = [point.x, point.y, point.z]
		samples.append(sample)
	FileAccess.open("res://../artifacts/qa/boxing-points.json", FileAccess.WRITE).store_string(JSON.stringify(samples))
	quit()
