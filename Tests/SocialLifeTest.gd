extends SceneTree
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")
const Starting = preload("res://Simulation/StartingFamily.gd")

func _initialize() -> void: call_deferred("_run")

func _clock():
	var clock = Clock.new()
	clock.state.initialize(Starting.create_people("child"))
	clock.state.events.enabled = false
	clock.state.succession.enabled = false
	for person in clock.state.people.values():
		person.current_state["resentment"] = 0.0
		person.current_state["stress"] = 0.0
		person.values["family_loyalty"] = 1.0
		person.learned_tendencies["need_for_autonomy"] = 0.0
	return clock

func _run() -> void:
	var clock = _clock()
	var state = clock.state
	assert(state.people.size() == 3 and state.people["Carlo"].parent_ids == ["Giovanni", "Maria"])
	assert(state.people["Giovanni"].spouse_id == "Maria" and state.people["Maria"].spouse_id == "Giovanni")
	# Passage of time alone cannot reveal an absent person's traits.
	state.household["members"].erase("Maria")
	for month in 12: state.advance_month()
	assert(state.people["Maria"].knowledge[state.head_id]["values"]["known"].is_empty())
	assert(not state.social.reason(state, "Giovanni", "Maria", "social").is_empty())
	state.household["members"].append("Maria")
	state.people["Maria"].in_household = true
	# Household familiarity creates suspicions gradually, not immediate certainty.
	for month in 8: state.advance_month()
	assert(not state.people["Maria"].knowledge[state.head_id]["values"]["suspected"].is_empty())
	assert(state.people["Maria"].knowledge[state.head_id]["values"]["known"].is_empty())
	# A child can socialize with a parent; household work requires adulthood.
	assert(not state.social.reason(state, "Carlo", "Giovanni", "work").is_empty())
	state.people["Carlo"].parent_ids = ["SomeoneElse"]
	assert(state.social.reason(state, "Carlo", "Maria", "social").contains("parent"))
	state.people["Carlo"].parent_ids = ["Giovanni", "Maria"]
	var result: Dictionary = state.social.propose(state, "Carlo", "Maria", "social")
	assert(result["accepted"])
	var id: String = result["activity_id"]
	for month in 3: state.advance_month()
	assert(state.social.plans[id]["status"] == "completed")
	var child = state.people["Carlo"]
	var mothers_view: Dictionary = child.knowledge["Maria"]
	assert(not mothers_view["temperament"]["known"].is_empty())
	var finding: String = mothers_view["temperament"]["known"][0]
	assert(finding not in child.knowledge["Giovanni"]["temperament"]["known"], "Another observer's discovery is not omniscient player knowledge")
	var reply: String = state.social.ask_about(state, "Maria", "Carlo")
	assert(reply.contains("Maria") and reply.contains("not yet confirmed"))
	assert(finding in child.knowledge["Giovanni"]["temperament"]["suspected"])
	assert(finding not in child.knowledge["Giovanni"]["temperament"]["known"])
	assert(state.social.ask_about(state, "Maria", "Carlo").contains("already asked"))
	assert(child.knowledge["Giovanni"]["evidence"].any(func(e): return e.contains("Maria")))
	# Direct shared experience can confirm an impression received from someone else.
	for month in 3: state.social.observe(state, "Carlo", "Giovanni", "social", 2.0)
	assert(finding in child.knowledge["Giovanni"]["temperament"]["known"])
	assert(finding not in child.knowledge["Giovanni"]["temperament"]["suspected"])
	# Mutual consent: one refusal starts no shared plan and reveals no private trait.
	state.advance_month()
	state.people["Maria"].current_state["resentment"] = 1.0
	state.people["Maria"].current_state["stress"] = 1.0
	state.people["Maria"].values["family_loyalty"] = 0.0
	state.people["Maria"].interests["social"] = 0.0
	state.people["Maria"].learned_tendencies["need_for_autonomy"] = 1.0
	var count: int = state.social.plans.size()
	assert(not state.social.propose(state, "Giovanni", "Maria", "social")["accepted"])
	assert(state.social.plans.size() == count)
	clock.free()
	# Reluctant agreement slows shared time and can turn into abandonment.
	clock = _clock()
	state = clock.state
	var reluctant = state.people["Maria"]
	reluctant.values["family_loyalty"] = 0.0
	reluctant.interests["social"] = 0.0
	reluctant.learned_tendencies["need_for_autonomy"] = 1.0
	reluctant.current_state["resentment"] = 0.1
	reluctant.current_state["stress"] = 0.2
	reluctant.relationships["Giovanni"] = {"trust": 0.4, "affection": 0.4}
	result = state.social.propose(state, "Giovanni", "Maria", "social")
	assert(result["accepted"] and result["action_response"] == "reluctant")
	id = result["activity_id"]
	state.advance_month()
	assert(state.social.plans[id]["months"] < 1.0)
	reluctant.current_state["resentment"] = 0.95
	state.advance_month()
	assert(state.social.plans[id]["status"] == "cancelled")
	clock.free()
	# Work progress, interruptions, departures, persistent observation and reports.
	clock = _clock()
	state = clock.state
	# Farm coworkers observe traits even without a player-arranged plan.
	state.people["Maria"].career_id = "farm_laborer"
	state.people["Maria"].monthly_income_cents = 2000
	for month in 4: state.advance_month()
	assert(not state.people["Maria"].knowledge["Giovanni"]["temperament"]["suspected"].is_empty())
	result = state.social.propose(state, "Giovanni", "Maria", "work")
	assert(result["accepted"])
	id = result["activity_id"]
	state.people["Maria"].life_state["illness"] = {"until_month": 50}
	state.advance_month()
	assert(state.social.plans[id]["status"] == "interrupted" and state.social.plans[id]["months"] == 0)
	state.people["Maria"].life_state.erase("illness")
	state.advance_month()
	assert(state.social.plans[id]["months"] == 1)
	var path := "user://social_life_test.save"
	assert(Save.save_game(clock, path).is_empty())
	var original: Dictionary = state.to_save_data()
	assert(Save.load_game(clock, path).is_empty())
	assert(clock.state.to_save_data() == original)
	state = clock.state
	state.household["members"].erase("Maria")
	state.advance_month()
	assert(state.social.plans[id]["status"] == "cancelled")
	var malformed: Dictionary = original["social"].duplicate(true)
	malformed["plans"][id]["participants"][1] = "missing"
	assert(not state.SocialLife.valid(malformed, state.people, state.elapsed_months))
	var bad_knowledge: Dictionary = original["people"]["Maria"]["knowledge"].duplicate(true)
	bad_knowledge["Giovanni"]["social_observations"].values()[0]["points"] = -1.0
	assert(not state.SocialLife.valid_knowledge(bad_knowledge))
	var legacy: Dictionary = original.duplicate(true)
	legacy.erase("social")
	state.restore_save_data(legacy)
	assert(state.social.plans.is_empty(), "Old saves acquire an empty shared-time system")
	DirAccess.remove_absolute(path)
	clock.free()
	# Native controls are reachable through the existing profile.
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	screen.starting_people = Starting.create_people("child")
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen._show_person("Maria")
	assert(screen.details_content.find_child("SharedTimeRequest", true, false) != null)
	assert(screen.details_content.find_child("AskForImpressions", true, false) != null)
	for frame in 5: await process_frame
	assert(screen.details_popup.get_global_rect().end.y <= root.size.y, "The expanded social controls fit the viewport")
	screen._show_person("Carlo")
	assert(screen.details_content.find_child("SharedCompanion", true, false) != null)
	var companion: OptionButton = screen.details_content.find_child("SharedCompanion", true, false)
	assert(companion.item_count == 2, "Both parents are available in the child's profile")
	screen.free()
	await process_frame
	print("PASS: wife and son, gradual familiarity, absence, shared social/work time, consent, observer privacy, sourced reports, confirmation, interruptions, saves and UI")
	quit()
