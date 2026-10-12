# Succession and loans

The game now generates age-related deaths. Mortality uses its own saved random stream: low annual risk from 55, increasing at 65, 75 and 85, with death guaranteed at 95. Illness increases the risk. These are prototype simulation estimates, not historical demographic data. A death pauses the clock, records grief and a Chronicle entry, and removes the person from the household; the deceased remains in the family tree.

Open **Succession & will** to nominate the next head and inspect a cash inheritance projection. On the head's death, a mandatory paused screen lets you choose a living relative. The nominee is a recommendation, not a forced choice. Children, spouses and other relatives can lead; a minor can continue the family without a separate regency model. If no relative survives, the run ends. The new head returns to Landi House and retains their own memories and knowledge; they do not inherit the former player's understanding of everyone.

The cash plan is an **explicit equal-share will**, separate from leadership. Children share equally; descendants represent a child who predeceased the parent, dividing that branch's share. Cent remainders are allocated in stable family order. There are no arbitrary disinheritance or unequal-share controls. Other heirs' money is stored as personal inheritance outside the shared purse. The continuing head's share and previously held personal inheritance enter the purse. Bank liabilities are settled before distribution; unpaid principal and negative cash survive succession. Dowry capital still owed to resident couples is reserved rather than counted as free inheritance.

Personal inheritances of other deceased relatives pass to their descendants, or to a surviving spouse if there are no descendants. With neither, the estate is recorded as unsettled outside the shared purse; more remote intestate claims are not silently fabricated. House and business ownership remain family-held in this first cash-only model.

## Historical scope

From April 1862, the cash estate also pays the scenario's modeled 2% inheritance registration duty after loans and reserved dowry capital and before shares are calculated. The same duty applies to relatives' personal cash estates. The projection and actual settlement use the current date's law. See [Laws and taxes](Laws-and-Taxes.md) for dates, simplifications and validation; **Laws & obligations** shows the current rules in game.

The 1865 Italian Civil Code, effective in 1866, included sons and daughters in succession (article 736), provided representation (articles 729–733), and reserved half the estate for children (article 805). An angry parent could not simply remove a protected share. [Original code](https://it.wikisource.org/wiki/Codice_civile_(1865)/Libro_III/Titolo_II).

Earlier Tuscan intestacy was different: Napoleonic equality was followed by an 1814 restoration favoring male lines. Therefore the game implements a deliberate equal-share **will**, not a claim that Tuscan intestacy always divided equally. [Galligani's legal-history research, pp. 17–19](https://www.historiaetius.eu/uploads/5/9/4/8/5948821/galligani_6.pdf). A Tuscan-region archival example from 1854 also records a will benefiting multiple children. [Regional Council publication, p. 78](https://www-next.consiglio.regione.toscana.it/sites/default/files/eda-2025-12/pub4148.pdf).

This preserves every descendant's share, but is not a complete historical estate calculator: municipal statutes, exact statutory reserves across periods, spouse usufruct, past gifts/dowry collation, illegitimacy distinctions, property division, guardianship and exceptional legal unworthiness require additional rules. No unsupported disinheritance mechanism is offered.

## Loans

Open **Finances → Loans** to borrow or make partial/full repayments. Total outstanding principal is capped at 10,000 in-game lire. The prototype annual rate is 5%, with no compound interest and no scheduled principal installments. Interest accrues in fixed integer units monthly and is billed every twelve simulated months after borrowing. Early repayment pays the corresponding accrued interest, preventing a free loan repaid just before the anniversary. The discount bonus does not discount loan principal or interest. Unaffordable annual interest becomes unpaid bills and pauses time on first entering debt.

Borrowing, repayments, annual interest and estate settlements appear in Payments and sales and the Chronicle. Cash received from a loan does not count as earned wealth: the legacy objective subtracts outstanding principal and accrued interest. Mortality, nominations, personal inheritance, pending succession, loans and their billing dates survive save/load. Version 1 saves without these modules migrate to an empty loan book and a fresh mortality stream.

Run `Tests/LoansSuccessionTest.gd` for anniversary billing, partial/early repayment, daughters, protected shares, representation, debt inheritance, natural death, clock interruption, observer changes, save migration and real UI controls. `Tools/PreviewSuccession.gd` captures the screens. The simulator now chooses the nominee or first adult relative on succession and returns `family_ended` when no one survives, rather than fabricating heirs. Its existing bots do not automatically borrow or arrange marriage proposals.
