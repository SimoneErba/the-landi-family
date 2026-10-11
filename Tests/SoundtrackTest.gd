extends SceneTree

const Audio = preload("res://Scripts/Soundtrack.gd")
const TEST_SETTINGS := "user://soundtrack-test-settings.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var soundtrack = root.get_node("Soundtrack")
	soundtrack.settings_path = TEST_SETTINGS
	soundtrack.set_muted(false)
	soundtrack.set_music_volume(0.62)
	soundtrack.set_ambience_volume(0.28)
	assert(soundtrack.music.playing)
	assert(not soundtrack.ambience.playing)
	for path in Audio.TRACKS:
		var stream = load(path)
		assert(stream is AudioStreamOggVorbis and stream.get_length() > 200.0)
		assert(not stream.loop, "Tracks must finish to begin an ambience interval")
	assert(soundtrack.ambience.stream.get_length() >= Audio.MAX_GAP)
	# The actual finished signal starts the gap, rather than looping the piano.
	soundtrack.music.seek(soundtrack.music.stream.get_length() - 0.1)
	await create_timer(0.5).timeout
	assert(soundtrack.gap_duration >= 30.0 and soundtrack.gap_duration <= 60.0)
	assert(soundtrack.gap_remaining > 0.0)
	assert(not soundtrack.music.playing and soundtrack.ambience.playing)
	# Global scene-tree pauses must not pause the real-time soundtrack.
	paused = true
	var remaining: float = soundtrack.gap_remaining
	await create_timer(0.1, true).timeout
	assert(soundtrack.gap_remaining < remaining)
	paused = false
	soundtrack.set_muted(true)
	assert(soundtrack.ambience.volume_linear == 0.0)
	assert(soundtrack.music.volume_linear == 0.0)
	assert(soundtrack.ambience.playing, "Mute preserves playback position and scheduling")
	var restored := Audio.new()
	restored.settings_path = TEST_SETTINGS
	restored.load_settings()
	assert(restored.muted and is_equal_approx(restored.music_volume, 0.62))
	assert(is_equal_approx(restored.ambience_volume, 0.28))
	restored.free()
	# Fast-forward gaps only in this test. Every track plays once per cycle.
	for expected in [1, 2, 0]:
		soundtrack._process(soundtrack.gap_remaining + 0.1)
		assert(soundtrack.track_index == expected)
		assert(soundtrack.music.playing and not soundtrack.ambience.playing)
		soundtrack._begin_gap()
	# Exercise the real settings UI and saved values through its signals.
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._show_settings()
	await process_frame
	var panel = screen.settings_popup
	assert(panel.visible and not screen.menu_popup.visible)
	panel.music_slider.value = 37
	panel.ambience_slider.value = 21
	panel.mute.button_pressed = false
	assert(is_equal_approx(soundtrack.music_volume, 0.37))
	assert(is_equal_approx(soundtrack.ambience_volume, 0.21) and not soundtrack.muted)
	assert(panel.music_level.text == "37%")
	screen._show_settings()
	assert(screen.settings_popup == panel, "Reopening settings reuses the existing window")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await process_frame
	assert(not panel.visible)
	screen.queue_free()
	await process_frame
	assert(soundtrack.music != null, "Closing screens preserves the soundtrack")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	print("PASS: audio assets, finished transitions, 30–60s gaps, pause independence, playlist cycle, mute, persistence and settings UI")
	quit()
