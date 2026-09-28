# Prompt template: extract_evidence

You are extracting GF and DF evidence for a **coeliac + dairy-intolerant** diner. Your output is a structured JSON object. **Do not score yet — extraction only.**

## Context you will receive
- Venue name and city
- Review snippets, blog paragraphs, menu text
- Optional: menu image or PDF
- Source URL and date for each snippet

## Extraction rules

1. **Paraphrase all quotes to under 15 words.** Never reproduce verbatim.
2. **Mark `is_coeliac_reviewer: true` only** when the reviewer explicitly self-identifies as coeliac / celiac. "GF" or "gluten-free" alone does not qualify.
3. **Weight each piece of evidence** per `sources.yaml` tier × recency decay (see rubric).
4. **Reaction reports** — first-person credible "got glutened / made me sick / had a reaction" → `is_reaction_report: true`. Vague second-hand complaints do not qualify.
5. **Oat milk**: if the only plant milk is oat, flag it separately. Do not include oat in `plant_milks_available` as a positive DF signal — list it with a note.
6. **Vague positive claims** ("they have GF options") get weight 0.5 unless corroborated by specifics.
7. **Menu evidence** is separate from review evidence — don't double-count. A GF label on the menu is `menu.gf_labelled_items`, not a gf_evidence entry.

## Output JSON shape

```json
{
  "venue": "",
  "city": "",
  "country": "",
  "menu": {
    "source": "venue_site | google_maps | instagram | facebook | burpple | foody | user_upload | none",
    "source_url": "",
    "date": "YYYY-MM-DD or null",
    "staleness": "fresh | aging | stale | unknown",
    "gf_labelled_items": [],
    "df_labelled_items": [],
    "separate_gf_menu": true,
    "allergen_key_present": true,
    "red_flag_ingredients": [],
    "notes": ""
  },
  "gf_evidence": {
    "positive": [
      {
        "paraphrase": "under 15 words",
        "source": "",
        "source_tier": "coeliac_specialist | allergy_blog | general_review | social | venue_own",
        "date": "YYYY-MM-DD or null",
        "is_coeliac_reviewer": true,
        "weight": 3.0
      }
    ],
    "negative": [
      {
        "paraphrase": "",
        "source": "",
        "date": "",
        "is_reaction_report": false,
        "weight": 1.0
      }
    ]
  },
  "df_evidence": {
    "positive": [],
    "negative": []
  },
  "plant_milks_available": {
    "soy": false,
    "almond": false,
    "coconut": false,
    "rice": false,
    "macadamia": false,
    "oat": false,
    "oat_only_warning": false
  },
  "safe_dish_candidates": [],
  "avoid_dish_candidates": [],
  "open_questions": [],
  "source_count_independent": 0,
  "needs_in_person_verification": false,
  "extraction_notes": ""
}
```

## Checks before returning

- `source_count_independent` counts distinct domains / platforms, not individual reviews.
- Set `needs_in_person_verification: true` if `source_count_independent < 2`.
- If the menu wasn't found, set `menu.source = "none"` and populate `menu.notes` accordingly.
- Do not invent dates. If unknown, use `null` and rely on the undated recency multiplier.
- Keep `extraction_notes` for anything the scorer should know (e.g. "venue recently changed ownership", "menu in Vietnamese only").
