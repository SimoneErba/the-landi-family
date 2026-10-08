extends SceneTree
## Export a screenshot of the native archive UI using the actual renderer.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://Assets/UI/interface-preview.png") == OK)
	if "--person" in OS.get_cmdline_user_args():
		screen._show_person("Carlo")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(screen.details_popup.get_texture().get_image().save_png("res://Assets/UI/person-window-preview.png") == OK)
	if "--finances" in OS.get_cmdline_user_args():
		if "--accounts" in OS.get_cmdline_user_args():
			for month in range(12):
				screen.game_clock.state.economy.settle_month(screen.game_clock.state.date_text(), screen.people, screen.game_clock.state.household["members"])
				screen.game_clock.state.month += 1
				if screen.game_clock.state.month > 12:
					screen.game_clock.state.month = 1
					screen.game_clock.state.year += 1
		screen._refresh_people()
		screen._show_screen("Finances")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://Assets/UI/finances-preview.png") == OK)
	quit()
