extends Control

const Reaction = preload("res://Scripts/AssignmentReaction.gd")
const InlinePanel = preload("res://Scripts/InlinePanel.gd")
const TravelScreen = preload("res://Scripts/TravelScreen.gd")
const GameplayScreens = preload("res://Scripts/GameplayScreens.gd")
const Archive = preload("res://Scripts/ArchiveTheme.gd")
const EventPresentation = preload("res://Scripts/EventPresentation.gd")
const PersonStats = preload("res://Scripts/PersonStats.gd")
const PEOPLE_PATH := "res://Data/people.json"
const SaveGame = preload("res://Simulation/SaveGame.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Economy = preload("res://Simulation/Economy.gd")
const PersonPortrait = preload("res://Scripts/PersonPortrait.gd")
const TEXT_MAIN := Color("#392b20")
const TEXT_MUTED := Color("#786b57")
const TEXT_KNOWN := Color("#4d6046")
const TEXT_SUSPECTED := Color("#9a6533")
const TEXT_UNKNOWN := Color("#62707a")
const NAV_TEXT := Color("#f5e4c4")

var people: Dictionary = {}
var details_popup: PanelContainer
var marriage_popup: PopupPanel
var marriage_person_id: String = ""
var marriage_candidate_id: String = ""
var details_content: VBoxContainer
var menu_popup: PopupPanel
var content_overlay: PanelContainer
var page: MarginContainer
var game_clock = Clock.new()
var top_bar: MarginContainer
var period_label: Label
var play_button: Button
var pause_button: Button
var speed_buttons: Array[Button] = []
var house_description: Label
var clock_status: Label
var cash_label: Label
var cohesion_label: Label
var reputation_label: Label
var travel_city_id: String = "florence"
var travel_person_id: String = "Carlo"
var travel_purpose_id: String = "study"
var travel_result: String = ""
var current_screen: String = "People"
var gameplay_result: String = ""
var gameplay_person_id: String = "Giovanni"
var gameplay_activity_id: String = "study"
var gameplay_target_id: String = "rossi"
var village_view: Control
var focus_overlay: Control
var legacy_status: Label
var finance_content: VBoxContainer
var selected_person_id: String = ""
var conversation_result: String = ""
var assignment_feedback: Dictionary = {}
var notification_feed: PanelContainer
var notification_text: Label
var profile_expanded := false
var profile_section := "Activities"
var influence_popup: PopupMenu
var influence_person_id: String = ""
var elsewhere_list: VBoxContainer
var careers_popup: PanelContainer
var careers_content: VBoxContainer
var career_person_id: String = ""
var event_popup: PopupPanel
var event_content: VBoxContainer
var last_event_serial: int = -1
var house_note: Label
var portraits_ready := false
var family_frame: Panel
var month_progress_bar: ProgressBar
const NAV_WIDTH := 192.0


func _ready() -> void:
	theme = Archive.create()
	Input.set_custom_mouse_cursor(load("res://Assets/UI/hand-cursor.svg"), Input.CURSOR_ARROW, Vector2(9, 3))
	Input.set_custom_mouse_cursor(load("res://Assets/UI/hand-cursor.svg"), Input.CURSOR_POINTING_HAND, Vector2(9, 3))
	page = $PageMargins
	_build_archive_surround()
	resized.connect(_update_page_bounds)
	_update_page_bounds()
	_load_people()
	game_clock.state.initialize(people)
	people = game_clock.state.people
	add_child(game_clock)
	_build_time_controls()
	_build_details_popup()
	_build_careers_popup()
	_build_event_popup()
	_build_notification_feed()
	game_clock.month_advanced.connect(_on_month_events)
	_build_influence_menu()
	_build_navigation()
	_build_menu()
	var top_menu: Button = top_bar.get_node("Frame/Header/ClockModule/TimeControls/MenuButton")
	_apply_period_button_style(top_menu)
	top_menu.size_flags_vertical = Control.SIZE_FILL
	top_menu.pressed.connect(_toggle_menu)
	_connect_cards()
	_build_elsewhere_list()
	_refresh_people()
	_update_page_bounds()
	_show_screen("People")
	_show_focus()


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)


func _build_archive_surround() -> void:
	var plaster := TextureRect.new()
	plaster.texture = preload("res://Assets/UI/plaster.svg")
	plaster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaster.stretch_mode = TextureRect.STRETCH_TILE
	plaster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Background.add_child(plaster)
	family_frame = Panel.new()
	family_frame.name = "FamilyArchiveFrame"
	family_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	family_frame.add_theme_stylebox_override("panel", Archive.window_frame())
	add_child(family_frame)
	move_child(family_frame, 1)
	$PageMargins/Page/Concern.add_theme_stylebox_override("panel", Archive.card())
	page.add_theme_constant_override("margin_bottom", 20)
	$PageMargins/Page/Concern/ConcernMargins/ConcernText.add_theme_color_override("font_color", Color("#753e30"))
	$PageMargins/Page/RosterScroll/FamilyList/ImmediateHeading.add_theme_color_override("font_color", TEXT_SUSPECTED)
	$PageMargins/Page/RosterScroll/FamilyList/OtherBranchHeading.add_theme_color_override("font_color", TEXT_SUSPECTED)


func _build_time_controls() -> void:
	var header: HBoxContainer = $PageMargins/Page/Header
	header.get_parent().remove_child(header)
	top_bar = MarginContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 8
	top_bar.offset_bottom = 82
	add_child(top_bar)
	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.add_theme_stylebox_override("panel", Archive.wood_panel())
	top_bar.add_child(frame)
	frame.add_child(header)
	page.add_theme_constant_override("margin_top", 108)
	header.add_theme_constant_override("separation", 9)
	var title: Label = header.get_node("Title")
	title.add_theme_font_override("font", Archive.HEADING)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", NAV_TEXT)
	period_label = header.get_node("Period")
	header.remove_child(period_label)
	var clock_module := VBoxContainer.new()
	clock_module.name = "ClockModule"
	clock_module.add_theme_constant_override("separation", 4)
	header.add_child(clock_module)
	header.move_child(clock_module, header.get_node("MenuButton").get_index())
	var date_row := HBoxContainer.new()
	date_row.add_theme_constant_override("separation", 8)
	clock_module.add_child(date_row)
	date_row.add_child(period_label)
	period_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	period_label.add_theme_font_override("font", Archive.HEADING)
	period_label.add_theme_font_size_override("font_size", 15)
	period_label.add_theme_color_override("font_color", NAV_TEXT)
	var summaries := HBoxContainer.new()
	summaries.name = "FamilySummary"
	summaries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summaries.add_theme_constant_override("separation", 14)
	header.add_child(summaries)
	header.move_child(summaries, title.get_index() + 1)
	header.get_node("HeaderSpacer").hide()
	cash_label = _add_header_stat(summaries, "FAMILY PURSE")
	cohesion_label = _add_header_stat(summaries, "COHESION")
	reputation_label = _add_header_stat(summaries, "REPUTATION")
	cash_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var controls := HBoxContainer.new()
	controls.name = "TimeControls"
	controls.add_theme_constant_override("separation", 2)
	clock_module.add_child(controls)
	play_button = _add_time_button(controls, "▶", _play_game)
	play_button.tooltip_text = "Play — advance one month at a time"
	pause_button = _add_time_button(controls, "Ⅱ", game_clock.pause)
	pause_button.tooltip_text = "Pause — preserve the current month"
	for level in range(1, 6):
		var button := _add_time_button(controls, "x%d" % level, game_clock.set_speed.bind(level))
		button.tooltip_text = "Speed preset %d · %s seconds per month" % [level, str(Clock.SECONDS_PER_MONTH[level - 1])]
		speed_buttons.append(button)
	var menu_button: Button = header.get_node("MenuButton")
	header.remove_child(menu_button)
	menu_button.custom_minimum_size = Vector2(64, 28)
	controls.add_child(menu_button)
	month_progress_bar = ProgressBar.new()
	month_progress_bar.custom_minimum_size = Vector2(0, 3)
	month_progress_bar.show_percentage = false
	month_progress_bar.max_value = 1.0
	month_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#2a1c14")
	month_progress_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#c0a46a")
	month_progress_bar.add_theme_stylebox_override("fill", fill)
	clock_module.add_child(month_progress_bar)
	clock_status = _add_label(clock_module, "Paused", 12, NAV_TEXT)
	clock_status.hide()
	game_clock.month_advanced.connect(_refresh_time_controls)
	game_clock.playback_changed.connect(_refresh_time_controls)
	_refresh_time_controls()


