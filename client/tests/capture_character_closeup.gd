extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dojo: Node3D = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.reset_match()
	dojo.resume_match()
	dojo.training_dummy = true
	for extra in dojo.rivals.slice(1):
		dojo.rivals.erase(extra)
		extra.queue_free()
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(1.7, 0.03, 0)
	dojo.hero.face(Vector3.FORWARD)
	dojo.rivals[0].face(Vector3.BACK)
	var review := Camera3D.new()
	dojo.add_child(review)
	review.position = dojo.hero.position + Vector3(0.65, 1.62, -1.45)
	review.look_at(dojo.hero.position + Vector3.UP * 1.40)
	review.fov = 40
	review.current = true
	for frame in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/character-closeup.png"))
	dojo.stop_audio()
	quit()
