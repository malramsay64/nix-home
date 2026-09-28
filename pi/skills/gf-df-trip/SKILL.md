---
name: gf-df-trip
description: Vet a restaurant, cafe, or play venue anywhere in the world for a coeliac diner with a dairy intolerance. Takes a Google Maps URL, place name + city, or a TREK trip/place, optionally a menu image, and produces a structured verdict block covering GF and DF confidence, evidence, safe dishes, and red flags. Can write verdicts into TREK place notes. Source coverage is richest for Singapore, Vietnam, and Australia; other regions fall back to universal sources. Use when the user asks to "vet", "check", "score", or "add to trip" a food, coffee, or play venue.
---

# GF/DF Trip Vetting

## Who this is for
The primary diner is a **coeliac** (medical, not preference) with a **dairy intolerance**. Scoring is strict on cross-contamination. **Oat milk is not an acceptable DF option** — coeliac CC and avenin risk.

## Inputs
- **Required**: Google Maps URL, *or* place name + city + country, *or* a TREK trip / place ID.
- **Optional**: menu image/PDF upload, category override (Food / Coffee / Play).

## Regions
Source tuning by region:
- **Singapore, Vietnam, Australia** — region-specific blogs, review platforms, and cuisine notes in `sources.yaml` and `scoring_rubric.md`.
- **Anywhere else** — universal sources only (Find Me Gluten Free, r/Coeliac, Google Maps, TripAdvisor, Coeliac UK / Coeliac Australia search). Note thinner coverage in the verdict.

## Workflow

1. **Normalise input** — extract venue name, city, country. Keep any Google Maps URL / place ID. Identify which region's source tuning applies (SG / VN / AU / other).
2. **Check the venue is operating** — look for closure news, "permanently closed" on Google/TripAdvisor, and whether reviews continue within the last 6 months. If closed, output the CLOSED block (see `score_and_write.md`) and stop. If it moved, assess the current location and say so.
3. **Classify the venue**:
   - *Single kitchen* (restaurant, cafe, stall) → normal flow.
   - *Multi-stall* (hawker centre, food court, market) → assess named stalls individually where evidence exists; the venue verdict is the best stall(s) plus centre-wide risks. Never score the whole centre as one kitchen.
   - *No prepared food/drink* (grocery, play space with no menu, shop) → output the NOT ASSESSED block and stop.
4. **Fetch the most recent menu** per `scoring_rubric.md` §Menu sources. Record source and date. A user-uploaded menu is primary; still look for the online menu for freshness comparison.
5. **Gather evidence** with `prompt_templates/extract_evidence.md` across the sources in `sources.yaml`.
6. **Score** with `prompt_templates/score_and_write.md` against the extracted JSON and `scoring_rubric.md`.
7. **Output** the verdict block. Only write to TREK if the user asked for it (see below).

## Output

Print the verdict block (template in `prompt_templates/score_and_write.md`) followed by the raw sources list with dates.

## Writing to TREK (only when asked)

TREK is the trip planner, available through the `trek` MCP server. Rules:

- **Find places by ID, not by text search of a trip summary.** Use `list_places` (optionally `search=`) and take the `id` from the matching object. Before writing, confirm the place's `name` matches the venue; after writing, confirm the `name` in the response. Stop on any mismatch.
- **Search before creating.** Before `create_place`, check `list_places(search=<name>)` and any matching `google_place_id`. Prefer updating an existing place over creating a duplicate.
- **Append, never replace.** Keep the user's existing notes verbatim, then add the verdict under the marker line `--- GF/DF check <YYYY-MM-DD> ---`. On a re-run, replace only the text from an existing marker to the end; everything above the marker is the user's.
- **Fit the limit.** `notes` is capped at 2000 characters. Shorten the verdict (drop sources to domain names, fewer bullets), never the user's notes.
- **Only touch `notes`** unless the user asks otherwise. Never add phone numbers, websites, or addresses that did not come from a fetched page or Google place data.
- **Batch runs**: gather venues with `list_places`, filtering to categories Restaurant and Coffee plus any place in another category whose name suggests food or drink (cafe, café, coffee, bakery, restaurant, food, pho, bánh, bún). Dedupe by name/`google_place_id` before assessing.

## Guardrails
- If a source cannot be found or accessed, say so explicitly — do not fabricate reviews, quotes, dates, or contact details.
- Notes already in TREK or in the user's itinerary are **not evidence** — they are the user's own prior judgement and never count toward sources or scores.
- If fewer than 2 independent sources exist, cap both scores at 3 and flag "needs in-person verification".
- If any credible reaction report is found, GF is capped at 2 regardless of positive signals.
- If the venue is outside a region with specific tuning (SG / VN / AU), note "limited regional source coverage" in the verdict and rely on universal sources.
- Keep evidence quotes under 15 words each and paraphrase rather than quoting verbatim.

## Non-goals
- No bookings, no directions, no price tracking.
- No scoring of vegetarian/vegan beyond what affects DF.
