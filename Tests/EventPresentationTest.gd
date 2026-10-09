extends SceneTree

const Presentation = preload("res://Scripts/EventPresentation.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	var state = screen.game_clock.state
	screen._start_family_story("populous", "discount")
	var event := {"person_id": "Carlo"}
	var rows: Array = Presentation.consequences(state, event, {"cash": -2000, "happiness": 0.06, "stress": -0.02, "resentment": 0.03, "trust": -0.01})
	assert(rows.size() == 5)
	assert(rows[0].tone == -1 and state.economy.money(state.economy.purchase_cost(2000)) in rows[0].text, "Cash preview must match the discounted purchase price")
	assert(rows[1].tone == 1 and rows[2].tone == 1, "More happiness and less stress are benefits")
	assert(rows[3].tone == -1 and rows[4].tone == -1, "More resentment and less trust are harms")
	assert("0.06" not in rows[1].text, "Private psychology remains qualitative")
	rows = Presentation.consequences(state, event, {"crisis": {"months": 6, "food_multiplier": 1.25, "income_multiplier": 0.85, "travel_delay_months": 2}})
	assert(rows.size() == 3 and rows.all(func(row): return row.tone == -1))
	rows = Presentation.consequences(state, event, {"crisis": {"months": 3, "food_multiplier": 0.8, "income_multiplier": 1.1}})
	assert(rows.size() == 2 and rows.all(func(row): return row.tone == 1))
	rows = Presentation.consequences(state, event, {"stay_release": true, "pregnancy": true})
	assert(rows.all(func(row): return row.tone == 0), "Contextual life changes are neutral")
	assert(Presentation.consequences(state, event, {"cash": 0, "stress": 0}).is_empty())
	state.events.monthly_chance = 0
	assert(state.events.trigger(state, "repairs_01"))
	screen._show_pending_event()
	await process_frame
	await process_frame
	var columns = screen.event_content.get_node("EventColumns")
	assert(columns is HBoxContainer)
	assert(columns.get_node("Story/Illustration").size.y >= 230)
	assert(columns.get_node("Story").position.x < columns.get_node("Actions").position.x)
	assert(columns.get_node("Actions/Choice0").get_child(0).get_child(0) is Button)
	assert(screen.event_popup.visible and not screen.game_clock.is_playing)
	screen.event_popup.hide()
	root.size = Vector2i(720, 900)
	root.content_scale_size = Vector2i(720, 900)
	await process_frame
	screen._show_pending_event()
	await process_frame
	assert(screen.event_content.get_node("EventColumns") is VBoxContainer, "Narrow windows stack the columns")
	screen.free()
	print("PASS: event consequence signs, purchase costs, qualitative psychology, neutral changes, and split event layout")
	quit()
