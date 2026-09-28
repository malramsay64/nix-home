---
name: gf-df-trip
description: Vet a restaurant, cafe, or play venue anywhere in the world for a coeliac diner with a dairy intolerance. Takes a Google Maps URL or place name + city, optionally a menu image, and produces a structured verdict block covering GF and DF confidence, evidence, safe dishes, and red flags. Source coverage is richest for Singapore, Vietnam, and Australia; other regions fall back to universal sources. Use when the user asks to "vet", "check", "score", or "add to trip" a food, coffee, or play venue.
---

# GF/DF Trip Vetting

## Who this is for
The primary diner is a **coeliac** (medical, not preference) with a **dairy intolerance**. Scoring is strict on cross-contamination. **Oat milk is not an acceptable DF option** — coeliac CC and avenin risk.

## Inputs
- **Required**: Google Maps URL *or* place name + city + country.
- **Optional**: menu image/PDF upload, category override (Food / Coffee / Play).

## Regions
Source tuning by region:
- **Singapore, Vietnam, Australia** — region-specific blogs, review platforms, and cuisine notes in `sources.yaml` and `scoring_rubric.md`.
- **Anywhere else** — universal sources only (Find Me Gluten Free, r/Coeliac, Google Maps, TripAdvisor, Coeliac UK / Coeliac Australia search). Note thinner coverage in the verdict.

## Workflow

1. **Normalise input** — extract venue name, city, country. If a Google Maps URL is given, keep it for later use with TRIP. Identify which region's source tuning applies (SG / VN / AU / other).
2. **Fetch the most recent menu** per the hierarchy in `scoring_rubric.md` §Menu sources. Record source and date. If user uploaded a menu, use that as primary and still try to find the online menu for freshness comparison.
3. **Gather evidence** by running `prompt_templates/extract_evidence.md` across the sources listed in `sources.yaml`. Use `web_search` and `web_fetch`.
4. **Score** by running `prompt_templates/score_and_write.md` against the extracted JSON and `scoring_rubric.md`.
5. **Output the verdict block as plain text** — do NOT call any TRIP API yet. (API integration is a later iteration; keep the skill text-mode for now.)

## Output

Print the verdict block (template in `prompt_templates/score_and_write.md`) followed by the raw sources list with dates. The user is using this output manually to test criteria and will paste into TRIP by hand for now.

## Guardrails
- If a source cannot be found or accessed, say so explicitly — do not fabricate reviews, quotes, or dates.
- If fewer than 2 independent sources exist, cap both scores at 3 and flag "needs in-person verification".
- If any credible reaction report is found, GF is capped at 2 regardless of positive signals.
- If the venue is outside a region with specific tuning (SG / VN / AU), note "limited regional source coverage" in the verdict and rely on universal sources.
- Keep evidence quotes under 15 words each and paraphrase rather than quoting verbatim.

## Non-goals
- No automated posting to TRIP (yet).
- No bookings, no directions, no price tracking.
- No scoring of vegetarian/vegan beyond what affects DF.
