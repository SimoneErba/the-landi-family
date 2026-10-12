# Fifty-year money balance experiment

160 completed runs: 600 months each, January 1800–January 1850; seeds 1–10.
Four starting households × two bonuses × two action policies. Wealth is the selected objective.

Money below matches the stable **lire displayed in-game** (accounting cents ÷ 100). Individual batch reports instead use Italian-lira equivalents (× 0.84). Every run starts with 100 lire.

**Event policy:** choose option one whenever available; otherwise the first legal option. All costs, refusals and autonomous behavior remain active.
**Routine policy:** the existing education bot makes quarterly requests for higher-paid eligible jobs and affordable courses, preserves six months of bills, and waits two years before repeating the same proposal. The player-controlled head is not assigned a new job or course by this bot.
**Passive comparison:** no proactive player requests; relatives still make their own autonomous decisions.

## Ending cash

| Start | Bonus | Actions | Median lire | Seed range | Runs with debt |
|---|---|---|---:|---:|---:|
| Alone | learning | passive | 21,569 | 20,396–22,280 | 0/10 |
| Alone | learning | education | 21,569 | 20,396–22,280 | 0/10 |
| Alone | discount | passive | 24,344 | 23,153–24,968 | 0/10 |
| Alone | discount | education | 24,344 | 23,153–24,968 | 0/10 |
| With wife | learning | passive | 30,721 | 21,459–43,163 | 0/10 |
| With wife | learning | education | 30,760 | -3,905–40,193 | 3/10 |
| With wife | discount | passive | 35,853 | 27,579–47,031 | 0/10 |
| With wife | discount | education | 25,402 | 18,225–39,476 | 1/10 |
| With child | learning | passive | 20,203 | 19,308–21,679 | 0/10 |
| With child | learning | education | 16,473 | 14,757–18,813 | 0/10 |
| With child | discount | passive | 22,879 | 21,334–24,311 | 0/10 |
| With child | discount | education | 19,399 | 18,440–22,708 | 0/10 |
| Original seven-person family | learning | passive | 122,206 | 96,949–145,428 | 0/10 |
| Original seven-person family | learning | education | 101,766 | 88,015–115,541 | 0/10 |
| Original seven-person family | discount | passive | 125,152 | 105,280–142,146 | 0/10 |
| Original seven-person family | discount | education | 77,046 | 59,009–88,312 | 0/10 |

## Cash over time: routine work/study, Quick learners

| Start | Year 0 | Year 10 | Year 20 | Year 30 | Year 40 | Year 50 |
|---|---:|---:|---:|---:|---:|---:|
| Alone | 100 | 3,242 | 7,753 | 12,347 | 17,128 | 21,569 |
| With wife | 100 | 1,297 | 1,213 | 4,662 | 12,859 | 30,760 |
| With child | 100 | 1,220 | 2,657 | 6,972 | 12,418 | 16,473 |
| Original seven-person family | 100 | 8,693 | 17,500 | 35,955 | 57,849 | 101,766 |

## Money flows: routine work/study, Quick learners

Medians are computed independently and need not add exactly to the median ending cash.

| Start | Wages over 50 years | Food | Tuition | Other net cash | Final monthly surplus | Work proposals | Study proposals | Births |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Alone | 44,914 | 7,680 | 0 | -15,699 | 67 | 0 | 0 | 0 |
| With wife | 90,576 | 32,772 | 14,900 | -15,336 | 150 | 27 | 52 | 3 |
| With child | 49,938 | 13,109 | 4,818 | -15,408 | 67 | 8 | 18 | 0 |
| Original seven-person family | 181,315 | 43,425 | 17,617 | -15,659 | 522 | 66 | 82 | 0 |

## Findings

- 4/160 runs experienced a negative month-end balance. Option one was used for 67,254/67,645 resolved events; 391 used a later legal option.
- Cash accumulates substantially even with no proactive requests. Routine study typically lowers ending cash relative to the passive policy; this bot frequently spends on further courses and suspends wages during full-time study.
- All four debt runs started with a wife and used routine work/study. One Quick learners run (seed 2) had five births, first entered debt in month 146, spent 455 months in debt, and ended at -3,904.75 lire. The other three debt runs recovered. Household growth can create a persistent deficit despite easy accumulation in the typical run.
- The unchanged family head earns 80 lire/month while base food costs 10 lire/person/month. Food inflates by only 0.5% annually. This produces persistent surplus without business investment.
- Routine costs primarily cover food and tuition; housing and other cash pressures mostly arise through events rather than a full recurring maintenance/health/tax economy.
- Existing retirement, mortality, succession and inheritance are incomplete. Very old original-family workers remain alive and earning; no complete generational money balance can be inferred from these results.
- The wife-start initialization bug that cleared pregnancy eligibility was fixed before the final wife batches. New births in those batches come from the actual pregnancy system.
- A successful 600-month run means the simulation completed; it does not mean the million-Italian-lire wealth objective was achieved.
- Assessment: money pressure is uneven rather than balanced across household growth. Before changing numbers, test recurring housing/care costs, retirement and generational transitions, education commitments under a growing household, and practical recovery from sustained debt. Economic rules were not retuned in this experiment.

## Reproduce

```powershell
godot --headless --audio-driver Dummy --path . --script Tools/RunSimulations.gd -- --years=50 --seeds=10 --strategies=passive,education --starting-family=wife --event-policy=first_legal --bonus=learning --objective=wealth --output=res://Reports/Simulations/balance-50-years/wife-learning
```

Repeat with alone, child and authored; then use bonus=discount for the second comparison. Run `Tools/AnalyzeBalance.py` to regenerate this overview.

[Structured summary](balance-summary.json). Each household/bonus directory contains its full results, annual checkpoints and decision samples.
