# Worklog 005 - Hoi quy v2 + Admin

- Pham vi: M01-M09, M12-M19 tren Android `12b304f9`; M10/M11 V3 planned, ngoai E2E.
- Da doc workflow test/bugfix va dung ma tran `docs/test/v2-admin-regression/001-test-v2-admin-regression.md`.
- Preflight: xac nhan device/package, dung `.env` local da ignore, reset bang `adb -s 12b304f9 shell pm clear com.example.nano_app` giua hai entrypoint.
- V2: chay onboarding, validation, consent, tao lich fallback, dashboard/menu, body metrics va auth validation; luu anh trong `docs/test/v2-admin-regression/assets/`.
- Admin: chay login/validation, dashboard, drawer, users va reports. Phat hien `RIGHT OVERFLOWED BY 39 PIXELS` tren work-item report; sua `_MetaPill` de text co the co lai, format/analyze pass, hot-reload va chup lai `ADMIN-M18-REPORTS-002-fixed.png`.
- Them asset directories cho frame animation 30fps trong `pubspec.yaml`; clean rebuild khong con asset-not-found trong log runtime.
- Cap nhat test stale expectation theo UI hien tai; targeted analyze/test pass. Full suite van can chay diagnostic va phan loai failure truoc khi ket luan.
- Bao mat: khong ghi endpoint, token, mat khau seed hay PII vao artifact; runtime log redirect phai xoa sau khi dung.

## Tu kiem tra

- [x] Khong thay doi public API hay business rule.
- [x] Patch UI nho, co retest va evidence sau fix.
- [ ] Chua hoan tat 101 case; cac case chua co evidence van giu PENDING.
