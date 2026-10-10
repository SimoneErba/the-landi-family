extends RefCounted
## Unrelated people generated through the normal founder/arrival portrait path.
const Portrait = preload("res://Scripts/PersonPortrait.gd")

static func start(host) -> void:
	var state = host.game_clock.state
	host.game_clock.pause()
	if not state.people.has("PortraitStranger001"):
		var source := {"age": 23, "parent_ids": [], "spouse_id": "", "relationship": "Stranger", "in_household": false, "job": "No paid work", "monthly_income_cents": 0, "education": {"level": "secondary"}}
		for index in range(100):
			var stranger_source: Dictionary = source.duplicate(true)
			var person_id := "PortraitStranger%03d" % (index + 1)
			stranger_source["name"] = "Stranger %03d" % (index + 1)
			stranger_source["branch_id"] = person_id
			stranger_source["portrait"] = {"appearance": {"presentation": "masculine" if index % 2 == 0 else "feminine"}}
			# Empty parent links use ordinary founder generation, without inheritance.
			state.add_person(person_id, stranger_source)
		state.household["capacity"] = state.household["members"].size()
		state.economy.cash_cents = 10000000
		state.events.enabled = false
		host._start_family_story("populous", "fertility")
		var navigation: VBoxContainer = host.get_node("Navigation").get_child(0).get_child(0)
		host._add_navigation_button(navigation, "Portraits", "Portraits")
		navigation.move_child(navigation.get_child(navigation.get_child_count() - 1), 4)
	host._show_screen("Portraits")

static func build(host) -> void:
	var column := VBoxContainer.new()
	host.content_overlay.add_child(column)
	host._add_label(column, "100 strangers", 26, host.TEXT_MAIN)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "StrangerPortraitGrid"
	grid.columns = maxi(1, int((host.size.x - host.NAV_WIDTH - 48) / 150))
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	var ids := []
	for index in range(100): ids.append("PortraitStranger%03d" % (index + 1))
	for id in ids:
		if not host.people.has(id): continue
		var person = host.people[id]
		var card := PanelContainer.new()
		card.name = "StrangerPortrait_" + id
		card.add_theme_stylebox_override("panel", host.Archive.card())
		grid.add_child(card)
		var body := VBoxContainer.new()
		card.add_child(body)
		var face := Portrait.new()
		face.custom_minimum_size = Vector2(132, 132)
		face.show_person(person)
		body.add_child(face)
		var label: Label = host._add_label(body, person.name, 14, host.TEXT_MAIN)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		host._ignore_child_mouse(card)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				host._show_person(id))
