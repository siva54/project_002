extends SceneTree

const SOURCE := "res://assets/characters/vitruvian/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source: PackedScene = load(SOURCE + "hairtool_cards.glb")
	var scene := source.instantiate()
	root.add_child(scene)
	var mesh_instance := scene.get_node("VitEveGuides_converted") as MeshInstance3D
	var arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for cut in [{"name": "short", "height": 1.66}, {"name": "medium", "height": 1.62}]:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var kept := 0
		for triangle in range(0, indices.size(), 3):
			var a: int = indices[triangle]
			var b: int = indices[triangle + 1]
			var c: int = indices[triangle + 2]
			if minf(vertices[a].y, minf(vertices[b].y, vertices[c].y)) < cut.height:
				continue
			for index in [a, b, c]:
				builder.set_normal(normals[index])
				builder.set_uv(uvs[index])
				builder.add_vertex(vertices[index])
			kept += 1
		var trimmed: ArrayMesh = builder.commit()
		trimmed.resource_name = "Hair " + cut.name
		ResourceSaver.save(trimmed, SOURCE + "hair_" + cut.name + ".res")
		print(cut.name, ": ", kept, " of ", indices.size() / 3, " triangles")
	var diffuse := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + "vit_hair_diffuse.png"))
	var opacity := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + "vit_hair_opacity.png"))
	diffuse.resize(512, 512)
	opacity.resize(512, 512)
	for y in 512:
		for x in 512:
			var color := diffuse.get_pixel(x, y)
			color.r = minf(1.0, color.r * 3.0)
			color.g = minf(1.0, color.g * 3.0)
			color.b = minf(1.0, color.b * 3.0)
			color.a = smoothstep(0.12, 0.55, opacity.get_pixel(x, y).r)
			diffuse.set_pixel(x, y, color)
	diffuse.save_png(ProjectSettings.globalize_path(SOURCE + "hair_strands.png"))
	quit()
