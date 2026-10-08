# Image Generation Guide

This file defines the visual rules for every generated image used in the game.

The objective is consistency.

Every portrait, menu illustration, house image, object, icon, event illustration, and decorative element should look as if it belongs to the same game and was produced by the same artist.

---

# 1. Core Visual Identity

The game takes place around an Italian family and their house across multiple generations.

The visual style should evoke:

- late 19th-century and early 20th-century Italy
- family archives
- old photographs
- illustrated family records
- old account books
- faded ink
- charcoal and pencil drawings
- restrained historical realism

The visual identity should feel:

- intimate
- nostalgic
- slightly melancholic
- understated
- human
- historical
- imperfect
- warm but muted

Avoid fantasy, exaggerated stylization, bright modern UI art, glossy digital painting, or cartoon aesthetics.

---

# 2. Global Style

Use the following base description for all generated artwork:

> Historical Italian family archive illustration. Restrained semi-realistic hand-drawn style inspired by early 20th-century portrait sketches, faded family photographs, pencil, charcoal, ink and subtle watercolor. Muted earthy palette, aged paper feeling, soft contrast, slightly imperfect hand-made lines, natural faces and proportions, subdued lighting, no glossy digital rendering, no modern concept-art aesthetic.

Images should look like illustrations recovered from the same family's archive.

They should not look like independently commissioned artworks.

---

# 3. Color Palette

Primary visual colors:

- warm grey
- charcoal
- faded black
- brown
- dark walnut
- beige
- parchment
- desaturated olive
- muted burgundy
- dusty blue

Avoid:

- highly saturated colors
- neon colors
- pure white
- pure black backgrounds
- strong blue digital shadows
- cinematic orange/teal grading

Color should generally feel slightly faded.

---

# 4. Texture

Images should have subtle analog imperfections.

Possible textures:

- old paper
- graphite
- charcoal
- ink
- faded watercolor
- photographic grain
- slight discoloration

Do not make the texture excessively dirty.

The interface should still remain clean and readable.

---

# 5. Portraits

Portraits are one of the most important visual elements in the game.

The player may encounter hundreds or thousands of characters over multiple generations.

Portraits must therefore follow a strict visual system.

## Portrait composition

All portraits should use approximately the same framing.

Preferred framing:

- head and upper shoulders
- front-facing or slight three-quarter angle
- neutral camera height
- simple background
- consistent portrait dimensions
- face centered
- similar head size across portraits

Avoid dramatic poses.

Avoid cinematic camera angles.

Avoid full-body portraits for normal character cards.

---

# 6. Portrait Background

Character portraits should use a minimal background.

Preferred background:

- faded beige
- warm grey
- parchment
- subtle paper texture

The background should not contain recognizable scenery.

The purpose of the portrait is identification, not storytelling.

Event illustrations may include environments.

---

# 7. Facial Expression

Default portraits should be emotionally restrained.

Preferred expressions:

- neutral
- slight seriousness
- subtle warmth
- subtle tiredness
- subtle confidence

Avoid:

- exaggerated smiles
- exaggerated sadness
- cartoon expressions
- dramatic anger
- theatrical poses

Characters should look like ordinary people photographed for a family portrait.

---

# 8. Historical Appearance

Clothing, hairstyles and grooming should correspond approximately to the character's period.

However, portraits should remain visually consistent across generations.

Historical accuracy should affect:

- hairstyle
- beard and moustache styles
- glasses
- collars
- jackets
- dresses
- shirts
- accessories

The illustration technique itself should remain constant.

A character born in 1880 and a character born in 1980 should still look like they belong to the same game's portrait system.

---

# 9. Character Portrait Generation Strategy

Do NOT generate every character as a completely independent AI image.

This would produce inconsistent faces and make relatives visually unrelated.

The game should use a controlled portrait generation system.

There are three possible approaches.

---

## Option A — Modular Portrait Generator

Preferred long-term solution.

Create reusable visual components such as:

### Face structure

- narrow face
- wide face
- round face
- oval face
- long face
- angular face

### Skin

Several skin tones and subtle variations.

### Eyes

Different:

- shapes
- spacing
- sizes
- eyebrow shapes

### Nose

Different:

- width
- length
- bridge
- tip

### Mouth

Different:

- width
- lip shape
- resting expression