func _add_time_button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(34, 28)
	button.toggle_mode = true
	button.add_theme_color_override("font_color", TEXT_MAIN)
	_apply_period_button_style(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _refresh_time_controls() -> void:
	_refresh_notifications()
	period_label.text = game_clock.state.date_text()
	cash_label.text = game_clock.state.economy.money(game_clock.state.economy.cash_cents)
	cash_label.tooltip_text = "Shared family purse, in the current historical currency."
	_refresh_family_summary()
	cash_label.add_theme_color_override("font_color", Color("#e09a81") if game_clock.state.economy.cash_cents < 0 else Color("#d9c28c"))
	if is_instance_valid(finance_content):
		_refresh_finances()
	period_label.tooltip_text = "%s · Speed %d · %s seconds per month" % ["Playing" if game_clock.is_playing else "Paused", game_clock.speed_level, str(game_clock.seconds_per_month())]
	play_button.set_pressed_no_signal(game_clock.is_playing)
	pause_button.set_pressed_no_signal(not game_clock.is_playing)
	for index in range(speed_buttons.size()):
		speed_buttons[index].set_pressed_no_signal(index + 1 == game_clock.speed_level)
	if is_instance_valid(house_description):
		house_description.text = _house_summary()
		if is_instance_valid(house_note):
			house_note.text = "Rooms: " + ", ".join(game_clock.state.household["rooms"])
	_refresh_legacy()
	if current_screen in ["Italy", "Family Tree"]:
		_show_screen(current_screen)
	elif current_screen == "Village" and is_instance_valid(village_view):
		village_view.refresh()
	_refresh_clock_status()
	_refresh_event_notice()
	_refresh_people()
	if is_instance_valid(marriage_popup) and marriage_popup.visible:
		preload("res://Scripts/PersonMarriage.gd").open_candidates(self, marriage_person_id)
	if details_popup != null and details_popup.visible and not selected_person_id.is_empty():
		_show_person(selected_person_id, false)
	if careers_popup != null and careers_popup.visible and not career_person_id.is_empty():
		_show_careers(career_person_id, false)


func _refresh_people() -> void:
	if portraits_ready:
		_add_missing_cards(true)
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	var count := 0
	var branches: Dictionary = {}
	for card in family_list.get_children():
		if not (card is PanelContainer) or not people.has(str(card.name)):
			continue
		var person = people[str(card.name)]
		card.visible = person.alive and person.id in game_clock.state.household["members"]
		if card.visible:
			count += 1
			branches[person.branch_id] = true
		card.get_node("Row/Details/Name").text = "%s · %d" % [person.name, person.age]
		card.get_node("Row/Details/Role").text = str(person.view_for(game_clock.state.head_id)["relationship"]).get_slice("·", 0).strip_edges() + " · " + person.job
		PersonStats.refresh(self, card, person)
		var face := card.get_node_or_null("Row/Portrait/Face")
		if face != null:
			face.show_person(person)
	$PageMargins/Page/RosterHeading/Count.text = "%d people  ·  %d branches" % [count, branches.size()]
	if elsewhere_list != null:
		var outside_count := 0
		for card in elsewhere_list.get_children():
			var person = people[str(card.name)]
			card.visible = person.alive and person.id not in game_clock.state.household["members"]
			card.get_node("Row/Details/Name").text = "%s · %d" % [person.name, person.age]
			var location: String = game_clock.state.travel.location_text(person.id)
			card.get_node("Row/Details/Role").text = person.job + (" · " + location if not location.is_empty() else " · Living elsewhere")
			PersonStats.refresh(self, card, person)
			card.get_node("Row/Portrait/Face").show_person(person)
			if card.visible:
				outside_count += 1
		$PageMargins/Page/RosterScroll/FamilyList/ElsewhereHeading.visible = outside_count > 0
		elsewhere_list.visible = outside_count > 0


func _process(_delta: float) -> void:
	if clock_status != null:
		_refresh_clock_status()


func _refresh_clock_status() -> void:
	if game_clock.is_playing:
		var remaining := maxf(0.0, (1.0 - game_clock.month_progress) * game_clock.seconds_per_month())
		clock_status.text = "Playing · next month in %ds" % int(ceil(remaining))
	else:
		clock_status.text = "Paused · press ▶ to play"
	if month_progress_bar != null:
		month_progress_bar.value = game_clock.month_progress
		month_progress_bar.tooltip_text = clock_status.text
		play_button.tooltip_text = clock_status.text


func _update_page_bounds() -> void:
	var available_width := maxf(0.0, size.x - NAV_WIDTH - 24.0)
	var page_width := available_width
	var left := NAV_WIDTH + 12.0 + (available_width - page_width) / 2.0
	page.offset_left = left
	page.offset_right = left + page_width
	if family_frame != null:
		family_frame.position = Vector2(left, 92)
		family_frame.size = Vector2(page_width, maxf(0.0, size.y - 104))
	if content_overlay != null:
		content_overlay.offset_left = left
		content_overlay.offset_right = left + page_width - size.x
	for panel in [details_popup, careers_popup]:
		if is_instance_valid(panel) and panel.visible: panel.popup_centered(Vector2i(panel.size))
	_refresh_notifications()
	if top_bar != null:
		top_bar.offset_left = left
		top_bar.offset_right = left + page_width - size.x


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(focus_overlay) and focus_overlay.visible:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if details_popup != null and details_popup.visible:
			details_popup.hide()
		else:
			_toggle_menu()
		get_viewport().set_input_as_handled()


func _build_navigation() -> void:
	var rail := PanelContainer.new()
	rail.name = "Navigation"
	rail.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rail.offset_right = NAV_WIDTH
	rail.add_theme_stylebox_override("panel", Archive.wood_panel())
	add_child(rail)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	rail.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	margin.add_child(list)
	var masthead := _add_label(list, "THE LANDI\nFAMILY", 24, NAV_TEXT)
	masthead.add_theme_font_override("font", Archive.HEADING)
	_add_label(list, "TUSCAN COUNTRYSIDE", 12, Color("#d4b77e"))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	list.add_child(spacer)
	_add_navigation_button(list, "People", "People", true)
	_add_navigation_button(list, "Albero genealogico", "Family Tree")
	_add_navigation_button(list, "Landi House", "House")
	_add_navigation_button(list, "Village", "Village")
	_add_navigation_button(list, "Italy", "Italy")
	_add_navigation_button(list, "Finances", "Finances")
	_add_navigation_button(list, "Chronicle", "Chronicle")
	_add_navigation_button(list, "Events", "Events")
	legacy_status = _add_label(list, "", 13, Color("#d4b77e"))
	var art_spacer := Control.new()
	art_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_child(art_spacer)
	var engraving := TextureRect.new()
	engraving.texture = load("res://Assets/ancestral-house-engraving.png")
	engraving.custom_minimum_size = Vector2(0, 150)
	engraving.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	engraving.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	engraving.modulate = Color("#dac08d")
	engraving.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(engraving)
	_add_label(list, "LANDI HOUSE · TUSCANY", 11, Color("#d4b77e"))


func _add_navigation_button(parent: VBoxContainer, caption: String, screen_name: String, selected := false) -> void:
	var button := Button.new()
	button.text = caption
	button.toggle_mode = true
	button.button_pressed = selected
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 32)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", NAV_TEXT)
	_apply_period_button_style(button, true)
	if selected:
		button.add_theme_color_override("font_color", Color("#ffd98d"))
	button.pressed.connect(_show_screen.bind(screen_name))
	parent.add_child(button)


