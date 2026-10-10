extends SceneTree

const State = preload("res://Simulation/GameState.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var state = State.new()
	state.initialize(source)
	state.events.enabled = false
	assert(state.request("Giovanni", "leave")["outcome"] == "unavailable")
	assert(state.request("Sofia", "marry")["outcome"] == "unavailable")
	assert(state.request("Maria", "marry")["outcome"] == "unavailable")
	assert(state.request("missing", "join")["outcome"] == "unavailable")
	assert(state.request("Carlo", "unknown")["outcome"] == "unavailable")
	assert(state.chronicle.is_empty(), "Invalid requests have no effects")
	var carlo = state.people["Carlo"]
	var resentment: float = carlo.current_state.get("resentment", 0.0)
	var result: Dictionary = state.request("Carlo", "leave")
	assert(result["outcome"] == "accepted", "Independent earning son wants a place of his own")
	assert(not carlo.in_household and "Carlo" not in state.household["members"])
	assert(carlo.current_state["resentment"] > resentment, "Being asked to leave still hurts")
	assert(state.chronicle.size() == 1 and carlo.memories[-1]["kind"] == "request")
	assert(state.request("Carlo", "join")["outcome"] == "unavailable", "Cannot spam requests")
	state.advance_month()
	assert(state.economy.ledger[-1]["residents"] == 6, "Departures change the actual budget")
	assert(state.request("Carlo", "join")["outcome"] == "refused", "He will not abandon his independent plans")
	assert(not carlo.in_household)
	state.advance_month()
	carlo.values["independence"] = 0.0
	carlo.values["family_loyalty"] = 1.0
	carlo.values["security"] = 1.0
	carlo.learned_tendencies["need_for_autonomy"] = 0.0
	assert(state.request("Carlo", "join")["outcome"] == "accepted", "Changed wishes can make returning attractive")
	assert(carlo.in_household and state.household["members"].count("Carlo") == 1)
	state.advance_month()
	assert(state.economy.ledger[-1]["residents"] == 7)

	var neutral = State.new()
	neutral.initialize({"Giovanni": {"age": 50}, "Adult": {"age": 25, "monthly_income_cents": 1000}})
	neutral.events.enabled = false
	assert(neutral.request("Adult", "stay")["outcome"] == "reluctant")
	assert(neutral.people["Adult"].current_state["resentment"] > 0.0)
	neutral.advance_month()
	var adult = neutral.people["Adult"]
	adult.values["romance"] = 1.0
	adult.values["tradition"] = 1.0
	adult.values["independence"] = 0.0
	adult.learned_tendencies["need_for_autonomy"] = 0.0
	assert(neutral.request("Adult", "marry")["outcome"] == "accepted")
	assert(adult.goals[-1]["kind"] == "seek_marriage" and adult.spouse_id.is_empty(), "Seeking a partner does not force a marriage")
	neutral.advance_month()
	assert(neutral.request("Adult", "marry")["outcome"] == "unavailable", "No duplicate marriage intentions")
	adult.alive = false
	assert(neutral.request("Adult", "leave")["outcome"] == "unavailable")

	var outside = State.new()
	outside.initialize({"Giovanni": {"age": 50}, "Relative": {"age": 30, "in_household": false}})
	outside.events.enabled = false
	assert(not outside.people["Relative"].in_household and "Relative" not in outside.household["members"])

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	screen.game_clock.play()
	screen._on_card_input(click, "Carlo")
	assert(screen.influence_popup.visible and screen.game_clock.is_playing)
	assert(screen.influence_popup.is_item_disabled(screen.influence_popup.get_item_index(3)), "Join is disabled for residents")
	screen.influence_popup.hide()
	screen._make_request("Carlo", "leave")
	assert(screen.assignment_feedback["Carlo:request"]["accepted"])
	assert(not screen.get_node("PageMargins/Page/RosterScroll/FamilyList/Carlo").visible)
	assert(screen.elsewhere_list.get_node("Carlo").visible, "Departed relatives remain accessible")
	screen._show_screen("Chronicle")
	assert(screen.content_overlay.visible)
	screen.free()
	print("PASS: request validity, consent, reluctant compliance, memories, cooldown, moves, economy, marriage intention, and right-click UI")
	quit()
