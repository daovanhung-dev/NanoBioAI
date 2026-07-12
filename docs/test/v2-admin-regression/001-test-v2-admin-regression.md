Commit de xuat: test(v2-admin-regression): tao ma tran bang chung hoi quy v2 va Admin

# Test - Hoi quy v2 + Admin

## Trang thai va nguyen tac ghi nhan

- Trang thai tai lieu: **DANG THUC THI (partial evidence)**. Ma tran van giu `PENDING` cho case chua co bang chung; khong suy dien PASS tu viec mo duoc man hinh.
- P0 da xac nhan device `12b304f9`, package `com.example.nano_app`, cau hinh local ignore va reset state bang `adb pm clear`. V2 va Admin deu da khoi dong tren Android that.
- Bang chung da thu duoc: onboarding/AI plan/dashboard/body metrics/auth va cac man Admin login, dashboard, drawer, users, reports. Case report da phat hien overflow UI, sua local va hot-reload kiem tra lai.
- Cac case backend/RLS, payment lifecycle, RBAC persona va notification nen chua du bang chung; giu `PENDING`/`BLOCKED` cho den khi co seed va log an toan.
- Moi dong case ben duoi deu o trang thai `PENDING`; chi doi thanh `PASS`, `FAIL`, `BLOCKED` hoac `N/A` sau khi co bang chung tu lan chay that.
- Khong ghi secret, token, mat khau, PII hay du lieu suc khoe nhay cam vao anh, log hoac ghi chu case. Su dung du lieu seed gia va ma persona trong tai lieu nay.

## Pham vi, lich chay va dieu kien chung

### Pham vi module

- In scope: 17 module co the kiem thu qua `lib/main_v2.dart` va `lib/main_admin.dart`: **M01-M09, M12-M19**.
- Ngoai scope E2E Android: **M10** (theo doi nang cao) va **M11** (FamilyPlus). Hai module nay la V3 planned, khong co entrypoint E2E trong chien dich nay; E2E duoc ghi `N/A` co ly do, con cac case `AUT-M10-*`/`AUT-M11-*` bat buoc `PASS` bang unit/widget/contract test va anh report da che du lieu.

| Dot | Entry point | Pham vi | Dieu kien hoan tat dot | Trang thai |
| --- | --- | --- | --- | --- |
| P0 | Khong ap dung | Sandbox, device, persona, baseline, reset state va pipeline bang chung | Toan bo `PRE-*` co bang chung hoac blocker ro rang | PENDING |
| P1 | `lib/main_v2.dart` | M01-M04 | Case M01-M04 duoc thuc thi, loi duoc retest sau khi fix | PENDING |
| P2 | `lib/main_v2.dart` | M05-M09 | Case auth/quota/chat/score/notification duoc thuc thi | PENDING |
| P3 | `lib/main_v2.dart` | M12-M14 | Case Sale, payment va Diem Sale duoc thuc thi | PENDING |
| P4 | `lib/main_admin.dart` | M15-M19 | Case Admin, doi soat, bao cao va audit duoc thuc thi | PENDING |
| P5 | Ca hai + automation | Retest, M10/M11 automated-only, regression, anh, ghi chu va tong hop | Khong con `PENDING`/`FAIL`/`BLOCKED`; M10/M11 automated PASS va E2E N/A | PENDING |

### Lenh du kien (chua chay)

```powershell
flutter run -d 12b304f9 -t lib/main_v2.dart --dart-define-from-file=<sandbox.env-da-duoc-ignore>
flutter run -d 12b304f9 -t lib/main_admin.dart --dart-define-from-file=<sandbox.env-da-duoc-ignore>
adb -s 12b304f9 shell pm clear com.example.nano_app
flutter screenshot -d 12b304f9 -o docs/test/v2-admin-regression/assets/<CASE-ID>-pass.png
```

- Xac nhan endpoint sandbox va danh sach persona truoc khi chay; khong ghi gia tri `sandbox.env` vao repo.
- Vi hai entrypoint dung chung application ID, reset state giua persona/dot bang logout hoac lenh `pm clear` o tren; ghi ro cach da dung trong ghi chu case.
- Baseline `flutter test` phai duoc chay va phan loai theo v2/Admin, V3 ngoai scope, test cu, hoac runtime truoc khi sua loi. Con so duoc neu trong ke hoach nguoi dung la muc can xac minh, khong phai bang chung hien co.

### Ma persona va du lieu seed can xac nhan o P0

| Ma | Persona/du lieu | Muc dich |
| --- | --- | --- |
| `G0` / `G1` | Guest moi / Guest da dung lich dau tien | Onboarding, allowlist, lich va notification |
| `F0` / `FQ3` | Member Free con quota / da dung 3 luot trong ky | Quota Chat va tao lich |
| `PP` / `PL` | Payment pending / Plus entitlement sau duyet | Payment va entitlement |
| `SR` / `SA` / `SS` / `SC` | Sale pending-review / active / suspended / closed | Vong doi Sale va ma gioi thieu |
| `RA` / `RB` / `RC` | Sale A, khach truc tiep B, tai khoan do B gioi thieu | Quan he 1 tang va hoa hong |
| `PX` / `PY` / `PR` | Payment X, gia han Y, payment da hoan/huy | Hoa hong, retry va reversal |
| `AS` / `AF` / `AU` / `AC` | Super Admin, Finance Admin, Support Admin, Content Admin | RBAC Admin bốn role; không seed/grant `view_admin` hoặc `operations_admin` mới |

### Quy uoc bang chung cua tung case

- Moi case phai co anh Android khi UI/luong nguoi dung nhin thay ket qua. Duong dan du kien: `assets/<CASE-ID>-pass.png`.
- Moi case phai co ghi chu chi tiet tai `evidence/<CASE-ID>.md` sau khi thuc thi: persona, du lieu seed khong nhay cam, buoc, actual result, thoi gian, command/log ID, duong dan anh, bug/fix/retest neu co.
- Case backend/RLS/notification nen co anh trigger/ket qua tren app hoac Android va command/log ID trong ghi chu; khong dung log de thay the kiem tra UI khi UI la muc tieu case.
- Neu phat hien loi UI/logic/khong dung BD: ghi `FAIL`, tao lien ket bug/fix, sua toi thieu trong scope duoc phep, bo sung regression test, test lai va chi luu anh `-pass.png` sau retest thanh cong.

