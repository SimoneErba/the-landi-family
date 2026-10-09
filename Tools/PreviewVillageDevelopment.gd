extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	var state = screen.game_clock.state
	# Preview only: accelerate the independent village, preserving the player's people.
	for month in 1080:
		state.elapsed_months += 1
		state.year = 1800 + state.elapsed_months / 12
		state.month = state.elapsed_months % 12 + 1
		state.village.advance_month(state)
	screen._refresh_time_controls()
	screen._show_screen("Village")
	screen.village_view.map.building_selected.emit("church")
	await _capture("res://.godot/village-1890-preview.png")
	screen.village_view.timeline.value = 0
	await _capture("res://.godot/village-history-preview.png")
	quit()
