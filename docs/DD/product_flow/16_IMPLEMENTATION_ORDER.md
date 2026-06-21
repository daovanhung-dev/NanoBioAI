# DD-PRODUCT-FLOW-PLAN-001 - Thứ tự triển khai và dependency gate

**BD nguồn:** `BD-BIOAI-PRODUCT-FLOW-001`  
**Status:** Draft  
**Dependencies:** All product_flow DDs  

## 1. Phases

### Phase A - DD / decision gate

1. Tạo và review bộ DD này.
2. Chốt Q-01..Q-10 theo từng phase cần code.
3. Chỉ chuyển DD sang `Ready for implementation` khi không còn blocker cho scope đó.

**Gate:** Checklist DD ghi rõ file nào Ready, file nào Draft và vì sao.

### Phase B - Supabase foundation

1. Review `docs/supabase/*.sql` trong sandbox.
2. Chạy core auth/profile, health/schedule, membership/quota, FamilyPlus, Sale/referral SQL theo thứ tự.
3. Seed reference data.
4. Chạy acceptance/RLS checks.

**Gate:** RLS không leak cross-user/family; client không ghi server-only tables.

### Phase C - Guest V1 hardening

1. Chốt Q-01/Q-02.
2. Đảm bảo onboarding lưu đủ local data.
3. Đảm bảo initial schedule sinh một lần và notification hoạt động.
4. Chặn route/use-case ngoài V1.

**Gate:** TC-PF-01..04, TC-PF-29..32 pass.

### Phase D - Auth membership access and Free quota

1. Dựa trên DD authentication hiện có.
2. Đọc membership/effective access từ Supabase.
3. Wire route/use-case gate.
4. Triển khai quota Free qua trusted layer.

**Gate:** TC-PF-05..12, TC-PF-33, TC-PF-38 pass.

### Phase E - Health score

1. Chốt Q-05.
2. Implement score calculator theo completion history.
3. Dashboard đọc real data và empty state khi thiếu data.

**Gate:** TC-PF-13..15 pass.

### Phase F - Plus / FamilyPlus planned

1. Chốt Q-06 cho subscription lifecycle.
2. Plus: chỉ implement capability có DD riêng Ready.
3. Chốt Q-07 trước FamilyPlus member management.
4. Implement family subject boundary.

**Gate:** TC-PF-16..20 pass.

### Phase G - Sale/referral/payment/commission

1. Chốt Q-08/Q-09/Q-10.
2. Implement Sale registration/referral code via trusted backend/RPC.
3. Implement payment event ingestion and commission creation.
4. Implement Sale dashboard read-only views.

**Gate:** TC-PF-21..28 pass trên sandbox/staging.

## 2. Out-of-scope protection

- Không tự thêm paid feature vào v1/v2 khi BD/DD chưa Ready.
- Không dùng Flutter client để ghi membership, quota, payment hoặc commission server-only tables.
- Không triển khai payout/refund/chargeback nếu Q-10 chưa chốt.
- Không triển khai FamilyPlus consent/member policy nếu Q-07 chưa chốt.

## 3. Commit segmentation gợi ý

- `docs(dd): add product flow membership sale design docs`
- `docs(codex): document DD creation workflow`
- `feat(access): implement membership effective access`
- `feat(quota): enforce free AI usage quota`
- `feat(family): add family subject boundary`
- `feat(sale): add referral commission flow`

Mỗi commit code sau này phải reference DD ID và TC IDs tương ứng.

