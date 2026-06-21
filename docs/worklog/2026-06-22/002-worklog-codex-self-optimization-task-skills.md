Commit de xuat: docs(codex): them self-optimization va task-skills

# Worklog - Codex Self Optimization Task Skills

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: trong phien Codex hien tai
- Ket thuc: trong phien Codex hien tai
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-context
- Module chinh: `.codex`, history learning, task-skills, project skill
- Yeu cau goc: them co che de AI Agent tu danh gia chat luong, muc do hoan thanh, toi uu token sau moi phien; tu phan loai kinh nghiem theo task va doc skill tuong ung khi lam task.

## Da lam

- Cap nhat `.codex/AGENTS.md` de doc `task-skills` sau workflow va bat buoc dat cau hoi toi uu token truoc khi mo rong context.
- Cap nhat `.codex/DOCS_WORKFLOW.md` va `.codex/CHECKLIST.md` de them self-review vao worklog va quy trinh after-work.
- Cap nhat workflow registry va workflow `docs-context` de rang buoc thu tu workflow -> task-skill -> domain.
- Cap nhat skill project-local `nanobio-project-agent` va references de load task-skill, session quality review, va history refresh.
- Mo rong `.codex/tools/update_worklog_learning.ps1` de sinh `.codex/history/SESSION_QUALITY_REVIEW.md` va `.codex/task-skills/*.md`.
- Sua loi PowerShell scalar `.Count` khi task group chi co 1 worklog.
- Chay refresh history de sinh task-skills tu toan bo worklog hien co.

## File code/docs da sua

- `.codex/AGENTS.md` - sua - them task-skill router va self-review rule.
- `.codex/CHECKLIST.md` - sua - them token question, task-skill read, self-review after-work.
- `.codex/DOCS_WORKFLOW.md` - sua - them worklog self-review template.
- `.codex/README.md` - sua - mo ta `task-skills` va cach doc context moi.
- `.codex/workflows/README.md` - sua - them common session rules.
- `.codex/workflows/docs-context.md` - sua - them required context va completion cho task-skills.
- `.codex/skills/nanobio-project-agent/SKILL.md` - sua - them task-skill va session quality review.
- `.codex/skills/nanobio-project-agent/references/context-router.md` - sua - them task-skill vao default read pack.
- `.codex/skills/nanobio-project-agent/references/worklog-learning.md` - sua - them task-skill va self-optimization rule.
- `.codex/tools/update_worklog_learning.ps1` - sua - sinh session review va task-skills theo task type.
- `.codex/history/*` - sinh lai - cap nhat memory tu worklog.
- `.codex/task-skills/*` - tao/sinh lai - skill theo loai task.
- `.codex/MAP_TREE.md` - sinh lai - cap nhat inventory co `task-skills` va worklog moi.
- `docs/worklog/2026-06-22/002-worklog-codex-self-optimization-task-skills.md` - tao - ghi nhan phien nay.

## Tai lieu lien quan

- `.codex/history/SESSION_QUALITY_REVIEW.md`
- `.codex/task-skills/README.md`
- `.codex/skills/nanobio-project-agent/SKILL.md`

## Commands

- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - sinh `history` va `task-skills` tu 25 worklog truoc khi tao worklog nay.
- `python C:\Users\daohu\.codex\skills\.system\skill-creator\scripts\quick_validate.py .codex\skills\nanobio-project-agent`: PASS - skill hop le.
- `rg -n "lib/features|lib/services/ai|lib/services/notifications|TOKEN_SAVING_RULES|docs/DD/README|MODULE_INDEX|prompts" .codex`: PASS - khong con stale reference.
- `Select-String -Path .codex\task-skills\*.md -Pattern '\$taskKey|Generated from  worklog'`: PASS - khong con placeholder/count rong.
- `rg --files .codex docs\worklog docs\DD docs\BD docs\supabase`: PASS - inventory docs/context doc duoc.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh lan cuoi tu 26 worklog sau khi tao worklog nay.
- Sinh lai `.codex/MAP_TREE.md` tu `rg --files .codex docs lib test`: PASS - inventory co task-skills va worklog moi; loc cac source path gay stale-check noise.
- `git diff --check -- .codex docs\worklog`: PASS - chi co canh bao LF/CRLF, khong co whitespace error.

## Loi/Rui ro

- Da fix: PowerShell wildcard check ban dau dung `-LiteralPath` nen fail; chay lai bang `-Path` da PASS.
- Da fix: task-skill README bi rong count voi nhom 1 worklog; da boc `$taskEntries` bang array va refresh lai.
- Chua fix: mot so task key sinh tu lich su co slug khong dau/chua chuan do worklog cu ghi `Loai task` khong dong nhat.
- Can kiem tra tiep: neu muon task key on dinh hon, co the them mapping manual workflow -> canonical task key trong script refresh.

## Ty le hoan thanh

- Hoan thanh: them self-review, token optimization question, task-skill generation, project skill routing, va refresh history.
- Dang do: chua chay Flutter analyze/test vi chi thay doi docs/context `.codex`.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - cac quy tac moi duoc dat vao entrypoint, checklist, workflow, skill, generator va file sinh ra.
- Muc do hoan thanh task: hoan thanh phan cot loi; task-skills da duoc sinh theo loai task tu worklog.
- Bang chung kiem chung: refresh script PASS, skill validate PASS, stale-reference check PASS, placeholder/count check PASS.
- Diem ton token/chua toi uu: da doc mot so router va file context de dam bao dong bo; lan sau co the doc `.codex/task-skills/docs-context.md` truoc khi xem chi tiet workflow.
- Cach toi uu cho phien sau: them canonical mapping trong script neu task key lich su bi nhieu bien the; doc task-skill truoc raw history.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
