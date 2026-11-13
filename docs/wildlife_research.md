# Mountain-valley wildlife: research and simulation parameters

| Convention | Meaning |
|---|---|
| `range → default` | Plausible working range followed by one recommended simulation value. Defaults describe a healthy adult, usually female or intermediate-sized—not a maximum-sized male. |
| `†` | **Simulation estimate**, not a well-established species constant. Especially applicable to movement, pursuit duration, fasting reserves, and local home ranges. |
| `U` | Reliable, transferable measurement unavailable. An explicit simulation proxy follows where useful. |
| Food units | Meat is **edible wet mass**; herbivore forage is **dry matter (DM)**; grain/feed is approximately dry feed. Fresh grass at 20% DM weighs **5×** its DM amount. |
| Fasting | Assumes drinking water. “Reserve days” are proposed initial energy reserves, **not measured time to death**. Cold, lactation, youth, injury, and initial body condition change survival substantially. |
| Hunting success | Probability per **committed attack**, not per animal seen or hour spent searching. Definitions differ among studies; most values below are tuning envelopes. |
| Lifespan | Approximate lifespan of an animal surviving infancy, not newborn life expectancy or a mandatory death age. Domestic values describe potential life under husbandry, not slaughter age. |
| Geographic fit | Use an Amur/NE-Asian forest assemblage as the core. Chinese goral and water buffalo broaden this toward a fictional central-Chinese transition zone. Asian “red deer” may be **wapiti, *Cervus canadensis***; do not directly copy European red-deer or North American elk measurements without adjustment. [Taxonomic context](https://explorer.natureserve.org/Taxon/ELEMENT_GLOBAL.2.1353292/Cervus_canadensis). |

## Species tables

### A. Body size, feeding, fasting, and hunting

Food ranges are maintenance starting points; increase requirements for growth, pregnancy, lactation, work, and thermoregulation. Wild herbivore and bear intake estimates below are deliberately approximate.

| Species | Adult mass, kg | Diet / prey / forage | Daily food, kg/day | Without food / reserve model | Kill interval; attack success |
|---|---:|---|---:|---|---|
| **Grey wolf** | 25–55 → **38** | Deer, boar—especially vulnerable individuals; hares, rodents, carrion; livestock opportunistically | Meat 2–5 → **3.5** | Adults can endure days–weeks; reserve **7–14 → 10 d†**, with declining condition | Medium/large ungulate every **2–5 → 3 d per pack†**; **5–30% → 15%†**, prey-dependent. [Feeding](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/hunting-feeding-behavior/), [energetics](https://www.nps.gov/yell/learn/nature/upload/2021-Wolf-Report_reduced.pdf). |
| **Amur tiger** | Females ~100–160; males ~160–220 → **150** | Primarily boar and larger deer; roe deer; occasional bears, dogs, livestock | Meat 6–11 → **7.5** | U; reserve **7–14 → 10 d†**; a multi-day feeding gap is normal | Empirical **7.2–9.4 → 8.3 d/kill** in one study; success **5–20% → 10%†**. [Field energetics](https://scholarworks.umt.edu/etd/114/), [species biology](https://www.animaldiversity.org/accounts/Panthera_tigris/). |
| **Asiatic black bear** | 50–180 → **90** | Acorns, nuts, berries, shoots, roots, insects; carrion; occasional vertebrates | Mixed wet food **3–12 → 6†**; energy density matters greatly | Active fasting U: reserve **10–30 → 20 d†**; northern denning lasts months | Opportunistic predation; **no defensible generic interval or success rate**. [Species account](https://animaldiversity.org/accounts/Ursus_thibetanus/). |
| **Brown bear** | Inland East-Asian adults ~100–350 → **200** | Herbs, roots, berries, nuts, insects, carrion; calves/fawns, occasional livestock; fish where available | Mixed wet food **5–20 → 10†**; autumn intake much higher | Active reserve **15–45 → 30 d†**; denning ~3–6 months where climate requires | Opportunistic; seasonal neonate hunting can be important; **U** for generic success. [Bear biology](https://www.bearbiology.org/the-eight-bear-species/ursus-arctos-brown-bear/). |
| **Red fox** | 3–10 → **5** | Rodents, hares/leverets, birds, eggs, insects, fruit, carrion; chickens | Wet food **0.5–1 → 0.65** | U; reserve **3–7 → 5 d†**; caching buffers shortages | Several small prey/day†; mouse-sized prey count depends on biomass; **10–40% → 25%†**. [Species account](https://animaldiversity.org/accounts/Vulpes_vulpes/). |
| **Leopard** | 25–70 → **40** | Roe/musk deer, smaller sika, boar piglets, hares, birds, dogs, goats | Meat **1.5–4 → 2.5†** | U; reserve **5–10 → 7 d†** | **3–8 → 5 d/kill†**; **10–40% → 25%†**. Global review reports mean ~5.2 d/kill, not an Amur-specific constant. [Kill-rate review](https://euanritchie.org/wp-content/uploads/2024/09/biological-reviews-2024-emerson-a-global-assessment-of-large-terrestrial-carnivore-kill-rates.pdf), [biology](https://www.animaldiversity.org/accounts/Panthera_pardus/). |
| **Wild boar** | 40–150 → **75**; large males exceed this | Mast, roots, tubers, herbs, crops; invertebrates, eggs, carrion, occasional small vertebrates | **1.5–3 → 2 DM†** | U; reserve **7–20 → 12 d†**; piglets much less tolerant | Predation opportunistic; interval/success **U**. [Species account](https://animaldiversity.org/accounts/Sus_scrofa/). |
| **Sika deer** | 35–110 → **65**; regional variation large | Grasses, sedges, herbs, leaves, twigs, bark, crops | **1.2–2.5 → 1.8 DM†** | U; reserve **7–21 → 14 d†** | —. [Species account](https://animaldiversity.org/accounts/Cervus_nippon/). |
| **Asian red deer / wapiti analogue** | 120–300 → **180** | Grasses, sedges, herbs; winter browse, bark; crops | **3–6 → 4.5 DM†** | U; reserve **10–30 → 20 d†** | —. [Asian taxonomy](https://explorer.natureserve.org/Taxon/ELEMENT_GLOBAL.2.1353292/Cervus_canadensis), [older broad species account](https://animaldiversity.org/accounts/Cervus_elaphus/). |
| **Siberian roe deer** | 25–50 → **35** | Selective browse: young leaves, shoots, herbs, buds; some grass and crops | **0.7–1.4 → 1 DM†** | U; reserve **5–15 → 10 d†** | —. [Species account](https://animaldiversity.org/accounts/Capreolus_pygargus/). |
| **Siberian musk deer** | 7–17 → **12** | Lichens, leaves, herbs, shoots; winter arboreal lichens particularly valuable | **0.25–0.5 → 0.35 DM†** | U; reserve **4–12 → 7 d†** | —. [Species treatment](https://treatment.plazi.org/GgServer/xhtml/03C6E250FFB8F05EFFC0FE63137BF728). |
| **Chinese goral** | 22–42 → **30** | Grasses, herbs, leaves, shoots, some fruit | **0.6–1.1 → 0.8 DM†** | U; reserve **5–15 → 10 d†** | —. Published accounts disagree on some life-history values. [Zoo account](https://www.zoothailand.org/en/animal_view.php?c_id=&detail_id=333), [comparative biology](https://perinataldiscovery.ucsd.edu/comparative-placentation/species-index/mammalia/order-artiodactyla/chinese-goral/index.html). |
| **Hare**, mountain-hare physiological proxy | 2–4.5 → **3** | Grasses, herbs; winter twigs/bark; reingests soft feces | **0.08–0.18 → 0.12 DM†** | U; reserve **2–5 → 3 d†** | —. Use a local hare skin/species; these are not measured Manchurian-hare constants. [Mountain hare](https://animaldiversity.org/accounts/Lepus_timidus/). |
| **Common pheasant** | 0.7–1.5 → **1** | Seeds, grain, leaves, shoots; insects, especially for chicks | Dry food **0.06–0.12 → 0.08†** | U; reserve **1–4 → 2 d†** | Insect foraging; no useful large-prey kill interval. [Species account](https://animaldiversity.org/accounts/Phasianus_colchicus/). |
| **Sheep**, small village breed | 30–70 → **45†** | Grass, herbs, hay; crop residues and supplementary grain | **0.9–1.8 → 1.2 DM†** | U; reserve **7–20 → 12 d†**; daily feeding still required | —. Small-ruminant intake commonly ~2–4% body mass DM, varying by production stage. [Nutrition](https://www.sheepandgoat.com/introfeeding). |
| **Goat**, small village breed | 25–60 → **35†** | Shrub/tree browse, leaves, herbs, grass, hay | **0.7–1.4 → 0.9 DM†** | U; reserve **7–20 → 12 d†** | —. [Goat nutrition](https://www.merckvetmanual.com/management-and-nutrition/preventative-health-care-and-husbandry-of-goats/nutrition-of-goats). |
| **Cattle**, small village breed | 250–550 → **350†** | Grass, hay, straw plus adequate supplements; grain | **6–12 → 8 DM†** | U; reserve **10–30 → 20 d†** | —. Typical intake around 2–3% body mass DM, diet-dependent. [Feeding guidance](https://extensionpubs.unl.edu/publication/g2095/na/html/view). |
| **Water buffalo**, swamp type | 300–650 → **450†** | Wetland grasses, sedges, hay, rice straw with supplements | **7–13 → 10 DM†** | U; reserve **10–30 → 20 d†** | —. Fresh-fodder mass varies dramatically with moisture. [FAO feeding](https://www.fao.org/4/t1265e/t1275e01.htm). |
| **Domestic pig**, traditional breed | 50–180 → **90†** | Roots, grain, mast, kitchen scraps, forage, invertebrates | Balanced dry feed **1.5–3 → 2.2†**; scraps require conversion | U; reserve **7–20 → 12 d†** | Opportunistic small-prey feeding; **U**. [Pig nutrition](https://www.merckvetmanual.com/management-and-nutrition/nutrition-pigs/nutritional-requirements-of-pigs?mredirectid=408). |
| **Chicken**, village breed | 1–3 → **1.7†** | Grain/seeds, greens, insects, worms; occasional tiny vertebrates | Dry feed **0.07–0.12 → 0.09†** | U; reserve **1–4 → 2 d†** | Insect foraging; **U**. [Measured husbandry intake](https://extension.usu.edu/poultry/research/principles-of-feeding-small-flocks-of-chickens-at-home). |
| **Village dog** | 10–30 → **18†** | Cooked starches plus protein/fat, scraps, carrion; may hunt wildlife | Wet mixed ration **0.4–1 → 0.7†**; use energy rather than mass | U; reserve **5–14 → 7 d†** | Managed dogs: no hunting requirement. Feral hunting highly variable; **U**, avoid assigning wolf success rates. [Energy requirements](https://www.merckvetmanual.com/management-and-nutrition/nutrition-small-animals/nutritional-requirements-of-small-animals?mredirectid=2389). |

### B. Activity, movement, stamina, and rest

**All numerical movement envelopes below are provisional simulation parameters (`†`).** Reliable comparative measurements of sustained speed and exhaustion time do not exist for this complete species set. “Sustained” means economical walk/trot or moderate escape running—not indefinitely maintainable maximum speed. Burst duration is **below maximum speed**; do not multiply top speed by the whole duration.

`D` = daytime; `N` = night; `C` = dawn/dusk; `P` = repeated bouts across the day. Rest includes quiet lying, rumination, or roosting, **not just sleep**.

| Species | Activity | Daily travel km† | Top / sustained km/h†, each range → default | Hard chase/flee bout† | Quiet/rest h/day† |
|---|---|---:|---|---|---:|
| Wolf | C/N/P; flexible | 10–40 → **20** | 45–60 → **50** / 6–10 → **8** | Fast pursuit 1–10 → **3 min**; searching/trailing can last hours | 10–16 → **12** |
| Amur tiger | C/N; flexible | 3–15 → **7** | 45–60 → **50** / 3–5 → **4** | 10–60 → **20 s**; abandon poor ambushes early | 14–20 → **16** |
| Asiatic black bear | D/C; more N near people | 1–8 → **4** | 30–45 → **35** / 2–5 → **3** | 15–90 → **30 s** | 8–14 → **10**, outside denning |
| Brown bear | D/C/N; seasonal | 2–15 → **6** | 40–55 → **45** / 3–6 → **4** | 20–120 → **45 s** | 8–14 → **10**, outside denning |
| Fox | C/N | 3–12 → **6** | 40–50 → **48** / 5–9 → **7** | 10–90 → **30 s**; stalking/pouncing dominates rodent hunts | 10–16 → **12** |
| Leopard | C/N | 2–10 → **5** | 45–60 → **50** / 3–5 → **4** | 10–60 → **20 s** | 12–18 → **15** |
| Wild boar | C/N near people; otherwise flexible | 1–8 → **3** | 30–45 → **35** / 3–6 → **4** | 30–180 → **60 s** | 10–16 → **12** |
| Sika deer | C/P; often N under disturbance | 1–5 → **2** | 45–65 → **55** / 8–15 → **10** | 1–5 → **2 min** | 8–14 → **10**, much rumination |
| Asian red deer/wapiti | C/P | 2–8 → **4** | 50–65 → **55** / 8–15 → **10** | 1–8 → **3 min** | 8–14 → **10** |
| Roe deer | C/P | 1–4 → **2** | 40–60 → **50** / 7–12 → **9** | 30–180 → **90 s** | 8–14 → **10** |
| Musk deer | C/N | 0.5–3 → **1** | U: **30–45 → 35** / 4–8 → **6** | 15–90 → **30 s**; bounding into cover | 10–16 → **12** |
| Goral | D/C | 0.5–3 → **1** | U: **25–40 → 30** / 3–7 → **5** | 15–120 → **45 s**; cliff access outweighs flat speed | 8–14 → **10** |
| Hare | C/N | 1–5 → **2** | 50–70 → **60** / 15–25 → **20** | 30–180 → **60 s**, turning and concealment | 10–16 → **12** |
| Pheasant | D; roost N | 0.3–2 → **0.8** | Flight 50–80 → **60** / ground 3–6 → **4** | Flight 5–30 → **10 s**; usually land nearby | 10–14 → **12** |
| Sheep | D/P; husbandry-led | 1–6 → **3** | 25–40 → **30** / 3–5 → **4** | 30–180 → **60 s** | 10–14 → **12** |
| Goat | D/P | 1–6 → **3** | 25–40 → **30** / 3–5 → **4** | 30–180 → **60 s**; climb for refuge | 8–14 → **10** |
| Cattle | D/P | 1–5 → **2** | 25–40 → **30** / 3–5 → **4** | 30–180 → **60 s** | 10–14 → **12** |
| Buffalo | D/C; shade/wallow in heat | 1–5 → **2** | 25–40 → **30** / 2–4 → **3** | 30–180 → **60 s** | 10–14 → **12** |
| Pig | D/C; midday rest | 0.2–3 → **1** | 15–30 → **20** / 2–4 → **3** | 20–120 → **45 s** | 12–18 → **14** |
| Chicken | D; roost N | 0.1–1 → **0.4** | Ground 10–15 → **12** / 1–3 → **2** | Run/flight 3–20 → **8 s** | 10–14 → **12** |
| Dog | Human schedule; flexible | 2–15 → **6** | 30–50 → **40** / 6–12 → **8** | 1–10 → **3 min**; breed, heat, fitness matter | 10–16 → **12** |

**Evidence anchors:** wolf travel and feeding are adapted to prolonged search; fox top speed is reported around 48 km/h; tigers stalk and feed repeatedly at carcasses; hares rest concealed during daylight. These support behavioral differences, not precise exhaustion timers. [Wolf biology](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/), [fox](https://animaldiversity.org/accounts/Vulpes_vulpes/), [tiger](https://www.marwell.org.uk/animals/amur-tiger/), [hare](https://animaldiversity.org/accounts/Lepus_timidus/).

### C. Social organization, range, territoriality, and conflict

Home range is **not necessarily defended territory**. Numerical ranges are broad starting envelopes; `†` marks particularly uncertain/local tuning. Domestic ranges represent managed daily access, not intrinsic territorial requirements.

| Species | Social unit: size → default | Home range km²: range → default | Marking; response to own species and other species | Predators/fears; humans; winter/scarcity |
|---|---|---:|---|---|
| Wolf | Family pack 3–10 → **6** | 100–500 → **250†**, per pack | Urine, scat, ground scratching, howling; exclude rival packs, sometimes kill intruders. Hunt prey; avoid stronger carnivores | Tigers can kill/suppress wolves; people usually avoided. Vulnerable livestock may be taken. Snow can initially improve hunting; prolonged prey loss reduces breeding, promotes dispersal. [Social biology](https://www.nationalzoo.si.edu/animals/gray-wolf), [tiger interaction](https://blog.wcs.org/photo/2015/11/04/unfriendly-neighbors-amur-tigers-wolves-russia/). |
| Tiger | Solitary **1**; mother + cubs | Female 200–500 → **300†**; male 500–1,000 → **700†** | Urine spray, scrapes, tree scratches, calls; strong same-sex exclusion, male/female overlap. May kill competitors | Adults have few natural enemies; other tigers and large bears dangerous. Avoid people; defend cubs/kills when pressed. Scarcity can increase ranging and livestock/dog use. [Biology](https://www.animaldiversity.org/accounts/Panthera_tigris/), [livestock study](https://arxiv.org/abs/1810.11195). |
| Black bear | Solitary **1**; mother + cubs | 5–100 → **25†** | Tree rubbing, claw/bite marks, scent; overlapping ranges, dominance at food—not universal boundary defense | Tigers; adult male bears threaten cubs. Usually withdraws/climbs; close surprise or cub defense dangerous. Mast failure encourages crop raids; northern populations den. [Account](https://animaldiversity.org/accounts/Ursus_thibetanus/). |
| Brown bear | Solitary **1**; mother + cubs | 30–500 → **150†** | Rub trees, scent, scratches; ranges overlap, defend food/personal space | Tigers threaten some individuals; adult males threaten cubs. Avoid people, but surprise/cubs/carcasses provoke defense. Autumn hyperphagia; den in winter. [Account](https://animaldiversity.org/accounts/Ursus_arctos/). |
| Fox | Solitary foraging; family 2–6 → **3†** | 1–12 → **5†** | Urine/scat, gland scent, calls; defend core against foxes; retreat from wolves/dogs | Wolves and larger predators; raptors take young. Avoid people but exploit refuse/chickens. Winter: caches, carrion, rodents under snow; expand searches. [Account](https://animaldiversity.org/accounts/Vulpes_vulpes/). |
| Leopard | Solitary **1**; mother + cubs | 20–150 → **60†** | Spray, scrapes, scratches, calls; same-sex defense, opposite-sex overlap; evade larger carnivores | Tigers, other leopards; cubs vulnerable. Usually avoids people; may take dogs/goats. Scarcity changes prey choice and range use. [Account](https://www.animaldiversity.org/accounts/Panthera_pardus/). |
| Boar | Female/young sounder 4–15 → **8†**; mature males often alone | 1–20 → **5†** | Rubbing, gland odors, urine; male rut fights, little exclusive landscape defense | Tigers/wolves; leopards/bears mainly young. Usually flee; cornered/wounded adults or sows can charge. Crop raids; deep snow/frozen soil and mast failure sharply reduce food. [Account](https://animaldiversity.org/accounts/Sus_scrofa/). |
| Sika | Female groups 2–15 → **6†**; seasonal male groups | 0.2–5 → **1†** | Stags scent-mark, thrash vegetation, wallow, call; rut contests. Otherwise tolerate overlapping ranges | Tiger, wolf, leopard; young also smaller predators. Flee humans; crop browsing. Move downslope, aggregate, browse woody plants in winter. [Account](https://animaldiversity.org/accounts/Cervus_nippon/). |
| Asian red deer/wapiti | Sex-segregated herds 5–30 → **12†**; rut harems | 2–30 → **10†** | Rut calls, wallows, scent/rubs, antler contests; defend females rather than every hectare | Tiger/wolf; young vulnerable to bears/leopards. Flee humans; stags dangerous at close quarters in rut. Winter lowland movements and herd formation; poor nutrition reduces recruitment. [Life history](https://animaldiversity.org/accounts/Cervus_elaphus/). |
| Roe deer | Solitary/family 1–4 → **2†**; larger winter groups | 0.2–3 → **0.8†** | Bucks rub/scrape and scent-mark breeding areas; winter overlap more tolerated | Wolf/leopard, occasionally tiger; flee with alarm signals. Browse crops; winter grouping, reduced movement or regional migration. [Account](https://animaldiversity.org/accounts/Capreolus_pygargus/). |
| Musk deer | Mostly solitary **1** | 0.1–1 → **0.3†** | Male scent marks and latrines; male contests using elongated canines; conceal from predators | Leopard, wolf and other forest predators; flee/hide from people. Winter relies on lichens, shelter, conservative movement. [Treatment](https://treatment.plazi.org/GgServer/xhtml/03C6E250FFB8F05EFFC0FE63137BF728). |
| Goral | Small groups 2–12 → **4†**; older males alone | 0.2–1 → **0.4†** | Scent/gland marking; males defend small mating areas; otherwise overlap | Leopard/wolf; young also raptors. Flee humans onto steep rock; cornered animal may horn. Seek exposed forage and sheltered slopes in snow. [Zoo account](https://www.zoothailand.org/en/animal_view.php?c_id=&detail_id=333). |
| Hare | Mostly solitary **1**; loose feeding aggregations | 0.1–1 → **0.3†** | Scent communication; breeding chases, no wolf-like exclusion | Fox, leopard, wolf, dogs, raptors. Freeze, then zigzag/run to cover; browse bark/twigs in winter. [Proxy account](https://animaldiversity.org/accounts/Lepus_timidus/). |
| Pheasant | Breeding male + females; winter flocks 3–20 → **8†** | 0.05–1 → **0.2†** | Male crowing/display, fights over breeding areas; no scent boundary patrol | Fox, raptors, dogs; boar eat eggs. Run/hide, flush at close range. Winter flocking; seek dense cover and grain; snow can block food. [Account](https://animaldiversity.org/accounts/Phasianus_colchicus/). |
| Sheep | Flock 5–50 → **15†** | Managed 0.05–2 → **0.3†** | Social hierarchy, ram contests; no exclusive range defense | Wolf/tiger/leopard, dogs; bunch and flee, follow flock/herder. Winter depends on hay and shelter. |
| Goat | Herd 3–30 → **8†** | Managed 0.05–2 → **0.3†** | Dominance, buck scent and contests; shared browse range | Same large predators/dogs; flee/climb, adults may horn. Hungry goats browse trees and escape enclosures. |
| Cattle | Herd 3–30 → **6†** | Managed 0.1–3 → **0.5†** | Dominance; bulls may challenge, no carnivore-like territory | Tiger/wolf especially threaten calves; herd can confront predators. Human danger from bulls, handling, calf defense. Winter feed shortage causes weight loss. |
| Buffalo | Herd 2–20 → **4†** | Managed 0.1–3 → **0.5†** | Dominance; bulls compete; herd defense rather than exclusive territory | Tigers; calves more vulnerable. Adults may face/charge predators. Require shelter in cold; wallowing is mainly heat management. |
| Pig | Managed group 2–15 → **5†** | Pen/forage 0.001–0.5 → **0.02†** | Dominance and scent; sow defends piglets, boars fight | Large carnivores; piglets especially vulnerable. Root crops, escape for food; cold increases maintenance demand. |
| Chicken | Flock 5–30 → **12†** | Yard 0.001–0.05 → **0.01†** | Pecking order; rooster calls/fights, no scent territory | Fox, dogs, raptors, small carnivores; alarm, scatter, roost. Cold/short days reduce laying; snow restricts foraging. |
| Dog | Human-associated 1–8 → **3†** | Managed/roaming 0.05–5 → **0.5†** | Urine, scat, scratching, barking; defend household/core, response depends on training | Tigers/leopards and wolves may kill dogs. Chase wildlife if unmanaged. Scarcity encourages scavenging/roaming; guard dogs require feeding. |

Domestic behavior rows describe ordinary husbandry patterns; exact group sizes and access areas are **design choices**, not population estimates. Husbandry and seasonal feeding context: [FAO livestock manual](https://www.fao.org/4/t0690e/t0690e05.htm), [poultry management](https://www.merckvetmanual.com/exotic-and-laboratory-animals/backyard-poultry/management-of-backyard-poultry?query=chicken+protein).

### D. Reproduction and lifespan

Northern Hemisphere seasons. `m` = months, `y` = years. Maturity means physiological capability; first successful reproduction can be later. For birds, gestation is replaced by **incubation**.

| Species | Breeding season | Gestation/incubation days: range → default | Young per birth/clutch: range → default | Maturity: range → default | Typical adult-survivor lifespan y: range → default |
|---|---|---:|---:|---|---:|
| Wolf | Jan–Mar | 60–65 → **63** | 3–8 → **5** | 1–3 y → **2** | 5–10 → **7†**. [Biology](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/). |
| Amur tiger | Any; winter/spring peak | 96–111 → **103** | 1–5 commonly → **3** | F 3–4 y → **3.5**; M 4–5 → **4.5** | 10–15 → **12†**. Cubs dependent ~18–36 months; births generally several years apart. [Reproduction](https://www.animaldiversity.org/accounts/Panthera_tigris/). |
| Asiatic black bear | Usually Jun–Jul | ~200–240 → **220†**, including delayed implantation | 1–3 → **2** | 3–5 y → **4** | 15–25 → **20†**. Usually not annual successful litters. [Account](https://animaldiversity.org/accounts/Ursus_thibetanus/). |
| Brown bear | May–Jul | ~180–250 → **220†**, delayed implantation | 1–3 commonly → **2** | 4–7 y → **5** | 15–25 → **20†**. Birth interval often 2–4 years. [Account](https://animaldiversity.org/accounts/Ursus_arctos/). |
| Fox | Jan–Mar | 49–58 → **52** | 3–8 → **5** | 9–12 m → **10** | 2–5 → **3**. [Account](https://animaldiversity.org/accounts/Vulpes_vulpes/). |
| Leopard | Any; regional seasonality | 90–105 → **96** | 1–3 commonly → **2** | 2–3 y → **2.5** | 10–15 → **12†**. Successful litters roughly 18–24 months apart†. [Account](https://www.animaldiversity.org/accounts/Panthera_pardus/). |
| Boar | Mainly Nov–Jan; can extend | 112–120 → **115** | 3–8 → **5** | 8–18 m → **12**; strongly condition-dependent | 5–10 → **7†**. [Account](https://animaldiversity.org/accounts/Sus_scrofa/). |
| Sika | Sep–Nov | 210–240 → **225** | 1–2 → **1** | 1.5–2.5 y → **2** | 8–15 → **10†**. [Account](https://animaldiversity.org/accounts/Cervus_nippon/). |
| Asian red deer/wapiti | Sep–Oct | 230–260 → **245†** | 1; twins rare → **1** | F 1.5–3 y → **2**; successful males later | 10–18 → **12†**. Species/population identification matters. [Broad older account](https://animaldiversity.org/accounts/Cervus_elaphus/). |
| Siberian roe deer | Jul–Sep | ~280–300 → **290†**, including delayed implantation | 1–3 → **2** | 1–2 y → **1.5** | 7–12 → **9†**. [Account](https://animaldiversity.org/accounts/Capreolus_pygargus/). |
| Musk deer | Nov–Dec | 182–194 → **187** | 1–2 → **2†** | ~1.5–2 y → **1.5†** | 5–12 → **7**. [Treatment](https://treatment.plazi.org/GgServer/xhtml/03C6E250FFB8F05EFFC0FE63137BF728). |
| Chinese goral | Autumn/early winter | **180–260 → 220†**, published disagreement | 1–2 → **1** | 2–3 y → **2.5** | U: **8–15 → 10†**. [Conflicting gestation evidence](https://perinataldiscovery.ucsd.edu/comparative-placentation/species-index/mammalia/order-artiodactyla/chinese-goral/index.html). |
| Hare, mountain-hare proxy | Spring–summer | 45–55 → **50†** | 1–4 → **2†**; ~2–3 litters/year | ~1 y → **1†** | 2–5 → **3†**. [Proxy](https://animaldiversity.org/accounts/Lepus_timidus/). |
| Pheasant | Mar–Jun | Incubation 23–28 → **25** | 7–15 eggs → **10** | ~1 y → **1** | 1–3 → **2†**; substantial juvenile mortality. [Account](https://animaldiversity.org/accounts/Phasianus_colchicus/). |
| Sheep | Autumn; breed-dependent | 145–152 → **148** | 1–3 → **1†**, conservative village breed | 6–12 m → **9†** | 8–12 → **10†** |
| Goat | Autumn; breed-dependent | 145–155 → **150** | 1–3 → **2†** | 5–12 m → **9†** | 10–15 → **12†** |
| Cattle | Any with adequate condition | 278–290 → **283** | 1; twins uncommon → **1** | 9–18 m → **15†** | 15–20 → **16†** |
| Buffalo | Often seasonal peak; management-dependent | 305–340 → **320†**, swamp-type default | 1; twins rare → **1** | 2–3.5 y → **3†** | 15–25 → **20†** |
| Pig | Any | 112–116 → **114** | 4–10 → **6†**, traditional breed | 5–9 m → **7†** | 8–15 → **10†** |
| Chicken | Spring/summer; laying responds to light | Incubation 20–22 → **21** | Broody clutch 6–12 → **8†** | 5–8 m → **6†** | 4–8 → **6†** |
| Dog | Often 1–2 estrous cycles/year | 62–64 after ovulation → **63** | 3–8 → **5†** | 6–18 m → **12†** | 8–14 → **11†** |

Domestic gestation sources: [Merck reproductive overview](https://www.merckvetmanual.com/reproductive-system/reproductive-system-introduction/the-reproductive-system-in-animals?mredirectid=17), [goats](https://www.merckvetmanual.com/management-and-nutrition/management-of-reproduction-goats/pregnancy-in-goats), [buffalo](https://ccari.res.in/dss/buffalo.html). Domestic maturity, litter, and longevity envelopes are broad breed-dependent defaults.

## 1. Food web

| Consumer | Main links to simulate | Important qualifications |
|---|---|---|
| Tiger | Larger deer, boar; occasional roe deer, bears, livestock and dogs | Can kill wolves. Treat this as occasional intraguild predation and avoidance, not constant combat. |
| Wolf | Deer, boar juveniles/vulnerable adults, hares, carrion; exposed livestock | Packs share kills. Large healthy boar and adult bovines impose substantial injury risk. |
| Leopard | Roe/musk deer, small deer, piglets, hares, birds; goats/dogs | Overlaps tiger and wolf diets but favors smaller prey and concealment. |
| Fox | **Rodents**, leverets, pheasants/chickens, eggs, insects, fruit, carrion | Rodents must exist at least as an abstract food pool; hares alone cannot support every fox. |
| Bears | Mast, berries, herbs, roots, insects; carrion; occasional young ungulates | Brown bears can appropriate carcasses. Black bears also scavenge but risk tiger predation. |
| Boar/pigs | Mast, roots, crops, invertebrates, carrion, eggs | Omnivory matters: they compete with bears for mast and with deer/livestock for some forage. |
| Deer/goral/livestock | Grass, browse, herbs; some mast/crops | Separate grass, browse, mast, and crop resources; a single “plant food” variable erases useful niches. |
| Hare | Herbs/grass, winter bark/twigs | Dense vegetation provides both food and concealment. |
| Pheasant/chicken | Seeds, grain, greens, invertebrates | Chicks need insects; egg and chick mortality differ from adult mortality. |
| Dogs | Human food, carrion; wildlife if roaming | Human subsidy can support more dogs than wild prey alone could support. |

Tiger–wolf killing is documented, including a released tiger killing and eating two wolves; prey competition and avoidance also contribute to wolf suppression. Bears, wolves, and foxes exploit carcasses, but the larger animal does not automatically win every encounter. [WCS field account](https://blog.wcs.org/photo/2015/11/04/unfriendly-neighbors-amur-tigers-wolves-russia/), [wolf scavenging interactions](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/hunting-feeding-behavior/), [black bear–tiger interactions](https://animaldiversity.org/accounts/Ursus_thibetanus/).

**Competition rules:** tiger/wolf/leopard compete through shared prey and interference; wolves may kill foxes without eating them; foxes can benefit from scavenging larger predators’ leftovers. Browsers compete most strongly with browsers, grazers with grazers, and mast consumers during autumn shortages. Livestock can reduce wild ungulates’ habitat access as well as consume their food. [Fox interactions](https://animaldiversity.org/accounts/Vulpes_vulpes/), [NE-China livestock study](https://arxiv.org/abs/1810.11192).

## 2. Population dynamics and carrying capacity

### Working density targets

These are **initialization/calibration envelopes†**, not measured universal carrying capacities. Apply them per km² of suitable habitat, with seasonal food budgets and shared competition.

| Guild/species | Working density/km²† | Default† | Interpretation |
|---|---:|---:|---|
| Larger deer, sika + wapiti equivalents combined | 1–8 | **3** | Productive forest-edge mosaic; poorer closed/cold forest can support less |
| Roe deer | 1–10 | **3** | Do not add its full maximum independently of other browsers |
| Boar | 0.5–5 | **2** | Mast/crops can temporarily support substantially more |
| Musk deer | 0.2–2 | **0.5** | Suitable forest cover and winter lichens required |
| Goral | 0.5–5 per suitable rocky km² | **2** | Usually only a fraction of the map qualifies |
| Combined deer + boar live biomass | 200–1,000 kg/km² | **500** | More useful than total animal count when species differ greatly in size |

Actual field densities vary enormously. Sikhote-Alin counts include deer densities around or below one animal/km² in some settings; a Polish forest study estimated boar densities around **8–10/km²**. Neither observation is itself carrying capacity. [Sikhote-Alin methods/results](https://www.scipedia.com/public/Myslenkov_Miquelle_2015a), [boar field study](https://link.springer.com/article/10.1007/s42991-021-00182-7).

**Predator:prey biomass:** use **1:100–1:500, default 1:200†**, as a conservative starting envelope for **large obligate carnivores versus their standing ungulate prey biomass**. This is a proposed calibration range, not a universal ecological law. Exclude largely plant-fed bears and human-fed dogs from that ratio. Empirical work finds sublinear predator–prey biomass scaling, so there is no single constant ratio transferable across all ecosystems. [Hatton et al.](https://pubmed.ncbi.nlm.nih.gov/26339034/), [food-web analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC9411528/).

**Check annual flows before accepting a ratio.** For example:

- A tiger eating **7.5 kg/day** needs **2,738 kg edible meat/year**.
- At an assumed **60% usable carcass yield†**, that requires about **4,563 kg/year of live prey**, before scavenger losses.
- A six-wolf pack at **3.5 kg/wolf/day†** requires **7,665 kg edible meat/year**.
- A 20 km² valley at **500 kg ungulate biomass/km²†** contains only **10,000 kg standing ungulate biomass**. One resident tiger plus a resident wolf pack would demand an implausibly large share of it annually.

These are arithmetic design checks using field tiger intake and proposed wolf/yield assumptions. [Tiger intake measurement](https://scholarworks.umt.edu/etd/114/).

**Recommended scale:** treat the valley as part of a larger landscape. A tiger may visit, feed, and leave; a wolf pack may use it intermittently. Maintain regional animals and migration routes outside the rendered map. Several hundred visible animals need not constitute a closed, self-sufficient community.

### Lags and safeguards

Predator abundance follows prey with delays from breeding seasons, gestation, dependent young, recruitment, and immigration. Wolves may respond through their next annual litter; tiger and bear recruitment takes multiple years. A predator should not reproduce immediately because its hunger meter filled. [Wolf demography](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/), [tiger development](https://www.animaldiversity.org/accounts/Panthera_tigris/).

For a lightweight model:

1. **Regrow food seasonally.** Winter capacity should fall through plant access, snow, and forage quality.
2. **Use functional responses:** search time + handling time + digestion limit consumption.
3. **Provide real refuges:** dense cover, inaccessible cliffs, hiding young, escape trees, protected enclosures.
4. **Limit breeding by condition and mates**, and large-predator density by territorial space.
5. **Allow prey switching and scavenging**, with switching costs and different capture risks.
6. **Allow emigration and bounded immigration** from a regional population.
7. **Make encounters local.** Predators cannot know every prey position.
8. **Accept occasional local extinction.** Preventing every crash artificially is less realistic than recovery through dispersal.

These are modeling recommendations informed by spatial predator–prey dynamics; simple energy-based models demonstrate how food renewal and reproduction settings can produce persistence or extinction. [NetLogo model documentation](https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation).

## 3. Hunger and stamina from physiology

**Separate appetite, stored energy, and performance.** A workable state contains:

| State | Suggested purpose |
|---|---|
| Stomach/gut contents | Meal capacity, digestion, immediate satiation |
| Body reserves | Fat/protein energy buffer; changes over days/weeks |
| Burst stamina | Rapid exertion capacity; recovers after stopping |
| Fatigue | Accumulates over prolonged travel, poor sleep, repeated pursuits |
| Condition/health | Persistent consequences of malnutrition, injury, disease |
| Temperature/water access | Heat limits pursuit; cold raises costs; water shortage differs from starvation |

Use an energy budget:

```text
reserve_change =
    assimilated_food_energy
    - maintenance
    - locomotion
    - thermoregulation
    - growth
    - reproduction
```

Food kilograms are an input conversion, not energy themselves. A kilogram of wet berries, lean meat, dry grain, and straw have very different nutritional value. Gut capacity and digestibility constrain how much low-quality forage an herbivore can use. [Ruminant feeding](https://www.sheepandgoat.com/introfeeding), [pig energy/intake](https://www.merckvetmanual.com/management-and-nutrition/nutrition-pigs/nutritional-requirements-of-pigs?mredirectid=408), [dog energy requirements](https://www.merckvetmanual.com/management-and-nutrition/nutrition-small-animals/nutritional-requirements-of-small-animals?mredirectid=2389).

**Gorging and carcasses:** wolves can eat approximately **20% of body mass** in one meal. Tigers feed repeatedly from large kills. Store carcass mass, accessibility, spoilage, scavenger removal, and ownership risk; an animal already guarding substantial food should usually return to it. [Wolf feeding](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/hunting-feeding-behavior/), [Amur tiger feeding](https://www.marwell.org.uk/animals/amur-tiger/).

**Starvation should be gradual.** Missing one meal should usually increase motivation, not immediately remove health. Sustained deficits reduce reserves, reproduction, growth, and eventually locomotor performance. Young animals have smaller buffers. Set initial reserves from body condition, then calculate depletion rather than killing every animal after a fixed fasting timer. Wolf adults’ feast/famine tolerance and pups’ need for regular feeding illustrate this distinction. [Wolf FAQ](https://wolf.org/wolf-info/basic-wolf-info/wolf-faqs/).

**Hunting locomotion:** wolves spend much effort traveling, finding, testing, and following prey; that does not mean sprinting for hours. Tigers and leopards depend on approach and ambush. Model detection distance, cover, approach angle, prey vigilance, and abandonment decisions before resolving a chase. **Do not independently apply a fixed success roll after already simulating an escape outcome**—that double-counts failure.

Suggested recovery defaults†: recover burst stamina substantially over **2–10 minutes** of quiet behavior, but let fatigue require hours. Injury, deep snow, heat, full stomachs, and poor condition alter both depletion and recovery. These are tuning values, not measured universal recovery times.

**Bear denning needs a separate metabolic mode.** Research on American black bears measured metabolism around **25% of basal rates** during hibernation; brown-bear research also documents major physiological conservation. Do not copy the exact percentage to Asiatic black bears as if directly measured. Use **25–50% of basal metabolism†** as an initial denning envelope, plus species-specific reproductive costs. [Black-bear experiment](https://pubmed.ncbi.nlm.nih.gov/21330544/), [brown-bear physiology](https://pmc.ncbi.nlm.nih.gov/articles/PMC5077189/).

## 4. Human–wildlife conflict

### Frequency: exposure matters more than a universal daily probability

| Conflict | Quantitative evidence | Simulation implication |
|---|---|---|
| Amur tiger livestock consumption | One Sino-Russian-border study estimated **94.9% wild prey and 5.1% livestock by consumed biomass** | This is a diet fraction, **not** a 5.1% attack chance or annual livestock loss rate. Forest grazing creates exposure. [Study](https://arxiv.org/abs/1810.11195). |
| Wolf livestock losses | A 2022 compilation across ten contiguous US states recorded at least **425 cattle/calves killed or injured**, approximately **0.002% of cattle inventories** in those states | This modern, managed aggregate cannot be transferred to an unguarded mountain flock. Losses can concentrate heavily on particular holdings. [Data compilation](https://apnews.com/article/80dd1eeac13b5f6395c4c007a96df7aa). |
| Bears and livestock | No defensible universal annual rate for this fictional setting | Represent individual learning, food availability, livestock access, and protection. Bears also damage crops and enter buildings; livestock predation is only one conflict type. [Qinghai records](https://www.sciencedirect.com/science/article/pii/S1617138119301827). |
| Bear injuries to people | Bhutan records identified **34 attacks over 2015–2019**, mean **6.8/year**, across a whole country | Demonstrates real danger without supplying an encounter probability. Many encounters occur during forest work. [Clinical/context study](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0237812). |

### Deterrents

| Measure | Plausible modeled effect | Limits |
|---|---|---|
| Attentive herders | Earlier detection, cohesive flock, interruption of approaches | Depends on visibility, staffing, and proximity |
| Livestock guardian dogs | Alarm, pursuit interruption, group defense | Must be trained, bonded, fed; dogs can themselves be killed |
| Strong maintained enclosures | Reduce access, especially at night | Species-specific construction matters: foxes dig, leopards climb, bears force weak structures |
| Electric fencing | Modern reference: strong deterrence when maintained | Not appropriate to ordinary historical village technology |
| Fire, torches, noise, lights | Temporary perceived risk and detection | No universal protection; habituation and food rewards can overcome fear |
| Remove carcasses/refuse; secure grain | Reduce attraction and repeated visits | Does not eliminate natural predation on exposed stock |
| Avoid unattended forest grazing | Reduce overlap with ambush predators | Costs labor and alternative fodder |

Reviews support fencing, dogs, and herders in some contexts, but evidence quality and effect sizes vary. Do not assign every measure a universal percentage reduction. A protected enclosure is not automatically predator-proof merely because animals are confined. [Intervention evidence review](https://pubmed.ncbi.nlm.nih.gov/28522834/), [management synthesis](https://www.sciencedirect.com/science/article/pii/S1550742418300290).

**Danger to people should emerge from context.** Ordinary wolf encounters usually end in avoidance; documented attacks include rabies-associated, predatory, and defensive circumstances. Habituation and food conditioning matter. Bears are especially dangerous during surprise encounters, cub defense, and food defense. Tigers do not attack every human entering a home range; territorial aggression toward another tiger is a different behavior. Injury or prey shortage can change decisions but should not automatically switch on human predation. [NINA wolf attack review](https://brage.nina.no/nina-xmlui/bitstream/handle/11250/2729772/ninarapport1944.pdf), [bear encounter evidence](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0237812), [tiger biology](https://www.animaldiversity.org/accounts/Panthera_tigris/).

**Useful decision rule†:** select livestock when expected food gain minus handling, injury, and human-intervention costs exceeds available alternatives. Remember successful raids as learned opportunities. Winter can increase exposure through prey weakness or forage shortage, while a well-fed individual may also raid easy stock outside winter.

## 5. Existing games and models: useful lessons

The implementation takeaways below are recommendations. Public descriptions demonstrate selected features; they do not establish that commercial games maintain closed, mass-balanced ecosystems.

| Game/model | Documented approach or visible mechanism | Takeaway for a few hundred animals |
|---|---|---|
| **Equilibrium-style / Lotka–Volterra models** | Population-level births, deaths, and encounter-driven predation; classic equations omit many spatial and behavioral constraints | Useful for regional population budgets and diagnostics. Add seasonal capacity, handling time, age structure, and dispersal before using them as ecology. |
| **NetLogo Wolf Sheep Predation** | Agents gain energy by eating, lose energy through movement, reproduce probabilistically; optional regrowing grass | Excellent minimal testbed. Replace arbitrary step energy and instant reproduction with consistent time/energy units and breeding seasons. [Model documentation](https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation). |
| **Ecosystem** | Evolving aquatic creatures with simulated bodies, movement, feeding, mating, and adaptation | Borrow food-web feedback and observable organism needs. Evolving locomotion/body plans is unnecessary for fixed real-world species. [Developer’s store description](https://store.steampowered.com/app/1133120/Ecosystem/). |
| **Rain World** | Creatures independently seek food and shelter; the player participates within these interactions | Give animals goals that remain meaningful without the player. Use abstract movement offscreen and detailed behavior nearby. Do not import its catastrophic rain into this setting. [Developer account](https://blog.playstation.com/?p=187776). |
| **Dwarf Fortress** | Data-defined creatures support taming, training, livestock roles, and individual interactions | Species data and persistent injuries create stories. Its animal systems should not be assumed to constitute a complete trophic simulation. [Animal system documentation](https://dwarffortresswiki.org/index.php/Animal). |
| **RimWorld** | Animal hunger, food seeking, grazing, predation, and livestock systems | Needs-driven jobs are inexpensive and readable. For this project, add strong human avoidance and risk assessment instead of treating a hungry predator as automatically willing to hunt a villager. [Community mechanics documentation](https://rimworldwiki.com/wiki/Animals). |
| **Red Dead Redemption 2** | Around 200 animal/bird/fish species with habitat-specific environmental responses | Borrow perceptible behavior: tracks, alarm, scavenging, carcasses, flight distance, daily routines. Public material does not demonstrate a closed demographic food web. [Rockstar](https://www.rockstargames.com/newswire/article/51974aa3a8k847/Wildlife-in-Red-Dead-Redemption-2). |
| **Far Cry** | Systemic interactions among world systems generate emergent encounters | Use reusable rules for perception, threat, prey, and interruption. Tune aggression and encounters for ecology rather than frequent combat spectacle. [Ubisoft](https://news.ubisoft.com/en-us/article/2PYfTguMauD7UsnlhJ0u4U/the-future-of-ai-in-games-qa-with-dominic-butler), [developer talk](https://www.gdcvault.com/play/1021974/Far-Cry-4-Gameplay-Team). |
| **Spore** | Five broad stages, from cellular life through civilization and space | Diet categories and recognizable niches aid readability; progression systems are not evidence of realistic population ecology. [Official overview](https://www.spore.com/what/spore). |
| **WolfQuest** | Territory claims respond to scent marking, presence, hunting, and encounters; maintenance competes with hunting and pup care | Particularly useful reference for decaying scent information and competing time budgets. [Territory mechanics](https://support.wolfquest.org/help/quest-establish-territory). |

**Suggested Godot architecture†:** individual agents for the few hundred meaningful animals; pooled rodents, insects, vegetation, and microbes; spatial hash for perception; utility decisions at staggered intervals; continuous close-range movement; coarse offscreen travel and feeding. Maintain territory at pack/individual level, carcasses as finite resources, and reproduction on a seasonal demographic clock.

Start with **one predator system plus two ungulates**, verify annual food balance, then add omnivores and smaller prey. Track biomass, births, causes of death, food availability, failed hunts, injuries, and emigration. Evaluate several simulated decades across multiple random seeds; apparent balance for one summer is insufficient.

## Sources

All links above support their adjacent claim groups. Principal references:

- **Predator energetics:** [Miller, Amur tiger predation and energetic requirements](https://scholarworks.umt.edu/etd/114/); [Yellowstone wolf report](https://www.nps.gov/yell/learn/nature/upload/2021-Wolf-Report_reduced.pdf); [International Wolf Center feeding](https://wolf.org/wolf-info/basic-wolf-info/biology-and-behavior/hunting-feeding-behavior/); [global carnivore kill-rate review](https://euanritchie.org/wp-content/uploads/2024/09/biological-reviews-2024-emerson-a-global-assessment-of-large-terrestrial-carnivore-kill-rates.pdf).
- **Carnivore life histories:** [tiger](https://www.animaldiversity.org/accounts/Panthera_tigris/), [leopard](https://www.animaldiversity.org/accounts/Panthera_pardus/), [fox](https://animaldiversity.org/accounts/Vulpes_vulpes/), [Asiatic black bear](https://animaldiversity.org/accounts/Ursus_thibetanus/), [brown bear](https://animaldiversity.org/accounts/Ursus_arctos/).
- **Ungulates and smaller wildlife:** [boar](https://animaldiversity.org/accounts/Sus_scrofa/), [sika](https://animaldiversity.org/accounts/Cervus_nippon/), [roe deer](https://animaldiversity.org/accounts/Capreolus_pygargus/), [musk deer](https://treatment.plazi.org/GgServer/xhtml/03C6E250FFB8F05EFFC0FE63137BF728), [goral](https://perinataldiscovery.ucsd.edu/comparative-placentation/species-index/mammalia/order-artiodactyla/chinese-goral/index.html), [hare](https://animaldiversity.org/accounts/Lepus_timidus/), [pheasant](https://animaldiversity.org/accounts/Phasianus_colchicus/).
- **Husbandry:** [FAO livestock manual](https://www.fao.org/4/t0690e/t0690e05.htm); [small-ruminant feeding](https://www.sheepandgoat.com/introfeeding); [cattle intake](https://extensionpubs.unl.edu/publication/g2095/na/html/view); [buffalo feeding](https://www.fao.org/4/t1265e/t1275e01.htm); [poultry intake](https://extension.usu.edu/poultry/research/principles-of-feeding-small-flocks-of-chickens-at-home); [domestic gestation](https://www.merckvetmanual.com/reproductive-system/reproductive-system-introduction/the-reproductive-system-in-animals?mredirectid=17).
- **Population ecology:** [Hatton et al., biomass scaling](https://pubmed.ncbi.nlm.nih.gov/26339034/); [complex food-web analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC9411528/); [Sikhote-Alin ungulate census](https://www.scipedia.com/public/Myslenkov_Miquelle_2015a); [boar density study](https://link.springer.com/article/10.1007/s42991-021-00182-7).
- **Physiology:** [black-bear hibernation experiment](https://pubmed.ncbi.nlm.nih.gov/21330544/); [brown-bear conservation physiology](https://pmc.ncbi.nlm.nih.gov/articles/PMC5077189/).
- **Conflict:** [Amur tiger diet](https://arxiv.org/abs/1810.11195); [NINA wolf attack review](https://brage.nina.no/nina-xmlui/bitstream/handle/11250/2729772/ninarapport1944.pdf); [Bhutan bear attacks](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0237812); [livestock protection evidence](https://pubmed.ncbi.nlm.nih.gov/28522834/).
- **Simulation references:** [NetLogo](https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation), [Ecosystem](https://store.steampowered.com/app/1133120/Ecosystem/), [Rain World](https://blog.playstation.com/?p=187776), [Dwarf Fortress](https://dwarffortresswiki.org/index.php/Animal), [RimWorld](https://rimworldwiki.com/wiki/Animals), [RDR2](https://www.rockstargames.com/newswire/article/51974aa3a8k847/Wildlife-in-Red-Dead-Redemption-2), [Far Cry](https://www.gdcvault.com/play/1021974/Far-Cry-4-Gameplay-Team), [Spore](https://www.spore.com/what/spore), [WolfQuest](https://support.wolfquest.org/help/quest-establish-territory).