func _show_screen(screen_name: String) -> void:
	current_screen = screen_name
	family_frame.visible = screen_name in ["People", "Events"]
	for button in get_node("Navigation").find_children("*", "Button", true, false):
		button.set_pressed_no_signal(button.text == screen_name or (screen_name == "Family Tree" and button.text == "Albero genealogico"))
	details_popup.hide()
	if is_instance_valid(marriage_popup): marriage_popup.hide()
	careers_popup.hide()
	influence_popup.hide()
	if screen_name == "Events":
		page.visible = true
		if content_overlay != null:
			content_overlay.hide()
		_show_pending_event()
		return
	if screen_name == "People":
		page.visible = true
		if content_overlay != null:
			content_overlay.hide()
		return
	page.visible = false
	if content_overlay == null:
		content_overlay = PanelContainer.new()
		content_overlay.name = "ContentOverlay"
		content_overlay.add_theme_stylebox_override("panel", Archive.window_frame())
		add_child(content_overlay)
	content_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_overlay.offset_left = NAV_WIDTH + 12
	content_overlay.offset_top = 92
	content_overlay.offset_right = -12
	content_overlay.offset_bottom = -12
	for child in content_overlay.get_children():
		content_overlay.remove_child(child)
		child.queue_free()
	finance_content = null
	if screen_name == "Italy":
		TravelScreen.build(self)
		content_overlay.show()
		return
	if screen_name == "Village":
		GameplayScreens.village(self)
		content_overlay.show()
		return
	if screen_name == "Portraits":
		preload("res://Scripts/StrangerPortraitPreview.gd").build(self)
		content_overlay.show()
		return
	if screen_name == "Family Tree":
		preload("res://Scripts/FamilyTree.gd").build(self)
		content_overlay.show()
		return
	if screen_name == "House":
		_build_house_screen()
		content_overlay.show()
		return
	if screen_name == "Finances":
		_build_finances_screen()
		content_overlay.show()
		return
	if screen_name == "Chronicle":
		_build_chronicle_screen()
		content_overlay.show()
		return
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	content_overlay.add_child(column)
	_add_label(column, screen_name, 34, TEXT_MAIN)
	_add_label(column, "This screen is empty for now.", 17, TEXT_MUTED)
	content_overlay.show()


func _play_game() -> void:
	if game_clock.state.legacy.objective_id.is_empty():
		_show_focus()
		return
	game_clock.play()


func _show_focus() -> void:
	if not game_clock.state.legacy.objective_id.is_empty():
		if is_instance_valid(focus_overlay):
			focus_overlay.hide()
		return
	game_clock.pause()
	if is_instance_valid(focus_overlay):
		focus_overlay.show()
		return
	focus_overlay = Control.new()
	focus_overlay.name = "StartingFocus"
	focus_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_overlay.z_index = InlinePanel.OVERLAY_Z_INDEX
	focus_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(focus_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.09, 0.06, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 0)
	panel.add_theme_stylebox_override("panel", Archive.card())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 1032
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var legacy = game_clock.state.legacy
	var selected := {"objective": "", "bonus": ""}
	var objective_buttons: Array[Button] = []
	var bonus_buttons: Array[Button] = []
	_add_label(column, "What will your family be remembered for?", 30, TEXT_MAIN)
	_add_label(column, "One century. Three ambitions. Choose a legacy, then a lasting family perk.", 16, TEXT_MUTED)
	var images := ["family", "wealth", "influence"]
	var flavor := ["A house full of voices. A name carried by generations yet to come.", "From a modest purse to a fortune that outlives its founders.", "A family whose voices reach beyond the village, into the halls of power."]
	var row := HBoxContainer.new()
	row.name = "ObjectiveCards"
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for index in legacy.OBJECTIVES.size():
		var key: String = legacy.OBJECTIVES.keys()[index]
		var button := _add_focus_card(row, legacy.OBJECTIVES[key], flavor[index], images[index], "Choose this legacy", 164)
		objective_buttons.append(button)
	_add_label(column, "A gift for the generations", 23, TEXT_SUSPECTED)
	var perk_row := HBoxContainer.new()
	perk_row.name = "PerkCards"
	perk_row.add_theme_constant_override("separation", 8)
	column.add_child(perk_row)
	var perk_flavor := ["Let the next generation fill the house with life.", "Every coin saved is a little more security for tomorrow.", "What one generation learns, the next can build upon."]
	for index in legacy.BONUSES.size():
		var key: String = legacy.BONUSES.keys()[index]
		var button := _add_focus_card(perk_row, legacy.BONUSES[key], perk_flavor[index], images[index], "Choose this perk", 64)
		bonus_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	var begin := Button.new()
	begin.name = "BeginFamilyStory"
	begin.text = "Begin family story"
	begin.custom_minimum_size.y = 28
	begin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	begin.disabled = true
	actions.add_child(begin)
	begin.pressed.connect(func(): _start_family_story(selected["objective"], selected["bonus"]))
	_add_menu_button(actions, "Load saved family", _load_game)
	var portrait_test := Button.new()
	portrait_test.name = "StartStrangerPortraitTest"
	portrait_test.text = "Start with 100 strangers"
	portrait_test.pressed.connect(func(): preload("res://Scripts/StrangerPortraitPreview.gd").start(self))
	actions.add_child(portrait_test)
	for index in objective_buttons.size():
		var button := objective_buttons[index]
		var key: String = legacy.OBJECTIVES.keys()[index]
		button.pressed.connect(func():
			selected["objective"] = key
			for other in objective_buttons:
				other.set_pressed_no_signal(other == button)
				other.text = "Legacy selected" if other == button else "Choose this legacy"
			begin.disabled = selected["bonus"].is_empty())
	for index in bonus_buttons.size():
		var button := bonus_buttons[index]
		var key: String = legacy.BONUSES.keys()[index]
		button.pressed.connect(func():
			selected["bonus"] = key
			for other in bonus_buttons:
				other.set_pressed_no_signal(other == button)
				other.text = "Perk selected" if other == button else "Choose this perk"
			begin.disabled = selected["objective"].is_empty())
	# Trap tab navigation inside the mandatory modal.
	var choices: Array[Button] = []
	choices.append_array(objective_buttons)
	choices.append_array(bonus_buttons)
	choices.append(begin)
	choices.append(actions.get_child(1))
	choices.append(portrait_test)
	for index in choices.size():
		choices[index].focus_next = choices[index].get_path_to(choices[(index + 1) % choices.size()])
		choices[index].focus_previous = choices[index].get_path_to(choices[(index - 1 + choices.size()) % choices.size()])
	objective_buttons[0].grab_focus()


func _add_focus_card(parent: Node, entry: Dictionary, flavor: String, image_id: String, caption: String, image_height: int) -> Button:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Archive.card())
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 320
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var picture := TextureRect.new()
	picture.texture = load("res://Assets/Legacy/" + image_id + "-1800.png")
	picture.custom_minimum_size.y = image_height
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	_add_label(column, entry["name"], 22 if image_height > 100 else 19, TEXT_MAIN)
	_add_label(column, flavor, 15, TEXT_SUSPECTED)
	var description := _add_label(column, entry["description"], 14, TEXT_MUTED)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.text = caption
	button.toggle_mode = true
	button.custom_minimum_size.y = 28
	column.add_child(button)
	return button


func _add_header_stat(parent: Node, caption: String) -> Label:
	var column := VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation", 2)
	parent.add_child(column)
	var heading := _add_label(column, caption, 11, Color("#d4b77e"))
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	var value := _add_label(column, "", 18, NAV_TEXT)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	return value