Mau ghi chu bat buoc cho `evidence/<CASE-ID>.md`:

```md
# <CASE-ID>

- Trang thai: PENDING | PASS | FAIL | BLOCKED | N/A
- Persona / tien dieu kien:
- Buoc thuc hien:
- Ket qua mong doi (BD/AC):
- Ket qua thuc te:
- Device / build / command-log ID:
- Anh: assets/<CASE-ID>-pass.png | khong co (ly do)
- Loi / fix / regression retest:
- Ghi chu bao mat / du lieu da che:
```

## Ma tran phu bao test

Ky hieu: `H` = happy path, `V` = validation/bien, `E` = loi/offline, `Q` = auth/role/deep-link, `I` = retry/idempotency, `P` = persistence/relaunch, `U` = UI Android. `-` chi dung khi loai case khong ap dung theo BD; neu phat hien ap dung trong implementation thi tao case con va giu `PENDING` cho den khi co bang chung.

| Module | H | V | E | Q | I | P | U | BD/AC chinh |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M01 Onboarding | x | x | x | x | - | x | x | BD §6 M01, AC-01 |
| M02 AI lich | x | x | x | x | x | x | x | BD §6 M02, AC-01, AC-02, AC-05 |
| M03 Dashboard | x | x | x | x | x | x | x | BD §6 M03 |
| M04 Suc khoe co ban | x | x | x | x | - | x | x | BD §6 M04 |
| M05 Auth/sync | x | x | x | x | x | x | x | BD §6 M05 |
| M06 Goi/quota | x | x | x | x | x | x | x | BD §6 M06, AC-04-AC-08 |
| M07 AI Chat | x | x | x | x | x | x | x | BD §6 M07, AC-03, AC-04, AC-06 |
| M08 Diem suc khoe | x | x | x | x | x | x | x | BD §6 M08 |
| M09 Notification | x | x | x | x | x | x | x | BD §6 M09 |
| M10 Theo doi nang cao | automated | automated | automated | automated | automated | automated | report | BD §6 M10; E2E N/A |
| M11 FamilyPlus | automated | automated | automated | automated | automated | automated | report | BD §6 M11; E2E N/A |
| M12 Referral | x | x | x | x | x | x | x | BD §7, AC-09, AC-10 |
| M13 Payment | x | x | x | x | x | x | x | BD §8, AC-07, AC-08, AC-11, AC-15 |
| M14 Diem Sale | x | x | x | x | x | x | x | BD §7, §9, AC-12-AC-18 |
| M15 Dashboard Admin | x | x | x | x | - | x | x | BD §11.2, AC-19 |
| M16 Admin Ops | x | x | x | x | x | x | x | BD §11.3-§11.7, AC-20-AC-24 |
| M17 Doi soat | x | x | x | x | x | x | x | BD §12.1 |
| M18 Bao cao | x | x | x | x | x | x | x | BD §12.2, AC-23 |
| M19 Audit/bao mat | x | x | x | x | x | x | x | BD §11.8, AC-21, AC-24 |

## Ma tran case P0 - Preflight

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| PRE-01 | Android `12b304f9` ket noi | Xac nhan device dung, package ID dung va co the chup man hinh truoc khi chay case nghiep vu. | Device gate | `assets/PRE-01-pass.png` | `evidence/PRE-01.md` | PENDING |
| PRE-02 | Cau hinh local da ignore | Khoi chay v2 va Admin chi den sandbox; khong hien thi/ghi endpoint secret hay production credential. | Sandbox gate | `assets/PRE-02-pass.png` | `evidence/PRE-02.md` | PENDING |
| PRE-03 | Toan bo ma persona | Xac nhan G0/G1, F0/FQ3, PP/PL, SR/SA/SS/SC, RA/RB/RC, PX/PY/PR va AS/AF/AU/AC ton tai, phan quyen dung va du lieu khong nhay cam. | Data gate | `assets/PRE-03-pass.png` | `evidence/PRE-03.md` | PENDING |
| PRE-04 | App da co state tu case truoc | Logout hoac `pm clear`, khoi chay lai va xac nhan state cua persona cu khong bi dung nham sang persona tiep theo. | State-isolation gate | `assets/PRE-04-pass.png` | `evidence/PRE-04.md` | PENDING |
| PRE-05 | Workspace sach cho test | Chay baseline `flutter test`, luu command ID va phan loai tung failure; khong coi con so trong ke hoach la PASS khi chua xac minh. | Regression gate | `assets/PRE-05-pass.png` | `evidence/PRE-05.md` | PENDING |
| PRE-06 | Thu muc evidence | Xac nhan quy tac dat ten anh/log hoat dong va anh mau khong co PII. | Evidence gate | `assets/PRE-06-pass.png` | `evidence/PRE-06.md` | PENDING |

## Ma tran case v2

### M01 - Onboarding va ho so suc khoe

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M01-01 | `G0` | Hoan tat cac buoc bang du lieu hop le, xac nhan man hinh tong ra soat; ho so duoc luu va danh dau onboarding hoan tat de chuyen M02. | BD §6 M01, AC-01 | `assets/V2-M01-01-pass.png` | `evidence/V2-M01-01.md` | PENDING |
| V2-M01-02 | `G0` | Bo trong truong bat buoc, nhap sai dinh dang/don vi hoac gia tri bien; khong duoc qua buoc va truong can sua duoc chi ro. | BD §6 M01 - validation | `assets/V2-M01-02-pass.png` | `evidence/V2-M01-02.md` | PENDING |
| V2-M01-03 | `G0` | Tu choi dong y bat buoc; khong sinh lich dung du lieu khong duoc dong y va UX xu ly theo chinh sach. | BD §6 M01 - consent | `assets/V2-M01-03-pass.png` | `evidence/V2-M01-03.md` | PENDING |
| V2-M01-04 | `G0` | Thoat giua onboarding, relaunch app va kiem tra draft duoc giu/bo theo implementation, nhung khong danh dau hoan tat sai. | BD §6 M01 - exception, persistence | `assets/V2-M01-04-pass.png` | `evidence/V2-M01-04.md` | PENDING |
| V2-M01-05 | `G0` | Mo lai route onboarding sau state chua hoan tat/da hoan tat; route va UI khong cho bypass du lieu bat buoc hay tao ho so nham. | BD §6 M01 - state/route | `assets/V2-M01-05-pass.png` | `evidence/V2-M01-05.md` | PENDING |

