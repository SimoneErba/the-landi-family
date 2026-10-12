extends SceneTree

const StartingFamily = preload("res://Simulation/StartingFamily.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const PATH := "user://main_menu_test.save"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(StartingFamily.create_people("invalid").is_empty())
	for choice in StartingFamily.OPTIONS:
		var clock = Clock.new()
		clock.state.initialize(StartingFamily.create_people(choice))
		var state = clock.state
		assert(state.people.size() == (1 if choice == "alone" else (3 if choice == "child" else 2)))
		assert(state.household["members"].size() == state.people.size())
		assert(state.people["Giovanni"].age == 30)
		if choice in ["wife", "child"]: assert(state.people["Maria"].life_state["can_be_pregnant"])
		for person in state.people.values():
			for parent in person.parent_ids: assert(state.people.has(parent))
			for relative in person.relationships: assert(state.people.has(relative))
			assert(person.spouse_id.is_empty() or state.people[person.spouse_id].spouse_id == person.id)
		if choice == "child":
			assert(state.people["Carlo"].age == 6)
			assert(state.people["Carlo"].monthly_income_cents == 0)
			assert(state.people["Carlo"].parent_ids == ["Giovanni", "Maria"])
			assert(state.people["Giovanni"].spouse_id == "Maria")
		assert(SaveGame.save_game(clock, PATH).is_empty())
		var restored = Clock.new()
		assert(SaveGame.load_game(restored, PATH).is_empty())
		assert(restored.state.to_save_data() == state.to_save_data())
		restored.free()
		# Exercise all game screens with a smaller roster and monthly progression.
		var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
		screen.starting_people = StartingFamily.create_people(choice)
		root.add_child(screen)
		assert(screen.people.size() == state.people.size())
		assert(screen._start_family_story("populous", "fertility"))
		for page in ["People", "Family Tree", "House", "Village", "Italy", "Finances", "Chronicle", "Events"]:
			screen._show_screen(page)
		screen.game_clock.state.events.enabled = false
		for month in 12: screen.game_clock.state.advance_month()
		screen._refresh_time_controls()
		screen.free()
		clock.free()
	var menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	assert(menu.column.has_node("NewGame") and menu.column.has_node("LoadGame"))
	menu._show_new_game()
	menu._select_choice("child")
	assert(menu.starting_choice == "child")
	assert(menu.choice_buttons[2].button_pressed and not menu.choice_buttons[0].button_pressed)
	menu._show_settings()
	assert(menu.settings_popup.visible)
	await process_frame
	await process_frame
	assert(menu.settings_popup.get_global_rect().is_equal_approx(menu.menu_panel.get_global_rect()), "Settings overlays the menu at the same size and position")
	assert(menu.settings_popup.mute.has_focus())
	menu.settings_popup.hide()
	menu._show_home()
	await process_frame
	menu._show_settings()
	await process_frame
	assert(menu.settings_popup.get_global_rect().is_equal_approx(menu.menu_panel.get_global_rect()), "Home settings also matches the main menu bounds")
	root.size = Vector2i(1280, 900)
	await process_frame
	await process_frame
	assert(menu.settings_popup.get_global_rect().is_equal_approx(menu.menu_panel.get_global_rect()), "Settings follows menu bounds when the window resizes")
	menu._show_home()
	assert(not menu.settings_popup.visible)
	menu.free()
	# A loaded game must bypass initialization and preserve its month and legacy.
	var loaded = load("res://Scenes/FamilyScreen.tscn").instantiate()
	assert(SaveGame.load_game(loaded.game_clock, PATH).is_empty())
	loaded.game_clock.state.advance_month()
	var before: Dictionary = loaded.game_clock.state.to_save_data()
	loaded.loaded_game = true
	root.add_child(loaded)
	assert(loaded.game_clock.state.to_save_data() == before)
	assert(not loaded.game_clock.is_playing)
	loaded.free()
	# Follow the real menu transitions, including a save loaded from the title page.
	var original := FileAccess.get_file_as_bytes(SaveGame.SAVE_PATH) if FileAccess.file_exists(SaveGame.SAVE_PATH) else PackedByteArray()
	var start_menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(start_menu)
	current_scene = start_menu
	start_menu.starting_choice = "child"
	start_menu._start_game()
	await process_frame
	await process_frame
	var running = current_scene
	assert(running.people.size() == 3 and running.people["Carlo"].age == 6)
	assert(running._start_family_story("populous", "fertility"))
	running.game_clock.state.events.enabled = false
	running.game_clock.state.advance_month()
	assert(SaveGame.save_game(running.game_clock).is_empty())
	var saved: Dictionary = running.game_clock.state.to_save_data()
	running.free()
	var load_menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(load_menu)
	current_scene = load_menu
	assert(not load_menu.column.get_node("LoadGame").disabled)
	load_menu._load_game()
	await process_frame
	await process_frame
	assert(current_scene.game_clock.state.to_save_data() == saved)
	assert(not is_instance_valid(current_scene.focus_overlay) or not current_scene.focus_overlay.visible)
	current_scene.free()
	if original.is_empty():
		DirAccess.remove_absolute(SaveGame.SAVE_PATH)
	else:
		var file := FileAccess.open(SaveGame.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	DirAccess.remove_absolute(PATH)
	await process_frame
	print("PASS: main menu, settings, three households, child constraints, save round trips, small-roster screens and loaded startup")
	quit()
