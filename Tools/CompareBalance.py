"""Compare the unchanged baseline experiment with the tuned economy."""
import json
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
BEFORE = ROOT / "Reports/Simulations/balance-50-years"
AFTER = ROOT / "Reports/Simulations/balanced-50-years"
names = {"alone": "Alone", "wife": "With wife", "child": "With child", "authored": "Original seven-person family"}
rows = []
all_after = []
for family in names:
    for bonus in ("learning", "discount"):
        old = json.loads((BEFORE / f"{family}-{bonus}/results.json").read_text())
        new = json.loads((AFTER / f"{family}-{bonus}/results.json").read_text())
        assert new["completed"] and len(new["runs"]) == 20
        assert all(r["status"] == "completed" and r["months_simulated"] == 600 for r in new["runs"])
        all_after.extend(new["runs"])
        for strategy in ("passive", "education"):
            a = [r for r in old["runs"] if r["strategy"] == strategy]
            b = [r for r in new["runs"] if r["strategy"] == strategy]
            rows.append(dict(family=family, bonus=bonus, strategy=strategy,
                             before=median(r["final"]["cash_basis_cents"] / 100 for r in a),
                             after=median(r["final"]["cash_basis_cents"] / 100 for r in b),
                             minimum=min(r["final"]["cash_basis_cents"] / 100 for r in b),
                             maximum=max(r["final"]["cash_basis_cents"] / 100 for r in b),
                             before_debt=sum(r["debt_months"] > 0 for r in a),
                             after_debt=sum(r["debt_months"] > 0 for r in b),
                             ending_debt=sum(r["final"]["cash_basis_cents"] < 0 for r in b),
                             max_debt_months=max(r["debt_months"] for r in b)))
summary = dict(runs=len(all_after), rows=rows,
               debt_runs=sum(r["debt_months"] > 0 for r in all_after),
               ending_debt_runs=sum(r["final"]["cash_basis_cents"] < 0 for r in all_after),
               max_debt_months=max(r["debt_months"] for r in all_after))
(AFTER / "comparison.json").write_text(json.dumps(summary, indent=2) + "\n")
lines = ["# Economy balance pass — fifty-year comparison", "",
         "Same experiment as the baseline: 160 completed runs of 600 months, seeds 1–10, four starts, two bonuses, passive and routine work/study policies. All start with 100 lire and the wealth objective. Events use the first available option; normal consent and autonomous behavior remain active.",
         "", "Amounts below match **in-game lire**. Batch summaries use Italian-lira equivalents (in-game amount × 0.84). Changes to event eligibility mean random streams can diverge despite identical initial seeds.", "",
         "## Changes", "",
         "- Monthly essentials: 5 lire per adult, 2.5 per child, adjusted by the existing price index and discount bonus.",
         "- Monthly care: 1.5 lire for children under six; 4 lire for relatives aged 70 and above.",
         "- Upkeep: 4 lire per house plus 2 per room per month. Expansion increases upkeep.",
         "- Food portions: 65% of the adult allowance below age 13, 85% for teenagers. This is a gameplay cost estimate.",
         "- Earnings gradually fall after 60: 50% at 85, reaching zero at 95. No pension or cash bailout is invented. Illness still halves effective earnings.",
         "- In debt, simpler food costs 15% less and essentials/upkeep are halved. Care is protected; residents lose 0.01 happiness each economizing month.",
         "- New/resumed full-time courses must leave three months of living costs plus their projected full-course income shortfall in reserve. Children already on the way are included.",
         "- After three unfunded months, adults suspend a course, preserve progress and return to previous paid work or seek a new job. Resuming the same course still needs consent and affordable funding.",
         "- Expansion events require limited spare capacity, accounting for expected births. Manual renovation remains available.",
         "- Finances, expense history, portraits and profiles display the actual costs and reduced earnings. Earlier saved ledger entries remain readable.", "",
         "## Results: routine work/study, Quick learners", "",
         "| Start | Before: median cash | After: median cash | After: seed range | Debt runs | Ended in debt |",
         "|---|---:|---:|---:|---:|---:|"]
for r in rows:
    if r["bonus"] == "learning" and r["strategy"] == "education":
        lines.append(f"| {names[r['family']]} | {r['before']:,.0f} | {r['after']:,.0f} | {r['minimum']:,.0f}–{r['maximum']:,.0f} | {r['after_debt']}/10 | {r['ending_debt']}/10 |")
lines += ["", "## All comparisons", "", "| Start | Bonus | Policy | Before cash | After cash | Before debt runs | After debt runs | After months in debt, worst run |", "|---|---|---|---:|---:|---:|---:|---:|"]
for r in rows:
    lines.append(f"| {names[r['family']]} | {r['bonus']} | {r['strategy']} | {r['before']:,.0f} | {r['after']:,.0f} | {r['before_debt']}/10 | {r['after_debt']}/10 | {r['max_debt_months']} |")
lines += ["", "## Assessment", "",
          f"- {summary['debt_runs']}/160 runs entered month-end debt; {summary['ending_debt_runs']}/160 ended there. The largest total time in debt was {summary['max_debt_months']} months, compared with 455 months in the baseline's worst case.",
          "- All 80 routine work/study runs finished with positive balances. The one negative ending was a passive wife-start run at -55.04 lire, first entering debt in the last month.",
          "- Small households now have much less spare money, and work/study has a meaningful opportunity cost. Educating several children can still produce a successful household; it is no longer uniformly worse than doing nothing.",
          "- Larger initial families can still generate considerable savings. Costs follow residents and house size rather than applying an arbitrary wealth cap. Business investment and the million-Italian-lire legacy target need separate tuning.",
          "- This is a more useful first economy balance, not complete generational balance. Mortality, succession and inheritance remain incomplete. The aging curve is a transparent prototype assumption, not a claim about historical retirement or disability.",
          "", "## Validation", "", "Economy, aging/illness contributions, dependent care, expansion context, course affordability, saved suspended progress, paid-work recovery, event rules and finances presentation have targeted checks. Existing simulation, save, career, influence, activity, travel, marriage and legacy suites are exercised alongside the 50-year benchmark.",
          "", "## Reproduce", "", "```powershell", "godot --headless --audio-driver Dummy --path . --script Tools/RunSimulations.gd -- --years=50 --seeds=10 --strategies=passive,education --starting-family=wife --event-policy=first_legal --bonus=learning --objective=wealth --output=res://Reports/Simulations/balanced-50-years/wife-learning", "```", "", "Repeat for alone, child and authored, and for bonus=discount. Run `Tools/CompareBalance.py` to regenerate this comparison.", "", "[Structured comparison](comparison.json). Each household/bonus directory contains its full results, yearly CSV and decision samples.", ""]
(AFTER / "comparison.md").write_text("\n".join(lines), encoding="utf-8")
print(json.dumps(summary, indent=2))
