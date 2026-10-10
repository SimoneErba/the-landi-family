extends RefCounted
## Persistent activity data, coordinated by ActivitySystem.
## See todo/second-gameplay-layer/README.md before integrating.

const STATUSES := ["proposed", "active", "interrupted", "completed", "cancelled", "failed"]

var id: String = ""
var activity_id: String = ""
var proposer_id: String = ""
var participant_ids: Array = []
var accepted_participant_ids: Array = []
var target_household_id: String = ""
var target_person_id: String = ""
var location_id: String = ""
var property_id: String = ""
var status: String = "proposed"
var proposed_month: int = 0
var started_month: int = -1
var duration_months: int = 1
var progress_months: float = 0.0
var upfront_cost_cents: int = 0
var monthly_cost_cents: int = 0
var interruption_reason: String = ""
var outcome: Dictionary = {}
var agreement: Dictionary = {}


func to_save_data() -> Dictionary:
	return {
		"id": id, "activity_id": activity_id, "proposer_id": proposer_id,
		"participant_ids": participant_ids.duplicate(),
		"accepted_participant_ids": accepted_participant_ids.duplicate(),
		"target_household_id": target_household_id, "target_person_id": target_person_id, "location_id": location_id,
		"property_id": property_id, "status": status, "proposed_month": proposed_month,
		"started_month": started_month, "duration_months": duration_months,
		"progress_months": progress_months, "upfront_cost_cents": upfront_cost_cents,
		"monthly_cost_cents": monthly_cost_cents, "interruption_reason": interruption_reason,
		"outcome": outcome.duplicate(true), "agreement": agreement.duplicate(true),
	}


func restore_save_data(data: Dictionary) -> void:
	# SaveGame validates IDs, types, status and costs before restore.
	for field in to_save_data():
		if data.has(field):
			var value: Variant = data[field]
			set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
