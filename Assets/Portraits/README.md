# Family portrait library

This prototype implements the **base face library** alternative in [PORTRAITS.md](../../PORTRAITS.md), following [ART_DIRECTION.md](../../ART_DIRECTION.md). Artwork was produced with the built-in image generation tool. The exact production prompts are in [PROMPTS.md](PROMPTS.md).

Each atlas has five equal columns: child (reference age 8), teenager (16), adult (28), mature adult (50), elderly (75). `men-v1.png` has Giovanni, Carlo, and Pietro in its three rows; `women-v1.png` has Maria, Anna, Lucia, and Sofia in its four rows. Faces are centered, with upper shoulders, subdued expressions, modest early twentieth century clothing, and graphite / ink / faded watercolor on parchment. Rows preserve one identity through aging and were directed to share family features.

`Scripts/PersonPortrait.gd` caches atlas textures and regions. The roster, departed relatives, and person popup use the same renderer. Portraits advance at ages 13, 22, 40, and 65, following the simulation's existing birthdays. Deceased people retain their last age variant. No runtime image generation or global random calls are used.

`Simulation/PortraitIdentity.gd` separates a permanent seed and numeric visual genetics from mutable appearance (`presentation` and `base_face`). Authored starters persist all three in `Data/people.json`. Unauthored people receive deterministic genetics; when parents are supplied, traits blend parental values with small seeded variation. GameState resolves parents before children, independent of roster order. A library base is chosen once by presentation and a seeded, genetically weighted match when no explicit face is provided. Weighted selection preserves foundation variety; the facial shader supplies the inherited proportions. `Scripts/PortraitFeatures.gdshader` then reshapes face length, jaw width, eye spacing and size, nose length and width, and mouth width, and varies skin wash, hair color, and hair wave from the inherited traits. Each portrait owns its shader material; sharing a cached base texture does not share facial traits. Hair gradually greys from 40 to 75. Visual traits do not affect psychology, goals, or knowledge.

This is a procedural renderer built on seven reusable base identities and thirty-five age illustrations. Inherited continuous traits reshape and tint individual faces, so new people do not require new artwork. The available range remains bounded by these bases; this is not yet a composited library of independently interchangeable facial parts. Aging uses discrete illustrated stages; infants currently use the child image. Clothing is fixed to the starting era, and separate interchangeable hairstyle, accessory, health, mood, and period layers remain future work. Expand the library or replace the renderer with standardized components to provide finer genetic resemblance and appearance changes.

`portrait.to_data()` produces an independent serializable dictionary. Future save-game code must store it under the person's `portrait` key and restore it through `Person`; the game does not implement save/load yet.

Run `godot --headless --path . --script Tests/PortraitTest.gd` to check identity round trips, inherited trait bounds, initialization order, age transitions, atlas bounds, and matching portraits across household, departed, and detail views.

## Creating new people

Use `GameState.add_person(id, profile)` for arrivals and future births. Supply parent IDs and, optionally, appearance presentation; no portrait seed, base face, or scene node is required. IDs must be unique and parents must already be in the state. The family screen adds cards for new people on its next refresh.

```gdscript
var child = state.add_person("Landi-1918-01", {
    "name": "Elena Landi",
    "birth": {"year": state.year, "month": state.month},
    "parent_ids": ["Carlo", "PartnerId"],
    "branch_id": "Giovanni",
    "portrait": {"appearance": {"presentation": "feminine"}}
})
# Renderer works anywhere, independently of the family scene.
var view = preload("res://Scripts/PersonPortrait.gd").new()
view.custom_minimum_size = Vector2(160, 160)
parent_control.add_child(view)
view.show_person(child)
```

Provide `portrait.seed` to explicitly control the random stream. Omit parents for unrelated people. A single known parent is supported. Missing or cyclic ancestry is handled without recursion failure during initial loading. Identity exports include resolved appearance and all ten genes; restoring them preserves the exact portrait. The base library is static and each face's shader parameters are runtime data.

## Visual preview

Run `godot --path . --script Tools/PreviewPortraits.gd --windowed` to view five unrelated generated founders, five descendants of Giovanni and Maria, and one generated person's five age variants. Append `-- --capture` to save `Assets/Portraits/engine-preview.png` and close automatically. The included preview was captured from Godot's actual OpenGL renderer, including the procedural feature shader.
