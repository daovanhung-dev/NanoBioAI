Commit de xuat: fix(analyzer): dua flutter analyze ve trang thai sach

# Fixbug - Analyzer zero diagnostics

## Tom tat

- Sua toan bo 31 diagnostics da duoc xac nhan bang Flutter 3.47.1.
- Pham vi gom integration smoke tests, Nabi flags, notification care, Admin UI,
  sleep tracking, nutrition, logger va test doubles.
- Khong thay doi production schema, Supabase contract hoac migration.

## Cach sua

- Bo `await` khi goi entrypoint `main()` tra ve `void` trong hai integration
  smoke tests.
- Khoi phuc `NabiFeatureFlags.spriteMascotEnabled` voi gia tri mac dinh bat.
- Sua import planner notification care va danh dau cac controller concrete la
  `final` de phu hop voi Dart base class rules.
- Chuyen Admin radio selection sang `RadioGroup<String>` va doi dropdown form
  sang `initialValue` theo Flutter API moi.
- Bo sung method con thieu cho Admin/Sleep test fakes.
- Don cac loi null-safety, curly-braces, string interpolation, import va
  parameter naming trong cac file bi bao.
- Xoa helper Supabase test khong duoc tham chieu.
- Hoan thien fixture companion table trong test nutrition de kiem chung rich
  details van ton tai sau legacy replace; day la test-only schema, khong phai
  migration production.

## Kiem chung

- `flutter analyze`: PASS - `No issues found`.
- Bo test trong tam Admin, sleep, nutrition, Nabi notification va notification
  navigation: PASS - 36 tests.
- `flutter test` toan repo: FAIL do debt/failure co san o cac module khac;
  run den hon 1.096 tests va ghi nhan nhieu failure khong lien quan batch nay.
- `dart format` tren cac file patch: PASS.

## Luu y

- Working tree da co nhieu thay doi truoc khi bat dau; batch nay khong rollback
  hoac ghi de cac file ngoai pham vi diagnostics.
- Test SQLite can `libsqlite3.so`; moi truong nay chi co binary versioned nen
  targeted test duoc chay voi alias tam trong `/tmp`.
