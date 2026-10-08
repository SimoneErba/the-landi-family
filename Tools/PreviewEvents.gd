extends SceneTree
## Render an event window for visual review without changing gameplay data.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.monthly_chance = 0.0
	screen.game_clock.state.events.trigger(screen.game_clock.state, "expansion_04")
	screen._show_pending_event()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://Assets/UI/event-window-preview.png"
	assert(screen.event_popup.get_texture().get_image().save_png(path) == OK)
	print("Saved event window preview: " + path)
	quit()