### Hair

Many hairstyles divided by:

- gender presentation
- age
- historical period
- hair texture

### Facial hair

- moustaches
- beards
- stubble
- sideburns

### Accessories

- glasses
- hats
- earrings
- historical accessories

### Age layers

Characters should visually age.

Possible age states:

- child
- teenager
- young adult
- adult
- mature adult
- elderly

Age can modify:

- wrinkles
- hair color
- hairline
- facial fullness
- eye bags
- skin texture

The game combines these layers into a portrait.

This makes it possible to generate thousands of characters while keeping the art style perfectly consistent.

---

# 10. Family Resemblance

Family resemblance is important.

Children should visually inherit traits from their parents.

Possible inherited attributes:

- face shape
- eye shape
- eye color
- nose
- mouth
- skin tone
- hair color
- hair texture
- eyebrows
- jaw shape

Example:

Father:

- long face
- large nose
- dark curly hair
- narrow eyes

Mother:

- round face
- small nose
- brown straight hair
- wide eyes

Child:

- long face from father
- small nose from mother
- dark straight hair
- wide eyes from mother

The exact combination can contain randomness.

This allows the player to recognize family resemblance without every relative looking identical.

---

# 11. Genetic Portrait Data

Each character should ideally have a hidden visual genotype.

Example:

```text
face_shape = 0.72
jaw_width = 0.43
eye_spacing = 0.61
eye_size = 0.48
nose_length = 0.67
nose_width = 0.35
mouth_width = 0.58
skin_tone = 0.42
hair_color = dark_brown
hair_texture = curly
```

Children receive values derived from their parents plus small random variation.

Example:

```text
child_trait =
    parentA_trait * random_weight
    + parentB_trait * inverse_weight
    + mutation
```

The portrait renderer then converts these values into visual features.

The psychological simulation and the visual genetics system should remain independent.

---

# 12. Recommended Portrait Architecture

Preferred architecture:

```text
Character
 ├── Genetics
 │    ├── face shape
 │    ├── eyes
 │    ├── nose
 │    ├── mouth
 │    ├── skin
 │    └── hair
 │
 ├── Appearance
 │    ├── hairstyle
 │    ├── beard
 │    ├── glasses
 │    ├── clothing
 │    └── age
 │
 └── Portrait Renderer
```

The genetic values remain stable.

Appearance changes through life.

For example:

A character can:

- change hairstyle
- grow a beard
- start wearing glasses
- become bald
- become grey-haired
- age

without losing the recognizable underlying face.

---

# 13. AI and Portrait Production

AI image generation should primarily be used to create the reusable portrait components and reference artwork.

Do not rely on runtime AI generation for every NPC.

Reasons:

- visual inconsistency
- expensive generation
- difficult reproducibility
- difficult inheritance
- difficult save-game stability
- characters may unexpectedly change appearance
- generation may produce unusable faces

Instead:

1. Generate a controlled library of facial features.
2. Clean and standardize them.
3. Use them as game assets.
4. Combine them procedurally at runtime.

AI therefore acts as the game's artist, not as the runtime portrait engine.

---

# 14. Alternative: Base Face Library

If a modular facial system is too expensive to build initially, use a simpler prototype.

Generate approximately:

- 40 male base faces
- 40 female base faces
- several age variants
- multiple hairstyles
- facial hair
- glasses
- clothing layers

Then modify them through overlays and variations.

This can already create thousands of visually distinct people.

For example:

```text
80 faces
× 12 hairstyles
× 5 hair colors
× 8 clothing variants
× 4 accessories
```

produces a very large number of combinations without requiring thousands of unique paintings.

This is a better prototype than generating 1,000 complete portraits.

---

# 15. Portrait Seed

Every character must have a permanent portrait seed.

Example:

```text
portraitSeed = 91824721
```

The seed determines visual variations.

Given the same:

- genetics
- appearance
- age
- seed

the portrait renderer must always reproduce the same result.

The player's uncle must never randomly acquire a different face after loading a save.

---

# 16. Character Aging

Portraits should change during the character's life.

However, the character must remain immediately recognizable.

Age should gradually affect:

- wrinkles
- skin
- hairline
- hair color
- beard color
- facial fullness
- posture if shoulders are visible

Do not generate completely unrelated portraits for different ages.

