"""Build the authored event catalog. Run from the project root after editing stories."""
import json
from pathlib import Path

# Each line is a distinct situation, rather than a title assembled at runtime.
STORIES = {
'family_requests': '''Boots for the winter|{person} shows you boots patched so often that water now reaches their socks.
A cart fare|{person} wants to visit a relative in another town and asks for the fare.
A private savings purse|{person} asks for a small sum they can manage without explaining every purchase.
Tools of their own|{person} wants a personal set of tools instead of borrowing from the family shop.
A birthday promise|{person} reminds you of a birthday gift promised during a difficult year.
A friend's urgent loan|{person} wants to help a friend who has fallen behind on rent.
Clothes for an interview|{person} has an interview coming up and worries about arriving in worn clothes.
A letter from abroad|{person} asks for postage and document fees to contact relatives overseas.
A pair of walking shoes|{person} wants sturdy shoes for the long walk to the fields and village market.
An unpaid personal bill|{person} admits that a personal bill has been hidden in a drawer for weeks.
A wedding contribution|{person} wants the family to contribute to a close friend's wedding.
Money without questions|{person} asks for financial help but is uncomfortable explaining the reason.''',
'education': '''The evening school|{person} has found an evening school and brings home its prospectus for {course}.
A tutor's recommendation|A tutor believes {person} could go further with {course}, if the family can support it.
The examination fee|{person} has been preparing for {course} and asks you to cover the next step.
A place left vacant|Someone has withdrawn from {course}; {person} hopes to take the place.
Books beyond the syllabus|{person} has been reading borrowed books and wants structured teaching in {course}.
A teacher's letter|A teacher writes that {person} should not let the chance to study {course} slip away.
Study instead of wages|{person} asks to sacrifice current earnings for a course in {course}.
A second chance at school|{person} regrets leaving school and wants to begin {course}.
An apprenticeship classroom|{person} wants formal instruction in {course} alongside practical ambitions.
A difficult entrance test|{person} has identified {course} as a way to prepare for more demanding work.
The younger branch's ambitions|{person} hopes {course} will open a future beyond the branch's present work.
A quiet application|{person} has investigated {course} without telling you and now asks for support.''',
'work': '''A supplier's introduction|{person} could meet a supplier who might open doors into independent work.
An unfamiliar machine|{person} wants time to learn a machine that local employers are starting to use.
The account books|{person} asks to learn bookkeeping rather than remain on routine errands.
A market stall trial|{person} wants to try selling at the market for a few mornings.
A place in a workshop|{person} has been invited to observe a workshop and wants help with travel and tools.
A customer with connections|A customer offers to introduce {person} to people in a different trade.
A design portfolio|{person} wants materials to assemble a portfolio for prospective employers.
A public speaking invitation|{person} has an opportunity to speak at a trade meeting but lacks confidence.
A difficult commission|{person} could take on an unfamiliar task that would stretch their abilities.
A reference letter|{person} asks you to help obtain references for a more independent career.
A business partner's visit|An acquaintance wants to discuss a small venture with {person}.
A wage negotiation|{person} wants preparation and support before discussing their wages.''',
'privacy': '''The crowded bedroom|{person} says there is nowhere in the house to be alone.
A desk by the window|{person} asks for a workspace where letters and books will not be disturbed.
A lock on a cupboard|{person} wants somewhere private to keep personal belongings.
Visitors after supper|{person} wants to receive friends without the entire household listening.
The noisy staircase|{person} cannot rest while everyone passes their sleeping place.
A room for examinations|{person} asks for a quiet corner while preparing for examinations.
Two branches at one table|{person} feels that their branch never gets time apart from the others.
An independent key|{person} wants a house key and freedom to come and go without explanations.
A curtain across the room|{person} proposes a modest screen to divide the shared sleeping space.
Personal letters opened|{person} complains that someone has been reading their letters.
The return of a guest|{person} asks that an extended visitor stop using their usual sleeping place.
A corner of the attic|{person} wants to make the attic into a private retreat.''',
'care': '''The caregiver's tired hands|{person} admits that daily care and household work have become exhausting.
A missed day of work|{person} asks for help after caregiving caused them to miss paid work.
An elder's appointment|{person} cannot manage an older relative's appointment alone.
A night without sleep|{person} has spent several nights watching over someone else.
A child needs supervision|{person} asks the household to share responsibility for a younger relative.
The laundry backlog|{person} feels trapped by chores that never seem to end.
The family meal burden|{person} asks for help preparing meals for both branches.
A letter left unanswered|{person} has been too overwhelmed by responsibilities to maintain friendships.
A day outside the house|{person} wants one day away from caring for everyone else.
Care during a busy season|{person} cannot keep up with household needs while work is busy.
A sibling does not help|{person} asks you to address an unfair division of care work.
The promise of a break|{person} reminds you that relief from their responsibilities was promised months ago.''',
'conflict': '''The borrowed heirloom|{person} is angry that a keepsake was lent without asking.
An insult at breakfast|{person} says a remark about their branch should not go unanswered.
The missing invitation|{person} believes they were deliberately excluded from a family gathering.
A promise disputed|Two relatives remember your old promise differently, and {person} wants an answer.
The cost of a celebration|{person} objects to the household paying for another branch's celebration.
A comparison between siblings|{person} is tired of being compared with a more successful sibling.
Advice from an uncle|{person} has heard advice that contradicts your plans for them.
The shop's credit ledger|{person} accuses another relative of receiving preferential treatment.
A guest takes sides|An extended visitor has encouraged {person} in an existing family dispute.
The family keepsakes|{person} notices that their branch has no keepsakes displayed beside those of the other branch.
A harsh word remembered|{person} brings up a remark you thought had been forgotten.
The family name in public|{person} has argued with a relative in public and wants you to intervene.''',
'repairs': '''Tiles after a windstorm|Several roof tiles have slipped, leaving the rafters exposed.
A dripping kitchen ceiling|Water now drips into the kitchen whenever it rains.
The sticking front door|The front door no longer closes properly and scrapes its frame.
A cracked chimney liner|A mason finds cracks inside the chimney and recommends repairs.
The loose staircase rail|The stair rail shifts when anyone puts weight on it.
The washroom drain|Waste water is backing up near the outdoor washroom.
A rotten window sill|The bedroom window sill is soft with rot beneath the paint.
The pantry wall|A widening crack runs across the pantry wall.
The cellar's damp floor|Water seeps through the cellar floor and spoils stored goods.
The courtyard paving|Uneven paving in the courtyard has become a tripping hazard.
A failing gutter|The gutter has pulled away from the house and dumps water onto the wall.
The kitchen flue|Smoke no longer draws properly through the kitchen flue.''',
'accidents': '''A candle overturns|A candle falls onto a cloth before anyone notices the flame.
A burst water vessel|A heavy water vessel breaks and floods the lower floor.
The stove sparks|Sparks from the stove scorch a section of the kitchen wall.
A cart hits the gate|A delivery cart strikes the gate and damages its hinges.
A tree limb falls|A fallen branch tears part of the roof covering.
The cellar shelf collapses|A loaded shelf collapses, damaging its contents and the wall behind it.
A cooking fire|An unattended pan catches fire and fills the kitchen with smoke.
The plaster gives way|A section of ceiling plaster falls during the night.
A lamp breaks on the stairs|A broken lamp leaves scorched wood and glass across the stairs.
Rain through an open hatch|An attic hatch left open lets a storm soak the upper room.
A delivery spills|A delivery of fuel spills and damages the courtyard entrance.
An overturned wash boiler|A wash boiler tips over and damages the washroom floor.''',
'expansion': '''The adjoining strip of land|A neighbor offers a narrow strip of land beside the house.
An attic conversion|A builder says the attic could become another sleeping room.
The courtyard annex|A small annex could fit beside the courtyard without blocking the gate.
A second bedroom|A mason offers a price for dividing and extending the upper floor.
An indoor washroom|A plumber proposes bringing washing facilities inside the house.
A covered workshop|Unused space behind the kitchen could shelter a workshop.
A room above the store|The space above the store is available for conversion into a family room.
A kitchen extension|A builder can extend the kitchen while working on a neighboring property.
A sheltered nursery|A sunny corner could be converted into a room for young children.
A study room|The family could add a shared study with a door that closes.
The garden cottage|A disused garden structure could be rebuilt as another living space.
A guest room offer|A local builder has surplus materials suitable for a modest guest room.''',
'maintenance': '''A winter fuel bargain|A fuel merchant offers a discount for ordering before winter.
The kitchen's worn utensils|Cooking has become harder with damaged utensils and a failing work surface.
Better window shutters|New shutters could make the shared rooms easier to keep warm.
A clean water filter|A supplier offers a household filter and instruction in its upkeep.
The bedding wears thin|Several bed covers are beyond another repair.
A stronger front lock|A locksmith recommends replacing the worn front-door lock.
A pantry improvement|Better shelves and sealed containers could reduce spoiled provisions.
The washroom screen|The outdoor washroom needs a new privacy screen.
A stove refurbishment|A stove fitter offers to refurbish the old stove before it fails.
An insect problem|Insects have settled into a damp corner of the kitchen.
The house's faded walls|Paint and plaster are peeling in rooms where both branches receive guests.
A courtyard drain cover|A safer cover would keep rubbish out of the courtyard drain.''',
'robbery': '''The empty till|The shop till has been opened and part of the cash is missing.
A forced pantry door|Someone has forced the pantry door and taken household provisions.
The purse on the tram|A household purse disappears during a crowded journey.
The stolen delivery|Goods paid for by the family never arrive, and the carrier cannot explain why.
A lock picked at night|The front lock shows signs of tampering and valuables are gone.
A forged collection notice|A visitor collects money using a convincing but false notice.
The missing silver|A small piece of family silver disappears after a busy gathering.
A break-in at the store|Someone enters the store after closing and takes cash from the office.
The dishonest repairman|A repairman takes an advance payment and cannot be found.
The courtyard thief|A thief takes goods left briefly in the courtyard.
A stolen travel bag|A relative's bag is taken with money entrusted by the household.
The false supplier|An unfamiliar supplier accepts payment and delivers worthless goods.''',
'illness': '''A fever after supper|{person} develops a fever and struggles to keep up with ordinary work.
A cough that lingers|{person} has been coughing for weeks and now needs rest.
A stomach complaint|{person} cannot keep food down and feels increasingly weak.
An infected cut|A small cut on {person}'s hand has become swollen and painful.
A painful tooth|{person} has trouble eating and sleeping because of a painful tooth.
An aching back|{person} can no longer carry out their usual work comfortably.
A winter chest illness|{person} becomes ill during cold weather and needs care at home.
A bout of exhaustion|{person} has worked through fatigue until they can barely get out of bed.
A household rash|{person} develops an irritating rash and worries about passing it on.
A sprained ankle|{person} twists an ankle and cannot travel to work easily.
A recurring headache|{person} has headaches severe enough to interrupt normal responsibilities.
A summer fever|{person} falls ill during hot weather and needs someone to watch over them.''',
'drought': '''The rain does not come|Fields around the village dry out while households begin conserving water.
The well runs low|The local well yields less water each day.
A thirsty kitchen garden|Gardens that supplement household meals are drying out.
Water carts in the square|Water is now being sold from carts at a price the family never used to pay.
The dust on the roads|Dry roads slow deliveries and the cost of provisions begins to rise.
A failed planting season|Farmers report that seed has failed to take in the dry ground.
Rationed washing water|The neighborhood asks households to reduce water used for washing.
A dry reservoir|A local reservoir is falling and restrictions are expected.
The cracked orchard soil|Fruit growers are cutting their expected harvests.
Livestock sold early|Farmers sell animals early because there is not enough water or fodder.
A dry summer market|The market has fewer fresh goods and sharply higher asking prices.
Waiting for the storm|A long dry spell forces households to pay more for food and water.''',
'famine': '''The grain stalls are bare|Grain merchants cannot replace the sacks they sold last week.
A failed regional harvest|A poor harvest has turned into a regional shortage of staple foods.
Bread queues before dawn|People queue before sunrise, unsure whether bread will reach them.
The ration notice|A notice limits the quantity of staple foods each household may buy.
An expensive sack of flour|The price of flour climbs beyond what poorer branches can afford.
The soup kitchen opens|A neighborhood relief kitchen opens for households without enough food.
Seeds kept for eating|Farmers are eating grain they would normally keep for planting.
An empty grain cart|An expected shipment of food arrives with very little to distribute.
A winter without reserves|Regional stores are running out before winter has ended.
A hungry visitor|A traveler describes villages where food cannot be bought at any price.
Market sellers withdraw|Several food sellers close their stalls rather than sell below replacement cost.
The last household staples|A prolonged shortage forces the family to decide how to protect its meals.''',
'war': '''Mobilization notices|Regional mobilization disrupts deliveries and puts families on edge.
A road reserved for troops|Civilian carts are delayed while military traffic takes priority.
The border closes|A neighboring border closes and trade routes become unreliable.
A night of distant guns|Reports of fighting nearby unsettle the town and interrupt ordinary business.
The requisition office|An office begins requesting supplies from local households and businesses.
A military checkpoint|A checkpoint slows customers, workers, and deliveries entering the district.
Refugees on the road|People fleeing fighting pass through the village while the local economy strains.
A missing postal route|Letters and payments from outside the district stop arriving reliably.
The wartime price notice|Merchants warn that disrupted supply routes will raise their prices.
The curfew announcement|A curfew cuts evening trade and changes household routines.
A workshop changes contracts|Local artisans shift to military orders, interrupting ordinary commerce.
The uncertain armistice|Fighting may ease, but disrupted wages and food supplies continue.''',
'trade': '''A large customer order|A customer offers a larger order than the family normally handles.
A surplus shipment|A supplier has surplus goods available at a favorable price.
A stall at the fair|The family is offered a selling place at an upcoming fair.
A new delivery route|A carrier offers access to customers the family has not reached before.
An early-payment discount|A supplier offers a discount in return for immediate payment.
A seasonal demand|Demand for a familiar product rises just as the family considers buying stock.
The visiting merchant|A traveling merchant offers a small trial arrangement.
A neighbor closes a shop|A neighboring trader is selling useful stock while closing their business.
A repair contract|A local organization needs reliable workers for a modest contract.
A bulk purchase|Several neighbors want to combine their orders through the family.
A display in the square|The family could pay for a display in a busy public square.
An export inquiry|An inquiry from another town offers a chance to broaden trade.''',
'community': '''The neighborhood relief fund|Neighbors ask the family to contribute to a relief fund.
A school roof appeal|A local school needs help repairing its roof before lessons resume.
A communal well repair|Several streets are collecting money to restore a shared well.
A displaced household|A nearby household needs temporary help after losing its lodgings.
The public reading room|A community reading room asks for support to stay open.
A neighbor's funeral|Neighbors ask for help with funeral expenses for someone without savings.
A workers' collection|Workers collect aid for families affected by a stoppage.
A medical visitor fund|The district wants to bring a medical visitor to households that cannot travel.
A festival volunteer|Organizers ask the family to help put on a neighborhood gathering.
The muddy village lane|Residents want to repair the lane connecting the farms to the village market.
A charitable sale|The family is invited to contribute goods to a charitable sale.
The shared bread oven|Neighbors propose repairing a bread oven used by poorer households.''',
'inheritance': '''A small bequest|A solicitor sends notice of a modest bequest left to the family.
An old debt repaid|A distant relative's estate includes repayment of an old family loan.
The disputed keepsake|A parcel arrives with a keepsake whose intended owner is unclear.
A property document|A neglected document may establish a small claim, if the family pays to investigate.
The executor's expenses|An executor offers to settle a modest inheritance if the family covers paperwork.
An absent cousin's share|An absent cousin proposes selling a minor claim to simplify their affairs.
A trunk from another branch|A trunk of saleable belongings arrives from another branch's estate.
An unclaimed deposit|A clerk finds an old deposit registered under the family name.
The last workshop tools|A retired relative offers their remaining workshop tools to the household.
A legacy with conditions|A small legacy asks the family to contribute part of it to a public cause.
The boundary agreement|A relative proposes settling a minor property dispute for a fixed payment.
An estate auction invitation|The family can buy useful household goods before an estate auction opens.''',
'celebration': '''An anniversary meal|{person} hopes the family will mark an anniversary with a proper meal.
The first paid commission|{person} wants to celebrate completing a first significant commission.
A relative returns for a visit|{person} asks you to welcome a visiting relative warmly.
A family photograph|{person} wants a photograph while both branches are together.
A music evening|{person} proposes an evening of music and asks for a small allowance.
A name remembered|{person} wants to mark the birthday of a departed relative.
The branch's good news|{person} wants the household to recognize a success in their branch.
A picnic in the olive grove|{person} suggests a day in the olive grove to ease recent tensions.
A meal for old friends|{person} asks to invite old friends to the family table.
A holiday gathering|{person} wants to make the next holiday feel different from an ordinary day.
An engagement elsewhere|{person} brings news of a friend's engagement and wants to send a gift.
A quiet family reunion|{person} hopes a small gathering will bring distant relatives back into contact.''',
'discovery': '''Coins beneath a floorboard|During cleaning, someone finds a small packet of old coins.
The forgotten storage box|A storage box contains household goods that may still be useful.
A valuable old book|An old book catches the attention of a visiting bookseller.
A hidden roof problem|An inspection uncovers damage that had been concealed behind sound plaster.
The useful salvage pile|A neighbor offers leftover materials from demolition work.
An old family recipe|A handwritten recipe suggests a small commercial possibility.
A map of the cellar|A forgotten plan shows where the cellar might be improved.
The dusty instrument|An unused instrument could be repaired or sold.
A supplier's ledger note|An old ledger records credit the family never collected.
Letters in the attic|Letters reveal an unresolved quarrel between earlier generations.
A forgotten garden patch|The family discovers an unused patch with room for a small improvement.
The spare household fittings|Stored fittings could be sold or used to improve the house.''',
'pregnancy': '''News after breakfast|{person} tells the household that they are expecting a child.
A private confidence|{person} shares news of a pregnancy and asks for discretion.
A growing family|{person} and their partner expect a child and begin discussing space in the house.
The unfinished cradle|{person} brings pregnancy news while an old cradle still needs repair.
A letter to the grandparents|{person} wants help sharing pregnancy news with older relatives.
Another place at the table|{person} is expecting a child and worries about the household budget.
The nursery question|{person} asks how the household will make room for an expected baby.
News during a busy month|{person} announces a pregnancy just as family responsibilities increase.
The midwife's visit|{person} confirms a pregnancy after speaking with a local midwife.
A hopeful announcement|{person} shares pregnancy news after a long period of uncertainty.
The work-and-care question|{person} asks how paid work and care will be managed when the baby arrives.
A branch prepares for a baby|{person}'s branch is expecting a child and asks the household for support.'''
}

