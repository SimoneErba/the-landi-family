extends SceneTree
## Render the starting ambition, wider roster and aligned header for review.

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
	await _capture("res://.godot/legacy-start-preview.png")
	var goals = screen.focus_overlay.find_child("ObjectiveCards", true, false)
	goals.get_child(2).find_children("*", "Button", true, false)[0].pressed.emit()
	var perks = screen.focus_overlay.find_child("PerkCards", true, false)
	perks.get_child(1).find_children("*", "Button", true, false)[0].pressed.emit()
	await _capture("res://.godot/legacy-selected-preview.png")
	screen._start_family_story("populous", "fertility")
	screen._show_screen("People")
	screen._refresh_time_controls()
	await _capture("res://.godot/legacy-people-preview.png")
	screen._show_screen("People")
	await _capture("res://.godot/legacy-progress-preview.png")
	screen._show_screen("Family Tree")
	await _capture("res://.godot/family-tree-preview.png")
	screen._show_screen("Village")
	await _capture("res://.godot/village-labels-preview.png")
	screen._show_screen("Italy")
	var choice = screen.content_overlay.find_child("TravelerChoice", true, false)
	choice.get_popup().position = Vector2i(choice.global_position + Vector2(0, choice.size.y))
	choice.show_popup()
	await _capture("res://.godot/traveler-portraits-preview.png")
	choice.get_popup().hide()
	screen.travel_city_id = "genoa"
	screen._show_screen("Italy")
	await _capture("res://.godot/genoa-route-preview.png")
	screen.free()
	quit()
