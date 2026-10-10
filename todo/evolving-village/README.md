# A persistent, evolving village

Status: first playable prototype integrated. The full request is preserved unchanged in [source.md](source.md).

Implemented:
- One fixed parchment SVG terrain layer; forty handcrafted parcels, eighteen initial buildings.
- Separate interchangeable SVG building sprites, three appearances per type. Persistent building IDs, addresses, owners, condition, level, construction date and history.
- Capital-funded autonomous construction and renovation; housing pressure, agricultural expansion, neglected properties and school investment. Public maintenance competes with modernization for money. A reserved southern parcel supports a railway station.
- Construction, ownership transfer, changes of use and demolition in the simulation. Landi House, church and square are protected from demolition. Player UI supports purchasing available land, building on owned parcels and renovating owned buildings. Other households act independently.
- Technology availability plus public funds and suitable land for railway, paving and electricity. Wealth and railway access can support workshop conversion into factories.
- Click buildings and parcels to inspect ownership, use, condition, land value, fertility and histories. Existing family activities remain accessible through the inspector.
- Pan/zoom; ownership, land wealth, relationship influence and development overlays. Wealth/influence are explicitly current-state overlays, hidden during replay.
- Read-only monthly timeline from the recorded baseline, reconstructed from structural events and annual surveys. Current building nodes persist during monthly refreshes.
- Save validation, migration of prior static village saves, deterministic continuation, and a century-long village test.

Prototype limits:
- Neighbor population is aggregate household data, not named NPC residents. Productive property earns monthly sales after materials and upkeep, constrained by available household labor. A small placeholder surplus still represents other household work.
- Public land purchase uses fixed values. Private household property can now be negotiated: families refuse needed homes, reject low offers, counter, or accept. Ownership-transfer, conversion and demolition APIs remain available to future events; conversion/demolition are not unrestricted player commands.
- Technology dates are availability gates, not a complete regional infrastructure event system. One public savings fund finances improvements. Farm expansion currently adds farm buildings rather than simulating crop yields.
- Building views contain recorded structural and condition history; they do not claim to reconstruct old family psychologies or wealth. Old saves start recording at migration and cannot invent lost village history.
- Roads retain their authored route. Parcel uses are a small authored zoning model; there is no general city-builder or character navigation system.

Next: named village residents and household formation; richer negotiations and inheritance hooks; inventories, crop choices and business debt; regional infrastructure decisions; richer terrain and road extensions; checkpointed replay if event history grows large.

Validation: `Tests/VillageDevelopmentTest.gd`, existing gameplay, legacy UI and save tests. Preview tools render the starting village and the same world's grown and historical views.

Productive farms, workshops, factories and taverns now settle monthly sales and costs. Condition, upgrades, manager skills, seasonal harvests, land fertility, local competition and infrastructure affect output. Neighbor businesses share capped household labor. Family businesses require a consenting adult resident manager, assigned through Show more → Activities; courses, travel and other activities compete for that person's time. Management builds skill and stress; unhappy relatives can resign, pausing the game. Ordinary paid work continues in this prototype. Finances separates productive property accounts from the household wage budget, and sales reach the current owner only. The last 24 monthly business reports and manager assignments persist in saves.

Player construction and renovation can be cancelled in the village inspector. Refunds return 80% of the actual payment attributable to unfinished work; the land stays owned and payments cannot be refunded twice. Older projects without payment records migrate with zero refundable payment. Tests: `Tests/VillageBusinessTest.gd`; preview: `Tools/PreviewVillageBusiness.gd`.

Negotiated sales are a playable first slice: agreed money reaches the seller, parcel/building ownership changes atomically, counteroffers persist and expire after two months, and saved replay retains old ownership. One proposal per neighboring household per month. Family purchase discounts do not reduce privately agreed sale proceeds. Profiles now own all family activity controls, with optional information sections and no activity page. Tests: `Tests/PropertyNegotiationTest.gd`, `Tests/PersonProfileTest.gd`.
