extends RefCounted
## Visual identity is independent of personality and observer knowledge.
## Persist to_data() alongside a person when save games are implemented.

const TRAITS := ["face_length", "jaw_width", "eye_spacing", "nose_length", "skin_tone", "hair_wave", "eye_size", "nose_width", "mouth_width", "hair_color"]
const BASES := {
	"giovanni": {"presentation": "masculine", "genes": [0.8, 0.55, 0.45, 0.8, 0.55, 0.6]},
	"carlo": {"presentation": "masculine", "genes": [0.7, 0.45, 0.5, 0.55, 0.5, 0.5]},
	"pietro": {"presentation": "masculine", "genes": [0.6, 0.8, 0.45, 0.75, 0.55, 0.8]},
	"maria": {"presentation": "feminine", "genes": [0.4, 0.4, 0.6, 0.35, 0.45, 0.4]},
	"anna": {"presentation": "feminine", "genes": [0.65, 0.45, 0.55, 0.45, 0.5, 0.5]},
	"lucia": {"presentation": "feminine", "genes": [0.5, 0.65, 0.6, 0.4, 0.55, 0.5]},
	"sofia": {"presentation": "feminine", "genes": [0.55, 0.7, 0.55, 0.6, 0.55, 0.7]},
	"blond_sidepart": {"presentation": "masculine", "genes": [0.75, 0.3, 0.6, 0.4, 0.3, 0.3], "hair": 0.7},
	"black_crop": {"presentation": "masculine", "genes": [0.45, 0.8, 0.4, 0.5, 0.65, 0.25], "hair": 0.25},
	"auburn_curls": {"presentation": "masculine", "genes": [0.35, 0.6, 0.65, 0.35, 0.3, 0.8], "hair": 0.6},
	"chestnut_swept": {"presentation": "masculine", "genes": [0.75, 0.65, 0.4, 0.8, 0.55, 0.65], "hair": 0.45},
	"brown_middlepart": {"presentation": "masculine", "genes": [0.55, 0.7, 0.6, 0.55, 0.55, 0.3], "hair": 0.35},
	"honey_braidbun": {"presentation": "feminine", "genes": [0.6, 0.35, 0.6, 0.35, 0.3, 0.4], "hair": 0.7},
	"black_braids": {"presentation": "feminine", "genes": [0.5, 0.8, 0.45, 0.65, 0.65, 0.25], "hair": 0.25},
	"copper_curls": {"presentation": "feminine", "genes": [0.35, 0.6, 0.7, 0.35, 0.3, 0.8], "hair": 0.6},
	"ash_twist": {"presentation": "feminine", "genes": [0.8, 0.3, 0.45, 0.6, 0.4, 0.4], "hair": 0.8},
	"chestnut_bun": {"presentation": "feminine", "genes": [0.5, 0.8, 0.55, 0.55, 0.55, 0.55], "hair": 0.45},
}

var seed: int
var genetics: Dictionary = {}
var appearance: Dictionary = {}


func _init(person_id: String, source: Dictionary = {}, parents: Array = []) -> void:
	# Explicit algorithm rather than global RNG or engine-dependent string hashes.
	seed = int(source.get("seed", stable_seed(person_id)))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var supplied: Dictionary = source.get("genetics", {})
	for index in range(TRAITS.size()):
		var key: String = TRAITS[index]
		var value := rng.randf_range(0.25, 0.8)
		if not parents.is_empty():
			var first: float = parents[0].genetics[key]
			var second: float = parents[-1].genetics[key]
			value = lerpf(first, second, rng.randf_range(0.25, 0.75)) + rng.randf_range(-0.04, 0.04)
		genetics[key] = clampf(float(supplied.get(key, value)), 0.0, 1.0)
	appearance = source.get("appearance", {}).duplicate(true)
	appearance["presentation"] = str(appearance.get("presentation", "masculine" if seed % 2 == 0 else "feminine"))
	var base_face := str(appearance.get("base_face", ""))
	if not BASES.has(base_face):
		base_face = _choose_base()
	appearance["base_face"] = base_face



static func stable_seed(person_id: String) -> int:
	var result := 5381
	for byte in person_id.to_utf8_buffer():
		result = (result * 33 + int(byte)) & 0x7fffffff
	return result


func _choose_base() -> String:
	# A weighted match keeps the central prototype from absorbing every new face.
	# Genetics biases the reusable foundation; the same seed always picks the same one.
	var candidates: Array = []
	var total := 0.0
	for base_id in BASES:
		var base: Dictionary = BASES[base_id]
		if base["presentation"] != appearance["presentation"]:
			continue
		var score := 0.0
		for index in range(base["genes"].size()):
			score += pow(float(genetics[TRAITS[index]]) - float(base["genes"][index]), 2)
		score += pow(float(genetics["hair_color"]) - float(base.get("hair", 0.4)), 2) * 1.5
		var weight := exp(-score * 6.0)
		total += weight
		candidates.append({"id": base_id, "weight": weight})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed ^ 0x5bd1e995
	var pick := rng.randf() * total
	for candidate in candidates:
		pick -= float(candidate["weight"])
		if pick <= 0.0:
			return str(candidate["id"])
	return str(candidates[-1]["id"]) if not candidates.is_empty() else "giovanni"


func to_data() -> Dictionary:
	return {"seed": seed, "genetics": genetics.duplicate(true), "appearance": appearance.duplicate(true)}


static func age_stage(age: int) -> int:
	if age < 13:
		return 0
	if age < 22:
		return 1
	if age < 40:
		return 2
	if age < 65:
		return 3
	return 4