### M02 - AI lich trinh ca nhan

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M02-01 | `G0`, M01 hop le | Tao lich dau tien; ket qua hop le co thuc don, bai tap va moc lich, duoc luu va hien tren dashboard. | BD §6 M02, AC-01 | `assets/V2-M02-01-pass.png` | `evidence/V2-M02-01.md` | PENDING |
| V2-M02-02 | `G1` | Yeu cau tao them khi `guest_initial_plan_used`; khong goi AI tao moi va dieu huong dang nhap ro rang. | BD §6 M02, AC-02 | `assets/V2-M02-02-pass.png` | `evidence/V2-M02-02.md` | PENDING |
| V2-M02-03 | `FQ3` cho tao lich | Yeu cau tao lich thu 4 trong thang; chan o UI/use-case/API, khong tao lich va khong dem quota sai. | BD §6 M02, §6 M06, AC-05 | `assets/V2-M02-03-pass.png` | `evidence/V2-M02-03.md` | PENDING |
| V2-M02-04 | `F0`, AI tra thieu truong bat buoc | Khong cong bo lich khong hop le; hien trang thai loi/fallback an toan va khong tru quota truoc ket qua hop le. | BD §6 M02 - AI validation | `assets/V2-M02-04-pass.png` | `evidence/V2-M02-04.md` | PENDING |
| V2-M02-05 | `F0`, mat mang/timeout | Thu lai cung `request_id`; khong co ban ghi lich trung, khong dem quota hai lan va UI bao loi ro rang. | BD §6 M02 - retry/idempotency | `assets/V2-M02-05-pass.png` | `evidence/V2-M02-05.md` | PENDING |
| V2-M02-06 | `F0`, lich moi da luu | Relaunch va kiem tra phien ban lich hien hanh hien dung; lich su thuc hien cua lich cu khong bi ghi de. | BD §6 M02 - version/persistence | `assets/V2-M02-06-pass.png` | `evidence/V2-M02-06.md` | PENDING |

### M03 - Dashboard va thuc hien lich trinh

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M03-01 | `G1` hoac `F0` co lich | Mo dashboard hom nay/theo ngay, xem thuc don, bai tap va moc viec; UI Android hien dung lich cua dung ho so. | BD §6 M03 - view | `assets/V2-M03-01-pass.png` | `evidence/V2-M03-01.md` | PENDING |
| V2-M03-02 | `F0` co muc lich | Danh dau hoan thanh; luu timestamp, status, source/note, cap nhat tien do ngay va du lieu dau vao M08. | BD §6 M03 - completion | `assets/V2-M03-02-pass.png` | `evidence/V2-M03-02.md` | PENDING |
| V2-M03-03 | `F0` co muc lich | Bo qua hoac sua trang thai sau khi da tinh diem; lich su van con va he thong danh dau tinh lai/adjustment minh bach. | BD §6 M03 - history/recalculation | `assets/V2-M03-03-pass.png` | `evidence/V2-M03-03.md` | PENDING |
| V2-M03-04 | `F0`, route/ID cua nguoi khac | Thu thao tac qua UI/deep link; bi tu choi neu khong co quyen, khong lam thay doi lich cua nguoi khac. | BD §6 M03 - authorization | `assets/V2-M03-04-pass.png` | `evidence/V2-M03-04.md` | PENDING |
| V2-M03-05 | `F0` vua cap nhat status | Relaunch/offline-then-reconnect theo implementation; dashboard, lich su va tien do khong mat/nhan doi su kien. | BD §6 M03 - persistence/sync | `assets/V2-M03-05-pass.png` | `evidence/V2-M03-05.md` | PENDING |

### M04 - Tinh toan suc khoe co ban

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M04-01 | `G0` hoac `F0` co chi so hop le | Nhap/chap nhan chi so va don vi hop le; ket qua dung cong thuc duoc phe duyet va co giai thich tham khao. | BD §6 M04 - happy path | `assets/V2-M04-01-pass.png` | `evidence/V2-M04-01.md` | PENDING |
| V2-M04-02 | `G0` hoac `F0` | Nhap gia tri thieu, sai don vi, ngoai pham vi; khong tinh ket qua sai va UI chi ro loi. | BD §6 M04 - validation | `assets/V2-M04-02-pass.png` | `evidence/V2-M04-02.md` | PENDING |
| V2-M04-03 | `F0` va `G0` | Xac minh prefill tu onboarding co the sua; Member luu lich su khi dong y, Guest chi giu trong phien/cuc bo theo thiet ke. | BD §6 M04 - profile/history | `assets/V2-M04-03-pass.png` | `evidence/V2-M04-03.md` | PENDING |
| V2-M04-04 | `G0` hoac `F0` | Relaunch va mo lai cong cu; ket qua/UI khong tu nhan la chan doan va khong lo du lieu ho so khac. | BD §6 M04 - persistence/safety | `assets/V2-M04-04-pass.png` | `evidence/V2-M04-04.md` | PENDING |

