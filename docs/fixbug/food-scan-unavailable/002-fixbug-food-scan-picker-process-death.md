Commit de xuat: fix(food-scan): on dinh picker va nutrition fallback

# Fixbug - Food Scan bi dung khi chon anh va thieu dinh duong

## Trieu chung

- Tren Xiaomi RAM 4 GB, mo thu vien anh co the lam MIUI dung process NanoBio; ket qua picker khong quay lai app.
- SmolVLM co the nhan dien mon nhung khong tra du bo calories/macros, lam trang ket qua bi chan.

## Root cause da xac nhan

1. `LocalAiSetupGate` nap model text da chon moi lan khoi dong lanh, du chi can biet model da cai dat va checksum hop le. PSS do duoc khoang 1.88 GiB truoc picker; MIUI force-stop NanoBio khi DocumentsUI mo.
2. Luong unload truoc picker khong giu khoa runtime trong suot thao tac. Mot AI job dang doi co the nap lai model khi DocumentsUI foreground.
3. Vision prompt v6 co luot tra mon an nhung khong co nutrition core fields du dung; parser alias `nutrition` mot minh khong sua duoc ket qua thieu estimates.
4. Anh goc duoc giu local; chi payload dua vao vision model duoc resize toi da 1024 px.

## Da sua

- Gate startup chi kiem tra model da cai dat va checksum, khong nap model text vao RAM khi mo app.
- Them `withModelUnloaded` de unload model va giu operation lease trong suot picker va chuan bi anh; giu recovery cho anh bi mat khi Android recreate activity.
- Chuyen Food Scan sang SmolVLM-500M-Instruct Q8, pin assets/hash va cap nhat dung luong/RAM trong catalog.
- Chuan hoa anh payload rieng cho vision toi da 1024 px; anh preview va anh luu local van giu ban goc.
- Parser chap nhan nutrition object theo `fallback_nutrition` hoac `nutrition`; kiem tra du calories/protein/carbohydrates/fat.
- Neu vision nhan dien mon/khau phan nhung thieu dinh duong, chay them mot prompt text-only local cho chinh cac mon va khoi luong da nhan dien. Neu van thieu estimates, Food Scan tu choi ket qua dinh duong khong day du.
- Giu ingredients/allergens trong schema; chi hien thi vi chat ma model tra ve, khong tu dien vi chat khong duoc ho tro.

## Kiem chung

- Thiet bi `220333QPG` (Xiaomi 220333QPG), Android 11, RAM khoang 3.77 GiB; anh Camera `IMG_20261020_191224.jpg` (2.63 MB) duoc chon qua DocumentsUI.
- Sau khoi dong lanh, PSS app khoang 414 MiB; vao Food Scan khoang 413 MiB. Khi picker foreground, PSS khoang 431 MiB; PID `16506` van song va anh quay lai preview.
- Luot vision v6 dau tien tra `NUTRITION_UNAVAILABLE`; alias parser don le van chua dat.
- Sau khi them text-only local nutrition fallback, cung anh cho ket qua Banh mi, 120 g, 320 kcal, protein 10 g, carbohydrate 55 g, chat beo 6 g. Tong thoi gian luot gan 155 giay.
- PSS cao nhat duoc lay mau khoang 1.87 GiB trong inference; sau khi render ket qua khoang 1.73 GiB voi swap PSS khoang 560 MiB. PID van song; khong thay ANR/force-stop moi.
- Trang ket qua hien nut `Xac nhan da an`; khong bam nut de khong ghi nhan bua an thay nguoi dung. Danh gia suc khoe hien `Chua du du lieu` va bao can thu lai; khong xem day la ket qua danh gia suc khoe thanh cong.
- Analyzer targeted khong co loi; debug APK moi nhat build thanh cong. 27 test Food Scan/image picker/catalog da pass truoc khi them nutrition fallback; khong chay lai tests sau thay doi cuoi cung.

## Gioi han

- Inference tren Xiaomi thu mat gan 155 giay va dung swap; chua xac nhan quet lien tiep, nhiet do, hoac thiet bi RAM thap hon.
- Du lieu calories/macros la uoc tinh local tu anh/ten mon va khoi luong, khong phai can do hay gia tri nhan dinh duong.
- Danh gia suc khoe tren luot cuoi khong hoan tat; trang hien can thu lai.
- Chua kiem chung chat luong cho nhieu mon, nhieu anh, hoac model/firmware khac.
- Cac asset Qwen cu trong app storage khong bi xoa trong task nay.
