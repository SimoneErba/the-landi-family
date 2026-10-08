extends Control

const Archive = preload("res://Scripts/ArchiveTheme.gd")
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
var details_popup: PopupPanel
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
var finance_content: VBoxContainer
var selected_person_id: String = ""
var conversation_result: String = ""
var influence_popup: PopupMenu
var influence_person_id: String = ""
var elsewhere_list: VBoxContainer
var careers_popup: PopupPanel
var careers_content: VBoxContainer
var career_person_id: String = ""
var event_popup: PopupPanel
var event_content: VBoxContainer
var last_event_serial: int = -1
var house_note: Label
var portraits_ready := false
var family_frame: Panel
var month_progress_bar: ProgressBar
const NAV_WIDTH := 260.0


func _ready() -> void:
	theme = Archive.create()
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
	game_clock.month_advanced.connect(_on_month_events)
	_build_influence_menu()
	_build_navigation()
	_build_menu()
	var top_menu: Button = top_bar.get_node("Frame/Header/MenuButton")
	_apply_period_button_style(top_menu)
	top_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_menu.pressed.connect(_toggle_menu)
	_connect_cards()
	_build_elsewhere_list()
	_refresh_people()
	_update_page_bounds()


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
	page.add_theme_constant_override("margin_bottom", 48)
	$PageMargins/Page/Concern/ConcernMargins/ConcernText.add_theme_color_override("font_color", Color("#753e30"))
	$PageMargins/Page/RosterScroll/FamilyList/ImmediateHeading.add_theme_color_override("font_color", TEXT_SUSPECTED)
	$PageMargins/Page/RosterScroll/FamilyList/OtherBranchHeading.add_theme_color_override("font_color", TEXT_SUSPECTED)


