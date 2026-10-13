Commit de xuat: docs(worklog): ghi nhan deploy Edge Functions NanoBio

# Worklog - Deploy cac Edge Functions NanoBio

## Thoi gian

- Ngay: 2026-10-13
- Bat dau: 15:40
- Ket thuc: 15:56
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Deploy backend
- Module chinh: Supabase Edge Functions / AI schedule
- Yeu cau goc: Deploy tat ca Edge Function co source trong repository.

## Da lam

- Xac nhan project link va `SUPABASE_URL` cung ref `rnwohifdnylqfofkydfl` (NanoBio, ap-southeast-1).
- Deploy 17 function co `index.ts` trong repository bang Supabase CLI; khong dung `--prune`.
- Xac minh ca 17 function trong repository co trang thai `ACTIVE`; `nabi-ai-generate` o version 10, `nabi-food-evidence` o version 1.
- Giữ function cloud-only `admin-purge-gmail-accounts` nguyen trang vi source khong co trong repository.
- Cho `USDA_FDC_API_KEY` thanh tuy chon: khi chua cau hinh key, endpoint van tra NIN; neu khong co ket qua thi giu trang thai chua co du lieu.
- Khong goi endpoint that, khong tao lich AI va khong tieu thu quota.

## File code/docs da sua

- `supabase/functions/nabi-food-evidence/index.ts` - sua - tranh endpoint khong khoi dong khi project chua co USDA key; du lieu thieu van duoc tra la chua xac minh.
- `docs/worklog/2026-10-13/006-worklog-deploy-all-edge-functions.md` - tao - ghi bang chung deploy va cac dieu kien runtime.

## Tai lieu lien quan

- `.codex/AGENTS.md`
- `.codex/workflows/coding.md`
- `.codex/domains/ai-service.md`
- `docs/supabase/README.md`

## Commands

- `supabase functions deploy --project-ref rnwohifdnylqfofkydfl --use-api --jobs 3 --yes`: PASS - 17 function da deploy.
- `supabase functions list --project-ref rnwohifdnylqfofkydfl --output json`: PASS - 17/17 function trong repo ACTIVE; co them mot function chi ton tai tren cloud.
- `supabase secrets list --project-ref rnwohifdnylqfofkydfl --output json`: PASS - chi doi chieu ten secret, khong doc/ghi gia tri; mot so secret provider chua co.
- `git diff --check`: PASS.
- Goi endpoint smoke test: SKIPPED - khong goi dich vu that trong task deploy.

## Loi/Rui ro

- Da fix: `nabi-food-evidence` khong con yeu cau USDA key de khoi dong; se dung NIN va tra unknown neu khong tim thay bang chung.
- Chua fix: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `SLEEP_SAFETY_PROVIDER_BASE_URL`, `SLEEP_SAFETY_PROVIDER_TOKEN`, `SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET` chua co tren project. Cac function can provider secrets nay da duoc deploy nhung chua the xem la runtime-ready.
- Can kiem tra tiep: bo sung credentials provider dung qua Supabase secrets khi san sang; sau do smoke test tung endpoint voi danh tinh va payload QA phu hop.
- Function cloud-only `admin-purge-gmail-accounts` khong co source local nen khong nam trong 17 function vua deploy va duoc giu nguyen.

## Ty le hoan thanh

- Hoan thanh: deploy tat ca 17 function co source local va xac minh trang thai tren project dich.
- Dang do: runtime smoke test va cau hinh cac secret provider con thieu.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - deploy dung project va bao toan function cloud-only.
- Muc do hoan thanh task: hoan thanh deploy; runtime readiness co gioi han do provider secrets chua co.
- Bang chung kiem chung: CLI deploy thanh cong; truy van Functions list xac nhan 17/17 ACTIVE.
- Diem ton token/chua toi uu: context project can doc ngan hon sau khi workflow deploy rieng duoc tao.
- Cach toi uu cho phien sau: doi chieu project ref, local inventory, remote inventory va secret names truoc; deploy mot lan; sau do chi smoke test cac endpoint co credential san sang.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
