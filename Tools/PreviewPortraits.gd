extends SceneTree
## Run with --script Tools/PreviewPortraits.gd; append -- --capture to export and quit.

const State = preload("res://Simulation/GameState.gd")
const Portrait = preload("res://Scripts/PersonPortrait.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1400, 940)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var state := State.new()
	state.initialize(source)
	var page := ColorRect.new()
	page.color = Color("#e6d8bf")
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(page)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 28)
	page.add_child(margins)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margins.add_child(content)
	_add_label(content, "The family archive · Procedural portrait engine", 28)
	_add_label(content, "Five unrelated founders, five inherited descendants. New relatives need no image generation.", 17)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 24)
	content.add_child(grid)
	for index in range(10):
		var presentation := "masculine" if index < 5 else "feminine"
		var parents: Array = [] if index < 5 else ["Giovanni", "Maria"]
		var person = state.add_person("PortraitPreview-%d" % index, {"age": 28, "parent_ids": parents, "portrait": {"appearance": {"presentation": presentation}}})
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		grid.add_child(column)
		var portrait := Portrait.new()
		portrait.custom_minimum_size = Vector2(245, 245)
		column.add_child(portrait)
		portrait.show_person(person)
		_add_label(column, "%s %d · age 28" % ["Founder" if index < 5 else "Descendant", index % 5 + 1], 16)
	_add_label(content, "Aging retains the inherited identity", 21)
	var ages := HBoxContainer.new()
	ages.add_theme_constant_override("separation", 22)
	content.add_child(ages)
	var aging_person = state.people["PortraitPreview-0"]
	for age in [8, 16, 28, 50, 75]:
		aging_person.age = age
		var column := VBoxContainer.new()
		ages.add_child(column)
		var portrait := Portrait.new()
		portrait.custom_minimum_size = Vector2(190, 190)
		column.add_child(portrait)
		portrait.show_person(aging_person)
		_add_label(column, "Age %d" % age, 15)
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://Assets/Portraits/engine-preview.png")
		assert(result == OK)
		quit()

func _add_label(parent: Node, text: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#392b20"))
	parent.add_child(label)
