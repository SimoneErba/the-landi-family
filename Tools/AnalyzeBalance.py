"""Summarize the 50-year first-option balance experiment, using in-game lire."""
import json
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Reports/Simulations/balance-50-years"
names = {"alone": "Alone", "wife": "With wife", "child": "With child", "authored": "Original seven-person family"}
batches = []
for family in names:
    for bonus in ("learning", "discount"):
        data = json.loads((OUT / f"{family}-{bonus}/results.json").read_text(encoding="utf-8"))
        assert data["completed"] and len(data["runs"]) == 20
        assert all(r["status"] == "completed" and r["months_simulated"] == 600 for r in data["runs"])
        batches.append((family, bonus, data))

rows = []
for family, bonus, batch in batches:
    for strategy in ("passive", "education"):
        runs = [r for r in batch["runs"] if r["strategy"] == strategy]
        cash = [r["final"]["cash_basis_cents"] / 100 for r in runs]
        row = dict(family=family, bonus=bonus, strategy=strategy, median_cash=median(cash),
                   min_cash=min(cash), max_cash=max(cash), debt_runs=sum(r["debt_months"] > 0 for r in runs),
                   median_income=median(r["income_basis_cents"] / 100 for r in runs),
                   median_food=median(r["food_basis_cents"] / 100 for r in runs),
                   median_tuition=median(r["tuition_basis_cents"] / 100 for r in runs),
                   median_residents=median(r["final"]["residents"] for r in runs),
                   median_births=median(r["final"]["births"] for r in runs),
                   median_graduates=median(r["final"]["graduates"] for r in runs),
                   median_work=median(r["decisions"].get("request:work", 0) for r in runs),
                   median_study=median(r["decisions"].get("request:train", 0) for r in runs),
                   median_monthly_net=median(r["final_monthly_budget"]["net_cents"] / 100 for r in runs),
                   fallback_events=sum(r["decisions"].get("event:other_option", 0) for r in runs),
                   total_events=sum(r["decisions"].get("event", 0) for r in runs),
                   trajectory={str(year): median(r["checkpoints"][year]["cash_basis_cents"] / 100 for r in runs)
                               for year in (0, 10, 20, 30, 40, 50)})
        # Residual includes event spending/receipts, theft and any other cash movements.
        row["median_other_net"] = median((r["final"]["cash_basis_cents"] - 10000 - r["income_basis_cents"]
                                         + r["food_basis_cents"] + r["tuition_basis_cents"]
                                         - r["business_net_basis_cents"]) / 100 for r in runs)
        rows.append(row)

