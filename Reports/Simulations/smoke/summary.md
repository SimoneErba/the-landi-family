# Century simulation results

Generated (UTC): 2026-10-09T13:20:58

1 years per run; 1 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 1/1 | 1954 | 7 | 0 | 0 | 0 | 0.24 | 0 | 0 |
| frugal | 1/1 | 2403 | 7 | 0 | 0 | 0 | 0.27 | 0 | 0 |
| education | 1/1 | 2000 | 7 | 0 | 0 | 0 | 0.23 | 0 | 0 |
| enterprise | 1/1 | 1972 | 7 | 0 | 0 | 0 | 0.27 | 0 | 0 |
| family | 1/1 | 1928 | 7 | 0 | 0 | 0 | 0.24 | 0 | 0 |

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
| passive | 1 | completed | 12 | 1954 | 7 | 0 | none | 0 | 0 | 0 |
| frugal | 1 | completed | 12 | 2403 | 7 | 0 | none | 2 | 0 | 0 |
| education | 1 | completed | 12 | 2000 | 7 | 0 | none | 4 | 0 | 0 |
| enterprise | 1 | completed | 12 | 1972 | 7 | 0 | none | 1 | 0 | 0 |
| family | 1 | completed | 12 | 1928 | 7 | 0 | none | 4 | 0 | 1 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.
- Accepted marriage requests remain goals; new partners are not generated.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
