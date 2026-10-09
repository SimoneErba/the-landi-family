# External-event review — 9 October 2026

Reviewed the original 304-entry catalog against travel, persistent village property, productive businesses, activities, management and starting objectives. The catalog now contains 306 entries. Historical dates and historical incident selection were retained; changes focus on simulated consequences.

| Event group | Updated behavior |
| --- | --- |
| War | Existing food/wage disruption remains. Business costs rise 15%; departures and outbound/return movement wait for two completed months. Paid placements already in progress can continue. Travel resumes automatically, with no repeated fare and no lost placement progress. |
| Drought | Existing food-price pressure remains. Farm sales fall 35% for the full crisis duration, across player and neighboring farms. Other businesses retain their ordinary output. |
| Famine | Existing food-price pressure remains. Business costs rise 10% while supplies are scarce. |
| Property damage | Two additional incidents target actual family-owned productive buildings. Condition loss reduces output and enters village history immediately. Paid repair, a partial family patch and postponement are available. |
| House damage/maintenance | Existing condition effects now synchronize the ancestral building immediately, rather than leaving the map out of date until another month. |
| Illness | Healthy active travelers are eligible, and the event names their city. Illness pauses placements; sick managers already stop producing while upkeep continues. |
| Pregnancy and birth | Eligibility keeps age, spouse, residence and recovery restrictions. Last-two-month care leave and three months of recovery pause activities and family business management. Manager assignments are retained. Activities charge nothing while paused; ordinary wages and courses retain their existing behavior. |
| Birth notice | Adds the recovery period and reports overcrowding when residents exceed house capacity. The person's compact profile shows remaining recovery time. |

Household relief purchases reduce food-price pressure, not farm losses, transport disruption or business supply costs. Simultaneous different crises can combine within existing multiplier bounds. Old saved pending events and active crises retain their stored effects; new optional factors default to neutral when absent. No past damage is applied retroactively.

Property incidents store the affected building ID and pre-incident condition. Repair checks ownership and ongoing building work again at resolution; a sold property cannot receive a paid repair, but postponement remains a legal response. Repair can restore only the condition actually lost, even when severe damage hit a nearly ruined building. Save validation checks building references, new crisis factors, transport interruption text and recovery dates.

## Authoring and verification

`Tools/build_event_catalog.py` owns the repeated crisis/illness rules. `Data/property_events.json` retains the two new incidents. Running the generator reproduces `Data/events.json` identically; direct regeneration does not erase these additions. Simulation policies score property repairs alongside house repairs.

Passed the all-306-event/every-choice test and the new `Tests/EventFeatureTest.gd`: full-duration crisis effects and expiry, wartime input costs and prepaid transport, illness away, immediate/replayable property damage, ownership rechecks, bounded repairs, childbirth interruptions and save validation. Save, travel, activities, business, balance, century-village, profile and runner regressions also passed. Property and war popups were rendered and visually checked.

Three 100-year policy runs (education, enterprise, family; seed 1; common discount bonus) are saved under `Reports/Simulations/event-check`. They verify progression without stuck event decisions, not statistical balance across every external risk. Earlier `century-check` reports remain a record of the prior source version; reports retain source fingerprints.

## Still deferred

Mortality, succession, actual new marriage partners, inheritance transfers/ownership claims, wartime conscription, city-specific conflict zones, crop inventories, business insurance, childcare appointments and childbirth complications remain separate systems. Existing trade and inheritance payments remain simplified arrangements. These events were not expanded to invent systems that the current game cannot yet simulate.