func _build_time_controls() -> void:
	var header: HBoxContainer = $PageMargins/Page/Header
	header.get_parent().remove_child(header)
	top_bar = MarginContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 22
	top_bar.offset_bottom = 136
	add_child(top_bar)
	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.add_theme_stylebox_override("panel", Archive.wood_panel())
	top_bar.add_child(frame)
	frame.add_child(header)
	page.add_theme_constant_override("margin_top", 182)
	header.add_theme_constant_override("separation", 18)
	var title: Label = header.get_node("Title")
	title.add_theme_font_override("font", Archive.HEADING)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", NAV_TEXT)
	period_label = header.get_node("Period")
	header.remove_child(period_label)
	var clock_module := VBoxContainer.new()
	clock_module.name = "ClockModule"
	clock_module.add_theme_constant_override("separation", 7)
	header.add_child(clock_module)
	header.move_child(clock_module, header.get_node("MenuButton").get_index())
	var date_row := HBoxContainer.new()
	date_row.add_theme_constant_override("separation", 16)
	clock_module.add_child(date_row)
	date_row.add_child(period_label)
	period_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	period_label.add_theme_font_override("font", Archive.HEADING)
	period_label.add_theme_font_size_override("font_size", 19)
	period_label.add_theme_color_override("font_color", NAV_TEXT)
	cash_label = _add_label(date_row, "", 16, Color("#d9c28c"))
	cash_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var controls := HBoxContainer.new()
	controls.name = "TimeControls"
	controls.add_theme_constant_override("separation", 3)
	clock_module.add_child(controls)
	play_button = _add_time_button(controls, "▶", game_clock.play)
	play_button.tooltip_text = "Play — advance one month at a time"
	pause_button = _add_time_button(controls, "Ⅱ", game_clock.pause)
	pause_button.tooltip_text = "Pause — preserve the current month"
	for level in range(1, 6):
		var button := _add_time_button(controls, "x%d" % level, game_clock.set_speed.bind(level))
		button.tooltip_text = "Speed preset %d · %s seconds per month" % [level, str(Clock.SECONDS_PER_MONTH[level - 1])]
		speed_buttons.append(button)
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
	button.custom_minimum_size = Vector2(44, 36)
	button.toggle_mode = true
	button.add_theme_color_override("font_color", TEXT_MAIN)
	_apply_period_button_style(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _refresh_time_controls() -> void:
	period_label.text = game_clock.state.date_text()
	cash_label.text = game_clock.state.economy.money(game_clock.state.economy.cash_cents)
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
	_refresh_clock_status()
	_refresh_event_notice()
	_refresh_people()
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
		card.get_node("Row/Details/Role").text = person.status_text()
		card.get_node("Row/Details/Observation").text = person.view_for(game_clock.state.head_id)["summary"]
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
			card.get_node("Row/Details/Role").text = person.status_text()
			card.get_node("Row/Details/Observation").text = person.view_for(game_clock.state.head_id)["summary"]
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
	var available_width := maxf(0.0, size.x - NAV_WIDTH - 80.0)
	var page_width := minf(1180.0, available_width)
	var left := NAV_WIDTH + 40.0 + (available_width - page_width) / 2.0
	page.offset_left = left
	page.offset_right = left + page_width
	if family_frame != null:
		family_frame.position = Vector2(left, 150)
		family_frame.size = Vector2(page_width, maxf(0.0, size.y - 174))
	if top_bar != null:
		top_bar.offset_left = left
		top_bar.offset_right = left + page_width - size.x


func _unhandled_key_input(event: InputEvent) -> void:
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
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	rail.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	margin.add_child(list)
	var masthead := _add_label(list, "THE LANDI\nFAMILY", 24, NAV_TEXT)
	masthead.add_theme_font_override("font", Archive.HEADING)
	_add_label(list, "TUSCAN COUNTRYSIDE", 12, Color("#d4b77e"))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	list.add_child(spacer)
	_add_navigation_button(list, "People", "People", true)
	_add_navigation_button(list, "House", "House")
	_add_navigation_button(list, "Finances", "Finances")
	_add_navigation_button(list, "Chronicle", "Chronicle")
	_add_navigation_button(list, "Events", "Events")
	var art_spacer := Control.new()
	art_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_child(art_spacer)
	var engraving := TextureRect.new()
	engraving.texture = load("res://Assets/ancestral-house-engraving.png")
	engraving.custom_minimum_size = Vector2(0, 250)
	engraving.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	engraving.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	engraving.modulate = Color("#dac08d")
	engraving.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(engraving)
	_add_label(list, "LANDI HOME · TUSCANY", 11, Color("#d4b77e"))


func _add_navigation_button(parent: VBoxContainer, caption: String, screen_name: String, selected := false) -> void:
	var button := Button.new()
	button.text = caption
	button.toggle_mode = true
	button.button_pressed = selected
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", NAV_TEXT)
	_apply_period_button_style(button, true)
	if selected:
		button.add_theme_color_override("font_color", Color("#ffd98d"))
	button.pressed.connect(_show_screen.bind(screen_name))
	parent.add_child(button)


func _show_screen(screen_name: String) -> void:
	family_frame.visible = screen_name in ["People", "Events"]
	for button in get_node("Navigation").find_children("*", "Button", true, false):
		button.set_pressed_no_signal(button.text == screen_name)
	details_popup.hide()
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
	content_overlay.offset_left = NAV_WIDTH + 40
	content_overlay.offset_top = 150
	content_overlay.offset_right = -40
	content_overlay.offset_bottom = -24
	for child in content_overlay.get_children():
		content_overlay.remove_child(child)
		child.queue_free()
	finance_content = null
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


func _build_finances_screen() -> void:
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 28)
	content_overlay.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	finance_content = VBoxContainer.new()
	finance_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finance_content.add_theme_constant_override("separation", 14)
	scroll.add_child(finance_content)
	_refresh_finances()


