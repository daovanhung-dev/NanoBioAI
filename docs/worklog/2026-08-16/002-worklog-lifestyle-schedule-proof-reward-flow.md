# Worklog - Lifestyle Schedule proof va reward completion flow

## Metadata

- Ngay: 2026-08-16
- Workflow: `coding`
- Task-skill: `.codex/task-skills/coding.md`
- Domain chinh: `.codex/domains/lifestyle-schedule.md`
- Module lien quan: M03 `DASHBOARD_SCHEDULE`, delta `BD-BIOAI-WELLNESS-REWARDS-001`
- Repository/ref: `daovanhung-dev/NanoBioAI` / `main`

## Muc tieu

1. Sua luong nut hoan thanh trong Lich trinh ca nhan de mot nhiem vu dang trong cua so thuc hien co the mo camera thay vi bi khoa khi reward backend tam thoi khong san sang.
2. Giu bat buoc anh minh chung va luu local truoc khi danh dau hoan thanh.
3. Voi Member online va eligibility hop le, giu luong trusted backend `begin -> upload -> finalize` de Supabase cap Diem cham soc.
4. Voi Guest/offline hoac loi reward duoc danh dau co the tiep tuc, van cho phep hoan thanh local nhung khong tu cong diem co the doi qua.

## Context va invariant da xac minh

- Cua so hoan thanh van la `[start_time, start_time + 30 phut]`; khong thay doi `LifestyleScheduleWindowPolicy`.
- Anh van duoc chup truc tiep qua `ScheduleProofImageService`, chuan hoa JPEG, bo EXIF va luu trong `schedule_proofs` app-private.
- `LifestyleScheduleLocalDatasource.updateItemCompletion` da ho tro transaction local cho task/proof/linked task/health-score va `localOnly/notEligible` khi khong co reward eligibility.
- Supabase gateway da co `register_my_schedule_reward_eligibilities`, `begin_my_schedule_completion`, private proof upload, `finalize_my_schedule_completion` va `undo_my_schedule_completion`.
- Client khong tu tang ledger. Diem chi duoc xac nhan tu `finalize_my_schedule_completion` va `points_delta` do backend tra ve.
- `wellness_rewards_rollout` trong seed van mac dinh `enabled=false` cho den khi acceptance sandbox hoan tat; phien nay khong tu y bat rollout.

## Nguyen nhan

`LifestyleScheduleController.toggleItem()` truoc day bat buoc `beginCompletion()` thanh cong truoc khi mo camera. Moi `ScheduleRewardException`, ke ca cac loi co `canContinueWithoutReward=true` nhu mat mang, het session hoac eligibility chua san sang, deu return `blocked` ngay lap tuc. Dieu nay trai voi BD da Approved: Guest/offline van duoc chup anh va hoan thanh local, chi khong nhan Diem cham soc co the doi qua.

Ngoai ra `ScheduleRewardEligibilityReconciler` da ton tai nhung controller khong best-effort reconcile eligibility truoc khi `begin`, lam Member co schedule vua sync/generate de gap `eligibility_unavailable` hon can thiet.

## Thay doi source

### `lifestyle_schedule_controller.dart`

- Khoi tao `ScheduleRewardEligibilityReconciler` trong controller.
- Best-effort reconcile reward eligibility khi build, refresh, truoc `beginCompletion()` va truoc pending-reward reconciliation.
- Giu fail-closed voi loi nghiep vu khong duoc phep tiep tuc: task chua mo/da het han/proof invalid theo backend.
- Voi `ScheduleRewardException.canContinueWithoutReward == true`:
  - khong return `blocked` truoc camera;
  - mo camera va luu proof local;
  - commit task local voi reward ids = null;
  - proof projection local tro thanh `local_only/not_eligible`;
  - hien thong bao ro lan hoan thanh nay khong co Diem cham soc.
