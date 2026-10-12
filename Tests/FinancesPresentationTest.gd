extends SceneTree
const Chart = preload("res://Scripts/LedgerChart.gd")

func _initialize() -> void:
	call_deferred("_run")

func _button(parent: Node, caption: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text == caption: return button
	return null

func _assert_expenses_reconcile(parent: Node) -> void:
	var sum := 0
	var total := -1
	var collecting := false
	var columns = parent.find_child("LedgerColumns", true, false)
	var expenses = columns.get_child(1)
	for row in expenses.get_children():
		if not row is HBoxContainer or row.get_child_count() != 2: continue
		var caption = row.get_child(0)
		var value = row.get_child(1)
		if not caption is Label or not value is Label: continue
		if caption.text.begins_with("Food ·"): collecting = true
		if caption.text == "Total household expenses":
			total = roundi(value.text.replace(" L.", "").to_float() * 100)
			break
		if collecting:
			sum += roundi(value.text.replace(" L.", "").to_float() * 100)
	assert(total >= 0 and sum == total, "Displayed expense rows must sum to the displayed total")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous", "fertility")
	var state = screen.game_clock.state
	state.events.enabled = false
	screen._show_screen("Finances")
	await process_frame
	await process_frame
	assert(screen.top_bar.size.y >= 48 and screen.top_bar.size.y <= 56, "The information bar stays compact")
	assert(not screen.top_bar.find_child("Title", true, false).visible)
	var navigation = screen.get_node("Navigation")
	assert(_button(navigation, "Family Tree") != null)
	assert(_button(navigation, "Pending events").tooltip_text.contains("awaiting"))
	assert(_button(navigation, "Family chronicle").tooltip_text.contains("history"))
	var surface = _button(navigation, "Finances").get_theme_stylebox("normal")
	assert(surface is StyleBoxTexture, "Navigation uses the original walnut buttons")
	assert(screen.finance_content.find_child("TreasurySummary", true, false).get_child_count() == 3)
	var chart = screen.finance_content.find_child("TreasuryHistory", true, false)
	assert(chart.entries.is_empty(), "Do not fabricate financial history")
	assert(_button(screen.finance_content, "Explore village businesses →") != null)
	# Reconcile the actual rendered values across changes to household and milling duties.
	for year in [1800, 1867, 1869, 1881]:
		state.year = year
		screen._refresh_finances()
		_assert_expenses_reconcile(screen.finance_content)
	state.year = 1800
	screen._refresh_finances()
	# Exact amounts come from the settled ledger, with twelve months retained in the view.
	for index in range(14):
		state.economy.settle_month("%s 1800" % state.MONTH_NAMES[index % 12], state.people, state.household["members"])
	screen._refresh_time_controls()
	await process_frame
	await process_frame
	chart = screen.finance_content.find_child("TreasuryHistory", true, false)
	assert(chart.entries.size() == 12)
	assert(chart.entries[0] == state.economy.ledger[2])
	assert(chart.amount(chart.entries.back()) == state.economy.ledger.back()["closing_cents"])
	_button(screen.finance_content, "Expenses").pressed.emit()
	assert(chart.series == "expenses")
	assert(chart.amount(chart.entries.back()) == state.economy.ledger.back()["expenses_cents"])
	screen._refresh_time_controls()
	chart = screen.finance_content.find_child("TreasuryHistory", true, false)
	assert(chart.series == "expenses", "Playback refreshes retain the selected series")
	# Flat, zero and negative histories have a finite, nonzero plotting range.
	chart.entries = [{"closing_cents": 0}, {"closing_cents": -10000}]
	chart.set_series("treasury")
	var bounds: Vector2 = chart._range()
	assert(bounds.x <= -100 and bounds.y > bounds.x)
	chart.entries = [{"closing_cents": 0}]
	bounds = chart._range()
	assert(bounds.y > bounds.x)
	screen._refresh_time_controls()
	await process_frame
	await process_frame
	chart = screen.finance_content.find_child("TreasuryHistory", true, false)
	assert(chart.size.x >= 240 and chart.size.y >= 255)
	assert(chart.get_global_rect().end.x <= root.size.x)
	# Land opportunities open the actual parcel inspector without buying anything.
	var cash: int = state.economy.cash_cents
	_button(screen.finance_content, "Inspect land in Village →").pressed.emit()
	assert(screen.current_screen == "Village")
	assert(screen.village_view.selected_kind == "parcel")
	assert(state.village.development.parcels[screen.village_view.selected_id]["for_sale"])
	assert(state.economy.cash_cents == cash)
	screen._show_screen("Finances")
	_button(screen.finance_content, "Explore village businesses →").pressed.emit()
	assert(screen.current_screen == "Village")
	root.size = Vector2i(900, 900)
	root.content_scale_size = Vector2i(900, 900)
	await process_frame
	screen._show_screen("Finances")
	await process_frame
	await process_frame
	chart = screen.finance_content.find_child("TreasuryHistory", true, false)
	assert(chart.get_global_rect().end.x <= root.size.x, "The ledger stacks on narrower windows")
	screen.free()
	print("PASS: ledger amounts, real twelve-month history, series persistence, negative/zero chart ranges, compact header, walnut navigation, empty businesses, actual property links and narrow ledger layout")
	quit()
