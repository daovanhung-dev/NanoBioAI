# Validation Strategy

## 4 validation levels

1. **Transport parsing** (FastAPI): header/query/path/body, type, missing fields -> 422/400.
2. **Basic DTO validation** (`models.py`): `EmailStr`, length/range, accepted enums, normalization thuần.
3. **Special pure rules** (`validate.py`): các quy tắc contract rõ ràng (prefix/regex/format). Trả `ValueError`/typed domain validation, không DB/IO/time/log.
4. **DB-backed business validation** (`view.py` + `query.py`): uniqueness, status, permissions, ownership, resource existence, state machine. Bảo vệ bằng DB constraint khi có race.

## Examples

| Rule | Correct home |
|---|---|
| `email` must be valid; trim surrounding whitespace | `models.py` + pure utils |
| Password must not be blank | `models.py` |
| Membership number has business prefix | `validate.py` **only if contract states** |
| Email already registered | `view.py` + database unique constraint |
| Actor owns resource | `view.py` + scoped SQL condition |
| Allowed status transition | `view.py` (state machine/domain service) |
| SQL query binds user-supplied values | `query.py` |

## Pitfalls

- Không gán mọi exception thành 422. Phân biệt invalid request vs internal/dependency failure.
- Nếu normalization mang nghĩa nghiệp vụ (email case insensitive, Unicode normalization), phải xác nhận contract trước; không thay password/case of other identifiers.
- Không gọi network/DB trong Pydantic validator.
- Không tạo duplicate uniqueness check chỉ ở app mà thiếu unique constraint/index; xử lý `IntegrityError` race an toàn.
- Validate cả response domain contract khi cần, không truyền thẳng row chưa lọc.
- Không viết test bẻ cong requirement cho vừa code.
