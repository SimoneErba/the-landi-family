extends SceneTree
## Render an event window for visual review without changing gameplay data.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.monthly_chance = 0.0
	var event_id := "expansion_04"
	var person_id := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--event="):
			event_id = argument.trim_prefix("--event=")
		if argument.begins_with("--person="):
			person_id = argument.trim_prefix("--person=")
	assert(screen.game_clock.state.events.trigger(screen.game_clock.state, event_id, person_id))
	screen._show_pending_event()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://Assets/UI/event-window-preview.png"
	assert(screen.event_popup.get_texture().get_image().save_png(path) == OK)
	print("Saved event window preview: " + path)
	quit()
