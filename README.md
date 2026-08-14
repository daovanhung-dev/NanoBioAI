# NanoBio — Meal catalog source-fidelity patch

## Mục tiêu

Khóa dữ liệu `public.meal_catalog` trong `docs/supabase/seed_data.sql` theo đúng nguồn:

`docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`

Source contract hiện tại: **163 công thức / 64 chủ đề / 11 chương**.

## File trong bản vá

- `tools/sync_meal_catalog_sql.py`: parse Markdown và tái sinh toàn bộ block `meal_catalog` deterministic.
- `docs/supabase/validate_meal_catalog.sql`: assertion chạy sau `setup.sql` + `seed_data.sql`.
- `validation/REPORT.md`: bằng chứng/phạm vi kiểm tra trong phiên này.

## Cách áp vào repository

Đặt hai file đúng đường dẫn tương ứng, sau đó ở repository root chạy:

```bash
python tools/sync_meal_catalog_sql.py
python tools/sync_meal_catalog_sql.py --check
python tools/validate_meal_catalog.py
```

Sau khi rebuild Supabase local/sandbox bằng `setup.sql` + `seed_data.sql`, chạy thêm:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/supabase/validate_meal_catalog.sql
```

## Quy tắc fidelity

Tool chỉ lấy từ Markdown các trường: chương, chủ đề, mô tả chủ đề, tên món, trang PDF, nguyên liệu, cách làm, công dụng, thứ tự, và hash nguồn. Không tự sửa những điểm bất thường trong tài liệu nguồn.

Các trường dinh dưỡng không có trong Markdown **không được coi là dữ liệu dinh dưỡng thật**. SQL/SQLite NanoBio hiện dùng `0` làm sentinel kỹ thuật; các row nguồn vẫn bắt buộc có:

- `nutrition_status = 'missing_source_data'`
- `constraint_metadata_status = 'awaiting_professional_review'`
- `metadata_status = 'source_imported'`
- `is_plan_eligible = false`
- `meal_type = 'unclassified'`

Điều này giữ tương thích với local SQLite (`NOT NULL DEFAULT 0`) mà không biến số 0 thành metadata đã được duyệt.
