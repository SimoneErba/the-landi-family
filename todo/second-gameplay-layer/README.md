# Second gameplay layer

Status: **first playable slice integrated, work in progress**. Activities in person profiles and Village are available in the game; monthly activity progression and neighboring household state are saved.

## Direction

Integrate family psychology with village opportunities. Economic choices should create personal dilemmas: expanding a farm competes with funding a child's education, while the people needed for either plan have their own priorities and can refuse.

Keep the head-of-family perspective, incomplete psychological knowledge, monthly time, and autonomy. A village should extend the intimate family game rather than turn it into factory management. Build actions before building a map.

The [original proposal](source.md) is preserved verbatim, including pasted illustration links and formatting. Its 1850/1852 examples are illustrative; the current game still starts in Tuscany in 1800. Daily or weekly activities must be expressed through monthly progress. Its suggestion of changeable aspirations needs reconciling with the existing locked starting Legacy objective; do not silently replace that system.

## Implementation skeleton

- `Simulation/Activities/ActivityPlan.gd`: one proposed or accepted activity, participants, target, costs, progress, interruptions, and a terminal outcome. ActivitySystem handles proposals and consent.
- `Simulation/Village/VillageHousehold.gd`: an external family's identity, members, property, finances, ambitions, and relationships. It is separate from the playable family's `GameState.people` roster.
- `Simulation/Village/VillageState.gd`: containers for neighboring families, locations, and properties. Five neighboring households and eight clickable locations are initialized; individual NPC people remain planned; the persistent illustrated map is implemented in the [evolving village prototype](../evolving-village/README.md).

These classes have data-only serialization helpers. GameState owns them, the monthly clock advances them, SaveGame validates and restores them, and person profiles/Village display them. Costs use the existing fixed Tuscan-lira accounting basis, not displayed currency denominations. Member references need globally unique IDs once NPC people are introduced.

## Phase 1 — Long-running activities

- [x] Scaffold an activity record.
- [ ] Author a small activity catalog, then expand toward 10–15 activities: study, friendship, field improvement, renovation, workshop setup, trade contacts, care, tutoring, courtship, information gathering, dispute mediation, and investigations.
- [x] Add a coordinator for proposal, acceptance/refusal, commitment, monthly progress, interruption, cancellation, completion, and failure.
- [ ] Set activity capacity per person; existing courses, careers, care, and autonomous plans must compete for time rather than run in parallel without limits.
- [ ] Route requests through Influence and autonomous choices through DecisionSystem. The head may commit their own time; relatives decide whether to participate.
- [x] Charge actual monthly costs through Economy once, including purchase discounts. Apply the learning bonus only to learning activities.
- [ ] Resolve outcomes from relevant skills, temperament, values, relationships, memories, and circumstances. Show evidence and qualitative risks rather than exact acceptance odds.
- [x] Preserve progress and commitments in saves; add backward-compatible defaults and validation in SaveGame.
- [x] Show proposals, active plans, expected duration, funding pressures, and interruption reasons in person details; record important changes in Chronicle.
- [x] Verify refusal, competing commitments, insufficient funds, departure, illness, death, cancellation, no duplicate charges, and deterministic save continuation.

First playable slice: ask a relative to improve a field over four months while another wants education. Limited money and time force a choice; reluctance or interruption changes both the project and family relationships.

## Phase 2 — Other families

- [x] Scaffold neighboring household and village records.
- [ ] Begin with 5–10 NPC households; expand only when simulation cost and story density justify it.
- [ ] Give each family members, professions, property, money, relationships, ambitions, and history. Use authored starter data rather than a huge procedural world.
- [ ] Establish global person IDs and external-person lookup without counting villagers toward the player's family objective or household food bill.
- [ ] Run NPC decisions on monthly ticks using the same resource, consent, and time constraints.
- [ ] Add introductions, friendship, negotiation, rivalry, trade, and consensual courtship. Agreements require both sides.
- [ ] Verify neighbors can reject offers and pursue opportunities while the player is occupied.

## Phase 3 — Village map

- [x] Add locations: church, tavern, market, school, farms, workshops, town hall, and neighboring houses.
- [x] Build an illustrated map with clickable buildings and parcels; expose property inspection and activities. The persistent map replaces the earlier static background.
- [x] Keep the map as a view over simulation records. No walking units or separate daily clock.
- [x] Keep activity management usable through the existing strategy UI.

