# Century simulation results

Generated (UTC): 2026-10-09T15:22:23

100 years per run; 1 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| education | 1/1 | 489384 | 8 | 5 | 4 | 0 | 0.00 | 0 | 0 |
| enterprise | 1/1 | 242851 | 8 | 2 | 0 | 3 | 0.72 | 0 | 0 |
| family | 1/1 | 229780 | 8 | 2 | 1 | 0 | 0.01 | 0 | 0 |

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
| education | 1 | completed | 1200 | 489384 | 8 | 1 | none | 353 | 0 | 0 |
| enterprise | 1 | completed | 1200 | 242851 | 8 | 1 | none | 22 | 9 | 0 |
| family | 1 | completed | 1200 | 229780 | 8 | 1 | none | 121 | 0 | 2 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.
- People over 100 remain alive: mortality and succession are incomplete.
- Accepted marriage requests remain goals; new partners are not generated.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
