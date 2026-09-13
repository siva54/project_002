extends SceneTree

func _initialize() -> void:
	call_deferred("_inspect")

func _inspect() -> void:
	var model = load("res://assets/characters/RobotExpressive.glb").instantiate()
	root.add_child(model)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		print(node.name, " bounds=", node.global_transform * node.get_aabb())
	for node in model.find_children("*", "AnimationPlayer", true, false):
		print("ANIMATIONS: ", node.get_animation_list())
		for id in ["Idle", "Walking", "Running", "Punch", "Jump"]:
			var clip: Animation = node.get_animation(id)
			print(id, " length=", clip.length, " first track=", clip.track_get_path(0))
	quit()
