extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")


func _initialize() -> void:
	call_deferred("_run")


func _profile(overrides: Dictionary = {}) -> Dictionary:
	var profile := {"age": 25, "psychology": {"values": {}, "learned_tendencies": {}, "temperament": {}}, "goals": []}
	for key in State.Person.VALUES:
		profile["psychology"]["values"][key] = 0.0
	for key in State.Person.TENDENCIES:
		profile["psychology"]["learned_tendencies"][key] = 0.0
	profile.merge(overrides, true)
	return profile


func _state(profile: Dictionary):
	var state = State.new()
	state.initialize({"Giovanni": _profile(), "Adult": profile})
	state.events.enabled = false
	state.economy.cash_cents = 100000
	return state


func _advance(state, months: int) -> void:
	for index in range(months):
		state.advance_month()


func _has_label(node: Node, fragment: String) -> bool:
	if node is Label and fragment in node.text:
		return true
	for child_node in node.get_children():
		if _has_label(child_node, fragment):
			return true
	return false


func _run() -> void:
	var independent := _profile({"monthly_income_cents": 5000})
	independent["psychology"]["values"]["independence"] = 1.0
	independent["psychology"]["learned_tendencies"]["need_for_autonomy"] = 1.0
	var state = _state(independent)
	var adult = state.people["Adult"]
	assert(not adult.goals.is_empty(), "Values generate personal goals")
	assert(not adult.view_for("Giovanni").has("goals"), "Private goals remain hidden")
	assert(adult.view_for("Giovanni")["expressed_goals"].is_empty())
	var response: String = adult.converse("Giovanni", 0, state.date_text())
	assert("home of my own" in response and adult.view_for("Giovanni")["expressed_goals"].size() == 1)
	var view: Dictionary = adult.view_for("Giovanni")
	view["expressed_goals"].clear()
	assert(adult.view_for("Giovanni")["expressed_goals"].size() == 1)
	_advance(state, 6)
	assert(adult.in_household and adult.decision_state["plan"]["action"] == "leave")
	assert(state.major_event and "plans" in adult.view_for("Giovanni")["summary"])
	state.advance_month()
	assert(adult.in_household, "The player has time to intervene")
	state.advance_month()
	assert(not adult.in_household and "Adult" not in state.household["members"])
	assert(state.economy.ledger[-1]["residents"] == 2, "Decisions follow the completed month's settlement")
	state.advance_month()
	assert(state.economy.ledger[-1]["residents"] == 1 and state.economy.ledger[-1]["income_cents"] == 0)
	assert(adult.goals[0]["status"] == "completed")
	assert(state.people["Giovanni"].decision_state.is_empty(), "The player's head never acts autonomously")

	var reconsider = _state(independent)
	_advance(reconsider, 6)
	reconsider.people["Adult"].monthly_income_cents = 0
	reconsider.advance_month()
	assert(reconsider.people["Adult"].in_household and reconsider.people["Adult"].decision_state["plan"].is_empty(), "Plans recheck affordability")

	var loyal := independent.duplicate(true)
	loyal["psychology"]["values"]["independence"] = 0.75
	loyal["psychology"]["values"]["family_loyalty"] = 0.9
	loyal["psychology"]["values"]["security"] = 0.8
	loyal["psychology"]["learned_tendencies"]["need_for_autonomy"] = 0.8
	loyal["relationships"] = {"Giovanni": {"affection": 1.0, "trust": 1.0, "respect": 1.0}}
	var promise = _state(loyal)
	promise.people["Adult"].decision_state["plan"] = {"action": "leave", "description": "move out", "due_month": 2}
	var result: Dictionary = promise.request("Adult", "stay")
	assert(result["outcome"] == "accepted")
	assert(promise.people["Adult"].decision_state["plan"].is_empty())
	promise.people["Adult"].values["family_loyalty"] = 0.0
	promise.people["Adult"].values["security"] = 0.0
	_advance(promise, 11)
	assert(promise.people["Adult"].in_household and promise.people["Adult"].decision_state["plan"].is_empty())
	_advance(promise, 3)
	assert(not promise.people["Adult"].in_household, "An agreement delays rather than erases their own goals")

	var worker := _profile({"skills": {"technical": 20}})
	worker["psychology"]["values"]["wealth"] = 1.0
	var employment = _state(worker)
	_advance(employment, 8)
	assert(employment.people["Adult"].career_id == "factory_worker", "Eligible work is found without a player request")
	assert(employment.people["Adult"].monthly_income_cents == 4500)
	assert(employment.last_requests.is_empty(), "Autonomous decisions do not masquerade as requests")
	assert(employment.people["Adult"].memories[-1]["kind"] == "decision")

	var artist := _profile({"career_id": "shop_assistant", "career_access": ["publisher", "capital", "suppliers"], "monthly_income_cents": 7000, "education": {"level": "primary"}, "skills": {"literacy": 75, "art": 40, "commerce": 55, "persuasion": 40, "mathematics": 40}, "interests": {"artistic": 100, "commercial": 0, "social": 0, "practical": 0, "academic": 0, "technical": 0}})
	artist["psychology"]["values"]["achievement"] = 1.0
	artist["goals"] = [{"kind": "career", "description": "Find creative work", "status": "active"}]
	var creative = _state(artist)
	_advance(creative, 8)
	assert(creative.people["Adult"].career_id == "writer", "An achievement-focused person can choose meaningful lower-paid work")
	var earner := artist.duplicate(true)
	earner["psychology"]["values"]["achievement"] = 0.0
	earner["psychology"]["values"]["wealth"] = 1.0
	earner["interests"]["commercial"] = 100
	earner["interests"]["artistic"] = 0
	var commercial = _state(earner)
	_advance(commercial, 8)
	assert(commercial.people["Adult"].career_id == "merchant", "Different values and interests produce different decisions")

	var scholar := _profile({"interests": {"academic": 100}})
	scholar["psychology"]["values"]["achievement"] = 1.0
	var education = _state(scholar)
	_advance(education, 8)
	assert(education.people["Adult"].decision_state["plan"]["action"].begins_with("funding:"))
	assert(education.people["Adult"].education["study"].is_empty(), "New study needs agreement on the household purse")
	var proposed: String = education.people["Adult"].decision_state["plan"]["action"].replace("funding:", "train:")
	assert(education.request("Adult", proposed)["outcome"] == "accepted")
	assert(not education.people["Adult"].education["study"].is_empty())

	var child := independent.duplicate(true)
	child["age"] = 12
	child["skills"] = {"technical": 20}
	var children = _state(child)
	_advance(children, 18)
	assert(children.people["Adult"].in_household and children.people["Adult"].career_id.is_empty(), "Children cannot autonomously leave or take adult work")
	var deceased = _state(worker)
	deceased.people["Adult"].alive = false
	_advance(deceased, 18)
	assert(deceased.people["Adult"].decision_state.is_empty() and deceased.people["Adult"].memories.is_empty())

	var support := _profile({"relationships": {"Giovanni": {"affection": 1.0}}})
	support["psychology"]["values"]["family_loyalty"] = 1.0
	var caring = _state(support)
	caring.people["Giovanni"].current_state["stress"] = 0.9
	_advance(caring, 6)
	assert(caring.people["Adult"].memories[-1]["description"].contains("help"))
	assert(caring.people["Giovanni"].current_state["stress"] < 0.84, "Support has a psychological consequence")
	assert(caring.people["Adult"].current_state["stress"] > 0.14, "Helping carries a burden")

	var romance := _profile()
	romance["psychology"]["values"]["romance"] = 1.0
	var courting = _state(romance)
	_advance(courting, 8)
	assert(courting.people["Adult"].goals[0].get("pursuit_started", false))
	assert(courting.people["Adult"].spouse_id.is_empty(), "Pursuit does not manufacture a spouse")

	var clock = Clock.new()
	clock.state = _state(independent)
	clock.state.elapsed_months = 5
	clock.play()
	clock.advance_time(clock.seconds_per_month() * 5)
	assert(not clock.is_playing and clock.state.elapsed_months == 6, "Announced plans interrupt time catch-up")
	var path := "user://autonomy_test.save"
	assert(Save.save_game(clock, path).is_empty())
	var other = Clock.new()
	assert(Save.load_game(other, path).is_empty())
	assert(other.state.people["Adult"].decision_state == clock.state.people["Adult"].decision_state)
	_advance(clock.state, 3)
	_advance(other.state, 3)
	assert(clock.state.to_save_data() == other.state.to_save_data(), "Plans resume deterministically after loading")
	var legacy_file := FileAccess.open(path, FileAccess.WRITE)
	var legacy: Dictionary = {"format": "TheHouse", "version": 1, "state": clock.state.to_save_data(), "clock": {"speed_level": 3, "month_progress": 0.0}}
	for saved_person in legacy["state"]["people"].values():
		saved_person.erase("decision_state")
	legacy_file.store_var(legacy, false)
	legacy_file.close()
	assert(Save.load_game(other, path).is_empty(), "Existing version 1 saves remain supported")
	assert(other.state.people["Adult"].decision_state.is_empty())
	DirAccess.remove_absolute(path)
	clock.free()
	other.free()

	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var family = State.new()
	family.initialize(source)
	family.events.enabled = false
	_advance(family, 120)
	assert(not family.people["Carlo"].in_household, "The initial family's independent son can actually leave")
	for person in family.people.values():
		assert(person.in_household == (person.id in family.household["members"]))
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	_advance(screen.game_clock.state, 6)
	screen._show_person("Anna")
	assert(_has_label(screen.details_content, "Waiting for agreement on education funding."), "Education plans appear in person details")
	var carlo = screen.people["Carlo"]
	carlo.decision_state["plan"] = {"action": "leave", "description": "move out", "due_month": 8}
	screen._show_person("Carlo")
	assert(_has_label(screen.details_content, "Preparing to act within 2 months."), "Departure notice is visible")
	screen.free()
	print("PASS: values, personal goals, private knowledge, autonomous work and moves, notice, reconsideration, promises, funding requests, support, minors, mortality guards, romance, clock pauses, saves, and ten-year simulation")
	quit()
