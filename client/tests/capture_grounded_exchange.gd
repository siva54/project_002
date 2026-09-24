extends SceneTree

# A deliberately isolated animation review: two views of the same one-two,
# followed by the kick and counter. Resets are marked, not a live-bout claim.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dojo: Node3D = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.resume_match()
	dojo.training_dummy = true
	var review_camera := Camera3D.new()
	dojo.add_child(review_camera)
	review_camera.fov = 43
	review_camera.current = true
	var label := Label.new()
	label.position = Vector2(28, 145)
	label.add_theme_font_size_override("font_size", 22)
	dojo.add_child(label)
	for frame in 660:
		if frame in [0, 180, 360, 480]:
			dojo.reset_match()
			dojo.resume_match()
			dojo.training_dummy = true
			for extra in dojo.rivals.slice(1):
				dojo.rivals.erase(extra)
				extra.queue_free()
			dojo.hero.position = Vector3(0, 0.03, 0.55)
			dojo.rivals[0].position = Vector3(0, 0.03, -0.57)
			dojo.hero.face(Vector3.FORWARD)
			dojo.rivals[0].face(Vector3.BACK)
			review_camera.position = Vector3(3.9, 1.8, 2.1) if frame != 180 else Vector3(-4.2, 1.5, 0.4)
			review_camera.look_at(Vector3(0, 0.88, 0))
			label.text = "ONE-TWO / THREE-QUARTER VIEW" if frame == 0 else ("ONE-TWO / SIDE VIEW" if frame == 180 else ("FRONT KICK / SUPPORT FOOT" if frame == 360 else "COUNTER / SAME GAMEPLAY CONTROLLER"))
		if frame in [35, 40, 215, 220]:
			dojo.attack("light")
		if frame == 395:
			dojo.attack("kick")
		if frame == 500:
			dojo.rivals[0].request_attack("light", dojo.hero)
		if frame > 500 and dojo.rivals[0].state == 1 and dojo.rivals[0].move.contact - dojo.rivals[0].state_time < 0.12:
			Input.action_press("guard")
		else:
			Input.action_release("guard")
		await process_frame
		if frame in [35, 42, 47, 53, 60, 68, 76, 90, 402, 412, 420, 435, 528, 550, 580, 606]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/grounded-%03d.png" % frame))
	dojo.stop_audio()
	OS.delay_msec(60)
	Input.action_release("guard")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
