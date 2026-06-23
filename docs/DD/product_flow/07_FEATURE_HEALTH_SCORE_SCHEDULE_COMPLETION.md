# DD-PRODUCT-FLOW-FR-004 - Health Score theo Lịch Sử Thực Hiện Lịch Trình

**BD nguồn:** BR-08, UC-08, BR-05, AC-05 context  
**Status:** Draft  
**Dependencies:** 03, 04, 06, 13, 14, 15, `.codex/playbooks/dashboard.md`

## 1. Mục tiêu và outcome

Free/Plus/FamilyPlus có cơ chế điểm dựa trên mức độ hoàn thành và tính đều đặn khi thực hiện lịch trình cá nhân do AI tạo. Dashboard phải đọc dữ liệu thật, không mock.

## 2. Trigger / Preconditions

- User đã đăng nhập và có quyền Free trở lên.
- Có lịch sử meal/task/schedule item với trạng thái thực hiện.
- Công thức điểm được PO phê duyệt trước khi Ready.

## 3. Input contract

| Field                | Required | Type      | Validation                                | Sensitive? |
| -------------------- | -------: | --------- | ----------------------------------------- | ---------- |
| Schedule item status |      Yes | enum      | pending/completed/skipped hoặc equivalent | Yes        |
| Date/time            |      Yes | date/time | timezone/period rõ ràng                   | Yes        |
| Source type          |      Yes | enum      | meal/exercise/hydration/sleep/custom      | No         |
| Completion history   |      Yes | aggregate | From real DB rows only                    | Yes        |

## 4. Output / Postconditions

- Score/progress/timeline phản ánh lịch sử thật.
- Khi user complete/skip, dashboard refresh từ data layer.
- Nếu thiếu data hoặc công thức chưa chốt, hiển thị empty/pending state thay vì bịa điểm.

## 5. Happy path

```text
1. User hoàn thành hoặc bỏ qua schedule item.
2. Repository cập nhật trạng thái trong source of truth.
3. Dashboard provider đọc completion history.
4. Calculator áp công thức điểm đã phê duyệt.
5. UI hiển thị score/progress bằng copy Nabikhông phán xét.
```

## 6. Alternative and error flows

| Case                           | Detection         | UI behavior            | Technical behavior                             | Retry               |
| ------------------------------ | ----------------- | ---------------------- | ---------------------------------------------- | ------------------- |
| Chưa có lịch sử                | empty query       | Empty state            | Không tạo mock score                           | Refresh khi có data |
| Công thức chưa chốt            | DD status Draft   | Không triển khai Ready | Block implementation                           | PO decision         |
| Update status fail             | datasource error  | Báo thử lại            | Không cập nhật score optimistic nếu không chắc | Retry               |
| Cross-user/family unauthorized | RLS/use-case deny | Không hiển thị data    | Fail closed                                    | No                  |

## 7. Persistence and ownership

| Action                  | Target                       | Actor allowed             | RLS/constraint         |
| ----------------------- | ---------------------------- | ------------------------- | ---------------------- |
| Read completion history | meal/tasks/schedule/tracking | owner/family allowed      | subject boundary       |
| Write completion status | schedule/task tables         | owner/family edit allowed | no cross-user          |
| Store score snapshot    | optional future table        | TBD                       | formula/version needed |

## 8. Layer responsibilities / affected files

| Layer                 | Responsibility                  | Proposed file                                           |
| --------------------- | ------------------------------- | ------------------------------------------------------- |
| Presentation          | Show score/progress/empty/error | dashboard widgets/pages                                 |
| Controller/provider   | Refresh state after actions     | dashboard providers/controllers                         |
| Repository/datasource | Read real history               | dashboard/daily/lifestyle data layer                    |
| Domain service        | Score formula                   | `dashboard_health_calculator.dart` or v2 health scoring |

## 9. Security / privacy

- Không dùng score để làm user cảm thấy bị chấm điểm/phán xét.
- Không log health completion details.
- FamilyPlus score phải tính theo đúng subject/member boundary.

## 10. Acceptance tests

- TC-PF-13: Score không hiển thị mock khi thiếu data.
- TC-PF-14: Complete/skip schedule item làm dữ liệu score refresh.
- TC-PF-15: Cross-user data không lọt vào score.

## 11. Non-goals

- Không tự định nghĩa công thức điểm khi Q-05 chưa chốt.
- Không triển khai gamification/premium analytics ngoài BD.

## 12. Open decisions

| ID   | Question                                                       | Owner                       | Impact                     |
| ---- | -------------------------------------------------------------- | --------------------------- | -------------------------- |
| Q-05 | Công thức điểm, trọng số đều đặn, xử lý skip/miss và UI score? | Product Owner / Health Lead | Calculator, tests, UX copy |
