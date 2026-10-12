# Century simulation results

Generated (UTC): 2026-10-12T08:24:25

50 years per run; 10 seeds per strategy, beginning at 1. Common bonus: **learning**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 10/10 | 6468 | 2 | 1 | 0 | 0 | 0.01 | 0 | 0 |
| education | 10/10 | 1871 | 2 | 1 | 1 | 0 | 0.02 | 1 | 0 |

Starting household: **child**. Event policy: **first_legal** (first_legal overrides strategy preferences).

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
| passive | 1 | completed | 600 | 6855 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 2 | completed | 600 | 6659 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 3 | completed | 600 | 5179 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 4 | completed | 600 | 5460 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 5 | completed | 600 | 6169 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 6 | completed | 600 | 5333 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 7 | completed | 600 | 6370 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 8 | completed | 600 | 6778 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 9 | completed | 600 | 7537 | 2 | 0 | none | 0 | 0 | 0 |
| passive | 10 | completed | 600 | 6565 | 2 | 0 | none | 0 | 0 | 0 |
| education | 1 | completed | 600 | 3689 | 2 | 0 | none | 13 | 0 | 0 |
| education | 2 | completed | 600 | 1086 | 2 | 0 | 160 | 24 | 0 | 0 |
| education | 3 | completed | 600 | 1292 | 2 | 0 | none | 24 | 0 | 0 |
| education | 4 | completed | 600 | 2833 | 2 | 0 | none | 12 | 0 | 0 |
| education | 5 | completed | 600 | 4820 | 2 | 0 | none | 11 | 0 | 0 |
| education | 6 | completed | 600 | 2068 | 2 | 0 | none | 26 | 0 | 0 |
| education | 7 | completed | 600 | 1150 | 2 | 0 | none | 28 | 0 | 0 |
| education | 8 | completed | 600 | 1674 | 2 | 0 | none | 27 | 0 | 0 |
| education | 9 | completed | 600 | 2348 | 2 | 0 | none | 28 | 0 | 0 |
| education | 10 | completed | 600 | 1305 | 2 | 0 | none | 25 | 0 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
