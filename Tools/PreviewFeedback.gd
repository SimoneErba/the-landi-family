extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen.game_clock.state.events.enabled = false
	screen.game_clock.state.economy.cash_cents = 100000
	screen._show_person("Anna")
	screen._open_person_activity("study")
	for button in screen.details_content.find_children("*","Button",true,false):
		if button.text == "Ask to take part": button.pressed.emit(); break
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://Docs/Screenshots/assignment.png") == OK)
	quit()
