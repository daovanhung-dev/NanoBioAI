# Prompt: Áp dụng Agent Context vào backend đã tồn tại

Repository hiện có có thể **khác** chuẩn Study Server. Không rewrite toàn bộ chỉ vì template gợi ý.

1. Đọc `AGENTS.md`/context hiện tại; inventory file tree, stack, runtime, configs, tests, API contracts, DB migrations.
2. Lập matrix `CURRENT vs TARGET` cho routing, modules, validation, transactions, security, error contract, tests/CI.
3. Phân loại target: `ADOPT` (có giá trị), `ADAPT` (tương đương), `SKIP` (không phù hợp). Có ADR cho thay đổi lớn.
4. Chỉ tạo `.agents/project/` cần thiết, cập nhật theo source có thật; không bịa trạng thái VERIFIED, không triển khai placeholder.
5. Đề xuất lộ trình incremental, breaking API/schema rollout; không đổi sync sang async, raw SQL sang ORM, JWT sang OAuth tùy tiện.
6. Chỉ thực thi migration/refactor được yêu cầu; chạy tests trước/sau và bàn giao đầy đủ.
