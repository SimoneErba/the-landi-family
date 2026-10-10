extends TextureRect
## Reusable archive portrait: authored identity library with stable age variants.

const Identity = preload("res://Simulation/PortraitIdentity.gd")
const FEATURES = preload("res://Scripts/PortraitFeatures.gdshader")
const LOCATIONS := {
	"giovanni": ["men", 0, 3], "carlo": ["men", 1, 3], "pietro": ["men", 2, 3],
	"maria": ["women", 0, 4], "anna": ["women", 1, 4],
	"lucia": ["women", 2, 4], "sofia": ["women", 3, 4],
	"blond_sidepart": ["men-variety", 0, 5],
	"black_crop": ["men-variety", 1, 5],
	"auburn_curls": ["men-variety", 2, 5],
	"chestnut_swept": ["men-variety", 3, 5],
	"brown_middlepart": ["men-variety", 4, 5],
	"honey_braidbun": ["women-variety", 0, 5],
	"black_braids": ["women-variety", 1, 5],
	"copper_curls": ["women-variety", 2, 5],
	"ash_twist": ["women-variety", 3, 5],
	"chestnut_bun": ["women-variety", 4, 5],
}
# Generated sheets have slightly unequal rows; use their observed cell boundaries.
# A small inset excludes the printed divider, without cropping the hair silhouette.
const ATLAS_GRIDS := {
	"men-variety": {"columns": [0,251,502,754,1006,1254], "rows": [0,248,490,735,980,1254]},
	"women-variety": {"columns": [0,249,502,756,1013,1254], "rows": [0,249,491,739,987,1254]},
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
		if ATLAS_GRIDS.has(atlas_id):
			var grid: Dictionary = ATLAS_GRIDS[atlas_id]
			var row: int = location[1]
			var scale := atlas.get_size() / 1254.0
			var origin := Vector2(grid["columns"][stage] + 2, grid["rows"][row] + 2) * scale
			var end := Vector2(grid["columns"][stage + 1] - 2, grid["rows"][row + 1] - 2) * scale
			portrait_texture.region = Rect2(origin, end - origin)
		else:
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
		if trait_name not in ["hair_color", "hair_wave"]:
			material.set_shader_parameter(trait_name, person.portrait.genetics[trait_name])
