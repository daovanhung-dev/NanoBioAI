# DD-PRODUCT-FLOW-TEST-001 - Test, Acceptance và Traceability

**Related DD:** All `docs/DD/product_flow/*`  
**Environment:** local, Supabase sandbox/staging for RLS/payment tests  
**Status:** Draft  

## 1. Test matrix

| Test ID | BD/AC | Given | When | Then | Evidence | Status |
|---|---|---|---|---|---|---|
| TC-PF-01 | AC-01 | Guest valid onboarding | Submit onboarding | Initial schedule has meal, exercise/task, timeline | Unit/widget/integration | Draft |
| TC-PF-02 | AC-02 | Guest already has initial schedule | Request new schedule | Block before AI call, ask login | Unit/provider | Draft |
| TC-PF-03 | AC-03 | Guest unauthenticated | Open non-V1 route/deep link | Route/use-case blocked | Router/unit | Draft |
| TC-PF-04 | BR-02 | AI returns invalid output | Generate initial schedule | No crash, no invalid persistence | AI service unit | Draft |
| TC-PF-05 | BR-04 | Free/Plus/Family accounts | Auth refresh | Effective access maps correctly | Unit/Supabase smoke | Draft |
| TC-PF-06 | BR-03/04 | Guest opens restricted module | Navigate directly | Auth entry/gate shown | Router test | Draft |
| TC-PF-07 | BR-04 | Local cache says Plus, server says Free | Refresh access | Server wins | Unit | Draft |
| TC-PF-08 | Section 7.1 | User is Free + Sale active | Build effective state | Sale axis does not unlock Plus | Unit | Draft |
| TC-PF-09 | AC-04 | Free user has 0..2 chat uses today | Send chat | Allowed | Quota unit | Draft |
| TC-PF-10 | AC-04 | Free user has 3 chat uses today | Send 4th chat | Block before AI call | Quota unit | Draft |
| TC-PF-11 | AC-05 | Free user has 3 schedule generations/month | Generate 4th | Block before AI/save | Quota unit | Draft |
| TC-PF-12 | AC-06 | Plus/FamilyPlus user | Chat/generate repeatedly | Not blocked by Free quota | Quota unit | Draft |
| TC-PF-13 | BR-08 | No completion history | Load score | Empty/pending state, no mock score | Dashboard unit/widget | Draft |
| TC-PF-14 | BR-08 | Schedule item exists | Complete/skip | Score inputs refresh | Repository/provider | Draft |
| TC-PF-15 | BR-08 | User B attempts User A score data | Read score | Denied/no leak | RLS smoke | Draft |
| TC-PF-16 | BR-06 | Free user | Open Plus planned feature | Block/upgrade entry | Access unit/router | Draft |
| TC-PF-17 | Q-06 | Server downgrades Plus to Free | Refresh | Plus access removed | Unit/Supabase smoke | Draft |
| TC-PF-18 | AC-07 | FamilyPlus owner with member | Read member subject | Allowed | RLS smoke | Draft |
| TC-PF-19 | AC-07 | Non-family user | Read family subject | Denied | RLS smoke | Draft |
| TC-PF-20 | AC-07 | Family member without edit | Update subject data | Denied | RLS smoke | Draft |
| TC-PF-21 | UC-12 | Active Sale code | New user applies code | Referral relationship created | Backend/Supabase test | Draft |
| TC-PF-22 | UC-12 | User uses own code | Apply code | Rejected | Backend/Supabase test | Draft |
| TC-PF-23 | UC-13 | Suspended Sale/revoked code | Apply code | Rejected | Backend/Supabase test | Draft |
| TC-PF-24 | AC-08 | A referred B | B payment succeeded | A commission 10% | Supabase/payment test | Draft |
| TC-PF-25 | AC-09 | A->B->C | C payment succeeded | B 10%, A 5% | Supabase/payment test | Draft |
| TC-PF-26 | AC-11 | Level 3 payer | Payment succeeded | No commission beyond two levels | Supabase/payment test | Draft |
| TC-PF-27 | AC-10 | B no payment, C payment | C succeeded | B/A get commission from C only | Supabase/payment test | Draft |
| TC-PF-28 | Section 7.4 | Duplicate webhook | Same provider event repeats | No duplicate commission | Supabase/payment test | Draft |
| TC-PF-29 | UC-04 | Schedule item | Schedule reminder | Stable notification id | Unit | Draft |
| TC-PF-30 | UC-04 | Valid payload | Round trip parse | Payload parsed | Unit | Draft |
| TC-PF-31 | UC-04 | Invalid payload | Action handler receives | No crash | Unit | Draft |
| TC-PF-32 | UC-04 | Complete/skip action | Tap action | Correct source item updated | Unit/integration | Draft |
| TC-PF-33 | Section 9 | Trusted access/quota source unavailable | Paid/resource action | Fail closed | Unit | Draft |
| TC-PF-34 | Section 9 | Error/log path | Operation fails | No raw health/payment/referral data in logs | Static/log review | Draft |
| TC-PF-35 | UI copy | Error states | Render | No internal technical terms | Widget/static search | Draft |
| TC-PF-36 | Layer contract | Presentation files | Static scan | No DAO/datasource/localdb imports | `rg` architecture check | Draft |
| TC-PF-37 | Version boundary | V2/V3/sale source | Static scan | No forbidden presentation imports | Architecture test | Draft |
| TC-PF-38 | Access guard | Unauthorized action | Route and direct use-case call | Both blocked | Unit/router | Draft |

## 2. Security checks

- [ ] Cross-user read denied.
- [ ] Cross-user update denied.
- [ ] FamilyPlus cross-family read/update denied.
- [ ] Client cannot write membership/quota/payment/commission server-only tables.
- [ ] Client contains no service-role key/payment override.
- [ ] Logs do not include raw health profile, raw AI prompt/response, payment event, referral tree or commission details.

## 3. Acceptance traceability

| BD AC | Test IDs |
|---|---|
| AC-01 | TC-PF-01, TC-PF-04 |
| AC-02 | TC-PF-02 |
| AC-03 | TC-PF-03, TC-PF-06, TC-PF-38 |
| AC-04 | TC-PF-09, TC-PF-10 |
| AC-05 | TC-PF-11 |
| AC-06 | TC-PF-12, TC-PF-16, TC-PF-17 |
| AC-07 | TC-PF-18, TC-PF-19, TC-PF-20 |
| AC-08 | TC-PF-24 |
| AC-09 | TC-PF-25 |
| AC-10 | TC-PF-27 |
| AC-11 | TC-PF-26 |

## 4. Definition of Done

- [ ] DD liên quan có status phù hợp và không còn open decision blocker cho scope code.
- [ ] Tests tương ứng trong matrix đã chạy hoặc có lý do blocked.
- [ ] Supabase/RLS/payment cases chạy trên sandbox/staging trước production.
- [ ] Worklog, feature/test docs được cập nhật theo `.codex/DOCS_WORKFLOW.md`.

## 5. Cleanup

Test payment/referral/family data chỉ tạo trong sandbox/staging và phải có script hoặc hướng dẫn cleanup riêng trước khi chạy manual QA diện rộng.