### M05 - Xac thuc, ho so va dong bo Guest -> Member

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M05-01 | `G0`, email mới | Đăng ký không referral, xác thực email bằng cold/warm callback, khôi phục session và đi qua Auth Gate; tạo đúng một auth user/profile/self subject. | BD §6 M05 - auth lifecycle | `assets/V2-M05-01-pass.png` | `evidence/V2-M05-01.md` | PENDING |
| V2-M05-02 | `G1`, tài khoản cloud mới | Auth Gate hỏi consent; **Đồng bộ ngay** rekey/push Guest rồi pull, giữ profile/meal/task/schedule/request ledger không mất hoặc nhân đôi. | BD §6 M05 - fresh Guest merge | `assets/V2-M05-02-pass.png` | `evidence/V2-M05-02.md` | PENDING |
| V2-M05-03 | `G1`, push/pull lỗi hoặc local write trong lúc pull | Outbox được push trước pull; lỗi/pending/race không xóa local hoặc marker; resume/connectivity/manual retry idempotent. | BD §6 M05 - retry/persistence | `assets/V2-M05-03-pass.png` | `evidence/V2-M05-03.md` | PENDING |
| V2-M05-04 | `G1`, tài khoản đã có cloud data | Auth Gate cảnh báo hai bước; **Để sau** giữ Guest và chặn phần authenticated; **Dùng dữ liệu tài khoản** mới xóa Guest/pull cloud. | BD §6 M05 - established cloud consent | `assets/V2-M05-04-pass.png` | `evidence/V2-M05-04.md` | PENDING |
| V2-M05-05 | `RA`/`RB`, referral hợp lệ | Referral + fingerprint được gửi trong signup; active Sale/direct-only relation được tạo cùng transaction, không attach sau signup. | BD §6 M05, §7.4, AC-10 | `assets/V2-M05-05-pass.png` | `evidence/V2-M05-05.md` | PENDING |
| V2-M05-06 | Referral sai/inactive/collision; session pending | Signup rollback toàn bộ, không để auth/profile mồ côi; password recovery hoạt động; sign-out preflight cảnh báo và force sign-out giữ marker. | BD §6 M05, §7.3 | `assets/V2-M05-06-pass.png` | `evidence/V2-M05-06.md` | PENDING |

### M06 - Goi thanh vien va quota

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M06-01 | `F0` va `FQ3` Chat | Free dung dung 3 luot Chat/ngay va bi chan o luot thu 4; thong bao quota/reset phu hop va khong gui request moi. | BD §6 M06, AC-04 | `assets/V2-M06-01-pass.png` | `evidence/V2-M06-01.md` | PENDING |
| V2-M06-02 | `F0` va `FQ3` tao lich | Free dung dung 3 lan tao lich/thang va bi chan lan thu 4; khong goi AI, khong dem quota sai. | BD §6 M06, AC-05 | `assets/V2-M06-02-pass.png` | `evidence/V2-M06-02.md` | PENDING |
| V2-M06-03 | `PL` | Plus dung Chat va tao lich khong bi chan boi quota Free; van xu ly loi ky thuat/rate limit an toan neu co. | BD §6 M06, AC-06 | `assets/V2-M06-03-pass.png` | `evidence/V2-M06-03.md` | PENDING |
| V2-M06-04 | `PP` | Payment Plus dang cho duyet khong mo entitlement Plus, ke ca khi refresh/relaunch. | BD §6 M06, §8, AC-07 | `assets/V2-M06-04-pass.png` | `evidence/V2-M06-04.md` | PENDING |
| V2-M06-05 | `PP` -> `PL` sau admin duyet | Sau payment duoc duyet, entitlement co hieu luc tu nguon server va co lich su; UI/route/use-case su dung cung tap quyen. | BD §6 M06, §8, AC-08 | `assets/V2-M06-05-pass.png` | `evidence/V2-M06-05.md` | PENDING |
| V2-M06-06 | `F0`/`PL`, cache cu va request loi | Quota chi tang sau use-case thanh cong; expiry/relaunch/deep link khong dua vao UI cache va khong mo chuc nang trai quyen. | BD §6 M06 - source/audit | `assets/V2-M06-06-pass.png` | `evidence/V2-M06-06.md` | PENDING |

### M07 - AI Chat

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M07-01 | `F0` con quota | Gui cau hoi hop le; co `request_id`, phan hoi an toan hien thi va quota tang mot lan sau khi phan hoi thanh cong. | BD §6 M07 - happy path | `assets/V2-M07-01-pass.png` | `evidence/V2-M07-01.md` | PENDING |
| V2-M07-02 | `FQ3` Chat | Thu Chat lan thu 4 qua UI/route/use-case/API; deu bi chan va khong tao request moi. | BD §6 M07, AC-04 | `assets/V2-M07-02-pass.png` | `evidence/V2-M07-02.md` | PENDING |
| V2-M07-03 | `G0`/`G1` | Mo AI Chat qua menu/deep link/API; Guest bi chan o moi lop, dung theo allowlist. | BD §6 M07, AC-03 | `assets/V2-M07-03-pass.png` | `evidence/V2-M07-03.md` | PENDING |
| V2-M07-04 | `F0`, AI/network loi | Timeout/mat mang/phan hoi loi va retry cung request; khong tru quota, khong luu ban ghi trung va UI bao trang thai ro rang. | BD §6 M07, §6 M06 - retry | `assets/V2-M07-04-pass.png` | `evidence/V2-M07-04.md` | PENDING |
| V2-M07-05 | `F0` va `AU` | Relaunch kiem tra lich su theo chinh sach; Support Admin chi xem so lieu/audit trong scope, khong doc noi dung suc khoe rieng tu. | BD §6 M07 - privacy/persistence | `assets/V2-M07-05-pass.png` | `evidence/V2-M07-05.md` | PENDING |

### M08 - Diem suc khoe va thoi quen

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M08-01 | `F0`, su kien M03 hop le | Tinh diem/tiendo tu lich su thuc hien, luu nguon du lieu va phien ban cong thuc, hien dung tren dashboard. | BD §6 M08 - happy path | `assets/V2-M08-01-pass.png` | `evidence/V2-M08-01.md` | PENDING |
| V2-M08-02 | `F0`, mix complete/skip/missing | Bien completion, bo qua va du lieu thieu duoc xu ly theo cong thuc duoc phe duyet; khong suy dien chan doan. | BD §6 M08 - validation/safety | `assets/V2-M08-02-pass.png` | `evidence/V2-M08-02.md` | PENDING |
| V2-M08-03 | `F0`, diem da tinh | Sua status M03 sau tinh diem; he thong tinh lai/tao adjustment truy vet duoc, khong ghi de lich su im lang. | BD §6 M08 - recalculation | `assets/V2-M08-03-pass.png` | `evidence/V2-M08-03.md` | PENDING |
| V2-M08-04 | `F0` va `SA` | Kiem tra tach biet du lieu, logic va UI cua Diem suc khoe voi Diem Sale; khong quy doi Diem suc khoe thanh tien hoac hien cho Sale. | BD §9 - separation | `assets/V2-M08-04-pass.png` | `evidence/V2-M08-04.md` | PENDING |
| V2-M08-05 | `F0`, relaunch/sync | Relaunch va dong bo theo implementation giu dung diem cua chu ho so; khong tron voi ho so khac. FamilyPlus tach profile la phu thuoc M11 va phai ghi blocker neu khong test duoc. | BD §6 M08, §10.4 | `assets/V2-M08-05-pass.png` | `evidence/V2-M08-05.md` | PENDING |

