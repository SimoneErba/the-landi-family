extends SceneTree

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
	screen._start_family_story("populous", "fertility")
	screen.game_clock.state.activities.propose(screen.game_clock.state, "Giovanni", "repair")
	screen._open_person_activity("repair")
	await process_frame
	await RenderingServer.frame_post_draw
	assert(screen.details_popup.get_texture().get_image().save_png("res://.godot/activities-profile-preview.png") == OK)
	screen._show_screen("Village")
	await _capture("res://.godot/village-preview.png")
	quit()
