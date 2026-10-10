extends RefCounted
const Map = preload("res://Scripts/ItalyMap.gd")

static func build(host) -> void:
	var state = host.game_clock.state
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_overlay.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	host._add_label(column, "Italy · cities and journeys", 32, host.TEXT_MAIN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var map_scroll := ScrollContainer.new()
	map_scroll.name = "ItalyMapViewport"
	map_scroll.tooltip_text = "Scroll to explore · drag to pan · select a city"
	map_scroll.custom_minimum_size = Vector2(560, 520)
	map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	row.add_child(map_scroll)
	var map = Map.new()
	map.selected_city = host.travel_city_id
	map_scroll.add_child(map)
	map.city_selected.connect(func(city_id):
		host.travel_city_id = city_id
		host.travel_result = ""
		var map_position := Vector2(map_scroll.scroll_horizontal, map_scroll.scroll_vertical)
		host._show_screen("Italy")
		await host.get_tree().process_frame
		var new_scroll := host.content_overlay.find_child("ItalyMapViewport", true, false) as ScrollContainer
		if new_scroll != null:
			new_scroll.set_deferred("scroll_horizontal", int(map_position.x))
			new_scroll.set_deferred("scroll_vertical", int(map_position.y)))
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 320
	detail.size_flags_horizontal = Control.SIZE_FILL
	detail.add_theme_constant_override("separation", 8)
	row.add_child(detail)
	var city: Dictionary = state.travel.CITIES[host.travel_city_id]
	host._add_label(detail, city["name"], 28, host.TEXT_SUSPECTED)
	var city_engraving := TextureRect.new()
	city_engraving.name = "SelectedCityEngraving"
	city_engraving.texture = Map.city_texture(host.travel_city_id)
	city_engraving.custom_minimum_size = Vector2(0, 110)
	city_engraving.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	city_engraving.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	city_engraving.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(city_engraving)
	host._add_label(detail, city["description"], 17, host.TEXT_MAIN)
	host._add_label(detail, "Study focus · " + str(city["skill"]).capitalize(), 16, host.TEXT_KNOWN)
	var people := OptionButton.new()
	people.name = "TravelerChoice"
	people.add_theme_constant_override("icon_max_width", 32)
	var ids: Array = []
	for person in state.people.values():
		if person.alive and person.age >= 18 and person.id != state.head_id and person.id in state.household["members"]:
			host._add_person_choice(people, person)
			ids.append(person.id)
	people.select(maxi(0, ids.find(host.travel_person_id)))
	people.custom_minimum_size.y = 28
	detail.add_child(people)
	var purposes := OptionButton.new()
	var purpose_ids: Array = state.travel.PURPOSES.keys()
	for key in purpose_ids:
		purposes.add_item(state.travel.PURPOSES[key]["name"])
	purposes.select(maxi(0, purpose_ids.find(host.travel_purpose_id)))
	purposes.custom_minimum_size.y = 28
	detail.add_child(purposes)
	var explanation: Label = host._add_label(detail, "", 17, host.TEXT_MAIN)
	var propose := Button.new()
	propose.text = "Propose this journey"
	propose.custom_minimum_size.y = 28
	detail.add_child(propose)
	var refresh := func(_index = 0):
		host.travel_purpose_id = purpose_ids[purposes.selected]
		if not ids.is_empty():
			host.travel_person_id = ids[people.selected]
		var purpose: Dictionary = state.travel.PURPOSES[host.travel_purpose_id]
		var reason: String = "No adult relative is available at home." if ids.is_empty() else state.travel.reason(state, host.travel_person_id, host.travel_city_id, host.travel_purpose_id)
		var description: String = purpose["description"].replace("20 Tuscan lire", state.economy.money(2000)).replace("60 Tuscan lire", state.economy.money(6000))
		var travel_time: String = "%d month%s" % [city["months"], "" if city["months"] == 1 else "s"]
		explanation.text = "%s\n\n%s each way · %d months at destination.\nTotal upfront: %s. Covers both fares and the full stay. No refund for early returns.\n\n%s" % [description, travel_time, purpose["months"], state.economy.money(state.travel.cost(state, host.travel_city_id, host.travel_purpose_id)), reason]
		propose.disabled = not reason.is_empty()
	refresh.call()
	people.item_selected.connect(refresh)
	purposes.item_selected.connect(refresh)
	propose.pressed.connect(func():
		var result: Dictionary = state.travel.propose(state, host.travel_person_id, host.travel_city_id, host.travel_purpose_id)
		host.Reaction.remember(host, result, "", "travel")
		host._refresh_time_controls())
	host.Reaction.build(host, detail, "", "travel")
	host._add_label(column, "Family journeys", 24, host.TEXT_SUSPECTED)
	if state.travel.journeys.is_empty():
		host._add_label(column, "No active journeys.", 17, host.TEXT_MUTED)
	for journey in state.travel.journeys.values():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		column.add_child(box)
		var person = state.people[journey["person_id"]]
		host._add_label(box, person.name + " · " + state.travel.CITIES[journey["city_id"]]["name"] + " · " + state.travel.PURPOSES[journey["purpose_id"]]["name"], 21, host.TEXT_MAIN)
		var status: String = journey["status"].capitalize()
		if journey["status"] == "staying":
			status += " · %.1f / %d months" % [journey["progress"], state.travel.PURPOSES[journey["purpose_id"]]["months"]]
		elif journey["status"] in ["outbound", "returning"]:
			status += " · %d months remaining" % journey["remaining_months"]
		host._add_label(box, status, 17, host.TEXT_MUTED)
		if not journey.get("interruption_reason","").is_empty():
			host._add_label(box,journey["interruption_reason"],16,host.TEXT_SUSPECTED)
		if not journey["outcome"].is_empty():
			host._add_label(box, journey["outcome"], 17, host.TEXT_KNOWN)
		if journey["status"] in ["outbound", "staying"]:
			var recall := Button.new()
			recall.text = "Request early return"
			box.add_child(recall)
			recall.pressed.connect(func():
				var result: Dictionary = state.travel.recall(state, journey["id"])
				host.Reaction.remember(host, result, "", "travel")
				host._refresh_time_controls())
