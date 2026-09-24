extends SceneTree

const Fighter := preload("res://scripts/kung_fu_fighter.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dojo: Node3D = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	var review_camera := Camera3D.new()
	dojo.add_child(review_camera)
	review_camera.fov = 42
	review_camera.current = true
	var label := Label.new()
	label.position = Vector2(24, 143)
	label.add_theme_font_size_override("font_size", 23)
	dojo.add_child(label)
	for frame in 750:
		if frame % 150 == 0:
			dojo.reset_match()
			dojo.resume_match()
			dojo.training_dummy = true
			for extra in dojo.rivals.slice(1):
				dojo.rivals.erase(extra)
				extra.queue_free()
			dojo.hero.position = Vector3(0, 0.03, 0.55)
			var direction := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(25 if frame == 0 else (-25 if frame == 150 else 0)))
			dojo.rivals[0].position = dojo.hero.position + direction * (1.35 if frame in [150, 300] else 1.15)
			dojo.hero.face(direction)
			dojo.rivals[0].face(-direction)
			review_camera.position = Vector3(3.1, 1.75, 3.7)
			review_camera.look_at(Vector3(0, 0.95, 0))
			label.text = ["ANGLED JAB > CROSS", "CRANE STRAIGHT", "STEPPING KARATE STRAIGHT", "RIGHT DEFENSIVE SLIP", "LEFT DEFENSIVE SLIP"][frame / 150]
		if frame in [20, 27]:
			dojo.hero.request_attack("light", dojo.rivals[0])
		if frame == 170:
			dojo.hero.action_name = "Uppercut"
			dojo.hero.combo_age = 1
			dojo.hero.request_attack("light", dojo.rivals[0])
		if frame == 320:
			dojo.hero.drive = Vector3.FORWARD
			dojo.hero.request_attack("light", dojo.rivals[0])
		if frame in [470, 620]:
			dojo.hero.request_evade(Vector3.RIGHT if frame == 470 else Vector3.LEFT)
		await process_frame
		if frame in [10, 20, 31, 42, 55, 180, 197, 207, 321, 339, 353, 470, 483, 496, 620, 633, 646]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/karate-position-%03d.png" % frame))
	dojo.stop_audio()
	OS.delay_msec(60)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
