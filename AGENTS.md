Here’s the current game concept we converged on.

## Core concept

A **generational family strategy game** spanning roughly **100 years**.

You play as the current **head of a family**, not as an omnipotent god. Your goal is to guide the family toward a chosen legacy while dealing with autonomous relatives who have their own personalities, ambitions, relationships, grudges, values, and plans.

The game is intentionally much smaller and more intimate than CK3, Victoria 3, or Norland.

The “world map” is effectively:

- your family
- the ancestral house
- the family tree
- shared property
- relationships between branches of the family

The core fantasy is:

> **Lead one family across generations, but never fully control the people inside it.**

## Time scale

We initially discussed 1 minute = 1 month, but that would make a century take about 24 real hours.

A better baseline is roughly:

- 20 sec/month at 1×
- 10 sec/month at 2×
- 5 sec/month at 4×

At around **10 seconds/month**, 100 years takes about **3h20 before pauses**.

The game should automatically pause for major events such as:

- death
- marriage
- someone wanting to leave
- inheritance disputes
- business crisis
- family conflict
- major financial problems
- succession

Quiet periods can pass quickly.

## The player is the family head

You control the current patriarch/matriarch/head of household.

You can:

- make requests
- give orders where you have authority
- negotiate
- offer money or property
- threaten consequences
- make promises
- assign responsibilities
- choose successors
- influence education/careers
- manage shared assets

But relatives can refuse.

You are **not controlling units directly**.

Example:

> You ask your son to remain home and take over the family business.

He may:

- accept willingly
- accept reluctantly
- refuse
- agree now and leave years later
- comply while building resentment

When your character dies, you continue as the next family head.

This creates a strong generational mechanic because you may eventually play as someone who suffered under your previous character.

## Family authority is limited

Authority depends on the relationship.

You may have considerable influence over:

- your children
- your spouse
- people financially dependent on you
- people working in your business
- relatives who respect you

But you may have little direct authority over:

- siblings
- cousins
- nephews/nieces
- adult children living elsewhere
- other branches of the family

For example, you may believe your nephew should attend university, but his father is your brother. You need to convince the father rather than simply choosing the nephew’s education.

That creates internal family politics.

## Shared house

Multiple branches of the family may live inside the ancestral house.

Example:

```text
You + spouse + children

Your brother + spouse + children

Possibly elderly parents
```

Ownership can become fragmented:

```text
Your branch        50%
Brother's branch   30%
Sister             20%
```

Rooms, renovations, costs, businesses, and inheritance can create conflicts.

The ancestral house remains a central strategic asset, but it probably **should not be the main visual screen with people walking around**, because months pass too quickly.

Instead, the house gets its own management screen.

## Family branches

As generations expand, you don't control everyone.

Relatives can exist in concentric layers:

- immediate household
- other relatives living in the house
- nearby relatives
- distant relatives
- estranged relatives

Branches can develop distinct identities.

For example:

```text
Your branch:
educated, wealthy, strict

Brother's branch:
large, poor, close-knit

Sister's branch:
moved abroad, sends money home
```

Leadership, wealth, and ownership may shift between these branches over time.

## Goal structure

The game should **not be open-ended like CK3**.

A run lasts roughly 100 years and has a concrete **Family Ambition / Legacy Objective**.

Examples:

### The Family Business
- establish a business
- keep majority family ownership
- pass it through three generations
- retain the ancestral home

### The Great House
- preserve family ownership of the ancestral home
- eliminate debt
- improve/expand it
- survive inheritance fragmentation

### The Dynasty
- maintain a viable line across several generations
- preserve family cohesion
- avoid losing the house

### From Poverty to Wealth
- begin poor
- reach a target asset level
- without losing the ancestral property

### The Learned Family
- produce several highly educated generations
- establish a professional/academic legacy

Different objectives encourage different styles of play.

Money, number of children, prestige, etc. are **resources/strategies**, not the universal win score.

## Core gameplay loop

The game increasingly became a **psychological strategy game**.

The fundamental loop is:

> observe → understand → plan → influence → observe reaction → update your understanding

You notice something:

> Your son may want to leave.

You investigate why.

Perhaps:

