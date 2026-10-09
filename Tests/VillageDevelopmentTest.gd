extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 1000000
	return state

func _valid(state) -> bool:
	return SaveGame._valid_save({"state":state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}})

func _tick(state, count: int) -> void:
	for month in count:
		state.elapsed_months += 1
		state.month = state.elapsed_months % 12 + 1
		state.year = 1800 + state.elapsed_months / 12
		state.village.advance_month(state)

func _run() -> void:
	var state = _state()
	var dev = state.village.development
	assert(dev.parcels.size() == 40 and dev.buildings.size() == 18)
	assert(_valid(state))
	var initial: Dictionary = dev.view_at(0)
	var parcel_id: String = dev.best_parcel("house","landi")
	assert(not parcel_id.is_empty())
	var opening: int = state.economy.cash_cents
	dev.begin_construction(state, parcel_id, "house", "landi")
	assert(dev.projects.is_empty() and state.economy.cash_cents == opening, "Construction requires owned land")
	dev.buy_parcel(state, parcel_id)
	state.legacy.choose("populous","discount")
	state.economy.price_multiplier = .9
	opening = state.economy.cash_cents
	dev.begin_construction(state, parcel_id, "house", "landi")
	assert(state.economy.cash_cents == opening - 10800, "Construction uses the existing purchase discount once")
	assert(dev.buildings.size() == 18 and dev.projects.size() == 1)
	assert(_valid(state))
	var project_id: String = dev.projects.keys()[0]
	dev.begin_construction(state, parcel_id, "house", "landi")
	assert(dev.projects.size() == 1, "An active plot cannot be built twice")
	_tick(state,12)
	assert(dev.buildings.has(project_id) and dev.buildings[project_id]["parcel_id"] == parcel_id)
	assert(dev.view_at(0)["buildings"] == initial["buildings"], "Earlier maps never acquire future buildings")
	assert(_valid(state))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	assert(restored.to_save_data() == state.to_save_data())
	_tick(state,18)
	_tick(restored,18)
	assert(state.to_save_data() == restored.to_save_data(), "Save continuation is deterministic")
	assert(dev.buildings.size() > 18, "Neighbor investment creates real village growth")
	dev.renovate(state,project_id)
	_tick(state,6)
	assert(dev.buildings[project_id]["level"] == 2 and dev.buildings[project_id]["visual_variant"] == 1)
	assert(dev.transfer(state, project_id, "moretti"))
	assert(dev.buildings[project_id]["owner_id"] == "moretti")
	assert(dev.change_use(state, project_id, "workshop"))
	assert(dev.buildings[project_id]["type"] == "workshop")
	assert(dev.demolish(state, project_id))
	assert(dev.buildings[project_id]["status"] == "demolished" and dev.parcels[parcel_id]["building_id"].is_empty())
	assert(not dev.demolish(state,"home") and not dev.demolish(state,"church"))
	assert(_valid(state))
	var before_history: int = dev.history.size()
	var snapshot: Dictionary = dev.to_save_data()
	dev.view_at(12)
	assert(dev.to_save_data() == snapshot and dev.history.size() == before_history, "Replay never alters the live world")
	var invalid := {"state": state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}}
	invalid["state"]["village"]["development"]["buildings"]["church"]["parcel_id"] = "missing"
	assert(not SaveGame._valid_save(invalid))
	invalid = {"state": state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}}
	invalid["state"]["village"]["development"]["history"].clear()
	assert(not SaveGame._valid_save(invalid), "Truncated history cannot corrupt replay")
	invalid = {"state": state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}}
	invalid["state"]["village"].erase("development")
	assert(SaveGame._valid_save(invalid), "Static village saves migrate with a new history baseline")
	state = _state()
	dev = state.village.development
	state.year = 1890
	state.elapsed_months = 1080
	assert(not dev.adopt_infrastructure(state,"railway"), "A year alone cannot build infrastructure")
	dev.public_fund_cents = 180000
	assert(dev.adopt_infrastructure(state,"railway"))
	assert(dev.adopt_infrastructure(state,"paved_roads"))
	assert(dev.adopt_infrastructure(state,"electricity"))
	assert(not dev.adopt_infrastructure(state,"railway"))
	assert(dev.public_fund_cents == 0 and dev.projects.size() == 1)
	assert(_valid(state))
	state = _state()
	dev = state.village.development
	_tick(state,1200)
	assert(_valid(state), "A century of growth preserves all ownership and replay invariants")
	assert(dev.parcels.size() == 40 and dev.buildings.size() <= 40)
	assert(dev.view_at(0)["buildings"].size() == 18)
	assert(dev.view_at(600)["buildings"].size() <= dev.buildings.size())
	# Renderable persistent nodes and read-only inspector.
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen._show_screen("Village")
	await process_frame
	var view = screen.village_view
	assert(view.map.building_nodes.size() == 18)
	var church_node = view.map.building_nodes["church"]
	view.map.building_selected.emit("church")
	assert(view.selected_id == "church")
	view.refresh()
	assert(view.map.building_nodes["church"] == church_node, "Monthly refresh preserves existing scene nodes")
	var ui_state = screen.game_clock.state
	ui_state.economy.cash_cents = 100000
	var ui_plot: String = ui_state.village.development.best_parcel("house","landi")
	view.map.parcel_selected.emit(ui_plot)
	for button in view.inspector.find_children("*","Button",true,false):
		if button.text.begins_with("Buy land"):
			button.pressed.emit()
			break
	assert(ui_state.village.development.parcels[ui_plot]["owner_id"] == "landi", "Inspector purchase updates real ownership")
	for button in view.inspector.find_children("*","Button",true,false):
		if button.text.begins_with("Build house"):
			button.pressed.emit()
			break
	assert(ui_state.village.development.projects.size() == 1, "Inspector commissions an actual construction")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = view.map.size / 2
	view.map._gui_input(wheel)
	assert(view.map.zoom > 1.0)
	view.map.set_replay(0)
	view.map.building_selected.emit("home")
	for button in view.inspector.find_children("*","Button",true,false):
		assert(not button.text.begins_with("Renovate"), "Historical inspection cannot spend money")
	view.map.reset_view()
	assert(view.map.zoom == 1 and view.map.pan == Vector2.ZERO)
	screen.free()
	print("PASS: persistent parcels, costs, construction, renovation, ownership, conversion, demolition, replay, migration, deterministic saves, infrastructure and live village UI")
	quit()
