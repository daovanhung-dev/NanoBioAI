# Stitch Green Wellness — DD readiness và evidence pack

| Thuộc tính | Giá trị |
|---|---|
| Mã tài liệu | `GW-DD-READINESS-001` |
| Ngày chốt bằng chứng | 2026-08-08 |
| Trạng thái | **Draft — readiness/evidence only; không phải DD Approved** |
| Phạm vi | Wave 0 cho các năng lực wellness mới, M20–M29 và delta M05/M06/M07/M09/M10/M11/M12/M14/M19/M30 |
| Không thuộc phạm vi | Tạo schema/migration/RLS/RPC, provider/repository mới, route nghiệp vụ mới, tích hợp thiết bị/OCR/AI/chat hoặc tự ký duyệt thay owner |

## 1. Mục đích và cách đọc

Tài liệu này là cổng kiểm soát trước khi tạo hoặc cập nhật DD. Nó ghi lại nguồn hiện có, trạng thái phê duyệt, quyết định còn thiếu, UI được phép làm và phần runtime phải fail closed. Tài liệu **không** thay thế bộ DD module bắt buộc và không làm tăng phần trăm hoàn thành DD hay business coding.

Thứ tự nguồn chuẩn cho đợt refactor:

1. DD/BD đã Approved quyết định nghiệp vụ, access, dữ liệu và side effect hiện hữu.
2. [Stitch Green Wellness coding plan](../../../.codex/design/15_CODING_PLAN.md) và yêu cầu triển khai ngày 2026-08-08 quyết định phạm vi đề xuất mới, nhưng không tự tạo approval.
3. [`screen.png`](./) quyết định bố cục; `code.html` quyết định typography/token; cả hai chỉ là nguồn presentation.
4. [Implementation registry](./IMPLEMENTATION_REGISTRY.md) quyết định owner/surface/evidence của 76 mẫu, nhưng không phải bằng chứng DD hoặc clinical/privacy approval.

Nguồn DD/BD liên quan:

- [DD registry M01–M30](../../DD/README.md).
- [BD product flow M01–M19](../../BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md).
- [BD Advanced Health M20–M29](../../BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md), trạng thái `Draft - UI catalog shell approved`.
- [DD creation checklist](../../checklist/checklist_create_DD.md) và [DD completion checklist](../../checklist/checklist_complete_DD.md).
- [Route matrix](../../../.codex/design/14_ROUTE_MATRIX.md) và [UI acceptance checklist](../../../.codex/design/16_ACCEPTANCE_CHECKLIST.md).

## 2. Quy ước trạng thái

| Ký hiệu | Ý nghĩa |
|---|---|
| `BASE APPROVED` | DD hiện hữu đã Approved cho baseline trước Stitch; không bao phủ delta mới nếu delta thay đổi hành vi, dữ liệu, quyền hoặc side effect. |
| `SHELL ONLY` | Chỉ tên/thứ tự/tier, access-aware navigation và placeholder không side effect được phê duyệt. |
| `REQUESTED` | Có yêu cầu sản phẩm/implementation plan, nhưng chưa có BD/DD hoàn chỉnh và chưa có approval record. |
| `PENDING` | Chưa tìm thấy approval record có owner, version, ngày và phạm vi rõ ràng. |
| `UI ALLOWED` | Có thể refactor visual hoặc giữ placeholder/trạng thái trung thực trong contract hiện hữu. |
| `DD BLOCKED` | Không được tạo nghiệp vụ/runtime tương ứng cho tới khi DD Approved và các quyết định ảnh hưởng safety/privacy/access được chốt. |

Một approval hợp lệ cho phạm vi này phải ghi rõ: owner, vai trò, phiên bản BD/DD, quyết định (`Approved`, `Rejected`, `Changes requested`), ngày, phạm vi và đường dẫn evidence. Tin nhắn yêu cầu triển khai, ảnh Stitch, HTML, route có sẵn hoặc widget test **không** thay thế approval record.

## 3. Gate bắt buộc

