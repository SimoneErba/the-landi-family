extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _capture(screen, path: String) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(screen.details_popup.get_texture().get_image().save_png(path) == OK)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	screen.starting_people = preload("res://Simulation/StartingFamily.gd").create_people("child")
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen.game_clock.state.events.enabled = false
	screen._show_person("Maria")
	for frame in 5: await process_frame
	preload("res://Scripts/PersonProfile.gd").jump_to(screen, "Requests")
	await _capture(screen, "res://.godot/social-reports-preview.png")
	preload("res://Scripts/PersonProfile.gd").jump_to(screen, "Activities")
	await _capture(screen, "res://.godot/social-activities-preview.png")
	screen._show_person("Carlo")
	for frame in 5: await process_frame
	preload("res://Scripts/PersonProfile.gd").jump_to(screen, "Activities")
	await _capture(screen, "res://.godot/social-child-preview.png")
	screen.free()
	quit()