func _refresh_family_summary() -> void:
	# Summaries reflect existing relationships, without exposing acceptance scores.
	var state = game_clock.state
	var connection := 0.0
	var bonds := 0
	for person in state.people.values():
		if not person.alive:
			continue
		for relative_id in person.relationships:
			if not state.people.has(relative_id) or not state.people[relative_id].alive:
				continue
			var bond: Dictionary = person.relationships[relative_id]
			connection += clampf((float(bond.get("affection", 0.5)) + float(bond.get("trust", 0.5))) / 2.0 - float(bond.get("resentment", 0.0)), 0.0, 1.0)
			bonds += 1
	var cohesion := connection / bonds if bonds > 0 else 0.5
	cohesion_label.text = "Close-knit" if cohesion >= 0.65 else ("Steady" if cohesion >= 0.4 else "Strained")
	cohesion_label.tooltip_text = "Family cohesion · a broad impression of affection, trust and unresolved resentment among living relatives."
	var standing := 0.0
	var neighbors := 0
	for family in state.village.households.values():
		var bond: Dictionary = family.relationships.get("landi", {})
		standing += float(bond.get("trust", 0.3)) - float(bond.get("resentment", 0.0))
		neighbors += 1
	standing = standing / neighbors if neighbors > 0 else 0.0
	reputation_label.text = "Respected" if standing >= 0.55 else ("Known" if standing >= 0.25 else "Unproven")
	reputation_label.tooltip_text = "Village reputation · how neighboring families regard the Landi, based on trust and unresolved grievances."


func _add_person_choice(choice: OptionButton, person) -> void:
	var face := PersonPortrait.new()
	face.show_person(person)
	choice.add_icon_item(face.texture, person.name)
	choice.get_popup().set_item_icon_max_width(choice.item_count - 1, 32)
	face.free()


func _start_family_story(objective_id: String, bonus_id: String) -> bool:
	var legacy = game_clock.state.legacy
	if not legacy.choose(objective_id, bonus_id):
		return false
	game_clock.state.economy.price_multiplier = legacy.price_multiplier()
	legacy.evaluate(game_clock.state)
	game_clock.state.chronicle.append({"date": game_clock.state.date_text(), "description": "The family chose " + legacy.OBJECTIVES[legacy.objective_id]["name"] + " with the " + legacy.BONUSES[legacy.bonus_id]["name"] + " bonus."})
	_show_focus()
	_show_screen("People")
	_refresh_time_controls()
	return true


func _refresh_legacy() -> void:
	var legacy = game_clock.state.legacy
	if not is_instance_valid(legacy_status):
		return
	if legacy.objective_id.is_empty():
		legacy_status.text = "Choose your family focus"
		return
	var progress: Dictionary = legacy.progress(game_clock.state)
	legacy_status.text = legacy.OBJECTIVES[legacy.objective_id]["name"] + (" · Achieved" if legacy.completed else "") + "\n" + progress["text"]
	legacy_status.tooltip_text = legacy.OBJECTIVES[legacy.objective_id]["description"] + "\nStarting bonus · " + legacy.BONUSES[legacy.bonus_id]["name"]


func _build_finances_screen() -> void:
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 11)
	content_overlay.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	finance_content = VBoxContainer.new()
	finance_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finance_content.add_theme_constant_override("separation", 7)
	scroll.add_child(finance_content)
	_refresh_finances()


func _finance_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := _add_label(parent, value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _finance_money(amount: int) -> String:
	return game_clock.state.economy.money(amount).replace("lire", "L.")


func _finance_icon(parent: Node, icon_name: String, hint: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load("res://Assets/UI/Icons/" + icon_name + ".svg")
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.tooltip_text = hint
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(icon)
	return icon


func _finance_card(parent: Node, icon_name: String, caption: String, amount: int, hint: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Archive.card())
	panel.tooltip_text = hint
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 5)
	column.add_child(heading)
	_finance_icon(heading, icon_name, hint)
	_finance_label(heading, caption, 17, TEXT_MUTED)
	var value := _finance_label(column, _finance_money(amount), 23, color)
	value.name = caption.replace(" ", "") + "Value"
	value.custom_minimum_size.x = 140
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.tooltip_text = hint


func _finance_section(parent: Node, icon_name: String, caption: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Archive.card())
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 5)
	column.add_child(heading)
	_finance_icon(heading, icon_name, caption)
	_finance_label(heading, caption, 22, TEXT_MAIN)
	column.add_child(HSeparator.new())
	return column


func _refresh_finances() -> void:
	for child in finance_content.get_children():
		finance_content.remove_child(child)
		child.queue_free()
	var state = game_clock.state
	var economy = state.economy
	var budget: Dictionary = economy.budget(state.people, state.household["members"])
	var heading := HBoxContainer.new()
	finance_content.add_child(heading)
	var title := _finance_label(heading, "Finances", 34, TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_finance_label(heading, state.date_text(), 17, TEXT_MUTED)
	_finance_icon(heading, "info", "L. = lire. All money uses this one gameplay currency throughout the run.\nShared household purse: all resident earnings enter this balance.\nFood prices rise by 0.5% per year (monthly increments); wages stay fixed. Other living costs and separate branch purses are not yet simulated.")

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 6)
	finance_content.add_child(summary)
	_finance_card(summary, "wallet", "Balance", economy.cash_cents, "Available household savings", TEXT_SUSPECTED if economy.cash_cents < 0 else TEXT_MAIN)
	_finance_card(summary, "income", "Income", budget["income_cents"], "Expected earnings this month", TEXT_KNOWN)
	_finance_card(summary, "food", "Food", budget["food_cents"], "%d residents × %s per month" % [budget["residents"], economy.money(economy.food_per_person_cents())], TEXT_MAIN)
	_finance_card(summary, "education", "Tuition", budget["tuition_cents"], "Monthly course costs. Planned: " + economy.money(budget["planned_tuition_cents"]), TEXT_MAIN)
	_finance_card(summary, "net", "Monthly net", budget["net_cents"], "Income minus food and funded tuition", TEXT_KNOWN if int(budget["net_cents"]) >= 0 else TEXT_SUSPECTED)
	if economy.cash_cents < 0:
		_finance_notice(finance_content, "Unpaid bills", "The balance is below zero. Time paused when the household first entered debt.")
	if not budget["training_funded"] and int(budget["planned_tuition_cents"]) > 0:
		_finance_notice(finance_content, "Courses paused", "Food takes priority. The household cannot fund " + economy.money(budget["planned_tuition_cents"]) + " in planned tuition.")

	var dowry_owed := 0
	for union in state.marriage.unions.values():
		if union["held_at_home"]: dowry_owed += int(union["capital_cents"])
	if dowry_owed > 0:
		_finance_notice(finance_content, "Dowry owed to resident couples · " + economy.money(dowry_owed), "Included in the shared balance. It must follow couples who leave; spending it can create a future cash shortfall.")
	for family_id in state.marriage.alliances:
		var obligation: int = state.marriage.alliances[family_id]["obligation_cents"]
		if obligation > 0:
			_finance_notice(finance_content, "Favor owed to " + state.village.households[family_id].name, economy.money(obligation) + " · Repay through a person’s Marriage & dote screen.")
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 9)
	finance_content.add_child(columns)
	var residents := _finance_section(columns, "people", "Household income")
	var earnings := GridContainer.new()
	earnings.columns = 2
	earnings.add_theme_constant_override("h_separation", 10)
	earnings.add_theme_constant_override("v_separation", 7)
	residents.add_child(earnings)
	for contribution in budget["contributions"]:
		var person := VBoxContainer.new()
		person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		earnings.add_child(person)
		_finance_label(person, contribution["name"], 18, TEXT_MAIN)
		_finance_label(person, contribution["job"], 14, TEXT_MUTED)
		var amount := _finance_label(earnings, _finance_money(contribution["income_cents"]), 17, TEXT_KNOWN if int(contribution["income_cents"]) > 0 else TEXT_MUTED)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount.custom_minimum_size.x = 170

	var history := _finance_section(columns, "history", "Monthly accounts")
	if economy.ledger.is_empty():
		_finance_label(history, "No settled months yet", 17, TEXT_MUTED)
		var empty_hint := _finance_label(history, "First accounts at the start of next month.", 14, TEXT_MUTED)
		empty_hint.tooltip_text = "Each completed month settles earnings, food and funded tuition."
	else:
		var accounts := GridContainer.new()
		accounts.columns = 3
		accounts.add_theme_constant_override("h_separation", 9)
		accounts.add_theme_constant_override("v_separation", 5)
		history.add_child(accounts)
		_finance_label(accounts, "Month", 14, TEXT_MUTED)
		for item in [["net", "Monthly net"], ["wallet", "Closing balance"]]:
			_finance_icon(accounts, item[0], item[1])
		for index in range(economy.ledger.size() - 1, maxi(-1, economy.ledger.size() - 13), -1):
			var entry: Dictionary = economy.ledger[index]
			var date := _finance_label(accounts, entry["date"], 15, TEXT_MAIN)
			date.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hint := "Income: %s\nFood: %s\nTuition: %s\nNet: %s\nBalance: %s" % [economy.money(entry["income_cents"]), economy.money(entry["food_cents"]), economy.money(entry["tuition_cents"]), economy.money(entry["net_cents"]), economy.money(entry["closing_cents"])]
			date.tooltip_text = hint
			for key in ["net_cents", "closing_cents"]:
				var amount := _finance_label(accounts, _finance_money(entry[key]), 15, TEXT_SUSPECTED if int(entry[key]) < 0 else TEXT_KNOWN)
				amount.custom_minimum_size.x = 140
				amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				amount.tooltip_text = hint

	var commitments: Array = []
	var businesses := _finance_section(finance_content, "income", "Family businesses")
	for building in state.village.development.buildings.values():
		if building["owner_id"] == "landi" and building["type"] in state.village.business.CATALOG and building["status"] != "demolished":
			var estimate: Dictionary = state.village.business.estimate(state, building["id"])
			_finance_label(businesses, "%s · %s · estimated net %s" % [building["address"], estimate["status"], economy.money(estimate["net_cents"])], 16, TEXT_MAIN)
	if not state.village.business.reports.is_empty():
		var report: Dictionary = state.village.business.reports.back()
		for entry in report["rows"]:
			if entry["owner_id"] == "landi":
				_finance_label(businesses, "%s · %s · sales %s · costs %s · net %s" % [report["date"], state.village.development.buildings[entry["building_id"]]["address"], economy.money(entry["revenue_cents"]), economy.money(entry["cost_cents"]), economy.money(entry["net_cents"])], 15, TEXT_MUTED)
	for plan in state.activities.plans.values():
		if plan.status in ["active", "interrupted"]:
			commitments.append(plan)
	if not commitments.is_empty():
		var projects := _finance_section(finance_content, "wallet", "Family project commitments")
		for plan in commitments:
			_finance_label(projects, "%s · %s per active month · %s" % [state.activities.CATALOG[plan.activity_id]["name"], economy.money(economy.purchase_cost(plan.monthly_cost_cents)), plan.status], 16, TEXT_MAIN)
		_finance_label(projects, "Paid after household bills. Progress pauses when funds are unavailable.", 14, TEXT_MUTED)
	var events = state.events
	for effect in events.active:
		var hint: String = "Food prices ×%.2f · Wages and sales ×%.2f\nFarm output ×%.2f · Business costs ×%.2f" % [effect["food_multiplier"],effect["income_multiplier"],effect.get("farm_multiplier",1.0),effect.get("business_cost_multiplier",1.0)]
		if effect.get("travel_until_month",-1) > state.elapsed_months:
			hint += "\nTransport disrupted for %d more months." % (effect["travel_until_month"]-state.elapsed_months)
		_finance_notice(residents, "%s · %d months" % [str(effect["kind"]).capitalize(), maxi(0, int(effect["until_month"]) - state.elapsed_months)], hint)
	if not events.transactions.is_empty():
		var transactions := _finance_section(finance_content, "wallet", "Payments and sales")
		for entry in events.transactions.slice(maxi(0, events.transactions.size() - 8)):
			var row := HBoxContainer.new()
			transactions.add_child(row)
			var description := _finance_label(row, entry["description"], 15, TEXT_MAIN)
			description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			description.tooltip_text = entry["date"]
			_finance_label(row, _finance_money(entry["amount_cents"]), 15, TEXT_SUSPECTED if int(entry["amount_cents"]) < 0 else TEXT_KNOWN)


