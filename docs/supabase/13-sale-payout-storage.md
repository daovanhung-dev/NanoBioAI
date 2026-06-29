Commit de xuat: docs(supabase): cau hinh storage minh chung chi tra Sale

# Sale payout proof storage

Bucket `sale-payout-proofs` dung de Admin upload anh minh chung khi mark paid
yeu cau quy doi diem Sale. Bucket phai private; database chi luu storage path
trong `sale_point_conversions.metadata.payment_proof_path` va audit event.

## Cau hinh tren Supabase dashboard

1. Tao bucket `sale-payout-proofs`.
2. Tat public access.
3. Chi cho Admin app upload sau khi user co permission `sales.write`.
4. Dat gioi han file anh theo chinh sach van hanh, vi du `image/jpeg`,
   `image/png`, dung luong toi da 5 MB.
5. Khong cap policy public read. Khi can xem minh chung, tao signed URL qua
   backend/Admin workflow co audit.

## Optional storage policy SQL

Chay doan nay trong moi truong da co Supabase Storage schema neu muon rang
buoc upload bang RLS. Khong dua vao `config.sql` vi local rebuild app schema
khong quan ly `storage.objects`.

```sql
insert into storage.buckets (id, name, public)
values ('sale-payout-proofs', 'sale-payout-proofs', false)
on conflict (id) do update set public = false;

create policy "admin_upload_sale_payout_proofs"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'sale-payout-proofs'
  and public.admin_has_permission('sales.write')
);

create policy "admin_read_sale_payout_proofs"
on storage.objects for select to authenticated
using (
  bucket_id = 'sale-payout-proofs'
  and public.admin_has_permission('sales.write')
);
```

## Acceptance

- Upload path co dang
  `sale-point-conversions/{conversion_id}/{timestamp}-{filename}`.
- `admin_review_sale_point_conversion(..., p_payment_proof_path)` luu path khi
  Admin confirm paid.
- Admin co the confirm paid khong anh, nhung UI nen hien canh bao/khuyen nghi
  upload minh chung.
