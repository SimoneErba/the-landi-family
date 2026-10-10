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
	return state

func _run() -> void:
	var state = _state()
	assert(state.village.households.size() == 5 and state.village.locations.size() == 8)
	assert(state.people.size() == 7, "Neighbors do not enter the family roster")
	assert(not state.activities.propose(state, "Giovanni", "visit", "missing")["ok"])
	var person = state.people["Carlo"]
	person.interests["practical"] = 0
	person.values["family_loyalty"] = 0
	person.current_state["resentment"] = 1.0
	assert(not state.activities.propose(state, "Carlo", "repair")["ok"], "A relative can refuse")
	assert(state.activities.plans.is_empty())
	assert(not state.activities.reason(state, "Carlo", "study").is_empty(), "Requests share a monthly limit")
	var result: Dictionary = state.activities.propose(state, "Giovanni", "repair")
	assert(result["ok"])
	var plan = state.activities.plans[result["plan_id"]]
	assert(not state.activities.propose(state, "Giovanni", "study")["ok"], "One commitment per person")
	assert(not state.careers.request_reason(state, state.people["Giovanni"], "train:secondary").is_empty())
	var opening: int = state.economy.cash_cents
	state.people["Giovanni"].life_state["illness"] = {"until_month": 10, "previous_health": "Well"}
	state.activities.advance_month(state)
	assert(plan.status == "interrupted" and plan.progress_months == 0 and state.economy.cash_cents == opening)
	state.people["Giovanni"].life_state["illness"] = {}
	state.economy.cash_cents = 0
	state.activities.advance_month(state)
	assert(plan.status == "interrupted" and plan.progress_months == 0)
	state.economy.cash_cents = opening
	state.legacy.choose("populous", "discount")
	state.events.prepare_economy(state)
	state.activities.advance_month(state)
	assert(plan.status == "active" and plan.progress_months == 1 and state.economy.cash_cents == opening - 450)
	var saved: Dictionary = state.to_save_data()
	var restored = State.new()
	restored.restore_save_data(saved)
	assert(restored.to_save_data() == saved)
	for month in range(3):
		state.advance_month()
		restored.advance_month()
	assert(state.to_save_data() == restored.to_save_data(), "Saved activities and neighbors continue identically")
	assert(plan.status == "completed" and state.household["condition"] == 95 and not state.notifications.is_empty())
	opening = state.economy.cash_cents
	state.activities.advance_month(state)
	assert(state.economy.cash_cents == opening, "Completed plans do not charge again")
	result = state.activities.propose(state, "Giovanni", "visit", "rossi")
	assert(result["ok"])
	for month in range(3):
		state.advance_month()
	assert(state.village.households["rossi"].relationships["landi"]["trust"] > 0.3)
	result = state.activities.propose(state, "Giovanni", "study")
	assert(result["ok"])
	state.activities.cancel(state, result["plan_id"])
	assert(state.activities.commitment("Giovanni") == null)
	result = state.activities.propose(state, "Giovanni", "study")
	state.household["members"].erase("Giovanni")
	state.activities.advance_month(state)
	assert(state.activities.plans[result["plan_id"]].status == "failed")
	state = _state()
	state.legacy.choose("influence", "learning")
	state.activities.propose(state, "Giovanni", "study")
	var literacy: float = state.people["Giovanni"].skills["literacy"]
	for month in range(5):
		state.advance_month()
	assert(state.activities.plans["activity_1"].status == "completed")
	assert(state.people["Giovanni"].skills["literacy"] == minf(100, literacy + 12))
	var clock = Clock.new()
	clock.state = state
	var path := "user://gameplay_layer_test.save"
	assert(SaveGame.save_game(clock, path).is_empty())
	assert(SaveGame.load_game(clock, path).is_empty())
	assert(clock.state.to_save_data() == state.to_save_data())
	DirAccess.remove_absolute(path)
	clock.free()
	var data := {"state": state.to_save_data(), "clock": {"speed_level": 1, "month_progress": 0.0}}
	data["state"].erase("activities")
	data["state"].erase("village")
	assert(SaveGame._valid_save(data), "Older saves get a village and empty plans")
	data["state"]["activities"] = state.activities.to_save_data()
	data["state"]["activities"]["plans"]["activity_1"]["accepted_participant_ids"] = ["missing"]
	assert(not SaveGame._valid_save(data), "Invalid references are rejected")
	state = _state()
	state.elapsed_months = 12
	var before: int = state.village.households["rossi"].cash_cents
	state.village.advance_month(state)
	var production := 0
	for row in state.village.business.reports.back()["rows"]:
		if row["owner_id"] == "rossi":
			production += row["net_cents"]
	assert(state.village.households["rossi"].cash_cents == before + 300 + production - 12000)
	assert(not state.village.households["rossi"].history.is_empty())
	state = _state()
	state.elapsed_months = 6
	person = state.people["Carlo"]
	person.interests["practical"] = 100
	person.values["family_loyalty"] = 1.0
	person.current_state["resentment"] = 0.0
	person.current_state["stress"] = 0.0
	person.learned_tendencies["need_for_autonomy"] = 0.0
	assert(state.activities.propose(state, "Carlo", "repair")["ok"])
	person.values["family_loyalty"] = 0.0
	person.values["independence"] = 1.0
	person.values["security"] = 0.0
	person.values["tradition"] = 0.0
	person.learned_tendencies["need_for_autonomy"] = 1.0
	person.relationships[state.head_id]["affection"] = 0.0
	state.last_requests["Carlo"] = -10
	State.DecisionSystem.advance_month(state, person)
	assert(person.decision_state["plan"]["action"] == "leave", "Activity commitments do not suppress independence")
	state.advance_month()
	state.advance_month()
	assert(not person.in_household and state.activities.plans["activity_1"].status == "failed")
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen._open_person_activity("study")
	await process_frame
	for button in screen.details_content.find_children("*", "Button", true, false):
		if button.text == "Begin activity":
			button.pressed.emit()
			break
	assert(screen.game_clock.state.activities.commitment("Giovanni") != null, "Project button starts an actual plan")
	screen._show_screen("Village")
	await process_frame
	var visit_buttons: Array = []
	for button in screen.content_overlay.find_children("*", "Button", true, false):
		if button.text == "Plan visits to this family":
			visit_buttons.append(button)
	visit_buttons[1].pressed.emit()
	assert(screen.details_popup.visible and screen.profile_section == "Activities" and screen.gameplay_target_id == "bianchi", "Village links preserve the selected family")
	screen.free()
	print("PASS: activity consent, commitments, illness and funding, costs, outcomes, cancellation, departure, learning, neighbors, save migration and live screens")
	quit()
