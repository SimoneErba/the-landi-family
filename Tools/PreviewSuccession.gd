extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen.game_clock.state.events.enabled = false
	screen.game_clock.state.economy.cash_cents = 180000
	screen.game_clock.state.loans.borrow(screen.game_clock.state, 10000)
	screen._show_screen("Finances")
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/loans-preview.png") == OK)
	screen._show_screen("Succession")
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/will-preview.png") == OK)
	screen.game_clock.state.succession.die(screen.game_clock.state, "Giovanni")
	screen._refresh_time_controls()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/succession-preview.png") == OK)
	quit()
