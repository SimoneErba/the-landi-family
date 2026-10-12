extends Control

const Archive = preload("res://Scripts/ArchiveTheme.gd")
const StartingFamily = preload("res://Simulation/StartingFamily.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const Clock = preload("res://Simulation/GameClock.gd")

var column: VBoxContainer
var menu_panel: PanelContainer
var settings_popup: PanelContainer
var status: Label
var starting_choice := "alone"
var choice_buttons: Array[Button] = []
var opening_family := false

func _ready() -> void:
	theme = Archive.create()
	var background := TextureRect.new()
	background.texture = preload("res://Assets/UI/plaster.svg")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	menu_panel = panel
	panel.add_theme_stylebox_override("panel", Archive.paper_panel(32, 2))
	center.add_child(panel)
	column = VBoxContainer.new()
	column.custom_minimum_size.x = 540
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_show_home()
	menu_panel.item_rect_changed.connect(_align_settings)
	resized.connect(_align_settings)

func _clear() -> void:
	if is_instance_valid(settings_popup): settings_popup.hide()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	choice_buttons.clear()

func _label(caption: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	return label

func _button(caption: String, action: Callable, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 20)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	column.add_child(button)
	return button

func _show_home() -> void:
	_clear()
	_label("TUSCANY · 1800", 16)
	_label("The Landi Family", 42).add_theme_font_override("font", Archive.HEADING)
	_label("One house. One century. Generations of consequences.")
	var new_game := _button("New game", _show_new_game, "NewGame")
	var load_game := _button("Load game", _load_game, "LoadGame")
	load_game.disabled = not FileAccess.file_exists(SaveGame.SAVE_PATH)
	load_game.tooltip_text = "Continue your saved family" if not load_game.disabled else "No saved game yet. Save from the game menu during a run."
	_button("Settings", _show_settings, "Settings")
	_button("Quit", func(): get_tree().quit(), "Quit")
	status = _label("", 16)
	new_game.grab_focus()

func _show_new_game() -> void:
	_clear()
	_label("A new family story", 34)
	_label("Who shares Landi House with you?")
	for key in StartingFamily.OPTIONS:
		var entry: Dictionary = StartingFamily.OPTIONS[key]
		var button := _button(entry["name"], _select_choice.bind(key), key)
		button.toggle_mode = true
		choice_buttons.append(button)
	status = _label("", 18)
	_select_choice(starting_choice)
	_button("Continue · choose your legacy", _start_game, "Continue")
	_button("Back", _show_home, "Back")
	choice_buttons[0].grab_focus()

func _select_choice(choice: String) -> void:
	starting_choice = choice
	for button in choice_buttons:
		button.set_pressed_no_signal(str(button.name) == choice)
	status.text = StartingFamily.OPTIONS[choice]["description"]

func _start_game() -> void:
	if opening_family: return
	opening_family = true
	var screen = preload("res://Scenes/FamilyScreen.tscn").instantiate()
	screen.starting_people = StartingFamily.create_people(starting_choice)
	_open_family.call_deferred(screen)

func _load_game() -> void:
	if opening_family: return
	var clock = Clock.new()
	var error: String = SaveGame.load_game(clock)
	if not error.is_empty():
		clock.free()
		status.text = error
		return
	opening_family = true
	var screen = preload("res://Scenes/FamilyScreen.tscn").instantiate()
	screen.game_clock.free()
	screen.game_clock = clock
	screen.loaded_game = true
	_open_family.call_deferred(screen)

func _open_family(screen: Control) -> void:
	get_tree().root.add_child(screen)
	get_tree().current_scene = screen
	queue_free()

func _show_settings() -> void:
	if not is_instance_valid(settings_popup):
		settings_popup = preload("res://Scripts/AudioSettings.gd").new()
		settings_popup.hide()
		add_child(settings_popup)
		settings_popup.add_theme_stylebox_override("panel", Archive.paper_panel(32, 2))
	settings_popup.show()
	_align_settings()
	settings_popup.mute.grab_focus()

func _align_settings() -> void:
	if is_instance_valid(settings_popup) and settings_popup.visible:
		settings_popup.size = menu_panel.size
		settings_popup.global_position = menu_panel.global_position

func _input(event: InputEvent) -> void:
	if not is_instance_valid(settings_popup) or not settings_popup.visible:
		return
	# Keep keyboard focus in the overlay while the menu remains underneath.
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		var controls: Array[Control] = [settings_popup.find_child("CloseSettings", true, false), settings_popup.mute, settings_popup.music_slider, settings_popup.ambience_slider]
		var focused := get_viewport().gui_get_focus_owner()
		var index := controls.find(focused)
		controls[posmod(index + (-1 if event.shift_pressed else 1), controls.size())].grab_focus()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(settings_popup) and settings_popup.visible:
			settings_popup.hide()
		else:
			_show_home()
		get_viewport().set_input_as_handled()
