extends SceneTree
## Screenshots use the running game and its native controls.
func _initialize() -> void: call_deferred("_run")
func _capture(viewport, path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(path) == OK)
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous", "fertility")
	await _capture(root, "res://Docs/Screenshots/family.png")
	screen._show_screen("Village")
	await _capture(root, "res://Docs/Screenshots/village.png")
	screen._show_screen("People")
	screen._show_person("Anna")
	screen.profile_expanded = true
	screen.profile_section = "Marriage"
	screen._show_person("Anna", false)
	screen.details_popup.popup_centered(Vector2i(860,1000))
	await _capture(screen.details_popup, "res://Docs/Screenshots/marriage.png")
	quit()
