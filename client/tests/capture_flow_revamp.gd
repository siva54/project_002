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

func single_partner() -> CharacterBody3D:
	dojo.reset_match()
	dojo.resume_match()
	dojo.training_dummy = true
	for extra in dojo.rivals.slice(1):
		dojo.rivals.erase(extra)
		extra.queue_free()
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	var rival: CharacterBody3D = dojo.rivals[0]
	rival.position = Vector3(0, 0.03, -0.7)
	rival.face(Vector3.BACK)
	return rival

func _run() -> void:
	dojo = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	await frames(30)
	await capture("flow-revamp-title")
	var rival := single_partner()
	await frames(30)
	dojo.attack("light")
	await frames(7)
	dojo.attack("light")
	await frames(14)
	Input.action_press("move_right")
	await frames(6)
	await capture("flow-moving-cross")
	Input.action_release("move_right")
	dojo.attack("light")
	await frames(22)
	dojo.attack("light")
	await frames(20)
	await capture("flow-hook-chain")
	dojo.attack("light")
	await frames(27)
	dojo.attack("light")
	await frames(60)
	await capture("flow-controlled-knockdown")
	await frames(100)
	# A second exchange demonstrates the kick branch and foot contact.
	rival = single_partner()
	await frames(20)
	dojo.attack("kick")
	await frames(21)
	await capture("flow-front-kick")
	dojo.attack("kick")
	await frames(31)
	await capture("flow-side-kick")
	dojo.attack("light")
	await frames(60)
	dojo.hero.request_evade(Vector3.RIGHT)
	await frames(16)
	await capture("flow-grounded-evade")
	await frames(20)
	# Counter input drives the real exchange, then the clinch follow-up stays animated.
	rival = single_partner()
	await frames(15)
	rival.request_attack("light", dojo.hero)
	await frames(6)
	Input.action_press("guard")
	await frames(38)
	Input.action_release("guard")
	await capture("flow-counter")
	await frames(35)
	dojo.grapple()
	await frames(14)
	await capture("flow-collar-control")
	dojo.attack("light")
	await frames(30)
	await capture("flow-clinch-knee")
	await frames(44)
	await capture("flow-controlled-fall")
	await frames(110)
	dojo.grapple()
	await frames(12)
	dojo.attack("kick")
	await frames(35)
	await capture("flow-sweep")
	await frames(115)
	var guide := InputEventKey.new()
	guide.physical_keycode = KEY_TAB
	guide.pressed = true
	dojo._unhandled_input(guide)
	await frames(10)
	await capture("flow-move-list")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Flow revamp captures complete. Active physical bones: ", dojo.find_children("*", "PhysicalBone3D", true, false).size())
	quit()
