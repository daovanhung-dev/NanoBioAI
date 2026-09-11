Commit de xuat: fix(auth): chan submit dang ky lap tren thiet bi that

# Fixbug - Dang ky Auth V2 tren Android that

## Hien tuong

- APK debug duoc chay tren Android that `220333QPG` / ADB `12b304f9`.
- Luong `Dang nhap -> Tao tai khoan` voi du lieu hop le, khong referral, da tao tai khoan va chuyen dung sang man hinh yeu cau xac thuc email.
- Thu nghiem ban dau co ky tu email bi Gboard Telex bien doi thanh ky tu co dau. Day la du lieu nhap khong hop le tu cong cu ADB, khong phai loi Supabase hay loi validator cua app.
- Trong cua so giua hai lan frame, nut dang ky van co the nhan cung callback truoc khi `_loading` kip rebuild. Controller da co single-flight, nhung page van co nguy co chay tiep continuation/route hai lan.

## Root cause

`_V2RegisterPageState._submit()` khong co guard som khi `_loading == true`. `onPressed` duoc gan truc tiep vao `_submit`, vi vay mot tap lap rat nhanh co the vao lai ham truoc khi widget render lai trang thai loading.

## Cach sua

- Them `if (_loading) return;` o dau `_submit()` cua `V2RegisterPage`.
- Giu nguyen `RegisterCommand`, `RegistrationResult`, `AuthFailure` va public repository contract.
- Them regression test controller: hai lenh signup dong thoi chi goi repository mot lan va cung cho ket qua session.

## Bang chung backend/runtime

- Auth settings read-only: cho phep signup email va yeu cau xac thuc email.
- Remote contract read-only: function/trigger atomic signup, profile, health subject va referral contract deu ton tai.
- Sau lan signup thanh cong, read-only query trong cua so 20 phut cho ket qua `1 auth user = 1 profile user = 1 health subject`, trigger binding count `1`.
- Logcat da loc theo PID app: khong co `FATAL EXCEPTION`, `AndroidRuntime` hay `Unhandled exception`.
- APK sau patch build thanh cong, cai thanh cong bang `adb install -r --no-streaming`, va mo duoc tren thiet bi that.

## Kiem thu

- `dart format --set-exit-if-changed` tren source/test lien quan: PASS.
- `flutter analyze` source auth va test lien quan: PASS, khong co diagnostic.
- Focused auth/config/error-translator/Supabase contract suite: PASS `42/42`.
- Regression test moi `repeated sign up calls share one in-flight operation`: PASS.
- Thu lai double-tap tren APK sau patch: khong tao them row trong read-only count; lan retry sau do bi Supabase rate-limit do nhieu signup trong phien debug, nen khong tiep tuc retry.

## Gioi han va viec con lai

- Chua xac nhan lien ket trong inbox that, nen chua dong duoc nhat ky `email confirmation -> login -> onboarding`.
- Smoke test auth page hien van co baseline Flutter 3.47.1 assertion ve `ListTile` background/ink; khong lien quan den request signup runtime va khong sua trong pham vi nay.
- Auth stream timeout trong test baseline truoc do cung duoc giu rieng, khong dung lam ket luan cho signup.
- Khong chay script rebuild Supabase destructive tren remote.
