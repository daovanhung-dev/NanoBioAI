Commit de xuat: fix(ai): allow general wellness onboarding schedule

# Fixbug: onboarding khong tao duoc lich khi ho so co muc tieu wellness

> Ghi chú: phần nguyên nhân/thay đổi bên dưới ghi nhận bản sửa candidate pool ban đầu, trước khi người dùng yêu cầu đưa 3.000 món workspace vào policy wellness. Trạng thái hiện tại được cập nhật ở cuối tài liệu.

## Nguyen nhan

- `GeneratedPlanService` dung cung bo loc strict cho ca truy van can danh gia dinh duong/chong chi dinh va lich wellness tong quat.
- 163 mon legacy trong SQLite duoc giu tu namespace `src_`, nhung toan bo dang `unclassified`, thieu nutrition da xac minh va cho review rang buoc. Khi ho so co muc tieu nhu `lose_weight` hoac dieu kien tu khai bao, bo loc strict tra ve tap ung vien rong cho moi slot.
- AI normalizer va local fallback deu nhan tap ma duoc phep rong; lich khong duoc commit, va onboarding khong duoc danh dau hoan tat.

## Thay doi

- Tach `MealCandidateSelectionPolicy.wellnessSchedule` khoi chinh sach `strict`; personal schedule generation dung policy wellness cho ca initial guest va additional schedule qua `GeneratedPlanService`.
- Policy wellness cho phep catalog legacy tao goi y tong quat du nutrition/condition evidence chua duoc xac minh. Policy `strict` mac dinh van giu hanh vi cu cho cac caller khac.
- Di ung ro rang/khong ho tro, thong tin di ung chua phan tich, va thuc pham nguoi dung yeu cau tranh van tiep tuc chan ung vien neu evidence khong du. Condition-conflict tags chi duoc dung de loai mon khi metadata condition da verified.
- Prompt nhac AI chi dua goi y wellness chung; khong tuyen bo phu hop dieu tri, an toan cho benh, hay gia tri dinh duong chua xac minh.
- Tang staging prompt version len `personal_schedule_v11_wellness_candidate_policy` de chunk cu khong tron voi policy moi.
- Eligibility chung van loai candidate 3.000 mon chua duoc duyet. Khong sua JSON goc, khong tao migration v36, va khong bat candidate cho AI.

## Kiem chung

- Selector regression doc asset that 163 mon legacy: profile co `lose_weight` va `diabetes` nhan duoc ung vien; peanut allergy chua duoc review van chan tat ca mon.
- Synthetic `GeneratedPlanService` onboarding voi `lose_weight` va `diabetes` tao du 5 bua, 2 hoat dong va truyen danh sach ma du dieu kien cho moi meal type.
- Focused Flutter suite: 52 tests PASS, gom onboarding, catalog, prompt, normalizer, fallback eligibility va asset exclusion.
- `dart analyze` cac file Dart lien quan: PASS, khong co van de.
- Khong dung Gemini that, ho so suc khoe that, hoac tao lich tren thiet bi trong lan kiem chung nay. Device acceptance con chua xac minh.

## Gioi han va viec tiep theo

- Policy wellness tao goi y tong quat, khong chung minh mon an an toan ve mat lam sang cho bat ky benh nao. Neu nguoi dung khai bao di ung/them thuc pham can tranh ma catalog chua the xac minh, luong van fail closed.
- De nap 3.000 mon moi, can ho so quyen su dung va review dinh duong, loai bua, cong thuc, di ung/chong chi dinh day du theo intake contract. Sau do moi tao package 3.163 dong, SQLite v36/seeder va kiem tra hydrate.

## Cập nhật triển khai catalog — 2026-10-16

- Theo chỉ thị mới của người dùng, JSON workspace đã được bundle và tích hợp vào SQLite v36, giữ 163 món cũ cùng 3.000 mã candidate. Cài mới seed 3.163 món; upgrade v35 insert-only thêm candidate và giữ dữ liệu sẵn có.
- Chỉ policy `wellnessSchedule` cho phép gửi code/name candidate để AI chọn. Normalizer, fallback và final validation nhận cùng `eligibleCodesByType`; strict policy từ chối candidate. Chi tiết hydrate từ SQLite; nutrition chưa xác minh không được lưu/hiển thị như giá trị đã biết.
- Candidate vẫn giữ `is_plan_eligible=false` cùng các trạng thái review ban đầu. Allergy chưa xác minh và món cần tránh fail-closed; không có khẳng định an toàn y khoa hay xác nhận quyền phân phối.
- Staging prompt version hiện tại: `personal_schedule_v12_unreviewed_wellness_candidates`.
- Test migration/bundle/storage (6), selector/normalizer/schedule/detail (46) và AIService candidate prompt/fallback (2) PASS; Flutter asset bundle PASS. Gemini thật và device acceptance chưa chạy.
