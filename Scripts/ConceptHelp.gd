extends RefCounted
## Short, player-facing lessons shown in the archive's themed hover boxes.
const LESSONS := {
	"Laws": "Review current inheritance, tax and old-age obligations. Italian government arrives in 1861, followed by separate tax and civil-law reforms. Laws apply when their dates arrive.",
	"People": "Observe relatives and talk to them to learn what matters to them. You lead the family, but each person can refuse your requests.",
	"Family Tree": "Follow parents, children and marriages across generations. Relatives outside your household still belong to the family.",
	"House": "The ancestral home is a shared asset. Rooms, maintenance and ownership affect everyone living here. Expansion costs money and creates new responsibilities.",
	"Village": "Meet neighboring households, develop property and build relationships. Their trust and interests shape how they respond to your family.",
	"Italy": "Explore destinations for travel, education and work. Leaving home creates opportunities, but takes people away from household duties.",
	"Finances": "Review the shared purse, monthly income, expenses and debt. A profitable month does not guarantee you can afford a large payment today.",
	"Chronicle": "Read the family's recorded history. Earlier choices and conflicts help explain today's relationships and intentions.",
	"Events": "Developments awaiting your decision pause time so you can choose how to respond. Reading an event later leaves the decision pending.",
	"Family purse": "Money available to the household for everyday costs and major decisions. Income and expenses change each month. Some money may be owed to others.",
	"Family cohesion": "A broad impression of family bonds, trust and unresolved resentment. Listen to individual concerns: a close family can still contain unhappy people.",
	"Village reputation": "How neighboring households regard your family. Trust, favors and grievances shape relationships beyond the ancestral home.",
	"Family ambition": "Your chosen legacy gives this family a purpose across generations. Money and relationships are tools for reaching its particular goals.",
	"Personality": "Your understanding of how this person tends to behave. It comes from observation and conversation, and may be incomplete or mistaken.",
	"Temperament": "Habitual ways of reacting, such as being reserved or open to change. Circumstances and relationships still affect each decision.",
	"Values": "What this person cares about, such as independence, family or achievement. A request can conflict with their values even when they love you.",
	"Learned tendencies": "Patterns shaped by experience, such as avoiding conflict or needing approval. Watch their actions as well as their words.",
	"Skills": "Practical abilities developed through education, work and activities. Unknown abilities stay hidden until you learn more about the person.",
	"Background": "Earlier experiences help explain the person you see today. The same experience can affect different relatives differently.",
	"Requests": "Ask a relative to do something. Their wishes, circumstances and relationship with the family head shape their answer. Agreement can still carry resentment.",
	"Activities": "Plans take time and may cost money or compete with work and family duties. Relatives need to agree to take part, and may later abandon a plan.",
	"Marriage & dote": "Marriage requires willing partners. A dowry supports the couple and can create obligations for the shared purse, especially if they leave home.",
	"History": "Past conversations, choices and experiences provide evidence for understanding this relative. Memories can affect later decisions.",
	"Known": "Your family head has evidence for this belief. It describes their understanding of the person, rather than perfect knowledge.",
	"Suspected": "A tentative impression based on limited evidence. Talk and observe before making a major decision around it.",
	"Unknown": "You have not learned enough about this part of the person yet. Shared experiences and conversation can reveal more.",
	"Monthly income": "Wages contributed by people in the household. Earnings gradually fall after age 60. Illness, travel and changes in work also affect contributions. Business returns are recorded separately.",
	"Monthly surplus": "Household wages left after food, clothing, care, upkeep and funded tuition. Projects, business costs and one-off payments can still reduce the shared purse.",
	"Expenses": "Recurring costs include food, household essentials, young-child and elder care, upkeep and tuition. Debt triggers cheaper living with a happiness cost. Leave funds for obligations and emergencies.",
	"How they seem to feel": "Your impression of this person's current emotional state. Stress and resentment can change over time and affect responses to requests."
}
const ALIASES := {
	"Landi House": "House", "Family treasury": "Family purse",
	"Family Finances": "Finances", "Habits & responses": "Learned tendencies",
	"What matters to them": "Values", "Family standing": "Village reputation"
}

static func attach(control: Control, concept: String) -> void:
	var key := concept.strip_edges()
	key = ALIASES.get(key, key)
	# Ledger summary captions are uppercase.
	for lesson in LESSONS:
		if lesson.to_lower() == key.to_lower(): key = lesson
	if not LESSONS.has(key): return
	control.tooltip_text = key + "\n" + _wrap(LESSONS[key])
	# Labels ignore mouse input by default; pass allows both hover and scrolling.
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS

static func _wrap(text: String) -> String:
	var lines := ""
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() > 52:
			lines += line + "\n"
			line = ""
		line += (" " if not line.is_empty() else "") + word
	return lines + line
