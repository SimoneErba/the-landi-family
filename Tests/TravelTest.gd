extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const Clock = preload("res://Simulation/GameClock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 100000
	var person = state.people["Carlo"]
	person.interests["academic"] = 100.0
	person.interests["commercial"] = 100.0
	person.interests["practical"] = 100.0
	person.current_state["resentment"] = 0.0
	person.current_state["stress"] = 0.0
	return state

func _run() -> void:
	var state = _state()
	assert(state.travel.CITIES.size() == 11)
	assert(not state.travel.propose(state, state.head_id, "florence", "study")["ok"])
	assert(not state.travel.propose(state, "Carlo", "missing", "study")["ok"])
	state.people["Carlo"].age = 16
	assert(not state.travel.propose(state, "Carlo", "florence", "study")["ok"])
	state.people["Carlo"].age = 23
	state.economy.cash_cents = 0
	assert(not state.travel.propose(state, "Carlo", "florence", "study")["ok"])
	state.economy.cash_cents = 100000
	state.activities.propose(state, "Carlo", "study")
	assert(not state.travel.reason(state, "Carlo", "florence", "study").is_empty())
	state = _state()
	var person = state.people["Carlo"]
	person.interests["academic"] = 0.0
	person.values["independence"] = 0.0
	person.values["security"] = 1.0
	person.current_state["resentment"] = 1.0
	assert(not state.travel.propose(state, "Carlo", "florence", "study")["ok"])
	assert(state.travel.journeys.is_empty() and person.in_household and state.economy.cash_cents == 100000)
	state = _state()
	state.legacy.choose("populous", "discount")
	state.events.prepare_economy(state)
	var cost: int = state.travel.cost(state, "florence", "study")
	assert(cost == 5940)
	assert(state.travel.propose(state, "Carlo", "florence", "study")["ok"])
	assert(state.economy.cash_cents == 100000 - cost)
	assert(not state.people["Carlo"].in_household and "Carlo" not in state.household["members"])
	assert(state.economy.budget(state.people, state.household["members"])["residents"] == 6)
	assert(not State.Influence.unavailable_reason(state, "Carlo", "join").is_empty())
	assert(not state.travel.propose(state, "Carlo", "milan", "work")["ok"])
	var skill: float = state.people["Carlo"].skills["medicine"]
	state.advance_month()
	assert(state.travel.current("Carlo")["status"] == "staying")
	var saved: Dictionary = state.to_save_data()
	var restored = State.new()
	restored.restore_save_data(saved)
	assert(restored.to_save_data() == saved)
	for month in range(7):
		state.advance_month()
		restored.advance_month()
	assert(state.to_save_data() == restored.to_save_data())
	assert(state.travel.current("Carlo").is_empty() and state.people["Carlo"].in_household)
	assert(state.household["members"].count("Carlo") == 1)
	assert(state.people["Carlo"].skills["medicine"] == minf(100, skill + 15))
	assert(not state.notifications.is_empty())
	var clock = Clock.new()
	clock.state = state
	var path := "user://travel_test.save"
	assert(SaveGame.save_game(clock, path).is_empty())
	assert(SaveGame.load_game(clock, path).is_empty())
	assert(clock.state.to_save_data() == state.to_save_data())
	clock.free()
	DirAccess.remove_absolute(path)
	var data := {"state": state.to_save_data(), "clock": {"speed_level": 1, "month_progress": 0.0}}
	data["state"].erase("travel")
	assert(SaveGame._valid_save(data))
	data["state"]["travel"] = state.travel.to_save_data()
	data["state"]["travel"]["journeys"]["journey_1"]["city_id"] = "missing"
	assert(not SaveGame._valid_save(data))
	state = _state()
	state.travel.propose(state, "Carlo", "milan", "work")
	state.advance_month()
	person = state.people["Carlo"]
	person.values["family_loyalty"] = 0.0
	person.values["independence"] = 1.0
	person.learned_tendencies["need_for_autonomy"] = 1.0
	assert(not state.travel.recall(state, "journey_1")["ok"], "Relatives can refuse early return")
	state.advance_month()
	person.values["family_loyalty"] = 1.0
	person.values["independence"] = 0.0
	person.learned_tendencies["need_for_autonomy"] = 0.0
	assert(state.travel.recall(state, "journey_1")["ok"])
	var commerce: float = person.skills["commerce"]
	state.advance_month()
	state.advance_month()
	assert(person.in_household and person.skills["commerce"] == commerce)
	state = _state()
	state.travel.propose(state, "Carlo", "rome", "trade")
	for month in range(7):
		state.advance_month()
	assert(state.people["Carlo"].in_household)
	assert(state.events.transactions[-1]["amount_cents"] == 2000)
	state = _state()
	state.legacy.choose("wealth", "learning")
	state.travel.propose(state, "Carlo", "florence", "study")
	for month in range(7):
		state.advance_month()
	assert(state.travel.current("Carlo").is_empty())
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.economy.cash_cents = 100000
	screen.game_clock.state.people["Carlo"].interests["academic"] = 100.0
	screen._show_screen("Italy")
	await process_frame
	await process_frame
	var viewport := screen.content_overlay.find_child("ItalyMapViewport", true, false) as ScrollContainer
	assert(viewport != null)
	var map = viewport.get_child(0)
	assert(map.size.x >= 1400 and map.size.y >= 1600)
	assert(map.markers.size() == state.travel.CITIES.size())
	var coastlines := _coastline_polygons()
	for city_id in state.travel.CITIES:
		var by_sea: bool = map.SEA_ROUTES.has(city_id)
		var route: Array = map.SEA_ROUTES[city_id] if by_sea else map.ROUTES[city_id]
		assert(route.size() >= 4)
		if by_sea:
			assert(route[0] != Vector2(.37, .39))
			assert(route[-1].distance_to(state.travel.CITIES[city_id]["position"]) < .035)
			var rect: Rect2 = map._map_rect()
			for point in map._route_curve(city_id).get_baked_points():
				var normalized: Vector2 = (point - rect.position) / rect.size
				for polygon in coastlines:
					assert(not Geometry2D.is_point_in_polygon(normalized, polygon), "Boat routes must stay in the water")
		else:
			assert(route[0] == Vector2(.37, .39))
			assert(route[-1].is_equal_approx(state.travel.CITIES[city_id]["position"]))
	var choice: OptionButton = screen.content_overlay.find_child("TravelerChoice", true, false)
	assert(choice != null and choice.item_count > 0)
	for index in choice.item_count:
		assert(choice.get_item_icon(index) != null, "People choices include small portraits")
	assert(map.markers["milan"] is TextureRect)
	assert(map.markers["milan"].size == map.CITY_IMAGE_SIZE)
	var selected_art := screen.content_overlay.find_child("SelectedCityEngraving", true, false) as TextureRect
	assert(selected_art != null and selected_art.texture == map.markers["florence"].texture)
	viewport.scroll_vertical = 150
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	map.markers["milan"].gui_input.emit(click)
	await process_frame
	await process_frame
	await process_frame
	viewport = screen.content_overlay.find_child("ItalyMapViewport", true, false) as ScrollContainer
	assert(viewport.scroll_vertical == 150)
	assert(screen.travel_city_id == "milan")
	selected_art = screen.content_overlay.find_child("SelectedCityEngraving", true, false) as TextureRect
	assert(selected_art.texture == viewport.get_child(0).markers["milan"].texture)
	for button in screen.content_overlay.find_children("*", "Button", true, false):
		if button.text == "Propose this journey":
			button.pressed.emit()
			break
	assert(not screen.game_clock.state.travel.current("Carlo").is_empty())
	screen.free()
	print("PASS: cities, consent, affordability, absence, stages, return, rewards, recall, bonuses, saves and map actions")
	quit()

func _coastline_polygons() -> Array:
	# Read the original projected coastlines, rather than sampling atlas colors.
	var parser := XMLParser.new()
	assert(parser.open_buffer(FileAccess.get_file_as_string("res://Assets/Maps/italy.svg").to_utf8_buffer()) == OK)
	var number := RegEx.new()
	number.compile("[0-9]+(?:[.][0-9]+)?")
	var polygons: Array = []
	var land := false
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "g":
				land = parser.get_named_attribute_value_safe("fill") == "#d5c69f"
			elif land and parser.get_node_name() == "path":
				var coordinates := number.search_all(parser.get_named_attribute_value_safe("d"))
				var polygon := PackedVector2Array()
				for index in range(0, coordinates.size(), 2):
					polygon.append(Vector2(coordinates[index].get_string().to_float() / 700.0, coordinates[index + 1].get_string().to_float() / 800.0))
				polygons.append(polygon)
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "g":
			land = false
	assert(not polygons.is_empty())
	return polygons
