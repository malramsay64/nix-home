# Scoring Rubric — GF/DF Trip Vetting

Primary diner: **coeliac + dairy-intolerant adult**. Scoring is skeptical by default.

## GF scale (0–5, coeliac-grade)

| Score | Label | Criteria |
|---|---|---|
| 5 | Coeliac-confident | EITHER (a) dedicated GF kitchen / fryer / prep station or formal certification (Coeliac UK / Coeliac Australia accredited, AFDIAN, etc.), OR (b) shared kitchen with **exceptional** coeliac protocols: 3+ explicit coeliac reviewers report safe meals, zero credible reaction reports, staff demonstrably make whole menu adaptable, editorial press recognises coeliac-awareness. |
| 4 | Strong GF program | EITHER (a) a separate GF prep area, station or fryer (described by staff, menu, or reviews) AND staff who are generally knowledgeable about GF/CC, OR (b) no separate area, but excellent GF/coeliac reviews (consistently positive across 2+ independent sources) AND strong support (staff actively adapt dishes, answer CC questions well, take precautions). Zero reaction reports either way. |
| 3 | GF-aware | GF items labelled, staff answer CC questions competently, no explicit separate prep. Positive GF (not necessarily coeliac) reviews dominate. |
| 2 | GF on request | Kitchen will "try" but shared surfaces/fryers. Safe for GF-by-choice, **not coeliac-safe**. |
| 1 | Naturally GF only | No GF program; some dishes inherently GF (pho, rice bowls). High CC risk from soy sauce, shared woks. |
| 0 | Avoid | No GF option, or multiple credible coeliac reaction reports. |

**GF evidence floor** — scores are earned by venue-specific evidence, never by cuisine or ingredients:
- GF 3 needs labelled GF items or a documented instance of staff answering CC questions competently.
- GF 4 needs either (a) a separate prep area, station or fryer **and** generally knowledgeable staff, or (b) excellent GF/coeliac reviews across 2+ independent sources **and** strong staff support (adapting dishes, good CC answers, precautions like cleaning surfaces or changing gloves). Good support with only one source, or good reviews without evidence of support, stays at GF 3.
- Ingredient-GF food (rice rolls, pho, sticky rice) with no venue-specific evidence is **max 2** — usually 1.

## DF scale (0–5)

| Score | Label | Criteria |
|---|---|---|
| 5 | DF-native | EITHER (a) cafe/coffee context with multiple GF-safe plant milks as default (soy, almond, coconut, rice) plus standard butter/cream subs, OR (b) restaurant context where the cuisine is naturally low-dairy (most Thai, Vietnamese, Chinese, Japanese, Korean) AND staff reliably flag/sub the few dairy-containing items, OR (c) any cuisine — including dairy-heavy ones — where the menu carries explicit (DF) labels on most items and a clear "DF optional" / substitution system (e.g. DF cheese available on burgers). Vegan items clearly marked. |
| 4 | Strong DF options | At least one GF-safe plant milk available, DF items labelled, kitchen willing to sub. |
| 3 | DF-accommodating | Can accommodate on request, some DF items naturally on menu. |
| 2 | Limited DF | Dairy-heavy menu with a few exceptions. **Cap here if oat is the only plant milk offered.** |
| 1 | Dairy-forward | French bistro / gelateria / creamery — maybe one safe item. |
| 0 | Everything dairy | No viable option. |

**Oat milk rule**: Oat is *not* GF-safe for this diner. Its presence does not count as a ✓. **Oat-only** means no non-oat plant milk is available, *including on request*. If oat-only, DF caps at 2 and a warning must appear in the verdict block. If soy/almond/coconut/rice is available on request, the cap does not apply — say "ask for soy/almond".

**DF baseline — absence of evidence is not dairy.** Before applying evidence, set a starting DF from what the menu is made of:
- Naturally low-dairy cuisines (Vietnamese, Thai, Chinese, Malay, Japanese, Korean, hawker food): start at **4**. Pull down for known dairy (condensed-milk coffee, cream curries, dessert focus).
- Mixed / modern cafe / brunch: start at **3**.
- Butter- and cream-based cuisines (French, Italian fine dining, bakery, gelato): start at **2**.
DF 1 is reserved for venues where nearly every item contains dairy. Caps (thin evidence → 3) still apply after the baseline.

**Coffee venues** — for the Coffee category, DF is about drinks: one GF-safe plant milk (soy, almond, coconut, rice, macadamia) → DF 4; two or more → DF 5; oat-only → cap 2; none → 1. Mention food DF separately in the bullets if the venue also serves food.

## Evidence weights

| Tier | Weight | Examples |
|---|---|---|
| Coeliac-specific | ×3.0 | Find Me Gluten Free (coeliac-tagged), r/Coeliac, Coeliac Society chapters, dedicated coeliac bloggers |
| Allergy-aware blog | ×2.0 | Legally GF, GF Singapore blogs, European Coffee Trip (DF only, not GF) |
| General review | ×1.0 | Google Maps, TripAdvisor, Burpple, HungryGoWhere, Foody.vn, Riviu |
| Social / menu photo | ×1.0 | Instagram, Facebook — useful mostly for menu recency |
| Venue own | ×0.5 | Restaurant site, restaurant socials (marketing copy) |
| Reaction report | −5.0 | Credible first-person "got glutened" / "made me sick" — also caps GF at 2 |

## Recency decay
Applied to each piece of evidence based on its dated source.

| Age | Multiplier |
|---|---|
| < 18 months | ×1.0 |
| 18 months – 3 years | ×0.5 |
| > 3 years | ×0.3 |
| Undated | ×0.5 |

## Menu freshness

