# The Landi family: rural Tuscany from 1800

The household lives in the Tuscan countryside, tending a small podere with grain, vines, and olives. The starting head and son work the farm; relatives retain carpentry, sewing, household care, and ambitions for education. Florence replaces Milan as the nearby destination for independence. The family is authored as smallholders; mezzadria provides regional context and neighboring estates, not a simulated ownership contract.

The fixed historical calendar is authored in `Data/historical_events.json`, merged into the event catalog by `Tools/build_event_catalog.py`. National and regional news occurs once on its month, independent of random chance. Events queue behind other milestones, pause the clock, and add history and choices to the Chronicle. Decisions influence the household rather than changing historical outcomes. Economic multipliers, costs, and psychological effects are gameplay estimates.

## Historical sources

- [Treccani: Tuscany](https://www.treccani.it/enciclopedia/toscana/) and [Kingdom of Etruria](https://www.treccani.it/enciclopedia/regno-di-etruria/): French occupation, the 1801–1807 kingdom, restoration, and the end of grand-ducal rule.
- [Tuscan Regional Council: independence of Tuscany](https://www-new.consiglio.regione.toscana.it/iniziative/indipendenza-della-toscana): 27 April 1859 and the March 1860 plebiscite.
- [Treccani: Risorgimento](https://www.treccani.it/enciclopedia/risorgimento/): revolutionary movements and the wars of independence.
- [Presidency of the Republic: 150 years of Italian unity](https://presidenti.quirinale.it/elementi/54797): 1861, Veneto, Rome, and the later territorial outcome of the First World War.
- [Treccani: Italy](https://www.treccani.it/enciclopedia/italia/): the broader historical sequence and Italian neutrality in 1914.
- [Presidency of the Republic: 2 June 1946](https://www.quirinale.it/it/pagine/2-giugno-1946-2-giugno-2016): the 1943 armistice and transition to a republic.

The usual hundred-year scenario covers 1800–1900. The existing prototype does not enforce an end date, so the catalog also provides events through 1948 for longer runs. Mortality and succession remain future systems. Regional reports do not assume fighting happened on the family's doorstep.

## Currency

In 1800 the family's accounts use **Tuscan lire**: 20 soldi per lira, 12 denari per soldo, and 60 quattrini per lira. The UI abbreviates soldi and denari as `s` and `d`. Decimal centesimi belong to the later Italian lira.

In **1826**, the fiorino reform changes the displayed accounts: **1 fiorino = 1⅔ Tuscan lire = 100 quattrini**. Because the simulation has month precision and the historical source establishes the year, this reform is placed in January as a scenario convention.

In **November 1859**, an event changes the accounts to the new Italian lira at **1 fiorino = 1.40 Italian lire**. This precedes the 1861 proclamation of the kingdom; the nationwide 1862 monetary law is not presented as Tuscany's first adoption.

- [Bank of Italy monetary chronology](https://www.bancaditalia.it/servizi-cittadino/mostre-ed-eventi/mostra-moneta/esplora/stanza-a/cronologia/index.html): fiorino reform and the spread of decimal lire during unification.
- [Tuscan provisional government acts, 1859](https://www.giustizia.it/resources/cms/documents/Atti_Governo__Toscana.pdf) and [the monetary decrees](https://www.giustizia.it/resources/cms/documents/Atti_Toscana_1859_Sez6.pdf): November adoption and denomination changes.
- [Tuscan lira](https://en.wikipedia.org/wiki/Tuscan_lira) and [Tuscan fiorino](https://en.wikipedia.org/wiki/Tuscan_florin): subdivisions and conversion ratios.

A fixed accounting basis preserves the value of cash, debts, wages, tuition, prices, incident costs, delayed payments, and ledger amounts across denomination changes. The `_cents` names are retained internally for compatibility; they represent hundredths of the base Tuscan lira in new saves, not a historical Tuscan coin. The UI rounds to the active currency's subdivision. For example: 100 Tuscan lire → 60 fiorini → 84 Italian lire. This is a change of denomination, not a loss of purchasing value.

Mixed French and local coins during Napoleonic rule, in-kind payments, and barter are summarized rather than modeled. The former 1912 salary benchmarks are retained in `Finances-1912.md` as background; all 1800 wages, food allowances, and fixed inflation are prototype balance values.
