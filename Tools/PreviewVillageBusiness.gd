extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _capture(path: String, viewport) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(path) == OK)
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","discount")
	var state = screen.game_clock.state
	state.events.enabled = false
	state.village.development.transfer(state,"workshop","landi")
	state.village.business.propose(state,"Giovanni","workshop")
	state.advance_month()
	screen.gameplay_person_id = "Giovanni"
	screen._open_person_activity()
	await _capture("res://.godot/business-profile-preview.png",screen.details_popup)
	screen.details_popup.hide()
	screen._show_screen("Finances")
	await _capture("res://.godot/business-finances-preview.png",root)
	quit()
