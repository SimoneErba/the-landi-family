# Century simulation results

Generated (UTC): 2026-10-12T09:07:09

100 years per run; 3 seeds per strategy, beginning at 1. Common bonus: **learning**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| education | 2/3 | 47430 | 1 | 1 | 0 | 0 | 0.04 | 1 | 0 |
| family | 2/3 | -19208 | 1 | 0 | 0 | 0 | 1.00 | 3 | 0 |

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
| education | 1 | completed | 1200 | 47430 | 5 | 3 | none | 108 | 0 | 0 |
| education | 2 | family_ended | 1125 | 19563 | 5 | 3 | 170 | 83 | 0 | 0 |
| education | 3 | completed | 1200 | 79439 | 5 | 3 | none | 122 | 0 | 0 |
| family | 1 | completed | 1200 | -17400 | 5 | 3 | 712 | 4 | 0 | 1 |
| family | 2 | family_ended | 1125 | -19208 | 5 | 3 | 529 | 4 | 0 | 0 |
| family | 3 | completed | 1200 | -21377 | 5 | 3 | 602 | 4 | 0 | 1 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.
- Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game.
- education seed 2: 
- Accepted marriage requests remain goals; new partners are not generated.
- family seed 2: 

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
