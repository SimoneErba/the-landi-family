extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	return state

func _run() -> void:
	var state = _state()
	assert(not state.legacy.choose("invalid", "learning"))
	assert(state.legacy.choose("populous", "fertility"))
	assert(not state.legacy.choose("wealth", "discount"))
	assert(state.legacy.fertility_multiplier() == 1.25)
	while state.people.size() < 100:
		state.add_person("Relative%d" % state.people.size(), {"in_household": false})
	state.people["Carlo"].alive = false
	state.legacy.evaluate(state)
	assert(not state.legacy.completed, "Only living relatives count")
	state.people["Carlo"].alive = true
	state.legacy.evaluate(state)
	assert(state.legacy.completed and state.major_event)
	var count: int = state.chronicle.size()
	state.legacy.evaluate(state)
	assert(state.chronicle.size() == count, "Completion is recorded once")
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	assert(restored.legacy.to_save_data() == state.legacy.to_save_data())
	var legacy_save := {"state": state.to_save_data(), "clock": {"speed_level": 1, "month_progress": 0.0}}
	legacy_save["state"].erase("legacy")
	assert(SaveGame._valid_save(legacy_save), "Existing saves remain loadable")
	legacy_save["state"]["legacy"]["bonus_id"] = "invalid"
	assert(not SaveGame._valid_save(legacy_save))
	state = _state()
	state.legacy.choose("wealth", "discount")
	state.events.prepare_economy(state)
	assert(state.economy.food_per_person_cents() == 900)
	state.people["Carlo"].education["study"] = {"monthly_cost_cents": 1000}
	assert(state.economy.budget(state.people, state.household["members"])["planned_tuition_cents"] == 900)
	state.events._cash(state, -1000, "Purchase")
	assert(state.economy.cash_cents == 9100)
	state.events._effects(state, {"title": "Robbery", "person_id": ""}, {"cash_loss": 1000})
	assert(state.economy.cash_cents == 8100, "Discounts do not reduce robbery losses")
	state.economy.cash_cents = ceili(state.legacy.WEALTH_TARGET)
	for currency in ["tuscan_lira", "tuscan_fiorino", "italian_lira"]:
		state.economy.currency = currency
		assert(state.legacy.progress(state)["value"] >= state.legacy.progress(state)["target"])
	state.legacy.evaluate(state)
	assert(state.legacy.completed)
	var normal = _state()
	var learner = _state()
	learner.legacy.choose("influence", "learning")
	for sample in [normal, learner]:
		sample.careers.apply_request(sample.people["Carlo"], "train:secondary")
		sample.economy.cash_cents = 100000
		sample.advance_month()
	assert(is_equal_approx(learner.people["Carlo"].education["study"]["progress"], normal.people["Carlo"].education["study"]["progress"] * 1.25))
	var member = learner.people["Carlo"]
	member.career_id = "manager"
	member.skills["leadership"] = 50
	member.skills["persuasion"] = 49
	learner.legacy.evaluate(learner)
	assert(not learner.legacy.completed)
	member.skills["persuasion"] = 50
	learner.legacy.evaluate(learner)
	assert(not learner.legacy.completed, "One influential relative is insufficient")
	for index in range(8):
		var relative = learner.add_person("Leader%d" % index, {"in_household": false})
		relative.career_id = "lawyer"
		relative.skills["leadership"] = 50
		relative.skills["persuasion"] = 50
	learner.legacy.evaluate(learner)
	assert(learner.legacy.progress(learner)["value"] == 9)
	assert(not learner.legacy.completed, "Nine influential relatives are insufficient")
	var tenth = learner.add_person("Leader9", {"in_household": false})
	tenth.career_id = "doctor"
	tenth.skills["leadership"] = 50
	tenth.skills["persuasion"] = 50
	tenth.alive = false
	learner.legacy.evaluate(learner)
	assert(not learner.legacy.completed, "Deceased relatives do not count")
	tenth.alive = true
	learner.legacy.evaluate(learner)
	assert(learner.legacy.completed)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	assert(screen.focus_overlay.visible and screen.page.visible, "New games show a mandatory popup over the family")
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	screen._unhandled_key_input(escape)
	assert(screen.focus_overlay.visible, "Escape cannot dismiss the focus popup")
	assert(not screen._start_family_story("invalid", "fertility"))
	assert(screen.focus_overlay.visible, "Invalid choices do not dismiss the popup")
	screen._play_game()
	assert(not screen.game_clock.is_playing, "Choose an ambition before playing")
	var objectives = screen.focus_overlay.find_child("ObjectiveCards", true, false)
	var perks = screen.focus_overlay.find_child("PerkCards", true, false)
	assert(objectives.get_child_count() == 3 and perks.get_child_count() == 3)
	var begin = screen.focus_overlay.find_child("BeginFamilyStory", true, false)
	assert(begin.disabled)
	objectives.get_child(2).find_children("*", "Button", true, false)[0].pressed.emit()
	assert(begin.disabled, "Both a goal and a perk must be chosen")
	perks.get_child(0).find_children("*", "Button", true, false)[0].pressed.emit()
	assert(not begin.disabled)
	begin.pressed.emit()
	assert(screen.game_clock.state.legacy.objective_id == "influence")
	assert(screen.game_clock.state.legacy.bonus_id == "fertility")
	assert(not screen.focus_overlay.visible)
	screen._show_screen("House")
	screen._show_screen("People")
	for width in [1920, 2560]:
		screen.size = Vector2(width, 1080)
		screen._update_page_bounds()
		await process_frame
		await process_frame
		assert(is_equal_approx(screen.family_frame.size.x, screen.content_overlay.size.x))
		var menu: Button = screen.top_bar.get_node("Frame/Header/ClockModule/TimeControls/MenuButton")
		assert(is_equal_approx(menu.global_position.y, screen.speed_buttons[0].global_position.y))
		assert(is_equal_approx(menu.size.y, screen.speed_buttons[0].size.y))
	screen._show_screen("Village")
	var village_maps: Array = screen.content_overlay.find_children("", "Control", true, false)
	var village_map = null
	for candidate in village_maps:
		if candidate.get_script() == load("res://Scripts/VillageMap.gd"):
			village_map = candidate
	assert(village_map != null and village_map.buttons.size() == 18)
	assert(village_map.map_texture != null)
	village_map.buttons["school"].pressed.emit()
	assert(screen.village_view.selected_id == "school")
	for button in screen.village_view.inspector.find_children("*", "Button", true, false):
		if button.text == "Plan an activity here":
			button.pressed.emit()
			break
	assert(screen.details_popup.visible and screen.profile_expanded and screen.profile_section == "Activities" and screen.gameplay_activity_id == "study")
	screen._show_screen("Italy")
	var italy_map = null
	for candidate in screen.content_overlay.find_children("", "Control", true, false):
		if candidate.get_script() == load("res://Scripts/ItalyMap.gd"):
			italy_map = candidate
	assert(italy_map != null and italy_map.markers.size() == 11)
	assert(italy_map.map_texture != null)
	italy_map.size = Vector2(900, 620)
	assert(is_equal_approx(italy_map._map_rect().size.x / italy_map._map_rect().size.y, 700.0 / 800.0))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	italy_map.markers["rome"].gui_input.emit(click)
	assert(screen.travel_city_id == "rome")
	screen._show_screen("Family Tree")
	var tree = screen.content_overlay.find_child("FamilyTreeDiagram", true, false)
	assert(tree.positions.size() == screen.people.size())
	assert(tree.positions["Carlo"].y > tree.positions["Giovanni"].y)
	assert(tree.positions["Giovanni"].y == tree.positions["Maria"].y)
	assert(tree.couples.size() == 2 and tree.descent.size() == 3)
	tree.get_node("TreePerson_Carlo").pressed.emit()
	assert(screen.details_popup.visible and screen.selected_person_id == "Carlo")
	screen.free()
	print("PASS: objectives, living relatives, currency equivalence, completion, discounts, learning, saves and responsive UI")
	quit()

