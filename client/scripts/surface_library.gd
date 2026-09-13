extends RefCounted

const CONCRETE := "res://assets/materials/Concrete030/Concrete030_1K-JPG_"
const METAL := "res://assets/materials/Metal032/Metal032_1K-JPG_"

static func pbr(kind: String, tint: Color = Color.WHITE, tiling: float = 0.5) -> StandardMaterial3D:
	var prefix := METAL if kind == "metal" else CONCRETE
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(prefix + "Color.jpg")
	material.normal_enabled = true
	material.normal_texture = load(prefix + "NormalGL.jpg")
	material.normal_scale = 0.65
	material.roughness_texture = load(prefix + "Roughness.jpg")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 0.85
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * tiling
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if kind == "metal":
		material.metallic = 0.65
		material.metallic_texture = load(prefix + "Metalness.jpg")
		material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	return material