### M09 - Thong bao lich trinh

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M09-01 | `G1` hoac `F0`, lich co moc | Tao lich hoac doi gio; danh sach nhac duoc tao/cap nhat va Guest van nhan nhac cua lich dau tien. | BD §6 M09 - scheduling | `assets/V2-M09-01-pass.png` | `evidence/V2-M09-01.md` | PENDING |
| V2-M09-02 | Thiet bi tu choi permission | App xu ly quyen notification ro rang, khong crash/khong danh dau da gui khi chua co quyen va cho phep luong phuc hoi phu hop. | BD §6 M09 - permission/error | `assets/V2-M09-02-pass.png` | `evidence/V2-M09-02.md` | PENDING |
| V2-M09-03 | Lich cu co nhac, tao lich moi | Nhac cu het hieu luc duoc huy/danh dau thay the; khong co duplicate reminder sau retry/relaunch. | BD §6 M09 - replacement/idempotency | `assets/V2-M09-03-pass.png` | `evidence/V2-M09-03.md` | PENDING |
| V2-M09-04 | Notification da hien | Mo notification/deep link; vao dung muc lich va dung ho so co quyen. Hanh dong complete/skip cap nhat M03/M08 dung mot lan. | BD §6 M09 - deep link/action | `assets/V2-M09-04-pass.png` | `evidence/V2-M09-04.md` | PENDING |
| V2-M09-05 | App background/relaunch Android | Kich hoat reminder tren device, chup man hinh trigger/ket qua va xac minh state sau relaunch khong mat hay nhan doi. | BD §6 M09 - Android lifecycle | `assets/V2-M09-05-pass.png` | `evidence/V2-M09-05.md` | PENDING |

### M12 - Sale: gioi thieu truc tiep

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M12-01 | `SR` -> `SA` qua Admin | Duyet Sale hop le chuyen sang active, cap ma gioi thieu duy nhat va hien Dashboard Sale; tu choi co ly do phu hop. | BD §7.2, AC-09 | `assets/V2-M12-01-pass.png` | `evidence/V2-M12-01.md` | PENDING |
| V2-M12-02 | `SA`, `RB` chua co quan he/payment | Nhap ma hop le tao dung mot quan he truc tiep A -> B, luu ma/thoi diem/nguon va khong tao cay/tang. | BD §7.3-§7.4, AC-10 | `assets/V2-M12-02-pass.png` | `evidence/V2-M12-02.md` | PENDING |
| V2-M12-03 | `SA`, `RB` | Thu ma khong ton tai, Sale inactive, tu gioi thieu, dinh danh bat thuong hoac gan ma trung; bi tu choi va khong lo du lieu Sale. | BD §7.3-§7.4 - validation/fraud | `assets/V2-M12-03-pass.png` | `evidence/V2-M12-03.md` | PENDING |
| V2-M12-04 | `RB` da thanh toan lan dau | Thu gan/doi ma sau payment dau tien; bi chan tru workflow Admin dac biet co ly do/audit. | BD §7.3, §6 M05 - lock | `assets/V2-M12-04-pass.png` | `evidence/V2-M12-04.md` | PENDING |
| V2-M12-05 | `SA` -> `SS`/`SC` | Tam dung/dong Sale; ma khong con hieu luc cho quan he moi va Sale chi thay du lieu duoc phep, khong thay suc khoe/chat/lich cua khach. | BD §7.3, §7.9 - status/privacy | `assets/V2-M12-05-pass.png` | `evidence/V2-M12-05.md` | PENDING |
| V2-M12-06 | `RA`, `RB`, `RC` | Thu du lieu gioi thieu cua nguoi do B gioi thieu; A khong co quan he/cay gian tiep va khong co duong xem du lieu Sale khac. | BD §7.1, AC-14 | `assets/V2-M12-06-pass.png` | `evidence/V2-M12-06.md` | PENDING |

### M13 - Thanh toan, xac minh va quyen goi

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M13-01 | `F0`, goi Plus | Tao yeu cau thanh toan, gui bang chung theo sandbox; ban ghi `payment_pending` va `transaction_reference` khong bi trung. | BD §8.2 - create/validation | `assets/V2-M13-01-pass.png` | `evidence/V2-M13-01.md` | PENDING |
| V2-M13-02 | `PP`, `RA`/`RB` | Payment cho duyet khong mo Plus va khong cong Diem Sale; relaunch khong lam thay doi ket qua. | BD §8.2-§8.3, AC-07, AC-11 | `assets/V2-M13-02-pass.png` | `evidence/V2-M13-02.md` | PENDING |
| V2-M13-03 | `PP` duoc `AF` duyet | Payment chuyen approved, entitlement bat dau/ket thuc ro rang, lich su va thong bao phu hop; Sale du dieu kien chi duoc xu ly qua M14. | BD §8.2-§8.4, AC-08 | `assets/V2-M13-03-pass.png` | `evidence/V2-M13-03.md` | PENDING |
| V2-M13-04 | `PP` bi tu choi | Tu choi co ly do, khong kich hoat quyen/khong cong Diem Sale va khong ghi de trang thai duyet sau do. | BD §8.2, §8.4, AC-21 | `assets/V2-M13-04-pass.png` | `evidence/V2-M13-04.md` | PENDING |
| V2-M13-05 | `PL`, `PR` | Hoan/huy sau duyet dieu chinh quyen theo policy va tao adjustment/reversal co audit, khong xoa lich su giao dich. | BD §8.2-§8.4, AC-15 | `assets/V2-M13-05-pass.png` | `evidence/V2-M13-05.md` | PENDING |
| V2-M13-06 | `PL`, payment gia han `PY` | Gia han khong tao entitlement chong cheo sai; replay/duplicate reference khong nhan doi quyen hay kich hoat. | BD §8.3 - renewal/idempotency | `assets/V2-M13-06-pass.png` | `evidence/V2-M13-06.md` | PENDING |

