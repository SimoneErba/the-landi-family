# Century simulation engine

This harness runs the current game without the UI or real-time clock. Every run creates a fresh `GameState`; it never loads, replaces or autosaves the player's family. It uses normal event resolution, influence requests, consent, monthly wages/bills, courses, construction, activities and business management.

Run from the project directory with the Godot executable available on PATH:

```powershell
godot --verbose --headless --audio-driver Dummy --path . --script Tools/RunSimulations.gd -- --years=100 --seeds=3 --seed-start=1 --strategies=passive,frugal,education,enterprise,family --bonus=discount --objective=wealth --output=res://Reports/Simulations/century-check
```

On a Windows Mono install, use its console executable instead of `godot`. Arguments after the second `--` configure the batch. Defaults: 100 years, three seeds beginning at 1, all five strategies, the discount bonus and wealth objective. Use a new output directory to retain earlier batches. Years and seeds each support 1–100; strategies must be unique. Outputs are restricted to `Reports/Simulations`.

For a quick smoke run, use `--years=2 --seeds=1`. To compare bonuses fairly, keep the seed list, strategies and objective fixed and run each bonus into its own directory. Same inputs, sources and seed reproduce each run's decisions and checkpoints. Policies can cause random streams to diverge as they change which events are eligible.

Optional `--starting-family=alone|wife|child|authored` selects a main-menu household (default: the original seven-person authored family). `--event-policy=first_legal` makes every strategy choose the first available event option, falling back only when earlier options are unavailable. The default `strategy` retains each policy's preferences. For routine work and study with first-option events, use `--strategies=education --event-policy=first_legal`. Reports count first/other event options, work/study proposals and accepted requests, total wages/food/tuition, and the final monthly household budget. Accounting-basis cents divided by 100 match the stable lire displayed in-game; Italian-lira equivalents multiply that amount by 0.84.

## Components

The `child` starting-family key now means Giovanni, his wife Maria, and their six-year-old son Carlo. Reports generated before this change used a two-person single-father start and should not be compared as the same household.

- `SimulationRunner.gd`: configuration validation, isolated run execution, yearly checkpoints, stalled-run detection and median/min/max aggregation. `run_one(config, strategy, seed)` returns a report dictionary for use by tests or other tools.
- `SimulatedPlayer.gd`: event-choice preferences and quarterly proactive decisions. Repeat proposals have a two-year cooldown. Refusals, reluctance, tuition, unavailable workers, construction time and operating costs retain their normal consequences. Policies never set relationships, skills, spouses or wealth directly.
- `SimulationReport.gd`: JSON, readable Markdown and yearly CSV exports. Records configuration and source-file fingerprints so results can be associated with the actual rules used.
- `Tools/RunSimulations.gd`: command-line entry point; saves completed runs incrementally and yields between runs.

## Strategies

| Strategy | Simulated player decisions |
| --- | --- |
| Passive | Chooses the first legal event response; makes no proactive requests. |
| Frugal | Favors cash and health/property recovery; suggests higher-paid eligible jobs. |
| Education | Favors learning and supportive responses; funds eligible courses when income and six months of household bills cover the commitment; suggests eligible employment. |
| Enterprise | Buys available land, builds up to three farms/workshops, requests managers, upgrades property and expands/repairs the family house when needed. Keeps six months of household bills in reserve. |
| Family | Favors supportive responses; asks departing people to stay, absent relatives to join, and unmarried adults to consider marriage. Expands overcrowded housing and suggests employment. |

These are deliberately simple scripted test players. They use eligibility assessments when selecting careers/courses; they do not reproduce imperfect human knowledge or optimal play. The head follows the same authority restrictions as the UI. Head self-training/job requests are not invented. Marriage acceptance remains a goal until the actual game supplies a partner.

## Reports

Each batch directory contains:

- `summary.md`: comparison by strategy and individual-run table, with warnings.
- `results.json`: config, source fingerprints, runs, counters, the last 100 decision samples per run, yearly history and aggregate ranges.
- `annual.csv`: one row per run/year, including year zero, for plotting and spreadsheet analysis.

Money uses Italian-lira equivalents to compare historical denominations; real savings also use the starting food-price index. Education counts living members with university-level education or higher. Population includes living relatives outside the house. Business profit accumulates only amounts paid to the family. Debt statistics describe month-end balances after events and business settlement; intermediate household bill crises are still handled by the game.

Stalled events return an explicit error instead of being silently discarded. An unexpected event queue cycle is bounded. A completed run means the requested time was simulated, not that its ambition succeeded. Ambition wins and completion month are separate fields.

## Current game limits

The normal age-related mortality and equal-share cash-will systems run in the harness. On succession it chooses the nominee, otherwise the first adult relative, otherwise a surviving minor. No surviving relative means `family_ended`, and the report records how many months were actually reached. No deaths, spouses, heirs or money are fabricated to force 100 years. Existing bots request marriage intentions but do not arrange proposals or borrow automatically. Full historical intestacy, property estates and spousal usufruct remain outside this cash-only prototype. Reports include `heads_played` and final loan principal.

Verification: `Tests/SimulationRunnerTest.gd` checks determinism, isolation through fresh-state construction, actual paid property development, manager proposals, real refusals, request cooldowns, impossible event handling, annual records, aggregation and exports.