- he dislikes the business
- he likes the business but hates working under you
- his partner wants to move
- he values independence
- he feels ignored
- his uncle is encouraging him
- he thinks there is no future locally

Then you choose your intervention.

You are solving **the person**, rather than optimizing a visible acceptance percentage.

## No CK-style exact acceptance numbers

Internally the simulation can absolutely use numeric scoring.

For example:

```text
authority
affection
respect
resentment
ambition
family attachment
independence
financial dependence
```

But the player should generally **not see**:

```text
72% chance of acceptance
+20 father
-15 ambitious
```

Instead they see behavioral evidence.

Example:

> Carlo frequently talks about Milan.

> He has stopped helping in the shop.

> He recently asked how expensive rent is elsewhere.

> He has argued with you twice this year.

When you ask him to stay, his response provides more information.

This makes understanding people part of the strategy.

## Psychology model

We decided not to use MBTI/INFJ/INTJ as the underlying system.

Better foundation:

### Temperament
Big-Five-like continuous traits:

- openness
- conscientiousness
- extraversion
- agreeableness
- emotional stability

### Values
For example:

- family loyalty
- independence
- wealth
- status
- achievement
- tradition
- security
- romance

### Learned tendencies
For example:

- trust
- need for approval
- risk tolerance
- conflict avoidance
- jealousy
- forgiveness
- sensitivity to rejection
- need for autonomy

### Current state
For example:

- stress
- resentment
- happiness
- desires
- relationships
- current goals

Behavior then comes from roughly:

> **personality + values + relationships + memories + current circumstances**

rather than a fixed archetype.

## Formative experiences

Life events modify people, but not through simplistic rules.

Bad:

> father died young → distrusts men +20

Better:

The event interacts with:

- age
- personality
- relationship with father
- behavior of surviving family
- existing fears/values

The same event can affect different children differently.

One might become:

- more anxious

another:

- extremely self-reliant

another:

- guilty

another:

- more attached to family

This gives generational history real consequences.

## Psychological knowledge is incomplete

The player does not automatically know everyone's personality.

Knowledge increases through:

- living together
- conversations
- shared work
- conflict
- crises
- observing behavior
- talking to other relatives

A person's psychology screen might show:

```text
Known:
✓ strongly values independence
✓ close to mother
✓ dislikes confrontation

Suspected:
~ wants recognition
~ uncomfortable with dependence

Unknown:
? attitude toward marriage
? attitude toward money
```

The player may sometimes be wrong.

For example:

> You thought Carlo was lazy.

After interacting with him more:

> You discover he is ambitious but hates working under you.

This is intentional.

The player's model of the person is imperfect.

## Psychology screen

Each character gets a screen showing your current understanding of them.

Possible sections:

### Personality
- reserved
- stubborn
- risk-taking
- conscientious

### Values
- independence
- family
- status
- money
- achievement

### Formative experiences
- father died young
- raised younger sibling
- failed engagement
- family bankruptcy

### Observed patterns
- avoids depending on others
- responds badly to threats
- tends to keep grudges
- seeks approval from older relatives

### Evidence
- refused financial help twice
- moved out early
- defended younger sibling
- left previous job after conflict

The screen is not a clinical diagnosis.

It represents:

> **what your current character thinks they understand about this person.**

## Personality affects communication style

Two people with the same desire may behave very differently.

One says:

> “I'm leaving.”

Another says:

> “Maybe I'll think about staying.”

but quietly prepares to leave.

A conflict-avoidant person may say yes while intending no.

A blunt person may openly refuse.

This means the player needs to learn **how each person communicates**, not just their goals.

## Roles and responsibilities

Psychology has practical importance because you assign people roles.

Long-term roles might include:

- family treasurer
- business manager
- caregiver
- household manager
- heir/successor
- mentor
- family representative
- property manager

Short-term tasks could include:

- negotiate with the bank
- organize a wedding
- repair the house
- care for a sick relative
- resolve a dispute
- deal with paperwork
- help a child with education

Characters may accept or refuse roles.

And a psychologically suitable person may still suffer from the responsibility.

Example:

Anna is loyal and caring, so she becomes grandmother's caregiver.

Three years later:

- her education has stalled
- she resents her siblings
- she feels trapped

So even a “good assignment” can create future problems.

## Decisions should create trade-offs

