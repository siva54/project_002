extends SceneTree

var dojo: Node3D

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/qa/" + name + ".png"))

func _run() -> void:
	dojo = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	dojo.resume_match()
	dojo.training_dummy = true
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	var rival: CharacterBody3D = dojo.rivals[0]
	rival.position = Vector3(0, 0.03, -0.7)
	rival.face(dojo.hero.position - rival.position)
	await frames(30)
	dojo.attack("light")
	await frames(10)
	await capture("combat-connected-jab")
	await frames(8)
	dojo.attack("light")
	await frames(25)
	await capture("combat-connected-cross")
	await frames(65)
	# An actual incoming attack and guard input drive the counter sequence.
	rival.target = dojo.hero
	rival.request_attack("light")
	await frames(6)
	Input.action_press("guard")
	await frames(11)
	await capture("combat-counter-deflect")
	await frames(19)
	await capture("combat-counter-contact")
	Input.action_release("guard")
	await frames(90)
	print("Exchange captured: hero vitality ", dojo.hero.health, ", rival vitality ", rival.health)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit()