func _finance_notice(parent: Node, caption: String, hint: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	_finance_icon(row, "warning", hint)
	var label := _finance_label(row, caption, 17, TEXT_SUSPECTED)
	label.tooltip_text = hint


func _build_house_screen() -> void:
	var page_column := VBoxContainer.new()
	page_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	page_column.add_theme_constant_override("separation", 7)
	content_overlay.add_child(page_column)
	_add_label(page_column, "Landi House", 34, TEXT_MAIN)
	house_description = _add_label(page_column, _house_summary(), 16, TEXT_MUTED)

	var rule := HSeparator.new()
	rule.add_theme_constant_override("separation", 4)
	page_column.add_child(rule)

	var rooms := HBoxContainer.new()
	rooms.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rooms.add_theme_constant_override("separation", 9)
	page_column.add_child(rooms)
	_add_house_module(rooms, "Bedroom", "Shared bedroom  ·  Capacity: 2", "res://Assets/House/bedroom-01.png")
	_add_house_module(rooms, "Kitchen", "Hearth and family table", "res://Assets/House/kitchen-01.png")
	_add_house_module(rooms, "Outdoor washroom", "Cold water  ·  Outside", "res://Assets/House/outdoor-washroom-01.png")

	house_note = _add_label(page_column, "Rooms: " + ", ".join(game_clock.state.household["rooms"]), 14, TEXT_MUTED)
	house_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_house_module(parent: HBoxContainer, title: String, subtitle: String, asset_path: String) -> void:
	var module := VBoxContainer.new()
	module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module.add_theme_constant_override("separation", 4)
	parent.add_child(module)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 180)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", Archive.card())
	module.add_child(frame)

	var image := TextureRect.new()
	image.texture = load(asset_path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(image)
	_add_label(module, title, 20, TEXT_MAIN)
	_add_label(module, subtitle, 14, TEXT_MUTED)


func _build_menu() -> void:
	menu_popup = PopupPanel.new()
	menu_popup.name = "GameMenu"
	menu_popup.add_theme_stylebox_override("panel", Archive.window_frame())
	add_child(menu_popup)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	menu_popup.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	margin.add_child(list)
	_add_label(list, "GAME MENU", 15, TEXT_SUSPECTED)
	_add_menu_button(list, "Save", _save_game)
	_add_menu_button(list, "Load", _load_game)
	_add_menu_button(list, "Settings", _show_menu_message.bind("Settings will be added here."))
	_add_menu_button(list, "Exit", _exit_game)


func _add_menu_button(parent: Container, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(180, 28)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	_apply_period_button_style(button)
	button.pressed.connect(action)
	parent.add_child(button)


func _apply_period_button_style(button: Button, _dark := false) -> void:
	Archive.style_button(button)


func _toggle_menu() -> void:
	if menu_popup.visible:
		menu_popup.hide()
	else:
		var menu_button: Button = top_bar.get_node("Frame/Header/ClockModule/TimeControls/MenuButton")
		var menu_size := Vector2i(300, 330)
		var position := Vector2i(menu_button.global_position.x + menu_button.size.x - menu_size.x, menu_button.global_position.y + menu_button.size.y + 8)
		position.x = clampi(position.x, 16, int(get_viewport_rect().size.x) - menu_size.x - 16)
		position.y = clampi(position.y, 16, int(get_viewport_rect().size.y) - menu_size.y - 16)
		menu_popup.popup(Rect2i(position, menu_size))


func _show_menu_message(message: String) -> void:
	menu_popup.hide()
	_show_screen("People")
	var dialog := AcceptDialog.new()
	dialog.title = "Game menu"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(410, 180))


func _save_game() -> void:
	var error: String = SaveGame.save_game(game_clock)
	_show_menu_message(error if not error.is_empty() else "Saved the family in " + game_clock.state.date_text() + ".")


func _load_game() -> void:
	var error: String = SaveGame.load_game(game_clock)
	if not error.is_empty():
		_show_menu_message(error)
		return
	event_popup.hide()
	last_event_serial = -1
	assignment_feedback.clear()
	people = game_clock.state.people
	selected_person_id = ""
	career_person_id = ""
	conversation_result = ""
	gameplay_result = ""
	travel_result = ""
	influence_person_id = ""
	# Hide cards for people added after this save, retaining reusable scene cards.
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	for card in family_list.get_children():
		if card is PanelContainer and not people.has(str(card.name)):
			family_list.remove_child(card)
			card.queue_free()
	for card in elsewhere_list.get_children():
		if not people.has(str(card.name)):
			elsewhere_list.remove_child(card)
			card.queue_free()
	_show_screen("People")
	_refresh_time_controls()
	_show_focus()
	_show_menu_message("Loaded the family in " + game_clock.state.date_text() + ". Time is paused.")
	if not game_clock.state.events.pending.is_empty():
		call_deferred("_show_pending_event")


func _exit_game() -> void:
	get_tree().quit()


func _load_people() -> void:
	var file := FileAccess.open(PEOPLE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open " + PEOPLE_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Personality data is not a JSON object: " + PEOPLE_PATH)
		return
	people = parsed


func _connect_cards() -> void:
	_add_missing_cards(false)
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	for child in family_list.get_children():
		if child is PanelContainer and people.has(str(child.name)):
			_configure_card(child)
	portraits_ready = true


func _add_missing_cards(connect_now: bool) -> void:
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	# The initial scene is an authored layout, but new profiles need no scene edits.
	for person_id in people:
		if family_list.has_node(NodePath(person_id)):
			continue
		if not family_list.has_node("OtherRelativesHeading"):
			var heading := _add_label(family_list, "OTHER RELATIVES", 15, TEXT_MUTED)
			heading.name = "OtherRelativesHeading"
		var template: PanelContainer = family_list.get_node("Giovanni")
		var new_card: PanelContainer = template.duplicate(0)
		new_card.name = person_id
		family_list.add_child(new_card)
		if connect_now:
			_configure_card(new_card)
			var outside_card: PanelContainer = new_card.duplicate(Node.DUPLICATE_SCRIPTS)
			outside_card.get_node("Row/Portrait/Face").material = outside_card.get_node("Row/Portrait/Face").material.duplicate()
			elsewhere_list.add_child(outside_card)
			_bind_card_input(outside_card)


func _configure_card(card: PanelContainer) -> void:
	card.add_theme_stylebox_override("panel", Archive.card())
	_apply_card_paper_colours(card)
	_install_portrait(card.get_node("Row/Portrait"), people[str(card.name)], 56)
	_ignore_child_mouse(card)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_ALL
	_bind_card_input(card)


func _bind_card_input(card: PanelContainer) -> void:
	card.gui_input.connect(_on_card_input.bind(str(card.name)))
	card.mouse_entered.connect(_set_card_highlight.bind(card, true))
	card.mouse_exited.connect(_set_card_highlight.bind(card, false))
	card.focus_entered.connect(_set_card_highlight.bind(card, true))
	card.focus_exited.connect(_set_card_highlight.bind(card, false))


func _apply_card_paper_colours(card: PanelContainer) -> void:
	var name_label: Label = card.get_node("Row/Details/Name")
	var role: Label = card.get_node("Row/Details/Role")
	name_label.add_theme_color_override("font_color", TEXT_MAIN)
	role.add_theme_color_override("font_color", TEXT_MUTED)


func _install_portrait(frame: PanelContainer, model: RefCounted, width: int) -> void:
	var previous := frame.get_node_or_null("Face")
	if previous != null:
		frame.remove_child(previous)
		previous.queue_free()
	var initials := frame.get_node_or_null("Initials")
	if initials != null:
		frame.remove_child(initials)
		initials.queue_free()
	frame.custom_minimum_size = Vector2(width, width)
	frame.add_theme_stylebox_override("panel", Archive.box(Archive.PORTRAIT, 14, 4))
	var portrait := PersonPortrait.new()
	frame.add_child(portrait)
	portrait.show_person(model)


func _ignore_child_mouse(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_child_mouse(child)


func _set_card_highlight(card: PanelContainer, active: bool) -> void:
	card.modulate = Color("#fff3d9") if active else Color.WHITE


func _on_card_input(event: InputEvent, person_id: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_person(person_id)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_open_influence_menu(person_id)
	elif event is InputEventKey:
		if event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_show_person(person_id)
		elif event.pressed and not event.echo and event.keycode == KEY_MENU:
			_open_influence_menu(person_id)


func _build_details_popup() -> void:
	details_popup = InlinePanel.new()
	details_popup.hide()
	details_popup.name = "PersonDetails"
	details_popup.add_theme_stylebox_override("panel", Archive.window_frame())
	add_child(details_popup)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 11)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_right", 11)
	margins.add_theme_constant_override("margin_bottom", 10)
	details_popup.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)

	details_content = VBoxContainer.new()
	details_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_content.add_theme_constant_override("separation", 6)
	scroll.add_child(details_content)


func _show_person(person_id: String, open_popup: bool = true) -> void:
	if not people.has(person_id):
		return
	if selected_person_id != person_id:
		conversation_result = ""
		gameplay_result = ""
		profile_expanded = false
		profile_section = "Activities"
	selected_person_id = person_id
	gameplay_person_id = person_id
	for child in details_content.get_children():
		details_content.remove_child(child)
		child.queue_free()
	preload("res://Scripts/PersonProfile.gd").build(self, person_id)
	if open_popup:
		var viewport_size := get_viewport_rect().size
		details_popup.popup_centered(Vector2i(int(minf(760.0,viewport_size.x-32)),int(minf(580.0 if profile_expanded else 360.0,viewport_size.y-32))))

	elif details_popup.visible:
		var height := 580 if profile_expanded else 360
		var dimensions := Vector2i(int(minf(760,get_viewport_rect().size.x-32)),int(minf(height,get_viewport_rect().size.y-32)))
		if details_popup.size != Vector2(dimensions):
			details_popup.popup_centered(dimensions)


func _open_person_activity(activity_id: String = "", target_id: String = "") -> void:
	var person_id: String = gameplay_person_id
	if not people.has(person_id) or not people[person_id].alive or not people[person_id].in_household or people[person_id].age < 18:
		person_id = game_clock.state.head_id
	_show_person(person_id)
	if not activity_id.is_empty():
		gameplay_activity_id = activity_id
	if not target_id.is_empty():
		gameplay_target_id = target_id
	profile_expanded = true
	profile_section = "Activities"
	_show_person(person_id,false)


func _talk_to_person(person_id: String) -> void:
	var state = game_clock.state
	conversation_result = people[person_id].converse(state.head_id, state.elapsed_months, state.date_text())
	_show_person(person_id, false)


func _build_influence_menu() -> void:
	influence_popup = PopupMenu.new()
	influence_popup.theme = theme
	influence_popup.name = "InfluenceMenu"
	influence_popup.add_theme_font_size_override("font_size", 14)
	add_child(influence_popup)
	influence_popup.id_pressed.connect(_on_influence_selected)


func _open_influence_menu(person_id: String) -> void:
	influence_person_id = person_id
	influence_popup.clear()
	influence_popup.add_item("About " + people[person_id].name, 0)
	influence_popup.add_item("Education & careers…", 100)
	influence_popup.add_separator("Requests")
	var index := 1
	for action in game_clock.state.Influence.ACTIONS:
		var reason: String = game_clock.state.Influence.unavailable_reason(game_clock.state, person_id, action)
		influence_popup.add_item(game_clock.state.Influence.ACTIONS[action], index)
		var item_index := influence_popup.get_item_index(index)
		influence_popup.set_item_metadata(item_index, action)
		influence_popup.set_item_disabled(item_index, not reason.is_empty())
		influence_popup.set_item_tooltip(item_index, reason if not reason.is_empty() else ("Ask them to seek a partner; marriage needs their own choice and a willing partner." if action == "marry" else "Make a request. Their wishes and relationship with you shape their answer."))
		index += 1
	influence_popup.position = Vector2i(get_viewport().get_mouse_position())
	influence_popup.popup()


func _on_influence_selected(item_id: int) -> void:
	if item_id == 100:
		_show_careers(influence_person_id)
		return
	if item_id == 0:
		_show_person(influence_person_id)
		return
	var action: String = influence_popup.get_item_metadata(influence_popup.get_item_index(item_id))
	_make_request(influence_person_id, action)


func _make_request(person_id: String, action: String) -> void:
	if action in ["leave", "join", "marry"]: game_clock.pause()
	var result: Dictionary = game_clock.state.request(person_id, action)
	if action.begins_with("train:") or action.begins_with("work:"):
		Reaction.remember(self, result, person_id, action)
		_show_careers(person_id, not careers_popup.visible)
	else:
		Reaction.remember(self, result, person_id, "request")
		if selected_person_id != person_id or not details_popup.visible: _show_person(person_id)
		_show_person(person_id, false)
	_refresh_people()
	if is_instance_valid(finance_content): _refresh_finances()


func _build_careers_popup() -> void:
	careers_popup = InlinePanel.new()
	careers_popup.hide()
	careers_popup.name = "EducationAndCareers"
	careers_popup.add_theme_stylebox_override("panel", details_popup.get_theme_stylebox("panel").duplicate())
	add_child(careers_popup)
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 10)
	careers_popup.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	careers_content = VBoxContainer.new()
	careers_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	careers_content.add_theme_constant_override("separation", 7)
	scroll.add_child(careers_content)


