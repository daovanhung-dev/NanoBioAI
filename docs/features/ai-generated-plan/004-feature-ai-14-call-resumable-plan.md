Commit de xuat: feat(ai): tao lich 14 luot co the tiep tuc

# Tạo lịch cá nhân bằng 14 lượt AI có thể tiếp tục

> Lịch sử: mô tả triển khai ban đầu. Cách gửi catalog hiện tại được cập nhật trong `005-feature-full-catalog-ai-context.md`.

## Mục tiêu

- Tách kế hoạch 7 ngày thành 14 yêu cầu nhỏ: mỗi ngày tạo 5 bữa rồi 2 hoạt động.
- AI chỉ chọn mã từ các ứng viên hoạt động đã được ứng dụng lọc; nội dung chuẩn được đọc từ SQLite.
- Giữ từng phần mã đã xác thực trong SQLite staging để có thể tiếp tục sau gián đoạn.
- Khi một ngày đã đủ 5 bữa và 2 hoạt động, chuẩn hóa, dựng, xác thực rồi lưu ngày đó vào lịch chính bằng một transaction SQLite. Lỗi ở ngày sau không xóa các ngày đã lưu.
- Khi backend AI lỗi, tạo gợi ý từ catalog SQLite đang hoạt động và đã qua bộ lọc an toàn; đánh dấu nguồn `local_fallback` để giao diện nhận biết đây là gợi ý cơ bản.

## Luồng tạo lịch

1. Ứng dụng đọc hồ sơ cục bộ tối thiểu, mục tiêu, dị ứng/giới hạn đã lưu, lịch sinh hoạt, tùy chọn vận động và catalog SQLite đang hoạt động. Bộ lọc tại thiết bị loại ứng viên không đáp ứng các ràng buộc đã biết hoặc còn thiếu xác minh liên quan.
2. Với từng ngày theo thứ tự 1–7, ứng dụng gọi một lượt tạo bữa rồi một lượt tạo vận động. Mỗi prompt chỉ chứa catalog phù hợp với loại lịch đó, dưới dạng tóm tắt ngắn của các ứng viên đã lọc; mã đã dùng ở các ngày trước được đưa vào để giảm lặp.
3. Prompt bữa gửi mã, loại bữa, tên, trạng thái chất lượng rút gọn và chỉ số dinh dưỡng đã xác minh nếu có. Prompt vận động gửi mã, nhóm, tên, đơn vị, cường độ, mục tiêu, dụng cụ và trạng thái an toàn. Không gửi tên người dùng, định danh, ghi chú tự do, thuốc, xét nghiệm hoặc hồ sơ sức khỏe.
4. AI trả cấu trúc tối giản: bữa gồm `day`, `meal_type`, `meal_code`; vận động gồm `day`, `exercise_code`. Ứng dụng xác thực ngày, số lượng, slot, mã, hoạt động catalog và quy tắc lặp; sau đó nạp chi tiết chuẩn từ SQLite và gán giờ theo sở thích sinh hoạt cùng mục tiêu mặc định.
5. Mỗi phần hợp lệ được lưu riêng vào SQLite staging cùng `request_id`, dấu vân tay đầu vào, dấu vân tay catalog, phiên bản prompt và nguồn tạo. Khi tiếp tục, ứng dụng tái dùng các phần staging nếu hồ sơ, catalog và phiên bản prompt khớp; nếu dấu vân tay đổi, phần staging cũ bị xóa và tạo lại.
6. Sau khi đủ phần của một ngày, ứng dụng chuẩn hóa 5 bữa và 2 hoạt động từ catalog, dựng các mục lịch, xác thực ngày rồi lưu toàn bộ dữ liệu ngày đó cùng bộ đếm tiến độ và nguồn tạo trong một transaction SQLite. Ngày chưa hoàn chỉnh không được đưa vào lịch chính.
7. Khi đủ mọi ngày, ứng dụng xác thực toàn lịch 35 bữa/14 hoạt động và số dòng đã lưu; transaction cuối chỉ đánh dấu yêu cầu thành công, đặt cờ lịch đầu tiên nếu là khách và xóa staging. Transaction cuối không ghi đè lại lịch từng ngày.

