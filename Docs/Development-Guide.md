# Development guide

Set in the **Tuscan countryside, January 1800**, with the Landis tending a small podere and maintaining ties to the village and Florence.

A Godot prototype for the generational family strategy game described in [AGENTS.md](../AGENTS.md). This prototype shows the people in Landi House, their branch, and observable concerns. Select a person to see your current understanding of their temperament, values, learned tendencies, and current state, with formative experiences and evidence. Knowledge is qualitative and can be known, suspected, or unknown. The starting family is authored. Illustrated archive portraits use a stable base-face library with five age stages and shared family features. Conversations clarify understanding; requests let relatives accept, reluctantly comply, or refuse household moves, education, and work.

The top-right clock starts paused in January 1800. Use Play, Pause, and speeds 1–5 to advance months at 60, 30, 15, 7.5, or 3.75 seconds per month. Pausing and speed changes preserve partial-month progress. Dates use months and years only.

`Simulation/GameState.gd` owns the in-memory date, people, household, and economy. Every completed month advances the date and runs `_update_monthly()`, the entry point for future simulation systems. Each month settles resident earnings and food costs, then inflates prices for the next month. People age on their birth month, and financial pressure updates their current psychological state. `Simulation/GameClock.gd` handles playback and emits `month_advanced` after the state update; major personal plans and autonomous household moves pause it for review; routine career changes and graduation use notifications. The clock stays available on every screen. Use the game menu’s **Save** and **Load** buttons to save the current run and resume it later. There is one save slot at `user://current_game.save` (Godot’s per-user application data directory). Save replaces the previous slot after writing successfully. It preserves the complete family, observer knowledge and conversation/request cooldowns, portraits, household, education and careers, finances, chronicle, speed, and partial-month progress. Load restores the saved date and pauses time. Missing, damaged, or unsupported saves show an error without replacing the current family.

## Launch

