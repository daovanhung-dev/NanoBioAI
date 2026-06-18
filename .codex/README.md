# NanoBio Codex Pack

Bộ này cố ý chỉ đặt mọi thứ trong `.codex/` để giảm rác ở root project.

## Cách dùng nhanh

Mở Codex tại root project, nơi có `pubspec.yaml`, rồi dùng prompt:

```text
Đọc .codex/AGENTS.md trước, sau đó thực hiện task sau:
[TASK CỦA TÔI]
```

## Lưu ý quan trọng

Codex thường tự ưu tiên `AGENTS.md` ở root project. Vì bộ này chỉ nằm trong `.codex/`, hãy luôn nhắc Codex đọc `.codex/AGENTS.md` ở đầu prompt.

## Lệnh kiểm tra

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -FixFormat -BuildApk
```

Git Bash/WSL/macOS/Linux:

```bash
bash .codex/tool/codex_quick_check.sh
bash .codex/tool/codex_check.sh --fix-format --build-apk
```
