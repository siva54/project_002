extends SceneTree

const Fighter := preload("res://scripts/kung_fu_fighter.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dojo: Node3D = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.resume_match()
	# One continuous live-AI encounter, initialized close enough to show contact.
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(0, 0.03, -0.65)
	dojo.rivals[0].ai_delay = 0.9
	dojo.rivals[1].position = Vector3(2.0, 0.03, -0.8)
	dojo.rivals[1].chain_index = 2
	dojo.rivals[1].ai_delay = 2.5
	var captured := {}
	for frame in 900:
		await process_frame
		if frame in [20, 26, 45, 66, 89]:
			dojo.attack("light")
		if frame > 110:
			var incoming := false
			for rival in dojo.rivals:
				if rival.state == Fighter.State.ATTACK and rival.move.contact - rival.state_time < 0.12:
					incoming = true
			if incoming and dojo.hero.state == Fighter.State.READY and dojo.round_number == 1:
				Input.action_press("guard")
			else:
				Input.action_release("guard")
		if dojo.hero.state == Fighter.State.COUNTER:
			var key: String = dojo.hero.pair_kind + "-" + str(floori(dojo.hero.state_time / 0.15))
			if not captured.has(key):
				captured[key] = true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/flow-" + key + ".png"))
		if dojo.round_number > 1 and frame % 18 == 0:
			dojo.attack("kick" if frame % 54 == 0 else "light")
	print("Contact flow recording: ", captured.keys())
	dojo.stop_audio()
	OS.delay_msec(60)
	Input.action_release("guard")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
