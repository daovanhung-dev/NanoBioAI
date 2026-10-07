Commit de xuat: docs(worklog): ghi nhan phien event-info-stt

# Worklog - Them STT cho danh sach thong tin su kien

## Thoi gian

- Ngay: 2026-10-07
- Bat dau: khoang 11:10
- Ket thuc: 11:20
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: coding
- Module chinh: NanoBio Early Access - Thong tin su kien
- Yeu cau goc: them cot STT, danh lien tuc qua cac trang va bat dau lai khi tim kiem.

## Da lam

- Them cot STT o ben trai cot so dien thoai, danh theo `page * PAGE_SIZE + index + 1`.
- Dat cot hep, can giua va khong xuong dong; bang tiep tuc dung vung cuon ngang hien co.
- Mo rong test UI cho dong dau, dong 25, trang ke tiep bat dau 26 va tim kiem bat dau lai tu 1.

## File code/docs da sua

- `admin-web/src/pages/EventInfoPage.tsx` - them cot va tinh STT.
- `admin-web/src/styles.css` - dinh dang cot STT hep.
- `admin-web/src/pages/EventInfoPage.test.tsx` - kiem tra STT tren trang va sau tim kiem.
- `docs/worklog/2026-10-07/009-worklog-event-info-serial-number.md` - ghi nhan phien.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `deno run --allow-all node_modules/vitest/vitest.mjs run src/pages/EventInfoPage.test.tsx`: PASS - 3 test.
- `deno run --allow-all node_modules/typescript/bin/tsc --noEmit`: PASS.
- `deno run --allow-all node_modules/vite/bin/vite.js build`: PASS - co canh bao bundle JS lon hon 500 kB.
- `git diff --check`: PASS.
- Kiem tra browser desktop/mobile: SKIPPED - khong mo route Admin co the tai du lieu khach hang; CSS giu cuon ngang va test UI xac nhan gia tri.

## Loi/Rui ro

- Da fix: danh so theo trang va tu dong reset vi luong tim kiem hien tai quay ve trang 1.
- Chua fix: khong co.
- Can kiem tra tiep: neu can bang chung layout thuc te tren viewport mobile, kiem tra trong moi truong Admin co du lieu test duoc phep su dung.

## Ty le hoan thanh

- Hoan thanh: thay doi code va kiem tra tu dong muc tieu.
- Dang do: khong co.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - STT bam theo page offset san co, khong can doi API.
- Muc do hoan thanh task: hoan tat.
- Bang chung kiem chung: test trang thong tin su kien 3/3, TypeScript va production build deu PASS.
- Diem ton token/chua toi uu: Node/npm khong co san; dung Deno de chay cac entrypoint da cai trong `node_modules`.
- Cach toi uu cho phien sau: tiep tuc chay truc tiep entrypoint local khi Node/npm vang mat, neu runtime tuong thich.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
