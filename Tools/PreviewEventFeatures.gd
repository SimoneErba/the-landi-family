extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	var state = screen.game_clock.state
	state.events.monthly_chance = 0.0
	state.economy.cash_cents = 100000
	state.village.development.transfer(state,"workshop","landi")
	assert(state.events.trigger(state,"property_repairs_01"))
	screen._show_pending_event()
	await _capture(screen,"res://.godot/property-event-preview.png")
	var event: Dictionary = state.events.pending[0]
	state.events.resolve(state,event["serial"],0)
	assert(state.events.trigger(state,"war_01"))
	screen.last_event_serial = -1
	screen._show_pending_event()
	await _capture(screen,"res://.godot/war-event-preview.png")
	quit()
func _capture(screen,path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(screen.event_popup.get_texture().get_image().save_png(path) == OK)
