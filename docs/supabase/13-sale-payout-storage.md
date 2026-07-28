Commit de xuat: docs(supabase): cau hinh storage minh chung chi tra Sale

# Sale payout proof storage

Bucket `sale-payout-proofs` dung de Admin upload anh minh chung khi mark paid
yeu cau quy doi diem Sale. Bucket phai private; database chi luu storage path
trong `sale_point_conversions.metadata.payment_proof_path` va audit event.

## Hai giai doan local/sandbox

1. Chay `config.sql` de rebuild database, fixture canonical 19, bucket private
   va policy local/sandbox. Giai doan nay chi tao contract/du lieu quan he;
   khong chen `storage.objects`, anh chung chi hay bang chung chi tra that.
2. Kiem tra bucket/policy vua rebuild, sau do dung tai khoan Admin co
   `sales.write` de upload mot anh gia lap moi. Chi goi
   `admin_review_sale_point_conversion(..., p_payment_proof_path)` sau khi co
   path cua object vua upload; kiem tra tai khoan khong co quyen khong doc duoc.
   Fixture runner dung prefix `sale-point-conversions/{conversion_id}/`, upload
   voi `upsert: false` va chi duoc chay mot lan sau moi destructive rebuild.

Khong dua object, anh, path hay thong tin chi tra cua fixture sang staging dung
chung hoac production. `config.sql` khong quan ly `storage.objects` cua bucket
nay.

## Kiem tra sau rebuild

1. Xac nhan `config.sql` da tao bucket `sale-payout-proofs` trong local/sandbox.
2. Xac nhan bucket private va gioi han `image/jpeg`, toi da 5 MB.
3. Chi cho Admin app upload sau khi user co permission `sales.write`.
4. Khong cap policy public read. Khi can xem minh chung, tao signed URL qua
   backend/Admin workflow co audit.
5. Xoa object gia lap sau smoke test hoac reset local/sandbox theo quy trinh
   van hanh; khong dung bucket nay de luu tai lieu that.

## Policy SQL tham chieu

Chinh sach nay duoc fold vao fixture/rebuild contract; doan duoi day chi de
review hoac khoi phuc policy trong local/sandbox. Rebuild khong quan ly
`storage.objects` va khong duoc dung nhu bang chung da upload.

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

- Sau giai doan 2, upload path co dang
  `sale-point-conversions/{conversion_id}/{timestamp}-{filename}`.
- `admin_review_sale_point_conversion(..., p_payment_proof_path)` chi luu path
  cua object vua upload trong local/sandbox khi Admin confirm paid.
- Admin co the confirm paid khong anh, nhung UI nen hien canh bao/khuyen nghi
  upload minh chung.
- Fixture SQL khong thay the upload that, policy RLS hai tai khoan hay evidence
  cua payment workflow; khong claim san sang production neu chua co smoke test
  sandbox tach rieng.
- Neu can chay lai `Seed-StorageFixtures.ps1`, rebuild `config.sql` va ap dung
  lai profile demo truoc. Khong xoa/ghi de evidence immutable bang client de
  co gang reset fixture.
