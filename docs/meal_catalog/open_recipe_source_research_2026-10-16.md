# Rà soát nguồn mở cho catalog công thức

## Phạm vi và kết luận

Khảo sát ngày 2026-10-16 các nguồn công thức có giấy phép và nguồn dinh dưỡng công khai để tìm đường đạt ít nhất 3.000 món. Chưa nguồn nào được xác nhận đồng thời có đủ 3.000 công thức dùng lại được, ảnh hợp lệ cho từng món, dinh dưỡng theo khẩu phần và thẩm định phù hợp cho mọi nhóm sức khỏe. Không nhập các nguồn khảo sát vào catalog runtime trong bước này.

## Nguồn đã khảo sát

| Nguồn | Quy mô hoặc dữ liệu quan sát được | Quyền sử dụng | Khoảng trống đối với yêu cầu NanoBioAI |
| --- | --- | --- | --- |
| Wikibooks Cookbook | API danh mục `Category:Recipes` trả 3.830 trang; liệt kê thành viên cho thấy 3.797 trang namespace `Cookbook`, 32 trang `User`, 1 trang chính và 15 danh mục con. `Recipes with images`: 836 trang; `Recipes with metric units`: 895 trang. | Phần lớn văn bản theo CC BY-SA 4.0 và GFDL; phải ghi công và nội dung sửa đổi phải theo ShareAlike. Một số trang chỉ theo CC BY-SA; ảnh/tư liệu không phải văn bản có license riêng, có thể có nội dung fair use. | Số trang không đồng nghĩa với số công thức đã xác minh. Mẫu đọc trực tiếp có cả định lượng mơ hồ (`to taste`, `measures`), không có dinh dưỡng nhất quán và không được thẩm định y khoa. Chỉ 836 trang được gắn danh mục có ảnh; từng ảnh còn cần kiểm tra license riêng. |
| USDA MyPlate Kitchen | Trang công thức mẫu chính thức có định lượng, hướng dẫn, khẩu phần, dinh dưỡng và nguồn đóng góp; ví dụ Chicken Tortilla Casserole ghi nguồn ONIE Project. | Trang mẫu ghi nguồn từ đối tác/extension; cần xác minh quyền của nguồn đóng góp và ảnh theo từng recipe trước khi đóng gói. | Chưa tìm được manifest/export chính thức đang hoạt động chứng minh số lượng và quyền phân phối toàn bộ thư viện. Một archive bên thứ ba tự công bố 1.072 recipe nhưng không dùng con số đó làm kiểm kê chính thức. |
| RecipeDB (IIIT-Delhi) | Nghiên cứu về recipe và hồ sơ dinh dưỡng, lấy dữ liệu từ nhiều nguồn web và dữ liệu thành phần USDA. | FAQ của dự án ghi dữ liệu tải xuống theo CC BY-NC-SA 3.0. | Điều khoản NonCommercial không phù hợp để đưa vào app nếu hoạt động/phân phối thương mại chưa được cấp quyền riêng. Dù có dinh dưỡng, ảnh và quyền từng recipe vẫn cần rà soát. |
| USDA FoodData Central | Có dữ liệu thành phần thực phẩm; bộ Foundation Foods, FNDDS và SR Legacy có thể tải xuống. | USDA ghi dữ liệu FDC theo CC0 1.0, đề nghị dẫn nguồn. | Đây là dữ liệu thành phần thực phẩm, không cấp quyền cho recipe hoặc ảnh của nguồn khác và không tự xác nhận dinh dưỡng của món đã nấu. |
| Pepesto self-serve recipe dataset | Nhà cung cấp tự công bố hơn 70.000 recipe, JSONL từng dòng; trang dataset mô tả nguyên liệu, bước nấu, thời gian, portions, calories/macros, danh sách dị ứng EU-14, ảnh WebP 1024×1024 và mã license. | Nhà cung cấp công bố license vĩnh viễn, cho phép lưu/hiển thị recipe trong app mà không cần ghi công; API terms cho phép dùng thương mại và kết hợp nội dung khác. | Là lựa chọn gần form nhất nhưng là nguồn trả phí và claim chất lượng do chính nhà cung cấp công bố. Tier 1.000–9.999 là €0,90/món: 3.000 món tiếng Anh khoảng €2.700; ngôn ngữ khác cộng €0,30/món (khoảng €3.600 nếu đủ 3.000). Danh sách locale hiện không có tiếng Việt. Ví dụ dataset cho nutrition toàn recipe kèm portions dạng khoảng; cần mua mẫu để xác minh quy đổi/serving, dữ liệu còn thiếu fiber/water và provenance nguồn gốc từng recipe. |
| Open Recipe Archive (GitHub) | README ghi 54.843 recipe lịch sử trong 31 collection, mỗi dòng có ingredients/directions cùng tác giả, tên/năm/URL nguồn và license. | Repo mô tả nội dung lịch sử là public domain, có provenance theo từng dòng; cần kiểm tra URL gốc và license từng dòng trước khi dùng. | Không cung cấp ảnh món ăn, nutrition hoặc khẩu phần chuẩn hóa; dữ liệu lịch sử cần rà soát để dùng làm recipe wellness hiện đại. |
| Epicurious scrape dataset mirror | README của mirror ghi 13.000 recipe đã scrape từ Epicurious và gắn CC BY-SA 3.0. | License tại mirror không chứng minh người tải lên có quyền cấp lại quyền cho văn bản/ảnh từ Epicurious. | Không dùng làm nguồn nếu chưa có giấy phép từ chủ thể quyền hoặc nhà cung cấp có thẩm quyền; bản mirror đã bỏ ảnh. |
| Vietnamese Recipe Dataset (PTIT-KLTN) | README mô tả crawler lấy tên món, nguyên liệu, cách làm và khẩu phần từ Điện Máy Xanh. | Danh sách file trong repository không có file license; không suy ra quyền dùng recipe từ quyền đối với mã crawler. | Chưa chứng minh quyền sao chép/phân phối recipe và ảnh; không có nutrition theo món trong form được mô tả. |
| xlabsinc/global-recipes | README tự khai 420 recipe thuộc 16 nhóm ẩm thực; có 2 file Vietnamese. | Repository ghi MIT, nhưng không có bằng chứng quyền riêng theo từng recipe hoặc nguồn ảnh. | Chỉ 420 món; schema README không có nutrition hoặc ảnh, và chính README liệt kê ảnh/nutrition là tính năng tương lai. Không đạt số lượng hay form. |
| global-recipe-db | README tự khai 75.321 recipe, nhưng file database 276 MB không có trong repository; bảng nguồn ghi cả license Unknown/CC và Fair use. | README nói recipe giữ license của nguồn; MIT chỉ áp dụng cho scripts, không phải blanket license cho dữ liệu. | Không phải gói dữ liệu tải dùng trực tiếp; nguồn trộn chưa rõ quyền/fair use, schema công bố không có ảnh hay nutrition chuẩn. Không dùng tổng số 75.321 như số recipe đã cleared. |
| Palate Canonical 250 | 250 recipe mẫu có nguyên liệu theo gram, steps/timing, macro theo 100 g; mẫu chia đều 36 ẩm thực, có Vietnamese. Trang sản phẩm nêu toàn corpus riêng có 4.566 recipe. | Bản mẫu tải công khai theo CC BY-NC 4.0; trang yêu cầu liên hệ trước khi dùng thương mại. License và quyền cấp dữ liệu của toàn bộ 4.566 món chưa được công bố trong gói mẫu. | Mẫu chỉ có 250 món, không có ảnh cho từng món trong schema công khai, cờ chế độ ăn/dinh dưỡng là ước tính engine và được nhà cung cấp ghi rõ không dùng làm quyết định dị ứng. Chỉ là đầu mối xin báo giá/license, chưa đủ điều kiện nhập. |

