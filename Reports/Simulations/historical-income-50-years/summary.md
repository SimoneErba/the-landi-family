# Century simulation results

Generated (UTC): 2026-10-12T11:59:57

50 years per run; 1 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 1/1 | 1262 | 4 | 1 | 0 | 0 | 0.00 | 0 | 0 |
| education | 1/1 | 4033 | 4 | 2 | 1 | 0 | 0.01 | 0 | 0 |
| enterprise | 1/1 | 6448 | 4 | 1 | 0 | 3 | 0.71 | 0 | 0 |

Starting household: **authored**. Event policy: **strategy** (first_legal overrides strategy preferences).

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
| passive | 1 | completed | 600 | 1262 | 8 | 1 | none | 0 | 0 | 0 |
| education | 1 | completed | 600 | 4033 | 8 | 1 | none | 137 | 0 | 0 |
| enterprise | 1 | completed | 600 | 6448 | 8 | 1 | none | 6 | 23 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves events and succession using normal commands. Dead lines end rather than receiving invented heirs or money.
- Age-related mortality and equal-share cash wills are implemented; historical intestacy, property succession and spousal usufruct are not fully modeled. Bots request marriage goals but do not arrange partners, and do not borrow automatically.

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
