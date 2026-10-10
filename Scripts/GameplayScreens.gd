extends RefCounted
## Native work-in-progress views of the activity and village simulation.

static func _column(host) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_overlay.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	return column


static func village(host) -> void:
	var column := _column(host)
	var state = host.game_clock.state
	host._add_label(column, "The village", 32, host.TEXT_MAIN)
	var village_view := preload("res://Scripts/VillageScreen.gd").new()
	village_view.host = host
	host.village_view = village_view
	column.add_child(village_view)
	host._add_label(column, "Neighboring families", 24, host.TEXT_SUSPECTED)
	for family in state.village.households.values():
		var content := _card(host, column)
		host._add_label(content, family.name, 22, host.TEXT_MAIN)
		host._add_label(content, "Ambition · " + family.ambitions[0], 17, host.TEXT_MUTED)
		var bond: Dictionary = family.relationships["landi"]
		var attitude := "Warm" if bond["trust"] >= 0.5 else ("Wary" if bond["trust"] - bond["resentment"] < 0.15 else "Reserved")
		host._add_label(content, "Relations · " + attitude, 17, host.TEXT_KNOWN)
		for property_id in family.property_ids:
			host._add_label(content, "Property · " + state.village.properties[property_id]["name"], 16, host.TEXT_MUTED)
		if not family.history.is_empty():
			host._add_label(content, family.history[-1]["description"], 16, host.TEXT_MUTED)
		var visit := Button.new()
		visit.text = "Plan visits to this family"
		content.add_child(visit)
		visit.pressed.connect(func():
			host.gameplay_target_id = family.id
			host.gameplay_activity_id = "visit"
			host.gameplay_result = "Plan visits to the " + family.name + "."
			host._open_person_activity("visit", family.id))


static func _card(host, parent: Node) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", host.Archive.card())
	parent.add_child(card)
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 6)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)
	return content
