# Beast cultivation: research and implementation proposal

## 1. Scope and evidence

**Recommendation:** rare animals awaken, then temper the same nine bodily foundations as people. Spirit/demonic is a path and behavior distinction, independent of species, layer, grade, and intelligence. Stop at Body Tempering equivalence: no human transformation, flight, ranged spells, or Golden Core realm.

Read against [wildlife research](wildlife_research.md), [species catalogue](species_catalogue.md), [curated animals](../data/wild/curated.json), [human body rules](../data/society/body.json), [combat rules](../data/society/combat.json), and [combat implementation](../src/combat.gd). All probabilities, thresholds, Chinese form names, lifespans, and balance values below are **proposed fiction/simulation parameters**, not ecological facts or historical cultivation doctrine. Sources were consulted on 2026-11-13.

### Older sources: what they actually support

| Source | Relevant tradition | Boundary for this design |
|---|---|---|
| [*Shan Hai Jing*, Southern Mountains](https://zh.wikisource.org/wiki/山海經/南山經), composite ancient geographical bestiary | Qingqiu's nine-tailed fox eats people; eating it averts a harmful influence. Other entries connect unusual animals, plants, minerals, and beneficial materials to named mountains. | Supports place-specific marvels and useful remains; supplies neither nine cultivation layers nor a universal beast-core economy. Its creatures need not be ordinary animals that trained. |
| Gan Bao, [*Soushen Ji*, vol. 18](https://zh.wikisource.org/wiki/搜神記/第18卷), fourth-century collection in its transmitted form | An ancient fox takes the form of a learned scholar; animal apparitions speak, disguise themselves, and interact with households. | Supports age, learning, and ambiguous encounters. Do not attribute the familiar 50/100/1,000-year fox ladder to this collection. |
| [*Xuanzhong Ji*, surviving collected fragments](https://zh.wikisource.org/wiki/玄中記), traditionally attributed to Guo Pu | Fox powers increase at fifty and one hundred years; a thousand-year fox communicates with heaven. | An early age-based progression motif, not zoology or a consistent modern realm system. |
| Ge Hong, [*Baopuzi*, Inner Chapters 3, “Responses to Common Views”](https://zh.wikisource.org/wiki/抱朴子/卷03), fourth century | Long-lived cranes and turtles; enduring snakes; monkeys changing with age; white old tigers, deer, and hares; old bears and fox/wolf relatives transforming. | Strong foundation for ancient, wise, unusually colored animals. These are longevity claims within a religious argument, not a standardized animal training manual. |
| [*Journey to the West*, ch. 1](https://zh.wikisource.org/wiki/西遊記/第001回), Ming fiction | The stone monkey develops through prolonged reception of terrestrial/celestial essence, including sun and moon; the mountain contains extraordinary flora and fauna. | Literary bridge to modern awakening imagery. A stone-born protagonist is an example, not a template to copy into every species. |
| [*Journey to the West*, ch. 2](https://zh.wikisource.org/wiki/西遊記/第002回) | Cultivation encounters destructive thunder, fire, and wind disasters. | Supports tribulation imagery; does not establish that being struck by lightning ordinarily awakens an animal. |
| [*Soushen Ji*, vol. 20](https://zh.wikisource.org/wiki/搜神記/第20卷) | Animals repay help; a person assists a tiger giving birth, and a rescued bird returns a gift. | Reciprocity can motivate trust and local reverence without magical ownership. |

These traditions overlap Daoist, Buddhist, local religious, and literary worlds; “Daoist lore” should not flatten them into one doctrine. White deer and cranes suggest longevity; snakes suggest transformation; monkeys suggest intelligence and learning; tigers combine formidable bodies with numinous associations. None establishes a moral division between herbivores and predators.

### Modern genre conventions

The publisher-hosted [*General Glossary of Terms in Wuxia, Xianxia & Xuanhuan Novels*](https://www.wuxiaworld.com/page/general-glossary-of-terms) documents the following broad vocabulary: wuxia emphasizes martial humans; xianxia includes immortality and Daoist-inspired supernatural cultivation; xuanhuan mixes fantasy traditions. Cultivating animals belong most naturally in the latter two. Beasts absorb spiritual energy, gain awareness, and often contain essence-bearing cores (妖核 *yaohe*, 魔核 *mohe*). 灵兽 *lingshou* and 妖兽 *yaoshou* can label substantially similar creatures. 妖 *yao* often denotes an anomalous transformed being; 魔 *mo* carries demonic/devilish associations, but translation varies. Cultivation uses realms, layers, bottlenecks, medicines, and tribulations. Consequently, neither “demonic beast” nor “spirit beast” guarantees an ethical alignment.

**Genre synthesis for adaptation, not a universal taxonomy:** numbered tiers or ranks (阶/级) commonly coexist with early/middle/late/peak subdivisions; other stories align beasts to human realms. Use **Beast Tempering / 炼体, layers 1–9**, plus the existing four quality grades. Avoid nine “ranks” that players could mistake for nine whole realms. “Beast king” should describe local dominance, not a tenth layer. A beast core is a material organ/condensation in this proposal, distinct from human Golden Core cultivation.

### Awakening motifs and safe adaptations

| Motif | Provenance/status | Valley interpretation |
|---|---|---|
| Qi-rich mountain, cave, spring | Ancient numinous geography; solar/lunar essence in *Journey*, ch. 1; spiritual-energy absorption in the modern glossary above | Sustained residence near a finite qi source, not a roll every frame. |
| Spirit herb or fruit | Magical vegetation in *Shan Hai Jing*; extraordinary fruit/flora in *Journey*, ch. 1 | Rare compatible food supplies an awakening catalyst; ordinary food still supplies calories. |
| Other beasts' cores | Modern core vocabulary above; consumption as a progression resource is an adaptation of that trope | Limited assimilation with incompatibility, poison, and injury risks; never an automatic layer. |
| Bloodline | Modern fantasy motif; no single classical universal rule | Inherited sensitivity modestly raises odds; offspring inherit neither layers nor guaranteed awakening. |
| Great age | *Baopuzi* and *Xuanzhong Ji* above | Surviving older animals receive a bounded sensitivity bonus; centuries require prior awakening. |
| Moonlight / sun essence | Explicit literary precedent in *Journey*, ch. 1 | Quiet, exposed resting sites permit slow uptake; night activity alone is insufficient. |
| Survived lightning, flood, fire, winter | Tribulation precedent in *Journey*, ch. 2; awakening-through-survival is a design extrapolation | One rare catalyst after actual survival and recovery; damage remains real. |
| Human blood, slaughter, accumulated resentment | Predatory monsters have ancient precedent; blood-powered advancement and corruption meters are modern-fantasy adaptations, not a rule from *Shan Hai Jing* | A dangerous alternative catalyst under corrupted qi; ordinary predation and self-defense do not prove evil. |

Taming, blood/soul contracts, beast hunting, and valuable remains are recurring modern fantasy devices, with widely varying mechanics. Here these become optional systems: establish trust before later negotiated bonds; distinguish coercion from friendship; make cores and materials useful but finite. The ancient material-benefit and reciprocal-animal stories above support the atmosphere, not modern contract specifications.

## 2. Nine layers of Beast Tempering

**Layer 0:** ordinary animal. Awakening grants persistent awareness and eligibility for layer 1; it need not finish Copper Skin immediately. Species anatomy remains recognizable. Fur, feathers, claws, horns, and scales are integument analogues, not reasons to skip a foundation.

The layer names below exactly follow `body.json`. Every layer needs accumulated work, adequate condition, a foundation exercise, and a compatible medicine/catalyst where indicated. Visible signs are probabilistic diagnostic cues, not guaranteed cosmetic replacements.

| Layer / human parallel | Beast bodily effect and natural drill | Visible signs | Minimum gate; baseline years in this layer before next | Lifespan multiplier at completion |
|---|---|---|---|---:|
| 1 Copper Skin | Tougher hide, footpads, feather roots; rubbing, cold exposure, repeated locomotion | Glossy coat, faint metallic hair tips; normal size | Qi shelter + habitual exertion; 1 y | 1.20× |
| 2 Dense Flesh | Denser muscle and soft tissues; climbs, carries, bounds, hunts or escapes | Fuller shoulders/haunches, unusually steady stance | Sustained feeding + varied exertion; 2 y | 1.45× |
| 3 Steel Sinew | Resilient tendons and ligaments; repeated controlled leaps and turns | Corded limbs; clean, unusually precise movement | Recognized instinctive exercise; 3 y | 1.80× |
| 4 Iron Bone | Reinforced skeleton, teeth, horn/antler bases; safe impact loading | Ivory-dark claws/horns, heavier tracks | Impact practice + mineral/iron-bark analogue; 4 y | 2.30× |
| 5 Jade Marrow | Restored marrow and slow deep repair; exertion alternating with long recovery | Pale inner sheen at horn bases; bright eyes | Refined practice + marrow medicine; 5 y | 3.00× |
| 6 Living Blood | Better circulation and exertion tolerance; extended travel, winter endurance | Warm breath in cold air, deeper coat color | Recovered hardship + blood/marrow tonic; 6 y | 4.00× |
| 7 Five Viscera | Better heart, lungs, digestion, detoxification; balanced feeding/breathing | Powerful but quiet breathing; clear gaze | Complete instinctive method + seven-leaf equivalent; 8 y | 5.00× |
| 8 Open Meridians | Stable internal qi channels; bodily regulation, no spellcasting | Fine markings glow briefly during exertion | Circulation practice + compatible spirit herb; 10 y | 6.50× |
| 9 Perfected Body | Integrated foundations and efficient recovery; complete movement/breath cycle | Distinctive mature markings, controlled close aura | All foundations integrated + rare catalyst; terminal stage | 8.00× |

Times are minimum work/recovery intervals at reliable qi access, not automatic promotions. They total **39 years from completed layer 1 to layer 9**; allow another ~1 year to finish layer 1. Scarcity, injury, missing gates, and deliberate polishing prolong them. Herbs/cores can improve accumulation within an interval but cannot erase it. Most awakened beasts should die, disperse, or stall at layers 1–3. Layer 9 is a regional legend, with no initial guaranteed resident.

**Size and appearance:** cap adult mass at `base_mass × (1 + 0.04 × layer)`, at most 1.36×; distribute growth across layers rather than making nine giant resizes. Pale coats, golden hairs, eye changes, and markings vary by lineage/path. Red eyes or white fur alone never identify corruption. Show aura only during stress or focused observation. No compulsory extra tails, antlers on females, or mammalian teeth on birds.

**Intelligence:** awakening improves memory and recognition; layers 1–3 learn hazards and particular people; 4–6 plan routes, guard resources, and understand repeated gestures; 7–9 can understand simple requests and bargain through behavior. Individual aptitude matters: monkeys/foxes may learn quickly, but lower layers never imply human speech. Human form and fluent language belong to a later, separately designed stage.

### Work, gates, and immutable grades

Human `gate_method` is `[0,0,1,2,2,2,3,3,3]`; medicine starts at layer 4 (`iron_bark`), layers 5–6 use `beast_marrow`, and layers 7–9 use `seven_leaf`. Preserve that difficulty shape, using animal-compatible recipes and instinctive methods rather than requiring a deer to read a manual. Grazing, climbing, migration, play, and successful escape count as drills; killing need not be the best training action.

Use method cap 0/1/2/3 for incidental exertion / patterned instinct / coherent inherited-or-learned regimen / complete balanced regimen. They correspond to Low/Middle/High/Perfect maximum grade. Grade indices are 0–3, stamped **per completed layer for life**. Later purification or a better method cannot rewrite an old stamp.

Proposed gate quality `Q` (0–100): 30% developmental health, 25% completed/varied practice, 20% catalyst compatibility/purity, 15% stable uptake, 10% bounded innate affinity. Normalize each component to 0–100. Stamp Low below 45, Middle 45–69, High 70–89, Perfect 90–100, then apply method cap. Polishing improves practice/stability before advancement, at a time/food cost. Starvation, incompatible cores, and unrecovered injuries lower quality. Successful recovered hardship can improve practice; torture itself grants nothing. Perfect quality is possible on either path: corruption and structural quality are separate axes.

### Rare awakening, measured per animal-year

Use annual **hazards**, `λ`, and sample `p(Δt) = 1 − exp(−λ × Δt_years)`. At these small values hazard and annual probability are nearly equal. Only living unawakened animals are eligible; no spontaneous replacement for a species with zero population.

| Exposure | Base λ per animal-year, before species affinity | Approximate annual odds |
|---|---:|---|
| Ordinary valley, no known catalyst | 0.00001 | 0.001%, 1 in 100,000 |
| Regular access to a weak qi site | 0.00010 | 0.010%, 1 in 10,000 |
| Sustained access to a rare strong qi site | 0.00100 | 0.100%, 1 in 1,000 |
| Exceptional compatible fruit / survived qi disaster | Separate one-time 0.5% trial, consuming catalyst | Never repeat each update for the same event |

Multiply by species affinity in section 5 and a combined age/bloodline factor capped at 2. Cap ambient λ at 0.005/year; exceptional-event trials are separate, with a one-year refractory period after any such trial. Count exposure in disjoint time intervals, not simultaneously as all three ambient categories. Proposed ordinary-valley mix: 95% ordinary, 4.9% weak, 0.1% strong. At affinity 1, 1,000 ordinary animals then produce **0.0154 awakenings/year**, roughly one per 65 years before mortality/migration and exceptional events. Even at the maximum ambient hazard, a ten-year survivor has only ~4.9% chance. Tune site distribution before raising global odds; “rare per animal” can still overwhelm a large regional population.

**Lifespan:** multiply the species' `lifespan_y` aging scale by the table value, not remaining years repeatedly. Store cumulative biological aging; each year advances biological age by `1 / multiplier`. Reaching a layer slows subsequent aging and never rejuvenates accrued age. A tiger awakened young and maintained at layer 9 has an eventual aging scale of 12×8 = 96 years; a fox 3×8 = 24 years. These are scaling illustrations, not guaranteed lifetimes: a fast-lived fox usually cannot survive the full progression without an exceptional longevity lineage. Predation, injury, hunger, disease, and reproduction costs persist. Lifespan numbers in curated data are ecological working defaults, not measured maximum ages.

## 3. Combat calibration against current code

The present ordinary-beast table contains only sika deer `(6,6,11,10,1)`, boar `(20,14,5,8,2)`, and black bear `(45,40,5,6,2)` in **power, guard, speed, breath, will** order. “Stone swordsman” is an encounter profile, not an animal baseline. Tigers and the other curated species need explicit base profiles before integration; mass alone must not generate them.

Proposed continuous scaling uses completed layers `L` and mean immutable grade `g` (0–3):

```text
power = base_power × [1 + 0.12 × L × (0.8 + 0.1 × g)]
guard = base_guard × [1 + 0.14 × L × (0.8 + 0.1 × g)]
speed = base_speed × (1 + 0.025 × L)
breath = base_breath × (1 + 0.18 × L)
will = min(3, base_will + floor(L / 3))
```

At L0 these recover the original profiles exactly; an awakened-but-untempered animal gets no stat bonus. Exclude uncompleted grades from `g`. Demonic status gives no free multiplier. Will is a **wound-index retreat threshold**, not courage points: current `9` means never retreat, and protecting young/revenge already override motives to it. Keep escape possible; change targeting and motives rather than setting all demonic beasts to 9.

| Fighter, all adults healthy | Power | Guard | Speed | Breath | Will |
|---|---:|---:|---:|---:|---:|
| Ordinary human, attributes 10, skill 0, realm 0 | 10 | 10 | 5 | 8 | 3 |
| Human L9, all Middle, skill 0, realm 0 | 58.60 | 58.60 | 8.15 | 26 | 3 |
| Human L9, all Middle, martial skill 6, realm 0 | 87.90 | 72.66 | 8.15 | 26 | 3 |
| Same skilled human, hunting spear power ×1.3 | 114.27 | 72.66 | 8.15 | 26 | Hunting currently caps at 1 |
| Ordinary tiger **proposed baseline** | 50 | 30 | 7 | 8 | 2 |
| Spirit tiger L9, all Middle **proposed** | 98.60 | 64.02 | 8.58 | 20.96 | 3 |
| Spirit boar L9, all Middle **proposed scaling** | 39.44 | 29.88 | 6.13 | 20.96 | 3 |
| Spirit black bear L9, all Middle **proposed scaling** | 88.74 | 85.36 | 6.13 | 15.72 | 3 |
| Spirit sika L9, all Middle **proposed scaling** | 11.83 | 12.80 | 13.48 | 26.20 | 3 |

Human numbers directly apply `Combat.person()` with grade index 1; realm 0 excludes separate qi-cultivation bonuses. At L9 all Low/Perfect, the human body multiplier ranges 5.32–6.94; tiger power ranges 93.20–109.40 under the proposal. Verify the eventual shared grade accessor uses the same index convention.

**Layer-9 tiger versus layer-9 human:** the tiger clearly outmuscles an untrained unarmed human; against a skilled spear user it has lower power, lower guard, slightly higher strike speed, and less breath. It remains dangerous through cover and first strike, rather than guaranteed superiority. In neutral ground, initial tiger hit chance against the skilled unarmed human is `98.6/(98.6+72.664) ≈ 57.6%`; the reverse is `87.9/(87.9+64.02) ≈ 57.9%`. These are per-strike hit chances, not win rates.

Current fights schedule strikes at `12/speed` seconds; breath lasts `3×breath` seconds, then power falls to 60% and speed to 70%. Damage scales with `(power/guard)^0.8`; forest guard is ×1.15 for both sides. Combat speed also drives escape but is **not km/h**. Preserve ecological locomotion and stamina separately. Existing hunting permits a 2.5× ambush, cautious early retreat, and an automatic tracked kill after sufficiently wounded prey escape; awakened intelligence should invalidate that automatic kill unless an explicit tracking encounter succeeds. Persistent beast wounds must survive encounter resolution. Treat these as integration requirements, not changes made by this report.

## 4. Spirit and demonic paths in simulation terms

Use `path = latent | spirit | demonic`, plus independent qi purity, resentment, human-food conditioning, territoriality, and trust. “Spirit” means stable local qi integration; “demonic” means a sustained hazardous qi/behavior feedback loop. Neither is an ecological diet class. A spirit tiger still hunts deer; a demonic deer may defend a poisoned spring and attack intruders without eating meat.

| Dimension | Spirit tendency | Demonic tendency |
|---|---|---|
| Establishment | Stable uptake, compatible herbs, repeated recovery, secure refuge | Corrupted uptake, repeated blood-rich feeding, or sustained resentment **combined with** unstable qi |
| Site use | Defend a small qi core within ordinary home range; tolerate familiar visitors at a distance | Hoard access, expand exclusion, revisit violent sites; behavior still depends on species |
| Aggression | Better risk assessment; escape, warning displays, cub defense | Lower approach threshold, target-specific grudges, persistence; severe corruption may impair judgment |
| Human relationship | Avoid, recognize benefactors, accept boundaries; trust is individual | Some learn to hunt people; others target former captors or flee everyone |
| Food | Species diet retained, qi/herbs supplement | Same base diet, with explicit learned preferences; no automatic conversion of herbivores into carnivores |
| Remains | Relatively stable essence and useful tissues | Same organ/material opportunities, with instability/taint requiring processing |

**Concrete provisional transition:** update purity `P` and resentment `R` in [0,1] monthly. Compatible clean uptake adds up to 0.03 P/month; corrupted uptake subtracts up to 0.08; incompatible raw cores subtract 0.10/event. Injury/captivity associated with a remembered attacker adds 0.10 R/event, bounded to one event/month; a secure, recovered month removes 0.02. Repeated intentional human predation adds 0.15 instability per distinct hunt; defending young or scavenging a corpse does not. Cap P at `1 − instability`, where instability decays by 0.02 per clean recovered month. Enter demonic at P<0.30 for three consecutive monthly checks and either R>0.60 or instability>0.60. Establish spirit at P≥0.60 for three checks. Recover from demonic only after P≥0.70 and both R and instability<0.30 for six checks. These hysteresis rules are tunable; record causes so the narrative can explain transitions.

Awakening through a corrupted catalyst can initialize low P/high instability, but still needs the transition checks. A single hunting injury, human kill, or cage never guarantees demonhood. Trauma is a possible story pressure, not moral guilt; stop resentment accumulation when its cause is absent. Human hunters can create grudges while believing they are protecting the village.

### Cores, materials, and village responses

| Layer at death | Proposed recoverable goods | Uses and constraints |
|---|---|---|
| 0 | Ordinary meat, hide, bone/marrow | No qi core. Keep current ordinary marrow economy separate. |
| 1–3 | Slightly infused hide, sinew, bone; tiny essence traces | Weak supplementary tempering ingredients; no portable core. |
| 4–6 | One fragile “core seed” / 核胚; reinforced skeletal tissues, marrow | Medicine ingredient after stabilization; cracks/spoils rapidly, limited value. |
| 7–9 | One stable beast core / 兽核; strongly infused tissues | Bounded medicine/refinement resource, graded by layer/quality/purity; not human Golden Core. |

A core concentrates part of the animal's absorbed qi; never count the same essence fully in core, meat, and marrow. Proposed usable essence budget `10×L` units times grade factor `[0.6,1,1.4,2]`, distributed across recovered products, with processing losses. Cap a consumer's absorbed core essence at 10% of its next layer's work requirement per month; gate medicine, time, and exercises remain mandatory. Invalid anatomy produces no product: no deer antler harvest from females, musk only where biologically applicable. Shed antlers, quills, and molted feathers offer small nonlethal supplies without regenerating unlimited qi.

For human integration, refined beast marrow may fill existing layers 5–6 medicine requirements. Hide/bone preparations can support layer 4 recipes. Core extracts can be a costly optional component for layers 7–9 **with** compatible seven-leaf medicine; do not silently replace those existing gates. Demonic goods require purification and lose yield; harvesting cannot erase taint. These are fictional medicines, not claims about real animal products or health benefits.

Villages need reports/tracks before responding. Give choices: reroute around a territorial deer, fence crops, evacuate a danger area, offer a protected grove, hire a hunter, or request a coordinated hunt. Reputation follows observed deeds, not color or species. Reverence can protect a spring, while offerings create habituation and food costs. Hunting has injury, ecological, and grudge consequences; killing the source guardian may expose valuable habitat but does not create infinite respawns.

Reserve taming for a later system: habituation → trust → cooperative behavior → optional informed bond for sufficiently intelligent beasts. Hunger, pain, or a defeated state should not itself sign a contract. Track owner/partner, obligations, consent/coercion, and broken promises separately; a tame animal remains hungry, territorial, and capable of refusal.

“Heaven” can initially be event framing: rare qi storms, auspicious sightings, or warnings at a major breakthrough. No necessary lightning at each layer and no automatic divine punishment for a predator's normal meal. If an active heavenly system comes later, react to sustained corruption, widespread slaughter, or destabilized qi sites, with observable rules and warning time.

## 5. Curated-species forms

All 25 entries in `curated.json` are covered, including the three population-tier species. Affinity multiplies section 2's ambient hazard, not combat strength. **All names below are newly proposed descriptive Chinese names, not attested classical species or novel-specific creatures.** S = spirit; D = demonic. Form traits emphasize existing ecological niches; they do not add spells. Fox/deer/monkey prominence is a stylistic choice informed by the older sources in section 1; other affinities are design choices.

| Curated species | Affinity | Signature forms and behavior |
|---|---:|---|
| Grey wolf | 1.0× | S 银毫灵狼, Silver-haired Spirit Wolf: patient pack guardian. D 血牙妖狼, Blood-fanged Yao Wolf: learns raids and holds grudges; packmates remain ordinary. |
| Tiger | 1.2× | S 云纹灵虎, Cloud-striped Spirit Tiger: deliberate ambush hunter at a spring. D 血纹妖虎, Blood-striped Yao Tiger: returns to successful human ambush sites. |
| Asiatic black bear | 1.0× | S 月纹灵熊, Moon-marked Spirit Bear: pale chest crescent, guards mast grove. D 裂爪妖熊, Rending-claw Yao Bear: breaks food stores and defends carcasses. |
| Brown bear | 1.0× | S 岩背灵熊, Rock-backed Spirit Bear: massive shoulders, seasonal upland visitor. D 赤背妖熊, Red-backed Yao Bear: excludes rivals from corrupted feeding grounds. |
| Red fox | 2.0× | S 霜尾灵狐, Frost-tailed Spirit Fox: exceptional memory and pale tail tip. D 惑踪妖狐, Trail-confounding Yao Fox: uses cover and learned decoys; no literal illusion spell. |
| Leopard | 1.0× | S 云斑灵豹, Cloud-spotted Spirit Leopard: precise tree routes. D 夜爪妖豹, Night-clawed Yao Leopard: stalks familiar paths and isolates vulnerable targets. |
| Wild boar | 0.8× | S 玉牙灵豕, Jade-tusked Spirit Boar: hardy rooter guarding mineral wallow. D 铁鬃妖豕, Iron-bristled Yao Boar: crop-breaking charges and dangerous injury grudges. |
| Sika deer | 1.6× | S 白毫灵鹿, White-haired Spirit Deer: pale coat, wary herb-patch guardian. D 赤眸妖鹿, Red-eyed Yao Deer: aggressive exclusion and rut displays; antlers only where appropriate. |
| Siberian roe deer | 1.0× | S 青影灵狍, Green-shadow Spirit Roe: concealment and alert browsing. D 荆影妖狍, Thorn-shadow Yao Roe: lashes at pursuers, prefers tangled cover. |
| Forest musk deer | 1.4× | S 幽香灵麝, Hidden-fragrance Spirit Musk Deer: secret herb refuges. D 煞牙妖麝, Baleful-fanged Yao Musk Deer: defensive bites, ambush deterrence; male musk remains sex-specific. |
| Chinese goral | 1.0× | S 踏岩灵斑羚, Rock-treading Spirit Goral: exceptional footing. D 断崖妖斑羚, Sheer-cliff Yao Goral: repeated charges at narrow ledges. |
| Hare | 0.5× | S 月毫灵兔, Moon-haired Spirit Hare: pale flecks, keen vigilance. D 赤影妖兔, Red-shadow Yao Hare: erratic territorial rushes; survives mainly through escape. |
| Common pheasant | 0.5× | S 锦羽灵雉, Brocade-feathered Spirit Pheasant: striking plumage and alarm calls. D 血冠妖雉, Blood-crested Yao Pheasant: aggressive spurs where present; never automatically a phoenix. |
| Sheep | 0.4× | S 云绒灵羊, Cloud-fleeced Spirit Sheep: flock vigilance and resilience. D 逆角妖羊, Defiant-horned Yao Sheep: repeated butting; hornless individuals use another visible marker. |
| Goat | 0.6× | S 青崖灵山羊, Green-cliff Spirit Goat: climbs to herb shelves. D 裂石妖山羊, Stone-rending Yao Goat: powerful butting, stubborn exclusion. |
| Cattle | 0.5× | S 厚土灵牛, Deep-earth Spirit Ox: steady work and calf defense. D 血角妖牛, Blood-horned Yao Ox: dangerous charges after repeated persecution; name variant for hornless stock. |
| Water buffalo | 0.6× | S 玄泽灵水牛, Dark-marsh Spirit Buffalo: protects watering grounds. D 泥渊妖水牛, Mud-pool Yao Buffalo: blocks crossings and attacks close intruders. |
| Domestic pig | 0.4× | S 福纹灵猪, Fortune-marked Spirit Pig: detects compatible roots by scent. D 噬栏妖猪, Pen-gnawing Yao Pig: escape and learned food aggression. |
| Chicken | 0.3× | S 晨辉灵鸡, Dawn-glow Spirit Chicken: early warnings and bright feathers. D 赤距妖鸡, Red-spurred Yao Chicken: repeated attacks at the coop boundary; spurs depend on individual anatomy. |
| Village dog | 1.0× | S 守山灵犬, Mountain-guarding Spirit Dog: remembers allies and patrol boundaries. D 怨牙妖犬, Resentful-fanged Yao Dog: target-specific hostility after abuse; loyalty is never automatic. |
| Takin | 1.4× | S 金背灵羚牛, Golden-backed Spirit Takin: herd sentinel at highland qi forage. D 碎岩妖羚牛, Rock-shattering Yao Takin: formidable close charges; remains a browser. |
| Giant panda | 0.8× | S 竹隐灵熊猫, Bamboo-hidden Spirit Panda: slowly guards a qi-bamboo patch. D 墨爪妖熊猫, Ink-clawed Yao Panda: defensive exclusion and biting, not mandatory human hunting. |
| Golden snub-nosed monkey | 2.0× | S 金毫灵猴, Golden-haired Spirit Monkey: quick learning and troop alarms. D 赤面妖猴, Red-faced Yao Monkey: coordinated harassment learned by ordinary troop members. |
| Reeves's muntjac | 0.8× | S 青溪灵麂, Green-stream Spirit Muntjac: quiet browsing and sharp alarms. D 暗牙妖麂, Shadow-fanged Yao Muntjac: cover-based defense; never a miniature tiger. |
| Malayan porcupine | 0.6× | S 玉刺灵豪猪, Jade-quilled Spirit Porcupine: resilient quills and patient defense. D 铁刺妖豪猪, Iron-quilled Yao Porcupine: dangerous backward rushes; quills cannot shoot. |

Cranes and snakes have strong literary potential but are outside these curated entries; do not add them merely to satisfy a folklore checklist. Keep the existing scientific IDs and local taxonomy rather than silently correcting the hare or replacing Qinling species with mythical taxa.

## 6. Data, scheduling, and verification proposal

### Static configuration and persistent state

`species.json` is generated from GBIF/rules/curated overrides. Future implementation should author overrides in `curated.json` and preserve them through `tools/build_species_catalogue.py`; avoid hand-maintaining divergent generated rows. This report does not edit either file.

| Location | Proposed fields | Purpose/default |
|---|---|---|
| Species / curated override | `cultivation_eligible`, `awakening_affinity`, `qi_food_tags`, `instinct_method_cap`, `form_ids` | Eligibility false outside an explicit supported set; affinity 1 for eligible supported animals; forms reference shared definitions. |
| Species / curated override | `combat_profile_id`, `anatomy_tags`, `cultivation_growth_cap` | Preserve combat/ecology separation; validate profile exists; prevent invalid harvests; growth cap 1.36. |
| Shared beast rules, future separate data file | Layers, work costs, method caps, grade weights, minimum years, aging multipliers, core yields, path thresholds | One authoritative table; derive human parallels rather than duplicating scattered constants. |
| Qi site | Stable ID, location/radius, quality, purity, uptake capacity/day, remaining catalyst stock, renewal rate | Finite benefits, spatial lookup, contention; no map-wide qi omniscience. |
| Ordinary individual or cohort | Exposure category/time, sensitivity seed or distribution, event-trial history | Avoid a full cultivation object for ordinary animals. Cohorts retain age/condition strata. |
| Awakened animal | `id`, species ID, origin cohort, birth/biological age, awakening date/cause, `layer`, `layer_grades[9]`, work, layer start | Identity, immutable history, gates; incomplete grades use sentinel −1. |
| Awakened animal | Method ID/cap, drill evidence, catalyst inventory/assimilation, reserves, injury, fatigue, last update | Recovery and nutrition remain causal; reuse existing physiology where present. |
| Awakened animal | Path, purity, instability, resentment, threshold durations, human-prey conditioning, qi-site claim, known threats/benefactors | Explain behavior; sparse memories with bounded size and decay. |
| Awakened animal | Form ID/seed, bond state, core state/essence allocation, reproduction cooldown | Stable appearance, later taming, no duplicate loot or inherited layers. |

### Cost-conscious operation

1. Keep common wildlife in spatial **species × habitat × age/condition cohorts**. Existing curated large animals already use individual tier; retain meaningful existing individuals rather than forcing a migration solely for cultivation. Hares, pheasants, and chickens are explicitly population tier today.
2. For each exposure cohort, sample awakenings weekly/monthly as `Binomial(N, 1−exp(−λΔt))`. Poisson with mean `NλΔt` is acceptable only as a rare-event approximation with bounded draws. Sample/remove actual cohort age and sex; decrement exactly once and create exactly one persistent individual per success. Never roll for absent tigers (`start: 0`).
3. Once awakened, retain identity even offscreen. Abstract travel, feeding, and work on coarse ticks; wake detailed AI only for nearby events. Do not return an awakened animal to anonymous counts and later duplicate its core or history.
4. Qi-site occupancy limits cumulative uptake. Cache candidate sites spatially; use local detection and remembered locations. A spirit deer defends the spring core, not necessarily its entire ecological home range. Claims overlap according to species/social structure.
5. Resolve growth/aging monthly and breakthroughs only when all requirements change to satisfied. Use fixed timestep-independent exposure accounting and stable event-specific RNG streams so combat draws do not alter regional awakening counts.
6. Keep energy/biomass accounting from the wildlife report: hunger, reserves, fatigue, ordinary prey, water, and winter still matter. Proposed maintenance surcharge is +3% per layer at unchanged mass, plus explicit additional mass costs; qi uptake pays the supernatural growth budget, not free edible meat. Do not charge growth twice.
7. Bound breeding through existing mates, condition, and intervals; optional high-layer fertility reduction prevents immortal dynasties swamping the valley. Proposed inherited affinity bonus ≤25%, inside the combined 2× cap; newborns start layer 0. Use regional emigration and finite site capacity, rather than deleting named beasts at a performance cap.
8. Log population removals, awakening causes, progression failures, qi uptake, kills, human encounters, and yields. Most years should contain ordinary ecology; a rare beast changes a local situation instead of converting the whole food web into loot combat.

### Proposed tests for the implementation job

| Test family | Assertions / measurements |
|---|---|
| Schema and generation | All 25 supported curated entries resolve forms/anatomy/profiles; generated catalogue preserves overrides; unknown species stay ordinary; pre-feature saves migrate to layer 0. |
| Hazard statistics | Zero exposure/time and absent populations yield none; cohort and individual samplers match expected means/confidence intervals; daily vs monthly constant-hazard trials agree statistically; exceptional event retried after reload does not reroll. |
| Conservation and identity | Promotion moves one animal, with age/sex/reserves intact; migration does not duplicate IDs; death/harvest consumes one core once; offspring inherit no layers; saved RNG/history survives load. |
| Gates and grades | Missing medicine/method/minimum age blocks; herb spam cannot bypass time; herbivores advance through escape/climbing; old grades never change after purification; cap and threshold boundaries are deterministic. |
| Path behavior | Ordinary carnivory/self-defense never alone causes demonhood; corruption needs duration; recovery requires hysteresis; peaceful panda and people-hunting tiger remain distinct behaviors. |
| Physiology and longevity | Starvation/injury remain lethal at L9; biological age never decreases; new layers slow future aging only; bear denning and seasonal food schedules still apply. |
| Combat parity and balance | L0 profiles match existing beasts; assert table arithmetic independently; later seeded encounter batches compare tiger/human skills, spear, cover, ambush, retreat and exhaustion. Measure deaths/escapes/duration, not only wins; no test executions are part of this research task. |
| Persistence and pursuit | Beast wounds carry across fights; escaped awakened prey cannot become an automatic tracked kill; all loot comes from a confirmed persistent death. |
| Long-run rarity and cost | Across many future simulated decades/seeds, compare counts to hazard expectations, track layer distribution/site crowding and food balance; common population count does not increase per-animal cultivation CPU/memory. |

## 7. Ten-line recommendation summary

1. Add rare awakening before a nine-layer Beast Tempering stage matching the human body foundations.
2. Separate species, layer, permanent grade, intelligence, path, and relationship to people.
3. Start ambient awakening at 0.001% per ordinary animal-year and concentrate opportunities at finite qi sites.
4. Require years, species-appropriate exercises, recovery, compatible medicine, and capped methods at gates.
5. Keep most awakened animals at layers 1–3; make layer 9 a decades-old regional rarity.
6. Preserve ordinary diets, hunger, seasonal behavior, injuries, and local territorial information.
7. Make demonic paths arise from sustained unstable qi and specific history, with possible recovery.
8. Use modest species-based combat multipliers; calibrate the spirit tiger against skilled armed humans.
9. Delay stable beast cores until late tempering and conserve essence across every harvested product.
10. Promote awakened population members into persistent individuals and verify rarity, conservation, and save stability.
