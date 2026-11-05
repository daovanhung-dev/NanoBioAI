Commit de xuat: docs(worklog): ghi nhan loi truy cap API Admin Web

# Worklog - Chẩn đoán API Admin Web không truy cập được

## Thời gian

- Ngày: 2026-11-04
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix / chẩn đoán kết nối.
- Module chính: Admin Web và đường vào FastAPI qua HTTPS.
- Yêu cầu gốc: tìm và sửa lỗi API không sẵn sàng trên trang Admin Web.
- Giới hạn: không thay đổi router, DNS, firewall, dịch vụ production, tài khoản hoặc dữ liệu.

## Đã làm

- Lần theo banner tới `BackendClient.checkReadiness()`: lỗi `fetch` của `/health/ready` hiển thị “Không kết nối được API” và khóa thao tác ghi.
- Xác nhận Admin Web build dùng đúng API origin `https://nanobio.s2w.click`; cấu hình CORS trong backend cho phép origin GitHub Pages và phản hồi runtime có `Access-Control-Allow-Origin` tương ứng.
- Tải trực tiếp GitHub Pages và bundle đang phục vụ: cả hai HTTP 200; bundle có `nanobio.s2w.click` và `/health/ready`, không dùng API origin cũ.
- Gọi cùng hostname qua Tailscale với TLS được xác thực bình thường: health trả HTTP 200; Nginx và `nanobio-backend.service` đang hoạt động, backend bind loopback port 8000.
- Route IPv4 của server có default gateway qua interface LAN; server có thể truy cập Internet chiều ra. Gọi hostname public từ chính server vẫn timeout.
- DNS phân giải đến địa chỉ egress công khai của server. Từ máy đang chạy Chrome, kết nối HTTPS tới địa chỉ công khai timeout. Server nghe TCP 443 trên mọi interface, UFW inactive và policy INPUT của nftables là accept.
- Bằng chứng hiện tại khoanh vùng lỗi vào nhánh truy cập hostname public trước Nginx (router/NAT, hairpin NAT, mạng ISP hoặc đường mạng của máy khách). Chưa đủ dữ liệu để phân biệt thiếu port-forward, double NAT với giới hạn của mạng ngoài.
- Không sửa runtime source vì cấu hình frontend, CORS, TLS và readiness đều hoạt động qua đường Tailscale. Không thay đổi quyền truy cập public khi chưa được xác nhận.

## File code/docs đã sửa

- `docs/worklog/2026-11-04/001-worklog-admin-web-api-public-reachability.md` - ghi lại bằng chứng và giới hạn xác minh.

## Tài liệu liên quan

- `admin-web/src/lib/backend-client.ts`
- `.github/workflows/deploy-admin-web.yml`
- `backend/src/nanobio_backend/main.py`
- `backend/.env.example`

## Commands

- Đối chiếu cấu hình Admin Web, backend CORS và readiness: PASS.
- HTTPS health qua Tailscale với chứng chỉ hợp lệ: PASS, HTTP 200.
- Tải trang và bundle GitHub Pages đang triển khai: PASS, HTTP 200; API origin đúng.
- HTTPS health qua hostname/DNS công khai từ máy làm việc: FAIL, TCP connect timeout.
- HTTPS health qua hostname public từ server: FAIL, TCP connect timeout; chiều ra Internet và default route vẫn hoạt động.
- Kiểm tra service, listener 443 và firewall trên server: PASS; không thay đổi cấu hình.
- `git diff --check`: chờ chạy sau khi lưu worklog.
- Test source: SKIPPED; không có runtime source thay đổi.

## Lỗi/Rủi ro

- Đã xác định: trình duyệt không thể kết nối tới API qua đường public từ máy hiện tại.
- Chưa xác định: router có port-forward TCP 443/80 tới server hay ISP/mạng khách đang chặn đường vào.
- Chưa sửa: cần kiểm tra trạng thái router WAN/NAT. Forward TCP 443 tới server sẽ làm API truy cập được từ Internet; cân nhắc TCP 80 nếu dùng HTTP-01 cho gia hạn chứng chỉ.
- Cần kiểm tra tiếp: xác nhận và cấu hình ingress tại router/ISP; giữ DHCP reservation cho địa chỉ LAN của server nếu dùng NAT.

## Tỷ lệ hoàn thành

- Hoàn thành: chẩn đoán source, TLS, CORS, readiness, service và firewall host.
- Đang dở: sửa ingress public cần quyền truy cập router và xác nhận thay đổi mở API ra Internet.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - tách được lỗi frontend/API khỏi đường ingress và không suy diễn database hỏng.
- Mức độ hoàn thành task: chẩn đoán xong; chưa thể sửa router khi chưa có quyền xác nhận.
- Bằng chứng kiểm chứng: HTTP 200 qua Tailscale, Access-Control-Allow-Origin hợp lệ, service active, cổng 443 listen và public connect timeout.
- Điểm tốn token/chưa tối ưu: Chrome automation không đọc được tab/DevTools do bridge lỗi; dùng probe TLS và source để khoanh vùng.
- Cách tối ưu cho phiên sau: kiểm tra router WAN IP và NAT rule trước khi đề xuất thay đổi; kiểm tra lại từ một mạng ngoài router sau khi cấu hình.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
