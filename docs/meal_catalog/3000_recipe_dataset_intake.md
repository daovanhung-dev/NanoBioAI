# Tiếp nhận bộ dữ liệu 3.000 món

## Mục tiêu và trạng thái

Mục tiêu là giữ 163 món hiện tại và có thể bổ sung 3.000 món candidate cho lịch wellness theo quyết định trực tiếp của người dùng ngày 2026-10-16. Candidate vẫn mang trạng thái dinh dưỡng, loại bữa, dị ứng/chống chỉ định và recipe chưa rà soát; quyết định này không xác nhận license hoặc tính chính xác dữ liệu. Không được coi các món đó là lời khuyên điều trị hay dinh dưỡng đã xác minh. Xem [biên bản rà soát](3000_recipe_dataset_review_2026-10-16.md) và [nghiên cứu nguồn có license](open_recipe_source_research_2026-10-16.md).

## JSON candidate trong workspace

`assets/data/nabi_3000_mon_viet_moi.json` là JSON candidate được kiểm tra trong phiên tích hợp ngày 2026-10-16. File có 3.000 dòng và 3.000 mã duy nhất; các mã không trùng 163 mã hiện tại. Kích thước file là 8.084.717 byte. Cả 3.000 dòng đều đặt `is_active=true`, `is_plan_eligible=false`, `meal_type=unclassified`, `nutrition_status=estimated_unverified`, `constraint_metadata_status=awaiting_professional_review` và `metadata_status=ai_generated_needs_review`. Có 466 dòng thiếu `water_ml`; không có hồ sơ rights hoặc nutrition evidence theo món trong JSON. Không sao chép `is_active=true` thành quyền chọn món.

JSON gốc được giữ nguyên. Ứng dụng đóng gói JSON này cùng 163 món hiện có, seed 3.163 hàng khi cài mới và chèn 3.000 mã candidate bằng SQLite v36 khi nâng từ v35. Chỉ lịch wellness được gửi mã/tên candidate cho AI; chi tiết món được nạp từ SQLite sau khi chọn. Các cờ và trạng thái chưa rà soát được giữ nguyên, `is_plan_eligible=false`; policy strict không chọn candidate. Không ghi đè JSON gốc.

Candidate chỉ được đưa vào lịch wellness khi hồ sơ không có dị ứng hoặc món cần tránh chưa xác minh; các điều kiện đó tiếp tục fail-closed. Lịch không được trình bày số dinh dưỡng ước tính chưa xác minh như số liệu đã biết.

## Trạng thái candidate ngày 2026-10-16

- Gói chứa 3.000 công thức mở rộng với 3.000 ảnh minh họa WEBP theo mã. SHA-256 của danh sách `recipes` khớp trường `source_sha256`; archive toàn vẹn và hai bản ZIP có cùng SHA-256.
- `meal_catalog_3000_provenance.json` chỉ mô tả nguồn/giấy phép ảnh minh họa. Gói không có `rights.csv` hoặc thư mục bằng chứng license; các dòng recipe tự ghi là công thức ghép độc lập, không lấy từ công thức đã thử nghiệm.
- Cả 3.000 dòng đều `nutrition_status=estimated_unverified`, `verified_nutrients=null`, không có `nutrition_food_ids` hoặc ngày bằng chứng dinh dưỡng; liên kết USDA là tham chiếu phương pháp chung, không phải đối chiếu từng nguyên liệu.
- Cả 3.000 dòng đều `is_active=false` và `is_plan_eligible=false`. Không bật chúng cho AI/lập lịch cho đến khi nguồn, phép tính và bước nấu được rà soát.
- Gói thêm 3.000 món vào 163 món gốc sẽ tạo 3.163 dòng. Script merge đi kèm chỉ chọn 2.837 món mở rộng để xuất đúng 3.000 tổng, nên không dùng nguyên trạng nếu cần giữ toàn bộ dữ liệu.
- Ứng dụng gửi danh sách mã/tên và tóm tắt trong ngân sách prompt; sau khi AI chọn mã, ứng dụng nạp chi tiết món từ SQLite. Không gửi toàn bộ 3.000 công thức đầy đủ trong một request.

## Nguồn thương mại đã khảo sát

