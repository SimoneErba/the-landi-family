extends SceneTree

const Clock = preload("res://Simulation/GameClock.gd")
var updates: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var clock = Clock.new()
	var initial_people := {"Carlo": {"age": 23, "monthly_income_cents": 2000}}
	clock.state.initialize(initial_people)
	clock.state.events.enabled = false
	clock.month_advanced.connect(func(): updates += 1)
	clock.advance_time(100)
	assert(clock.state.elapsed_months == 0, "Starts paused")
	clock.play()
	clock.advance_time(14)
	assert(updates == 0, "No update before month boundary")
	clock.pause()
	clock.advance_time(100)
	clock.play()
	clock.advance_time(1)
	assert(updates == 1 and clock.state.month == 2, "Speed 3 takes 15 seconds; pause preserves progress")
	clock.advance_time(7.5)
	clock.set_speed(5)
	clock.advance_time(1.875)
	assert(updates == 2, "Speed changes preserve half-completed month")
	clock.advance_time(37.5)
	assert(updates == 12 and clock.state.month == 1 and clock.state.year == 1801, "Catch-up updates every month and rolls over year")
	assert(clock.state.people["Carlo"].age == 24, "People age across twelve months")
	clock.state.people["Carlo"].values["independence"] = 0.9
	assert(initial_people["Carlo"]["age"] == 23, "State owns a deep copy")
	for level in range(1, 6):
		clock.set_speed(level)
		var before: int = updates
		clock.advance_time(Clock.SECONDS_PER_MONTH[level - 1])
		assert(updates == before + 1, "Every speed updates once at its interval")
	clock.month_advanced.connect(clock.pause)
	var before_pause: int = updates
	clock.advance_time(clock.seconds_per_month() * 3)
	assert(updates == before_pause + 1 and not clock.is_playing, "Major events can interrupt catch-up")
	clock.free()

	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	assert(screen.period_label.text == "January 1800")
	assert(screen.pause_button.button_pressed and screen.speed_buttons[2].button_pressed)
	screen.play_button.pressed.emit()
	screen.game_clock.advance_time(15)
	assert(screen.period_label.text == "February 1800")
	screen._show_screen("House")
	assert(screen.top_bar.is_visible_in_tree() and "February 1800" in screen.house_description.text)
	screen.game_clock.advance_time(15)
	assert("March 1800" in screen.house_description.text)
	screen._show_screen("Finances")
	assert(screen.top_bar.is_visible_in_tree())
	screen._show_screen("People")
	assert(screen.page.visible and screen.period_label.text == "March 1800")
	screen.pause_button.pressed.emit()
	assert(not screen.game_clock.is_playing)
	await process_frame
	await process_frame
	var point: Vector2 = screen.play_button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion)
	assert(root.gui_get_hovered_control() == screen.play_button, "Play is reachable by mouse")
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.pressed = down
		root.push_input(click)
	assert(screen.game_clock.is_playing, "Real mouse input starts playback")
	await create_timer(16).timeout
	assert(screen.period_label.text == "April 1800", "Live frame processing advances at speed 3")
	assert(screen.clock_status.text.begins_with("Playing"), "Playback status is visible")
	screen.game_clock._last_tick_usec -= 15000000
	screen.game_clock._process(0.001)
	assert(screen.period_label.text == "May 1800", "Clamped frame delta does not slow the clock")
	screen.free()
	print("PASS: monthly clock, state isolation, pause, five speeds, rollover, event interruption, real mouse input, live 15-second advancement, and slow-frame timing")
	quit()
