# Tax model validation

The current source was exercised with passive, education and enterprise policies, one common seed (1), the authored household, discount bonus and wealth objective. Each run requested 100 years but ended naturally after 857 months (about 71 years) when the family line died out. No heirs or money were fabricated to complete the century.

All three runs had zero month-end debt months and no stalled simulation or event errors. Household assessments/duties totaled 1,328.53 game lire for passive, 1,279.84 for education and 8,927.67 for enterprise; business income duties and estate duties are separate and are not included in this household total. The enterprise run accumulated three owned businesses, so its higher property burden is consistent with holdings being assessed rather than everyone paying the same flat levy.

This is an economic smoke check, not proof of balance or historical tax rates. The short sample shares one seed, policies are scripted, all lines end before 1884, and the lack of bot-arranged marriages limits descendant survival. The 1809, 1869 and 1884 boundaries, taxable mouths, class exemptions, ownership changes, income duties, estate conservation and saved state are covered separately by LawsTest. The regression checks for economy, education, business, finance presentation, history, decisions, succession, saves and the runner also pass.

The tax model, sources, assumptions and limits are documented in Docs/Laws-and-Taxes.md. Source fingerprints in results.json identify the implementation tested here.