- Guest khong goi `beginCompletion`, van di qua camera/local completion.
- Loai bo null assertion `remoteAttempt!` o local-only path.
- Member online co attempt hop le tiep tuc `uploadProof -> finalizeCompletion`.
- Sau finalize thanh cong, refresh proof projection va hien `+pointsDelta Diem cham soc da duoc dong bo`.
- Giu `_busyItemIds` single-flight de chan double tap trong khi camera/reward flow dang chay.

## Test bo sung

Them `test/features/lifestyle_schedule/presentation/lifestyle_schedule_controller_completion_flow_test.dart` voi cac contract:

1. Loi mang o reward begin van mo camera va commit local completion, khong tao reward eligibility gia.
2. Member online: begin -> upload -> finalize, proof chuyen `confirmed`, UI nhan `+10` tu ket qua backend.
3. Loi backend khong duoc phep fallback (vi du `window_closed`) khoa truoc camera.
4. Huy camera khong thay doi task/proof.
5. Double tap trong luc camera dang mo chi co mot flow, lan thu hai tra `ignored`.
6. Guest hoan thanh local-only va khong goi reward begin.

## Pham vi khong thay doi

- Khong thay `LifestyleScheduleWindowPolicy` va quy tac 30 phut.
- Khong thay schema SQLite hay tang database version.
- Khong sua `docs/supabase/setup.sql`/`seed_data.sql` vi RPC, private reward flow va rollout guard da ton tai.
- Khong bat `wellness_rewards_rollout`; activation van can Supabase sandbox + real-device acceptance theo checklist du an.
- Khong tao diem local co the doi voucher khi server khong xac nhan.

## Validation

### Da thuc hien

- Doi chieu source hien tai tren GitHub `main`: controller, provider, eligibility reconciler, proof image service, local datasource, reward gateway, BD wellness rewards, Supabase setup/seed va targeted test inventory.
- Static invariant scan tren cac file tao/sua:
  - khong con `remoteAttempt!` trong completion path;
  - khong co phep tang diem client-side kieu `points +=`;
  - `canContinueWithoutReward`, camera capture, begin/finalize va eligibility reconcile deu co path ro rang;
  - can bang delimiter `{}`, `()`, `[]` cua hai file Dart da kiem tra.

### Bi chan boi moi truong

- `dart format`: BLOCKED - container khong co executable `dart`.
- `flutter analyze`: BLOCKED - container khong co executable `flutter`.
- `flutter test`: BLOCKED - container khong co executable `flutter`.
- Clone GitHub bang `git clone`: BLOCKED do container khong resolve duoc `github.com`; source duoc doc tu GitHub connector tren `main` va file thay doi duoc tao local de dong goi.
- Supabase sandbox/private bucket/real-device camera smoke: KHONG CHAY trong moi truong hien tai.

## Acceptance con lai truoc khi bat reward rollout

1. Chay `dart format` + targeted analyze/test tren checkout day du.
2. Apply/smoke `docs/supabase/setup.sql` + seed tren Supabase sandbox disposable.
3. Xac minh private bucket `schedule-completion-proofs`, RLS, idempotency va hai-user isolation.
4. Real-device: den gio -> camera -> local proof -> complete -> upload/finalize -> ledger dung mot `+10`; test mat mang va double tap.
5. Chi sau acceptance moi doi `wellness_rewards_rollout.enabled` theo quy trinh release.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - sua dung orchestration point, tai su dung proof/reward infrastructure hien co va khong mo rong schema/UI khong can thiet.
- Muc do hoan thanh task: source + regression test da hoan thanh; runtime Flutter, Supabase sandbox va device smoke chua xac minh do gioi han moi truong.
- Bang chung kiem chung: GitHub main source/BD/SQL contract + static invariant/delimiter scan; khong claim Flutter test pass.
- Diem ton token/chua toi uu: phai doc them Supabase/reward context do task giao nhau giua Lifestyle Schedule va trusted reward backend; khong nap raw toan repo.
- Cach toi uu cho phien sau: dung checkout co Flutter SDK va Supabase sandbox ngay tu dau de chay targeted tests va device flow sau khi sua controller.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