func _finance_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := _add_label(parent, value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _finance_money(amount: int) -> String:
	return game_clock.state.economy.money(amount).replace("lire toscane", "L.").replace("lire italiane", "L.").replace("fiorini", "Fl.")


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
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
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
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
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
	_finance_icon(heading, "info", "L. = lire; Fl. = fiorini; s = soldi; d = denari.\nShared household purse: all resident earnings enter this balance.\nTuscan lire: 20 soldi per lira, 12 denari per soldo.\nFrom 1826: 1 fiorino = 1⅔ Tuscan lire. From November 1859: 1 fiorino = 1.40 Italian lire. Currency changes preserve value.\nFood prices rise by 2% per year (monthly increments); wages stay fixed. Other living costs and separate branch purses are not yet simulated.")

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 12)
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

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	finance_content.add_child(columns)
	var residents := _finance_section(columns, "people", "Household income")
	var earnings := GridContainer.new()
	earnings.columns = 2
	earnings.add_theme_constant_override("h_separation", 20)
	earnings.add_theme_constant_override("v_separation", 14)
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
		accounts.add_theme_constant_override("h_separation", 18)
		accounts.add_theme_constant_override("v_separation", 10)
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

	var events = state.events
	for effect in events.active:
		_finance_notice(residents, "%s · %d months" % [str(effect["kind"]).capitalize(), maxi(0, int(effect["until_month"]) - state.elapsed_months)], "Affects food prices and earnings.")
	if not events.transactions.is_empty():
		var transactions := _finance_section(finance_content, "wallet", "One-off payments")
		for entry in events.transactions.slice(maxi(0, events.transactions.size() - 8)):
			var row := HBoxContainer.new()
			transactions.add_child(row)
			var description := _finance_label(row, entry["description"], 15, TEXT_MAIN)
			description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			description.tooltip_text = entry["date"]
			_finance_label(row, _finance_money(entry["amount_cents"]), 15, TEXT_SUSPECTED if int(entry["amount_cents"]) < 0 else TEXT_KNOWN)


func _finance_notice(parent: Node, caption: String, hint: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	_finance_icon(row, "warning", hint)
	var label := _finance_label(row, caption, 17, TEXT_SUSPECTED)
	label.tooltip_text = hint


func _build_house_screen() -> void:
	var page_column := VBoxContainer.new()
	page_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	page_column.add_theme_constant_override("separation", 14)
	content_overlay.add_child(page_column)
	_add_label(page_column, "The Landi farmhouse", 34, TEXT_MAIN)
	house_description = _add_label(page_column, _house_summary(), 16, TEXT_MUTED)

	var rule := HSeparator.new()
	rule.add_theme_constant_override("separation", 8)
	page_column.add_child(rule)

	var rooms := HBoxContainer.new()
	rooms.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rooms.add_theme_constant_override("separation", 18)
	page_column.add_child(rooms)
	_add_house_module(rooms, "Bedroom", "Shared bedroom  ·  Capacity: 2", "res://Assets/House/bedroom-01.png")
	_add_house_module(rooms, "Kitchen", "Hearth and family table", "res://Assets/House/kitchen-01.png")
	_add_house_module(rooms, "Outdoor washroom", "Cold water  ·  Outside", "res://Assets/House/outdoor-washroom-01.png")

	house_note = _add_label(page_column, "Rooms: " + ", ".join(game_clock.state.household["rooms"]), 14, TEXT_MUTED)
	house_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_house_module(parent: HBoxContainer, title: String, subtitle: String, asset_path: String) -> void:
	var module := VBoxContainer.new()
	module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module.add_theme_constant_override("separation", 8)
	parent.add_child(module)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 270)
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
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	menu_popup.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	margin.add_child(list)
	_add_label(list, "GAME MENU", 15, TEXT_SUSPECTED)
	_add_menu_button(list, "Save", _save_game)
	_add_menu_button(list, "Load", _load_game)
	_add_menu_button(list, "Settings", _show_menu_message.bind("Settings will be added here."))
	_add_menu_button(list, "Exit", _exit_game)


func _add_menu_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(220, 38)
	button.add_theme_font_size_override("font_size", 16)
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
		var menu_button: Button = top_bar.get_node("Frame/Header/MenuButton")
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
	people = game_clock.state.people
	selected_person_id = ""
	career_person_id = ""
	conversation_result = ""
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
		new_card.get_node("Row/Details/Observation").text = people[person_id].view_for(game_clock.state.head_id)["summary"]
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
	_install_portrait(card.get_node("Row/Portrait"), people[str(card.name)], 92)
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
	var observation: Label = card.get_node("Row/Details/Observation")
	name_label.add_theme_color_override("font_color", TEXT_MAIN)
	role.add_theme_color_override("font_color", TEXT_MUTED)
	observation.add_theme_color_override("font_color", Color("#6f5e49"))
	if str(card.name) == "Carlo":
		observation.add_theme_color_override("font_color", Color("#8c4834"))


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
	frame.add_theme_stylebox_override("panel", Archive.box(Archive.PORTRAIT, 14, 7))
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
	details_popup = PopupPanel.new()
	details_popup.name = "PersonDetails"
	details_popup.add_theme_stylebox_override("panel", Archive.window_frame())
	add_child(details_popup)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_bottom", 24)
	details_popup.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)

	details_content = VBoxContainer.new()
	details_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_content.add_theme_constant_override("separation", 15)
	scroll.add_child(details_content)


