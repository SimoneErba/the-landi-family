extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 800)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen._show_screen("Laws")
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/laws-tuscany-preview.png")
	screen.game_clock.state.year = 1866
	screen._refresh_time_controls()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/laws-italy-preview.png")
	quit()
