# Education and careers

The model separates eligibility, aptitude, and willingness. A relative may qualify for a career and refuse it; another may want it and need years of preparation.

## Person data

`education.level` is `none`, `primary`, `secondary`, `university`, or `advanced`. `education.qualifications` is an independent list: a carpentry apprenticeship does not count as university education. `education.study` holds the program, progress in equivalent study months, status, and monthly cost.

`abilities` contains reasoning, verbal ability, spatial ability, memory, and learning speed. These are fictional game attributes, not clinical measurements. Their average is available internally as `cognitive_index()`. Missing abilities default to 50; there are no job IQ cutoffs.

`skills` contains literacy, mathematics, technical work, commerce, accounting, persuasion, leadership, empathy, care, household management, craft, agriculture, cooking, art, design, medicine, law, science, teaching, and music. Missing skills default to zero. Practice and qualifications are distinct.

`interests` contains technical, commercial, artistic, academic, social, and practical interests. Missing interests default to 50. Temperament and values remain the existing 0–1 psychological attributes. Social competence is represented by persuasion, empathy, and leadership rather than a charisma score inferred from extraversion.

`career_knowledge` stores the ability, skill, and interest keys known by each observer. Views return qualitative bands, not numeric scores. Unobserved fields remain unknown; the head knows their own attributes. Course completion adds its taught skills to the head's observed knowledge. Education history and qualifications are treated as public in this slice.

`career_access` lists practical resources such as land, premises, equipment, capital, suppliers, instruments, or an institution. These are authored availability tags for now; they do not represent purchased assets or deduct investment costs.

## Occupation catalog

`Data/careers.json` contains 32 occupations grouped under Agriculture, Household, Industry, Trades, Commerce, Administration, Education and care, Professions, and Arts and communication.

Each occupation specifies an education level, optional qualification, minimum learned skills, resource requirements, a relevant interest, weighted cognitive abilities, helpful temperament traits, and a prototype wage.

`job_assessment()` checks adulthood, living status, education, qualification, skills, and access. It separately computes aptitude, performance potential, and interest for simulation use. Cognitive abilities and personality do not block employment. Performance potential does not yet change wages or generate workplace outcomes. The UI displays requirements and unavailable-request explanations without showing private acceptance scores.

## Training catalog and monthly flow

The 22 programs include schooling, four trade apprenticeships, technical and commercial training, accounting, teaching, nursing, engineering, architecture, medicine, law, surveying, research, art, music, agriculture, household work, and writing. They grant an education level and/or qualification and teach specified skills. Some have prior schooling or entry-skill requirements.

An accepted education request starts full-time study and removes earnings. An occupation request requires completion of current study. Courses already mastered or qualifications already held cannot be repeated. Training does not lower existing skills or education.

The month settles income, food, and tuition before advancing study. If available cash plus resident earnings minus food cannot cover all tuition, courses pause together without charging fees. Learning also pauses outside the household or after death. Tuition is fixed; food follows the existing inflation model.

Monthly progress combines program-relevant abilities and conscientiousness, moderated by stress. Lower aptitude still allows progress; sustained discipline helps. Skills approach course targets as study advances and meet the targets at completion. Graduation updates education and credentials, supplies observed evidence, records a memory and Chronicle entry, and pauses the clock. Graduates seek work rather than receiving an automatic job.

## Consent

Education and job requests share the household-request relationship model, monthly cooldown, refusal, reluctant compliance, and resentment consequences. Career interest, achievement, openness, stress, security, and wealth affect willingness. Low independence is not a blanket reason to reject college; this slice does not yet model moving away to attend a particular institution.

Education requests for children require the head to be their parent. Other-branch parental negotiation remains a future action. The head's own career is currently shown for inspection; self-directed changes are not exposed through requests.

## Prototype limits

The catalog is a fictional balance model, not a historical credential system, occupational aptitude test, or salary dataset. Vacancy competition, admission capacity, professional licensing beyond a qualification tag, acquired resource access, physical demands, course withdrawal, relocation, and employment experience growth remain future systems. Courses currently cannot be cancelled or switched midway through. Occupation acceptance assumes a placement is available and uses the catalog wage.
