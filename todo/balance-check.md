# Prototype balance check — 9 October 2026

## Changes applied

| Value | Before | After | Reason |
| --- | --- | --- | --- |
| Annual food inflation | 2% | 0.5% | Wages remain fixed. Previously even an 80-lira wage could not feed two residents after 100 years. |
| Factory base sales/month | 22 lire | 28 lire | An adequately staffed, ordinary NPC factory previously lost money at its starting condition. |
| Factory materials/month | 10 lire | 11 lire | Preserve substantial input costs and avoid making industrial conversion an automatic winning choice. |
| Factory upkeep/month | 2 lire | 2.5 lire | Balance the improved sales margin and retain idle-property costs. |
| Manager stress/month, alongside a paid job | +0.025 | +0.016 | Ordinary recovery is −0.01/month; the previous net burden quickly overwhelmed managers. |
| Manager stress/month, without another paid job | +0.025 | +0.008 | Full-time management allows recovery; a second job still creates sustained pressure. |
| Neighbor investment reserve | None | 12 lire + three months of owned productive-property expenses | Avoid spending operating capital on construction and renovation. |

Construction prices, ordinary wages, goal targets, learning gains, family bonuses and refund values remain as before. The one-million-lire and 100-person targets are the requested objectives.

## Method and results

`Tools/BalanceCheck.gd` measures eight controlled productive-property scenarios (four types at levels 1 and 3), twelve household wage/year scenarios, and seeded 100-year autonomous family runs. The baseline used eight event seeds for each of two policies: save money with the discount bonus, and support family requests with the fertility bonus. The final values were rerun against seeds 1 and 2 for both policies. Four additional intermediate runs checked the initial adjustment, for 24 century runs overall. Policies are fixed test strategies, not optimal play, and their different bonuses mean this is not an isolated bonus comparison.

- Over a century, the food-price multiplier falls from **7.38× to 1.65×**. A 35-lira monthly wage feeding two people changes from a 112.54-lira monthly loss to a 2.02-lira surplus at the endpoint. Poverty and dependent households still create real costs.
- An NPC level-one factory at 80% condition, before infrastructure bonuses, changes from **−0.56 to +1.06 lire/month**. It still requires two workers. Poorly maintained factories lose money; inadequate labor produces no sales.
- Healthy family businesses with skill 50 have an approximate **1.5–4.8-year operating payback** across the checked levels. Payback includes the base building plus the renovations needed to reach that level; it excludes land acquisition, construction downtime, future deterioration, and skill growth. Factory level-one annual net rises from 46.08 to 79.92 lire. Farm, workshop and tavern values were retained.
- A manager starting at stress 0.2, with normal recovery and another paid job, reaches about **0.56 rather than 1.0** after five years of ordinary management. Without another paid job, stress falls to about **0.08**. Illness, debt, overcrowding and family conflicts can still add pressure; relatives can still resign.
- In the four matched century runs, the poorest neighbor ends with **447.30–447.97 lire**, versus **16.66–22.05 lire** before. Village development still reaches 37 total buildings in those runs; the reserve does not stop development.
- The same family runs end at **19.7–24.7% of the wealth target**, versus **6.5–12.5%** before, without crossing into household debt. Living family size peaks at **7–8** in both versions.

Full measurements are in [balance-results.json](balance-results.json). Run the tool with `-- --seeds=8` to repeat the larger sample; its default uses two seeds per policy and writes to `.godot/balance-results.json`.

## Remaining balance gaps

The tested starter family is financially comfortable, so these changes chiefly protect smaller working households and productive-property managers. The million-lire goal is still far beyond either tested strategy. The 100-person goal cannot be balanced by the fertility multiplier alone: the prototype needs a complete marriage, household formation, mortality and succession loop to provide enough generational growth. These runs evaluate implemented economics and autonomous decisions, not a complete century-long victory model. No claim of global strategy balance or objective reachability is made.

The three family bonuses also cannot yet be compared as equivalent paths to victory while these progression systems are incomplete. Crop inventories, business debt, shared ownership, stronger wealth progression and fuller generational mechanics should precede another objective/bonus pass.

## Verification

Passed: `BalanceTest`, `EconomyTest`, `VillageBusinessTest`, `SaveGameTest`, `GameplayLayerTest`, `VillageDevelopmentTest`, `TravelTest`, `EventSystemTest`, `CareersTest`.

The new balance checks enforce long-term food affordability for a modest working couple, profitable healthy factories with enough labor, losses under neglect, several-year business payback, operating reserves and sustainable management pressure.
