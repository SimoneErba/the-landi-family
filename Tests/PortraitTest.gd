extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Identity = preload("res://Simulation/PortraitIdentity.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# All generated identities have an illustrated age variant and valid atlas bounds.
	var portrait_script = load("res://Scripts/PersonPortrait.gd")
	for base in Identity.BASES:
		var identity_person = State.Person.new("AtlasCheck_" + base, {"age":28, "portrait":{"appearance":{"base_face":base}}}, 1800, 1, "")
		var portrait = portrait_script.new()
		for age in [8,16,28,50,75]:
			identity_person.age = age
			portrait.show_person(identity_person)
			assert(portrait.texture != null)
			var atlas: AtlasTexture = portrait.texture
			assert(atlas.region.position.x >= 0 and atlas.region.position.y >= 0)
			assert(atlas.region.end.x <= atlas.atlas.get_width() + .01 and atlas.region.end.y <= atlas.atlas.get_height() + .01)
		portrait.free()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var state := State.new()
	state.initialize(source)
	state.events.enabled = false
	var saved: Dictionary = state.people["Carlo"].portrait.to_data()
	var restored := Identity.new("Carlo", saved)
	assert(restored.to_data() == saved, "Identity round trips without changing the face")
	var reversed_source: Dictionary = {}
	var ids: Array = source.keys()
	ids.reverse()
	for person_id in ids:
		reversed_source[person_id] = source[person_id].duplicate(true)
	# An unauthored child's genetics must be resolved from parents independent of roster order.
	reversed_source["Child"] = {"birth": {"year": 1905, "month": 1}, "parent_ids": ["Giovanni", "Maria"], "portrait": {"appearance": {"presentation": "feminine"}}}
	var first := State.new()
	first.initialize(reversed_source)
	first.events.enabled = false
	ids = reversed_source.keys()
	ids.reverse()
	var ordered: Dictionary = {}
	for person_id in ids:
		ordered[person_id] = reversed_source[person_id]
	var second := State.new()
	second.initialize(ordered)
	second.events.enabled = false
	assert(first.people["Child"].portrait.to_data() == second.people["Child"].portrait.to_data())
	for trait_name in Identity.TRAITS:
		var low := minf(state.people["Giovanni"].portrait.genetics[trait_name], state.people["Maria"].portrait.genetics[trait_name]) - 0.04
		var high := maxf(state.people["Giovanni"].portrait.genetics[trait_name], state.people["Maria"].portrait.genetics[trait_name]) + 0.04
		assert(first.people["Child"].portrait.genetics[trait_name] >= low)
		assert(first.people["Child"].portrait.genetics[trait_name] <= high)
	assert(Identity.age_stage(12) == 0 and Identity.age_stage(13) == 1)
	assert(Identity.age_stage(21) == 1 and Identity.age_stage(22) == 2)
	assert(Identity.age_stage(39) == 2 and Identity.age_stage(40) == 3)
	assert(Identity.age_stage(64) == 3 and Identity.age_stage(65) == 4)
	saved["genetics"].clear()
	assert(not state.people["Carlo"].portrait.genetics.is_empty(), "Serialized identity is a copy")

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	var family_list: Node = screen.get_node("PageMargins/Page/RosterScroll/FamilyList")
	for person_id in source:
		var face: TextureRect = family_list.get_node(NodePath(person_id + "/Row/Portrait/Face"))
		assert(face.texture != null, "Every starter has a portrait")
		assert(not family_list.get_node(NodePath(person_id + "/Row/Portrait")).has_node("Initials"))
		var texture: AtlasTexture = face.texture
		assert(texture.region.end.x <= texture.atlas.get_width() + 0.01)
		assert(texture.region.end.y <= texture.atlas.get_height() + 0.01)
	var carlo_face: TextureRect = family_list.get_node("Carlo/Row/Portrait/Face")
	var old_texture: Texture2D = carlo_face.texture
	screen.people["Carlo"].age = 40
	screen._refresh_people()
	assert(carlo_face.texture != old_texture, "Portrait changes when aging into a new stage")
	assert(screen.people["Carlo"].portrait.to_data() == restored.to_data(), "Aging preserves identity")
	screen._show_person("Carlo")
	var detail_face: TextureRect = screen.details_content.get_child(1).get_node("Portrait/Face")
	assert(detail_face.texture == carlo_face.texture, "Details and roster show the same identity and age")
	screen.game_clock.state.household["members"].erase("Carlo")
	screen._refresh_people()
	var outside_face: TextureRect = screen.elsewhere_list.get_node("Carlo/Row/Portrait/Face")
	assert(outside_face.texture == carlo_face.texture, "Departure preserves the portrait")
	assert(screen.elsewhere_list.get_node("Carlo").visible)
	var newcomer = screen.game_clock.state.add_person("NewRelative", {"name": "New Relative", "age": 20, "parent_ids": ["Giovanni", "Maria"], "portrait": {"appearance": {"presentation": "feminine"}}})
	assert(newcomer != null)
	screen._refresh_people()
	var new_face: TextureRect = family_list.get_node("NewRelative/Row/Portrait/Face")
	assert(new_face.texture != null, "New people need no authored portrait or scene node")
	assert(new_face.material != screen.elsewhere_list.get_node("NewRelative/Row/Portrait/Face").material)
	assert(new_face.material.get_shader_parameter("nose_length") == newcomer.portrait.genetics["nose_length"])
	assert(screen.game_clock.state.add_person("NewRelative", {}) == null, "Duplicate arrivals cannot overwrite an identity")
	var sibling = screen.game_clock.state.add_person("NewSibling", {"age": 20, "parent_ids": ["Giovanni", "Maria"], "portrait": {"appearance": {"presentation": "feminine", "base_face": newcomer.portrait.appearance["base_face"]}}})
	screen._refresh_people()
	var sibling_face: TextureRect = family_list.get_node("NewSibling/Row/Portrait/Face")
	assert(new_face.texture == sibling_face.texture, "Library art can be shared")
	assert(new_face.material != sibling_face.material)
	assert(new_face.material.get_shader_parameter("eye_spacing") != sibling_face.material.get_shader_parameter("eye_spacing"), "Shared base faces have independently inherited features")
	var stable: Dictionary = newcomer.portrait.to_data()
	for index in range(24):
		screen.game_clock.state.advance_month()
	screen._refresh_people()
	assert(newcomer.portrait.to_data() == stable)
	screen.game_clock.state.household["members"].erase("NewRelative")
	screen._refresh_people()
	assert(screen.elsewhere_list.get_node("NewRelative").visible)
	screen.free()
	print("PASS: portrait persistence, inherited genetics, initialization order, age stages, atlas regions, all starter faces, details and departure")
	quit()