1. Install **Godot 4.3 or newer** from [godotengine.org/download](https://godotengine.org/download/). The .NET edition is the right choice for the planned C# simulation; this first UI screen also runs in the standard edition.
2. Open Godot's Project Manager, click **Import**, and select this folder's `project.godot`.
3. Open the imported project and press **F6** while `Scenes/FamilyScreen.tscn` is open, or press **F5** to run the project.

From a terminal, if Godot is on your `PATH`:

```bash
godot --editor --path /home/dimin/Desktop/TheHouse
```

Press **F5** in the editor to run the screen. To launch the screen directly, omit `--editor`. On some systems the executable is named `godot4` instead of `godot`.

## Edit the roster

Open `Scenes/FamilyScreen.tscn` in Godot. Each person is a `PanelContainer` under `FamilyList`, with labels for their name, relationship, role, and visible concern. Edit births, family links, numeric psychology, goals, relationships, memories, conversation topics, and the four observed psychology layers in `Data/people.json`. `Scripts/FamilyScreen.gd` connects the cards to the detail panel and initializes the game state from that data. The simulation foundation uses GDScript to match the current prototype; future gameplay simulation can be written in C# as recommended in AGENTS.md.

## Finances

Start with 100 Tuscan lire. Every resident costs 10 Tuscan lire/month for food in January 1800. At month end, resident earnings enter the shared purse and food is deducted; prices then compound by `1 + 0.005 / 12` (0.5% annually). Cash and wages do not inflate. This keeps century-long food inflation from making a modest two-person worker household inevitably unviable. Money uses a fixed accounting basis so currency reforms preserve the value of all balances and commitments. A lone non-earner has 90 lire in February and 80 lire in March after rounding. A negative balance represents unpaid bills, and crossing below zero pauses time.

The Finances screen shows the current budget, contributions by resident, and the latest 12 completed months. The balance stays visible beside the date on every screen. The initial seven residents earn 285 lire/month altogether and spend 70 on food, giving a first closing balance of 315 lire. This deliberately simple food-only budget excludes rent, fuel, clothes, repairs, taxes, and education. See [the historical research and assumptions](../Docs/Finances-1912.md). Edit `job` and `monthly_income_cents` in `Data/people.json` to adjust earnings. Only current household members contribute earnings and incur food costs.

Run the checks with your Godot executable:

```bash
godot --headless --path . --script Tests/PortraitTest.gd
godot --headless --path . --script Tests/PersonTest.gd
godot --headless --path . --script Tests/EconomyTest.gd
godot --headless --path . --script Tests/GameClockTest.gd
godot --headless --path . --script Tests/InfluenceTest.gd
godot --headless --path . --script Tests/CareersTest.gd
godot --headless --path . --script Tests/SaveGameTest.gd
```

## People

`Simulation/Person.gd` stores birth year/month, age, living status, health, occupation, earnings, branch, parents, spouse, responsibilities, goals, relationships, and memories. Temperament has five continuous traits; values and learned tendencies have independent continuous strengths. Stress, happiness, and resentment are current state. These numeric internals are private to the simulation; the UI shows qualitative understanding through `view_for(observer_id)`. Each observer has separate knowledge, and views return copies.

The roster shows current ages and circumstances. Birth months are authored placeholders that preserve the original ages in January 1800. Everyone advances through birthdays, including relatives outside the household; deceased people's age is frozen. Household membership governs visibility and expenses. The person panel stays current while time passes.

Use **Talk with …** in a relative's panel to hear an authored response and add dated evidence. A finding can replace a previous suspicion, and the conversation enters their memories. Each observer can talk to a relative once per month. These first conversations clarify expressed wishes; they do not force compliance or expose every private goal. Giovanni is the current observer; succession is still pending.

Monthly financial pressure increases stress, moderated by emotional stability, and quiet months allow gradual recovery. The first unpaid household bill becomes a memory and modestly changes attitudes toward security and risk, with effects shaped by age, temperament, and existing attachments. `experience_event` provides the entry point for later contextual life events. Initial formative memories are authored alongside the starting personality, not retroactively recalculated.

Right-click a person (or use **Make a request…** in their details) to **ask to stay**, **ask to leave**, **ask to join the house**, or **ask to marry**. Opening the request menu leaves time controls available. Requests use private values, active goals, financial dependence, and the relationship with the head. Communicated responses are enthusiastic, willing, reluctant, or refused; no acceptance scores are shown. Adults can receive one request per month. Invalid actions are disabled with an explanation. Being asked to leave can hurt even when someone wants independence; reluctant compliance builds resentment. Requests become memories, observed evidence, and dated entries in **Chronicle**.

Accepted household moves take effect immediately and change the next monthly budget. People who leave appear under **Living elsewhere**, where you can inspect them and ask them to return later. Asking to stay delays their departure plans for twelve months when willingly accepted, or four when reluctantly accepted. They can reconsider after that; their own goals remain. Asking to marry means asking them to pursue marriage: acceptance adds an intention to find a partner of their own choosing, visible in their details. It does not assign a spouse or create a wedding. Pregnancy events now lead to births, and illness events generate temporary illness and recovery. Partner selection, mutual consent, mortality, and succession still need gameplay systems; deaths are not yet generated.

## Education and careers

Open **Education & careers…** from a person's details or right-click menu. The Education tab offers 23 courses, including basic and secondary schooling, apprenticeships, commercial training, and college degrees. The Occupations tab lists 32 jobs with education, qualification, skill, and resource requirements. Helpful personality traits influence suitability without acting as career locks. Requests share the existing monthly limit and relationship consequences. Children aged six or older can receive education requests from their parent; requests for another branch's children require discussing their education with the parent first. Taking paid work requires adulthood in this prototype.

People now have education levels, qualifications, an active course, five cognitive abilities, twenty learned skills, and six career interests. Abilities and skills use private 0–100 game scores. `cognitive_index()` is an average game summary, not a real-world IQ measurement. Education and qualifications are public; abilities, skills, and interests are shown in qualitative bands only where the current observer has knowledge. Graduation provides evidence of learned skills. See [the model and prototype assumptions](../Docs/Education-and-Careers.md).

Accepted full-time study stops paid work and begins monthly learning. Fees are included in Finances and its ledger. Food takes priority: if the household cannot fund all active resident courses after food, all courses pause and no tuition is charged that month. Returning to affordability resumes progress. Departed or deceased students do not incur household tuition or make progress. Graduation raises the education level where appropriate, grants the qualification, records history, and pauses time. It does not immediately assign work; relatives can subsequently seek eligible work autonomously. Suggesting an eligible occupation is a separate request; acceptance changes the job and wage for the next settlement.

Starting qualifications and skills are authored examples. Initial wages remain unchanged. Career wages, tuition, durations, and requirements are prototype balancing values, not historical salaries or legal qualification rules. The prototype assumes vacancies are available; careers needing land, capital, instruments, or other resources check the person's authored `career_access`. Buying those resources, a job market, part-time study, working apprenticeships, training dropout, and workplace productivity are still pending.

## Portraits

The household roster, relatives living elsewhere, and person details show matching framed archive portraits. Each starter has a permanent portrait seed, visual genetics, and appearance in `Data/people.json`, separate from psychological data. Portraits change on entering age stages at 13, 22, 40, and 65. New people inherit parental visual traits, select a matching library base deterministically, and reshape individual facial features and coloring through the procedural renderer. `GameState.add_person()` supports new relatives during a run; the UI creates their cards automatically. This first library contains seven identities with five age variants each; modular face parts and later-era clothing remain future work. See [the portrait assets, architecture, and limitations](../Assets/Portraits/README.md) and [generation prompts](../Assets/Portraits/PROMPTS.md).

## Personal goals and autonomous decisions

`Simulation/DecisionSystem.gd` runs after each month's finances, birthdays, learning, and psychological changes. People retain their authored goals and gain a small set of goals from their values, age, and interests: independence, education, dependable income, family support, careers, or companionship. The current family head remains under player control. Relatives begin reviewing autonomous actions after six months in the household simulation.

They compare eligible work with their current occupation, prepare to leave or return, request funding for a preferred course, practice an interest, help a stressed relative, or decide to seek a partner. Choices consider values, active goals, interests, earnings, family ties, resentment, stress, tradition, and security. A creative relative may take lower-paid work; a security-minded relative may keep a reliable job. Children cannot take adult work or move out independently. Studying relatives finish their course before changing work or moving, and a parent with dependent children does not move out alone. Job qualifications and access requirements still apply.

Major plans produce observable evidence and a clock pause, followed by two months' notice before action. Relatives reconsider when their circumstances change. Small actions have a three-month cooldown; helping lowers a relative's stress and improves trust while burdening the helper, and practice modestly develops a skill without awarding qualifications. Education proposals wait for the head to approve a training request through **Education & careers**; relatives cannot independently commit shared money to tuition. Pursuing companionship records an intention, with partner selection still pending.

Cards show recent observable behavior, details show announced plans, and **Chronicle** records intentions, reconsideration, and decisions. Conversations can reveal personal goals after the authored topics. Unexpressed goals and decision scores stay private. Education and independence goals can complete; ongoing family and security concerns persist. Saves preserve plans, notice periods, completed goals, and agreements, and existing version 1 saves remain loadable.

Run the autonomous simulation checks with `godot --headless --path . --script Tests/DecisionSystemTest.gd`. They include contrasting motivations, financial feasibility, notice and reconsideration, agreements to stay, shared funding, minors, support, clock interruption, save continuation, and a ten-year family run.

## Monthly events

The new **Events** window appears when a new month brings a situation that needs a response. Time pauses; choose an option before continuing. **Read later** closes the window, and **Events** in the navigation reopens it. Multiple milestones or incidents queue instead of replacing each other. Loading a save restores outstanding decisions. Quiet months remain possible.

`Data/events.json` contains **306 authored entries**: twelve situations each in 22 categories, two additional productive-property incidents, three milestone notices, and 37 dated historical events. Categories cover family requests, education, work, privacy, care, conflict, repairs, accidents, expansion, maintenance, robbery, illness, drought, famine, war, trade, community, inheritance, celebration, discovery, and pregnancy. Related situations reuse consequence rules. To edit the authored source, update `Tools/build_event_catalog.py`, `Data/property_events.json` or `Data/historical_events.json` and run `python3 Tools/build_event_catalog.py` from the project root. Regeneration preserves the property incidents and crisis integrations.

The simulation considers a random event from the first completed month onward, with a 70% base monthly chance. Individual stories have a five-year cooldown and categories a four-month cooldown. War incidents occur only during authored Italian wartime periods; drought and harvest events are seasonal. Fixed historical events queue on their calendar month regardless of random event chance. Each historical event occurs once, pauses time, and is recorded in the Chronicle. Eligibility checks living residents, adulthood, personal values, available courses, existing illness, pregnancy capability, a living resident spouse, and space for expansion. Seeded random state is independent of portraits and persists in saves.

Choices spend or preserve shared funds, change stress, happiness, resentment and trust, improve skills, begin a requested course, repair damage, or add rooms and capacity. Cash costs are displayed and unaffordable responses are disabled; every incident has an option without an immediate cash cost. The house now starts with condition 80/100 and total capacity seven. Serious disrepair and overcrowding create monthly stress. Robbery immediately removes some available money, even if you decline to spend on security. Event payments and losses appear separately in Finances and the Chronicle.

Drought, famine, and war temporarily alter food costs; war also reduces earnings. Relief reserves can lessen a food-price shock. Crises expire after their stated duration and cannot overlap another crisis of the same kind. Trade and inheritance arrangements can generate a payment after several months. These are prototype estimates and simplified guaranteed arrangements, with a richer market and risk system still pending.

External crises now connect to productive property and travel. Drought reduces farm sales by 35%, including neighboring farms; famine raises operating costs by 10%; war raises operating costs by 15% and delays departures and journeys on the road for two completed months. Existing placements can continue unless illness interrupts them. No second fare is charged. A household relief reserve affects food prices only. Property incidents bind to an actual family-owned farm, workshop, factory or tavern, damage its condition and output, and record changes immediately in village history. Repairs check current ownership and active building work and cannot be paid twice. Existing Landi House incidents also update the map immediately.

Illness events can reach travelers and interrupt their placements. Late pregnancy pauses family activities and business management for the last two months; three months of recovery follows birth. The manager's role remains assigned during care leave, production stops, and upkeep remains payable. Activities pause without charging fees. Wages and courses continue under their existing rules. The birth notice reports overcrowding when relevant, and recovery time appears in the person's essential profile. See [event review](../todo/external-events-audit.md) and `Tests/EventFeatureTest.gd`.

Illness reduces the patient's earnings by half without changing their normal wage. Paid or family care shortens recovery; the family gets a recovery notice when the illness ends. Explicit reproductive data is separate from portraits. An eligible pregnancy creates a nine-month timer, then a named newborn with parent links, inherited portrait features, branch membership, and household expenses. A minimum interval prevents repeated immediate pregnancies. Births and graduation notices come from actual simulation state, rather than randomly inventing completed studies or children. Childbirth complications, partner selection, mortality, and succession remain future systems.

Run `godot --headless --path . --script Tests/EventSystemTest.gd` to verify catalog choices, contextual eligibility, affordability, incident consequences, expansion, temporary crises, illness and recovery, pregnancy and birth, graduation, delayed payments, clock interruption, deterministic save continuation, ten-year event variety, and the native event UI. `Tools/PreviewEvents.gd` renders the event window for visual review.


## Tuscany, history, and currency

The historical timeline includes Napoleonic rule, the Kingdom of Etruria, restoration, the Risorgimento, Tuscany’s 1859 revolution and 1860 plebiscite, Italian unification, the wars of independence, Rome, and later world wars for extended runs. News is historical; household choices and economic shocks are gameplay estimates. See [historical notes and sources](../Docs/Tuscany-History.md).

All gameplay money is displayed in **lire**, using decimals for fractions (for example, 6.67 lire). Balances, wages, tuition, costs and ledgers use the same stable accounting unit throughout the run. Historical currency reforms remain news events and saved historical context; they do not change the displayed unit or amounts. Older saves are rebased into the common accounting unit while preserving their value.

The original 1912 finance research is retained as background, not evidence for 1800 Tuscan salaries. Starting money, wages, expenses, and inflation remain prototype balance settings. Mixed Napoleonic coin circulation and barter are summarized rather than simulated. Portrait clothing and career access still use the existing prototype assets and rules.

Run `godot --headless --path . --script Tests/HistoricalEventsTest.gd` for calendar scheduling, Tuscan unification, seasonal/technology eligibility, currency reforms, and save continuation.

## Starting ambition and bonus

New games open with a choice of one ambition: **Populous family** (100 living family members, including those elsewhere), **Family fortune** (1,000,000 Italian lire in the shared purse, converted to equivalent value in earlier currencies), or **An influential family** (a living business manager, entrepreneur, lawyer, doctor, researcher or journalist with leadership and persuasion at least 50 (the Competent skill band)). Leadership and public speaking training provides a path to develop both skills. The influence definition is a prototype career milestone; public influence is not yet simulated.

Choose one independent, lasting bonus: **Fertility** increases eligible pregnancy event weight by 25%; **Thrifty family** discounts food, tuition and event purchases by 10%; **Quick learners** adds 25% to course progress, autonomous practice and event skill gains. Fertility preserves pregnancy eligibility and birth timing. Discounts do not reduce theft losses or increase income. Choices are locked once the story begins. The sidebar shows live progress; achievement pauses the monthly clock and enters the Chronicle once. Play can continue after achievement. Saves preserve the ambition, bonus and achievement; older saves select them through the required starting focus popup.

Run `godot --headless --path . --script Tests/LegacyTest.gd` for objective, bonus, save compatibility and layout checks.

## Planned gameplay extensions

See [todo](../todo/README.md) for the second gameplay layer proposal, phased roadmap, and the first playable activity/village slice.

## Person activities and village (work in progress)

Open a person profile and choose **Show more → Activities** to begin independent study, repair Landi House, or ask an adult relative to represent the family through visits to a neighbor. Activities take several months, cost money, and reserve one activity slot. Relatives can refuse; illness, insufficient funds, departure and cancellation affect progress. Jobs continue, while full-time courses and competing routine activities take priority constraints. Open **Village** to browse eight locations and five neighboring families, then plan visits. Their household-level finances and annual investments advance independently.

Plans, outcomes, village relationships and history persist in saves. Earlier saves gain starter village data and empty projects. The persistent map, public land purchases and travel are playable prototypes; individual NPC lives and richer economic trading remain on the [roadmap](../todo/evolving-village/README.md). Run `Tests/GameplayLayerTest.gd` for consent, funding, interruption, progression, saves and screen checks.

## Italy map and journeys (work in progress)

Open **Italy** to choose Turin, Milan, Venice, Genoa, Bologna, Florence, Rome, Naples, Bari, Palermo or Cagliari on a geographic parchment SVG map. Propose **Study**, **Trade contacts**, or **Paid work** to an adult resident relative. The head stays home; minors, parents with dependent children, pregnant or ill relatives, and people already committed to a course or family project cannot depart in this first slice. Relatives may accept, reluctantly accept or refuse. Requests share the existing monthly request limit.

Return fares and the full stay are prepaid, with the purchase-discount bonus applied once. While away, travelers incur no home food bill and their ordinary wage does not enter the shared purse. They move through outbound travel, a placement, and return travel. Study improves the city's featured skill without a qualification; trade and work develop commerce and bring home prototype proceeds after completion. The learning bonus shortens study. Early-return requests can be refused; an accepted early return produces no placement reward and no refund. Illness pauses a placement, and death ends a journey.

Travel locations appear under Living elsewhere and in person details. Arrival, placement completion and return create notifications and enter Chronicle without pausing the clock. Saved journeys resume at the same stage; older saves begin with no journeys. Prices, durations and rewards are game balance values; the map uses Natural Earth geographic outlines rather than historical political regions. Traveling with dependents, permanent migration, city-specific NPCs, formal university qualifications and historical travel restrictions remain future work.

Verification: `Tests/TravelTest.gd`. Visual preview: `Tools/PreviewTravel.gd`.

The starting focus popup cannot be dismissed by Escape or an outside click. Select an objective and bonus to begin, or load a saved family. There is no separate Objectives page. Italy uses a geographic SVG coastline in the archive palette, and the village uses an original SVG drawing with clickable buildings. Both maps preserve their aspect ratio.

## Persistent village prototype

Village now renders one fixed terrain SVG with 40 parcels and 18 initial structures as separate building nodes. Click buildings or open land for inspection. Buy offered public land, commission a house/farm/workshop on an eligible owned plot, or renovate family property. Work costs 120 Tuscan lire before the selected purchase bonus and takes 12 months for construction or 6 months for renovation. Neighbors invest their own funds; population is aggregate prototype data, distinct from the player's named relatives.

Use the timeline to revisit recorded map states; historical views are read-only. Ownership, land value, current relationships and development have overlays. Wheel zooms; middle/right drag pans; Reset view restores the view. Buildings retain IDs through renovation, conversion, ownership changes and demolition. Public investment funds maintenance and eligible modernization, with capital and available parcels governing actual development. Nothing regenerates the whole terrain by year.

Saves include the world, construction projects and history. Existing static-village saves start a new recorded baseline at their current date. `Tests/VillageDevelopmentTest.gd` checks a century of development, historical isolation, costs, deterministic continuation and live UI. See [implementation status and remaining work](../todo/evolving-village/README.md).

Person profiles now start with essentials: name/age, portrait, kinship, health/location/job, current intention and commitment. Show more reveals separate Activities, Background, Personality, Values & state, and History sections. Education/career controls live in Background; psychology preserves observer knowledge. Activity requests, progress, interruptions, outcomes and cancellation stay with the selected person. Village links open that person's Activities section. There is no separate activity navigation page.

Inspect a neighboring household's property to propose a purchase. An owner can refuse, counter or accept based on property value, productive use, available cash and relations. Needed housing and active building works cannot be sold. Counteroffers expire after two months and survive saves; accepting checks funds and ownership again. Payments conserve money and pay the seller the exact agreed amount. Public fixed-price purchases still use purchase discounts. Negotiated prices are agreed directly with the seller.

Validation: `Tests/PersonProfileTest.gd` and `Tests/PropertyNegotiationTest.gd`, plus the gameplay, legacy, persistent village and save suites.

## Automated century simulations

`Tools/RunSimulations.gd` runs fresh families for up to 100 years with passive, frugal, education, enterprise and family-oriented player policies. Configure seeds, strategies, bonus and objective from the command line. Requests can be refused; policies fund normal courses, construction and management without modifying player saves. Each batch exports strategy comparisons, yearly CSV data, detailed JSON and decision samples. See [runner instructions](../Simulation/Testing/README.md) and [the century batch](../Reports/Simulations/century-check/summary.md). `Tests/SimulationRunnerTest.gd` verifies deterministic execution and legal decisions.

## Marriage, dote, and allied families

Open an adult's profile → **Marriage & dote** to compare five proposals from the village's farming, merchant, artisan, landowner and educated families. Proposed partners have different values, ages, household requirements and dowries. Daughters provide a dowry; sons receive one from the bride's family. The convention is stored as `life_state.dowry_role`, separate from portrait appearance; older characters fall back to the existing reproductive data. All amounts and conventions are prototype game rules, not historical legal claims.

Negotiate the amount before proposing marriage. Trust, resentment and the other family's liquidity affect their terms; they can refuse or counter. Each proposal lasts twelve months. No money moves during negotiation. Landowners also require a recommendation: earn family standing through a successful allied-family favor. The agreed dowry is paid exactly, without the shopping discount.

Choose Landi House or a nearby branch household. Staying requires space for the arriving spouse (or both people if the relative already lives elsewhere). Both people's private values, compatibility, current resentment and educational plans affect consent. Willing acceptance, reluctant acceptance and refusal are possible. Proposals share the monthly person-request limit. Reluctant compliance hurts trust and creates resentment; refusal transfers no money and creates no alliance. Existing “Ask to marry” still asks someone to seek a partner; it does not complete a marriage.

A son's incoming dowry enters the shared purse only when the couple stays. It remains **owed to the couple**, rather than an unrestricted gift. Leaving transfers the capital out of the purse, including a negative balance if it has been spent. Returning brings their capital back once. Requests and autonomous departures move the couple and dependent children together. A spouse's death releases a resident incoming dowry once, reserving it for the survivor or descendants. Finances shows these liabilities and dowry transactions. Nearby couples keep their own dowry outside the player's purse; their wages and food costs are excluded from home accounts. They remain named people in the family tree, can be visited through Talk, and can have children through the existing pregnancy/birth system.

Marriage creates a lasting family connection. From any person's Marriage screen, ask an allied family to help that relative: seasonal work, a trade introduction, repairs, tutoring, or a recommendation. These requests can be refused or carry a repayment obligation. Favors develop relevant skills, and some provide actual money, house repairs, institutional access or family standing. A family allows one request per year, including refused requests. Repay before requesting another favor; debts left unpaid for more than a year increase resentment. Couples' affection and resentment evolve with differences in values and household stress, influencing alliance strength and family trust. No acceptance percentages are exposed.

Proposals, marriage records, couple capital, alliances, obligations and standing persist in saves. Older saves start with no arranged unions or alliances. Prospective spouses are generated from aggregate village families and become named simulated people upon marriage; a full NPC population, divorce, detailed dowry inheritance and lending/land-lease contracts remain future work. Nearby homes are abstract branch locations, not new constructed map buildings.

Validation: `Tests/MarriageTest.gd`, with save, influence, personal planning, profile, activity, travel and property suites. `Tools/PreviewMarriage.gd` renders the native proposal screen into `.godot/marriage-preview.png`.


## Assignment reactions and notification levels

Person and career details are nonmodal panels. The clock, navigation and other people remain usable, and browsing or assigning routine work does not pause playback. Routine requests stay in their current panel; career assignment no longer closes the career controls and opens another window. Requests still respond immediately while paused.

`Simulation/Assignment.gd` resolves a public `action_response` (enthusiastic, willing, reluctant, refused), `accepted`, a contextual `dialogue_key`, dialogue, and an activity identifier when an action starts. Existing `ok`, `outcome` and plan IDs remain compatible with simulation callers. Private agreement data is persisted for activities, courses, jobs, business management and journeys; the UI reads only the communicated response. A conflict-avoidant, loyal relative can conceal reluctant compliance behind a willing reply. Numerical willingness is never rendered.

`Scripts/AssignmentReaction.gd` displays an icon, text and color below the relevant controls. Dialogue lasts six real seconds and then collapses to a compact status. Rebuilding controls does not reset that deadline. Accepted plans become active, not completed. Reluctant activities, study and placements progress at 70% pace and accumulate extra stress and resentment. Under enough strain they can abandon the task; cancelled study awards no qualification, and abandoned travel returns without its placement reward. Reluctant workers and managers can leave under pressure. Old saves have empty agreements and retain normal progression.

Routine activity interruptions, completion and abandonment, recovery, graduation, travel milestones, player construction completion, and cooling marriage alliances create nonblocking updates and Chronicle entries. The on-screen feed shows the latest unread updates; dismissing them preserves their saved records and the journal. The feed retains the latest 100 notifications. Marriage, household departures, deaths, crises and events requiring a player choice still use the major-event pause and/or event window. Transient assignment feedback is cleared on load; private commitments and unread notifications persist.

Validation: `Tests/ActionFeedbackTest.gd` checks all four states, concealed reluctance, paused response, progress/abandonment, save migration and corruption, live nonmodal controls, compact feedback, notifications and major-event windows. Existing activity, career, influence, travel, save, business and event suites cover integration. `Tools/PreviewFeedback.gd` captures the live assignment panel for the README.
