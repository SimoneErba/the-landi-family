extends RefCounted
const Map = preload("res://Scripts/ItalyMap.gd")

static func build(host) -> void:
	var state = host.game_clock.state
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_overlay.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	host._add_label(column, "Italy · cities and journeys", 32, host.TEXT_MAIN)
	host._add_label(column, "Select a city and propose a placement. Travelers leave the household until they return; their usual wages and food costs are excluded while away. Travel and accommodation are funded upfront.", 17, host.TEXT_MUTED)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	var map = Map.new()
	map.selected_city = host.travel_city_id
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(map)
	map.city_selected.connect(func(city_id):
		host.travel_city_id = city_id
		host.travel_result = ""
		host._show_screen("Italy"))
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 440
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 16)
	row.add_child(detail)
	var city: Dictionary = state.travel.CITIES[host.travel_city_id]
	host._add_label(detail, city["name"], 28, host.TEXT_SUSPECTED)
	host._add_label(detail, city["description"], 17, host.TEXT_MAIN)
	host._add_label(detail, "Study focus · " + str(city["skill"]).capitalize(), 16, host.TEXT_KNOWN)
	var people := OptionButton.new()
	var ids: Array = []
	for person in state.people.values():
		if person.alive and person.age >= 18 and person.id != state.head_id and person.id in state.household["members"]:
			people.add_item(person.name)
			ids.append(person.id)
	people.select(maxi(0, ids.find(host.travel_person_id)))
	people.custom_minimum_size.y = 44
	detail.add_child(people)
	var purposes := OptionButton.new()
	var purpose_ids: Array = state.travel.PURPOSES.keys()
	for key in purpose_ids:
		purposes.add_item(state.travel.PURPOSES[key]["name"])
	purposes.select(maxi(0, purpose_ids.find(host.travel_purpose_id)))
	purposes.custom_minimum_size.y = 44
	detail.add_child(purposes)
	var explanation: Label = host._add_label(detail, "", 17, host.TEXT_MAIN)
	var propose := Button.new()
	propose.text = "Propose this journey"
	propose.custom_minimum_size.y = 44
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
		host.game_clock.pause()
		var result: Dictionary = state.travel.propose(state, host.travel_person_id, host.travel_city_id, host.travel_purpose_id)
		host.travel_result = result["response"]
		host._refresh_time_controls())
	if not host.travel_result.is_empty():
		host._add_label(detail, host.travel_result, 18, host.TEXT_KNOWN)
	host._add_label(detail, "Journey times, fees and placement rewards are prototype values.", 14, host.TEXT_MUTED)
	host._add_label(column, "Family journeys", 24, host.TEXT_SUSPECTED)
	if state.travel.journeys.is_empty():
		host._add_label(column, "No journeys yet. Choose a city on the map to begin.", 17, host.TEXT_MUTED)
	for journey in state.travel.journeys.values():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
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
				host.game_clock.pause()
				var result: Dictionary = state.travel.recall(state, journey["id"])
				host.travel_result = result["response"]
				host._refresh_time_controls())
