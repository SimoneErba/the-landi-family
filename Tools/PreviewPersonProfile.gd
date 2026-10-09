extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _capture(screen, path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(screen.details_popup.get_texture().get_image().save_png(path) == OK)
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen._show_person("Carlo")
	await _capture(screen,"res://.godot/person-essential-preview.png")
	screen._open_person_activity("study")
	await _capture(screen,"res://.godot/person-activities-preview.png")
	screen.profile_section = "Personality"
	screen._show_person("Carlo",false)
	await _capture(screen,"res://.godot/person-personality-preview.png")
	quit()