func _show_careers(person_id: String, open_popup: bool = true) -> void:
	if open_popup:
		details_popup.hide()
	career_person_id = person_id
	for child in careers_content.get_children():
		careers_content.remove_child(child)
		child.queue_free()
	var state = game_clock.state
	var model = people[person_id]
	var view: Dictionary = model.career_view_for(state.head_id)
	var header := HBoxContainer.new()
	careers_content.add_child(header)
	var title := _add_label(header, model.name + " · Education & careers", 26, TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(careers_popup.hide)
	header.add_child(close)
	_add_label(careers_content, "Education: " + str(model.education["level"]).capitalize() + " · Current work: " + model.job, 17, TEXT_MAIN)
	var qualifications: Array = []
	for qualification in model.education["qualifications"]:
		qualifications.append(str(qualification).replace("_", " ").capitalize())
	_add_label(careers_content, "Qualifications: " + (", ".join(qualifications) if not qualifications.is_empty() else "None yet"), 15, TEXT_MUTED)
	var study: Dictionary = model.education["study"]
	if not study.is_empty() and state.careers.programs.has(study.get("program_id")):
		var program: Dictionary = state.careers.programs[study["program_id"]]
		_add_label(careers_content, "%s · %s · %d%% completed · %s/month" % [program["name"], study["status"], int(float(study["progress"]) / float(program["months"]) * 100.0), game_clock.state.economy.money(game_clock.state.economy.purchase_cost(int(program["monthly_cost_cents"])))], 17, TEXT_KNOWN)
	_add_label(careers_content, "Your understanding of their abilities and interests", 21, TEXT_MAIN)
	for layer in ["abilities", "skills", "interests"]:
		var known: Array = []
		for key in view[layer]:
			if view[layer][key] != "Unknown":
				known.append(str(key).replace("_", " ").capitalize() + ": " + view[layer][key])
		_add_label(careers_content, str(layer).capitalize() + ": " + (" · ".join(known) if not known.is_empty() else "Not yet understood"), 15, TEXT_MAIN)
	_add_label(careers_content, "Unobserved abilities remain unknown. Qualifications and practice open careers; personality shapes comfort and interest.", 14, TEXT_MUTED)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 450)
	careers_content.add_child(tabs)
	var study_list := _career_tab(tabs, "Education")
	_add_label(study_list, "Full-time study stops earnings and adds monthly tuition. Courses pause when funding is unavailable. Lengths are estimates; learning pace varies.", 15, TEXT_MUTED)
	for program_id in state.careers.programs:
		var program: Dictionary = state.careers.programs[program_id]
		var action: String = "train:" + program_id
		_add_label(study_list, "%s · roughly %d months · %s/month" % [program["name"], program["months"], game_clock.state.economy.money(game_clock.state.economy.purchase_cost(int(program["monthly_cost_cents"])))], 18, TEXT_MAIN)
		var requirements: String = "Entry education: " + model.EDUCATION_LEVELS[int(program["required_level"])]
		if not program["entry_skills"].is_empty():
			requirements += " · Preparation: " + ", ".join(program["entry_skills"].keys())
		_add_label(study_list, requirements, 14, TEXT_MUTED)
		_career_request_button(study_list, person_id, action)
	var jobs_list := _career_tab(tabs, "Occupations")
	_add_label(jobs_list, "Eligible work can still be refused. This prototype assumes vacancies; independent work also needs the listed resources.", 15, TEXT_MUTED)
	var category := ""
	for job_id in state.careers.jobs:
		var job: Dictionary = state.careers.jobs[job_id]
		if category != job["category"]:
			category = job["category"]
			_add_label(jobs_list, category, 22, TEXT_SUSPECTED)
		_add_label(jobs_list, job["name"] + " · " + game_clock.state.economy.money(job["monthly_income_cents"]) + "/month", 18, TEXT_MAIN)
		var requirements: Array = ["Education: " + model.EDUCATION_LEVELS[int(job["education_level"])]]
		if not str(job["qualification"]).is_empty():
			requirements.append(str(job["qualification"]).replace("_", " ").capitalize())
		requirements.append("Skills: " + ", ".join(job["skills"].keys()))
		if not job["access"].is_empty():
			requirements.append("Access: " + ", ".join(job["access"]))
		_add_label(jobs_list, " · ".join(requirements), 14, TEXT_MUTED)
		_add_label(jobs_list, "Useful abilities: " + ", ".join(job["abilities"].keys()) + " · Helpful traits: " + ", ".join(job["helpful_traits"].keys()).replace("_", " "), 14, TEXT_MUTED)
		_career_request_button(jobs_list, person_id, "work:" + job_id)
	if open_popup:
		careers_popup.popup_centered(Vector2i(int(minf(980, size.x - 32)), int(minf(850, size.y - 32))))


