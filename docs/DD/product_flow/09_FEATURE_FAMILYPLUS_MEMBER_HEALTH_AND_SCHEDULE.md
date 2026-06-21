# DD-PRODUCT-FLOW-FR-006 - FamilyPlus Member Health và Schedule

**BD nguồn:** BR-07, UC-11, AC-07  
**Status:** Draft  
**Dependencies:** 03, 05, 08, 12, 13, 14, 15  

## 1. Mục tiêu và outcome

FamilyPlus kế thừa Plus/Free và mở khả năng quản lý nhiều thành viên gia đình, mỗi thành viên có hồ sơ, lịch trình, thực đơn và dữ liệu sức khỏe riêng trong family boundary.

## 2. Trigger / Preconditions

- User đã đăng nhập và effective plan là FamilyPlus.
- Family group/member đã được tạo bởi trusted backend/admin flow.
- Consent, member limit và quyền xem/sửa đã được PO xác nhận trước khi Ready.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| familyGroupId | Yes | UUID | User is owner/member allowed | Yes |
| subjectId | Yes | UUID | Belongs to family and allowed | Yes |
| member role/permission | Yes | enum/flags | From server only | Yes |
| member health data | Conditional | structured | Same validation as self profile | Yes |

## 4. Output / Postconditions

- FamilyPlus có thể xem/tạo/tinh chỉnh schedule theo từng subject được phép.
- Dữ liệu thành viên không bị lẫn với self profile hoặc thành viên khác.
- Member ngoài family không đọc/ghi được dữ liệu.

## 5. Happy path

```text
1. FamilyPlus owner mở family module.
2. App đọc family group/member permissions từ Supabase.
3. User chọn subject/member.
4. Onboarding/schedule/tracking use-case chạy theo subjectId được phép.
5. UI hiển thị dữ liệu từng member tách biệt.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Non-FamilyPlus mở family route | access gate false | Mời nâng cấp | Chặn route/use-case | Upgrade |
| Member không có `can_edit` | permission false | Chỉ xem hoặc chặn sửa | Fail closed | No |
| Subject không thuộc family | RLS/use-case deny | Không hiển thị data | No cross-subject leak | No |
| Consent chưa chốt | DD Draft | Không code Ready | Block implementation | PO decision |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Read family group/member | `family_groups`, `family_members` | owner/member allowed | RLS |
| Read member health data | health/schedule tables by `subject_id` | can_view allowed | `can_read_health_subject` |
| Write member health data | health/schedule tables by `subject_id` | can_edit/owner allowed | `can_write_health_subject` |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Presentation | Member switcher, family dashboard/schedule | `lib/app_versions/v3/features/family_*` |
| Controller/provider | Selected subject and permission state | v3 family providers |
| Repository/datasource | Supabase family/subject data | v3/family data layer |
| Domain | Permission and subject boundary | FamilyPlus domain services |
| Notification | Subject-aware reminders | notification service extension |

## 9. Security / privacy

- Health data sharing must be explicit by server-side permission.
- Không dùng client-selected subjectId nếu RLS/use-case không xác nhận.
- UI không hiển thị thông tin nhạy cảm của member không được phép.

## 10. Acceptance tests

- TC-PF-18: FamilyPlus owner đọc member subject trong group.
- TC-PF-19: Member ngoài family không đọc được subject.
- TC-PF-20: User không có `can_edit` không sửa được member data.

## 11. Non-goals

- Không tự định nghĩa số lượng member tối đa hoặc consent flow.
- Không triển khai invite/remove member nếu chưa có DD riêng.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-07 | Giới hạn số thành viên, quyền thêm/xóa/xem/sửa và consent chia sẻ sức khỏe? | Product Owner / Legal/Privacy | RLS, UX, data retention |
| Q-06 | FamilyPlus hết hạn thì family data/access thay đổi thế nào? | Product Owner | Downgrade behavior |