### M14 - Diem Sale va quy doi

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| V2-M14-01 | `RA` gioi thieu `RB`, `PX` approved | Sau payment X hop le duoc duyet, A nhan ledger Diem Sale bang 10% gia tri du dieu kien va co audit. | BD §7.5-§7.7, AC-12 | `assets/V2-M14-01-pass.png` | `evidence/V2-M14-01.md` | PENDING |
| V2-M14-02 | `RA`, `RB`, `PY` approved | Gia han Y cua B tao hoa hong 10% moi dung mot lan, giu rate/base tai thoi diem tinh. | BD §7.6-§7.7, AC-13 | `assets/V2-M14-02-pass.png` | `evidence/V2-M14-02.md` | PENDING |
| V2-M14-03 | `RA`, payment cua `RC` | A khong nhan hoa hong tu giao dich cua nguoi do B gioi thieu; khong co hoa hong tang 2/3. | BD §7.1, §7.6, AC-14 | `assets/V2-M14-03-pass.png` | `evidence/V2-M14-03.md` | PENDING |
| V2-M14-04 | `PX` duoc retry job | Retry cung payment key ket thuc an toan, ledger/so du khong bi cong lan hai. | BD §7.5, §12.1, AC-16 | `assets/V2-M14-04-pass.png` | `evidence/V2-M14-04.md` | PENDING |
| V2-M14-05 | `PR` sau khi da credit | Hoan/huy/gian lan tao reversal/adjustment co audit; khong xoa ban ghi Diem Sale lich su. | BD §7.8, §7.10, AC-15 | `assets/V2-M14-05-pass.png` | `evidence/V2-M14-05.md` | PENDING |
| V2-M14-06 | `SA`, so du khong du | Yeu cau quy doi vuot diem kha dung bi tu choi; so du va diem dang giu khong thay doi. | BD §7.10, AC-17 | `assets/V2-M14-06-pass.png` | `evidence/V2-M14-06.md` | PENDING |
| V2-M14-07 | `SA`, yeu cau conversion pending, `AF` | Duyet quy doi giu/tru dung mot lan, co trang thai/lich su ro rang; tu choi thi giai phong diem giu va luu ly do. | BD §7.10, AC-18 | `assets/V2-M14-07-pass.png` | `evidence/V2-M14-07.md` | PENDING |

## Ma tran case Admin


### Admin Auth Gate - Session, role và cấu hình

| Case ID | Persona / tiền điều kiện | Kịch bản và kết quả mong đợi | Phủ BD/AC | Ảnh PASS dự kiến | Ghi chú / log dự kiến | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-AUTH-01 | `AS`, session Admin đã lưu | Khởi động `main_admin`, restore bằng storage key Admin riêng, gọi `get_my_admin_session` và vào dashboard khi role active. | BD §11 - Admin access | `assets/ADM-AUTH-01-pass.png` | `evidence/ADM-AUTH-01.md` | PENDING |
| ADM-AUTH-02 | User thường hoặc Admin bị thu hồi role | Login/restore không được vào route Admin; app sign-out Admin session và quay về login, không ảnh hưởng session V2. | BD §11.8 - role lifecycle | `assets/ADM-AUTH-02-pass.png` | `evidence/ADM-AUTH-02.md` | PENDING |
| ADM-AUTH-03 | Token hết hạn hoặc thiếu cấu hình | Token hết hạn về login; thiếu cấu hình/lỗi kiểm tra role hiển thị support state và retry, không làm `main_admin` crash. | BD §11 - error/session | `assets/ADM-AUTH-03-pass.png` | `evidence/ADM-AUTH-03.md` | PENDING |

### M15 - Admin View / Dashboard

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-M15-01 | `AS`/`AF`/`AU`/`AC` | Dang nhap Admin, mo dashboard, chon khoang thoi gian/bo loc; chi so hien dung trong pham vi permission. | BD §11.2, AC-19 | `assets/ADM-M15-01-pass.png` | `evidence/ADM-M15-01.md` | PENDING |
| ADM-M15-02 | `AU` scope han che | Thu xem chi so/tong hop ngoai scope; backend/UI khong tiet lo du lieu khong duoc phep. | BD §11.2 - permission | `assets/ADM-M15-02-pass.png` | `evidence/ADM-M15-02.md` | PENDING |
| ADM-M15-03 | `AS`, du lieu seed co drill-down | Drill-down tu dashboard den module dung, hanh dong chi duoc phep khi vao dung man va co audit. | BD §11.2 - drill-down/audit | `assets/ADM-M15-03-pass.png` | `evidence/ADM-M15-03.md` | PENDING |
| ADM-M15-04 | `AS` | Smoke navigation Android qua 10 be mat quan tri: dashboard, nguoi dung, goi/cau hinh, Sale, payment, quy doi, noi dung/notification, doi soat, bao cao, audit/ho tro; loading/empty/error khong vo UI. | BD §11, §11.2-§12.2 | `assets/ADM-M15-04-pass.png` | `evidence/ADM-M15-04.md` | PENDING |

