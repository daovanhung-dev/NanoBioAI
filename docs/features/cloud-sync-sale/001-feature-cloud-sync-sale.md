Commit de xuat: feat(sync-sale): dong bo snapshot user va khong gian Sale cloud-direct

# Dong Bo Du Lieu User Va Khong Gian Sale

## Muc tieu

- Dong bo du lieu suc khoe, onboarding, lich trinh, nhiem vu, thong bao, diem theo ngay va AI insight giua SQLite va Supabase.
- Khi dang nhap, Supabase la nguon uu tien neu account da co onboarding/du lieu user thuc su.
- Khi Guest hoan tat onboarding roi moi tao/dang nhap account, day snapshot local len cloud neu account cloud chi co profile bootstrap va chua co du lieu onboarding.
- Moi thay doi user-data o SQLite tao outbox marker trong cung transaction; app day snapshot day du len Supabase ngay khi co session va retry neu offline/loi.
- Tao khong gian Sale tach biet, chi doc truc tiep Supabase; khong dung SQLite lam cache hay nguon quyet dinh Sale.

## Pham vi

### Bao gom

- SQLite database v9: `sync_outbox`, `sync_runtime_state`, trigger dirty-marker cho cac bang user-owned.
- Pull full snapshot cloud -> SQLite va replace toan bo projection local cua user dang nhap.
- Push full snapshot local -> Supabase qua RPC `sync_my_mobile_snapshot`.
- Luong Guest -> register/login va cloud-wins conflict policy.
- Sale participation terms, settings entry, Sale dashboard/tree/leaderboard/calculator UI.
- Supabase SQL draft `10-mobile-sync-and-sale-rpc.sql` voi RPC scope theo `auth.uid()`.

### Khong bao gom

- Production deployment SQL, migration Supabase thuc te, hoac xac nhan RLS tren project that.
- Conflict resolver da thiet bi (last-write-wins/merge). Ban nay dung snapshot replacement theo policy dang nhap.
- Membership entitlement, payment event, commission record, Free quota, FamilyPlus va payout workflow thuc te.
- Luu local data cho Sale, payment, commission, referral relationship hay role tin cay.

## Chinh sach dong bo

1. **Dang nhap account da co du lieu cloud**: pull tat ca bang user-owned tu Supabase va replace SQLite cua auth UUID. Guest cache pending (neu co) bi xoa sau khi replace thanh cong.
2. **Guest da onboarding -> dang ky/dang nhap account cloud moi**: neu cloud chi co bootstrap profile, `onboarding_status != completed` va chua co row user-data, push snapshot Guest len cloud; sau do pull cloud lai de SQLite dung UUID cloud.
3. **Dang nhap account moi, khong co Guest data**: pull profile bootstrap, set local onboarding false; router dua user vao onboarding.
4. **Thay doi local sau auth**: SQLite trigger ghi dirty marker. `UserDataSyncOutboxRefresher` drain ngay khi app start, resume, co mang va polling 1 giay. Full snapshot thanh cong xoa marker; marker moi tao trong luc RPC dang gui se duoc giu cho lan sau.
5. **Cloud pull**: `sync_runtime_state.is_applying_cloud = 1` trong transaction de trigger khong tao pull->push loop.

## Du lieu dong bo

- `users` (chi profile/onboarding fields duoc client write; `product_access_status`, `sale_status`, membership va payment la server-owned).
- `health_profiles`, `lifestyle_habits`, `health_goals`, `health_conditions`, `food_allergies`, `medical_treatments`, `survey_answers`.
- `meal_plans`, `daily_health_tasks`, `lifestyle_schedule_items`, `notifications`.
- `health_tracking_logs`, `nutrition_logs`, `ai_insights`, `ai_recommendations`.
- Catalog, FamilyPlus subject khac, payment, referral, commission, entitlement va quota khong nam trong snapshot mobile.

## Sale UX va phan quyen

- Settings chi hien nut **Chuyen sang khong gian Sale** khi `get_my_sale_state()` tra `sale_status = active` tu Supabase.
- User da dang nhap co the mo **Tham gia kiem tien cung Nami**, doc dieu le co version, tick dong y va goi `request_sale_participation`.
- RPC chi cho role `active` doc sale dashboard, referral tree va leaderboard; direct route khi khong co quyen chi hien trang ho tro, khong hien du lieu Sale.
- UI Sale co 4 tab rieng: tong quan, mang luoi, xep hang, cong cu uoc tinh. Tat ca dashboard/tree/rank la Supabase RPC; uoc tinh chi la tinh toan UI, khong phai quyet dinh chi tra.

## Bao mat

- RPC dat `security definer`, `search_path = public, pg_temp` va lay user tu `auth.uid()`; client khong truyen user_id/quyen/commission de server tin.
- `sync_my_mobile_snapshot` bo qua cac truong server-owned: membership, entitlement, Sale state, payment, commission, quota va foreign subject identity.
- Sale terms nhac ro khong cam ket thu nhap, khong thuong vi tuyen nguoi, chi co ghi nhan tren giao dich thanh toan hop le, cam thu OTP/password/du lieu suc khoe/thong tin thanh toan cua khach hang.
- SQL van la **DRAFT**: phai review RLS/RPC va chay sandbox/staging truoc production.

## File chinh

- `lib/core/storage/localdb/sync/sync_outbox_schema.dart`
- `lib/core/storage/localdb/sync/sync_runtime_state.dart`
- `lib/services/supabase/cloud_sync/user_data_sync_outbox.dart`
- `lib/services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart`
- `lib/app_versions/v2/features/cloud_sync/data/datasources/*`
- `lib/app_versions/v2/features/cloud_sync/data/repositories/authenticated_user_data_sync_repository_impl.dart`
- `lib/app_versions/v1/features/onboarding/*`
- `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/sale_referral/presentation/pages/sale_participation_page.dart`
- `lib/sale_referral/presentation/pages/sale_shell_page.dart`
- `lib/services/supabase/sale/*`
- `docs/supabase/10-mobile-sync-and-sale-rpc.sql`

## Rui ro va diem can xac nhan

- Snapshot replacement co the ghi de thay doi tu thiet bi khac. Truoc multi-device release can chot versioning/conflict policy trong BD/DD.
- SQL RPC va RLS chua co bang chung deploy tren Supabase that; can chay acceptance checklist va proof query trong staging.
- Dieu le Sale chi la copy trong app va khong thay the hop dong/chinh sach phap ly. Can business/legal owner phe duyet truoc khi tra hoa hong that.