## Phase 4 — Ownership and power

- [ ] Model property ownership, shares, claims, upkeep, and income.
- [ ] Add land/business purchases, negotiated terms, loans, reputation, offices, and inheritance disputes in small increments.
- [ ] Replace the current career-based influence milestone with actual social standing only after defining migration for existing runs.
- [ ] Make prosperity create labor, debt, inheritance, and relationship pressures; retain recovery paths.
- [ ] Verify ownership conservation, transaction affordability, shared-asset authority, and succession.

## Phase 5 — Travel and wider Italy

- [x] Add abstract city nodes and travel durations (first WIP slice: eleven cities).
- [ ] Support distant study, employment, trade contacts, migration, letters, and remittances.
- [ ] Account for absence, housing, travel costs, family attachment, and return decisions.
- [ ] Consider whole-household relocation separately; it affects Landi House premise.

## Decisions before integration

- Which three activities form the first playable slice, and what existing study/career behavior do they reuse?
- How much time does a job or course leave for other commitments?
- How are outside people introduced, observed, and admitted into the family?
- Which village aspirations can change without changing the run's Legacy objective?
- Which schemes fit the tone and scale? The proposal's darker examples remain design ideas, not implemented actions.

Success criterion: a ten-year run produces understandable family consequences from a few competing plans, with neighbors responding independently. More buttons or a map alone do not satisfy this.

## Current playable slice

Three person activities are available through Show more → Activities: independent literacy study (six months, three Tuscan lire per active month), house repairs (four months, five lire per active month, +15 condition on completion), and visits to a neighboring family (three months, three lire per active month). The head starts their own activity; adult relatives accept, reluctantly accept, or refuse using their interests, values, stress and relationship. Requests share the monthly request limit. One activity per person is allowed. Existing courses block new activities; ordinary paid work continues, with a stress burden. Autonomous competing work, study, help and practice are deferred while committed, but independent departure plans can still interrupt projects.

Household bills settle first. Projects then charge affordable costs; illness or missing funds pauses progress and spending. Departure or death fails the project; cancellation releases the participant. Completed study improves literacy without a qualification. Visits may warm relations or meet a cool reception. The learning and purchase-discount bonuses apply. Major changes pause time and enter Chronicle; payments appear in Finances.

Neighbors currently act at household level: productive property earns monthly sales after materials and upkeep, alongside a small placeholder surplus from other work. Limited labor and local competition constrain output; annual investments pursue household ambitions through persistent building development. Land purchases and private property negotiations are playable. Named NPC people, richer time allocation, crop inventories, marriage negotiations, schemes and political office remain future work. The Village screen renders separate buildings over fixed terrain, with inspection and historical replay.

Verification: `Tests/GameplayLayerTest.gd`. Visual preview: `Tools/PreviewGameplay.gd`.

### Italy map first slice

The **Italy** screen now includes clickable city nodes, travel proposals for study/trade/work, personality-based consent, upfront trip funding, absence from the household, outbound/stay/return stages, early-return requests, rewards, saved progress and older-save migration. See `Simulation/Travel.gd`, `Scripts/ItalyMap.gd`, `Scripts/TravelScreen.gd` and `Tests/TravelTest.gd`. Family travel, migration, permanent urban careers, city NPCs, letters and historical restrictions remain open.

The separate Projects/Activities page has been removed. Person profiles show essential identity, state, intentions and a current commitment first; Show more opens Activities, Background, Personality, Values & state, and History. Expanded sections retain known/suspected/unknown information. Village activity links open the selected person's Activities section.

Neighbor property offers now support refusals, counteroffers, a monthly household cooldown, exact agreed payments, protected housing needs, expiry and ownership rechecks. Inspect a privately owned building or parcel on the map to make an offer. Productive property now settles monthly sales, materials and upkeep; family managers accept or refuse, learn skills, experience pressure and may resign. Manage responsibilities in a person's Activities section and see property accounts in Finances. Construction cancellation refunds part of unfinished paid work. See `Tests/VillageBusinessTest.gd` and the evolving-village plan for implementation limits and remaining work.
