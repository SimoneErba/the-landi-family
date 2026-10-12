extends SceneTree
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var clock = Clock.new()
	var state = clock.state
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 100000
	var person = state.people["Pietro"]
	person.interests["practical"] = 100.0
	person.values["family_loyalty"] = 1.0
	person.current_state["resentment"] = 0.0
	person.current_state["stress"] = 0.0
	person.learned_tendencies["need_for_autonomy"] = 0.0
	person.relationships["Giovanni"]["trust"] = 1.0
	var first: String = state.activities.enqueue(state, "Giovanni", "study")
	var second: String = state.activities.enqueue(state, "Giovanni", "repair")
	var parallel: String = state.activities.enqueue(state, "Pietro", "repair")
	state.activities.move(second, -1)
	assert(state.activities.queue_for("Giovanni")[0].id == second)
	state.activities.pause_plan(state, second)
	state.activities.advance_month(state)
	assert(state.activities.commitment("Giovanni") == null, "Paused first plan holds only its owner's queue")
	assert(state.activities.commitment("Pietro").id == parallel, "Another person starts independently")
	state.activities.pause_plan(state, second)
	state.activities.advance_month(state)
	assert(state.activities.commitment("Giovanni").id == second, "Starting preserves queued identity")
	state.activities.pause_plan(state, second)
	var progress: float = state.activities.plans[second].progress_months
	var cash: int = state.economy.cash_cents
	state.activities.pause_plan(state, parallel)
	state.activities.advance_month(state)
	assert(state.activities.plans[second].progress_months == progress and state.economy.cash_cents == cash)
	assert(not state.activities.reason(state, "Giovanni", "repair").is_empty(), "Paused work still reserves its participant")
	var saved: Dictionary = state.to_save_data()
	var path := "user://family_journal_test.save"
	assert(Save.save_game(clock, path).is_empty())
	assert(Save.load_game(clock, path).is_empty())
	assert(clock.state.to_save_data() == saved, "Queues, order, pauses, contracts and stable IDs survive loading")
	state = clock.state
	state.activities.cancel(state, second)
	state.activities.advance_month(state)
	assert(state.activities.commitment("Giovanni").id == first)
	assert(state.activities.plans[second].status == "cancelled")
	# A plan is an intention, not a command: consent remains part of starting.
	var carlo = state.people["Carlo"]
	carlo.interests["practical"] = 0.0
	carlo.values["family_loyalty"] = 0.0
	carlo.current_state["resentment"] = 1.0
	var refused: String = state.activities.enqueue(state, "Carlo", "repair")
	state.activities.advance_month(state)
	assert(state.activities.plans[refused].status == "failed")
	assert(state.activities.commitment("Carlo") == null)
	DirAccess.remove_absolute(path)
	clock.free()
	# Actual journal views and Manage use the existing inspector.
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen._show_screen("Journal")
	assert(screen.journal_page.body.get_child_count() == 7)
	var manage = screen.journal_page.body.get_child(1).find_children("*", "Button", true, false)[0]
	manage.pressed.emit()
	assert(screen.selected_person_id == "Maria")
	screen.journal_page.tab = 1
	screen.journal_page.refresh()
	assert(screen.journal_page.body.get_child_count() == 7)
	var unchanged_row = screen.journal_page.body.get_child(0)
	screen.journal_page.refresh()
	assert(screen.journal_page.body.get_child(0) == unchanged_row, "Unchanged playback state does not recreate the rows")
	screen.game_clock.state.activities.enqueue(screen.game_clock.state, "Giovanni", "study")
	screen.journal_page.tab = 2
	screen.journal_page.person_filter = "Giovanni"
	screen.journal_page.history_category = "Projects"
	screen.journal_page.refresh()
	assert(screen.journal_page.body.get_child_count() >= 2, "Project history filters use the recorded participant")
	screen._show_screen("People")
	assert(not screen.content_overlay.visible, "The journal is hidden when visiting another page")
	assert(screen.find_children("FamilyJournal", "", true, false).size() == 1, "Only the page journal exists")
	assert(is_equal_approx(screen.page.offset_right, screen.size.x - 12), "Other pages use the full available width")
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_J
	shortcut.pressed = true
	screen._unhandled_key_input(shortcut)
	assert(screen.current_screen == "Journal" and screen.content_overlay.visible, "J opens the dedicated journal page")
	screen.game_clock.state.add_person("LaterArrival", {"name": "Later arrival"})
	screen.journal_page.refresh()
	assert(screen.journal_page.person_choice.item_count == 9, "Later relatives enter the person filter")
	screen.queue_free()
	await process_frame
	print("PASS: independent queues, priority, pauses, no paused charges, consent, stable save IDs, journal tabs and correct person inspector")
	quit()
