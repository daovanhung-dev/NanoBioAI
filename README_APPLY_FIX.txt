NanoBioAI - Feature Hub runtime hotfix

NGUYÊN NHÂN
- App đang chạy file features_hub_page.dart cũ (card full-width).
- Bản compact 3 cột chưa được overlay vào project local đang chạy.
- Thay đổi StatelessWidget -> StatefulWidget và cấu trúc grid nên cần HOT RESTART/full restart.

CÁCH 1 - DỄ NHẤT
1. Giải nén ZIP này.
2. Mở PowerShell trong root project NanoBioAI (nơi có pubspec.yaml).
3. Chạy:
   powershell -ExecutionPolicy Bypass -File "<thu_muc_giai_nen>\APPLY_FEATUREHUB_FIX.ps1" -ProjectRoot "$PWD"
4. Sau đó DỪNG APP và chạy lại:
   flutter clean
   flutter pub get
   flutter run

CÁCH 2 - COPY THỦ CÔNG
Copy đè file:
lib\app_versions\v1\features\features_hub\presentation\pages\features_hub_page.dart
vào đúng path tương ứng trong project.
Sau đó hot restart hoặc chạy lại app.

KIỂM TRA
powershell -ExecutionPolicy Bypass -File "<thu_muc_giai_nen>\VERIFY_FEATUREHUB_FIX.ps1" -ProjectRoot "$PWD"

KẾT QUẢ MONG ĐỢI
- Mobile: 3 shortcut / hàng.
- 15 shortcut runtime thật.
- Không còn card full-width + subtitle + arrow ở khu vực chính.
- Sắp ra mắt và Theo dõi chuyên sâu đóng mặc định.
