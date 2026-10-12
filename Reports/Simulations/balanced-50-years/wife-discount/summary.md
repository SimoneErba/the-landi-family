# Century simulation results

Generated (UTC): 2026-10-12T08:26:24

50 years per run; 10 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 10/10 | 13322 | 5 | 0 | 0 | 0 | 0.01 | 0 | 0 |
| education | 10/10 | 24509 | 5 | 4 | 0 | 0 | 0.01 | 1 | 0 |

Starting household: **wife**. Event policy: **first_legal** (first_legal overrides strategy preferences).

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
| passive | 1 | completed | 600 | 12978 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 2 | completed | 600 | 11126 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 3 | completed | 600 | 13285 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 4 | completed | 600 | 16310 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 5 | completed | 600 | 13159 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 6 | completed | 600 | 15922 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 7 | completed | 600 | 23533 | 3 | 1 | none | 0 | 0 | 0 |
| passive | 8 | completed | 600 | 13359 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 9 | completed | 600 | 15834 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 10 | completed | 600 | 6385 | 6 | 4 | none | 0 | 0 | 0 |
| education | 1 | completed | 600 | 19293 | 5 | 3 | none | 68 | 0 | 0 |
| education | 2 | completed | 600 | 15346 | 5 | 3 | 163 | 75 | 0 | 0 |
| education | 3 | completed | 600 | 26690 | 5 | 3 | none | 70 | 0 | 0 |
| education | 4 | completed | 600 | 25611 | 4 | 2 | none | 61 | 0 | 0 |
| education | 5 | completed | 600 | 27726 | 5 | 3 | none | 73 | 0 | 0 |
| education | 6 | completed | 600 | 30659 | 4 | 2 | none | 64 | 0 | 0 |
| education | 7 | completed | 600 | 17454 | 3 | 1 | none | 52 | 0 | 0 |
| education | 8 | completed | 600 | 25588 | 5 | 3 | none | 68 | 0 | 0 |
| education | 9 | completed | 600 | 23409 | 4 | 2 | none | 61 | 0 | 0 |
| education | 10 | completed | 600 | 23429 | 6 | 4 | none | 81 | 0 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