Age should be a transformation of the same face.

---

# 17. Clothing

Clothing should communicate:

- historical period
- social class
- profession
- wealth
- personality when appropriate

But it should remain secondary to the face.

For standard portraits, clothing should occupy only the lower portion of the image.

Avoid elaborate costumes that distract from character recognition.

---

# 18. Character Portrait Prompt Template

When generating base portrait assets, use a prompt based on:

> Portrait of [CHARACTER DESCRIPTION], Italian, approximately [AGE] years old, [FACE DESCRIPTION], [HAIR], [OPTIONAL FACIAL HAIR], wearing modest [PERIOD] clothing. Head and upper shoulders, slight three-quarter view, neutral restrained expression, plain faded parchment background. Historical Italian family archive illustration, semi-realistic hand-drawn portrait, graphite, charcoal, subtle ink and faded watercolor, muted earthy palette, early 20th-century family photograph influence, natural facial proportions, soft diffuse lighting, slightly imperfect traditional drawing, no cinematic composition, no modern digital concept-art appearance.

Keep the framing and visual style identical across all portrait generation sessions.

---

# 19. Menu Icons

Menu icons should use the same artistic language.

Examples:

### People

Simple group of two or three human silhouettes.

### House

Simple old Italian house silhouette.

### Finances

Coins, ledger, purse, or banknote.

### Family Tree

Small branching structure connecting portrait circles.

### Chronicle

Old book or journal.

Icons should be:

- simple
- readable at small size
- slightly hand-drawn
- rounded where appropriate
- limited in detail
- consistent line thickness

Do not make them realistic miniatures.

---

# 20. House Illustrations

The house should remain visually recognizable throughout the campaign.

Important structural features should stay consistent.

Examples:

- roof shape
- number of floors
- windows
- staircase
- courtyard
- major extensions

Renovations should modify the existing building rather than generating a completely new house.

The house should visually accumulate history.

---

# 21. Object Illustrations

Important objects may become part of the family's history.

Examples:

- wedding photograph
- grandfather's watch
- old piano
- desk
- painting
- family ledger
- military medal
- letter
- inherited ring

Object illustrations should resemble catalog sketches from an old archive.

Use:

- isolated object
- simple background
- soft shadow if necessary
- consistent scale
- muted palette

---

# 22. Event Illustrations

Major events may occasionally receive larger illustrations.

Examples:

- wedding
- funeral
- argument
- birth
- departure
- purchase of the house
- renovation
- bankruptcy
- family dinner
- inheritance dispute

These may be more atmospheric than portraits.

However, they must retain the same:

- drawing technique
- palette
- historical treatment
- character appearance

Characters appearing in event illustrations should resemble their portraits whenever technically possible.

---

# 23. Negative Style Rules

Avoid generating images containing:

- anime aesthetics
- Pixar-like characters
- Disney-like characters
- comic-book rendering
- fantasy clothing
- fantasy architecture
- exaggerated facial features
- hyper-realistic photography
- glossy 3D renders
- cinematic concept art
- dramatic movie lighting
- modern UI illustration style
- neon colors
- extreme depth of field
- over-detailed backgrounds

---

# 24. Consistency Rule

Before accepting any generated asset, ask:

> Could this image plausibly have been drawn by the same artist who produced every other image in the game?

If the answer is no, reject or regenerate it.

Consistency is more important than individual image quality.

A collection of slightly imperfect but coherent illustrations is preferable to a collection of individually beautiful images made in unrelated styles.

---

# 25. Production Principle

The visual system should have three layers:

```text
STYLE
    shared by the entire game

IDENTITY
    stable features belonging to a specific character or place

STATE
    temporary appearance caused by age, period, clothing, wealth, health, etc.
```

For a character:

```text
STYLE
historical archive drawing

IDENTITY
face genetics

STATE
age + hair + clothes + accessories
```

For the house:

```text
STYLE
historical archive drawing

IDENTITY
building structure

STATE
renovations + damage + extensions + period
```

This distinction should guide all asset generation.

---

# 26. Most Important Rule

Never solve a consistency problem by simply asking an image model to "make something similar."

Persist the underlying identity.

Characters need persistent facial data.

The house needs persistent structural data.

Objects need persistent designs.

AI should generate the building blocks.

The game should assemble and preserve them.
