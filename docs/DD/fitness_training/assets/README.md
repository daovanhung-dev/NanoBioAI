# M32 content asset manifest — Draft candidates used by PO-directed pilot

Candidate records and original images are bundled for the PO-directed pilot, with a visible in-app disclosure that content awaits review. They are not clinically approved or release-approved. Tech/Privacy, Clinical and QA sign-off remains pending.

## Pilot target

| Content | Draft pack | Required fields/assets | Review |
|---|---:|---|---|
| Exercises | 24: 16 gym, 8 home | Stable ID, Vietnamese instructions, steps, muscles, level, venue, gear IDs, sets/reps/rest bounds, cautions, original illustration, optional YouTube video | Clinical/QA pending |
| Equipment | 10 | Stable ID, category, gym filter, original illustration, accessible description | PO/QA pending |
| Recipes | 35: 7 per meal window | Stable ID, Vietnamese original recipe, ingredients/grams, meal group, portions, draft nutrients, allergens, original illustration | Clinical/Privacy pending |
| Ingredients | 47 | Stable ID, food group, display name, FDC ID, nutrients per 100 g, source version/date, allergen flags | Nutrition/Clinical pending |
| Category icons | 4 groups | Protein, carbohydrate, fruit/vegetable, fat source | Design pending |
| YouTube videos | Candidate search only; optional per exercise | Video ID, creator/title, public/embed check date, fallback URL; no downloaded bytes or thumbnail | Manual review pending; IFrame playback must pass on Android/iOS |

## Draft artifacts present

- `fitness_exercise_equipment_draft_v1.json`: 24 exercise and 10 equipment candidates. Each record points to a source image atlas and a 1-based cell index. Two exercise atlas sheets and one equipment sheet contain the original generated illustrations.
- `fitness_recipes_draft_v1.json`: 35 original recipe candidates, seven per meal window, with ingredient weights and arithmetic nutrient estimates derived from the ingredient file. Each record points to its meal atlas and cell index. These values are not approved nutrition prescriptions.
- `fitness_ingredients_draft_v1.json`: 47 candidate ingredients with FDC ID, English source description, nutrients per 100 g and allergen tags. Each ingredient also points to one of four original food-group icons.
- `fitness_image_atlases_draft_v1.json`: cell-to-record mapping, atlas grid, asset path and provenance/review status for all image sheets.
- `images/atlas/`: nine original generated atlases containing 69 distinct exercise/equipment/recipe illustrations and four category icons. Atlas sheets are kept whole; no third-party image search results, downloaded thumbnails or video frames are included.
- `style_board_draft_2026-10-01.png`: earlier art-direction sample; the atlas pack now provides the catalog illustration candidates.

The cell index is 1-based, row-major. The atlas manifest records the corresponding catalog ID. The in-app renderer crops atlas panels using manifest grids and gutters. Widget tests cover equipment illustration semantics; detailed crop quality, screen reader, text scale and Android/iOS player behavior remain QA acceptance work.

## Sources and rights handling

- Exercise/recipe copy and atlas illustrations were created for this NanoBio draft. Generated art used no supplied or downloaded reference images, branded machines, logos, cookbook text or third-party photos. The asset terms/attribution review remains pending; this process does not guarantee zero copyright risk.
- Nutrition facts are static candidates from USDA FoodData Central, FNDDS 2021–2023, October 2024 release. Keep FDC IDs and source version. Do not add a USDA API key. Sources: [FDC downloadable datasets](https://fdc.nal.usda.gov/download-datasets/) and [FDC API specification/license](https://fdc.nal.usda.gov/api-spec/fdc_api.html).
- YouTube discovery was done in Chrome. Two seated-row videos were found, but iframe playback could not be verified in the current browser client (player error 153); they are not approved catalog videos. Never download/rehost video or thumbnail. Final playback must use the official YouTube IFrame player and include an open-in-YouTube fallback.
- PO-confirmed direction (2026-10-05): a video is optional and never blocks an exercise entry. If no approved video is available or playback fails, use the original illustration and written steps, with an open-in-YouTube link when an approved video URL exists. The first-release platform target is Android/iOS, pending QA/Tech validation.
- Wikimedia Commons is not used in this pilot. Any future use requires per-file license, attribution and rights review.

## Status

The text/nutrition candidate records and original illustration panels are present with source IDs and provenance metadata and are read by the runtime pilot. USDA values and recipes remain candidate nutrition data; clinical content validation, rights review, video approval, platform/accessibility QA and cross-functional sign-off remain outstanding. Keep the catalog marked as pilot data until those reviews close.
