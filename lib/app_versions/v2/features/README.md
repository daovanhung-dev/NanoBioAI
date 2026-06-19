# V2 Features

V2 la lop mo rong chuc nang tren nen v1, khong phai replacement cua v1.

Quy uoc:

- Feature moi dat trong `lib/app_versions/v2/features/<feature_name>/`.
- Moi feature giu cau truc `presentation/`, `domain/`, `data/`, `providers/` khi can.
- V2 app/router co the compose v1 routes de giu hanh vi hien tai.
- V2 feature khong import truc tiep v1 presentation/controller.
- Neu can du lieu, di qua repository/service/shared storage thay vi query UI v1.
- `core/` khong duoc import nguoc vao `app_versions/v1` hoac `app_versions/v2`.
