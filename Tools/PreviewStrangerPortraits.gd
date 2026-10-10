extends SceneTree
## Capture the same unrelated stranger gallery available from the starting screen.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.find_child("StartStrangerPortraitTest", true, false).pressed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/stranger-portraits-preview.png") == OK)
	quit()