func _career_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	scroll.add_child(column)
	return column


func _career_request_button(parent: VBoxContainer, person_id: String, action: String) -> void:
	var state = game_clock.state
	var reason: String = state.Influence.unavailable_reason(state, person_id, action)
	var button := Button.new()
	button.text = state.careers.request_label(action)
	button.disabled = not reason.is_empty()
	button.tooltip_text = reason
	_apply_period_button_style(button)
	button.pressed.connect(_make_request.bind(person_id, action))
	parent.add_child(button)
	Reaction.build(self, parent, person_id, action)
	if not reason.is_empty():
		_add_label(parent, reason, 14, TEXT_MUTED)


func _build_elsewhere_list() -> void:
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	var heading := _add_label(family_list, "LIVING ELSEWHERE · Still part of your family", 15, TEXT_MUTED)
	heading.name = "ElsewhereHeading"
	elsewhere_list = VBoxContainer.new()
	elsewhere_list.add_theme_constant_override("separation", 6)
	family_list.add_child(elsewhere_list)
	# Duplicate presentation only; connections are bound afresh to each person.
	for person_id in people:
		var card: PanelContainer = family_list.get_node(NodePath(person_id)).duplicate(Node.DUPLICATE_SCRIPTS)
		var face: TextureRect = card.get_node("Row/Portrait/Face")
		face.material = face.material.duplicate()
		elsewhere_list.add_child(card)
		_bind_card_input(card)


func _build_chronicle_screen() -> void:
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 11)
	content_overlay.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	_add_label(column, "Chronicle", 34, TEXT_MAIN)
	if game_clock.state.chronicle.is_empty():
		_add_label(column, "Your requests and their responses will become family history here.", 17, TEXT_MUTED)
	for entry in game_clock.state.chronicle:
		_add_label(column, entry["date"] + " — " + entry["description"], 17, TEXT_MAIN)


func _add_layer(heading: String, layer: Dictionary, parent: Node = null) -> void:
	var panel := _make_section(parent)
	var body := panel.get_child(0) as MarginContainer
	var column := body.get_child(0) as VBoxContainer
	_add_label(column, heading, 21, TEXT_MAIN)
	_add_entries(column, "Known", layer["known"], TEXT_KNOWN)
	_add_entries(column, "Suspected", layer["suspected"], TEXT_SUSPECTED)
	_add_entries(column, "Unknown", layer["unknown"], TEXT_UNKNOWN)


