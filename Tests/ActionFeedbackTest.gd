extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const Assignment = preload("res://Simulation/Assignment.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
func _initialize() -> void: call_deferred("_run")
func _state():
	var state = State.new()
	state.initialize({"Giovanni":{"age":50}, "Relative":{"age":25, "name":"Lorenzo Moretti"}})
	state.events.enabled = false
	state.economy.cash_cents = 100000
	return state
func _button(parent, caption: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text == caption: return button
	return null
func _run() -> void:
	var state = _state()
	var person = state.people["Relative"]
	for entry in [[.8,"enthusiastic",true], [.4,"willing",true], [.2,"reluctant",true], [.01,"refused",false]]:
		var result: Dictionary = Assignment.resolve(person, entry[0], "repair Landi House")
		assert(result["action_response"] == entry[1] and result["accepted"] == entry[2])
		assert(result["dialogue_key"] == "assignment."+entry[1])
	person.learned_tendencies["conflict_avoidance"] = 1.0
	person.values["family_loyalty"] = .8
	person.interests["academic"] = 0.0
	person.learned_tendencies["need_for_autonomy"] = .2
	person.current_state["stress"] = 0.0
	person.current_state["resentment"] = .15
	var result: Dictionary = state.activities.propose(state, person.id, "study")
	assert(result["accepted"] and result["action_response"] == "willing" and result["outcome"] == "reluctant")
	assert(not "not what I wanted" in result["response"], "Communication does not reveal concealed reluctance")
	assert(state.elapsed_months == 0, "Paused assignments respond immediately")
	var plan = state.activities.plans[result["activity_id"]]
	assert(plan.status == "active" and plan.progress_months == 0 and plan.outcome.is_empty(), "Accepting is not completion")
	state.activities.advance_month(state)
	assert(is_equal_approx(plan.progress_months, .7) and person.current_state["resentment"] > .2)
	assert(not state.major_event)
	var data := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	assert(SaveGame._valid_save(data))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	state.advance_month()
	restored.advance_month()
	assert(state.to_save_data() == restored.to_save_data())
	person.current_state["resentment"] = .85
	state.activities.advance_month(state)
	assert(plan.status == "failed" and not state.major_event and state.notifications.back()["description"].contains("abandoned"))
	assert(state.notifications.back()["person_id"] == person.id)
	assert(SaveGame._valid_save({"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}))
	data["state"]["activities"]["plans"][plan.id]["agreement"]["private_response"] = "invalid"
	assert(not SaveGame._valid_save(data), "Corrupt commitments are rejected")
	var legacy := {"state":restored.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	legacy["state"].erase("notifications")
	for old_plan in legacy["state"]["activities"]["plans"].values(): old_plan.erase("agreement")
	assert(SaveGame._valid_save(legacy), "Old saves gain empty commitments and notifications")
	# The clock, family cards and assignment controls remain usable around the panels.
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen.game_clock.state.events.enabled = false
	screen.game_clock.state.economy.cash_cents = 100000
	screen.game_clock.play()
	screen._show_person("Giovanni")
	assert(screen.game_clock.is_playing and screen.details_popup is PanelContainer)
	screen._open_person_activity("repair")
	_button(screen.details_content,"Begin activity").pressed.emit()
	assert(screen.game_clock.is_playing and screen.details_popup.visible)
	assert(_button(screen.details_content,"Activity underway").disabled)
	var reaction = screen.details_content.find_child("AssignmentReaction",true,false)
	assert(reaction != null and not screen.event_popup.visible)
	# Expired feedback builds a compact status immediately rather than repeating dialogue on refresh.
	screen.assignment_feedback["Giovanni:activity"]["created_msec"] = Time.get_ticks_msec()-7000
	screen._show_person("Giovanni",false)
	reaction = screen.details_content.find_child("AssignmentReaction",true,false)
	assert(not "\n" in reaction.get_child(0).text and "Enthusiastic" in reaction.get_child(0).text)
	for month in 4: screen.game_clock.state.activities.advance_month(screen.game_clock.state)
	screen._show_person("Giovanni",false)
	reaction = screen.details_content.find_child("AssignmentReaction",true,false)
	assert("Completed" in reaction.get_child(0).text, "A finished task never keeps an outcome-pending indicator")
	screen.game_clock.pause()
	screen._show_careers("Anna")
	screen._make_request("Anna","train:architecture")
	assert(screen.careers_popup.visible and not screen.game_clock.is_playing and not screen.event_popup.visible)
	assert(screen.assignment_feedback["Anna:train:architecture"]["accepted"])
	assert(screen.game_clock.state.people["Anna"].education["study"]["program_id"] == "architecture")
	screen.game_clock.state.notify("A routine project finished.","Anna")
	screen._refresh_time_controls()
	assert(screen.notification_feed.visible and not screen.event_popup.visible)
	_button(screen.notification_feed,"Dismiss updates").pressed.emit()
	assert(not screen.notification_feed.visible and screen.game_clock.state.notifications.back()["read"])
	# A real decision still opens an event and pauses the clock.
	screen.game_clock.state.events.enabled = true
	screen.game_clock.state.events.trigger(screen.game_clock.state,"repairs_01")
	screen._show_pending_event()
	assert(screen.event_popup.visible and not screen.game_clock.is_playing)
	screen.free()
	print("PASS: four reactions, concealed reluctance, immediate paused acceptance, slower progress and abandonment, notification persistence, compact inline feedback, nonmodal panels and major decision windows")
	quit()
