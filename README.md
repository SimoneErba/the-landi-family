# The Landi family

Set in the **Tuscan countryside, January 1800**, with the Landis tending a small podere and maintaining ties to the village and Florence.

A Godot prototype for the generational family strategy game described in [AGENTS.md](AGENTS.md). This prototype shows the people in the ancestral house, their branch, and observable concerns. Select a person to see your current understanding of their temperament, values, learned tendencies, and current state, with formative experiences and evidence. Knowledge is qualitative and can be known, suspected, or unknown. The starting family is authored. Illustrated archive portraits use a stable base-face library with five age stages and shared family features. Conversations clarify understanding; requests let relatives accept, reluctantly comply, or refuse household moves, education, and work.

The top-right clock starts paused in January 1800. Use Play, Pause, and speeds 1–5 to advance months at 60, 30, 15, 7.5, or 3.75 seconds per month. Pausing and speed changes preserve partial-month progress. Dates use months and years only.

`Simulation/GameState.gd` owns the in-memory date, people, household, and economy. Every completed month advances the date and runs `_update_monthly()`, the entry point for future simulation systems. Each month settles resident earnings and food costs, then inflates prices for the next month. People age on their birth month, and financial pressure updates their current psychological state. `Simulation/GameClock.gd` handles playback and emits `month_advanced` after the state update; major personal plans, autonomous moves and career changes, and graduation pause it for review. The clock stays available on every screen. Use the game menu’s **Save** and **Load** buttons to save the current run and resume it later. There is one save slot at `user://current_game.save` (Godot’s per-user application data directory). Save replaces the previous slot after writing successfully. It preserves the complete family, observer knowledge and conversation/request cooldowns, portraits, household, education and careers, finances, chronicle, speed, and partial-month progress. Load restores the saved date and pauses time. Missing, damaged, or unsupported saves show an error without replacing the current family.

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

Open `Scenes/FamilyScreen.tscn` in Godot. Each person is a `PanelContainer` under `FamilyList`, with labels for their name, relationship, role, and visible concern. Edit births, family links, numeric psychology, goals, relationships, memories, conversation topics, and the four observed psychology layers in `Data/people.json`. `Scripts/FamilyScreen.gd` connects the cards to the detail popup and initializes the game state from that data. The simulation foundation uses GDScript to match the current prototype; future gameplay simulation can be written in C# as recommended in AGENTS.md.

## Finances

Start with 100 Tuscan lire. Every resident costs 10 Tuscan lire/month for food in January 1800. At month end, resident earnings enter the shared purse and food is deducted; prices then compound by `1 + 0.02 / 12`. Cash and wages do not inflate. Money uses a fixed accounting basis so currency reforms preserve the value of all balances and commitments. A lone non-earner has 90 lire in February and 79.98 in March. A negative balance represents unpaid bills, and crossing below zero pauses time.

The Finances screen shows the current budget, contributions by resident, and the latest 12 completed months. The balance stays visible beside the date on every screen. The initial seven residents earn 285 lire/month altogether and spend 70 on food, giving a first closing balance of 315 lire. This deliberately simple food-only budget excludes rent, fuel, clothes, repairs, taxes, and education. See [the historical research and assumptions](Docs/Finances-1912.md). Edit `job` and `monthly_income_cents` in `Data/people.json` to adjust earnings. Only current household members contribute earnings and incur food costs.

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

The roster shows current ages and circumstances. Birth months are authored placeholders that preserve the original ages in January 1800. Everyone advances through birthdays, including relatives outside the household; deceased people's age is frozen. Household membership governs visibility and expenses. The person popup stays current while time passes.

Use **Talk with …** in a relative's popup to hear an authored response and add dated evidence. A finding can replace a previous suspicion, and the conversation enters their memories. Each observer can talk to a relative once per month. These first conversations clarify expressed wishes; they do not force compliance or expose every private goal. Giovanni is the current observer; succession is still pending.

Monthly financial pressure increases stress, moderated by emotional stability, and quiet months allow gradual recovery. The first unpaid household bill becomes a memory and modestly changes attitudes toward security and risk, with effects shaped by age, temperament, and existing attachments. `experience_event` provides the entry point for later contextual life events. Initial formative memories are authored alongside the starting personality, not retroactively recalculated.

Right-click a person (or use **Make a request…** in their details) to **ask to stay**, **ask to leave**, **ask to join the house**, or **ask to marry**. Opening the request menu pauses time. Requests use private values, active goals, financial dependence, and the relationship with the head. Responses are acceptance, reluctant acceptance, or refusal; no acceptance scores are shown. Adults can receive one request per month. Invalid actions are disabled with an explanation. Being asked to leave can hurt even when someone wants independence; reluctant compliance builds resentment. Requests become memories, observed evidence, and dated entries in **Chronicle**.

