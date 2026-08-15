# Meal Plan image mapping audit

## Source of truth

- Recipe source: `docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`.
- The source document states 163 recipes across 64 condition/topic sections.
- Image source: `assets/images/meals/pdf_health_book` on current `main`.
- Git tree SHA audited: `7f3b83457374d4c4cacdfe4fd84e7f42d5c28b1c`.
- Exact `.webp` filenames captured in the resolver allow-list: **124**.

The recipe count and image-file count are not expected to be identical: recipes repeat across topics and the asset directory contains filename variants/aliases. No one-to-one count assumption is made.

## Mapping contract

1. Normalize the runtime `mealName` deterministically: lowercase, fold Vietnamese diacritics, replace separators/punctuation with `_`.
2. Form `<canonical_slug>.webp`.
3. Use the image **only if that exact filename is present in the audited allow-list**.
4. No `contains`, prefix, Levenshtein, AI inference, or nearest-name matching is permitted.
5. If no exact allow-listed filename exists, return `null`; UI renders a neutral food placeholder.
6. `Image.asset.errorBuilder` is a second safety net for missing/corrupt bundled assets.

## Representative verified mappings

| Runtime dish name | Exact asset |
|---|---|
| `CANH THỊT BÒ RAU CẢI BÓ XÔI` | `canh_thit_bo_rau_cai_bo_xoi.webp` |
| `Sinh tố cần tây và táo` | `sinh_to_can_tay_va_tao.webp` |
| `SÚP KHOAI TÂY VÀ CAROT` | `sup_khoai_tay_va_carot.webp` |
| `Trà hoa cúc mật ong` | `tra_hoa_cuc_mat_ong.webp` |
| `Canh cá chép nấu rau cần` | `canh_ca_chep_nau_rau_can.webp` |
| `Canh cá chép và rau cần` | `canh_ca_chep_va_rau_can.webp` |

## Duplicate payload audit

The Git tree exposes several different filenames that point to the same blob SHA. The resolver **does not merge names**; it preserves each exact filename. Examples observed during audit:

- `canh_ca_chep_nau_rau_can.webp` / `canh_ca_chep_va_rau_can.webp`
- `canh_ga_nau_nam.webp` / `canh_nam_huong_va_ga.webp`
- `canh_rau_mong_toi_va_dau_hu.webp` / `canh_rau_mong_toi_voi_dau_phu.webp`
- `nuoc_ep_dua_hau_va_bac_ha.webp` / `nuoc_ep_dua_hau_va_la_bac_ha.webp`
- `nuoc_ep_mat_ong_va_chanh.webp` / `tra_chanh_mat_ong.webp`
- `tra_gung_que_mat_ong.webp` / `tra_gung_va_mat_ong.webp`
- `sinh_to_cam_va_chanh.webp` / `sinh_to_cam_va_gung.webp`
- `nuoc_ep_ca_rot_va_cu_den.webp` / `sinh_to_ca_rot_va_cu_den.webp`
- `canh_ca_loc_nau_rau_cai.webp` / `canh_ca_loc_nau_rau_can.webp`

Some are clear wording/preparation aliases; some are semantically different names sharing the same source image payload. This integration does not silently rewrite those source assets. If pixel-level semantic correction is required, those files should be reviewed/replaced at the asset layer; the UI mapping remains deterministic.

## Catalog code decision

`MealPlanEntity.catalogCode` exists, but the current repository does not expose a source-backed `catalogCode -> pdf_health_book asset` contract. Using it for image inference would therefore be less exact than canonical `mealName`. This patch deliberately does not guess from catalog codes.