| ID | Gate | Điều kiện qua gate |
|---|---|---|
| `GW-GATE-01` | Source gate | Có BD/BRD hoặc addendum versioned, trace được scope, actor, BR/AC/UC, in/out và dependency. |
| `GW-GATE-02` | DD structure gate | Có đủ `README.md`, `Overall.md`, `List_Features.md`, `Function_List.md`, `Views.md`, `Import_File.md`, diagrams, assets và changelog; không có placeholder giả hoàn tất. |
| `GW-GATE-03` | Decision gate | Không còn open question làm thay đổi safety, privacy, access, schema, retention, AI, chat crypto hoặc acceptance. |
| `GW-GATE-04` | Owner gate | PO, Tech, QA, Clinical và Privacy ký đúng phiên bản. `N/A` chỉ hợp lệ khi owner chịu trách nhiệm ghi lý do; agent không tự gán `N/A`. |
| `GW-GATE-05` | Runtime gate | API/schema/RLS/RPC/idempotency/error/observability/test traceability đã được thiết kế và Approved trước migration/client. |
| `GW-GATE-06` | Evidence gate | Có unit/widget/integration, RLS sandbox, privacy leak, accessibility và real-device evidence tương ứng với rủi ro. |
| `GW-GATE-07` | UI gate | Visual work không tạo dữ liệu mẫu như dữ liệu thật, không unlock entitlement và không gọi API/AI/device khi capability bị block. |
| `GW-GATE-08` | Cutover gate | Acceptance 76/76 chỉ cho phép cutover design system; không tự mở business flag của module chưa Approved. |

## 4. Ma trận approval owner

`Chưa ghi nhận` nghĩa là không có evidence approval cho **phạm vi mới** trong các nguồn đã rà soát. Với delta của module cũ, chữ `Baseline` chỉ xác nhận DD cũ vẫn giữ hiệu lực.

### 4.1. Năng lực wellness mới

| Readiness ID | Năng lực | PO | Tech | QA | Clinical | Privacy | Kết luận |
|---|---|---|---|---|---|---|---|
| `GW-NEW-01` | `DAILY_WELLNESS_JOURNAL` | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | `REQUESTED / DD BLOCKED` |
| `GW-NEW-02` | `MEMBER_WELLNESS_REPORTS` | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | `REQUESTED / DD BLOCKED` |
| `GW-NEW-03` | `SELF_CARE_SESSIONS` | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | `REQUESTED / DD BLOCKED` |
| `GW-NEW-04` | `SLEEP_TRACKING` | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | `REQUESTED / SHELL ONLY` |
| `GW-NEW-05` | `STRESS_TRACKING` | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | Chưa ghi nhận | `REQUESTED / SHELL ONLY` |

### 4.2. Advanced Health M20–M29

| Readiness ID | Module | PO | Tech | QA | Clinical | Privacy | Kết luận |
|---|---|---|---|---|---|---|---|
| `GW-AHF-20` | M20 `BLOOD_PRESSURE_TRACKING` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-21` | M21 `HEART_OXYGEN_TRACKING` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-22` | M22 `MEDICATION_ADHERENCE` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-23` | M23 `GLUCOSE_TRACKING` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-24` | M24 `SYMPTOM_PAIN_JOURNAL` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-25` | M25 `WOMENS_CYCLE_HEALTH` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-26` | M26 `RESPIRATORY_ALLERGY_TRACKING` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-27` | M27 `LAB_RESULT_TRACKING` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-28` | M28 `PREVENTIVE_CARE` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |
| `GW-AHF-29` | M29 `AI_HEALTH_TRENDS` | Catalog shell only | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | Chưa ghi nhận DD | `SHELL ONLY`; DD 0% |

### 4.3. Delta trên module đã Approved

| Readiness ID | Delta | PO | Tech | QA | Clinical | Privacy | Kết luận |
|---|---|---|---|---|---|---|---|
| `GW-DELTA-05` | M05 guest wellness merge | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M05 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-06` | M06 tier/quota cho wellness, M20–M29, coaching/chat | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M06 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-07` | M07 trusted wellness coaching + AI memory boundary | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M07 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-09` | M09 notification cho tracking/chat mới | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M09 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-10` | M10 record envelope, goal tier, health hubs | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M10 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-11` | M11 FamilyPlus chat/E2EE/subject data | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M11 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-12` | M12 Sale care status/note/follow-up | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M12 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-14` | M14 read-only order/commission, campaign, aggregate analytics | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M14 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-19` | M19 health/OCR/AI/chat retention, privacy và evidence | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M19 cũ vẫn Approved; delta `PENDING` |
| `GW-DELTA-30` | M30 canonical Nabi overlay và notification taxonomy mới | Baseline ≠ delta | Baseline ≠ delta | Baseline ≠ delta | Chưa ghi nhận delta | Chưa ghi nhận delta | M30 cũ vẫn Approved; delta `PENDING` |