all_runs = [r for _, _, b in batches for r in b["runs"]]
summary = {"years": 50, "runs": len(all_runs), "debt_runs": sum(r["debt_months"] > 0 for r in all_runs), "rows": rows}
(OUT / "balance-summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

lines = ["# Fifty-year money balance experiment", "", "160 completed runs: 600 months each, January 1800–January 1850; seeds 1–10.",
         "Four starting households × two bonuses × two action policies. Wealth is the selected objective.", "",
         "Money below matches the stable **lire displayed in-game** (accounting cents ÷ 100). Individual batch reports instead use Italian-lira equivalents (× 0.84). Every run starts with 100 lire.", "",
         "**Event policy:** choose option one whenever available; otherwise the first legal option. All costs, refusals and autonomous behavior remain active.",
         "**Routine policy:** the existing education bot makes quarterly requests for higher-paid eligible jobs and affordable courses, preserves six months of bills, and waits two years before repeating the same proposal. The player-controlled head is not assigned a new job or course by this bot.",
         "**Passive comparison:** no proactive player requests; relatives still make their own autonomous decisions.", "",
         "## Ending cash", "", "| Start | Bonus | Actions | Median lire | Seed range | Runs with debt |", "|---|---|---|---:|---:|---:|"]
for r in rows:
    lines.append(f"| {names[r['family']]} | {r['bonus']} | {r['strategy']} | {r['median_cash']:,.0f} | {r['min_cash']:,.0f}–{r['max_cash']:,.0f} | {r['debt_runs']}/10 |")
lines += ["", "## Cash over time: routine work/study, Quick learners", "", "| Start | Year 0 | Year 10 | Year 20 | Year 30 | Year 40 | Year 50 |", "|---|---:|---:|---:|---:|---:|---:|"]
for r in rows:
    if r["strategy"] == "education" and r["bonus"] == "learning":
        lines.append("| " + names[r["family"]] + " | " + " | ".join(f"{v:,.0f}" for v in r["trajectory"].values()) + " |")
lines += ["", "## Money flows: routine work/study, Quick learners", "", "Medians are computed independently and need not add exactly to the median ending cash.", "", "| Start | Wages over 50 years | Food | Tuition | Other net cash | Final monthly surplus | Work proposals | Study proposals | Births |", "|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
for r in rows:
    if r["strategy"] == "education" and r["bonus"] == "learning":
        lines.append(f"| {names[r['family']]} | {r['median_income']:,.0f} | {r['median_food']:,.0f} | {r['median_tuition']:,.0f} | {r['median_other_net']:,.0f} | {r['median_monthly_net']:,.0f} | {r['median_work']:.0f} | {r['median_study']:.0f} | {r['median_births']:.0f} |")
events = sum(r["total_events"] for r in rows)
fallbacks = sum(r["fallback_events"] for r in rows)
lines += ["", "## Findings", "", f"- {summary['debt_runs']}/{len(all_runs)} runs experienced a negative month-end balance. Option one was used for {events-fallbacks:,}/{events:,} resolved events; {fallbacks:,} used a later legal option.",
          "- Cash accumulates substantially even with no proactive requests. Routine study typically lowers ending cash relative to the passive policy; this bot frequently spends on further courses and suspends wages during full-time study.",
          "- All four debt runs started with a wife and used routine work/study. One Quick learners run (seed 2) had five births, first entered debt in month 146, spent 455 months in debt, and ended at -3,904.75 lire. The other three debt runs recovered. Household growth can create a persistent deficit despite easy accumulation in the typical run.",
          "- The unchanged family head earns 80 lire/month while base food costs 10 lire/person/month. Food inflates by only 0.5% annually. This produces persistent surplus without business investment.",
          "- Routine costs primarily cover food and tuition; housing and other cash pressures mostly arise through events rather than a full recurring maintenance/health/tax economy.",
          "- Existing retirement, mortality, succession and inheritance are incomplete. Very old original-family workers remain alive and earning; no complete generational money balance can be inferred from these results.",
          "- The wife-start initialization bug that cleared pregnancy eligibility was fixed before the final wife batches. New births in those batches come from the actual pregnancy system.",
          "- A successful 600-month run means the simulation completed; it does not mean the million-Italian-lire wealth objective was achieved.",
          "- Assessment: money pressure is uneven rather than balanced across household growth. Before changing numbers, test recurring housing/care costs, retirement and generational transitions, education commitments under a growing household, and practical recovery from sustained debt. Economic rules were not retuned in this experiment.",
          "", "## Reproduce", "", "```powershell", "godot --headless --audio-driver Dummy --path . --script Tools/RunSimulations.gd -- --years=50 --seeds=10 --strategies=passive,education --starting-family=wife --event-policy=first_legal --bonus=learning --objective=wealth --output=res://Reports/Simulations/balance-50-years/wife-learning", "```", "",
          "Repeat with alone, child and authored; then use bonus=discount for the second comparison. Run `Tools/AnalyzeBalance.py` to regenerate this overview.", "",
          "[Structured summary](balance-summary.json). Each household/bonus directory contains its full results, annual checkpoints and decision samples.", ""]
(OUT / "balance-review.md").write_text("\n".join(lines), encoding="utf-8")
print(json.dumps(summary, indent=2))