func _show_person(person_id: String, open_popup: bool = true) -> void:
	if not people.has(person_id):
		return
	if selected_person_id != person_id:
		conversation_result = ""
	selected_person_id = person_id
	for child in details_content.get_children():
		details_content.remove_child(child)
		child.queue_free()

	var model = people[person_id]
	var person: Dictionary = model.view_for(game_clock.state.head_id)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	details_content.add_child(header)
	var title := _add_label(header, "%s  ·  %s" % [person["name"], person["age"]], 29, TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(details_popup.hide)
	header.add_child(close_button)

	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 22)
	details_content.add_child(identity_row)
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "Portrait"
	identity_row.add_child(portrait_frame)
	_install_portrait(portrait_frame, model, 176)
	var biography := VBoxContainer.new()
	biography.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biography.add_theme_constant_override("separation", 9)
	identity_row.add_child(biography)
	_add_label(biography, str(person["relationship"]), 16, TEXT_SUSPECTED)
	_add_label(biography, model.status_text(), 16, TEXT_MAIN)
	var pregnancy: Dictionary = model.life_state.get("pregnancy", {})
	if not pregnancy.is_empty():
		_add_label(biography, "Expecting a child · due in about %d months" % maxi(0, int(pregnancy["due_month"]) - game_clock.state.elapsed_months), 15, TEXT_KNOWN)
	if not model.spouse_id.is_empty() and people.has(model.spouse_id):
		_add_label(biography, "Married to " + people[model.spouse_id].name, 15, TEXT_MAIN)
	_add_label(biography, "Born %s %d · %s branch" % [game_clock.state.MONTH_NAMES[model.birth_month - 1], model.birth_year, model.branch_id], 14, TEXT_MUTED)
	_add_label(biography, "Responsibilities: " + ", ".join(model.roles), 15, TEXT_MAIN)
	_add_label(biography, "Education: " + str(model.education["level"]).capitalize(), 15, TEXT_MAIN)
	var careers_button := Button.new()
	careers_button.text = "Education & careers…"
	_apply_period_button_style(careers_button)
	careers_button.pressed.connect(_show_careers.bind(person_id, true))
	details_content.add_child(careers_button)
	if person_id == game_clock.state.head_id:
		var own_goals: Array = []
		for goal in model.goals:
			if goal.get("status") == "active":
				own_goals.append(str(goal["description"]))
		_add_notes("Your current goals", own_goals)
	else:
		var talk_button := Button.new()
		talk_button.text = "Talk with " + model.name.get_slice(" ", 0)
		talk_button.disabled = not model.alive or not model.in_household
		_apply_period_button_style(talk_button)
		talk_button.pressed.connect(_talk_to_person.bind(person_id))
		details_content.add_child(talk_button)
		var request_button := Button.new()
		request_button.text = "Make a request…"
		_apply_period_button_style(request_button)
		request_button.pressed.connect(_open_influence_menu.bind(person_id))
		details_content.add_child(request_button)
		for goal in model.goals:
			if goal.get("kind") == "seek_marriage" and goal.get("status") == "active":
				_add_label(details_content, "Expressed intention: find a partner of their own choosing.", 15, TEXT_KNOWN)
		_add_notes("Goals they have shared with you", person["expressed_goals"])
		var plan: Dictionary = model.decision_state.get("plan", {})
		if model.in_household and not plan.is_empty():
			var timing := "Waiting for agreement on education funding."
			if not str(plan["action"]).begins_with("funding:"):
				var remaining := maxi(0, int(plan["due_month"]) - game_clock.state.elapsed_months)
				timing = "Preparing to act within %d month%s." % [remaining, "" if remaining == 1 else "s"]
			_add_label(details_content, "Observed plan: " + str(plan["description"]) + ". " + timing, 15, TEXT_KNOWN)
		if not conversation_result.is_empty():
			_add_label(details_content, conversation_result, 17, TEXT_KNOWN)
	_add_label(details_content, str(person["summary"]), 17, TEXT_MAIN)
	_add_label(details_content, "Your understanding:  Known = observed or told  ·  Suspected = your reading  ·  Unknown = unanswered", 13, TEXT_MUTED)

	_add_layer("Temperament", person["temperament"])
	_add_layer("Values", person["values"])
	_add_layer("Learned tendencies", person["learned_tendencies"])
	_add_layer("Current state", person["current_state"])
	_add_notes("Formative experiences", person["experiences"])
	_add_notes("Evidence you have noticed", person["evidence"])

	var viewport_size := get_viewport_rect().size
	var popup_size := Vector2i(
		int(minf(860.0, viewport_size.x - 32.0)),
		int(minf(690.0, viewport_size.y - 32.0))
	)
	if open_popup:
		details_popup.popup_centered(popup_size)


