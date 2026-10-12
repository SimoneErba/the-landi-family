# Century simulation results

Generated (UTC): 2026-10-12T08:24:25

50 years per run; 10 seeds per strategy, beginning at 1. Common bonus: **learning**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 10/10 | 7605 | 5 | 0 | 0 | 0 | 0.01 | 1 | 0 |
| education | 10/10 | 25463 | 5 | 4 | 1 | 0 | 0.02 | 4 | 0 |

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
| passive | 1 | completed | 600 | 7209 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 2 | completed | 600 | 5289 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 3 | completed | 600 | 7480 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 4 | completed | 600 | 11020 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 5 | completed | 600 | 7400 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 6 | completed | 600 | 10552 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 7 | completed | 600 | 19046 | 3 | 1 | none | 0 | 0 | 0 |
| passive | 8 | completed | 600 | 7730 | 5 | 3 | none | 0 | 0 | 0 |
| passive | 9 | completed | 600 | 10553 | 4 | 2 | none | 0 | 0 | 0 |
| passive | 10 | completed | 600 | -46 | 6 | 4 | 600 | 0 | 0 | 0 |
| education | 1 | completed | 600 | 21278 | 5 | 3 | none | 75 | 0 | 0 |
| education | 2 | completed | 600 | 11930 | 5 | 3 | 170 | 69 | 0 | 0 |
| education | 3 | completed | 600 | 26224 | 5 | 3 | none | 76 | 0 | 0 |
| education | 4 | completed | 600 | 27601 | 5 | 3 | 156 | 68 | 0 | 0 |
| education | 5 | completed | 600 | 30079 | 5 | 3 | none | 76 | 0 | 0 |
| education | 6 | completed | 600 | 31602 | 6 | 4 | 77 | 90 | 0 | 0 |
| education | 7 | completed | 600 | 13703 | 3 | 1 | none | 50 | 0 | 0 |
| education | 8 | completed | 600 | 25859 | 5 | 3 | 204 | 69 | 0 | 0 |
| education | 9 | completed | 600 | 14779 | 4 | 2 | none | 60 | 0 | 0 |
| education | 10 | completed | 600 | 25068 | 6 | 4 | none | 88 | 0 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
