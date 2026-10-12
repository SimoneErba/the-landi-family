extends RefCounted
## Fresh, self-contained households; the authored large family remains a test fixture.

const OPTIONS := {
	"alone": {"name": "Alone", "description": "Giovanni, age 30. Build a family and a future from a quiet house."},
	"wife": {"name": "With a wife", "description": "Giovanni and Maria, ages 30 and 28. Begin your legacy together."},
	"child": {"name": "With a wife and son", "description": "Giovanni, Maria and their six-year-old son Carlo. Begin with a young family sharing Landi House."},
}

static func create_people(choice: String) -> Dictionary:
	if not OPTIONS.has(choice):
		return {}
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json"))
	var ids := ["Giovanni"]
	if choice in ["wife", "child"]: ids.append("Maria")
	if choice == "child": ids.append("Carlo")
	var result: Dictionary = {}
	for id in ids:
		var person: Dictionary = source[id].duplicate(true)
		person["birth"] = {"year": 1770 if id == "Giovanni" else (1772 if id == "Maria" else 1794), "month": 1}
		person["parent_ids"] = ["Giovanni", "Maria"] if id == "Carlo" else []
		person["spouse_id"] = ("Maria" if id == "Giovanni" else "Giovanni") if id != "Carlo" and choice in ["wife", "child"] else ""
		person["in_household"] = true
		person["branch_id"] = "Giovanni"
		person["memories"] = []
		person["experiences"] = []
		person["evidence"] = []
		person["conversation_topics"] = []
		person["goals"] = []
		person["life_state"] = {"can_be_pregnant": bool(source[id].get("life_state", {}).get("can_be_pregnant", false))}
		# Old observations describe adult children and relatives absent from these starts.
		for layer in ["temperament", "values", "learned_tendencies", "current_state"]:
			person[layer] = {"known": [], "suspected": [], "unknown": []}
		var bonds: Dictionary = {}
		for other in ids:
			if other != id and person["relationships"].has(other):
				bonds[other] = person["relationships"][other].duplicate(true)
		person["relationships"] = bonds
		person["summary"] = "You tend a small Tuscan farm. The next century of the Landi family begins with the choices you make today."
		if id == "Maria":
			person["summary"] = "Maria is building a home with you. She values security and wants a say in the family's future."
		if id == "Carlo":
			person["relationship"] = "Son · Child"
			person["summary"] = "Carlo is six, curious about the village and dependent on you. His education and childhood lie ahead."
			person["job"] = "Child (no paid work)"
			person["monthly_income_cents"] = 0
			person["roles"] = []
			person["education"] = {"level": "none", "qualifications": [], "study": {}}
			person["skills"] = {}
			person["career_access"] = []
			person["psychology"]["current_state"] = {"stress": 0.1, "happiness": 0.7, "resentment": 0.0}
		result[id] = person
	return result
