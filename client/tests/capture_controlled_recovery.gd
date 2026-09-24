extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dojo: Node3D = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.resume_match()
	dojo.training_dummy = true
	for extra in dojo.rivals.slice(1):
		dojo.rivals.erase(extra)
		extra.queue_free()
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(0, 0.03, -0.35)
	dojo.yaw = 0.55
	for frame in 270:
		await process_frame
		if frame == 25:
			dojo.grapple()
		if frame == 40:
			dojo.attack("kick")
		if frame in [60, 80, 105, 145, 160, 180, 200, 230]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/recovery-%d.png" % frame))
	dojo.stop_audio()
	OS.delay_msec(60)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
