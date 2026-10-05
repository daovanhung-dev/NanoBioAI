# Views — M32 / Chế độ luyện tập

## View registry

| ID | View | Entry | Main actions | State owner |
|---|---|---|---|---|
| M32-V01 | FeatureHub shortcut | FeatureHub | Open training | FeatureHub/router |
| M32-V02 | Profile review and eligibility | M32-V01 | Verify age, edit/confirm profile | Intake controller |
| M32-V03 | Training preferences | M32-V02 | Goal, level, schedule, venue, diet, sleep | Intake controller |
| M32-V04 | Equipment and food groups | M32-V03 | Select equipment/food groups | Catalog controller |
| M32-V05 | Generate/progress state | M32-V04 | Generate or retry | Program controller |
| M32-V06 | Program preview/detail | M32-V05 | Inspect 4 weeks, confirm apply | Program controller |
| M32-V07 | Weekly check-in/replan preview | Week end | Check-in, review, confirm | Program controller |

## Interaction and states

- V01 is a compact FeatureHub tile connected to the v1 route by PO direction; M32 remains Draft and reviewer approval is pending.
- V02 shows onboarding values for review and checks full self-declared DOB locally. Missing/future/under-18 values block before quota/AI. The pilot check is spoofable and is not trusted server proof; DOB is not sent to Gemini.
- V03 captures goal, experience, workout days/session duration, weekly availability, injury/movement restrictions, food allergies, food groups, meal windows and sleep/wake goals.
- V04 Gym renders selectable equipment cards with original illustrations and semantic labels; home renders home-only movements, initially bodyweight. Ingredient groups have category icons. Empty filtered catalog blocks generation. Asset/content review remains pending.
- V05 shows only meaningful loading, quota, network and AI validation states; no fake progress or sample health data.
- V06 shows program week/day details, exercise instructions and an optional YouTube IFrame only for an approved available video ID; if unavailable, show original illustration, steps and an open/search-on-YouTube action. Current catalog has no approved embed candidate. Recipes/portions and sleep routine remain visible. Confirm applies only current week; cancel leaves existing schedule intact.
- V07 records effort/soreness scores, displays a remaining-week proposal and change preview. Member confirm applies; Guest replan is unavailable. Skip keeps the saved program.

The first-release target is Android/iOS, pending QA/Tech platform review; Web/desktop are outside v1. All views need loading, ready, empty, error/offline, quota-denied, age-ineligible and stale-version states where applicable. Use Vietnamese consumer copy; no internal API/database terms. Interactive controls meet 48 dp target, include screen-reader semantics, work at increased text scale and respect reduced motion.
