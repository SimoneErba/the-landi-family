# Century simulation results

Generated (UTC): 2026-10-12T08:26:52

50 years per run; 10 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 10/10 | 42968 | 7 | 3 | 0 | 0 | 0.01 | 0 | 0 |
| education | 10/10 | 16625 | 7 | 4 | 2 | 0 | 0.01 | 0 | 0 |

Starting household: **authored**. Event policy: **first_legal** (first_legal overrides strategy preferences).

## Player strategies

- Passive: first legal event choice; no proactive requests.
- Frugal: favor money and health/property recovery; suggest better eligible employment.
- Education: fund sustainable courses and better jobs; favor learning and supportive event choices.
- Enterprise: preserve six months of household bills; buy land, build up to three businesses, request managers and renovate.
- Family: support relationships, ask departing relatives to stay or return, request marriage and expand overcrowded housing.

All requests can be refused. Proactive decisions happen quarterly; repeated requests wait two years. Construction and courses pay real costs. No relatives, spouses, qualifications or money are created by the test player.

## Individual runs

| Strategy | Seed | Status | Months | Cash | Peak living | Births | First debt month | Requests | Managers asked | Marriage goals remaining |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 1 | completed | 600 | 23058 | 8 | 1 | none | 0 | 0 | 0 |
| passive | 2 | completed | 600 | 41707 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 3 | completed | 600 | 44228 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 4 | completed | 600 | 26091 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 5 | completed | 600 | 46571 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 6 | completed | 600 | 51129 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 7 | completed | 600 | 35809 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 8 | completed | 600 | 40428 | 8 | 1 | none | 0 | 0 | 0 |
| passive | 9 | completed | 600 | 57116 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 10 | completed | 600 | 54297 | 7 | 0 | none | 0 | 0 | 0 |
| education | 1 | completed | 600 | 21523 | 8 | 1 | none | 142 | 0 | 0 |
| education | 2 | completed | 600 | 17144 | 7 | 0 | none | 131 | 0 | 0 |
| education | 3 | completed | 600 | 12497 | 7 | 0 | none | 122 | 0 | 0 |
| education | 4 | completed | 600 | 11009 | 7 | 0 | none | 129 | 0 | 0 |
| education | 5 | completed | 600 | 15357 | 7 | 0 | none | 139 | 0 | 0 |
| education | 6 | completed | 600 | 16106 | 7 | 0 | none | 102 | 0 | 0 |
| education | 7 | completed | 600 | 15680 | 7 | 0 | none | 139 | 0 | 0 |
| education | 8 | completed | 600 | 29712 | 8 | 1 | none | 149 | 0 | 0 |
| education | 9 | completed | 600 | 20983 | 7 | 0 | none | 136 | 0 | 0 |
| education | 10 | completed | 600 | 19684 | 7 | 0 | none | 142 | 0 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.
- People over 100 remain alive: mortality and succession are incomplete.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
