from pathlib import Path
from uuid import UUID, uuid4

from fastapi import Request, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.business_models import SalePointConversion
from nanobio_backend.db.models import FileObject, User
from nanobio_backend.modules.storage import query

ALLOWED_BUCKETS = {"sale-payout-proofs"}
ALLOWED_MEDIA_TYPES = {"image/jpeg", "image/png", "application/pdf"}


def create_file_object(
    bucket: str, request: Request, upload: UploadFile, user: User, db: Session
) -> dict[str, int | str]:
    if bucket not in ALLOWED_BUCKETS:
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy vị trí lưu tệp.")
    if upload.content_type not in ALLOWED_MEDIA_TYPES:
        raise ApiError(422, "UNSUPPORTED_FILE_TYPE", "Định dạng tệp chưa được hỗ trợ.")
    max_bytes = request.app.state.settings.max_upload_bytes
    content = upload.file.read(max_bytes + 1)
    if len(content) > max_bytes:
        raise ApiError(413, "FILE_TOO_LARGE", "Tệp vượt quá dung lượng cho phép.")
    signatures = {
        "image/jpeg": content.startswith(b"\xff\xd8\xff"),
        "image/png": content.startswith(b"\x89PNG\r\n\x1a\n"),
        "application/pdf": content.startswith(b"%PDF-"),
    }
    if not signatures.get(upload.content_type or "", False):
        raise ApiError(422, "FILE_CONTENT_MISMATCH", "Nội dung tệp không khớp định dạng khai báo.")
    object_id = uuid4()
    storage_name = object_id.hex
    owner_dir: Path = request.app.state.settings.upload_root / str(user.id)
    owner_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    destination = owner_dir / storage_name
    temporary = owner_dir / f".{storage_name}.tmp"
    try:
        temporary.write_bytes(content)
        temporary.replace(destination)
        with atomic(db):
            db.add(
                FileObject(
                    id=object_id,
                    owner_id=user.id,
                    bucket=bucket,
                    storage_name=storage_name,
                    media_type=upload.content_type or "application/octet-stream",
                    size_bytes=len(content),
                )
            )
        return {"id": str(object_id), "bucket": bucket, "size_bytes": len(content)}
    except Exception:
        temporary.unlink(missing_ok=True)
        destination.unlink(missing_ok=True)
        raise


def get_file_response(
    bucket: str, file_id: UUID, request: Request, user: User, db: Session
) -> FileResponse:
    record = query.get_owned_file(db, user.id, bucket, file_id)
    if record is None:
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    root = request.app.state.settings.upload_root.resolve()
    path = (root / str(user.id) / record.storage_name).resolve()
    if root not in path.parents or not path.is_file():
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    return FileResponse(path, media_type=record.media_type, filename=str(record.id))


def get_admin_payout_proof_response(
    bucket: str, file_id: UUID, request: Request, user: User, db: Session
) -> FileResponse:
    if bucket != "sale-payout-proofs":
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy vị trí lưu tệp.")
    record = db.get(FileObject, file_id)
    if record is None or record.bucket != bucket:
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    attached = db.scalar(
        select(SalePointConversion.id)
        .where(SalePointConversion.metadata_json["payment_proof_path"].as_string() == str(file_id))
        .limit(1)
    )
    if attached is None:
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    root = request.app.state.settings.upload_root.resolve()
    path = (root / str(record.owner_id) / record.storage_name).resolve()
    if root not in path.parents or not path.is_file():
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    return FileResponse(path, media_type=record.media_type, filename=str(record.id))


def remove_file_object(
    bucket: str, file_id: UUID, request: Request, user: User, db: Session
) -> None:
    record = query.get_owned_file(db, user.id, bucket, file_id)
    if record is None:
        raise ApiError(404, "RESOURCE_NOT_FOUND", "Không tìm thấy tệp.")
    owner_dir = request.app.state.settings.upload_root / str(user.id)
    path = owner_dir / record.storage_name
    quarantine = owner_dir / f".{record.storage_name}.deleting"
    try:
        if path.exists():
            path.replace(quarantine)
        with atomic(db):
            db.delete(record)
    except Exception:
        if quarantine.exists() and not path.exists():
            quarantine.replace(path)
        raise
    quarantine.unlink(missing_ok=True)
