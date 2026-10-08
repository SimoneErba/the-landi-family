extends TextureRect
## Reusable archive portrait: authored identity library with stable age variants.

const Identity = preload("res://Simulation/PortraitIdentity.gd")
const FEATURES = preload("res://Scripts/PortraitFeatures.gdshader")
const LOCATIONS := {
	"giovanni": ["men", 0, 3], "carlo": ["men", 1, 3], "pietro": ["men", 2, 3],
	"maria": ["women", 0, 4], "anna": ["women", 1, 4],
	"lucia": ["women", 2, 4], "sofia": ["women", 3, 4],
}
static var _atlases: Dictionary = {}
static var _portraits: Dictionary = {}


func _init() -> void:
	name = "Face"
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var features := ShaderMaterial.new()
	features.shader = FEATURES
	material = features


func show_person(person: RefCounted) -> void:
	var base: String = person.portrait.appearance["base_face"]
	var stage: int = Identity.age_stage(person.age)
	var key := "%s:%d" % [base, stage]
	if not _portraits.has(key):
		var location: Array = LOCATIONS.get(base, LOCATIONS["giovanni"])
		var atlas_id: String = location[0]
		if not _atlases.has(atlas_id):
			_atlases[atlas_id] = load("res://Assets/Portraits/%s-v1.png" % atlas_id)
		var atlas: Texture2D = _atlases[atlas_id]
		if atlas == null:
			return
		var cell := Vector2(atlas.get_width() / 5.0, atlas.get_height() / float(location[2]))
		var portrait_texture := AtlasTexture.new()
		portrait_texture.atlas = atlas
		portrait_texture.region = Rect2(Vector2(stage * cell.x, int(location[1]) * cell.y), cell)
		portrait_texture.filter_clip = true
		_portraits[key] = portrait_texture
	texture = _portraits[key]
	# Each instance owns its material. Shared atlas regions never share identity uniforms.
	if material == null or not material is ShaderMaterial:
		material = ShaderMaterial.new()
		material.shader = FEATURES
	var region: Rect2 = texture.region
	var atlas_size: Vector2 = texture.atlas.get_size()
	material.set_shader_parameter("cell_region", Vector4(region.position.x / atlas_size.x, region.position.y / atlas_size.y, region.size.x / atlas_size.x, region.size.y / atlas_size.y))
	for trait_name in Identity.TRAITS:
		material.set_shader_parameter(trait_name, person.portrait.genetics[trait_name])
	material.set_shader_parameter("grey_amount", clampf((person.age - 40.0) / 35.0, 0.0, 1.0))
