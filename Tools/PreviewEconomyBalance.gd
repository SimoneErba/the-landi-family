extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous", "fertility")
	screen.game_clock.state.events.enabled = false
	for month in 12: screen.game_clock.state.advance_month()
	screen._refresh_time_controls()
	screen._show_screen("Finances")
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/balanced-finances-preview.png") == OK)
	screen.game_clock.state.economy.cash_cents = -10000
	screen._refresh_time_controls()
	screen._show_screen("Finances")
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/debt-finances-preview.png") == OK)
	quit()
