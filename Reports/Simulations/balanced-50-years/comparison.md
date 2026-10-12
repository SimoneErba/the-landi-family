# Economy balance pass — fifty-year comparison

Same experiment as the baseline: 160 completed runs of 600 months, seeds 1–10, four starts, two bonuses, passive and routine work/study policies. All start with 100 lire and the wealth objective. Events use the first available option; normal consent and autonomous behavior remain active.

Amounts below match **in-game lire**. Batch summaries use Italian-lira equivalents (in-game amount × 0.84). Changes to event eligibility mean random streams can diverge despite identical initial seeds.

## Changes

- Monthly essentials: 5 lire per adult, 2.5 per child, adjusted by the existing price index and discount bonus.
- Monthly care: 1.5 lire for children under six; 4 lire for relatives aged 70 and above.
- Upkeep: 4 lire per house plus 2 per room per month. Expansion increases upkeep.
- Food portions: 65% of the adult allowance below age 13, 85% for teenagers. This is a gameplay cost estimate.
- Earnings gradually fall after 60: 50% at 85, reaching zero at 95. No pension or cash bailout is invented. Illness still halves effective earnings.
- In debt, simpler food costs 15% less and essentials/upkeep are halved. Care is protected; residents lose 0.01 happiness each economizing month.
- New/resumed full-time courses must leave three months of living costs plus their projected full-course income shortfall in reserve. Children already on the way are included.
- After three unfunded months, adults suspend a course, preserve progress and return to previous paid work or seek a new job. Resuming the same course still needs consent and affordable funding.
- Expansion events require limited spare capacity, accounting for expected births. Manual renovation remains available.
- Finances, expense history, portraits and profiles display the actual costs and reduced earnings. Earlier saved ledger entries remain readable.

## Results: routine work/study, Quick learners

| Start | Before: median cash | After: median cash | After: seed range | Debt runs | Ended in debt |
|---|---:|---:|---:|---:|---:|
| Alone | 21,569 | 8,716 | 8,334–9,845 | 0/10 | 0/10 |
| With wife | 30,760 | 30,314 | 14,202–37,621 | 4/10 | 0/10 |
| With child | 16,473 | 2,227 | 1,292–5,738 | 1/10 | 0/10 |
| Original seven-person family | 101,766 | 30,816 | 17,472–36,693 | 0/10 | 0/10 |

## All comparisons

| Start | Bonus | Policy | Before cash | After cash | Before debt runs | After debt runs | After months in debt, worst run |
|---|---|---|---:|---:|---:|---:|---:|
| Alone | learning | passive | 21,569 | 8,716 | 0/10 | 0/10 | 0 |
| Alone | learning | education | 21,569 | 8,716 | 0/10 | 0/10 | 0 |
| Alone | discount | passive | 24,344 | 12,460 | 0/10 | 0/10 | 0 |
| Alone | discount | education | 24,344 | 12,460 | 0/10 | 0/10 | 0 |
| With wife | learning | passive | 30,721 | 9,053 | 0/10 | 1/10 | 1 |
| With wife | learning | education | 30,760 | 30,314 | 3/10 | 4/10 | 3 |
| With wife | discount | passive | 35,853 | 15,860 | 0/10 | 0/10 | 0 |
| With wife | discount | education | 25,402 | 29,177 | 1/10 | 1/10 | 4 |
| With child | learning | passive | 20,203 | 7,699 | 0/10 | 0/10 | 0 |
| With child | learning | education | 16,473 | 2,227 | 0/10 | 1/10 | 1 |
| With child | discount | passive | 22,879 | 11,993 | 0/10 | 0/10 | 0 |
| With child | discount | education | 19,399 | 6,472 | 0/10 | 0/10 | 0 |
| Original seven-person family | learning | passive | 122,206 | 49,382 | 0/10 | 0/10 | 0 |
| Original seven-person family | learning | education | 101,766 | 30,816 | 0/10 | 0/10 | 0 |
| Original seven-person family | discount | passive | 125,152 | 51,152 | 0/10 | 0/10 | 0 |
| Original seven-person family | discount | education | 77,046 | 19,792 | 0/10 | 0/10 | 0 |

## Assessment

- 7/160 runs entered month-end debt; 1/160 ended there. The largest total time in debt was 4 months, compared with 455 months in the baseline's worst case.
- All 80 routine work/study runs finished with positive balances. The one negative ending was a passive wife-start run at -55.04 lire, first entering debt in the last month.
- Small households now have much less spare money, and work/study has a meaningful opportunity cost. Educating several children can still produce a successful household; it is no longer uniformly worse than doing nothing.
- Larger initial families can still generate considerable savings. Costs follow residents and house size rather than applying an arbitrary wealth cap. Business investment and the million-Italian-lire legacy target need separate tuning.
- This is a more useful first economy balance, not complete generational balance. Mortality, succession and inheritance remain incomplete. The aging curve is a transparent prototype assumption, not a claim about historical retirement or disability.

## Validation

Economy, aging/illness contributions, dependent care, expansion context, course affordability, saved suspended progress, paid-work recovery, event rules and finances presentation have targeted checks. Existing simulation, save, career, influence, activity, travel, marriage and legacy suites are exercised alongside the 50-year benchmark.

## Reproduce

```powershell
godot --headless --audio-driver Dummy --path . --script Tools/RunSimulations.gd -- --years=50 --seeds=10 --strategies=passive,education --starting-family=wife --event-policy=first_legal --bonus=learning --objective=wealth --output=res://Reports/Simulations/balanced-50-years/wife-learning
```

Repeat for alone, child and authored, and for bonus=discount. Run `Tools/CompareBalance.py` to regenerate this comparison.

[Structured comparison](comparison.json). Each household/bonus directory contains its full results, yearly CSV and decision samples.