| Age | Multiplier | Note in output |
|---|---|---|
| < 3 months | ×1.0 | "fresh" |
| 3–12 months | ×0.7 | "aging" |
| > 12 months | ×0.3 | "stale — verify on arrival" |
| No menu found | n/a | Cap GF/DF at 3, note "review-only" |

## Menu sources (attempt in order)
1. Restaurant's own website (look for `/menu`, `/food`, linked PDFs)
2. Google Maps menu tab
3. Reservation platforms: OpenTable (AU/global), TheFork (AU/EU), Chope/Klook (SG), Quandoo
4. Local review platforms: Burpple, HungryGoWhere (SG); Foody.vn, Riviu (VN)
5. Instagram (`site:instagram.com <venue> menu`)
6. Facebook page (especially Vietnam)
7. Most recent Google review photo tagged "menu"

Record source URL and date in the output.

## Caps and special rules
- **Reaction report**: any credible first-person coeliac reaction → GF max = 2.
- **Menu-only assessment** (no usable reviews): cap GF and DF at 3, note "menu-based estimate".
- **Thin evidence** (< 2 independent sources): cap at 3, set `needs_in_person_verification = true`.
- **Oat-only plant milk**: DF cap = 2, explicit warning.
- **Naturally-GF cuisine trap**: Vietnamese and some SE Asian cuisines are *ingredient*-GF but *preparation*-risky. Soy sauce is wheat-based by default here; shared woks and fryers are standard. Do not inflate scores on cuisine type alone — see the GF evidence floor (max 2 without venue-specific evidence).
- **Multi-stall venues** (hawker centres, food courts): score named stalls where evidence exists; the venue line reports the best stall's scores and names it. With no stall-level evidence, GF ≤ 1 and DF from the baseline, capped at 3.
- **User's own notes** in the trip are not evidence and do not count as a source.

## Red-flag phrases on menus

**Gluten risks:**
- Soy sauce without "GF" / "tamari" note (default soy sauce contains wheat almost everywhere; especially baked into SG/VN/Asian cuisines)
- Oyster sauce, hoisin, teriyaki, black bean sauce
- "Fried in our house oil" (shared fryer unless specified)
- "Contains traces of gluten"
- Any baked item without GF callout
- "Crispy" / "tempura" / "battered"

**Dairy risks:**
- "Beurre blanc", "cream of…", "in butter", "au gratin"
- "Kaya" or "pandan custard" (SG / Thai-AU — usually has dairy)
- "Condensed milk" (common in Vietnamese coffee, Thai desserts)
- "Ghee" (still dairy-derived)
- Unspecified "pesto" (usually has parmesan)
- Roti, naan, pancake-style wraps when paired with custard / kaya — wheat AND dairy
- "Curry" with cream notation (some kitchens add cream to coconut curries — confirm coconut-only)

## Region-specific cuisine traps

- **SG / VN**: Default soy sauce contains wheat; oyster/hoisin/teriyaki/black bean sauces are common cross-contaminants. Naturally-GF dishes (pho, rice bowls) often prepped in wheat-shared woks/fryers.
- **Thai (incl. Thai-AU venues)**: Same soy/oyster/sauce risks. "Crispy" items often coated in wheat batter — confirm rice flour. Pandan desserts (custard, roti) almost always contain dairy + wheat. Coconut-based curries (massaman, jungle, tom kha) are usually safe but confirm no fish-sauce-with-wheat-additives or cream additions.
- **AU shared-kitchen Asian restaurants**: Higher likelihood of tamari sub on request than in SG/VN; Coeliac Australia accreditation programme is the strongest single signal when present.

## Favorite flag
`favorite = true` when `gf_score >= 4 AND df_score >= 3`.

## Food rating (overall food/experience quality, separate from GF/DF)

This is the venue's general quality, not allergy-related. Pull from:
- Google Maps rating + count (primary, weighted by review count)
- TripAdvisor rating + count
- Editorial press (Broadsheet, CityMag, Qantas Travel Insider, Good Food Guide hats, etc.)

| Score | Threshold |
|---|---|
| 5 | Google ≥ 4.5 with 500+ reviews AND positive editorial press, OR awarded (hat / Good Food Guide / similar) |
| 4 | Google ≥ 4.3 with 200+ reviews, mostly positive editorial |
| 3 | Google ≥ 4.0, mixed editorial or no editorial |
| 2 | Google 3.5–4.0, or 4.0+ with notable repeated complaints (rushed, noisy, inconsistent) |
| 1 | Google < 3.5 |

Display as 1-decimal score next to stars: e.g. `Food ★★★★★ (4.6/5)`. Cite Google review count alongside.

## Pricing

Use Google `price_level` if available, plus the most concrete per-person figure:

| Symbol | Google price_level | Approx AUD per person | Notes |
|---|---|---|---|
| $ | 1 | < $25 | hawker, casual cafe, banh mi joint |
| $$ | 2 | $25–55 | mid-tier restaurant, brunch, casual dining |
| $$$ | 3 | $55–110 | nicer restaurant, set menu territory |
| $$$$ | 4 | $110+ | fine dining, tasting menus, hatted |

Display as `Price: $$$ · <concrete figure if known>` — e.g. `Price: $$$ · Tuk Tuk $72pp`. If no concrete figure, just the symbol.

## Category mapping (for TRIP `category` field, when API wired in later)
- **Food** — restaurants, hawker stalls, bakeries, brunch cafes, dessert shops, and any venue with a proper food menu (composed dishes, mains, brunch/lunch service)
- **Coffee** — venues where coffee/tea is the primary draw and food is incidental: specialty coffee roasters, matcha/tea bars, espresso bars with only pastries/snacks
- **Play** — playgrounds, kid-friendly parks, attractions
- Default to **Food** if ambiguous.