## 5. Ma trận readiness — năng lực wellness mới

| ID | Source và trạng thái hiện tại | Quyết định còn thiếu | UI được phép trong Wave 1–3 | Route/provider/schema bị chặn | Trace Stitch/plan |
|---|---|---|---|---|---|
| `GW-NEW-01` | Yêu cầu ngày 2026-08-08; chưa có BD/DD. `/health-tracking` hiện là alias Lifestyle Schedule. | Record taxonomy; sensitive/non-sensitive boundary; Guest/member ownership; merge conflict/idempotency; correction/delete/export/retention; FamilyPlus; offline; disclaimer; analytics. | Giữ/refactor alias hiện hữu hoặc placeholder trung thực; không hiển thị record mẫu. | Chặn chuyển `/health-tracking` thành journal nghiệp vụ; chặn journal controller/repository, Guest→cloud merge, `HealthRecordEnvelope` và mọi table/RLS/RPC mới. | ST-065; coding plan Wave 3; route matrix ghi rõ alias tới khi DD Approved. |
| `GW-NEW-02` | Yêu cầu ngày 2026-08-08; chưa có BD/DD. `/weekly-summary` là surface UI hiện hữu. | Định nghĩa “member report”; nguồn record hợp lệ; kỳ tuần/timezone; missing-data/completeness; quyền subject; snapshot hay tính động; export/share; retention; quan hệ với M08 Health Score. | Refactor `/weekly-summary`; chỉ render dữ liệu runtime đã được contract cho phép hoặc honest empty/error/offline state; M08 vẫn sở hữu Health Score. | Chặn report aggregator/provider mới, cloud snapshot/export, cross-subject query và table/materialized view/RPC báo cáo. | ST-075; coding plan Wave 3; M08 DD là owner score. |
| `GW-NEW-03` | Yêu cầu ngày 2026-08-08; chưa có BD/DD. Quick Care/Gentle Care hiện là deterministic UI. | Session lifecycle; catalog owner; local/cloud retention; sensitive flags; crisis/red-flag behavior; completion semantics; AI eligibility/quota; generated-content review; subject visibility. | Refactor `/quick-care`, `/gentle-care`, `/nami-care`; giữ bài self-care deterministic, không chẩn đoán, không booking/chuyên gia và không gọi model. | Chặn session repository/history, AI-generated sessions, `RequestWellnessCoaching`, `CoachingSafetyPolicy`, catalog publish và table/RLS/RPC `self_care_sessions`. | ST-022, ST-047, ST-054; coding plan Wave 3/5. |
| `GW-NEW-04` | Yêu cầu ngày 2026-08-08; hiện `/sleep-tracking` là preview/coming-soon, chưa có DD nghiệp vụ. | Manual fields/units; sleep-day boundary/timezone; HealthKit/Health Connect types; dedupe/provenance; correction/delete; red flags; deterministic vs AI insight; retention/consent. | Refactor preview/placeholder light/dark/accessibility, copy wellness không chẩn đoán. | Chặn form/persist/sync, sleep provider/repository, health-hub permission, coaching call và typed table/RLS/RPC. | ST-059; coding plan Wave 3/4/5. |
| `GW-NEW-05` | Yêu cầu ngày 2026-08-08; hiện `/stress-tracking` là preview/coming-soon, chưa có DD nghiệp vụ. | Scale/taxonomy; manual fields; crisis policy/local copy; sensitive data; correction/delete; health-hub mapping; deterministic care vs AI; consent/retention. | Refactor preview/placeholder và CTA an toàn tới deterministic self-care hiện hữu nếu route đó đã được duyệt. | Chặn form/persist/sync, stress provider/repository, health-hub permission, coaching call và typed table/RLS/RPC. | ST-060; coding plan Wave 3/4/5. |

## 6. Ma trận readiness — M20–M29

Quyền chung đã chốt trong `BD-BIOAI-ADVANCED-HEALTH-001`: catalog đúng 10 mục; Guest → login; Free M20–M22 → placeholder; Free M23–M29 → upgrade; Plus/FamilyPlus → placeholder. Placeholder không đọc/ghi health data, không gọi AI/API, không xin permission, không tạo notification và không commit quota.