def option(label, result, **effects):
    return {'label': label, 'result': result, 'effects': effects}

STORIES['rural'] = """The olive harvest|The olives are ready, but both family branches want to decide who picks, who presses, and who takes the oil to market.
A damaged vineyard wall|A dry-stone wall beside the vines has collapsed, leaving the terrace exposed before the next rain.
The fattore's visit|The steward of a neighboring estate asks whether the Landis can lend hands at harvest, just as their own fields need attention.
The sowing grain|A neighbor offers seed grain for the coming season, but buying it means less money for the household.
The ox needs rest|The family's working ox is limping, and the ploughing will take longer without it.
Wine for the village market|A buyer from the village asks for more wine than the household normally sets aside for sale.
A disputed irrigation ditch|Two farming households disagree over clearing the ditch that brings water to their plots.
The chestnut gathering|Relatives want to gather chestnuts in the hills, but someone must remain home to finish the daily work.
A leaking oil jar|An oil jar has cracked in the storeroom, threatening provisions the household counted on for winter.
The threshing day|Threshing needs several pairs of hands at once; each branch believes the other should contribute more.
The parish appeal|The parish asks for food and labor to help a struggling rural household through the season.
A market day in Florence|A carrier offers space for the family's produce on a cart to Florence, reopening Carlo's hopes of a life beyond the podere."""

