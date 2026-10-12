# Code map

The prototype currently uses GDScript. Start here when changing behavior; the longer development guide also contains descriptions of earlier prototype stages.

## Main boundaries

- `Simulation/`: game rules and serializable state. No screen nodes, portraits or UI input.
- `Scripts/`: Godot controls, presentation and routing of player actions into the simulation.
- `Data/`: authored people, event choices and career/training catalogues.
- `Tests/`: standalone Godot scripts checking rules and native UI integration.
- `Tools/`: previews, batch simulation entry points and analysis utilities.
- `Reports/Simulations/`: generated balance evidence, not game state or runtime dependencies. Analysis tools read these outputs.

`Simulation/GameState.gd` owns the systems. `Scripts/FamilyScreen.gd` owns the main gameplay screen and hosts the smaller presentation modules. It is still the largest UI file; add feature-specific presentation to those modules rather than growing it for every new feature.

## Where to make a change

| Change | Rules / data | Presentation | Relevant checks |
| --- | --- | --- | --- |
| Main menu and starting choices | `Simulation/StartingFamily.gd`, `Simulation/Legacy.gd` | `Scripts/MainMenu.gd`, `Scripts/StartingFocus.gd` | `MainMenuTest`, `LegacyTest` |
| Monthly wages, bills, food support | `Simulation/Economy.gd` | `Scripts/FinancesScreen.gd`, `Scripts/PersonStats.gd` | `EconomyTest`, `HistoricalEconomyTest`, `FinancesPresentationTest` |
| Taxes and legal reforms | `Simulation/Laws.gd` | `Scripts/LawsScreen.gd`, finance expense rows | `LawsTest` |
| Training and employment | `Simulation/Careers.gd`, `Data/careers.json` | `Scripts/PersonProfile.gd` | `CareersTest`, `HistoricalEconomyTest` |
| Psychology and requests | `Simulation/Person.gd`, `Simulation/Influence.gd`, `Simulation/DecisionSystem.gd` | `Scripts/PersonProfile.gd`, `Scripts/AssignmentReaction.gd` | `PersonTest`, `InfluenceTest`, `DecisionSystemTest`, `ActionFeedbackTest` |
| Activity queues | `Simulation/Activities/` | `Scripts/PersonActivities.gd`, `Scripts/FamilyJournal.gd` | `GameplayLayerTest`, `FamilyJournalTest` |
| Shared time and secondhand knowledge | `Simulation/SocialLife.gd`, observer beliefs in `Simulation/Person.gd` | `Scripts/PersonSocialLife.gd` | `SocialLifeTest`, `PersonProfileTest` |
| Marriage and dowries | `Simulation/Marriage.gd` | `Scripts/PersonMarriage.gd` | `MarriageTest` |
| Death, wills and loans | `Simulation/Succession.gd`, `Simulation/Loans.gd` | `Scripts/SuccessionScreen.gd`, finances | `LoansSuccessionTest` |
| Village property and businesses | `Simulation/Village/` | `Scripts/VillageScreen.gd`, `Scripts/VillageMap.gd` | `VillageDevelopmentTest`, `VillageBusinessTest`, `PropertyNegotiationTest` |
| Travel | `Simulation/Travel.gd` | `Scripts/TravelScreen.gd` | `TravelTest` |
| Clock and playback | `Simulation/GameClock.gd` | time controls in `Scripts/FamilyScreen.gd` | `GameClockTest` |
| Save format | `Simulation/SaveGame.gd`, each system's save/restore methods | menu in `Scripts/FamilyScreen.gd` | `SaveGameTest` and changed system's tests |
| Automated balance runs | `Simulation/Testing/`, `Tools/RunSimulations.gd` | Markdown/CSV/JSON reports | `SimulationRunnerTest` |

Test names in this table are files under `Tests/` with the `.gd` extension.

## Monthly update order

`GameState.advance_month()` stops while succession or an enabled event needs a decision. It then:

1. Prepares economic event modifiers and settles the month being completed.
2. Advances the calendar and elapsed-month counter; processes laws and loan interest.
3. Updates each person, birthdays, financial stress and career progress.
4. Processes mortality/succession, then autonomous personal decisions.
5. Advances travel, activities, village, marriage, shared time, events and the legacy objective, in that order.

That order affects costs, eligibility and consequences. Keep it explicit and check dependent systems when changing it. The UI refreshes from clock signals after the state changes.

## Money and account views

Money is integer hundredths of a Tuscan lira. `Economy.money()` formats the stable gameplay currency; the finances UI abbreviates lire as `L.`. Simulation reports may also contain Italian-lira equivalents, so report values need not match UI denominations.

`Economy.budget()` is a forecast with no side effects. `settle_month()` uses that forecast to spend cash, append the ledger entry and advance inflation. The current budget and the last settled ledger month are distinct views.

Food-support helpers keep shared farm produce, employment meals and boarding rules together. Funded tuition includes board; unfunded boarding restores the household food cost. Preserve integer rounding and affordability order when adjusting these rules.

`FinancesScreen.build()` assembles the page; `_heading()`, `_income()` and `_expenses()` render individual sections. The budget supplies all row values and totals. New expense categories must appear in the total, detailed rows and proportional strip; `FinancesPresentationTest` checks that displayed rows reconcile with the displayed total.

## Making changes safely

- Keep private psychology and agreement scores inside the simulation. UI views should show communicated responses and observer knowledge.
- Use existing request APIs for decisions, including costs, consent and monthly cooldowns. Avoid writing state directly from a new button to bypass those rules.
- Keep persistent dictionary keys and stable IDs compatible with existing saves. Update save validation and migration together when adding persistent fields.
- Prefer named helpers for a distinct rule or screen section. Format complex dictionaries over several lines so fields are easy to find.
- Add tests for changed behavior and important boundaries rather than private helper structure. For refactors, compare public results as well as running affected suites.
- Keep generated previews and temporary verification files under `.godot/`. Preserve intentional baseline reports when comparing balance changes.

## Run checks

Use your Godot executable from the project root:

```powershell
godot --headless --audio-driver Dummy --path . --script Tests/HistoricalEconomyTest.gd
godot --headless --audio-driver Dummy --path . --script Tests/FinancesPresentationTest.gd
godot --headless --audio-driver Dummy --path . --script Tests/SaveGameTest.gd
```

On Windows, use the console executable for visible output. Tests print `PASS:` on completion. Check for `SCRIPT ERROR` and assertion failures as well as the exit code: a Godot script assertion does not always yield a nonzero process exit. Save-related tests use Godot's per-user data directory; an isolated `APPDATA` directory can be used for a sandboxed run.