Balance should mostly come from conflicting goals rather than arbitrary difficulty.

Examples:

More children:

```text
+ heirs
+ workforce
+ larger family network

- costs
- overcrowding
- inheritance fragmentation
- sibling conflicts
```

Education:

```text
+ future opportunity
+ prestige/income

- current expense
- child may move away
- delays earning income
```

Keeping children home:

```text
+ family continuity
+ help with business/house

- resentment
- reduced independence
- possible future estrangement
```

A good solution should usually create another pressure.

## Money/economy

Money is important but shouldn't be the entire game.

Sources:

- salaries
- businesses
- property
- investments
- inheritance

Sinks:

- living expenses
- education
- maintenance
- health
- weddings
- renovations
- taxes
- inheritance buyouts
- business investment
- emergencies

Costs should evolve with family success instead of just scaling everything linearly.

Money should matter differently in different periods.

## Balancing

Useful balancing principles we discussed:

- avoid dominant strategies
- use diminishing returns
- make growth create new problems
- use positive and negative feedback loops
- allow recovery from mistakes
- major choices should have contextual advantages/disadvantages
- uncertainty should mostly come from imperfect knowledge rather than pure RNG

We can run large numbers of simulations automatically to inspect:

- family survival
- wealth distribution
- number of descendants
- business survival
- ownership fragmentation
- success rates of different strategies

Because the simulation can be separated from the UI.

## UI

The main screen probably shouldn't be a literal animated house.

Instead:

### Main Family Screen
Large portraits of the important people currently around you.

Show:

- immediate household
- other branch living in the house
- important concerns
- current intentions
- major warnings

Characters leaving the household disappear from the main group, making departures visually meaningful.

### Person Screen
Deep character/psychology information.

### House Screen
- ownership
- rooms
- capacity
- condition
- renovations
- claims
- shared spaces

### Family Tree
Generational overview.

### Finances
- income
- expenses
- assets
- debt
- business
- inheritance

Charts belong here rather than dominating the main UI.

### Chronicle
Meaningful family history:

> 1947 — Carlo announced plans to leave.

> 1948 — Giovanni convinced him to stay.

> 1953 — Carlo left anyway.

The chronicle allows the player to understand why the family became what it is.

## Visual style

Artwork is needed eventually, but not at first.

The game should avoid expensive full 3D Sims-style production.

Likely visual direction:

- illustrated portraits
- strategy UI
- simple stylized house diagrams
- generational portrait changes
- procedural portrait system

Potentially use reusable portrait parts:

- face shape
- eyes
- nose
- mouth
- hair
- clothing
- aging details

This would allow visible genetic resemblance across generations.

AI could help with:

- concept art
- exploration of visual styles
- furniture references
- portrait component ideation

But the prototype should initially use placeholders.

## Technology

Current recommendation:

> **Godot + C#**

Not because C++ is wrong, but because C# should let us iterate faster on the actual game systems.

The simulation should be engine-independent:

```text
Simulation/
    Person
    Family
    Household
    Relationship
    Economy
    DecisionSystem
    Succession
    Time

Godot/
    UI
    Screens
    Portraits
    Input
    Rendering
```

No web backend is necessary.

No PostgreSQL, Redis, APIs, RabbitMQ, etc.

Single-player state lives in memory and gets serialized into save files.

C++ remains a valid option if part of the project goal is specifically learning/building a simulation engine, but it isn't needed for expected performance.

## Development approach

Don't build the whole simulation first.

Build an **ugly vertical slice**.

First prototype:

- 5–8 family members
- parent/child relationships
- personalities
- basic values
- household membership
- money
- jobs
- monthly progression
- intention to leave
- player asks someone to stay
- acceptance/refusal
- resentment/relationship consequences

The first real test is something like:

> **Can we play ten years and care that our son wants to leave?**

If yes, add:

1. marriage
2. children
3. succession
4. siblings sharing the house
5. inheritance
6. roles/tasks
7. family objectives
8. deeper psychology
9. careers/business
10. historical context
11. art/polish

The most important idea we've reached is probably this:

> **It is a strategy game where other people are the territory you are trying to understand, not units you directly control.**

And the century-long dynasty provides the long-term consequences of how well—or badly—you understood them.
