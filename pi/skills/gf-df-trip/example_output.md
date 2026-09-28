# Example outputs (for format reference only)

Both venues below are **fictional**, used only to show the output shape. Replace with real runs during testing.

---

## Example 1 — rich evidence, good venue

```
The Sprout Pantry — Singapore (Tiong Bahru)
GF ★★★★☆ (4/5) · DF ★★★★☆ (4/5)
Verified: 2026-04-20
Menu: venue_site, 2026-03-02 — fresh

✓ Dedicated GF prep bench confirmed by staff and 4 coeliac reviewers
✓ Soy and almond milk as standard, butter subs on request
⚠ Shared fryer for one side dish — staff will flag on ordering
⚠ Kaya toast contains dairy unless requested vegan

Safe bets: GF sourdough avo toast, chia bowl, matcha w/ soy, tofu scramble
Avoid: fish & chips, kaya toast (default), anything with pesto
Open questions: confirm which fryer items are shared today

Category suggestion: Coffee
Favorite: yes

---
Sources:
- Find Me Gluten Free, 2025-11-14, tier: coeliac_specialist
- r/Coeliac thread, 2025-08-02, tier: coeliac_specialist
- Legally GF blog, 2026-01-20, tier: allergy_blog
- Google Maps reviews (5 filtered), 2025-06 to 2026-04, tier: general_review
- Venue site menu, 2026-03-02, tier: venue_own
```

---

## Example 2 — thin evidence, Vietnam

```
Pho Lan — Hanoi (Ba Dinh)
GF ★★★☆☆ (3/5) · DF ★★★★☆ (4/5)
Verified: 2026-04-20
Menu: facebook, 2025-11-10 — aging

✓ Owner responds to FB comments about GF soy sauce on request
✓ Coconut milk used in several dishes, no dairy in broth
⚠ Default soy sauce is wheat-based — must request tamari
⚠ Shared woks likely — no dedicated GF protocol described

Safe bets: pho ga (plain), goi cuon, bun ga (ask no soy)
Avoid: anything fried, pre-marinated meats, hu tieu nam vang
Open questions: confirm tamari availability, confirm no soy sauce in broth

Category suggestion: Food
Favorite: no

---
Sources:
- Google Maps reviews (2 filtered), 2025-09 to 2026-02, tier: general_review
- Venue Facebook page, 2025-11-10, tier: venue_own

Note: source_count_independent = 2, right at threshold. Needs in-person verification.
```

---

## Example 3 — oat-only DF cap

```
Kopi & Co — Singapore (Joo Chiat)
GF ★★☆☆☆ (2/5) · DF ★★☆☆☆ (2/5)
Verified: 2026-04-20
Menu: instagram, 2026-02-18 — fresh

✓ Staff know what coeliac means, will wipe surfaces on request
⚠ Oat-only plant milk — not GF-safe for coeliacs; ask for soy/almond or bring own
⚠ Shared fryer, no separate GF prep area

Safe bets: black coffee, espresso w/ no milk
Avoid: anything from the bakery case, hot food items
Open questions: any chance they stock soy? bring backup plant milk

Category suggestion: Coffee
Favorite: no

---
Sources:
- Google Maps reviews (3 filtered), 2025-10 to 2026-03, tier: general_review
- Venue Instagram, 2026-02-18, tier: venue_own
```

---

## What to look at during testing

1. **Does the rubric distinguish 3 vs 4 reliably?** — the coeliac-vs-GF-aware boundary is where most errors happen.
2. **Does oat-only actually cap at DF 2 in practice?** — verify the warning appears every time.
3. **Does thin evidence get capped?** — run a Vietnam venue with almost no English reviews and check.
4. **Are safe bets genuinely safe?** — spot check a few against the menu photos.
5. **Is the category mapping right?** — cafes with good food often ambiguate Coffee vs Food.
