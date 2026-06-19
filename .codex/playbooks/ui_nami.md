# Playbook - UI / Theme / Nami Copywriting

## Muc tieu

UI don gian, am ap, responsive, va cho nguoi dung cam giac duoc Nami cham soc thay vi bi danh gia.

## Doc truoc

- `lib/core/theme/`
- Page/widget cua feature lien quan.
- Controller/state neu UI phu thuoc state.
- Widget tests lien quan neu co.

## Quy tac UI

- Uu tien token co san: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppDecoration`, `AppGradients`, `AppShadows`, `AppDuration`.
- Khong hard-code style lap lai neu theme da co.
- Tranh overflow: dung `Flexible`, `Expanded`, constraints, scroll view dung cho.
- Loading/error/empty/data state phai day du.
- Khong doi business logic neu task chi yeu cau UI/copy, tru khi co bug UI ro rang.
- Neu text dai tren mobile, uu tien wrap/ellipsis co chu dich.

## Copy Nami

- Tieng Viet co dau.
- Cau ngan, tu nhien, khong phan xet.
- Khong noi thuat ngu noi bo: database, table, query, parser, exception, stack trace, log.
- Khong do loi cho user; dua loi moi/hanh dong tiep theo nhe nhang.

Vi du:

- Khong nen: `Không lấy được dữ liệu từ database.`
- Nen: `Nami chưa thể cập nhật thông tin lúc này. Mình thử lại sau một chút nhé.`

- Khong nen: `Bạn chưa hoàn thành nhiệm vụ.`
- Nen: `Hôm nay mình còn một việc nhỏ cần chăm sóc nhé.`

## Tim nhanh

```bash
rg "database|table|query|exception|stack trace|parser|log" lib/features lib/services
rg "AppColors|AppSpacing|AppRadius|AppTextStyles|AppDuration" lib/core/theme lib/features/<feature>
```

## Test nen chay

- Widget render khong loi.
- State loading/error/empty/data.
- Text chinh xuat hien dung.
