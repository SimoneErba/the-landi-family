# Shared time and knowledge

The family head's beliefs are separate from what each relative has learned. Existing conversations can reveal authored findings or expressed goals. Regular contact now adds qualitative observations of temperament, values and learned habits; calendar time without contact reveals nothing.

Living in Landi House builds familiarity slowly. Adults working on the family farm also observe one another at work. A shared job title outside that farm does not count as a shared workplace. Travellers and departed or deceased relatives are excluded from contact at home.

Open a person's **Activities & responsibilities → Time together** to choose a companion and either household work or social time. Each participant can have one shared-time plan. Both must agree; refusals start no plan. Requests use the normal monthly person-request limit. Social time is available from age six, while household work requires adults. Only a parent can arrange a child's time. Both participants must be residents; social time fits alongside everyday jobs and schooling, while household work yields to courses, family activities and business management.

Plans last three equivalent months. Repeated interaction first produces a suspicion, then a known observation, supported by dated evidence. Both participants learn independently. Learning about your partner does not grant the head access to their private beliefs. Reluctant participation takes longer and builds stress/resentment; overwhelmed relatives can stop. Illness and family care interrupt shared time, and departure or death cancels it. Completing household work restores three points of house condition. These are light household chores, rather than paid construction or professional work. There is no extra cash reward or monthly activity fee.

Open another relative's **Requests & influence → Ask about another relative**, choose a subject, and ask what they know. A willing speaker shares one novel belief they actually hold. A distrustful or resentful speaker may refuse. The report appears as a **suspicion**, with the speaker named in the subject's evidence. Even a confident report is not automatically the head's firsthand knowledge; direct experience can later confirm matching findings. Speakers can be asked once per head per month, including unsuccessful requests. Reports can concern a relative who lives elsewhere, provided the speaker is home.

Contact evidence is qualitative and does not display numeric psychology, exposure counters or agreement scores. Different contexts reveal different characteristics. This slice uses regular household contact, farm work and player-arranged pairs; it does not yet schedule a whole village's autonomous social calendar.

`Simulation/SocialLife.gd` owns contact, plans and reports. `Scripts/PersonSocialLife.gd` renders the controls in existing profiles. Plans, observations, sources and report cooldowns survive saves and succession. Older saves start with no shared-time plans. The `child` starting option retains its existing command-line key but now creates both parents and Carlo; earlier simulation reports using that key describe the previous two-person start.

Run `Tests/SocialLifeTest.gd`, `Tests/MainMenuTest.gd`, `Tests/PersonProfileTest.gd`, `Tests/SaveGameTest.gd` and `Tests/SimulationRunnerTest.gd` for integration checks.
