# Import File — [MODULE_CODE] / {{Tên module}}

> **Mục tiêu file:** Là bản đồ dependency để Developer biết chính xác file nào được phép import gì, package/external service nào đang dùng, cấu hình nằm ở đâu và function nào được export. Đây là tài liệu hỗ trợ coding và review dependency, không thay thế manifest/package manager thực tế.

## 0. Quy tắc dependency

1. **Chỉ import theo hướng layer:** Presentation → Controller/Provider → Use case/Service → Repository → Datasource/DAO/API client.
2. **Không import ngược:** Domain/use case không phụ thuộc UI framework, widget, HTTP client cụ thể hoặc ORM cụ thể.
3. **Không import xuyên feature** nếu chưa có public contract/interface rõ ràng. Ưu tiên shared kernel hoặc integration contract.
4. **External dependency phải có lý do, phiên bản, owner, license/security review và phương án thay thế.**
5. **Secrets không được import/hard-code trong source.** Chỉ đọc qua config/env/secrets manager.
6. Import mới hoặc xóa import phải cập nhật file này trong cùng commit/PR.

## 1. Package/external dependency registry

| ID | Package / service | Version / plan | Nguồn | Mục đích | Dùng tại file/layer | License / security note | Owner | Thay thế / rollback |
|---|---|---|---|---|---|---|---|---|
| `[MODULE]-DEP01` | `{{package/service}}` | `{{version}}` | `{{npm/pip/pub/Maven/vendor}}` | `{{...}}` | `{{path/layer}}` | `{{license/CVE review}}` | `{{team}}` | `{{...}}` |

### 1.1 Cấu hình package manager

| Nền tảng | File manifest/lock | Lệnh cài | Lệnh kiểm tra | Ghi chú |
|---|---|---|---|---|
| TypeScript/Node | `package.json`, lockfile | `{{pnpm/npm/yarn add}}` | `{{audit/outdated}}` | `{{...}}` |
| Python | `pyproject.toml` / `requirements.txt` | `{{uv/pip add}}` | `{{pip-audit}}` | `{{...}}` |
| Flutter/Dart | `pubspec.yaml` | `flutter pub add {{package}}` | `flutter pub outdated` | `{{...}}` |
| Java/Kotlin | `build.gradle(.kts)` | `{{dependency}}` | `{{gradle task}}` | `{{...}}` |

## 2. File map và contract nội bộ

<a id="file-map"></a>

| File path | Layer | Trách nhiệm duy nhất | Import được phép | Không được import | Export public | Feature / Function | Được dùng bởi |
|---|---|---|---|---|---|---|---|
| `{{src/modules/[module]/presentation/...}}` | Presentation | `{{Render + dispatch UI action}}` | `{{view-model/provider/use case contract}}` | `{{DAO/ORM/HTTP trực tiếp}}` | `{{Widget/Page}}` | `[MODULE]-V01` | `{{router}}` |
| `{{.../application/...}}` | Use case | `{{Orchestrate business flow}}` | `{{domain, repository interface}}` | `{{widget, SQL, HTTP client}}` | `{{execute()}}` | `[MODULE]-FN01` | `{{controller}}` |
| `{{.../infrastructure/...}}` | Repository/DAO | `{{Persist/integrate}}` | `{{ORM/HTTP/config}}` | `{{UI}}` | `{{Repository implementation}}` | `[MODULE]-FNxx` | `{{use case}}` |

## 3. Import matrix theo file

> Lập một block cho **mỗi file mới hoặc file bị sửa có dependency đáng kể**.

### File: `{{relative/path/to/file}}`

| Thuộc tính | Giá trị |
|---|---|
| Layer | `{{...}}` |
| Chịu trách nhiệm | `{{...}}` |
| Feature / Function / View | `[MODULE]-Fxx` / `[MODULE]-FNxx` / `[MODULE]-Vxx` |
| Owner | `{{...}}` |
| Exports | ``{{Class/function/interface names}}`` |
| Import nội bộ | `{{relative modules + lý do}}` |
| Import external | `{{package + lý do}}` |
| Config/env dùng | `{{key names only; không ghi giá trị secret}}` |
| Side effect | `{{DB/API/event/file/log}}` |
| Test file | `{{relative test path}}` |

```text
# Pseudo import map — thay bằng import thực tế của ngôn ngữ dự án
import {{internal_contract}}      # {{lý do}}
import {{external_package}}       # {{lý do}}
```

### Ví dụ format cho TypeScript

```ts
// src/modules/{{module}}/application/{{action}}.use-case.ts
import type { {{Entity}}Repository } from '../domain/{{entity}}.repository';
import { {{RulePolicy}} } from '../domain/{{rule}}.policy';
// Không import React/Vue component, axios/fetch hoặc ORM trực tiếp ở use case.
```

### Ví dụ format cho Python/FastAPI

```python
# app/modules/{{module}}/application/{{action}}_use_case.py
from app.modules.{{module}}.domain.repositories import {{Entity}}Repository
from app.modules.{{module}}.domain.policies import {{RulePolicy}}
# Không import FastAPI Request/Response hoặc SQLAlchemy session trực tiếp ở use case.
```

### Ví dụ format cho Flutter/Dart

```dart
// lib/features/{{module}}/application/{{action}}_use_case.dart
import '../domain/{{entity}}_repository.dart';
import '../domain/{{rule}}_policy.dart';
// Không import Widget/BuildContext hoặc sqflite/Dio trực tiếp ở use case.
```

## 4. Bản đồ source nội bộ và external integration

| Nguồn | Kiểu | Contract/interface | Endpoint/topic/path | Auth/config key | Timeout/retry | Consumer functions | Fallback |
|---|---|---|---|---|---|---|---|
| `{{Module khác}}` | `Internal API/package/event` | `{{DTO/interface}}` | `{{...}}` | `{{key name}}` | `{{...}}` | `[MODULE]-FNxx` | `{{...}}` |
| `{{Vendor}}` | `External API/SDK` | `{{version/schema}}` | `{{...}}` | `{{key name}}` | `{{...}}` | `[MODULE]-FNxx` | `{{...}}` |

## 5. Constants, config và feature flags

| ID | Tên | File / nguồn | Type | Default | Môi trường | Ai được sửa | Feature/function dùng |
|---|---|---|---|---|---|---|---|
| `[MODULE]-CFG01` | `{{MODULE_TIMEOUT_MS}}` | `{{config file/env}}` | `number` | `{{...}}` | `{{dev/stg/prod}}` | `{{DevOps/Lead}}` | `[MODULE]-FN01` |

> Chỉ ghi **tên biến config**, schema và mục đích. Không đưa API key, password, token, connection string thật vào DD hoặc Git.

## 6. Export contract registry

| Export | File định nghĩa | Kiểu | Mục đích | Consumer hợp lệ | Version/change rule |
|---|---|---|---|---|---|
| `{{I{{Entity}}Repository}}` | `{{path}}` | `interface/class/function` | `{{...}}` | `{{use case(s)}}` | `{{breaking change policy}}` |

## 7. Kiểm tra trước merge

- [ ] Mọi package mới có mục đích, version và owner.
- [ ] Không có import ngược layer hoặc UI → DAO/API trực tiếp.
- [ ] Không có circular dependency.
- [ ] Không hard-code secret/config production.
- [ ] Public export có consumer và mapping Feature/Function.
- [ ] External API có timeout, retry/fallback và error mapping.
- [ ] Test import đúng contract/mocks, không mock sai layer.
- [ ] `Import_File.md` khớp với code sau khi refactor.
