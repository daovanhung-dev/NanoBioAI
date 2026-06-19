Commit de xuat: docs(todo): tao checklist issue va todo

# Checklist - Issues va Todos

## Tong quan
- Tong issue: 11
- Tong todo da tao: 11
- Todo done: 1
- Todo con lai: 10
- Fixbug da ghi nhan: 1
- Lan cap nhat: 2026-06-19 23:50 Asia/Saigon

## Checklist theo uu tien

| Done | Severity | Issue | Todo | Fixbug | Ghi chu |
| --- | --- | --- | --- | --- | --- |
| [x] | high | [AI Chat crash khi dotenv chua khoi tao](../../issues/ai-chat-dotenv-uninitialized/001-issue-ai-chat-dotenv-uninitialized.md) | [Todo](../ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md) | [Fixbug](../../fixbug/ai-chat-dotenv-uninitialized/001-fixbug-ai-chat-dotenv-uninitialized.md) | Da fix va test AI service pass. |
| [ ] | high | [AI service log raw prompt, raw response va ho so suc khoe](../../issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md) | [Todo](../ai-raw-payload-logging/001-todo-ai-raw-payload-logging.md) | Chua co | Uu tien cao vi lien quan du lieu nhay cam. |
| [ ] | high | [Dashboard va AI Chat dang tat auth guard](../../issues/auth-guards-disabled/001-issue-auth-guards-disabled.md) | [Todo](../auth-guards-disabled/001-todo-auth-guards-disabled.md) | Chua co | Can chot protected/offline route truoc khi fix. |
| [ ] | high | [Features Hub expansion chua hien thi va chua co route](../../issues/features-hub-expansion-not-wired/001-issue-features-hub-expansion-not-wired.md) | [Todo](../features-hub-expansion-not-wired/001-todo-features-hub-expansion-not-wired.md) | Chua co | Anh huong kha nang mo cac module moi. |
| [ ] | high | [Onboarding log toan bo snapshot ho so suc khoe](../../issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md) | [Todo](../onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md) | Chua co | Uu tien cao vi lien quan PII/du lieu suc khoe. |
| [ ] | high | [Flutter test dang fail 3 case truoc release 1.0](../../issues/release-test-suite-fails/001-issue-release-test-suite-fails.md) | [Todo](../release-test-suite-fails/001-todo-release-test-suite-fails.md) | Chua co | Mot phan da giam rui ro sau fix dotenv, van can chay/fix suite tong. |
| [ ] | medium | [AI Chat giu lich su khong gioi han](../../issues/ai-chat-unbounded-context-tokens/001-issue-ai-chat-unbounded-context-tokens.md) | [Todo](../ai-chat-unbounded-context-tokens/001-todo-ai-chat-unbounded-context-tokens.md) | Chua co | Rui ro token/latency khi chat dai. |
| [ ] | medium | [Features Hub widget test tim AI Coach khong con ton tai](../../issues/features-hub-widget-test-stale/001-issue-features-hub-widget-test-stale.md) | [Todo](../features-hub-widget-test-stale/001-todo-features-hub-widget-test-stale.md) | Chua co | Co the fix cung dot voi release test suite. |
| [ ] | medium | [Cac page cham soc moi khong luu du lieu that](../../issues/new-care-pages-session-only-state/001-issue-new-care-pages-session-only-state.md) | [Todo](../new-care-pages-session-only-state/001-todo-new-care-pages-session-only-state.md) | Chua co | Can chon persistence that hay doi copy. |
| [ ] | medium | [Flutter analyze dang fail voi 290 issue](../../issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md) | [Todo](../release-analyze-red-290-issues/001-todo-release-analyze-red-290-issues.md) | Chua co | Nen tach batch nho de tranh blast radius lon. |
| [ ] | medium | [Dart format dry-run fail o 6 page moi](../../issues/release-format-dry-run-fails-new-pages/001-issue-release-format-dry-run-fails-new-pages.md) | [Todo](../release-format-dry-run-fails-new-pages/001-todo-release-format-dry-run-fails-new-pages.md) | Chua co | Nen lam som vi format-only, rui ro thap. |

## Checklist xu ly tiep
1. [ ] Chon todo tiep theo theo severity va rui ro release.
2. [ ] Chuyen sang mode `fix-issues` cho dung mot todo.
3. [ ] Doc issue + todo + mot playbook lien quan.
4. [ ] Sua nho nhat de dong todo.
5. [ ] Chay command kiem chung ghi trong todo.
6. [ ] Tao/cap nhat `docs/fixbug/<slug>/`.
7. [ ] Tao/cap nhat `docs/worklog/<yyyy-mm-dd>/`.
8. [ ] Cap nhat checklist nay: tick Done, them link Fixbug, va ghi chu ket qua.

## Goi y thu tu fix
1. [AI raw payload logging](../ai-raw-payload-logging/001-todo-ai-raw-payload-logging.md) - high, bao ve du lieu nhay cam.
2. [Onboarding sensitive snapshot logging](../onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md) - high, bao ve PII/health data.
3. [Release format dry-run fails new pages](../release-format-dry-run-fails-new-pages/001-todo-release-format-dry-run-fails-new-pages.md) - medium nhung nhanh, unblock release hygiene.
4. [Release test suite fails](../release-test-suite-fails/001-todo-release-test-suite-fails.md) - high, release gate.
5. [Auth guards disabled](../auth-guards-disabled/001-todo-auth-guards-disabled.md) - high, can chot route policy.
