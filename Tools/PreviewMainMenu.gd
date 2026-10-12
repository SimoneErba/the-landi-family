extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/main-menu-preview.png")
	menu._show_settings()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/main-menu-settings-preview.png")
	menu.settings_popup.hide()
	menu._show_new_game()
	menu._select_choice("child")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/new-game-preview.png")
	quit()
