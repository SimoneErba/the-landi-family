extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _run() -> void:
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous", "fertility")
	var manager = screen.get_node("WindowManager")
	screen._show_person("Carlo")
	screen._show_careers("Carlo")
	await process_frame
	assert(screen.details_popup.visible and screen.careers_popup.visible, "Opening careers preserves the person profile")
	assert(manager.windows.back() == screen.careers_popup)
	assert(screen.careers_popup.z_index > screen.details_popup.z_index)
	# Close an older window through its own close action.
	screen.details_popup.hide()
	assert(screen.careers_popup.visible and manager.windows.size() == 1)
	screen._show_person("Carlo")
	await process_frame
	assert(manager.windows.back() == screen.details_popup)
	# Clicking within a window never dismisses either window.
	_click(screen.details_popup.global_position + Vector2(10, 10))
	await process_frame
	assert(manager.windows.size() == 2)
	_click(Vector2(2, 2))
	await process_frame
	assert(not screen.details_popup.visible and screen.careers_popup.visible, "Outside click dismisses only the latest window")
	_click(Vector2(2, 2))
	await process_frame
	assert(not screen.careers_popup.visible and manager.windows.is_empty())
	assert(screen.current_screen == "People", "Dismissal cannot activate navigation underneath")
	screen._show_person("Carlo")
	screen._show_careers("Carlo")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await process_frame
	assert(not screen.careers_popup.visible and screen.details_popup.visible)
	assert(not screen.menu_popup.visible, "Escape closes a window without opening the menu")
	screen._toggle_menu()
	assert(screen.menu_popup.visible and screen.details_popup.visible)
	_click(Vector2(2, 2))
	await process_frame
	assert(not screen.menu_popup.visible and screen.details_popup.visible)
	var menu_button = screen.top_bar.get_node("Frame/Header/ClockModule/TimeControls/MenuButton")
	assert(not menu_button.button_pressed)
	# Major events pause time while keeping the windows being read underneath.
	screen._show_careers("Carlo")
	assert(screen.game_clock.state.events.trigger(screen.game_clock.state, "repairs_01"))
	screen._show_pending_event()
	await process_frame
	assert(screen.event_popup.visible and screen.careers_popup.visible and screen.details_popup.visible)
	_click(Vector2(2, 2))
	await process_frame
	assert(not screen.event_popup.visible and screen.careers_popup.visible and screen.details_popup.visible)
	assert(not screen.game_clock.state.events.pending.is_empty(), "Dismissal preserves the pending decision")
	var personality = screen.details_content.find_child("Personality", true, false)
	assert(personality.find_children("*", "Label", true, false).any(func(label): return label.tooltip_text.contains("observation")))
	assert(screen.cash_label.mouse_filter == Control.MOUSE_FILTER_PASS)
	assert(screen.cash_label.tooltip_text.contains("everyday costs"))
	assert(screen.get_node("Navigation").find_children("*", "Button", true, false).all(func(button): return button.tooltip_text.length() > 70))
	print("PASS: independent windows, stack order, outside clicks, Escape, menu state and concept help")
	screen.queue_free()
	await process_frame
	quit()
