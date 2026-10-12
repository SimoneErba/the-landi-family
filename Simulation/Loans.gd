extends RefCounted
## Simple annual interest, accrued without compounding and paid yearly or on repayment.
const ANNUAL_RATE_BPS := 500
const CREDIT_LIMIT_CENTS := 1000000
const INTEREST_DIVISOR := 120000
var loans: Dictionary = {}
var next_id := 1

func principal_cents() -> int:
	var total := 0
	for loan in loans.values(): total += int(loan["principal_cents"])
	return total

func accrued_cents() -> int:
	var total := 0
	for loan in loans.values(): total += ceili(float(loan["interest_units"]) / INTEREST_DIVISOR)
	return total

func borrow(state, amount: int) -> String:
	if state.succession.pending or state.succession.ended: return "Choose the next family head first."
	if amount <= 0 or amount > CREDIT_LIMIT_CENTS - principal_cents(): return "Choose a positive amount within the family's 10,000-lire credit limit."
	var id := "loan_%d" % next_id
	next_id += 1
	loans[id] = {"id": id, "principal_cents": amount, "issued_month": state.elapsed_months, "next_interest_month": state.elapsed_months + 12, "interest_units": 0}
	state.events._cash(state, amount, "Loan received · 5% annual interest", false)
	_record(state, "Borrowed " + state.economy.money(amount) + " at 5% annual interest. First annual bill in 12 months.")
	return ""

func repayment_cost(id: String, amount: int) -> int:
	if not loans.has(id) or amount <= 0 or amount > int(loans[id]["principal_cents"]): return -1
	var loan: Dictionary = loans[id]
	return amount + ceili(float(loan["interest_units"]) * amount / int(loan["principal_cents"]) / INTEREST_DIVISOR)

func repay(state, id: String, amount: int) -> String:
	if state.succession.pending or state.succession.ended: return "Choose the next family head first."
	var cost := repayment_cost(id, amount)
	if cost < 0: return "Choose a valid loan and repayment amount."
	if state.economy.cash_cents < cost: return "The purse cannot cover principal plus accrued interest."
	var loan: Dictionary = loans[id]
	var removed_units := roundi(float(loan["interest_units"]) * amount / int(loan["principal_cents"]))
	loan["interest_units"] -= removed_units
	loan["principal_cents"] -= amount
	state.events._cash(state, -cost, "Loan repayment including accrued interest", false)
	_record(state, "Repaid " + state.economy.money(amount) + " of loan principal and " + state.economy.money(cost - amount) + " of accrued interest.")
	if loan["principal_cents"] == 0: loans.erase(id)
	return ""

func advance_month(state) -> void:
	for loan in loans.values():
		loan["interest_units"] += int(loan["principal_cents"]) * ANNUAL_RATE_BPS
		if state.elapsed_months >= int(loan["next_interest_month"]):
			_bill(state, loan)
			loan["next_interest_month"] += 12

func _bill(state, loan: Dictionary) -> void:
	var interest := ceili(float(loan["interest_units"]) / INTEREST_DIVISOR)
	loan["interest_units"] = 0
	if interest <= 0: return
	var opening: int = state.economy.cash_cents
	state.events._cash(state, -interest, "Annual loan interest", false)
	_record(state, "Paid " + state.economy.money(interest) + " in loan interest. Principal is unchanged.")
	if opening >= 0 and state.economy.cash_cents < 0: state.economy.crisis_started = true
	state.notify("Loan interest charged: " + state.economy.money(interest) + ".")

func settle_estate(state) -> void:
	# Creditors precede heirs. Unpaid principal survives a change of family head.
	for id in loans.keys():
		var loan: Dictionary = loans[id]
		_bill(state, loan)
		var payment := mini(maxi(0, state.economy.cash_cents), int(loan["principal_cents"]))
		if payment > 0:
			state.events._cash(state, -payment, "Estate loan settlement", false)
			loan["principal_cents"] -= payment
		if loan["principal_cents"] == 0: loans.erase(id)

func _record(state, description: String) -> void:
	state.chronicle.append({"date": state.date_text(), "description": description})

func to_save_data() -> Dictionary:
	return {"loans": loans.duplicate(true), "next_id": next_id}

func restore_save_data(data: Dictionary) -> void:
	loans = data.get("loans", {}).duplicate(true)
	next_id = data.get("next_id", 1)

static func valid(data: Variant, elapsed_months: int) -> bool:
	if not data is Dictionary or not data.get("loans") is Dictionary or not data.get("next_id") is int or data["next_id"] < 1: return false
	var total := 0
	for id in data["loans"]:
		var loan: Variant = data["loans"][id]
		if not id is String or not id.begins_with("loan_") or not id.trim_prefix("loan_").is_valid_int(): return false
		if int(id.trim_prefix("loan_")) < 1 or int(id.trim_prefix("loan_")) >= data["next_id"]: return false
		if not loan is Dictionary or loan.get("id") != id: return false
		for field in ["principal_cents", "issued_month", "next_interest_month", "interest_units"]:
			if not loan.get(field) is int or loan[field] < 0: return false
		if loan["principal_cents"] <= 0 or loan["principal_cents"] > CREDIT_LIMIT_CENTS or loan["issued_month"] > elapsed_months or loan["next_interest_month"] <= elapsed_months or loan["next_interest_month"] > elapsed_months + 12: return false
		if loan["next_interest_month"] < loan["issued_month"] + 12 or (loan["next_interest_month"] - loan["issued_month"]) % 12 != 0: return false
		if loan["interest_units"] > loan["principal_cents"] * ANNUAL_RATE_BPS * 12: return false
		total += loan["principal_cents"]
	return total <= CREDIT_LIMIT_CENTS
