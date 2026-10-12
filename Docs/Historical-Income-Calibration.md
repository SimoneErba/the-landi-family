# Historical income and training calibration

Implemented 12 October 2026. All amounts below are in the game's fixed base Tuscan-lira accounting units, divided by 100 for display. See [the research audit](Research/Wages-Education-1800.md) for sources and their limits.

## Wages and receipts

The Florence building-worker benchmark is approximately 23-31 base lire/month for laborers and 34-43 for skilled craftsmen, calculated from chart readings and paid working-day assumptions. The catalogue now uses **38 for builders, 40 for carpenters and 42 for blacksmith/mechanics**. These are rounded calibration estimates, not archival monthly contracts. A teacher earns **56**, anchored to the particular late-eighteenth-century 96-scudi annual teaching salary.

Other rates are assumptions relative to those benchmarks: agricultural laborer 25; smallholder net cash receipts 45; farm manager 50; domestic worker 12 plus supplied meals; cook 22 plus some meals; factory worker 28; machine operator 35; tailor 24; shop assistant 26; merchant 60; shopkeeper 42; salesperson 30; bookkeeper 38; accountant 55; clerk 35; nurse 24; doctor 90; lawyer 80; engineer 75; architect 70; surveyor 50; researcher 55; journalist 40; writer 25; artist 28; musician 30; manager 60; entrepreneur 45. Professional premiums and commercial earnings are not proven occupation-by-occupation 1800 data. Commercial/self-employed amounts represent a simplified net receipt rather than an employee wage.

Authored starters now receive: Giovanni 45, Carlo 25, Pietro 40, Lucia 20 and Sofia initially 3. Carlo's job is explicitly paid farm labor, rather than another copy of the owner's family-farm receipts. Future work requests and autonomous occupation changes use the new catalogue. Existing save-file pay remains with each person; new offers use updated catalogue entries.

These are monthly equivalents. The simulation still does not reconstruct paid days, vacancies, piecework, seasonal harvest receipts or profession-specific historical wage trajectories. It would be misleading to describe the entire century as measured historical wages. No modern market prices were mixed into the historical currency scale.

## Schooling and work while learning

| Arrangement | Monthly fee and materials | Cash earnings during training |
| --- | --- | --- |
| Subsidized basic lessons | 0 tuition + 0.50 supplies | 50% of previous work |
| Private basic lessons | 3 tuition + 0.50 supplies | 50% of previous work |
| Local secondary lessons | 3 tuition + 0.50 supplies | None |
| Boarding grammar school | 17.50 board/tuition + 1 supplies | None; meals supplied when funded |
| Carpentry placement | 0 | 6 rising to 12 |
| Construction placement | 0 | 4.50 rising to 9.50 |
| Blacksmith/mechanical placement | 0 | 6 rising to 12.50 |
| Sewing placement | 0 | 3 rising to 6.50 |

The zero-tuition route is grounded in subsidized-school evidence, with supplies and local access assumed. Private/local lesson rates are estimated against teaching pay and small-group teaching. The boarding fee uses the Santa Chiara pre-1800 benchmark; supplies, eligibility, lodging and travel details are assumptions, and physical relocation is summarized rather than moving the person through Travel.

Paid local apprenticeships are an **assumed contract type**, informed by the documented existence of paid Tuscan apprenticeships in the later 1830s, not a universal entitlement proven for 1800. Employers supply working materials in these placements. Pay rises with training progress, is taxed as non-agricultural earnings when applicable, and is never discounted as a purchase. Children under 12 cannot start these placements; basic lessons require age 6. Adult work remains separately restricted. Sofia starts with an actual sewing contract, rather than an apprentice label disconnected from training progress.

Other monthly training totals: technical 3.50, commercial 2.50, accounting 4, teaching 3, nursing 1, engineering/architecture/law 8, medicine 10, surveying 3.50, research 7, art 3, music 3.50, agriculture/household 0.50, writing 2.50 and leadership 4. Most include 0.50 supplies. These are assumptions based on relative instruction intensity and the schooling benchmarks, not verified university tariffs. Agricultural/household lessons retain 75% of existing pay; other advanced courses are full-time. Existing qualification levels and course durations remain prototype abstractions.

## Household costs and saved contracts

A working smallholder supplies an assumed **35% of household food**. This is one shared production contribution: adding a second farmer does not multiply the same farm's food. Reduced work capacity, illness or time in day lessons reduces this provision. Other farm laborers do not automatically supply free food.

Domestic work supplies an assumed 60% of that worker's food, and cook employment 40%. Funded boarding supplies the student's meals; an unfunded boarding bill restores their household food costs, preventing free board. Provision reduces food purchases and is shown in Finances; it never adds cash to the purse. Existing baseline food, care, upkeep and price-index assumptions remain. Property and consumption duties are still charged independently.

Contracts snapshot course costs, mode, retained pay, apprenticeship stipends and board. Save/load preserves these terms and current earnings. Old full-time courses retain their stored fee and unpaid terms; resuming does not silently reinterpret an old agreement as a paid placement. Day lessons restore the preceding job on completion. Apprenticeships award their qualification and end the stipend; graduates must find work rather than receiving an automatic job. Unfunded zero-fee apprenticeships can keep progressing because no tuition payment is required. Fee-bearing courses retain the existing pause/suspension rules.

Funding checks simulate the proposed arrangement on a copied person, including lost wages, retained pay, produce, board, taxes and the full-course shortfall. They keep the existing three-month household reserve, except that a zero-fee paid placement covering the proposed household bills needs no tuition reserve. Previewing an arrangement cannot mutate the real person's employment.

## Verification and remaining limits

HistoricalEconomyTest covers cash-versus-food accounting, subsidized costs, retained work, rising apprentice pay, graduation without ghost wages, paid/unpaid board, shared farm production, save contracts and new catalogue offers. Regression checks include careers, costs, decisions, events, succession, saves, business reports, finance UI and simulated players. A taxed-business save-validation bug discovered during these checks was corrected: net equals revenue minus operating costs minus income duties.

The one-seed 50-year smoke batch in [historical-income-50-years](../Reports/Simulations/historical-income-50-years/summary.md) completed passive, education and enterprise runs without month-end debt. Education produced two living graduates and enterprise operated three businesses. This is evidence that the calibrated economy permits different investments, not proof of optimal balance: one seed, scripted players, assumed school access and simplified household production limit the conclusion. Earlier reports represent earlier wage rules.