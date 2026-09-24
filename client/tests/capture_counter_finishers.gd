extends SceneTree

const Fighter := preload("res://scripts/kung_fu_fighter.gd")
var dojo: Node3D
var captures := {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	dojo = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.resume_match()
	# Continuous live-AI bout; the second opponent opens with its kick branch.
	dojo.rivals[1].chain_index = 2
	for frame in 900:
		await process_frame
		if dojo.hero.state == Fighter.State.READY:
			var incoming: CharacterBody3D = null
			for rival in dojo.rivals:
				if rival.state == Fighter.State.ATTACK and rival.move.contact - rival.state_time < 0.12:
					incoming = rival
			if incoming != null and dojo.round_number == 1:
				Input.action_press("guard")
			else:
				Input.action_release("guard")
		else:
			Input.action_release("guard")
		if dojo.hero.state == Fighter.State.COUNTER:
			var stage: String = dojo.hero.pair_kind + "-" + str(floori(dojo.hero.state_time / 0.24))
			if not captures.has(stage):
				captures[stage] = true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/qa/" + stage + ".png"))
		if dojo.round_number > 1 and frame % 18 == 0:
			dojo.attack("kick" if frame % 54 == 0 else "light")
		if frame == 120:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/qa/counter-finishers.png"))
	print("Continuous counter capture: ", captures.keys())
	dojo.stop_audio()
	OS.delay_msec(60)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
