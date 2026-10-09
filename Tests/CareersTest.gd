extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var state = State.new()
	state.initialize(source)
	state.events.enabled = false
	assert(state.careers.jobs.size() == 32)
	assert(state.careers.programs.size() == 23)
	for job in state.careers.jobs.values():
		for skill in job["skills"]:
			assert(skill in State.Person.SKILLS)
		for ability in job["abilities"]:
			assert(ability in State.Person.ABILITIES)
		assert(job["interest"] in State.Person.INTERESTS)
	for program in state.careers.programs.values():
		assert(program["education_level"] in State.Person.EDUCATION_LEVELS)
		for skill in program["skills"]:
			assert(skill in State.Person.SKILLS)
	var anna = state.people["Anna"]
	assert(anna.education["level"] == "secondary")
	assert(not state.careers.job_assessment(anna, "architect")["eligible"])
	assert(state.careers.program_reason(anna, "architecture").is_empty())
	assert(state.careers.job_assessment(state.people["Pietro"], "carpenter")["eligible"])
	assert(not state.careers.job_assessment(state.people["Pietro"], "architect")["eligible"], "Trade expertise does not replace a degree")
	var view: Dictionary = anna.view_for(state.head_id)
	assert(view["career"]["abilities"]["reasoning"] == "Unknown")
	assert(view["career"]["abilities"]["verbal"] == "Strong")
	assert(view["career"]["skills"]["design"] == "Unknown")
	view["education"]["qualifications"].append("fake_degree")
	view["career"]["abilities"]["reasoning"] = 100
	assert("fake_degree" not in anna.education["qualifications"] and anna.abilities["reasoning"] == 82)
	assert(source["Anna"]["education"]["qualifications"].is_empty())
	assert(anna.cognitive_index() > 70 and anna.cognitive_index() <= 100)
	var bounds = State.Person.new("Bounds", {"abilities": {"reasoning": 200, "memory": -20}, "skills": {"craft": 500}, "interests": {"artistic": -1}, "education": {"level": "wrong"}}, 1800, 1, "Giovanni")
	assert(bounds.abilities["reasoning"] == 100 and bounds.abilities["memory"] == 0)
	assert(bounds.skills["craft"] == 100 and bounds.interests["artistic"] == 0)
	assert(bounds.education["level"] == "none")
	state.economy.cash_cents = 1000000
	var result: Dictionary = state.request("Anna", "train:architecture")
	assert(result["outcome"] == "accepted")
	assert(anna.education["study"]["program_id"] == "architecture")
	assert(anna.monthly_income_cents == 0)
	assert(state.request("Anna", "work:factory_worker")["outcome"] == "unavailable")
	var opening: int = state.economy.cash_cents
	state.advance_month()
	assert(state.economy.ledger[-1]["tuition_cents"] == 1800)
	assert(state.economy.cash_cents == opening + 28500 - 7000 - 1800)
	assert(anna.skills["design"] > 30 and anna.skills["medicine"] == 0)
	var months := 1
	while not anna.education["study"].is_empty() and months < 120:
		state.advance_month()
		months += 1
	assert(months < 120, "Training must complete")
	assert(anna.education["level"] == "university" and "architecture_degree" in anna.education["qualifications"])
	assert(anna.skills["design"] >= 65 and state.major_event)
	assert(anna.job == "Seeking work" and anna.monthly_income_cents == 0, "Graduation is not automatic employment")
	assert(anna.career_view_for("Giovanni")["skills"]["design"] == "Competent", "Graduation provides evidence of learned skills")
	assert(state.careers.job_assessment(anna, "architect")["eligible"])
	anna.temperament["extraversion"] = 1.0
	assert(state.careers.job_assessment(anna, "architect")["eligible"], "Extraversion is not a career gate")
	anna.abilities["reasoning"] = 25
	assert(state.careers.job_assessment(anna, "architect")["eligible"], "Cognitive ability is not a fixed exclusion")
	assert(state.request("Anna", "work:architect")["outcome"] == "accepted")
	assert(anna.job == "Architect" and anna.monthly_income_cents == 14000)
	var expected_income: int = state.economy.budget(state.people, state.household["members"])["income_cents"]
	state.advance_month()
	assert(state.economy.ledger[-1]["tuition_cents"] == 0 and state.economy.ledger[-1]["income_cents"] == expected_income)
	assert(state.request("Anna", "train:architecture")["outcome"] == "unavailable", "No repeat degree")

	var hesitant = State.new()
	hesitant.initialize(source)
	hesitant.events.enabled = false
	hesitant.people["Carlo"].interests["technical"] = 0
	hesitant.people["Carlo"].values["achievement"] = 0
	hesitant.people["Carlo"].current_state["resentment"] = 1
	assert(hesitant.request("Carlo", "train:engineering")["outcome"] == "refused")
	assert(hesitant.people["Carlo"].education["study"].is_empty())
	assert(hesitant.people["Carlo"].monthly_income_cents == 7000)

	var paused = State.new()
	paused.initialize(source)
	paused.events.enabled = false
	paused.economy.cash_cents = 100000
	assert(paused.request("Carlo", "train:engineering")["outcome"] != "refused")
	assert(paused.people["Carlo"].monthly_income_cents == 0, "Study has an opportunity cost")
	for person in paused.people.values():
		person.monthly_income_cents = 0
	paused.economy.cash_cents = 7000
	paused.advance_month()
	assert(paused.economy.ledger[-1]["tuition_cents"] == 0)
	assert(paused.people["Carlo"].education["study"]["progress"] == 0)
	paused.economy.cash_cents = 100000
	paused.advance_month()
	assert(paused.people["Carlo"].education["study"]["progress"] > 0, "Funding restores progress")
	var progress: float = paused.people["Carlo"].education["study"]["progress"]
	paused.household["members"].erase("Carlo")
	paused.advance_month()
	assert(paused.people["Carlo"].education["study"]["progress"] == progress and paused.economy.ledger[-1]["tuition_cents"] == 0)
	paused.people["Carlo"].alive = false
	paused.advance_month()
	assert(paused.people["Carlo"].education["study"]["progress"] == progress)

	var children = State.new()
	children.initialize({"Giovanni": {"age": 50}, "Child": {"age": 12, "parent_ids": ["Giovanni"]}, "Niece": {"age": 12, "parent_ids": ["Pietro"]}})
	children.events.enabled = false
	assert(children.Influence.unavailable_reason(children, "Child", "train:primary").is_empty())
	assert("parent" in children.Influence.unavailable_reason(children, "Niece", "train:primary"))
	assert(children.request("Child", "work:factory_worker")["outcome"] == "unavailable")

	var pace = State.new()
	pace.initialize({"Giovanni": {"age": 50}, "Slow": {"age": 25}, "Fast": {"age": 25}})
	pace.events.enabled = false
	pace.economy.cash_cents = 1000000
	for key in ["Slow", "Fast"]:
		pace.careers.apply_request(pace.people[key], "train:primary")
	pace.people["Slow"].abilities["learning_speed"] = 10
	pace.people["Fast"].abilities["learning_speed"] = 90
	pace.advance_month()
	assert(pace.people["Fast"].education["study"]["progress"] > pace.people["Slow"].education["study"]["progress"])
	pace.people["Slow"].temperament["conscientiousness"] = 1
	assert(pace.people["Slow"].education["study"]["progress"] > 0, "Slow learners still progress")
	var clock = Clock.new()
	clock.state.initialize(source)
	clock.state.events.enabled = false
	clock.state.economy.cash_cents = 100000
	clock.state.careers.apply_request(clock.state.people["Anna"], "train:architecture")
	clock.state.people["Anna"].education["study"]["progress"] = 47.99
	clock.play()
	clock.advance_time(clock.seconds_per_month() * 4)
	assert(not clock.is_playing and clock.state.elapsed_months == 1, "Graduation interrupts time catch-up")
	clock.free()

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	screen._show_careers("Anna")
	assert(screen.careers_popup.visible and not screen.game_clock.is_playing)
	assert(screen.careers_content.get_child(0).get_child(0).text.begins_with("Anna"))
	screen._make_request("Anna", "train:architecture")
	assert("Accepted" in screen.conversation_result and not screen.careers_popup.visible)
	screen._show_screen("Finances")
	assert(screen.game_clock.state.economy.budget(screen.people, screen.game_clock.state.household["members"])["tuition_cents"] == 1800)
	screen.free()
	print("PASS: career catalog, private abilities, qualifications, consent, funded study, progress, graduation, employment, guardian authority, and career UI")
	quit()
