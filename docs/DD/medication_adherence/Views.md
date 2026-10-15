# Views — M22 / Lịch dùng thuốc

## M22-V01 — Onboarding “Thông tin cần lưu ý”

Location: existing `ExtrasStep`, accordion “Thực phẩm bổ sung hoặc thuốc”.

| State | Behavior |
|---|---|
| Empty | Explain optional setup; show add action. Existing category picker/note remain. |
| Editing | Each row shows exact name, daily time chips, add-time and remove actions. |
| Invalid | Inline Vietnamese message for blank name or missing time; no partial save. |
| Saving | Keep entered values visible; commit with onboarding profile transaction. |
| Success/review | Review step lists each medicine and its times; no medicine is required. |
| Error | Preserve input and show existing onboarding save error. |

Copy requirements: explain that this is a reminder schedule entered by the
user, not a prescription. Do not ask for dose, diagnosis, or treatment advice.

## M22-V02 — Cài đặt thông báo / Lịch nhắc uống thuốc

Location: section within existing Notification Settings page.

| State | Behavior |
|---|---|
| Loading | Show existing settings loading state. |
| Empty | Explain that no medicine reminders were added during onboarding; show an action to add a medicine and schedule. |
| Success | List names and times in-app, with actions to add a medicine/schedule, rename a medicine, edit times, pause/resume, and delete a schedule. |
| Master disabled | Preserve row states and explain that all notifications are paused by the global switch. |
| Permission denied | Preserve schedule; show device-permission guidance and retry path. |
| Error | Keep existing data; expose retry and safe Vietnamese error copy. |

Tap on a medication reminder opens this page. Screen-reader labels must include
the medicine name only inside the app; notification copy/payload stays generic.