Pepesto hiện công bố hơn 70.000 recipe có license vĩnh viễn, kèm JSONL, ingredients/steps, calories/macros, dị ứng EU-14 và ảnh 1024×1024. Tier 1.000–9.999 niêm yết €0,90/recipe; 3.000 tiếng Anh ước tính €2.700. Ngôn ngữ khác cộng €0,30/món; danh sách locale công bố hiện không có tiếng Việt. Trang vendor mô tả nội dung là human-authored/curated, nhưng cần lấy mẫu để kiểm tra thực tế, nhất là nutrition có phải per-serving hay total-recipe và cách xử lý portions dạng khoảng. Chưa tạo checkout hoặc mua dữ liệu. Xem [nghiên cứu nguồn](open_recipe_source_research_2026-10-16.md).

## Kiểm kê catalog hiện có

Kiểm tra `assets/data/meal_catalog_v1.json` ngày 2026-10-16:

- Có 163 mã món duy nhất; 20 nhóm tên món xuất hiện lặp lại. Mã trùng lặp bằng 0.
- Tên, mô tả, nguyên liệu và bước nấu có ở 163/163 dòng. Loại bữa là `unclassified` ở cả 163 dòng.
- Khẩu phần và các trường năng lượng, protein, carbohydrate, chất béo, chất xơ, nước đều trống ở 163/163 dòng; `plan_eligible` là false ở cả 163 dòng.
- Không có trường ảnh hoặc license trong JSON. 124 ảnh nguồn hiện có khớp tên của 163 dòng; tên trùng dùng chung ảnh. Ảnh mới sẽ được ánh xạ theo mã món để hỗ trợ từng bản ghi riêng.

## Gói đầu vào

Đặt bundle hợp nhất chưa duyệt trong một thư mục tạm, không ghi đè catalog runtime hoặc JSON candidate gốc:

```text
incoming/meal_catalog_v1_candidate.json
incoming/rights.csv
incoming/licenses/                 # bản license, hợp đồng hoặc điều khoản nguồn
```

Bundle cần có đúng 3.163 dòng: giữ đủ 163 mã hiện tại và thêm đủ 3.000 mã candidate duy nhất. Mỗi món mới cần mã ổn định, tên, loại bữa đã rà soát, mô tả, nguyên liệu có lượng, bước nấu đã rà soát, khẩu phần, dinh dưỡng đã xác minh, thẻ dị ứng/chống chỉ định cùng evidence và trạng thái duyệt. Các dòng legacy hiện tại được giữ nguyên và không bị ép qua tiêu chí duyệt dành cho món mới.

`rights.csv` có một dòng cho mỗi mã món và các cột:

```text
code,recipe_source_url,recipe_license,recipe_attribution,nutrition_source_url,nutrition_evidence_date,nutrition_evidence_version
```

`rights.csv` chỉ cần rights/provenance của recipe và dinh dưỡng; không yêu cầu ảnh. Bản quyền ảnh, nếu được thêm trong một phạm vi riêng sau này, cần được quản lý độc lập.

## Kiểm tra gói

```bash
python3 tools/validate_meal_catalog_bundle.py \
  incoming/meal_catalog_v1_candidate.json \
  --rights-csv incoming/rights.csv \
  --license-dir incoming/licenses
```

Validator yêu cầu đúng 3.163 dòng, đủ 3.000 mã mới ngoài 163 mã cơ sở, năm loại bữa M02, dữ liệu dinh dưỡng không âm, `source_verified`, nutrition/constraint/allergen status đã xác minh, rights/provenance cho từng món mới và license evidence. Validator không tự chứng minh license cho phép phân phối lại, không xác nhận nguồn có thẩm quyền, không thẩm định tính chính xác dinh dưỡng, công thức hoặc công dụng y khoa. Người có thẩm quyền vẫn phải rà soát các evidence trước khi nhập.

Intake contract bên dưới vẫn là cổng bắt buộc trước khi đánh dấu món mới là đã rà soát, plan-eligible hoặc dùng trong policy strict. Việc hiện tại đưa danh sách code/name vào policy wellness theo chỉ thị người dùng không phải bằng chứng rằng license cho phép phân phối; hồ sơ quyền sử dụng và rà soát chuyên môn vẫn chưa có.

Migration v36 chỉ chèn mã candidate còn thiếu và xác minh hash, không xóa các món đã lưu hoặc dữ liệu người dùng. Trước khi nâng trạng thái duyệt, vẫn cần rights/license cho recipe, provenance dinh dưỡng theo nguyên liệu hoặc nguồn đã đối chiếu, và rà soát từng công thức/bước nấu.
