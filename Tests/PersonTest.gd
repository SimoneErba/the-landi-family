extends SceneTree

const State = preload("res://Simulation/GameState.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var state = State.new()
	state.initialize(source)
	state.events.enabled = false
	assert(state.people["Carlo"].age == 23)
	assert(state.people["Carlo"].parent_ids == ["Giovanni", "Maria"])
	assert(state.people["Giovanni"].spouse_id == "Maria")
	assert(state.people["Carlo"].temperament.size() == 5)
	assert(state.people["Carlo"].values["independence"] > state.people["Giovanni"].values["independence"])
	var carlo = state.people["Carlo"]
	var before: Dictionary = carlo.view_for(state.head_id)
	assert("psychology" not in before and "goals" not in before and "relationships" not in before)
	assert(carlo.view_for("Pietro")["values"]["known"].is_empty(), "Understanding belongs to the observer")
	var memory_count: int = carlo.memories.size()
	var response: String = carlo.converse(state.head_id, state.elapsed_months, state.date_text())
	assert("ideas" in response)
	var after: Dictionary = carlo.view_for(state.head_id)
	assert("Wants recognition for his own ideas at work" in after["values"]["known"])
	assert("Recognition from Giovanni" not in after["values"]["suspected"])
	assert(after["evidence"].size() == before["evidence"].size() + 1)
	assert(carlo.memories.size() == memory_count + 1)
	carlo.converse(state.head_id, state.elapsed_months, state.date_text())
	assert(carlo.memories.size() == memory_count + 1, "Repeated conversations do not duplicate evidence")
	after["values"]["known"].clear()
	assert(not carlo.view_for(state.head_id)["values"]["known"].is_empty(), "Views cannot mutate private understanding")
	assert(source["Carlo"]["values"]["suspected"].has("Recognition from Giovanni"), "Source data remains unchanged")
	for index in range(4):
		state.advance_month()
	assert(state.people["Carlo"].age == 23, "Age holds until the birth month")
	state.advance_month()
	assert(state.people["Carlo"].age == 24, "June birthday increments age")
	for index in range(7):
		state.advance_month()
	assert(state.people["Carlo"].age == 24, "New Year does not age everyone")
	assert(state.people["Sofia"].age == 18)
	var calm = State.Person.new("Calm", {"age": 30, "psychology": {"temperament": {"emotional_stability": 0.9}}}, 1800, 1, "Giovanni")
	var anxious = State.Person.new("Anxious", {"age": 12, "psychology": {"temperament": {"emotional_stability": 0.1}}}, 1800, 1, "Giovanni")
	calm.experience_event("financial_crisis", "Unpaid bill", "January 1800", [], 0.5)
	anxious.experience_event("financial_crisis", "Unpaid bill", "January 1800", [], 0.5)
	assert(anxious.current_state["stress"] > calm.current_state["stress"], "The same event has contextual effects")
	var expected_residents: int = state.economy.budget(state.people, state.household["members"])["residents"] - (1 if carlo.in_household else 0)
	carlo.alive = false
	state.advance_month()
	assert(carlo.age == 24 and carlo.status_text() == "Deceased")
	assert(state.economy.ledger[-1]["residents"] == expected_residents, "Deceased people incur no food or earnings")

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	screen._show_person("Carlo")
	screen._talk_to_person("Carlo")
	assert("ideas" in screen.conversation_result)
	for index in range(5):
		screen.game_clock.state.advance_month()
	screen._refresh_time_controls()
	assert("24" in screen.details_content.get_child(0).get_child(0).text, "Open popup refreshes on birthday")
	assert("24" in screen.get_node("PageMargins/Page/RosterScroll/FamilyList/Carlo/Row/Details/Name").text)
	screen.game_clock.state.household["members"].erase("Carlo")
	screen.game_clock.state.advance_month()
	screen._refresh_time_controls()
	assert(not screen.get_node("PageMargins/Page/RosterScroll/FamilyList/Carlo").visible)
	screen.free()
	print("PASS: birthdays, family links, psychology, private knowledge, conversations, contextual experiences, death state, and live person UI")
	quit()