catalog=[]
for category, stories in STORIES.items():
    for i, line in enumerate(stories.splitlines()):
        title, body=line.split('|',1)
        cost=(20+i*5)*100
        damage=6+i%5
        event={'id':f'{category}_{i+1:02d}', 'category':category, 'title':title, 'body':body,
               'weight':0.15 if category=='war' else 0.35 if category in ('pregnancy','famine') else 1.0,
               'cooldown_months':60, 'conditions':{}, 'on_trigger':{}, 'choices':[]}
        conditions=event['conditions']
        if category in ('family_requests','education','work','privacy','care','conflict','celebration'):
            conditions.update(target='relative', min_age=18)
        if category=='education': conditions.update(needs_program=True, min_age=6, value='achievement', min_value=.6)
        if category=='work':conditions.update(value='achievement',min_value=.6)
        if category=='privacy':conditions.update(value='independence', min_value=.65)
        if category=='care':conditions.update(min_stress=.3)
        if category in ('drought','famine'):conditions['months']=[5,6,7,8,9] if category=='drought' else list(range(1,13))
        if category=='war':conditions.update(wartime_only=True)
        if category=='illness': conditions.update(target='healthy',min_age=1)
        if category=='pregnancy':conditions.update(target='pregnancy',min_age=18,max_age=45)
        if category=='expansion':conditions.update(max_capacity=20)
        if category=='celebration' and i==3: conditions.update(min_year=1860)
        if category=='rural' and i==0: conditions['months']=[10,11,12]
        if category=='rural' and i==9: conditions['months']=[6,7,8]
        if category in ('repairs','accidents'):
            event['on_trigger']={'condition':-damage}
            choices=[option('Arrange proper repairs', 'The damage is repaired, at a cost to the shared purse.', cash=-cost, condition=damage),
                     option('Patch it with family labor', 'The patch restores part of the damage, but strains the household.', condition=damage//2, household_stress=.035),
                     option('Leave it for now', 'The damage remains and the household feels less secure.', household_stress=.05)]
        elif category=='expansion':
            room=['Garden extension','Attic bedroom','Courtyard annex','Second bedroom','Indoor washroom','Workshop','Upper room','Kitchen extension','Nursery','Study','Garden cottage','Guest room'][i]
            choices=[option('Buy materials and build', 'The household gains a new space and more capacity.',cash=-cost*6, room=room, capacity=2, condition=3),
                     option('Make a smaller improvement', 'A modest improvement makes the house more comfortable.',cash=-cost,condition=5,household_happiness=.02),
                     option('Keep the money in reserve','The opportunity passes; the shared purse is preserved.')]
        elif category=='maintenance':
            choices=[option('Pay for the improvement','The house is more comfortable and better maintained.',cash=-cost,condition=5,household_happiness=.025),
                     option('Use what the family already has','A makeshift improvement helps, but adds work.',condition=2,household_stress=.02),
                     option('Postpone it','The household lives with the inconvenience.',household_stress=.015)]
        elif category=='robbery':
            event['on_trigger']={'cash_loss':cost, 'household_stress':.06}
            choices=[option('Replace the loss and improve security','Better locks help the household feel safer, though the stolen money is gone.',cash=-cost//2,condition=2,household_stress=-.025),
                     option('Neighbors help watch the house','Shared vigilance eases some anxiety but requires effort.',household_stress=-.01),
                     option('Absorb the loss quietly','The theft is left unresolved.',household_stress=.025)]
        elif category=='illness':
            event['on_trigger']={'illness_months':2+i%4,'stress':.1}
            choices=[option('Pay for care and time to rest','Care shortens the illness and reassures the patient.',cash=-cost, shorten_illness=2,stress=-.06,trust=.03),
                     option('Care for them at home','Family care helps, but the household shares the burden.',shorten_illness=1,household_stress=.03,trust=.02),
                     option('Provide only basic rest','Recovery takes its course without extra expenditure.',stress=.03)]
        elif category in ('drought','famine','war'):
            duration=3+i%4 if category!='war' else 6+i%7
            food=1.2+i%4*.1 if category!='famine' else 1.5+i%4*.15
            income=.8 if category=='war' else 1.0
            event['on_trigger']={'crisis':{'kind':category,'months':duration,'food_multiplier':food,'income_multiplier':income},'household_stress':.08}
            choices=[option('Spend on a household relief reserve','The reserve eases the price shock for the duration of this crisis.',cash=-cost*2,relief=.15,household_stress=-.03),
                     option('Organize mutual help','The family shares the burden without buying a reserve.',household_stress=-.025,household_happiness=-.015),
                     option('Keep the purse intact','The family faces the disruption with its existing resources.',household_stress=.035)]
        elif category=='education':
            choices=[option('Fund the requested course','Their chosen full-time course begins; wages stop and monthly tuition will be charged.',study=True,trust=.04,happiness=.05),
                     option('Help with books for now','Books support informal learning without enrolling them.',cash=-cost//2,skill='literacy',skill_gain=2,trust=.01),
                     option('Ask them to postpone','The course is postponed, and they feel their ambition has been put aside.',resentment=.05)]
        elif category=='work':
            skill=['commerce','technical','accounting','commerce','craft','persuasion','design','persuasion','technical','literacy','leadership','persuasion'][i]
            choices=[option('Back their initiative','Support helps them develop practical ability and independence.',cash=-cost,skill=skill,skill_gain=4,trust=.025,stay_release=True),
                     option('Encourage a smaller trial','A cautious trial develops some ability without using household funds.',skill=skill,skill_gain=1,stress=.025),
                     option('Ask them to focus on current duties','They keep their current work, but resent the lost opportunity.',resentment=.05)]
        elif category=='privacy':
            choices=[option('Pay to make a private space','A rearrangement respects their need for privacy.',cash=-cost,happiness=.05,resentment=-.04,trust=.03),
                     option('Agree on new household boundaries','New boundaries improve trust, though shared space remains limited.',trust=.02,resentment=-.015),
                     option('Insist on the existing arrangement','The arrangement remains and they feel unheard.',resentment=.07)]
        elif category=='care':
            choices=[option('Pay for temporary help','The relative gets meaningful relief from their responsibilities.',cash=-cost,stress=-.15,trust=.04),
                     option('Share the work between residents','Their burden falls, while the rest of the household takes on more.',stress=-.08,household_stress=.02),
                     option('Ask them to manage a little longer','They continue carrying the burden and remember being dismissed.',stress=.07,resentment=.06)]
        elif category=='conflict':
            choices=[option('Make time for a family discussion','The discussion improves trust but brings tensions into the open.',trust=.04,resentment=-.03,household_stress=.02),
                     option('Offer a practical compromise','A small concession eases the immediate grievance.',cash=-cost//2,resentment=-.04),
                     option('Close the discussion','The immediate argument ends, but the grievance deepens.',resentment=.08,trust=-.04)]
        elif category in ('celebration','family_requests'):
            choices=[option('Support the request','They feel their wishes have a place in family decisions.',cash=-cost,happiness=.06,trust=.03),
                     option('Offer a modest contribution','A smaller contribution recognizes the request.',cash=-cost//3,happiness=.02,trust=.01),
                     option('Decline for now','The family keeps the money, but the disappointment remains.',resentment=.035)]
        elif category in ('community','rural'):
            choices=[option('Make a contribution','Helping the community lifts the household spirits.',cash=-cost,household_happiness=.04),
                     option('Offer family time instead','The family contributes effort rather than money.',household_happiness=.015,household_stress=.025),
                     option('Keep resources for the household','The family does not take part in this appeal.')]
        elif category=='trade':
            choices=[option('Finance the small arrangement','The arrangement ties up cash, then pays a modest return in three months.',cash=-cost,delayed_cash=cost+cost//3,delay_months=3),
                     option('Take a limited trial','A smaller trial returns less but exposes fewer resources.',cash=-cost//3,delayed_cash=cost//3+cost//8,delay_months=3),
                     option('Pass on the opportunity','The offer passes without changing the household finances.')]
        elif category=='inheritance':
            choices=[option('Pay to settle the paperwork','The claim is settled and the household receives its proceeds next month.',cash=-cost//4,delayed_cash=cost*2,delay_months=1),
                     option('Handle the paperwork within the family','The family receives a smaller settlement after a longer wait.',delayed_cash=cost,delay_months=4,household_stress=.03),
                     option('Let the claim go','The family leaves the matter unresolved.')]
        elif category=='discovery':
            choices=[option('Use the find to improve the house','The find becomes a modest household improvement.',cash=-cost//3,condition=4,household_happiness=.025),
                     option('Sell what can be sold','The household gains a small sum instead of retaining the find.',cash=cost//2),
                     option('Keep it as it is','The find stays with the family without further expenditure.',household_happiness=.01)]
        elif category=='pregnancy':
            event['on_trigger']={'pregnancy':True}
            choices=[option('Arrange care and baby supplies','The family prepares for the expected child and reassures the parent.',cash=-cost,stress=-.06,trust=.05),
                     option('Share preparations within the family','The family prepares with existing resources and shared effort.',stress=-.025,household_stress=.02),
                     option('Wait before spending','The pregnancy continues, but preparations are deferred.',stress=.035)]
        event['choices']=choices
        catalog.append(event)
for key,title,body in [('graduation','Graduation','{person} has completed {course}. A new chapter can begin.'),('birth','A new child in the family','{person} welcomes {child}. The household has another person to care for.'),('recovery','Recovery','{person} is well enough to resume ordinary life.')]:
    catalog.append({'id':key,'category':'milestone','title':title,'body':body,'weight':0,'cooldown_months':0,'conditions':{'automatic_only':True},'on_trigger':{},'choices':[option('Mark this in the family history','The family acknowledges this turning point.')]})
catalog.extend(json.loads(Path('Data/historical_events.json').read_text())['events'])
Path('Data/events.json').write_text(json.dumps({'schema_version':1,'events':catalog},ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(catalog)} events in {len(STORIES)} categories plus milestones')
