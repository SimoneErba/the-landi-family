extends RefCounted

static func build(host) -> void:
	var state = host.game_clock.state
	var laws: Dictionary = state.Laws.rules(state.year, state.month)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_overlay.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "LawsInfo"
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	host._add_label(column, "Laws & family obligations", 32, host.TEXT_MAIN)
	host._add_label(column, state.Laws.regime(state.year, state.month) + " · " + state.date_text(), 22, host.TEXT_SUSPECTED)
	host._add_label(column, "The head leads the family; the law governs its obligations. These rules change with the calendar, independently of historical-event choices.", 17, host.TEXT_MUTED)
	_section(host, column, "Inheritance & the will", "Sons and daughters inherit equally under the unified code. Children collectively have a protected half of the estate; descendants can represent a deceased child." if laws["civil_code"] else "Tuscan succession depended on local law and the period. Napoleonic equality was followed by a restoration favoring male lines. Wills could differ from intestate succession; there was no single century-long rule of eldest-son inheritance.")
	host._add_label(column, "In your family: the existing equal-share cash will includes daughters in every period. Naming a successor changes who you play, not the children's shares. Loans and reserved dowries come first; inheritance duties are then deducted. House and business ownership are not divided by this cash model.", 17, host.TEXT_KNOWN)
	var estate: Dictionary = state.succession.preview(state)
	host._add_label(column, "Current inheritance duty · %d%% · projected payment %s" % [roundi(float(laws["estate_rate"]) * 100), state.economy.money(estate["inheritance_tax_cents"])], 18, host.TEXT_SUSPECTED)
	var will := Button.new()
	will.text = "Review succession & will →"
	will.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	will.pressed.connect(host._show_screen.bind("Succession"))
	column.add_child(will)
	_section(host, column, "Property & community assessments", "Property obligations depend on the family's owned land and buildings, using estimated rental capacity. Buying holdings, expanding the house or adding buildings increases the assessment; selling them reduces it. The 1861 proclamation does not itself raise the rate.")
	var budget: Dictionary = state.economy.budget(state.people, state.household["members"], state.household, state.year, state.month, state.tax_property_assessment())
	host._add_label(column, laws["property_name"] + " · " + state.economy.money(budget["property_tax_cents"]), 18, host.TEXT_KNOWN)
	_section(host, column, "Tuscan macinato · household assessment", "In 1800 this is a household assessment based on mouths and means, not a charge per sack at the mill. Children under three are excluded. There are eight paying classes, with a separate exemption for households recognized as destitute. The old assessment ends with the French reorganization in January 1809.")
	if laws["household_macinato"]:
		var class_text := "Exempt · modeled destitute class" if budget["household_tax_class"] == 0 else "Paying class " + str(budget["household_tax_class"]) + " of 8"
		host._add_label(column, "%d taxable mouths · %s · %s/month" % [budget["taxable_mouths"], class_text, state.economy.money(budget["household_tax_cents"])], 18, host.TEXT_KNOWN)
	else:
		host._add_label(column, "The old Tuscan household macinato is no longer charged.", 17, host.TEXT_MUTED)
	_section(host, column, "Duties in purchase prices", "Salt and other consumption duties are disclosed as an estimated food-price component. The later Italian macinato, active from January 1869 to December 1883, instead taxes grain milled. This model estimates wheat consumption; it does not charge the earlier household tax a second time.")
	host._add_label(column, "Salt / consumption duties · " + state.economy.money(budget["salt_duty_cents"]) + "\nItalian milling duty · " + state.economy.money(budget["milling_tax_cents"]), 18, host.TEXT_KNOWN)
	if laws["milling_duty"]:
		host._add_label(column, "Estimated wheat · %.1f kg/month. Initial statutory tariff: 2 Italian lire per 100 kg; later tariff reductions and mixed cereals are not reconstructed." % budget["estimated_cereal_kg"], 16, host.TEXT_MUTED)
	_section(host, column, "Income duties", "From July 1864, ricchezza mobile is represented by a levy on non-agricultural wages and positive non-farm business profits. Farm earnings remain under the property assessment in this simplified model.")
	host._add_label(column, "Income duty · %d%% · %s" % [roundi(float(laws["income_rate"]) * 100), state.economy.money(budget["income_tax_cents"])], 18, host.TEXT_KNOWN)
	host._add_label(column, "Assessments are paid as monthly equivalents in the game. Means use earnings plus estimated property and savings income. Classes, poverty recognition and property yields are estimates; historical communal quotas and annual tax rolls are not reconstructed. Taxes reduce education affordability. Direct assessments are not discounted; buying less grain reduces consumption duties. Debt alone does not grant an exemption.", 16, host.TEXT_MUTED)
	_section(host, column, "Old age & pensions", "No automatic public pension supports this household. Older relatives earn less as their work capacity falls; savings, relatives and continued work must cover their care. The 1898 fund was voluntary, with compulsory insurance following in 1919. Contributions and eligibility are not yet simulated, so reaching either date does not create a pension payment.")
	_section(host, column, "Marriage, dowries & property", "Tuscan marriage and dowry practice shaped family obligations. The Italian civil code introduced civil marriage and retained restrictions on married women's legal autonomy. The game's marriage negotiations and reserved dowry capital continue; civil registration, marital authorization and spousal usufruct are historical context, not additional controls yet.")
	host._add_label(column, "The fiscal and legal calendar", 24, host.TEXT_MAIN)
	for reform in state.Laws.REFORMS:
		var active: bool = state.Laws.reached(state.year, state.month, reform["year"], reform["month"])
		host._add_label(column, "%s · %s %d · %s" % ["In force" if active else "Upcoming", state.MONTH_NAMES[reform["month"] - 1], reform["year"], reform["title"]], 18, host.TEXT_KNOWN if active else host.TEXT_SUSPECTED)
		host._add_label(column, reform["effect"], 16, host.TEXT_MUTED)
	host._add_label(column, "Historical dates; simplified gameplay rules", 22, host.TEXT_MAIN)
	host._add_label(column, "The kingdom begins in March 1861; national inheritance duties follow in 1862, income reform in 1864, and the 1865 civil code takes effect in January 1866. The 1800 household assessment ends in 1809; the national milling duty runs from 1869 to 1883. Tax-class thresholds, assessed yields and consumption estimates are gameplay assumptions. Earlier political periods are summarized; the inheritance model uses a deliberate will. Later runs retain these prototype rules rather than reconstructing every subsequent reform.", 16, host.TEXT_MUTED)
	for source in [
		["Tuscan household tax and exemptions", "https://ast.sns.it/view/ca/8050"],
		["French fiscal reorganization", "https://ricerca.sns.it/retrieve/d3eba5d6-3e32-4b30-9891-b3a642588c06/Strisciata%20Inventario.pdf"],
		["Italian milling tax · University of Florence", "https://www.sba.unifi.it/index.php?func=viewpage&module=CMpro&pageid=577"],
		["Tuscan succession history", "https://www.historiaetius.eu/uploads/5/9/4/8/5948821/galligani_6.pdf"],
		["1865 civil code · inheritance", "https://it.wikisource.org/wiki/Codice_civile_(1865)/Libro_III/Titolo_II"],
		["Income tax history · Ministry of Culture", "https://inventari-san.cultura.gov.it/inventari/296/ca/1085164"],
		["Inheritance tax history", "https://www.ecineq.org/wp-content/uploads/papers_EcineqLSE/EcineqLSE-332.pdf"],
		["Pension history · INPS", "https://www.inps.it/it/it/l-istituto/la-storia-e-i-numeri-dell-inps.html"]]:
		var link := LinkButton.new()
		link.text = source[0] + " ↗"
		link.uri = source[1]
		column.add_child(link)

static func _section(host, parent: Node, heading: String, description: String) -> void:
	host._add_label(parent, heading, 24, host.TEXT_MAIN)
	host._add_label(parent, description, 17, host.TEXT_MAIN)
