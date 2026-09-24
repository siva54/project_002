extends SceneTree

var dojo: Node3D
var output := "res://../docs/qa/"

func _initialize() -> void:
	_run.call_deferred()

func save_frame(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output + name + ".png"))

func wait_frames(count: int) -> void:
	for i in count:
		await process_frame

func _run() -> void:
	dojo = load("res://scenes/kung_fu_dojo.tscn").instantiate()
	root.add_child(dojo)
	await wait_frames(60)
	await save_frame("kung-fu-title")
	dojo.resume_match()
	dojo.training_dummy = true
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(0, 0.03, -0.85)
	await wait_frames(20)
	await save_frame("kung-fu-courtyard")
	dojo.attack("light")
	await wait_frames(12)
	await save_frame("kung-fu-strike")
	await wait_frames(20)
	dojo.attack("light")
	await wait_frames(40)
	dojo.attack("light")
	await wait_frames(18)
	await save_frame("kung-fu-roundhouse")
	await wait_frames(37)
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(0, 0.03, -1.1)
	dojo.attack("heavy")
	await wait_frames(30)
	await save_frame("kung-fu-spin-kick")
	await wait_frames(70)
	dojo.hero.request_evade(Vector3(1, 0, 0))
	await wait_frames(20)
	await save_frame("kung-fu-aerial-evade")
	await wait_frames(45)
	dojo.reset_match()
	dojo.resume_match()
	dojo.training_dummy = true
	dojo.hero.position = Vector3(0, 0.03, 0.5)
	dojo.rivals[0].position = Vector3(0, 0.03, -0.65)
	await wait_frames(10)
	dojo.grapple()
	await wait_frames(34)
	await save_frame("kung-fu-ragdoll-throw")
	await wait_frames(70)
	await save_frame("kung-fu-recovery")
	await wait_frames(90)
	await save_frame("kung-fu-return-to-guard")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Kung fu gameplay captures complete.")
	quit()