### M16 - Quan ly van hanh Admin

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-M16A-01 | `AS`/`AU`, user seed | Tim/loc user theo truong duoc phep, xem lich su can thiet; du lieu suc khoe nhay cam khong bi sua/tiet lo tuy tien. | BD §11.3, AC-24 | `assets/ADM-M16A-01-pass.png` | `evidence/ADM-M16A-01.md` | PENDING |
| ADM-M16A-02 | `AS`/`AU`, user seed | Khoa/mo khoa tai khoan voi ly do, thoi han, xac nhan va notification; status/quyen thay doi dung, co audit. | BD §11.3, §11.8 | `assets/ADM-M16A-02-pass.png` | `evidence/ADM-M16A-02.md` | PENDING |
| ADM-M16B-01 | `AS` co quyen cau hinh | Tao ban cau hinh goi/gia/quota/ty le quy doi co `effective_from`; khong sua giao dich/quyen lich su. | BD §11.4, AC-22 | `assets/ADM-M16B-01-pass.png` | `evidence/ADM-M16B-01.md` | PENDING |
| ADM-M16B-02 | `AU`/role khong du quyen | Thu soan/duyet ap dung cau hinh va mo deep link/API; bi tu choi theo permission, audit khi co hanh dong nhay cam. | BD §11.4 - separation/RBAC | `assets/ADM-M16B-02-pass.png` | `evidence/ADM-M16B-02.md` | PENDING |
| ADM-M16C-01 | `SR`, `AS` | Duyet/tu choi ho so Sale voi ly do; duyet chuyen active, cap ma duy nhat va co audit/notification. | BD §11.5, §7.2 | `assets/ADM-M16C-01-pass.png` | `evidence/ADM-M16C-01.md` | PENDING |
| ADM-M16C-02 | `SA`/`SS`/`SC`, `AS` | Tam dung/cham dut/cap lai/khoa ma theo policy; quan he va du lieu khach truc tiep khong lo suc khoe nhay cam. | BD §11.5, §7.3, AC-24 | `assets/ADM-M16C-02-pass.png` | `evidence/ADM-M16C-02.md` | PENDING |
| ADM-M16D-01 | `AF`, `PP`, conversion pending | Duyet/tu choi payment va quy doi voi ly do, timestamp, actor, audit; trang thai sau duyet khong bi ghi de truc tiep. | BD §11.6, AC-21 | `assets/ADM-M16D-01-pass.png` | `evidence/ADM-M16D-01.md` | PENDING |
| ADM-M16D-02 | `AU`/`AC`, `PP` | Admin khong co Finance thu duyet payment qua UI/deep link/API; backend/API tu choi. | BD §11.6, AC-20 | `assets/ADM-M16D-02-pass.png` | `evidence/ADM-M16D-02.md` | PENDING |
| ADM-M16E-01 | `AC`, segment seed | Tao/sua noi dung, FAQ, broadcast, template va feature flag theo moi truong; chi gui dung segment duoc phep va khong lo du lieu nhay cam. | BD §11.7 | `assets/ADM-M16E-01-pass.png` | `evidence/ADM-M16E-01.md` | PENDING |
| ADM-M16E-02 | `AC` va role han che | Theo doi AI/notification/sync va thu sua cau hinh ngoai quyen; UI bao loi phu hop, backend chan va khong hien raw PII. | BD §11.7 - ops/RBAC | `assets/ADM-M16E-02-pass.png` | `evidence/ADM-M16E-02.md` | PENDING |

### M17 - Tinh toan va doi soat

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-M17-01 | `AS`/`AF`, payment/entitlement/quota seed | Chay/yeu cau doi soat ky; doi chieu quyen goi, payment, quota, Diem Sale va Diem suc khoe voi du lieu nguon. | BD §12.1 - reconciliation | `assets/ADM-M17-01-pass.png` | `evidence/ADM-M17-01.md` | PENDING |
| ADM-M17-02 | `PX` approved, `RA`/`RB` | Commission job xu ly/retry cung khoa giao dich; ledger va so du nguyen tu, khong nhan doi. | BD §12.1 - idempotency, AC-16 | `assets/ADM-M17-02-pass.png` | `evidence/ADM-M17-02.md` | PENDING |
| ADM-M17-03 | Seed co sai lech co kiem soat | Bao cao sai lech dung loai (thieu/thua diem, trung, sai status, goi khong khop); xu ly bang adjustment, khong xoa lich su. | BD §12.1 - mismatch/adjustment | `assets/ADM-M17-03-pass.png` | `evidence/ADM-M17-03.md` | PENDING |
| ADM-M17-04 | `AF` va `AU` | Chon ky/bo loc va thu truy cap doi soat ngoai pham vi; Finance duoc xem/xu ly, Support bi chan, du lieu tai chinh khong dua tu UI cache. | BD §12.1 - RBAC/source | `assets/ADM-M17-04-pass.png` | `evidence/ADM-M17-04.md` | PENDING |
| ADM-M17-05 | `F0`, su kien M03/M08 da sua | Doi chieu/tinh lai Diem suc khoe theo phien ban cong thuc va chu ho so; khong tron voi Diem Sale hoac ghi de ket qua cu khong truy vet. | BD §12.1, §9 | `assets/ADM-M17-05-pass.png` | `evidence/ADM-M17-05.md` | PENDING |

### M18 - Thong ke va bao cao

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-M18-01 | `AS`/`AF`, du lieu seed da biet | Mo cac nhom bao cao san pham/goi/Sale/payment/van hanh; bo loc thoi gian, goi, Sale va status cho ket qua dung pham vi. | BD §12.2 - reporting | `assets/ADM-M18-01-pass.png` | `evidence/ADM-M18-01.md` | PENDING |
| ADM-M18-02 | `AF`, health data seed | Bao cao suc khoe hien dang tong hop/an danh khi khong can nhan dien; khong lo chat/ho so nhay cam. | BD §12.2 - privacy | `assets/ADM-M18-02-pass.png` | `evidence/ADM-M18-02.md` | PENDING |
| ADM-M18-03 | `AS`/role co export | Export Excel/CSV/PDF duoc phep, lay so lieu tai chinh tu ledger/giao dich nguon va tao log export. | BD §12.2, AC-23 | `assets/ADM-M18-03-pass.png` | `evidence/ADM-M18-03.md` | PENDING |
| ADM-M18-04 | `AU`/`AC` | Thu export qua UI/deep link/API; bi chan, khong tao file va khong lo du lieu. | BD §12.2, AC-23 | `assets/ADM-M18-04-pass.png` | `evidence/ADM-M18-04.md` | PENDING |
| ADM-M18-05 | `AS`, filter rong/loi tai du lieu | Empty/loading/error state Android ro rang; retry khong tao export trung hay lam sai bo loc da chon. | BD §12.2 - UI/retry | `assets/ADM-M18-05-pass.png` | `evidence/ADM-M18-05.md` | PENDING |

