extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("253037")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -20, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 9.5, 14)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11
	var catalog := preload("res://scripts/combat_moves.gd")
	var names: Array = catalog.MOVES.keys()
	names.append_array(["Down", "Rise"])
	var study := not OS.get_cmdline_user_args().is_empty()
	if study:
		names = ["GetUp", "GetUp", "GetUp", "GetUp", "GetUp", "GetUp", "GetUp", "GetUp", "Down", "Down", "Down", "Down"]
	for i in names.size():
		var visual := preload("res://scripts/kung_fu_visual.gd").new()
		stage.add_child(visual)
		visual.position = Vector3((i % 4 - 1.5) * 2.6, 0, (i / 4 - 1.5) * 2.8)
		visual.rotation.y = -0.5
		if study:
			var time := (i % 8) * 0.215 if i < 8 else (i - 8) * 0.8
			visual._sample_pose(names[i], time)
			print(names[i], " ", time, " hips ", visual.to_local(visual.bone_world("Hips")), " head ", visual.to_local(visual.bone_world("Head")))
		elif catalog.MOVES.has(names[i]):
			var move: Dictionary = catalog.MOVES[names[i]]
			if names[i] in ["FrontKick", "SideKick", "Knee"]:
				visual._sample_pose(move.clip, move.contact * move.rate)
				print(names[i], " base feet ", visual.to_local(visual.bone_world("LeftFoot")), " / ", visual.to_local(visual.bone_world("RightFoot")))
			visual.play_move(move, 0)
			visual.motion_time = move.contact
			visual.tick(0)
			print(names[i], " endpoint ", visual.to_local(visual.bone_world(move.bone)))
		else:
			visual.sample(names[i], 1.2 if names[i] == "Down" else 0.5)
		var label := Label3D.new()
		label.text = names[i] + (" " + str(i) if study else "")
		label.font_size = 30
		label.position = visual.position + Vector3(0, 1.9, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/qa/recovery-study.png" if study else "res://../docs/qa/flow-move-poses.png"))
	quit()
