# Playbook - Onboarding

## Muc tieu

Onboarding thu thap ho so suc khoe, luu SQLite day du, roi kich hoat flow tao meal plan, exercise/daily tasks, lifestyle schedule va notifications.

## Doc truoc

- `lib/features/onboarding/`
- `lib/main.dart` neu task lien quan callback sau onboarding.
- SQLite models/DAOs lien quan user, health profile, goals, habits, conditions, allergies, treatments, survey answers.
- `.codex/playbooks/access_membership_referral.md` neu task cham guest/basic access, tao lich trinh sau onboarding, login gate, hoac quota tao lich trinh.
- Neu sau submit bi loi: doc them playbook AI, lifestyle schedule, notification theo trieu chung.

## Luong dung

```text
Form input
-> validate
-> save profile/goals/habits/conditions/allergies/treatments/survey answers
-> generate meal/tasks/schedule
-> save SQLite
-> schedule notifications
-> navigate/dashboard refresh
```

## Quy tac

- Giu provider/controller/route/callback public neu chua `rg` usage.
- Validate truoc khi luu; khong bo qua field bat buoc bang nullable workaround.
- Sau submit thanh cong phai luu du data can cho dashboard va flow ca nhan hoa.
- Guest sau onboarding chi duoc AI tao lich trinh ca nhan 1 lan; muon tao them phai dang nhap va di qua membership/quota gate.
- Error state khong lam mat du lieu da nhap.
- Copy tieng Viet co dau, Nami nhe nhang, khong phan xet.

## Tim nhanh

```bash
rg "Onboarding|onboarding|submit|complete|callback" lib/features/onboarding lib/main.dart test
rg "health_profiles|health_goals|lifestyle_habits|survey_answers|allergies|treatments" lib/core/storage/localdb lib/features/onboarding test
```

## Test nen chay

- Validate required fields.
- Mapping form -> model/DAO.
- Submit success goi callback/flow tiep theo.
- Regression cho error state.
