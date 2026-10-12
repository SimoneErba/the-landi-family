extends RefCounted
## A family ledger: plain rows, settled history, and links to real opportunities.
const Chart = preload("res://Scripts/LedgerChart.gd")
const Economy = preload("res://Simulation/Economy.gd")

static func _label(host, parent: Node, text: String, size: int = 16, color: Color = Color("#392b20")) -> Label:
	var label: Label = host._add_label(parent, text, size, color)
	label.add_theme_font_size_override("font_size", size)
	return label

static func _section(host, parent: Node, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	parent.add_child(column)
	var heading := _label(host, column, title, 24)
	heading.add_theme_font_override("font", host.Archive.HEADING)
	return column

static func _row(host, parent: Node, caption: String, amount: int, strong := false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var label := _label(host, row, caption, 17 if strong else 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := _label(host, row, host._finance_money(amount), 19 if strong else 16, host.TEXT_SUSPECTED if amount < 0 else host.TEXT_MAIN)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	if strong:
		label.add_theme_font_override("font", host.Archive.HEADING)
		value.add_theme_font_override("font", host.Archive.HEADING)

static func _action(host, parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 34
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(action)
	parent.add_child(button)
	return button

static func _stat(host, parent: Node, caption: String, amount: int, hint: String, node_name: String, signed := false) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 235
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	var caption_label := _label(host, column, caption.to_upper(), 13, host.TEXT_MUTED)
	host.ConceptHelp.attach(caption_label, caption)
	var value := _label(host, column, ("+" if signed and amount > 0 else "") + host._finance_money(amount), 42, host.TEXT_SUSPECTED if amount < 0 else host.TEXT_MAIN)
	value.name = node_name
	host.ConceptHelp.attach(value, caption)
	value.add_theme_font_override("font", host.Archive.HEADING)
	_label(host, column, hint, 15, host.TEXT_MUTED)

static func build(host) -> void:
	var parent: VBoxContainer = host.finance_content
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	parent.add_theme_constant_override("separation", 24)
	var state = host.game_clock.state
	var economy = state.economy
	var budget: Dictionary = economy.budget(state.people, state.household["members"], state.household, state.year, state.month, state.tax_property_assessment())
	_heading(host, parent, budget)
	_obligations(host, parent, budget)
	_loans(host, parent)
	var main: BoxContainer = HBoxContainer.new() if host.get_viewport_rect().size.x >= 1200 else VBoxContainer.new()
	main.add_theme_constant_override("separation", 48)
	parent.add_child(main)
	var columns := VBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_stretch_ratio = 0.8
	columns.name = "LedgerColumns"
	columns.add_theme_constant_override("separation", 48)
	main.add_child(columns)
	_income(host, columns, budget)
	_expenses(host, columns, budget)
	_history(host, main, economy)
	var bottom: BoxContainer = HBoxContainer.new() if host.get_viewport_rect().size.x >= 1050 else VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 48)
	parent.add_child(bottom)
	_businesses(host, bottom)
	_opportunities(host, bottom)
	_commitments(host, parent)

static func _heading(host, parent: Node, budget: Dictionary) -> void:
	var state = host.game_clock.state
	var economy = state.economy
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	parent.add_child(heading)
	_label(host, heading, "THE LANDI FAMILY · " + state.date_text().to_upper(), 13, host.TEXT_MUTED)
	var title := _label(host, heading, "Family Finances", 38)
	title.add_theme_font_override("font", host.Archive.HEADING)
	_label(host, heading, "The household’s fortunes and obligations", 18, host.TEXT_MUTED)
	var summary := HFlowContainer.new()
	summary.name = "TreasurySummary"
	summary.add_theme_constant_override("h_separation", 48)
	summary.add_theme_constant_override("v_separation", 16)
	parent.add_child(summary)
	_stat(host, summary, "Family treasury", economy.cash_cents, "Available shared funds", "BalanceValue")
	_stat(host, summary, "Monthly income", budget["income_cents"], "From household wages", "IncomeValue")
	_stat(host, summary, "Monthly surplus", budget["net_cents"], "After living costs, taxes and funded tuition", "MonthlynetValue", true)
	_label(host, parent, "Household accounts cover food, clothing, care, upkeep, taxes and tuition. Older relatives gradually earn less after 60. Business returns and one-off payments appear separately below.", 14, host.TEXT_MUTED)

static func _income(host, columns: Node, budget: Dictionary) -> void:
	var income := _section(host, columns, "Household income")
	for contribution in budget["contributions"]:
		var row := HBoxContainer.new()
		income.add_child(row)
		var identity := VBoxContainer.new()
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(identity)
		_label(host, identity, contribution["name"], 18)
		_label(host, identity, contribution["job"], 14, host.TEXT_MUTED)
		if contribution["work_capacity"] < 1.0:
			_label(host, identity, "Reduced work with age · %d%% of usual earnings" % roundi(contribution["work_capacity"] * 100), 13, host.TEXT_MUTED)
		var value := _label(host, row, host._finance_money(contribution["income_cents"]), 18, host.TEXT_KNOWN if int(contribution["income_cents"]) > 0 else host.TEXT_MUTED)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.size_flags_vertical = Control.SIZE_SHRINK_CENTER

static func _expenses(host, columns: Node, budget: Dictionary) -> void:
	var state = host.game_clock.state
	var expenses := _section(host, columns, "Expenses")
	_expense_bar(host, expenses, budget)
	_row(host, expenses, "Food · %d residents" % budget["residents"], budget["food_cents"])
	if budget.get("food_support_cents", 0) > 0:
		_label(host, expenses, "Farm produce or supplied meals reduce food purchases by " + host._finance_money(budget["food_support_cents"]) + "/month; this is food provision, not cash income.", 14, host.TEXT_MUTED)
	_row(host, expenses, "Clothing and household essentials", budget["essentials_cents"])
	_row(host, expenses, "Young-child and elder care", budget["care_cents"])
	_row(host, expenses, "House upkeep", budget["upkeep_cents"])
	_row(host, expenses, "Property / community assessment", budget["property_tax_cents"])
	if state.Laws.rules(state.year, state.month)["household_macinato"]:
		_row(host, expenses, "Tuscan macinato · %d mouths · class %d" % [budget["taxable_mouths"], budget["household_tax_class"]], budget["household_tax_cents"])
	_row(host, expenses, "Salt / consumption duties in food prices", budget["salt_duty_cents"])
	if state.Laws.rules(state.year, state.month)["milling_duty"]:
		_row(host, expenses, "Italian milling duty in food prices", budget["milling_tax_cents"])
	_row(host, expenses, "Income duty", budget["income_tax_cents"])
	_action(host, expenses, "Read current laws →", host._show_screen.bind("Laws"))
	_row(host, expenses, "Education fees, board and supplies", budget["tuition_cents"])
	_row(host, expenses, "Total household expenses", budget["expenses_cents"], true)
	_row(host, expenses, "Net monthly savings", budget["net_cents"], true)

static func _expense_bar(host, parent: Node, budget: Dictionary) -> void:
	var total: int = budget["expenses_cents"]
	var bar := HBoxContainer.new()
	bar.name = "ExpenseBreakdown"
	bar.custom_minimum_size.y = 14
	bar.add_theme_constant_override("separation", 2)
	parent.add_child(bar)
	for entry in [["Food", int(budget["food_cents"]), Color("#9a6533")], ["Essentials", int(budget["essentials_cents"]), Color("#8a795c")], ["Care", int(budget["care_cents"]), Color("#866859")], ["Upkeep", int(budget["upkeep_cents"]), Color("#62707a")], ["Tuition", int(budget["tuition_cents"]), host.TEXT_KNOWN], ["Taxes", int(budget["taxes_cents"]), Color("#753e30")]]:
		if entry[1] <= 0: continue
		var segment := ColorRect.new()
		segment.color = entry[2]
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio = float(entry[1]) / maxf(1, total)
		segment.tooltip_text = entry[0] + " · " + host._finance_money(entry[1])
		bar.add_child(segment)
	_label(host, parent, "Hover over each segment for its expense category and amount.", 13, host.TEXT_MUTED)

static func _loans(host, parent: Node) -> void:
	var state = host.game_clock.state
	var section := _section(host, parent, "Loans · 5% annual interest")
	_label(host, section, "Interest is paid once every twelve months after borrowing. Principal stays owed until repaid; early repayment includes interest accrued so far. Loans follow the estate through succession.", 15, host.TEXT_MUTED)
	_row(host, section, "Outstanding principal", state.loans.principal_cents())
	_row(host, section, "Accrued interest", state.loans.accrued_cents())
	var borrow_row := HBoxContainer.new()
	section.add_child(borrow_row)
	var amount := SpinBox.new()
	amount.name = "LoanAmount"
	amount.min_value = 1
	amount.max_value = maxf(1, float(state.loans.CREDIT_LIMIT_CENTS - state.loans.principal_cents()) / 100.0)
	amount.value = minf(100, amount.max_value)
	amount.suffix = "lire"
	amount.custom_minimum_size.x = 160
	borrow_row.add_child(amount)
	var borrow := _action(host, borrow_row, "Borrow", func():
		var error: String = state.loans.borrow(state, roundi(amount.value * 100))
		host.gameplay_result = error if not error.is_empty() else "Loan received. Interest is due in twelve months."
		host._refresh_time_controls())
	borrow.disabled = state.loans.principal_cents() >= state.loans.CREDIT_LIMIT_CENTS or state.succession.pending or state.succession.ended
	for id in state.loans.loans:
		var loan: Dictionary = state.loans.loans[id]
		var row := HBoxContainer.new()
		section.add_child(row)
		_label(host, row, id + " · " + state.economy.money(loan["principal_cents"]) + " · annual bill in %d months" % (loan["next_interest_month"] - state.elapsed_months), 16)
		var repayment := SpinBox.new()
		repayment.min_value = 0.01
		repayment.max_value = float(loan["principal_cents"]) / 100.0
		repayment.step = 0.01
		repayment.value = minf(100, repayment.max_value)
		repayment.suffix = "lire"
		row.add_child(repayment)
		var repay := _action(host, row, "Repay", func():
			var error: String = state.loans.repay(state, id, roundi(repayment.value * 100))
			host.gameplay_result = error if not error.is_empty() else "Loan repayment recorded."
			host._refresh_time_controls())
		repay.disabled = state.succession.pending or state.succession.ended
		var cost := _label(host, section, "", 14, host.TEXT_MUTED)
		var update := func(_value: float = 0):
			var total: int = state.loans.repayment_cost(id, roundi(repayment.value * 100))
			cost.text = "Repayment including accrued interest · " + state.economy.money(total)
			repay.disabled = total < 0 or state.economy.cash_cents < total or state.succession.pending or state.succession.ended
		update.call()
		repayment.value_changed.connect(update)
	if not host.gameplay_result.is_empty(): _label(host, section, host.gameplay_result, 16, host.TEXT_KNOWN)

static func _history(host, parent: Node, economy) -> void:
	var section := _section(host, parent, "Household financial history")
	var toggles := HFlowContainer.new()
	section.add_child(toggles)
	var chart = Chart.new()
	chart.name = "TreasuryHistory"
	chart.entries = economy.ledger.slice(maxi(0, economy.ledger.size() - 12))
	chart.series = host.finance_series
	var group := ButtonGroup.new()
	for id in Chart.SERIES:
		var button := Button.new()
		button.text = {"treasury":"Treasury", "income":"Income", "expenses":"Expenses", "savings":"Net savings"}[id]
		button.name = "Series_" + id
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = id == host.finance_series
		toggles.add_child(button)
		button.pressed.connect(func():
			host.finance_series = id
			chart.set_series(id))
	section.add_child(chart)
	_label(host, section, "Last 12 settled months · L. = lire · Hover over a month for its exact value. Treasury shows the balance at household settlement; later payments appear in Payments and sales.", 13, host.TEXT_MUTED)
	if not economy.ledger.is_empty():
		var entry: Dictionary = economy.ledger.back()
		_label(host, section, "%s · Income %s · Expenses %s · Net savings %s · Closing treasury %s" % [entry["date"], host._finance_money(entry["income_cents"]), host._finance_money(Economy.total_expenses(entry)), host._finance_money(entry["net_cents"]), host._finance_money(entry["closing_cents"])], 15)

static func _obligations(host, parent: Node, budget: Dictionary) -> void:
	var state = host.game_clock.state
	var economy = state.economy
	if economy.cash_cents < 0:
		host._finance_notice(parent, "Unpaid bills · economizing", "The family buys simpler food and cuts clothing and upkeep expenses while in debt. Happiness suffers. Funded study takes priority only after essential bills; adults suspend unfunded courses after three months to return to paid work.")
	if not budget["training_funded"] and int(budget["planned_tuition_cents"]) > 0:
		host._finance_notice(parent, "Courses paused", "Living costs take priority. The household cannot fund " + economy.money(budget["planned_tuition_cents"]) + " in planned tuition.")
	var dowry_owed := 0
	for union in state.marriage.unions.values():
		if union["held_at_home"]: dowry_owed += int(union["capital_cents"])
	if dowry_owed > 0:
		host._finance_notice(parent, "Dowry owed to resident couples · " + economy.money(dowry_owed), "Included in the shared balance. It must follow couples who leave; spending it can create a future cash shortfall.")
	for family_id in state.marriage.alliances:
		var obligation: int = state.marriage.alliances[family_id]["obligation_cents"]
		if obligation > 0:
			host._finance_notice(parent, "Favor owed to " + state.village.households[family_id].name, economy.money(obligation) + " · Repay through a person’s Marriage & dote screen.")
	for effect in state.events.active:
		var hint: String = "Food prices ×%.2f · Wages and sales ×%.2f\nFarm output ×%.2f · Business costs ×%.2f" % [effect["food_multiplier"], effect["income_multiplier"], effect.get("farm_multiplier", 1.0), effect.get("business_cost_multiplier", 1.0)]
		if effect.get("travel_until_month", -1) > state.elapsed_months:
			hint += "\nTransport disrupted for %d more months." % (effect["travel_until_month"] - state.elapsed_months)
		host._finance_notice(parent, "%s · %d months" % [str(effect["kind"]).capitalize(), maxi(0, int(effect["until_month"]) - state.elapsed_months)], hint)

static func _businesses(host, parent: Node) -> void:
	var state = host.game_clock.state
	var section := _section(host, parent, "Family businesses")
	var owned := 0
	for building in state.village.development.buildings.values():
		if building["owner_id"] != "landi" or building["type"] not in state.village.business.CATALOG or building["status"] == "demolished": continue
		owned += 1
		var estimate: Dictionary = state.village.business.estimate(state, building["id"])
		_row(host, section, building["address"] + " · " + estimate["status"], estimate["net_cents"])
	if owned == 0:
		_label(host, section, "The family owns no businesses", 19)
		_label(host, section, "Acquire land, build a workshop or farm, then ask a relative to manage it to create income beyond wages.", 16, host.TEXT_MUTED)
		_action(host, section, "Explore village businesses →", host._show_screen.bind("Village"))
	else:
		_label(host, section, "Estimated monthly net · actual sales and upkeep depend on management, condition and the season.", 14, host.TEXT_MUTED)
		if not state.village.business.reports.is_empty():
			var report: Dictionary = state.village.business.reports.back()
			for entry in report["rows"]:
				if entry["owner_id"] == "landi":
					_label(host, section, "%s · %s · sales %s · costs %s · duties %s · net %s" % [report["date"], state.village.development.buildings[entry["building_id"]]["address"], host._finance_money(entry["revenue_cents"]), host._finance_money(entry["cost_cents"]), host._finance_money(entry.get("tax_cents", 0)), host._finance_money(entry["net_cents"])], 14, host.TEXT_MUTED)

static func _opportunities(host, parent: Node) -> void:
	var state = host.game_clock.state
	var dev = state.village.development
	var section := _section(host, parent, "Financial opportunities")
	var plots: Array = []
	for parcel in dev.parcels.values():
		if parcel["for_sale"] and parcel["owner_id"] == "village" and not dev._occupied_project(parcel["id"]): plots.append(parcel)
	plots.sort_custom(func(a, b): return dev.land_value(a) < dev.land_value(b))
	if not plots.is_empty():
		var parcel: Dictionary = plots[0]
		var cost: int = state.economy.purchase_cost(dev.land_value(parcel))
		_label(host, section, "Land is available for purchase", 19)
		_label(host, section, "%s · %s · %s" % [str(parcel["id"]).replace("_", " ").capitalize(), host._finance_money(cost), "Within the family’s means" if cost <= state.economy.cash_cents else "Requires more savings"], 16, host.TEXT_MUTED)
		_label(host, section, "Permitted uses: " + ", ".join(parcel["uses"]) + ". Construction and management require a further investment.", 14, host.TEXT_MUTED)
		_action(host, section, "Inspect land in Village →", func():
			host._show_screen("Village")
			host.village_view.selected_kind = "parcel"
			host.village_view.selected_id = parcel["id"]
			host.village_view.map.selected_id = parcel["id"]
			host.village_view.map.queue_redraw()
			host.village_view._inspect())
	else:
		_label(host, section, "Plan the family’s next investment", 19)
		_label(host, section, "Explore village properties or discuss education and careers with a relative.", 16, host.TEXT_MUTED)
		_action(host, section, "Explore the village →", host._show_screen.bind("Village"))
	_action(host, section, "Review education & careers →", host._show_careers.bind(state.head_id, true))

static func _commitments(host, parent: Node) -> void:
	var state = host.game_clock.state
	var commitments: Array = []
	for plan in state.activities.plans.values():
		if plan.status in ["active", "interrupted"]: commitments.append(plan)
	if not commitments.is_empty():
		var section := _section(host, parent, "Family project commitments")
		for plan in commitments:
			_row(host, section, state.activities.CATALOG[plan.activity_id]["name"] + " · " + plan.status, state.economy.purchase_cost(plan.monthly_cost_cents))
		_label(host, section, "Cost per active month, paid after household bills. Progress pauses when funds are unavailable.", 14, host.TEXT_MUTED)
	if not state.events.transactions.is_empty():
		var payments := _section(host, parent, "Payments and sales")
		for entry in state.events.transactions.slice(maxi(0, state.events.transactions.size() - 8)):
			_row(host, payments, entry["date"] + " · " + entry["description"], entry["amount_cents"])