Route duy nhất được phép ở gate hiện tại là dashboard/placeholder `/v2/health-modules/:moduleId`. Toàn bộ child route tạo/xem/correction record, `/v2/health-data-connections`, `/v2/ai-memory`, provider/port health và schema/RLS/RPC đều bị chặn.

| ID | Source/status | Quyết định còn thiếu trước DD Approved | UI được phép | Runtime bị chặn | Trace |
|---|---|---|---|---|---|
| `GW-AHF-20` | Advanced Health BD M20, UC-25, M20-BR01..03/M20-AC01..03; Draft. | Clinical source/threshold/copy; unit validation; measurement context; lifecycle/correction; provenance/dedupe; FamilyPlus; AHF-Q01/Q02/Q04/Q05. | Card Free + access-aware placeholder tên “Nhật ký huyết áp”. | Input/history/correction, BP typed store, device/import, score/alert/notification. | ST-028; Wave 4. |
| `GW-AHF-21` | BD M21, UC-26, BR/AC tương ứng; Draft. | Device limitation copy; HR/SpO₂ units/context; outlier handling; provenance/dedupe; lifecycle; clinical escalation; AHF-Q01/Q02/Q04/Q05. | Card Free + placeholder. | Input/history/correction, HR/SpO₂ typed store, wearable/platform sync, alert/AI. | ST-028; Wave 4. |
| `GW-AHF-22` | BD M22, UC-27, BR/AC tương ứng; Draft. | Medication identity/source; schedule/timezone; “taken/missed” semantics; correction; notification ownership; minor/family access; retention; AHF-Q01/Q02/Q04/Q05. | Card Free + placeholder. | Medication/adherence form/store, reminder jobs, platform medication read, interaction checker. | ST-028; Wave 4. |
| `GW-AHF-23` | BD M23, UC-28, BR/AC tương ứng; Draft. | Unit conversion; meal/fasting context; device provenance; validation/extreme-value copy; correction; escalation; FamilyPlus; AHF-Q01/Q02/Q04/Q05. | Card Plus + upgrade/placeholder theo tier. | Glucose form/store/import, device sync, insulin/treatment advice, alert/AI. | ST-028; Wave 4. |
| `GW-AHF-24` | BD M24, UC-29, BR/AC tương ứng; Draft. | Symptom/pain taxonomy; free-text minimization; red-flag/crisis flow; lifecycle; AI summary policy/evaluation/consent; AHF-Q01/Q02/Q04/Q06. | Card Plus + upgrade/placeholder. | Journal store, triage/symptom checker, AI summary, health recommendation. | ST-028; Wave 4/5. |
| `GW-AHF-25` | BD M25, UC-30, BR/AC tương ứng; Draft. | Minor/pregnancy/postpartum policy; cycle-day/timezone; fertility boundary; FamilyPlus disclosure; consent/delete/retention; AHF-Q01..Q04. | Card Plus + upgrade/placeholder. | Cycle record/store, prediction/fertility output, cross-subject sharing. | ST-028; Wave 4. |
| `GW-AHF-26` | BD M26, UC-31, BR/AC tương ứng; Draft. | Respiratory measure/context; trigger taxonomy; locale emergency copy; action-plan boundary; device provenance; lifecycle; AHF-Q01/Q02/Q04/Q05. | Card Plus + upgrade/placeholder. | Respiratory/allergy store, device sync, diagnosis/causal conclusion/alert. | ST-028; Wave 4. |
| `GW-AHF-27` | BD M27, UC-32, BR/AC tương ứng; Draft. | Test identity, unit/reference-range compatibility; document handling/retention; OCR model/quality/confirmation; duplicate/provenance; AHF-Q01/Q02/Q05/Q06. | Card Plus + upgrade/placeholder. | Lab form/store, image/PDF import, OCR, raw-document persistence, clinical interpretation. | ST-028; Wave 4/5. |
| `GW-AHF-28` | BD M28, UC-33, BR/AC tương ứng; Draft. | Vietnam schedule/source/version; age/sex/context applicability; overdue semantics; locale escalation; notification; correction; AHF-Q01/Q02/Q04. | Card Plus + upgrade/placeholder. | Preventive schedule/store, recommendation engine, notification jobs, hard-coded medical schedule. | ST-028; Wave 4. |
| `GW-AHF-29` | BD M29, UC-34, M29-BR01..06/M29-AC01..05; Draft. | Source allowlist/per-request consent; minimum/completeness/statistics; model/prompt/evaluation/human review; quota; retention/audit; revoke race; AHF-Q02/Q06/Q07. | Card Plus + upgrade/placeholder; không có report giả. | AI report request/store, model gateway call, AI memory coupling, diagnosis/risk/score generation. | ST-028; Wave 4/5. |