## Ghi chú chất lượng nguồn

- Wikibooks tự nêu quy tắc ghi công, ShareAlike, kiểm tra license theo từng tệp media và cảnh báo rằng nội dung fair use không tự chuyển thành CC BY-SA. Cookbook FAQ cũng yêu cầu không đăng recipe do AI tạo trừ khi người đóng góp đã tự nấu và xác nhận công thức tốt; điều này không chứng minh tất cả trang hiện có đã được chuyên gia hoặc người dùng kiểm nghiệm.
- Mẫu trang USDA MyPlate có cấu trúc gần với form catalog hơn: ingredients, directions, servings, nutrition và source attribution. Tuy vậy, trường `Source` có thể chỉ đến trường đại học hoặc tổ chức đối tác nên cần quyền tương ứng cho việc lưu, sửa, phân phối offline.
- FDC phù hợp làm căn cứ thành phần nguyên liệu khi đã đối chiếu chính xác loại/thể trạng/khối lượng; không thay thế quy trình quy đổi khẩu phần, yield/retention sau nấu hoặc kiểm nghiệm món hoàn chỉnh.
- Pepesto hiện là lựa chọn thương mại gần yêu cầu nhất về số lượng, ảnh, nutrition macros và license hiển thị trong app. Tuy nhiên trang agent của nhà cung cấp không liệt kê locale `vi`; các trường calories/macros của dataset cần đối chiếu trên mẫu vì ví dụ có `portions` dạng khoảng và số năng lượng lớn cho toàn recipe. Trang vendor mô tả nhóm recipe là human-authored/curated và ảnh là AI-generated; đây là claim của vendor, chưa phải xác minh độc lập.
- Trang agent ghi license proof chứa thời điểm mua, tên recipe và email người mua. Nếu dùng nguồn này, giữ proof trong kho riêng không public asset/app source. Trang này cũng ghi agent có thể tạo checkout nhưng không thể thanh toán; chưa tạo checkout hoặc phát sinh chi phí.
- Open Recipe Archive có provenance hữu ích để tìm công thức lịch sử gốc, nhưng không tự đáp ứng ảnh/nutrition/serving schema. Dùng làm nguồn tham khảo theo từng recipe chỉ sau khi kiểm tra bản gốc.
- Bộ Vietnamese Recipe Dataset mô tả rõ việc scrape Điện Máy Xanh và có recipe steps/servings, nhưng file listing không có LICENSE; việc công khai mã crawler không cấp quyền cho nội dung nguồn.
- Hai repository tổng hợp `xlabsinc/global-recipes` và `global-recipe-db` không giải quyết yêu cầu dữ liệu: repository đầu chỉ khai 420 món và để ảnh/nutrition ở roadmap; repository sau ghi rõ license theo từng nguồn, bao gồm `Unknown / CC` và `Fair use`, trong khi database không nằm trong Git.
- Palate là đầu mối có mẫu cấu trúc dinh dưỡng gần form nhất: 250 món theo CC BY-NC 4.0 có gram-normalized ingredients và macro/100 g, nhưng phải xin quyền thương mại riêng và xác minh ảnh/quyền của full corpus trước khi cân nhắc. Các macro/flags của trang được mô tả là best-effort, không thay thế quyết định dị ứng.