Accepted household moves take effect immediately and change the next monthly budget. People who leave appear under **Living elsewhere**, where you can inspect them and ask them to return later. Asking to stay delays their departure plans for twelve months when willingly accepted, or four when reluctantly accepted. They can reconsider after that; their own goals remain. Asking to marry means asking them to pursue marriage: acceptance adds an intention to find a partner of their own choosing, visible in their details. It does not assign a spouse or create a wedding. Pregnancy events now lead to births, and illness events generate temporary illness and recovery. Partner selection, mutual consent, mortality, and succession still need gameplay systems; deaths are not yet generated.

## Education and careers

Open **Education & careers…** from a person's details or right-click menu. The Education tab offers 22 courses, including basic and secondary schooling, apprenticeships, commercial training, and college degrees. The Occupations tab lists 32 jobs with education, qualification, skill, and resource requirements. Helpful personality traits influence suitability without acting as career locks. Requests share the existing monthly limit and relationship consequences. Children aged six or older can receive education requests from their parent; requests for another branch's children require discussing their education with the parent first. Taking paid work requires adulthood in this prototype.

People now have education levels, qualifications, an active course, five cognitive abilities, twenty learned skills, and six career interests. Abilities and skills use private 0–100 game scores. `cognitive_index()` is an average game summary, not a real-world IQ measurement. Education and qualifications are public; abilities, skills, and interests are shown in qualitative bands only where the current observer has knowledge. Graduation provides evidence of learned skills. See [the model and prototype assumptions](Docs/Education-and-Careers.md).

Accepted full-time study stops paid work and begins monthly learning. Fees are included in Finances and its ledger. Food takes priority: if the household cannot fund all active resident courses after food, all courses pause and no tuition is charged that month. Returning to affordability resumes progress. Departed or deceased students do not incur household tuition or make progress. Graduation raises the education level where appropriate, grants the qualification, records history, and pauses time. It does not immediately assign work; relatives can subsequently seek eligible work autonomously. Suggesting an eligible occupation is a separate request; acceptance changes the job and wage for the next settlement.

Starting qualifications and skills are authored examples. Initial wages remain unchanged. Career wages, tuition, durations, and requirements are prototype balancing values, not historical salaries or legal qualification rules. The prototype assumes vacancies are available; careers needing land, capital, instruments, or other resources check the person's authored `career_access`. Buying those resources, a job market, part-time study, working apprenticeships, training dropout, and workplace productivity are still pending.

## Portraits

The household roster, relatives living elsewhere, and person details show matching framed archive portraits. Each starter has a permanent portrait seed, visual genetics, and appearance in `Data/people.json`, separate from psychological data. Portraits change on entering age stages at 13, 22, 40, and 65. New people inherit parental visual traits, select a matching library base deterministically, and reshape individual facial features and coloring through the procedural renderer. `GameState.add_person()` supports new relatives during a run; the UI creates their cards automatically. This first library contains seven identities with five age variants each; modular face parts and later-era clothing remain future work. See [the portrait assets, architecture, and limitations](Assets/Portraits/README.md) and [generation prompts](Assets/Portraits/PROMPTS.md).

## Personal goals and autonomous decisions

`Simulation/DecisionSystem.gd` runs after each month's finances, birthdays, learning, and psychological changes. People retain their authored goals and gain a small set of goals from their values, age, and interests: independence, education, dependable income, family support, careers, or companionship. The current family head remains under player control. Relatives begin reviewing autonomous actions after six months in the household simulation.

They compare eligible work with their current occupation, prepare to leave or return, request funding for a preferred course, practice an interest, help a stressed relative, or decide to seek a partner. Choices consider values, active goals, interests, earnings, family ties, resentment, stress, tradition, and security. A creative relative may take lower-paid work; a security-minded relative may keep a reliable job. Children cannot take adult work or move out independently. Studying relatives finish their course before changing work or moving, and a parent with dependent children does not move out alone. Job qualifications and access requirements still apply.

Major plans produce observable evidence and a clock pause, followed by two months' notice before action. Relatives reconsider when their circumstances change. Small actions have a three-month cooldown; helping lowers a relative's stress and improves trust while burdening the helper, and practice modestly develops a skill without awarding qualifications. Education proposals wait for the head to approve a training request through **Education & careers**; relatives cannot independently commit shared money to tuition. Pursuing companionship records an intention, with partner selection still pending.

Cards show recent observable behavior, details show announced plans, and **Chronicle** records intentions, reconsideration, and decisions. Conversations can reveal personal goals after the authored topics. Unexpressed goals and decision scores stay private. Education and independence goals can complete; ongoing family and security concerns persist. Saves preserve plans, notice periods, completed goals, and agreements, and existing version 1 saves remain loadable.

