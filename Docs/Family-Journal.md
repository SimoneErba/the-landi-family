# Family Journal

The Journal adds a household activity overview to the existing archive interface. Open its separate page with **Family Journal** in the navigation or **J**. Other screens use the full available width. **Space** pauses or plays and **1–5** select speed presets.

## Activities

Each living resident has a portrait, occupation or daily-life fallback, and a Manage button opening the existing person inspector. Current schooling and apprenticeships, independent projects, business management, illness and observable concerns appear together. Travelling relatives and family construction/renovation projects are also included. Measurable courses and projects show equivalent months completed; routine work has an ongoing label. Remaining months are an estimate: aptitude, agreement and interruptions affect actual completion.

## Queue

Queue the existing independent study, house repair and village visits for an adult resident. Each person has their own priority order. Multiple people can work simultaneously, while one person keeps one family-project commitment. A paused first plan holds that person's queue until resumed, moved or cancelled.

Adding a plan records an intention, not consent. When the first plan becomes eligible at a monthly update, the simulation asks its participant through the existing relationship system. They can accept reluctantly or refuse. Funding, illness, childbirth, active education, business duties, travel and the shared monthly request limit can block starting. A refused plan becomes a failed outcome rather than repeatedly asking every month. Later plans start on a subsequent monthly update. No costs are charged before starting or while paused; previous expenses are not refunded on cancellation.

Started plans retain their original stable ID, priority and proposal month. Queue order, progress, pauses, agreements and outcomes persist in existing save files. Older saves acquire a default queue order during validation. Construction and formal courses retain their existing management systems rather than being moved into a second scheduler.

## History

The History tab reads the existing family chronicle, newest first and grouped by month. Filter by person and by projects or other family events. New project entries carry participant and category metadata. Earlier chronicle entries remain available; person matching falls back to the text for those records, and untagged entries appear under family events. Only lifecycle changes are logged, not each month's incremental progress. Trivial queue/pause commands use inline feedback rather than notifications.

The village currently displays places and buildings, not individual character markers, so there is no character hover highlight to connect. Manage reuses the same inspector rather than creating a second character screen. Personal ambitions remain represented through existing observations; the journal does not expose hidden psychological scores.

Rows refresh when observed state changes, rather than on every clock repaint. The person filter includes later arrivals and births. Run `Tests/FamilyJournalTest.gd` for queue independence, consent, persistence, pause economics, history filters, unchanged-row reuse, inspector routing and page navigation. `Tools/PreviewFamilyJournal.gd` renders the full page, queue, village and smaller-window view.