## Đối chiếu gói candidate trong Downloads

Ghi chú: các cờ `is_active=false` dưới đây nói về archive trong Downloads. JSON khác, `assets/data/nabi_3000_mon_viet_moi.json`, được kiểm tra trong workspace ngày 2026-10-16 có 3.000 mã mới nhưng lại đặt `is_active=true`; mọi dòng vẫn `is_plan_eligible=false`, `unclassified`, `estimated_unverified`, `awaiting_professional_review` và `ai_generated_needs_review`. Cờ `is_active` không phải bằng chứng duyệt.

- Gói hiện có ghi 3.000 code và tên món, nhưng `source_name` khai báo đây là các biến thể tự ghép, không được lấy từ recipe đã thử nghiệm. Provenance chỉ mô tả hình minh họa được tạo bằng chương trình; ảnh mẫu là minh họa dạng vector, không mô tả chính xác món đã nấu.
- 3.000/3.000 dòng vẫn có `nutrition_status=estimated_unverified`, không có FDC ID hoặc ngày chứng cứ dinh dưỡng; tất cả `is_active=false` và `is_plan_eligible=false`. Bundle không kèm bằng chứng license cho recipe.
- Mô phỏng serialization cục bộ theo giới hạn hiện có của `MealPlanPrompt`: JSON gồm 3.000 code/tên là 297.314 byte; thêm đoạn tóm tắt thứ nhất của mỗi mô tả là 1.662.627 byte. Với ngân sách 1.000.000 byte, thuật toán hiện tại giữ mọi code/tên và rút phần tóm tắt xuống tối đa 211 byte đồng đều (JSON danh mục 998.082 byte). Đây là phép đo kích thước UTF-8, không phải số token Gemini và không phải lời gọi model.
- JSON đầy đủ của 3.000 recipe candidate là 15.035.627 byte, lớn hơn giới hạn request body 1.500.000 byte của Edge Function. Vì vậy luồng hiện tại gửi chỉ mục toàn bộ món (code, tên, tóm tắt có thể rút gọn), rồi nạp chi tiết của các mã AI chọn từ SQLite; không thể gửi nguyên văn toàn bộ công thức trong một request hiện hành.

