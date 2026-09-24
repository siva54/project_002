extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("384046")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.8
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(3.8, 3.4, 9)
	camera.look_at(Vector3(0, 1, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9
	var clips := ["Guard", "Jab", "Cross", "Roundhouse", "SpinKick", "Backflip"]
	var times := [0.0, 0.25, 0.3, 0.6, 1.2, 0.7]
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		clips = [args[0], args[0], args[0], args[0], args[0], args[0]]
		times = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25]
		if args[0] == "SpinKick":
			times = [0.0, 0.4, 0.8, 1.2, 1.6, 2.0]
	for i in clips.size():
		var visual := preload("res://scripts/kung_fu_visual.gd").new()
		stage.add_child(visual)
		visual.position = Vector3((i % 3 - 1) * 2.5, 0, -2 if i < 3 else 1.5)
		visual.sample(clips[i], times[i])
		if not args.is_empty():
			for side in ["Left", "Right"]:
				var skeleton: Skeleton3D = visual.body_skeleton
				print(times[i], " ", side, " foot: ", skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_" + side + "Foot")).origin)
		var label := Label3D.new()
		label.text = "%s %.2f" % [clips[i], times[i]]
		label.position = visual.position + Vector3(0, 2.2, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/qa/kung-fu-poses.png"))
	quit()
