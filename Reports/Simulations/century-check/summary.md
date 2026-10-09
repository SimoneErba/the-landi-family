# Century simulation results

Generated (UTC): 2026-10-09T13:22:22

100 years per run; 3 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 3/3 | 255208 | 7 | 3 | 0 | 0 | 0.00 | 0 | 0 |
| frugal | 3/3 | 250813 | 7 | 2 | 0 | 0 | 0.75 | 0 | 0 |
| education | 3/3 | 432626 | 7 | 5 | 4 | 0 | 0.00 | 0 | 0 |
| enterprise | 3/3 | 269529 | 7 | 2 | 0 | 3 | 0.60 | 0 | 0 |
| family | 3/3 | 236897 | 7 | 2 | 0 | 0 | 0.01 | 0 | 0 |

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
| passive | 1 | completed | 1200 | 220520 | 8 | 1 | none | 0 | 0 | 0 |
| passive | 2 | completed | 1200 | 259640 | 7 | 0 | none | 0 | 0 | 0 |
| passive | 3 | completed | 1200 | 255208 | 7 | 0 | none | 0 | 0 | 0 |
| frugal | 1 | completed | 1200 | 208578 | 8 | 1 | none | 32 | 0 | 0 |
| frugal | 2 | completed | 1200 | 250813 | 7 | 0 | none | 32 | 0 | 0 |
| frugal | 3 | completed | 1200 | 286312 | 7 | 0 | none | 32 | 0 | 0 |
| education | 1 | completed | 1200 | 489384 | 8 | 1 | none | 353 | 0 | 0 |
| education | 2 | completed | 1200 | 432626 | 7 | 0 | none | 347 | 0 | 0 |
| education | 3 | completed | 1200 | 423311 | 7 | 0 | none | 337 | 0 | 0 |
| enterprise | 1 | completed | 1200 | 304907 | 8 | 1 | none | 26 | 12 | 0 |
| enterprise | 2 | completed | 1200 | 211117 | 7 | 0 | none | 15 | 70 | 0 |
| enterprise | 3 | completed | 1200 | 269529 | 7 | 0 | none | 16 | 71 | 0 |
| family | 1 | completed | 1200 | 229780 | 8 | 1 | none | 121 | 0 | 2 |
| family | 2 | completed | 1200 | 255659 | 7 | 0 | none | 131 | 0 | 1 |
| family | 3 | completed | 1200 | 236897 | 7 | 0 | none | 130 | 0 | 1 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.
- People over 100 remain alive: mortality and succession are incomplete.
- Accepted marriage requests remain goals; new partners are not generated.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