Run the autonomous simulation checks with `godot --headless --path . --script Tests/DecisionSystemTest.gd`. They include contrasting motivations, financial feasibility, notice and reconsideration, agreements to stay, shared funding, minors, support, clock interruption, save continuation, and a ten-year family run.

## Monthly events

The new **Events** window appears when a new month brings a situation that needs a response. Time pauses; choose an option before continuing. **Read later** closes the window, and **Events** in the navigation reopens it. Multiple milestones or incidents queue instead of replacing each other. Loading a save restores outstanding decisions. Quiet months remain possible.

`Data/events.json` contains **304 authored entries**: twelve situations each in 22 categories, three milestone notices, and 37 dated historical events. Categories cover family requests, education, work, privacy, care, conflict, repairs, accidents, expansion, maintenance, robbery, illness, drought, famine, war, trade, community, inheritance, celebration, discovery, and pregnancy. Related situations reuse consequence rules; this is a first content and balance pass, rather than 304 separate simulation systems. To edit the authored source, update `Tools/build_event_catalog.py` or `Data/historical_events.json` and run `python3 Tools/build_event_catalog.py` from the project root.

The simulation considers a random event from the first completed month onward, with a 70% base monthly chance. Individual stories have a five-year cooldown and categories a four-month cooldown. War incidents occur only during authored Italian wartime periods; drought and harvest events are seasonal. Fixed historical events queue on their calendar month regardless of random event chance. Each historical event occurs once, pauses time, and is recorded in the Chronicle. Eligibility checks living residents, adulthood, personal values, available courses, existing illness, pregnancy capability, a living resident spouse, and space for expansion. Seeded random state is independent of portraits and persists in saves.

Choices spend or preserve shared funds, change stress, happiness, resentment and trust, improve skills, begin a requested course, repair damage, or add rooms and capacity. Cash costs are displayed and unaffordable responses are disabled; every incident has an option without an immediate cash cost. The house now starts with condition 80/100 and total capacity seven. Serious disrepair and overcrowding create monthly stress. Robbery immediately removes some available money, even if you decline to spend on security. Event payments and losses appear separately in Finances and the Chronicle.

Drought, famine, and war temporarily alter food costs; war also reduces earnings. Relief reserves can lessen a food-price shock. Crises expire after their stated duration and cannot overlap another crisis of the same kind. Trade and inheritance arrangements can generate a payment after several months. These are prototype estimates and simplified guaranteed arrangements, with a richer market and risk system still pending.

Illness reduces the patient's earnings by half without changing their normal wage. Paid or family care shortens recovery; the family gets a recovery notice when the illness ends. Explicit reproductive data is separate from portraits. An eligible pregnancy creates a nine-month timer, then a named newborn with parent links, inherited portrait features, branch membership, and household expenses. A minimum interval prevents repeated immediate pregnancies. Births and graduation notices come from actual simulation state, rather than randomly inventing completed studies or children. Childbirth complications, partner selection, mortality, and succession remain future systems.

Run `godot --headless --path . --script Tests/EventSystemTest.gd` to verify catalog choices, contextual eligibility, affordability, incident consequences, expansion, temporary crises, illness and recovery, pregnancy and birth, graduation, delayed payments, clock interruption, deterministic save continuation, ten-year event variety, and the native event UI. `Tools/PreviewEvents.gd` renders the event window for visual review.


## Tuscany, history, and currency

The historical timeline includes Napoleonic rule, the Kingdom of Etruria, restoration, the Risorgimento, Tuscany’s 1859 revolution and 1860 plebiscite, Italian unification, the wars of independence, Rome, and later world wars for extended runs. News is historical; household choices and economic shocks are gameplay estimates. See [historical notes and sources](Docs/Tuscany-History.md).

Start with **Tuscan lire**, shown with soldi and denari where needed (20 soldi per lira, 12 denari per soldo). A reform event in **1826** changes the accounts to **fiorini** (1 fiorino = 1⅔ Tuscan lire; 100 quattrini per fiorino). In **November 1859**, a second event adopts **Italian lire** (1 fiorino = 1.40 lire; 100 centesimi per lira). Thus 100 Tuscan lire → 60 fiorini → 84 Italian lire, with the same underlying value. The conversion applies equally to savings, negative balances, wages, tuition, prices, event costs, delayed payments, and ledger displays. Saves retain the selected currency; older saves retain their dates and Italian-lira purchasing amounts.

The original 1912 finance research is retained as background, not evidence for 1800 Tuscan salaries. Starting money, wages, expenses, and inflation remain prototype balance settings. Mixed Napoleonic coin circulation and barter are summarized rather than simulated. Portrait clothing and career access still use the existing prototype assets and rules.

Run `godot --headless --path . --script Tests/HistoricalEventsTest.gd` for calendar scheduling, Tuscan unification, seasonal/technology eligibility, currency reforms, and save continuation.