func _add_notes(heading: String, notes: Array, parent: Node = null) -> void:
	var panel := _make_section(parent)
	var body := panel.get_child(0) as MarginContainer
	var column := body.get_child(0) as VBoxContainer
	_add_label(column, heading, 21, TEXT_MAIN)
	for note in notes:
		_add_label(column, "• " + str(note), 15, TEXT_KNOWN)


func _add_entries(parent: VBoxContainer, label: String, entries: Array, color: Color) -> void:
	for entry in entries:
		_add_label(parent, "%s  ·  %s" % [label, entry], 15, color)


func _make_section(parent: Node = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Archive.card())
	(parent if parent != null else details_content).add_child(panel)
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 6)
	margins.add_theme_constant_override("margin_top", 5)
	margins.add_theme_constant_override("margin_right", 6)
	margins.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margins)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margins.add_child(column)
	return panel


func _add_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", Archive.compact_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _add_flavor(parent: Node, value: String, quoted: bool = true) -> Label:
	var label := Label.new()
	label.theme_type_variation = "FlavorText"
	label.text = Archive.flavor_quote(value) if quoted else value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _house_summary() -> String:
	var house: Dictionary = game_clock.state.household
	return "%s · Condition: %d/100 · Capacity: %d · %d rooms" % [game_clock.state.date_text(), int(house.get("condition", 80)), int(house.get("capacity", 7)), house["rooms"].size()]


func _build_event_popup() -> void:
	event_popup = PopupPanel.new()
	event_popup.name = "MonthlyEvent"
	event_popup.add_theme_stylebox_override("panel", Archive.window_frame())
	add_child(event_popup)
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 10)
	event_popup.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	event_content = VBoxContainer.new()
	event_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_content.add_theme_constant_override("separation", 7)
	scroll.add_child(event_content)


func _on_month_events() -> void:
	if not game_clock.state.events.pending.is_empty():
		call_deferred("_show_pending_event")


func _refresh_event_notice() -> void:
	if not is_inside_tree():
		return
	var events = game_clock.state.events
	var notice: Label = $PageMargins/Page/Concern/ConcernMargins/ConcernText
	$PageMargins/Page/Concern.visible = not events.pending.is_empty()
	if not events.pending.is_empty():
		notice.text = "%d event%s awaiting your decision · Open Events to respond. Time is paused." % [events.pending.size(), "" if events.pending.size() == 1 else "s"]
		play_button.disabled = true
	else:
		play_button.disabled = false
		notice.text = ""


func _show_pending_event() -> void:
	if not is_instance_valid(event_popup):
		return
	var state = game_clock.state
	if state.events.pending.is_empty():
		event_popup.hide()
		_refresh_event_notice()
		return
	var event: Dictionary = state.events.pending[0]
	if event_popup.visible and last_event_serial == int(event["serial"]):
		return
	last_event_serial = int(event["serial"])
	game_clock.pause()
	details_popup.hide()
	if is_instance_valid(marriage_popup): marriage_popup.hide()
	careers_popup.hide()
	for child in event_content.get_children():
		event_content.remove_child(child)
		child.queue_free()
	var header := HBoxContainer.new()
	event_content.add_child(header)
	var title := _add_label(header, str(event["title"]), 28, TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var later := Button.new()
	later.text = "Read later"
	later.pressed.connect(event_popup.hide)
	header.add_child(later)
	_add_label(event_content, str(event["date"]) + " · " + str(event["category"]).replace("_", " ").capitalize(), 14, TEXT_MUTED)
	var viewport_size := get_viewport_rect().size
	var columns: BoxContainer = HBoxContainer.new() if viewport_size.x >= 820 else VBoxContainer.new()
	columns.name = "EventColumns"
	columns.add_theme_constant_override("separation", 12)
	event_content.add_child(columns)
	var story := VBoxContainer.new()
	story.name = "Story"
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.size_flags_stretch_ratio = 0.9
	story.add_theme_constant_override("separation", 8)
	columns.add_child(story)
	var illustration := PanelContainer.new()
	illustration.name = "Illustration"
	illustration.custom_minimum_size = Vector2(0, 160)
	illustration.add_theme_stylebox_override("panel", Archive.card())
	story.add_child(illustration)
	# Reserved for event art; intentionally empty during the prototype.
	var paper := ColorRect.new()
	paper.color = Color("#d8c7a5")
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.add_child(paper)
	_add_flavor(story, str(event["body"]))
	var triggered: Array = EventPresentation.consequences(state, event, event.get("on_trigger", {}))
	if not triggered.is_empty():
		_add_label(story, "What happened", 18, TEXT_MAIN)
		EventPresentation.draw_rows(self, story, triggered)
	var actions := VBoxContainer.new()
	actions.name = "Actions"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 6)
	columns.add_child(actions)
	_add_label(actions, "Your response", 20, TEXT_MAIN)
	_add_label(actions, "Time is paused until you decide. %d event%s awaiting a response." % [state.events.pending.size(), "" if state.events.pending.size() == 1 else "s"], 13, TEXT_MUTED)
	for index in range(event["choices"].size()):
		var choice: Dictionary = event["choices"][index]
		var card := PanelContainer.new()
		card.name = "Choice%d" % index
		card.add_theme_stylebox_override("panel", Archive.card())
		actions.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		card.add_child(content)
		var button := Button.new()
		button.text = str(choice["label"])
		button.custom_minimum_size = Vector2(0, 44)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_period_button_style(button)
		var reason: String = state.events.choice_reason(state, event, index)
		button.disabled = not reason.is_empty()
		button.tooltip_text = reason if not reason.is_empty() else str(choice["result"])
		button.pressed.connect(_resolve_event.bind(int(event["serial"]), index))
		content.add_child(button)
		_add_label(content, str(choice["result"]), 14, TEXT_MUTED)
		EventPresentation.draw_rows(self, content, EventPresentation.consequences(state, event, choice["effects"]))
		if not reason.is_empty():
			EventPresentation.draw_rows(self, content, [{"icon": "stress", "text": reason, "tone": -1}])
	event_popup.popup_centered(Vector2i(int(minf(1080, viewport_size.x - 32)), int(minf(800, viewport_size.y - 32))))


func _resolve_event(serial: int, choice: int) -> void:
	var result: Dictionary = game_clock.state.events.resolve(game_clock.state, serial, choice)
	if not result["ok"]:
		last_event_serial = -1
		_show_pending_event()
		return
	event_popup.hide()
	last_event_serial = -1
	people = game_clock.state.people
	_refresh_time_controls()
	if not game_clock.state.events.pending.is_empty():
		call_deferred("_show_pending_event")


func _build_notification_feed() -> void:
	notification_feed = PanelContainer.new()
	notification_feed.name = "FamilyNotifications"
	notification_feed.add_theme_stylebox_override("panel", Archive.card())
	add_child(notification_feed)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	notification_feed.add_child(column)
	notification_text = _add_label(column, "", 15, TEXT_MAIN)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var journal := Button.new()
	journal.text = "Open family journal"
	journal.pressed.connect(_show_screen.bind("Chronicle"))
	actions.add_child(journal)
	var dismiss := Button.new()
	dismiss.text = "Dismiss updates"
	dismiss.pressed.connect(func():
		for notice in game_clock.state.notifications: notice["read"] = true
		_refresh_notifications())
	actions.add_child(dismiss)
	_refresh_notifications()


func _refresh_notifications() -> void:
	if not is_instance_valid(notification_feed): return
	var unread: Array = []
	for notice in game_clock.state.notifications:
		if not notice["read"]: unread.append(notice)
	notification_feed.visible = not unread.is_empty()
	if unread.is_empty(): return
	notification_feed.position = Vector2(NAV_WIDTH + 56, maxf(150, size.y - 190))
	notification_feed.size = Vector2(minf(520, size.x - NAV_WIDTH - 90), 150)
	var lines: Array[String] = ["Family updates · %d unread" % unread.size()]
	for notice in unread.slice(maxi(0, unread.size() - 2)):
		lines.append(str(notice["date"]) + " · " + str(notice["description"]))
	notification_text.text = "\n".join(lines)
	notification_text.max_lines_visible = 5
	notification_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
