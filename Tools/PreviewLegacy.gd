extends SceneTree
## Render the starting ambition, wider roster and aligned header for review.

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	await _capture("res://.godot/legacy-start-preview.png")
	screen._start_family_story("populous", "fertility")
	screen._show_screen("People")
	screen._refresh_time_controls()
	await _capture("res://.godot/legacy-people-preview.png")
	screen._show_screen("People")
	await _capture("res://.godot/legacy-progress-preview.png")
	quit()
