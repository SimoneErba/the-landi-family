# Century simulation results

Generated (UTC): 2026-10-12T10:22:12

100 years per run; 1 seeds per strategy, beginning at 1. Common bonus: **discount**. Selected objective: **wealth**.

Batch status: complete. Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.

| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 0/1 | 6581 | 0 | 0 | 0 | 0 | 0.00 | 0 | 0 |
| education | 0/1 | 23248 | 0 | 0 | 0 | 0 | 0.00 | 0 | 0 |
| enterprise | 0/1 | 17254 | 0 | 0 | 0 | 3 | 0.00 | 0 | 0 |

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
| passive | 1 | family_ended | 857 | 6581 | 8 | 1 | none | 0 | 0 | 0 |
| education | 1 | family_ended | 857 | 23248 | 8 | 1 | none | 151 | 0 | 0 |
| enterprise | 1 | family_ended | 857 | 17254 | 8 | 1 | none | 3 | 36 | 0 |

## Interpretation limits

- Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.
- All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.
- The runner resolves events and succession using normal commands. Dead lines end rather than receiving invented heirs or money.
- Age-related mortality and equal-share cash wills are implemented; historical intestacy, property succession and spousal usufruct are not fully modeled. Bots request marriage goals but do not arrange partners, and do not borrow automatically.
- passive seed 1: 
- education seed 1: 
- enterprise seed 1: 

[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)
