Commit de xuat: feat(ai): retry va tach slot cho ngay tao lich loi

# Retry tăng model và tách món khi tạo lịch lỗi

## Mục tiêu

Tiếp tục tạo lịch khi một lượt AI trả lỗi, response rỗng hoặc JSON/kết quả không hợp lệ. Một ngày có lỗi sau ngưỡng retry được tách thành các slot món riêng; staging cho phép tiếp tục đúng phần còn thiếu.

## Luồng hiện tại

1. Mỗi đơn vị tạo lịch có tối đa 6 lời gọi AI: một lượt đầu và tối đa năm lần thử lại. Mỗi lần thất bại chuyển sang model tiếp theo trong chuỗi cấu hình, sau đó dùng model cao nhất cuối chuỗi cho các lượt còn lại. Mặc định lịch bắt đầu với Gemini 2.5 Flash và có Gemini 3.8 Flash làm model fallback ổn định.
2. Lỗi provider tạm thời, response rỗng, JSON lỗi, hoặc dữ liệu không qua validation đều làm đơn vị đó retry. Lỗi tạm thời có delay/cooldown; validation và lỗi cấu hình tiếp tục thử theo chuỗi model nhưng không thêm delay.
3. Nếu lượt tạo đủ 5 bữa cho ngày vẫn lỗi sau 6 lần gọi, `GeneratedPlanService` không chèn bữa local cho cả ngày. Nó lần lượt yêu cầu AI tạo breakfast, morning snack, lunch, afternoon snack và dinner, mỗi slot có cùng chính sách retry. AI slot được chọn từ catalog đầy đủ như lượt ngày và được kiểm tra active/type/duplicate; tập ứng viên selector chỉ giới hạn local fallback.
4. Nếu slot vẫn lỗi sau 6 lần gọi, ứng dụng chọn local fallback sau khi áp selector điều kiện/dị ứng/goal và kiểm tra mã, loại bữa, lặp lại với normalizer. Không đủ ứng viên an toàn thì yêu cầu dừng ở ngày đó.
5. Mỗi slot hợp lệ được ghi staging riêng. Nếu lần gọi tiếp theo bị gián đoạn, yêu cầu cùng `request_id` giữ slot đã xong và chỉ thử lại slot còn thiếu; sau khi đủ năm slot, ứng dụng xác thực lại cả ngày rồi mới staging khóa `meal:<day>` và commit ngày cùng phần vận động.
6. Ngày kế tiếp tiếp tục luồng tạo bữa theo ngày đầy đủ. Phần vận động cũng có 6 lần thử rồi dùng local fallback đã lọc như trước. Nếu bất kỳ phần nào dùng local fallback, nguồn kế hoạch thể hiện `local_fallback` và member plan không commit quota AI.

## Giới hạn lượt gọi và model

- Tối đa 300 lần gọi backend cho một request tại SQLite và Edge Function. Worst case kế hoạch 7 ngày là 294: mỗi ngày 6 lượt thử ngày bữa, 6 lượt cho mỗi trong 5 slot, và 6 lượt vận động.
- Gemini 3.8 Flash được thêm vào server allowlist để model escalation có thể tới backend. Edge provider chuyển cấu hình thinking theo họ model: `thinkingLevel` cho Gemini 3 và `thinkingBudget` cho Gemini 2.5.
- Đổi prompt/staging version sang `personal_schedule_v7_model_escalation_meal_slot_split`, nên staging từ chính sách cũ không bị tái dùng sai hợp đồng.

## Kiểm chứng

- Unit test xác nhận 6 lần gọi khi 429 hoặc response không hợp lệ, dùng model fallback và dừng đúng ngưỡng; test slot fallback dùng local choice sau 6 lần lỗi.
- Generated-plan tests xác nhận chỉ ngày bữa lỗi mới bị tách slot; ngày sau tiếp tục lượt đầy đủ. Test resume xác nhận các slot đã staging không bị tạo lại và lần sau chỉ gọi lại slot lỗi.
- Request-store test xác nhận trần 300 và giữ/tiếp tục staging hợp lệ. Deno tests xác nhận allowlist và chuẩn hóa thinking cho Gemini 3.8.
- Chạy test/analyze source cục bộ; chưa gửi request Gemini thật, deploy Supabase hoặc xác nhận luồng trên thiết bị.

## Ranh giới

- Fallback cục bộ chỉ dùng catalog đủ điều kiện đã có; không bịa dữ liệu để lấp slot.
- Mỗi ngày chỉ được ghi khi đủ năm bữa và hai hoạt động đã chuẩn hóa. Các ngày đã commit riêng vẫn có thể được tiếp tục sau lỗi ở ngày sau.
- Cơ chế retry không chứng minh Gemini, giới hạn/quota Edge Function đã triển khai, hoặc onboarding trên thiết bị hoạt động đúng. Các xác nhận này vẫn cần QA sandbox/thiết bị.
