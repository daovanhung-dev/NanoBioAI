# Checklist Task Coding

Commit de xuat: docs(checklist): khoi tao task coding theo DD progress

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/checklist/checklist_complete_DD.md` |
| Ngay cap nhat | 2026-06-28 |
| Muc dich | Ghi lai cong viec coding tiep theo tu tien do DD module cua phien truoc. |

## DD Progress Next Tasks

- [ ] Truoc moi phien coding, doc `docs/checklist/checklist_complete_DD.md` de chon DD module, phan tram hien tai, blocker va next step.
- [ ] Sau do doc file nay de tiep tuc note dang do cua phien truoc.
- [ ] Neu module can code van `Draft`, chi code phan khong bi open question chan; neu blocker anh huong behavior thi cap nhat checklist thay vi invent rule.
- [ ] Sau moi phien coding, cap nhat `docs/checklist/checklist_complete_DD.md` va ghi task tiep theo vao file nay.

## Uu tien tiep theo

| Priority | Module | Viec can lam tiep | Ly do |
|---:|---|---|---|
| 1 | M15/M16 Admin | Chot role matrix Q-12/Q-18, verify Admin SQL/RPC sandbox, them permission/error-state tests. | Admin da co scaffold + SQL draft + tests, can verification de tang tu 60 len 80. |
| 2 | M12/M14 Sale | Verify Sale RPC sandbox, complete participation/referral/point conversion acceptance tests. | Sale direct-only da co app/data path, can bang chung backend/RPC. |
| 3 | M06/M07 Quota + AI Chat | Chot quota reset/trusted write, wire guard truoc AI chat va schedule generation. | Quota la dependency cho AI Chat va Personal Schedule. |
| 4 | M01/M02/M03 Guest flow | M01 local hardening da verify; tiep theo chot M01 cloud/FamilyPlus contract va doi chieu M02/M03 guard/test gaps. | V1 runtime local da co, nhung cloud sync, subject/consent, quota va dashboard state van bi open questions chan. |
| 5 | M13/M17 Payment/Reconciliation | Chot provider/refund/chargeback/reconciliation policy truoc khi code them. | Financial behavior bi chan boi Q-03..Q-10 va Q-17. |

## Notes tu phien coding gan nhat

- 2026-06-28: M01 safe hardening da code/test local: sanitize onboarding logs, DB injection cho local datasource test, persistence/markCompleted/outbox tests, completion handoff va double-submit tests. Quick check fail o `flutter analyze` do analyzer issues toan cuc san co/ngoai pham vi; xem worklog 006.
- 2026-06-28: Khoi tao checklist task coding tu `checklist_complete_DD.md`; chua co runtime change trong phien nay.
