# Authentication, Authorization & Security Baseline

## AuthN

- Password new hash: Argon2id; legacy bcrypt verification chỉ khi migration được phép. Không mã hóa reversible để lưu password.
- Access token JWT ngắn hạn, signed với algorithm allowlist; kiểm `exp`, `iat`, `iss`, `aud`, `sub`, `type`, `jti`, key rotation. Chỉ thêm `roles` khi business model đã xác nhận.
- ES256 có private/public key an toàn và rotation phù hợp; OIDC/JWKS nếu external identity provider. Không dùng client-chosen algorithm.
- Refresh token opaque random (cryptographically secure), lưu **HMAC hash** với pepper lấy từ secret manager; chỉ đưa raw token cho client lúc cấp.
- Rotation/revoke phải atomic; expired/replayed/revoked trả 401 an toàn, tránh lộ token trong log.
- Với browser cookies: quyết định Secure+HttpOnly+SameSite+CSRF defense; Bearer API khác cookie sessions, không kết hợp tùy hứng.

## AuthZ

- Authorization hoàn toàn server side. Kiểm role/scope và **resource ownership/tenant** trên từng protected operation.
- `401` nếu chưa xác thực; `403` nếu đã xác thực nhưng thiếu quyền. Trả 404 thay vì 403 để tránh resource enumeration khi policy đã quy định.
- Least privilege ở DB/user/service accounts; chỉ data tối thiểu và short lived credentials.
- Guard toàn bộ resource IDOR/BOLA: user không thể đổi path ID để truy cập đối tượng của người khác.

## Service protection

- CORS explicit allowlist, không `*` với credentials; HTTPS/TLS cho public traffic; secret rotation và least privilege.
- Rate limits cho login/register/refresh/password reset/upload; anti-bruteforce strategy không chặn nhầm user vô thời hạn.
- Validate uploads: type/signature, size, malware scanning khi phù hợp; không dùng filename nguyên bản làm path.
- SSRF: outbound URL allowlist/network egress policy; HTTPX timeouts, max redirects.
- SQL injection: bind parameters, fixed SQL identifiers; chống mass assignment/overposting bằng typed response/request models.
- Không log Authorization, tokens, passwords, DSN, private keys, sensitive bodies, full SQL params, PII trừ khi đã có chính sách xử lý dữ liệu.
- Cấu hình qua environment/secret manager và `SecretStr` hoặc equivalent; `.env.example` placeholders, `.env` gitignored; production config validate fail-fast.

## Security validation & review

- Authentication error paths + refresh replay tests + role/tenant isolation + injection/invalid enum + bad cookie/header + secret scan.
- Audit log cho high-impact actions (admin, credential, payment) nhưng chỉ lưu metadata tối thiểu.
- Dependency audit và SBOM khi release; threat model theo feature. `pydantic` không thay thế ownership check, DB constraints hoặc rate limits.
- Production credentials không được copy từ project gốc, local `.env` hoặc từ session logs vào agent output.