func _talk_to_person(person_id: String) -> void:
	var state = game_clock.state
	conversation_result = people[person_id].converse(state.head_id, state.elapsed_months, state.date_text())
	_show_person(person_id, false)


func _build_influence_menu() -> void:
	influence_popup = PopupMenu.new()
	influence_popup.theme = theme
	influence_popup.name = "InfluenceMenu"
	influence_popup.add_theme_font_size_override("font_size", 17)
	add_child(influence_popup)
	influence_popup.id_pressed.connect(_on_influence_selected)
	$PageMargins/Page/Footer.text = "Left-click to understand a person · Right-click to make a request · Relatives can refuse"


func _open_influence_menu(person_id: String) -> void:
	game_clock.pause()
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
	game_clock.pause()
	careers_popup.hide()
	var result: Dictionary = game_clock.state.request(person_id, action)
	# Select first, because opening another person's details clears the last response.
	_show_person(person_id)
	conversation_result = "%s — %s\n%s" % [game_clock.state.Influence.action_label(game_clock.state, action), str(result["outcome"]).capitalize(), result["response"]]
	_show_person(person_id, false)
	_refresh_people()
	if is_instance_valid(finance_content):
		_refresh_finances()


func _build_careers_popup() -> void:
	careers_popup = PopupPanel.new()
	careers_popup.name = "EducationAndCareers"
	careers_popup.add_theme_stylebox_override("panel", details_popup.get_theme_stylebox("panel").duplicate())
	add_child(careers_popup)
	var margins := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 24)
	careers_popup.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	careers_content = VBoxContainer.new()
	careers_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	careers_content.add_theme_constant_override("separation", 14)
	scroll.add_child(careers_content)


func _show_careers(person_id: String, open_popup: bool = true) -> void:
	if open_popup:
		game_clock.pause()
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
		_add_label(careers_content, "%s · %s · %d%% completed · %s/month" % [program["name"], study["status"], int(float(study["progress"]) / float(program["months"]) * 100.0), game_clock.state.economy.money(program["monthly_cost_cents"])], 17, TEXT_KNOWN)
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
		_add_label(study_list, "%s · roughly %d months · %s/month" % [program["name"], program["months"], game_clock.state.economy.money(program["monthly_cost_cents"])], 18, TEXT_MAIN)
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
	column.add_theme_constant_override("separation", 10)
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
	if not reason.is_empty():
		_add_label(parent, reason, 14, TEXT_MUTED)


func _build_elsewhere_list() -> void:
	var family_list := $PageMargins/Page/RosterScroll/FamilyList
	var heading := _add_label(family_list, "LIVING ELSEWHERE · Still part of your family", 15, TEXT_MUTED)
	heading.name = "ElsewhereHeading"
	elsewhere_list = VBoxContainer.new()
	elsewhere_list.add_theme_constant_override("separation", 12)
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
		margins.add_theme_constant_override("margin_" + edge, 28)
	content_overlay.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	_add_label(column, "Chronicle", 34, TEXT_MAIN)
	if game_clock.state.chronicle.is_empty():
		_add_label(column, "Your requests and their responses will become family history here.", 17, TEXT_MUTED)
	for entry in game_clock.state.chronicle:
		_add_label(column, entry["date"] + " — " + entry["description"], 17, TEXT_MAIN)