## Bước tiếp theo

Tiếp tục chờ bộ dữ liệu có license được người dùng cung cấp. Bundle cần có quyền phân phối offline/sửa đổi/hiển thị attribution cho recipe và ảnh; hồ sơ nutrition phải chỉ rõ nguồn, phiên bản, ngày, đối chiếu nguyên liệu/khẩu phần và cách tính. Chỉ sau đó mới nhập, rà soát công thức, đánh giá dị ứng/điều kiện, và bật các món đủ điều kiện cho AI lập lịch.

Nếu dùng Pepesto, cần người dùng tự cung cấp batch/checkout đã thanh toán hoặc một license hợp lệ; không tự mua. Trước batch lớn cần mẫu dữ liệu để xác nhận license, calories/macros là per-serving hay per-recipe, portions, dịch sang tiếng Việt và ảnh theo recipe. Chi phí 3.000 món tiếng Anh niêm yết ước tính €2.700; vendor không liệt kê tiếng Việt trong locale được hỗ trợ.

Tài liệu intake: [3000_recipe_dataset_intake.md](3000_recipe_dataset_intake.md). Rà soát bundle hiện tại: [3000_recipe_dataset_review_2026-10-16.md](3000_recipe_dataset_review_2026-10-16.md).

## Nguồn tham khảo

- [Wikibooks — Category:Recipes](https://en.wikibooks.org/wiki/Category:Recipes)
- [Wikibooks API — categoryinfo cho Category:Recipes](https://en.wikibooks.org/w/api.php?action=query&prop=categoryinfo&titles=Category%3ARecipes&format=json)
- [Wikibooks API — categoryinfo cho Recipes with images](https://en.wikibooks.org/w/api.php?action=query&prop=categoryinfo&titles=Category%3ARecipes%20with%20images&format=json)
- [Wikibooks API — categoryinfo cho Recipes with metric units](https://en.wikibooks.org/w/api.php?action=query&prop=categoryinfo&titles=Category%3ARecipes%20with%20metric%20units&format=json)
- [Wikibooks copyright policy](https://en.wikibooks.org/wiki/Wikibooks:Copyrights)
- [Wikibooks Cookbook FAQ](https://en.wikibooks.org/wiki/Cookbook:FAQ)
- [USDA MyPlate — Chicken Tortilla Casserole](https://www.myplate.gov/recipes/chicken-tortilla-casserole)
- [RecipeDB FAQ and license](https://cosylab.iiitd.edu.in/recipedb/FAQ)
- [USDA FoodData Central API guide and license](https://fdc.nal.usda.gov/api-guide/)
- [USDA FoodData Central downloadable datasets](https://fdc.nal.usda.gov/download-datasets/)
- [Pepesto licensed recipe dataset and pricing](https://www.pepesto.com/recipe-dataset/)
- [Pepesto dataset instructions, locales, schema and pricing](https://www.pepesto.com/recipe-dataset-agent/)
- [Pepesto API terms](https://www.pepesto.com/api-terms/)
- [Open Recipe Archive](https://github.com/AdamBouhmad/open-recipe-archive)
- [Epicurious scrape mirror and license claim](https://github.com/josephrmartinez/recipe-dataset)
- [Vietnamese Recipe Dataset by PTIT-KLTN](https://github.com/PTIT-KLTN/vietnamese_recipe_dataset)
- [xlabsinc/global-recipes](https://github.com/xlabsinc/global-recipes)
- [global-recipe-db and its per-source license table](https://github.com/drwjkirkpatrick-web/global-recipe-db)
- [Palate Canonical 250 data and license](https://palate.kitchen/data)