### M19 - Audit, bao mat va ho tro

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| ADM-M19-01 | `AS`, hanh dong payment/Sale/config | Mo audit log va loc theo thoi gian, actor, action, object, module; cac hanh dong bat buoc co ly do/timestamp/actor du. | BD §11.8, AC-21 | `assets/ADM-M19-01-pass.png` | `evidence/ADM-M19-01.md` | PENDING |
| ADM-M19-02 | `AU`/`AC` | Thu xem audit nhay cam, sua role hoac dung deep link/API ngoai scope; bi chan dung permission va khong lo du lieu khong can thiet. | BD §11.8 - RBAC | `assets/ADM-M19-02-pass.png` | `evidence/ADM-M19-02.md` | PENDING |
| ADM-M19-03 | `AS`, su kien gia lap an toan | Kiem tra canh bao login bat thuong, loi quyen va giao dich nghi trung; co thong tin can xu ly nhung da che du lieu nhay cam. | BD §11.8 - security monitoring | `assets/ADM-M19-03-pass.png` | `evidence/ADM-M19-03.md` | PENDING |
| ADM-M19-04 | `AU`/`AS`, ticket seed | Mo/xu ly ticket ho tro theo workflow, luu lich su va bang chung can thiet; khong dua PII/raw payload vao ghi chu. | BD §11.8 - support | `assets/ADM-M19-04-pass.png` | `evidence/ADM-M19-04.md` | PENDING |
| ADM-M19-05 | `AS`, thay doi role | Super Admin quan ly role/permission; thay doi co audit, co hieu luc sau refresh/relaunch va khong tao quyen ngam cho role khac. | BD §11.8 - role lifecycle | `assets/ADM-M19-05-pass.png` | `evidence/ADM-M19-05.md` | PENDING |

## Ma tran automated-only M10/M11 (E2E Android N/A)

M10/M11 khong tao `main_v3.dart`. Anh chinh la anh report test da che du lieu; note phai ghi command ID, danh sach test, DD reference, actual result va ly do E2E `N/A`.

### M10 - Theo doi nang cao va muc tieu

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| AUT-M10-01 | Free/Plus/FamilyPlus synthetic | Entitlement, tao muc tieu va retry cung business key dung contract; Free bi chan, paid duoc phep, khong tao muc tieu trung. | BD §6 M10; ADVANCED_TRACKING_GOALS-F01/FN01 | `assets/AUT-M10-01-pass.png` | `evidence/AUT-M10-01.md` | PENDING |
| AUT-M10-02 | Paid co du lieu theo ky | Roadmap theo subject/ky duoc tinh va luu dung; reload va loc subject khong tron du lieu. | BD §6 M10; ADVANCED_TRACKING_GOALS-F02/FN02 | `assets/AUT-M10-02-pass.png` | `evidence/AUT-M10-02.md` | PENDING |
| AUT-M10-03 | Repository success/empty/error/forbidden | Widget bao phu loading, locked, empty, ready, business error, system error va permission denied; action goi dung function. | DD ADVANCED_TRACKING_GOALS Views | `assets/AUT-M10-03-pass.png` | `evidence/AUT-M10-03.md` | PENDING |
| AUT-M10-04 | Paid co nhieu goal/stage | Multi-goal, giai doan, so sanh lich su va dieu chinh lich trinh/phan hoi khong ghi de lich su. | BD §6 M10; DD feature/function branches | `assets/AUT-M10-04-pass.png` | `evidence/AUT-M10-04.md` | PENDING |
| AUT-M10-05 | FamilyPlus owner/member/outsider | Chi subject cung package duoc truy cap; outsider va subject tuy y bi chan o use-case/contract, co audit an toan. | BD §6 M10, Q-15; DD ownership/security | `assets/AUT-M10-05-pass.png` | `evidence/AUT-M10-05.md` | PENDING |

### M11 - FamilyPlus

| Case ID | Persona / tien dieu kien | Kich ban va ket qua mong doi | Phu BD/AC | Anh PASS du kien | Ghi chu / log du kien | Trang thai |
| --- | --- | --- | --- | --- | --- | --- |
| AUT-M11-01 | FamilyPlus owner + 5 member synthetic | Group/member CRUD, duplicate request va gioi han toi da 5 thanh vien duoc enforce tai write/RPC; khong tao member thu sau. | BD §6 M11, Q-15; FAMILYPLUS-F01/FN01 | `assets/AUT-M11-01-pass.png` | `evidence/AUT-M11-01.md` | PENDING |
| AUT-M11-02 | Owner/joined member/outsider | Q-15 visibility va live RLS cho phep joined member xem thong tin trong cung package, chan outsider; khong dua `can_view` trai contract vao quyet dinh quyen. | BD §6 M11, Q-15; FAMILYPLUS ownership/RLS | `assets/AUT-M11-02-pass.png` | `evidence/AUT-M11-02.md` | PENDING |
| AUT-M11-03 | FamilyPlus chuyen subject | Onboarding, plan, dashboard, health score va notification doc/ghi dung subject; actor/subject duoc truy vet va khong ro ri cheo. | BD §6 M11; cross-module M01/M02/M03/M08/M09 | `assets/AUT-M11-03-pass.png` | `evidence/AUT-M11-03.md` | PENDING |
| AUT-M11-04 | Package active/expired + repository states | Widget bao phu loading, locked, empty, ready, business/system error, permission denied; expiry thu hoi quyen dung contract. | DD FAMILYPLUS Views/entitlement | `assets/AUT-M11-04-pass.png` | `evidence/AUT-M11-04.md` | PENDING |
| AUT-M11-05 | FamilyPlus payment owner + referral | Commission chi tinh tren phan gia cua owner; member add-on khong tao hoa hong sai, retry/reversal giu ledger nguyen tu. | BD Q-11; M11/M14 contract | `assets/AUT-M11-05-pass.png` | `evidence/AUT-M11-05.md` | PENDING |

## Gate bao cao cuoi chien dich

- Khong duoc ket luan “test toan bo he thong thanh cong” khi con case `PENDING`, `FAIL` hoac `BLOCKED` trong 17 module E2E hoac 10 case automated-only M10/M11.
- Moi `PASS` can co ghi chu case va anh tai duong dan da quy uoc; case khong co UI phai ghi ly do va bang chung backend/Android thay the trong ghi chu.
- Moi loi da fix can co lien ket fix, targeted test/analyze/format, retest tren dung entrypoint va anh PASS moi.
- Bao cao tong hop can phan biet ro: ket qua v2, ket qua Admin, M10/M11 automated-only va E2E N/A, failure baseline, va moi gioi han sandbox/RLS/backend policy.

## Tai lieu nguon

- [BD BioAI Product Flow Sale Admin v2.0](../../BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md)
- `.codex/workflows/test.md`
- `.codex/task-skills/test.md`
