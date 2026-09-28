# Prompt template: score_and_write

You are scoring a venue for a **coeliac + dairy-intolerant** diner from the evidence JSON produced by `extract_evidence.md`.

Load `scoring_rubric.md` for the 0–5 scales, weights, decay, and caps.

## Scoring algorithm

1. **GF raw score**
   - Sum `gf_evidence.positive[].weight`
   - Subtract sum of `gf_evidence.negative[].weight`
   - Add menu weight: +1.0 per `menu.gf_labelled_items` up to +3.0 max, times menu freshness multiplier
2. **DF raw score**
   - Same as above with DF evidence
   - Add +1.0 per GF-safe plant milk available (soy, almond, coconut, rice, macadamia), max +3.0
   - Do not credit oat milk. If `oat_only_warning: true`, do not add any plant milk points.
3. **Map raw → 0–5 band** using judgement against the rubric labels. Round to whole number.
4. **Apply caps in this order:**
   - Any `is_reaction_report: true` → `gf_score = min(gf_score, 2)`
   - Menu-only (no reviews with evidence) → `gf_score, df_score = min(_, 3)`
   - `needs_in_person_verification: true` → `gf_score, df_score = min(_, 3)`
   - `plant_milks_available.oat_only_warning: true` → `df_score = min(df_score, 2)`
5. **Derive favorite flag**: `favorite = gf_score >= 4 AND df_score >= 3`
6. **Food rating**: independent of GF/DF — score per rubric §Food rating using Google + TripAdvisor + editorial. Display 1-decimal score.
7. **Pricing**: from Google `price_level` and concrete per-person figures; display per rubric §Pricing.

## Output — verdict block

Print exactly this format. No preamble, no trailing commentary. Two trailing line breaks then the raw sources list.

```
<Venue name> — <City>
GF <stars> (<n>/5) · DF <stars> (<n>/5) · Food <stars> (<n.n>/5)
Price: <symbol> · <concrete per-person figure if known>
Verified: <today ISO date>
Menu: <menu.source>, <menu.date or "undated"> — <freshness>

✓ <positive signal, <12 words>
✓ <positive signal>
⚠ <red flag>
⚠ <red flag>

Safe bets: <comma list, 3–6 items>
Avoid: <comma list>
Open questions: <comma list or "none">

Category suggestion: Food | Coffee | Play
Favorite: yes | no

---
Sources:
- <source name>, <date>, tier: <tier>
- ...
```

## Block rules

- **Stars**: filled = score, empty = remainder out of 5. Use ★ and ☆.
- **Maximum 4 bullets total** (✓ and ⚠ combined) — prioritise the most decision-relevant.
- If DF was capped due to oat-only: include explicit warning: `⚠ Oat-only plant milk — not GF-safe for coeliacs; ask for soy/almond or bring own`.
- If a reaction report capped GF: include warning bullet: `⚠ Reaction report on <date> — <source>`.
- If `needs_in_person_verification`: append to Open questions: `confirm GF protocol on arrival`.
- Each bullet ≤ 12 words.
- Safe bets and Avoid must be derived from `safe_dish_candidates` / `avoid_dish_candidates`, plus menu analysis. If none, write `—`.
- Category suggestion per rubric §Category mapping.

## Do not

- Do not invent reviewers, quotes, or dates.
- Do not score above 3 when evidence is thin — the cap exists for a reason.
- Do not call any API. This is text mode only.
- Do not reproduce verbatim quotes from any source — paraphrase.
- Do not treat "gluten-friendly" as equivalent to "coeliac-safe".
