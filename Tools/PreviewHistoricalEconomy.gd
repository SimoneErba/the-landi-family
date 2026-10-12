extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _capture(screen, path: String, popup := false) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var texture = screen.careers_popup.get_texture() if popup else root.get_texture()
	assert(texture.get_image().save_png(path) == OK)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen.game_clock.state.events.enabled = false
	screen._show_screen("Finances")
	await _capture(screen, "res://.godot/historical-income-finances.png")
	screen._show_careers("Sofia")
	await _capture(screen, "res://.godot/historical-income-training.png", true)
	quit()
