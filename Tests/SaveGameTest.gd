extends SceneTree

const Clock = preload("res://Simulation/GameClock.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const PATH := "user://save_game_test.save"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var clock = Clock.new()
	clock.state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	clock.state.events.enabled = false
	assert(clock.state.legacy.choose("wealth", "discount"))
	clock.state.people["Carlo"].converse("Giovanni", 0, clock.state.date_text())
	clock.state.request("Carlo", "stay")
	clock.state.advance_month()
	clock.state.people["Anna"].education["study"] = {"program_id": "test", "progress": 3.5, "monthly_cost_cents": 100}
	clock.state.add_person("NewRelative", {"name": "New relative", "parent_ids": ["Giovanni", "Maria"]})
	clock.speed_level = 4
	clock.month_progress = 0.625
	var before: Dictionary = clock.state.to_save_data()
	assert(SaveGame.save_game(clock, PATH).is_empty(), "Save succeeds")
	clock.state.advance_month()
	clock.state.people["Carlo"].knowledge.clear()
	clock.speed_level = 1
	clock.month_progress = 0.0
	clock.play()
	assert(SaveGame.load_game(clock, PATH).is_empty(), "Load succeeds")
	assert(clock.state.to_save_data() == before, "Every simulation field round trips exactly")
	assert(not clock.is_playing and clock.speed_level == 4 and clock.month_progress == 0.625, "Clock restores paused with progress")
	assert(SaveGame.save_game(clock, PATH).is_empty(), "Can replace existing save")
	var saved_bytes := FileAccess.get_file_as_bytes(PATH)
	assert(DirAccess.make_dir_absolute(PATH + ".tmp") == OK)
	assert(not SaveGame.save_game(clock, PATH).is_empty(), "Unwritable temporary file reports failure")
	assert(FileAccess.get_file_as_bytes(PATH) == saved_bytes, "Failed save preserves previous slot")
	DirAccess.remove_absolute(PATH + ".tmp")
	var other = Clock.new()
	assert(SaveGame.load_game(other, PATH).is_empty(), "Save works in a fresh session")
	clock.state.advance_month()
	other.state.advance_month()
	assert(clock.state.to_save_data() == other.state.to_save_data(), "Simulation continues identically after load")
	var unchanged: Dictionary = clock.state.to_save_data()
	assert(not SaveGame.load_game(clock, PATH + ".missing").is_empty())
	assert(clock.state.to_save_data() == unchanged)
	for bad in [null, {"format": "TheHouse", "version": 999}, {"format": "TheHouse", "version": 1, "state": {}}]:
		var file := FileAccess.open(PATH, FileAccess.WRITE)
		file.store_var(bad)
		file.close()
		assert(not SaveGame.load_game(clock, PATH).is_empty())
		assert(clock.state.to_save_data() == unchanged, "Invalid saves leave current family untouched")
	clock.free()
	other.free()
	# Exercise the actual menu handlers and restoration of added/removed cards.
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	screen.game_clock.state.advance_month()
	assert(SaveGame.save_game(screen.game_clock, PATH).is_empty())
	screen.game_clock.state.add_person("LaterArrival", {"name": "Later arrival"})
	screen._refresh_people()
	assert(SaveGame.load_game(screen.game_clock, PATH).is_empty())
	# The UI handler uses the default slot; isolate it from any player's real save.
	var original: PackedByteArray = FileAccess.get_file_as_bytes(SaveGame.SAVE_PATH) if FileAccess.file_exists(SaveGame.SAVE_PATH) else PackedByteArray()
	screen._save_game()
	for child in screen.get_children():
		if child is AcceptDialog:
			child.hide()
			child.confirmed.emit()
	await process_frame
	screen.game_clock.state.advance_month()
	screen._load_game()
	assert(screen.period_label.text == "February 1800")
	assert(screen.people == screen.game_clock.state.people)
	assert(not screen.game_clock.is_playing)
	assert(not screen.get_node("PageMargins/Page/RosterScroll/FamilyList").has_node("LaterArrival"))
	if original.is_empty():
		DirAccess.remove_absolute(SaveGame.SAVE_PATH)
	else:
		var file := FileAccess.open(SaveGame.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	screen.free()
	DirAccess.remove_absolute(PATH)
	await process_frame
	print("PASS: full state round trip, fresh session, deterministic continuation, atomic overwrite, invalid save handling, clock and UI restoration")
	quit()
