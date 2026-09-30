extends SceneTree

const HEAD := preload("res://assets/characters/vitruvian/vitruvian_head.glb")
const OUTPUT := "res://assets/characters/vitruvian/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := HEAD.instantiate()
	root.add_child(scene)
	var head: MeshInstance3D
	for item in scene.find_children("*", "MeshInstance3D", true, false):
		if item.name == "cm_vitruvian":
			head = item
			break
	if head == null:
		push_error("Head skin mesh missing")
		quit(1)
		return
	var arrays: Array = head.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for style in [{"name": "crew", "base": 1.57}, {"name": "buzz", "base": 1.60}]:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var kept := 0
		for triangle in range(0, indices.size(), 3):
			var a: int = indices[triangle]
			var b: int = indices[triangle + 1]
			var c: int = indices[triangle + 2]
			if not _in_hairline(vertices[a], style.base) or not _in_hairline(vertices[b], style.base) or not _in_hairline(vertices[c], style.base):
				continue
			for index in [a, b, c]:
				builder.set_normal(normals[index])
				builder.add_vertex(vertices[index] + normals[index] * 0.003)
			kept += 1
		var cap: ArrayMesh = builder.commit()
		cap.resource_name = style.name.capitalize() + " cut"
		ResourceSaver.save(cap, OUTPUT + style.name + "_cut.res")
		print(style.name, ": ", kept, " triangles")
	quit()

func _in_hairline(point: Vector3, base: float) -> bool:
	var front := smoothstep(-0.04, 0.10, point.z)
	return point.y > base + 0.10 * front