## Giới hạn dữ liệu và lượt gọi

- Mỗi nội dung prompt và payload gửi backend được kiểm tra dưới 32.000 ký tự trước khi gọi. Bộ catalog món hiện có 163 mã hoạt động; kiểm thử tải asset thực xác nhận prompt gọn chứa đủ mã và payload bọc backend vẫn dưới giới hạn.
- Mọi ứng viên đủ điều kiện và đang hoạt động được tóm tắt trong prompt; AI không nhận toàn bộ công thức, hướng dẫn nấu, ảnh hoặc hồ sơ sức khỏe. Bản ghi không hoạt động hoặc bị bộ lọc cục bộ loại không được gửi.
- Tối đa 18 lần gọi backend trong một phiên tiếp tục. HTTP 429 hoặc hết giới hạn chuyển phần hiện tại sang catalog fallback nếu có đủ ứng viên hợp lệ; các phần AI đã staging vẫn được giữ để tiếp tục. Mỗi lần tạo/tiếp tục chỉ kiểm tra quota một lần trước kế hoạch; chỉ lịch được tạo hoàn toàn bằng AI mới commit quota.
- Lượt lỗi có thể được gọi lại bằng cùng yêu cầu; yêu cầu chưa hoàn tất được tìm lại theo người dùng, chế độ tác nhân và số ngày. Ngày bắt đầu của yêu cầu đã lưu được giữ khi tiếp tục.

## Catalog và ranh giới an toàn

- SQLite v31 giữ staging cho lịch và metadata nguồn/trạng thái duyệt của bài tập. Schema bằng chứng, thành phần và bộ lọc món ăn đã được bổ sung trong migration v29–v30; migration v31 không thay mã, hash hay payload nguồn của 163 món.
- 16 bài vận động M02 hiện hữu tiếp tục hoạt động. 24 bài M32 được lưu với trạng thái chờ rà soát và không hoạt động; không tự nâng trạng thái lâm sàng/QA.
- Dữ liệu chưa xác minh vẫn để trống hoặc `unknown`; không suy diễn giá trị dinh dưỡng, tình trạng dị ứng hay chống chỉ định. AI hỗ trợ xếp lịch wellness và không kết luận an toàn y khoa hoặc tạo lịch điều trị.
- Danh mục hiện tại có thể thiếu dữ liệu đã xác minh cho ràng buộc của một người. Trong trường hợp bộ lọc không tìm đủ ứng viên, ứng dụng dừng và không dùng lịch chung thay thế.
- Local fallback chỉ chọn mã hoạt động đủ điều kiện theo hồ sơ dinh dưỡng, dị ứng, bệnh lý, dụng cụ và hạn chế vận động. Nếu không đủ ứng viên phù hợp, không tạo phần lịch đó; các ngày đã ghi trước đó vẫn còn và yêu cầu có thể tiếp tục sau khi dữ liệu được cập nhật.

## Bằng chứng và giới hạn kiểm chứng

- Kiểm thử xác nhận prompt với asset 163 món, hai API tạo từng ngày, fallback đã xác thực, thứ tự 14 lượt, 35 bữa/14 hoạt động, tiếp tục theo request, giới hạn 18 lần gọi, làm sạch staging khi dấu vân tay đổi và lưu SQLite staging.
- SQLite in-memory xác nhận ngày đã ghi còn nguyên sau khi yêu cầu bị đánh dấu lỗi, lần tiếp tục ghi ngày kế tiếp, transaction cuối chỉ hoàn tất trạng thái và đặt cờ khách sau khi đủ dòng.
- Chuỗi migration cục bộ v27–v31, seeder M32, selector món/bài, model catalog và analyzer đã được kiểm tra trong worklog `docs/worklog/2026-10-13/003-worklog-ai-14-call-resumable-plan.md`.
- Chưa xác minh bằng Gemini trực tiếp, Supabase sandbox/deploy hoặc thiết bị thật. Suite AIService tổng thể hiện còn 14 kiểm thử fail ở logging/AI chat; các nhóm prompt và API theo ngày liên quan thay đổi đều đạt.