## 7. Ma trận readiness — delta module hiện hữu

Các đường dẫn DD trong cột nguồn vẫn giữ `BASE APPROVED`. Chỉ phần delta mô tả dưới đây bị block; tài liệu này không sửa trạng thái hoặc nội dung Approved hiện hữu.

| ID | Source baseline / delta đề xuất | Quyết định còn thiếu | UI được phép | Route/provider/schema bị chặn | Trace Stitch/plan |
|---|---|---|---|---|---|
| `GW-DELTA-05` | [M05 Auth/Profile Sync](../../DD/auth_profile_sync/README.md); thêm Guest wellness local→cloud merge. | Allowlist dữ liệu Guest; classification; consent; merge key/conflict/idempotency; ownership; offline retry; deletion/revoke; telemetry không PII. | Refactor visual auth/onboarding và giữ redirect/merge baseline hiện hữu. | Chặn merge cho journal/sleep/stress/self-care/M20–M29, provider sync mới và schema/RPC wellness mới. | ST-002/021/037/055/056/069/071–073; Wave 2/3. |
| `GW-DELTA-06` | [M06 Membership/Quota](../../DD/membership_quota/README.md); thêm tier/goals/coaching/chat/M20–M29. | Entitlement matrix; subject source; quota reserve/commit/release; upgrade/downgrade/expiry; offline fail-closed; business flags độc lập UI flag. | Refactor locked/pending/upgrade states; giữ Plus/FamilyPlus và trusted effective access hiện hữu. | Chặn entitlement/quota mới cho coaching, AI memory, chat và module health; chặn unlock từ UI. | ST-019/028/052/063/064; Wave 2–5. |
| `GW-DELTA-07` | [M07 AI Chat](../../DD/ai_chat/README.md); thêm typed wellness coaching, safety và memory. | Command/result schema; trusted context; red-flag/crisis policy; deterministic input/output safety; gateway auth; rejected-output quota; retention/logging; memory allowlist/visibility. | Refactor AI chat/voice/Nabi presentation; failed input chỉ ở local UI draft; giữ quota/provider baseline. | Chặn UI gọi model/service mới, `RequestWellnessCoaching`, `CoachingSafetyPolicy`, `AiMemoryRepository`, `/v2/ai-memory` và stores/RPC. | ST-001/043/046/067; Wave 2/5. |
| `GW-DELTA-09` | [M09 Schedule Notifications](../../DD/schedule_notifications/README.md); thêm tracking/AI/chat notification. | Category/priority; permission/revoke; schedule/timezone; deeplink auth/access; retry/dedupe; hidden chat payload; health-content minimization; analytics. | Refactor notification/schedule UI theo baseline; không hiển thị success giả. | Chặn notification job/push/deeplink cho module chưa Approved; chặn chat preview plaintext/ciphertext và schema queue mới. | ST-035/049/066; Wave 2/4/5. |
| `GW-DELTA-10` | [M10 Advanced Tracking/Goals](../../DD/advanced_tracking_goals/README.md); thêm record envelope, goal tier và health hubs. | Ownership với M08/M20–M29; goal basic/advanced split; envelope/provenance; units/timezone; dedupe/correction/delete; capability/permission; bidirectional-write allowlist. | Refactor Personal Goals/Advanced Tracking/Water UI trong contract hiện hữu. | Chặn `/v2/health-data-connections`, child record routes, `HealthRecordEnvelope`, platform health ports và shared/typed schema. | ST-052/064/074/075; Wave 3/4. |
| `GW-DELTA-11` | [M11 FamilyPlus](../../DD/familyplus/README.md); thêm chat/E2EE và dữ liệu subject mới. | Adult-send rule; room lifecycle; key epoch/AEAD/envelopes; owner-offline invite; rotation/rejoin; multi-device recovery; revoke; retention/tombstone; report/moderation; offline escrow ceremony. | Refactor `/v3/familyplus` current membership/access page và community preview/lock; không ngụ ý chat hoạt động. | Chặn `/v3/familyplus/chat`, `FamilyChatRepository`, crypto port, realtime/RPC, room/message/key/read/report schema. | ST-011/019; Wave 2/5. |
| `GW-DELTA-12` | [M12 Direct Referral](../../DD/referral_direct/README.md); thêm Sale care status/note/follow-up. | State transition/auth; note fields/minimization; follow-up time; backend-derived `converted`; idempotency/audit; least privilege; retention; no health/AI/payment leakage. | Refactor `/v2/sale` direct-only 10%, direct customers và approved current states. | Chặn care-status/note/follow-up writes, new providers/RPC/tables; Sale không sửa payment/commission. | ST-006/032/038/048/061; Wave 2/5. |
| `GW-DELTA-14` | [M14 Sale Points](../../DD/sale_points/README.md); thêm read-only order/commission, campaign template/link, trusted aggregate analytics. | Read-model authority/freshness; campaign approval/version; share audit; aggregate privacy thresholds; relation M12/M13/M18; error/reconciliation. | Refactor point/conversion/payout visual trong contract hiện hữu; giữ direct 10%, không voucher/30%/doanh thu mẫu. | Chặn order/commission/campaign/analytics RPC/providers mới và mọi write payment/commission. | ST-007/026/034; Wave 2/5. |
| `GW-DELTA-19` | [M19 Audit/Security](../../DD/audit_security/README.md); thêm health/OCR/AI memory/chat evidence policy. | Data-class map; retention/delete/export/correction; 30-day hard delete; 12-month metadata; AI memory visibility/revoke; OCR raw-doc disposal; chat evidence +180 ngày; escrow custody/access/audit. | Áp accessibility, safe copy, no-sample-data, redaction và fail-closed trên UI; không mở raw evidence. | Chặn mọi schema/RLS/audit/retention job mới và moderation/escrow workflow tới khi Security/Clinical/Privacy Approved. | Cross-cutting 76 surfaces; Wave 0/4/5. |
| `GW-DELTA-30` | [M30 Nabi Companion Notifications](../../DD/nabi_companion_notifications/README.md); thêm canonical shell/overlay và notification taxonomy của feature mới. | Overlay ownership/priority; legacy FAB cutover; route/deeplink map; reduced motion/sound/haptic; new category eligibility; privacy payload; rollout/rollback. | Hợp nhất visual Nabi theo mapping baseline Approved; không tạo production route cho demo và không chạy hai FAB sau cutover. | Chặn notification/AI action mới ngoài M30 baseline; chặn route demo, feature side effect và schema category mới. | ST-001/040–045; Wave 1/2/5. |

