extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var lab = load("res://scenes/hero_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://../docs/qa/")
	root.get_texture().get_image().save_png(directory + "hero-builder.png")
	for id in ["bolt", "blink", "kinetic"]:
		lab._toggle_power(id)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "three-power-build.png")
	lab.start_play()
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "power-playground.png")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Saved hero builder and playground screenshots to ", directory)
	quit()
