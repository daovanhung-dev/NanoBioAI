# NanoBio Codex Pack

Bộ documentation và tools cho dự án BioAI. Được thiết kế để giúp AI agents (như Kiro, GitHub Copilot, Cursor, v.v.) hiểu đúng và làm việc hiệu quả với dự án.

## 📚 Structure

```
.codex/
├── AGENTS.md                 # ⭐ Luật chính - Đọc đầu tiên
├── PROJECT_MAP.md            # Task routing - Đọc file nào cho task gì
├── ARCHITECTURE.md           # Architecture decisions và patterns
├── QUICK_REFERENCE.md        # Cheat sheet nhanh
├── DEV_WORKFLOW.md           # Quy trình dev
├── CHECKLIST.md              # Checklist trước/sau sửa
├── TEST_WORKFLOW.md          # Quy trình test
├── TOKEN_SAVING_RULES.md     # Tiết kiệm token
├── playbooks/                # Best practices cho từng module
│   ├── dashboard.md
│   ├── onboarding.md
│   ├── ai_service.md
│   ├── notification.md
│   ├── sqlite.md
│   ├── ui.md
│   ├── health_tracking.md    # NEW!
│   └── lifestyle_schedule.md # NEW!
├── prompts/                  # Template prompts
└── tool/                     # Automation scripts
```

## 🚀 Cách dùng

### Cho AI Agents (Kiro, Cursor, GitHub Copilot)

**Bước 1**: Luôn đọc theo thứ tự:
1. `.codex/AGENTS.md` - Hiểu luật chơi
2. `.codex/PROJECT_MAP.md` - Biết đọc file nào
3. Playbook liên quan (chỉ 1 file) - Best practices

**Bước 2**: Dùng `rg` để tìm file cần đọc:
```bash
rg "ClassName|providerName" lib test
```

**Bước 3**: Làm việc theo quy trình:
- Discover → Plan → Patch → Validate → Report

### Cho Developers

**Quick reference**: Đọc `.codex/QUICK_REFERENCE.md` để tra cứu nhanh.

**Kiểm tra code**:
```bash
# Windows
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1

# Linux/Mac/WSL
bash .codex/tool/codex_quick_check.sh
```

## 📖 Key Documents

| File | Khi nào đọc |
|------|-------------|
| `AGENTS.md` | **Luôn luôn** - Luật chính của dự án |
| `PROJECT_MAP.md` | Khi bắt đầu task mới - Để biết đọc file nào |
| `ARCHITECTURE.md` | Khi cần hiểu architecture decisions |
| `QUICK_REFERENCE.md` | Khi cần tra cứu nhanh (cheat sheet) |
| `playbooks/*.md` | Khi làm việc với module cụ thể |

## 🎯 Playbooks Available

| Playbook | Module |
|----------|--------|
| `dashboard.md` | Dashboard, health score, BMI calculation |
| `onboarding.md` | 7-step onboarding wizard |
| `ai_service.md` | AI meal/exercise generation, parser, normalizer |
| `notification.md` | Local notifications, reminders, actions |
| `sqlite.md` | Database schema, DAO, migrations |
| `ui.md` | Design system, theme, Vietnamese copywriting |
| `health_tracking.md` | Daily health logs (weight, sleep, etc.) |
| `lifestyle_schedule.md` | Schedule timeline, status flow |

## ⚠️ Important Rules

### ✅ PHẢI làm:

- Đọc `.codex/AGENTS.md` trước khi làm bất cứ task nào
- Follow architecture layers: Presentation → Domain → Data
- Text tiếng Việt phải có dấu
- Update database version khi đổi schema
- Run `flutter analyze` trước khi commit

### ❌ CẤM làm:

- Không đọc toàn bộ project cho task nhỏ
- Không bypass layers (presentation → data)
- Không dùng mock/fake data trong production
- Không import features từ features khác
- Không hardcode API keys

## 🔧 Tools

### Quick Check (Luôn chạy)
```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

### Full Check (Khi đổi native/Android/notification)
```bash
flutter doctor -v
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## 📝 Report Format

Sau mỗi task, báo cáo theo format:

```markdown
## Task Summary

**Đã làm**: [Mô tả ngắn gọn]

**Files đã sửa/tạo**:
- `path/to/file.dart` - [Mô tả]

**Commands đã chạy**:
- `flutter analyze`: ✅ PASS / ❌ FAIL

**Rủi ro/Lưu ý**: [Nếu có]
```

## 🆕 What's New (v2.0)

- ✅ Added `ARCHITECTURE.md` - Architecture decisions document
- ✅ Added `QUICK_REFERENCE.md` - Developer cheat sheet
- ✅ Added `playbooks/health_tracking.md` - Health tracking best practices
- ✅ Added `playbooks/lifestyle_schedule.md` - Schedule management guide
- ✅ Enhanced `AGENTS.md` with detailed workflow and examples
- ✅ Enhanced `PROJECT_MAP.md` with all features and status map
- ✅ Better structure and organization

## 🔗 Related Documentation

- **Architecture violations**: `docs/issues/bug_architecture.md`
- **Project progress**: `docs/project_progress_update.md`
- **Main README**: `../README.md`
- **System features**: `../SYSTEM_FEATURES_DOCUMENTATION.md`

## 📞 Support

Nếu cần support:
1. Đọc `.codex/QUICK_REFERENCE.md` trước
2. Check `docs/issues/` để xem issue đã biết
3. Tìm trong `.codex/playbooks/` cho module cụ thể

---

**Version**: 2.0  
**Last Updated**: 2026-06-18  
**Maintained By**: Development Team