## 8. Decision register cần owner chốt

| Decision ID | Quyết định | Owner bắt buộc | Phạm vi bị block |
|---|---|---|---|
| `GW-Q01` | Module boundary và source BD/addendum cho 5 năng lực wellness mới. | PO | `GW-NEW-01..05` |
| `GW-Q02` | Data classification, Guest allowlist, member/subject ownership, merge và offline policy. | PO + Tech + Privacy | Journal/report/self-care/sleep/stress, M05/M10 |
| `GW-Q03` | Clinical source version, disclaimer, threshold/escalation và Vietnamese safety copy. | Clinical + PO + QA | Sleep/stress, M20–M29, coaching |
| `GW-Q04` | Correction/delete/export/retention/audit policy theo từng loại dữ liệu. | Privacy + Tech + QA | Wellness records, M20–M29, M19 |
| `GW-Q05` | HealthKit/Health Connect capability, read/write allowlist, provenance, dedupe và store policy. | Tech + Clinical + Privacy + QA | M10, M20–M29, sleep/stress |
| `GW-Q06` | OCR source handling, field confirmation, raw-document disposal/retention và evaluation. | Tech + Clinical + Privacy + QA | M27/M19 |
| `GW-Q07` | Wellness coaching/AI report/memory schema, safety, consent, model policy, evaluation, quota và retention. | PO + Tech + QA + Clinical + Privacy | M07/M24/M27/M29, self-care, sleep/stress |
| `GW-Q08` | FamilyPlus chat crypto protocol, membership revoke, retention, moderation evidence và escrow ceremony. | PO + Tech + QA + Privacy; Clinical cho safety copy | M11/M19 |
| `GW-Q09` | Sale care fields/transitions/RPC, trusted read models và least-privilege evidence. | PO + Tech + QA + Privacy | M12/M14/M19 |
| `GW-Q10` | Nabi overlay cutover, notification category/payload và business/UI flag separation. | PO + Tech + QA + Privacy | M09/M30 |

