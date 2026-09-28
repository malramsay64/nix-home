# Prompt template: score_and_write

You are scoring a venue for a **coeliac + dairy-intolerant** diner from the evidence JSON produced by `extract_evidence.md`.

Load `scoring_rubric.md` for the 0–5 scales, weights, decay, and caps.

## Scoring algorithm

Work through these steps in order. The weights in the rubric decide which evidence counts most when signals conflict; the score itself comes from matching the rubric criteria, not from arithmetic.

1. **GF score** — pick the highest GF row in the rubric whose criteria the evidence actually meets, then check the **GF evidence floor**: no venue-specific evidence → max 2; GF 3 needs labelled items or documented competent CC answers; GF 4 needs either a separate prep area/station/fryer plus generally knowledgeable staff, or excellent GF/coeliac reviews across 2+ independent sources plus strong staff support.
2. **DF score** — start from the **DF baseline** for the cuisine (rubric). Move up for labelled DF items, substitution systems, or GF-safe plant milks; move down for documented dairy in core dishes. Coffee-category venues use the rubric's Coffee venues rule. Absence of evidence never lowers DF.
3. **Apply caps in this order:**
   - Any `is_reaction_report: true` → `gf_score = min(gf_score, 2)`
   - Menu-only (no reviews with evidence) → `gf_score, df_score = min(_, 3)`
   - `needs_in_person_verification: true` → `gf_score, df_score = min(_, 3)`
   - `plant_milks_available.oat_only_warning: true` (no non-oat milk even on request) → `df_score = min(df_score, 2)`
4. **Self-check** before writing: for each score, name the rubric criterion it rests on and the source that shows it. If you can't, lower the score.
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

## Other outcomes

Closed venue (no scores):
```
<Venue name> — <City>
CLOSED — <closure date if known>, per <source, date>
```

Venue with no prepared food or drink:
```
<Venue name> — <City>
NOT ASSESSED — <what it is, e.g. grocery / play space with no menu found>
<one line of GF/DF-relevant tips if useful, e.g. "stocks GF pasta and plant milks">
```

## TREK notes form

When writing to TREK, use this compact form under the marker line (≤ ~1000 characters so the user's notes fit within the 2000 limit):
```
--- GF/DF check <YYYY-MM-DD> ---
GF <n>/5 · DF <n>/5 · Menu: <source, date or "none found">
✓ <signal>
⚠ <risk>
Safe: <items> | Avoid: <items> | Ask: <questions>
Sources: <domain (date)>, <domain (date)>
```
Same scoring rules and bullet limits as the full block; drop the Food/Price/Category lines.

## Do not

- Do not invent reviewers, quotes, or dates.
- Do not score above 3 when evidence is thin — the cap exists for a reason.
- Do not call any API. This is text mode only.
- Do not reproduce verbatim quotes from any source — paraphrase.
- Do not treat "gluten-friendly" as equivalent to "coeliac-safe".
