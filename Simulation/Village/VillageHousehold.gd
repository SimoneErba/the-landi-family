extends RefCounted
## Neighboring family data. Not part of the player's household or Legacy count.

var id: String = ""
var name: String = ""
var head_id: String = ""
var member_ids: Array = []
var property_ids: Array = []
var cash_cents: int = 0
var debt_cents: int = 0
var ambitions: Array = []
var relationships: Dictionary = {}
var history: Array = []


func to_save_data() -> Dictionary:
	return {
		"id": id, "name": name, "head_id": head_id, "member_ids": member_ids.duplicate(),
		"property_ids": property_ids.duplicate(), "cash_cents": cash_cents,
		"debt_cents": debt_cents, "ambitions": ambitions.duplicate(true),
		"relationships": relationships.duplicate(true), "history": history.duplicate(true),
	}


func restore_save_data(data: Dictionary) -> void:
	# SaveGame validates property and relationship records before restore.
	for field in to_save_data():
		if data.has(field):
			var value: Variant = data[field]
			set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