func _add_layer(heading: String, layer: Dictionary) -> void:
	var panel := _make_section()
	var body := panel.get_child(0) as MarginContainer
	var column := body.get_child(0) as VBoxContainer
	_add_label(column, heading, 21, TEXT_MAIN)
	_add_entries(column, "Known", layer["known"], TEXT_KNOWN)
	_add_entries(column, "Suspected", layer["suspected"], TEXT_SUSPECTED)
	_add_entries(column, "Unknown", layer["unknown"], TEXT_UNKNOWN)


func _add_notes(heading: String, notes: Array) -> void:
	var panel := _make_section()
	var body := panel.get_child(0) as MarginContainer
	var column := body.get_child(0) as VBoxContainer
	_add_label(column, heading, 21, TEXT_MAIN)
	for note in notes:
		_add_label(column, "• " + str(note), 15, TEXT_KNOWN)


func _add_entries(parent: VBoxContainer, label: String, entries: Array, color: Color) -> void:
	for entry in entries:
		_add_label(parent, "%s  ·  %s" % [label, entry], 15, color)


func _make_section() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Archive.card())
	details_content.add_child(panel)
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 16)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_right", 16)
	margins.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margins)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margins.add_child(column)
	return panel


func _add_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
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
		margins.add_theme_constant_override("margin_" + edge, 24)
	event_popup.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	event_content = VBoxContainer.new()
	event_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_content.add_theme_constant_override("separation", 14)
	scroll.add_child(event_content)


func _on_month_events() -> void:
	if not game_clock.state.events.pending.is_empty():
		call_deferred("_show_pending_event")


func _refresh_event_notice() -> void:
	if not is_inside_tree():
		return
	var events = game_clock.state.events
	var notice: Label = $PageMargins/Page/Concern/ConcernMargins/ConcernText
	if not events.pending.is_empty():
		notice.text = "%d event%s awaiting your decision · Open Events to respond. Time is paused." % [events.pending.size(), "" if events.pending.size() == 1 else "s"]
		play_button.disabled = true
	else:
		play_button.disabled = false
		notice.text = "The family has its own plans. Talk, observe, and choose where to intervene."


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
	_add_label(event_content, str(event["body"]), 19, TEXT_MAIN)
	_add_label(event_content, "Choose a response before advancing to the next month. %d event%s awaiting a decision." % [state.events.pending.size(), "" if state.events.pending.size() == 1 else "s"], 14, TEXT_SUSPECTED)
	for index in range(event["choices"].size()):
		var choice: Dictionary = event["choices"][index]
		var button := Button.new()
		button.text = str(choice["label"])
		button.custom_minimum_size = Vector2(0, 44)
		_apply_period_button_style(button)
		var reason: String = state.events.choice_reason(state, event, index)
		button.disabled = not reason.is_empty()
		button.tooltip_text = reason if not reason.is_empty() else str(choice["result"])
		button.pressed.connect(_resolve_event.bind(int(event["serial"]), index))
		event_content.add_child(button)
		var explanation: String = str(choice["result"])
		var effects: Dictionary = choice["effects"]
		if effects.has("cash"):
			explanation += " " + ("Cost: " if int(effects["cash"]) < 0 else "Receives: ") + game_clock.state.economy.money(absi(int(effects["cash"]))) + "."
		if effects.get("study", false):
			var program: Dictionary = state.careers.programs.get(event.get("program_id", ""), {})
			explanation += " Tuition: " + game_clock.state.economy.money(int(program.get("monthly_cost_cents", 0))) + "/month."
		if not reason.is_empty():
			explanation += " " + reason
		_add_label(event_content, explanation, 14, TEXT_MUTED)
	var viewport_size := get_viewport_rect().size
	event_popup.popup_centered(Vector2i(int(minf(790, viewport_size.x - 32)), int(minf(680, viewport_size.y - 32))))


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
