extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _capture(path: String) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen.game_clock.state.events.enabled = false
	screen.game_clock.state.activities.propose(screen.game_clock.state, "Giovanni", "repair")
	screen.game_clock.state.activities.enqueue(screen.game_clock.state, "Giovanni", "study")
	screen.game_clock.state.activities.enqueue(screen.game_clock.state, "Pietro", "visit", "rossi")
	screen._show_screen("Journal")
	await _capture("res://.godot/family-journal-activities.png")
	screen.journal_page.tab = 1
	screen.journal_page.refresh()
	await _capture("res://.godot/family-journal-queue.png")
	screen._show_screen("Village")
	await _capture("res://.godot/village-without-journal.png")
	root.size = Vector2i(1100, 800)
	screen._show_screen("Journal")
	await _capture("res://.godot/family-journal-compact.png")
	quit()