## 9. Evidence record cần thu cho từng DD/addendum

Mỗi module/delta chỉ chuyển khỏi `PENDING` khi thư mục evidence hoặc DD changelog có đủ:

- source ID, path, version/hash và danh sách conflict với baseline;
- stable feature/function/view/BR/API/test IDs và trace hai chiều;
- owner approval record cho đúng version, không dùng chữ ký chung chung từ phiên bản cũ;
- route/state/access matrix gồm loading, empty, error, locked, pending, offline, retry và duplicate submit;
- API/schema/RLS/RPC/idempotency/error/observability contract trước migration;
- data classification, actor/subject/provenance, consent, retention, correction/delete/export;
- clinical source/copy/evaluation evidence khi có health interpretation hoặc crisis path;
- AI test evidence khi có AI; crypto/test vectors và revoke evidence khi có chat;
- visual light/dark/adaptive/accessibility evidence liên kết đúng hàng Stitch;
- changelog ghi rõ điều gì được mở business flag và điều gì vẫn fail closed.

Mẫu approval record đề xuất (đây là cấu trúc tài liệu, không phải database schema):

| Owner role | Người duyệt | Decision | DD/addendum version | Ngày | Phạm vi/điều kiện | Evidence path |
|---|---|---|---|---|---|---|
| PO | `PENDING` | `PENDING` | `PENDING` | — | — | — |
| Tech | `PENDING` | `PENDING` | `PENDING` | — | — | — |
| QA | `PENDING` | `PENDING` | `PENDING` | — | — | — |
| Clinical | `PENDING` | `PENDING` | `PENDING` | — | — | — |
| Privacy | `PENDING` | `PENDING` | `PENDING` | — | — | — |

## 10. Vì sao chưa tạo “full DD” hoặc code business

1. Skill tạo DD yêu cầu mọi fact phải trace tới BD/BRD/AC/UC hoặc được đánh dấu open question/proposal. Năm năng lực wellness mới chưa có source BD đủ để điền module boundary, business rule, data lifecycle và acceptance mà không suy đoán.
2. M20–M29 có BD Draft nhưng văn bản khóa rõ DD completeness và business coding ở 0%; chỉ catalog/placeholder theo `AHF-BR-001..006` được phép. Tạo mười folder DD chứa template/open question vào lúc này dễ bị hiểu sai là đã bắt đầu hoặc đã hoàn tất DD.
3. Approval của M05/M06/M07/M09/M10/M11/M12/M14/M19/M30 áp dụng cho baseline hiện hữu. Approval đó không tự lan sang Guest health merge, AI memory, health hubs, E2EE chat, OCR hoặc Sale CRM.
4. Route/provider/schema là quyết định kiến trúc có side effect lên access, sensitive health data, retention và audit. Tạo trước khi owner chốt sẽ biến đề xuất kỹ thuật thành mặc định nghiệp vụ.
5. Visual acceptance của 76 Stitch pairs chỉ chứng minh presentation. Nó không chứng minh clinical safety, privacy, RLS, quota, crypto hoặc store permission readiness.

Vì vậy, kết quả đúng ở Wave 0 là: giữ các DD Approved hiện hữu nguyên vẹn; cho phép refactor visual và placeholder đúng contract; ghi decision register; chỉ tạo module DD/addendum sau khi source và owner decisions đạt `GW-GATE-01..04`; chỉ code business sau khi toàn bộ gate liên quan đạt.

## 11. Trạng thái checklist sau readiness review

- M01–M19 và M30: trạng thái DD Approved hiện hữu **không thay đổi**.
- M20–M29: DD completeness 0%, business coding 0%, chỉ catalog/placeholder.
- `DAILY_WELLNESS_JOURNAL`, `MEMBER_WELLNESS_REPORTS`, `SELF_CARE_SESSIONS`, `SLEEP_TRACKING`, `STRESS_TRACKING`: chưa có DD Approved; chỉ các surface UI được nêu ở mục 5 được phép.
- Delta M05/M06/M07/M09/M10/M11/M12/M14/M19/M30: `PENDING`; baseline vẫn là nguồn chuẩn cho runtime hiện hữu.
- Không có migration, schema, RLS/RPC, provider/repository, device permission, OCR, AI coaching/memory/report hoặc FamilyPlus chat nào được cho phép bởi tài liệu này.

