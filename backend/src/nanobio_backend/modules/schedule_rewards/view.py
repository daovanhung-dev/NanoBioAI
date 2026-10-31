from __future__ import annotations

import hashlib
import re
from datetime import UTC, date, datetime, time, timedelta
from pathlib import Path
from typing import Any
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo

from fastapi import Request, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.business_models import (
    ScheduleCompletionAttempt,
    ScheduleCompletionProof,
    ScheduleHealthCheckin,
    ScheduleRewardEligibility,
    ScheduleRewardRegistration,
    SystemConfigVersion,
    WellnessPointAllocation,
    WellnessPointLedger,
)
from nanobio_backend.db.models import (
    CloudSnapshot,
    FileObject,
    HealthSubject,
    UsageEvent,
    User,
    now_utc,
)
from nanobio_backend.modules.business.view import _get_or_create_wallet
from nanobio_backend.modules.schedule_rewards.models import (
    BeginCompletionRequest,
    FinalizeCompletionRequest,
    HealthCheckinRequest,
    RegisterEligibilityRequest,
    UndoCompletionRequest,
    UndoHealthCheckinRequest,
)

LOCAL_TZ = ZoneInfo("Asia/Ho_Chi_Minh")
PROOF_BUCKET = "schedule-completion-proofs"
MAX_PROOF_BYTES = 5 * 1024 * 1024
MANUAL_SOURCE = re.compile(
    r"^manual_health\|[0-9a-fA-F-]{36}\|"
    r"(quick_complete|hydration|mood_stress|sleep_checkin|weight_checkin)\|"
    r"[01]\|(once|daily|weekdays|weekends)$"
)


def register_eligibilities(
    db: Session, user: User, payload: RegisterEligibilityRequest
) -> dict[str, Any]:
    now = now_utc()
    request_id = payload.request_id.strip()
    ids = [row.schedule_item_id for row in payload.items]
    if len(ids) != len(set(ids)):
        raise ApiError(422, "SCHEDULE_ITEMS_INVALID", "Danh sách lịch có mã bị trùng.")
    with atomic(db):
        prior = db.scalar(
            select(ScheduleRewardRegistration)
            .where(
                ScheduleRewardRegistration.user_id == user.id,
                ScheduleRewardRegistration.idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if prior:
            if prior.schedule_request_id != request_id:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho yêu cầu khác.")
            items = list(
                db.scalars(
                    select(ScheduleRewardEligibility).where(
                        ScheduleRewardEligibility.user_id == user.id,
                        ScheduleRewardEligibility.schedule_request_id == request_id,
                    )
                )
            )
            return _registration_result(request_id, items, replay=True)

        stored = db.scalar(
            select(CloudSnapshot)
            .where(CloudSnapshot.user_id == user.id, CloudSnapshot.snapshot_type == "mobile-v1")
            .with_for_update()
        )
        tables = _snapshot_tables(stored)
        ai_request = next(
            (
                row
                for row in tables.get("personal_schedule_ai_requests", [])
                if str(row.get("request_id", "")) == request_id
            ),
            None,
        )
        if ai_request is None or ai_request.get("status") != "succeeded":
            raise ApiError(
                409, "SCHEDULE_REQUEST_NOT_ELIGIBLE", "Chưa đồng bộ được kế hoạch đã tạo."
            )
        try:
            days = int(ai_request.get("days", 0))
            item_count = int(ai_request.get("schedule_item_count", 0))
            start_date = date.fromisoformat(str(ai_request.get("start_date", ""))[:10])
        except (TypeError, ValueError) as exc:
            raise ApiError(
                409, "SCHEDULE_REQUEST_NOT_ELIGIBLE", "Thông tin kế hoạch chưa hợp lệ."
            ) from exc
        actor_mode = str(ai_request.get("actor_mode", ""))
        if not 1 <= days <= 7 or not days * 10 <= item_count <= days * 11:
            raise ApiError(
                409, "SCHEDULE_REQUEST_NOT_ELIGIBLE", "Kế hoạch chưa đủ điều kiện nhận điểm."
            )
        if actor_mode not in {"member_new", "initial_guest"}:
            raise ApiError(409, "SCHEDULE_REQUEST_NOT_ELIGIBLE", "Loại kế hoạch chưa đủ điều kiện.")
        if (
            actor_mode == "member_new"
            and db.scalar(
                select(UsageEvent.id).where(
                    UsageEvent.user_id == user.id,
                    UsageEvent.feature_key == "personal_schedule_generation",
                    UsageEvent.idempotency_key == request_id,
                    UsageEvent.event_source.in_(
                        ("trusted_backend", "edge_function", "sql_job", "admin")
                    ),
                )
            )
            is None
        ):
            raise ApiError(
                409, "SCHEDULE_QUOTA_COMMIT_REQUIRED", "Kế hoạch chưa được máy chủ xác nhận."
            )

        schedule_rows = tables.get("lifestyle_schedule_items", [])
        full_items = [
            row
            for row in schedule_rows
            if row.get("ai_generated") is True
            and _date(row.get("schedule_date")) >= start_date
            and _date(row.get("schedule_date")) < start_date + timedelta(days=days)
        ]
        by_id = {str(row.get("id")): row for row in full_items}
        full_ids = set(by_id)
        if (
            len(full_items) != item_count
            or len({str(row.get("schedule_date")) for row in full_items}) != days
        ):
            raise ApiError(
                409, "SCHEDULE_PLAN_INVALID", "Các mục trong kế hoạch chưa đồng bộ đầy đủ."
            )
        if actor_mode == "member_new" and set(map(str, ids)) != full_ids:
            raise ApiError(
                409,
                "MEMBER_SCHEDULE_MANIFEST_MISMATCH",
                "Danh sách mục không khớp kế hoạch máy chủ.",
            )
        if actor_mode == "initial_guest":
            guest_marker = db.scalar(
                select(ScheduleRewardRegistration.id).where(
                    ScheduleRewardRegistration.guest_user_id == user.id
                )
            )
            if guest_marker:
                raise ApiError(
                    409,
                    "GUEST_SCHEDULE_REQUEST_ALREADY_REGISTERED",
                    "Kế hoạch khởi tạo đã được đăng ký.",
                )
        else:
            per_day: dict[str, list[dict[str, Any]]] = {}
            for row in full_items:
                per_day.setdefault(str(row.get("schedule_date")), []).append(row)
            if any(
                not 10 <= len(rows) <= 11
                or len({str(row.get("start_time")) for row in rows}) != len(rows)
                for rows in per_day.values()
            ):
                raise ApiError(409, "MEMBER_SCHEDULE_PLAN_INVALID", "Lịch mỗi ngày chưa hợp lệ.")

        selected: list[dict[str, Any]] = []
        for item_id in ids:
            scheduled_row = by_id.get(str(item_id))
            if scheduled_row is None or scheduled_row.get("is_completed") is True:
                raise ApiError(
                    409, "SCHEDULE_ITEMS_NOT_FOUND", "Không tìm thấy mục lịch đủ điều kiện."
                )
            if actor_mode == "initial_guest" and _schedule_start(scheduled_row) <= now:
                raise ApiError(
                    409, "GUEST_SCHEDULE_ITEM_NOT_IN_PINNED_PLAN", "Mục lịch đã qua giờ bắt đầu."
                )
            selected.append(scheduled_row)
        if actor_mode == "member_new" and len(selected) != item_count:
            raise ApiError(
                409, "MEMBER_SCHEDULE_MANIFEST_INCOMPLETE", "Cần đăng ký đủ các mục trong kế hoạch."
            )
        subject = _self_subject(db, user.id)
        manifest_hash = hashlib.sha256(",".join(sorted(full_ids)).encode("utf-8")).hexdigest()
        registration = ScheduleRewardRegistration(
            user_id=user.id,
            guest_user_id=user.id if actor_mode == "initial_guest" else None,
            schedule_request_id=request_id,
            actor_mode=actor_mode,
            plan_start_date=start_date,
            plan_days=days,
            plan_item_count=item_count,
            manifest_hash=manifest_hash,
            idempotency_key=payload.idempotency_key,
        )
        db.add(registration)
        created: list[ScheduleRewardEligibility] = []
        for row in selected:
            start_time = _time(row.get("start_time"))
            start_at = datetime.combine(
                _date(row.get("schedule_date")), start_time, LOCAL_TZ
            ).astimezone(UTC)
            eligibility = ScheduleRewardEligibility(
                user_id=user.id,
                subject_id=subject.id,
                schedule_item_id=UUID(str(row["id"])),
                schedule_request_id=request_id,
                schedule_date=_date(row.get("schedule_date")),
                start_time=start_time,
                window_start=start_at,
                window_end=start_at + timedelta(minutes=30),
                title_snapshot=str(row.get("title", ""))[:240],
                category_snapshot=str(row.get("category", ""))[:80] or None,
                source_type_snapshot=str(row.get("source_type", ""))[:80],
                source_id_snapshot=str(row.get("source_id"))[:160]
                if row.get("source_id")
                else None,
                status="eligible",
                registration_idempotency_key=payload.idempotency_key,
            )
            db.add(eligibility)
            created.append(eligibility)
        db.flush()
        return _registration_result(request_id, created, replay=False)


def begin_completion(db: Session, user: User, payload: BeginCompletionRequest) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        attempt = db.scalar(
            select(ScheduleCompletionAttempt)
            .where(
                ScheduleCompletionAttempt.user_id == user.id,
                ScheduleCompletionAttempt.begin_idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if attempt:
            eligibility = db.get(ScheduleRewardEligibility, attempt.eligibility_id)
            if eligibility is None or eligibility.schedule_item_id != payload.schedule_item_id:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho mục lịch khác."
                )
            if attempt.status == "undone":
                raise ApiError(
                    409, "ELIGIBILITY_NOT_AVAILABLE", "Lượt hoàn thành đã được hoàn tác."
                )
            return _attempt_result(attempt, eligibility, replay=True)
        eligibility = db.scalar(
            select(ScheduleRewardEligibility)
            .where(
                ScheduleRewardEligibility.user_id == user.id,
                ScheduleRewardEligibility.schedule_item_id == payload.schedule_item_id,
            )
            .with_for_update()
        )
        if eligibility is None:
            raise ApiError(404, "ELIGIBILITY_NOT_FOUND", "Mục lịch chưa được đăng ký nhận thưởng.")
        _assert_window(eligibility, now)
        attempt = ScheduleCompletionAttempt(
            eligibility_id=eligibility.id,
            user_id=user.id,
            begin_idempotency_key=payload.idempotency_key,
            object_path=f"{user.id}/{eligibility.id}/{uuid4()}.jpg",
            status="begun",
        )
        db.add(attempt)
        db.flush()
        return _attempt_result(attempt, eligibility, replay=False)


def upload_proof(
    db: Session,
    request: Request,
    user: User,
    attempt_id: UUID,
    upload: UploadFile,
) -> dict[str, Any]:
    if upload.content_type != "image/jpeg":
        raise ApiError(422, "PROOF_CONTENT_TYPE_INVALID", "Ảnh minh chứng phải ở định dạng JPEG.")
    content = upload.file.read(MAX_PROOF_BYTES + 1)
    if not content or len(content) > MAX_PROOF_BYTES:
        raise ApiError(413, "PROOF_SIZE_INVALID", "Ảnh minh chứng vượt quá 5 MB.")
    if not content.startswith(b"\xff\xd8\xff"):
        raise ApiError(422, "PROOF_CONTENT_TYPE_INVALID", "Nội dung ảnh không hợp lệ.")
    attempt = db.scalar(
        select(ScheduleCompletionAttempt)
        .where(
            ScheduleCompletionAttempt.id == attempt_id, ScheduleCompletionAttempt.user_id == user.id
        )
        .with_for_update()
    )
    if attempt is None:
        raise ApiError(404, "COMPLETION_ATTEMPT_NOT_FOUND", "Không tìm thấy lượt hoàn thành.")
    eligibility = db.get(ScheduleRewardEligibility, attempt.eligibility_id)
    if eligibility is None:
        raise ApiError(404, "ELIGIBILITY_NOT_FOUND", "Không tìm thấy mục lịch đủ điều kiện.")
    _assert_window(eligibility, now_utc())
    proof = db.scalar(
        select(ScheduleCompletionProof).where(ScheduleCompletionProof.attempt_id == attempt.id)
    )
    if proof:
        return {
            "file_id": str(proof.file_id),
            "storage_path": proof.object_path,
            "idempotent_replay": True,
        }

    object_path = attempt.object_path
    storage_name = attempt.id.hex
    owner_dir: Path = request.app.state.settings.upload_root / str(user.id)
    owner_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    destination = owner_dir / storage_name
    temporary = owner_dir / f".{storage_name}.tmp"
    try:
        temporary.write_bytes(content)
        temporary.replace(destination)
        with atomic(db):
            file_obj = FileObject(
                owner_id=user.id,
                bucket=PROOF_BUCKET,
                storage_name=storage_name,
                media_type="image/jpeg",
                size_bytes=len(content),
            )
            db.add(file_obj)
            db.flush()
            db.add(
                ScheduleCompletionProof(
                    eligibility_id=eligibility.id,
                    attempt_id=attempt.id,
                    file_id=file_obj.id,
                    user_id=user.id,
                    bucket_id=PROOF_BUCKET,
                    object_path=object_path,
                    content_type="image/jpeg",
                    byte_size=len(content),
                    captured_at=now_utc(),
                    status="active",
                )
            )
            attempt.status = "proof_uploaded"
            attempt.updated_at = now_utc()
        return {
            "file_id": str(file_obj.id),
            "storage_path": object_path,
            "idempotent_replay": False,
        }
    except Exception:
        temporary.unlink(missing_ok=True)
        destination.unlink(missing_ok=True)
        raise


def download_proof(db: Session, request: Request, user: User, attempt_id: UUID) -> FileResponse:
    proof = db.scalar(
        select(ScheduleCompletionProof).where(
            ScheduleCompletionProof.user_id == user.id,
            ScheduleCompletionProof.attempt_id == attempt_id,
            ScheduleCompletionProof.status == "active",
        )
    )
    if proof is None:
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    file_obj = db.get(FileObject, proof.file_id)
    if file_obj is None or file_obj.owner_id != user.id or file_obj.bucket != PROOF_BUCKET:
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    root = request.app.state.settings.upload_root.resolve()
    path = (root / str(user.id) / file_obj.storage_name).resolve()
    if root not in path.parents or not path.is_file():
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    return FileResponse(path, media_type="image/jpeg", filename=f"{attempt_id}.jpg")


def download_proof_admin(db: Session, request: Request, attempt_id: UUID) -> FileResponse:
    proof = db.scalar(
        select(ScheduleCompletionProof).where(
            ScheduleCompletionProof.attempt_id == attempt_id,
            ScheduleCompletionProof.status == "active",
        )
    )
    if proof is None:
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    file_obj = db.get(FileObject, proof.file_id)
    if file_obj is None or file_obj.bucket != PROOF_BUCKET:
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    root = request.app.state.settings.upload_root.resolve()
    path = (root / str(file_obj.owner_id) / file_obj.storage_name).resolve()
    if root not in path.parents or not path.is_file():
        raise ApiError(404, "PROOF_NOT_FOUND", "Không tìm thấy ảnh minh chứng.")
    return FileResponse(path, media_type="image/jpeg", filename=f"{attempt_id}.jpg")


def finalize_completion(
    db: Session,
    user: User,
    attempt_id: UUID,
    payload: FinalizeCompletionRequest,
) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        attempt = db.scalar(
            select(ScheduleCompletionAttempt)
            .where(
                ScheduleCompletionAttempt.id == attempt_id,
                ScheduleCompletionAttempt.user_id == user.id,
            )
            .with_for_update()
        )
        if attempt is None:
            raise ApiError(404, "COMPLETION_ATTEMPT_NOT_FOUND", "Không tìm thấy lượt hoàn thành.")
        if attempt.finalize_idempotency_key:
            if attempt.finalize_idempotency_key != payload.idempotency_key:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "Lượt hoàn thành đã được xử lý.")
            return {
                "reward_status": "pending",
                "points_delta": _program(db)["reward_points"],
                "idempotent_replay": True,
            }
        eligibility = db.scalar(
            select(ScheduleRewardEligibility)
            .where(ScheduleRewardEligibility.id == attempt.eligibility_id)
            .with_for_update()
        )
        if eligibility is None:
            raise ApiError(404, "ELIGIBILITY_NOT_FOUND", "Không tìm thấy mục lịch đủ điều kiện.")
        _assert_window(eligibility, now)
        proof = db.scalar(
            select(ScheduleCompletionProof)
            .where(
                ScheduleCompletionProof.attempt_id == attempt.id,
                ScheduleCompletionProof.user_id == user.id,
                ScheduleCompletionProof.status == "active",
            )
            .with_for_update()
        )
        if (
            proof is None
            or proof.object_path != payload.storage_path
            or proof.object_path != attempt.object_path
        ):
            raise ApiError(422, "PROOF_NOT_UPLOADED", "Ảnh minh chứng chưa được tải lên.")
        if eligibility.status != "eligible":
            raise ApiError(409, "ALREADY_COMPLETED", "Mục lịch đã được xác nhận hoàn thành.")
        program = _program(db)
        points = program["reward_points"]
        available_at = eligibility.window_end
        expires_at = available_at + timedelta(days=program["expiry_days"])
        status = "pending" if now < available_at else "available"
        wallet = _get_or_create_wallet(db, user.id, lock=True)
        ledger = WellnessPointLedger(
            user_id=user.id,
            subject_id=eligibility.subject_id,
            source_type="schedule_completion",
            source_id=attempt.id,
            schedule_date=eligibility.schedule_date,
            points_delta=points,
            program_code=program["contract_version"],
            idempotency_key=f"schedule_completion:{attempt.id}",
            event_type="schedule_award",
            status=status,
            title=f"Hoàn thành nhiệm vụ: {eligibility.title_snapshot}",
            is_redeemable=True,
            available_at=available_at,
            expires_at=expires_at,
            eligibility_id=eligibility.id,
            metadata_json={"evidence_kind": "photo_proof"},
        )
        db.add(ledger)
        db.flush()
        db.add(
            WellnessPointAllocation(
                user_id=user.id,
                subject_id=eligibility.subject_id,
                ledger_id=ledger.id,
                eligibility_id=eligibility.id,
                source_type="schedule_reward",
                source_id=attempt.id,
                original_points=points,
                remaining_points=points,
                status=status,
                available_at=available_at,
                expires_at=expires_at,
                program_config_id=program["id"],
            )
        )
        if status == "pending":
            wallet.pending_points += points
        else:
            wallet.available_points += points
        wallet.lifetime_earned_points += points
        wallet.lock_version += 1
        wallet.updated_at = now
        eligibility.status = "completed"
        eligibility.updated_at = now
        attempt.status = "finalized"
        attempt.finalize_idempotency_key = payload.idempotency_key
        attempt.finalized_at = now
        attempt.updated_at = now
        _set_snapshot_schedule_completed(
            db, user.id, eligibility.schedule_item_id, completed=True, proof_path=proof.object_path
        )
        return {"reward_status": status, "points_delta": points, "idempotent_replay": False}


def undo_completion(db: Session, user: User, payload: UndoCompletionRequest) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        replay = db.scalar(
            select(ScheduleCompletionAttempt)
            .where(
                ScheduleCompletionAttempt.user_id == user.id,
                ScheduleCompletionAttempt.undo_idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if replay:
            eligibility = db.get(ScheduleRewardEligibility, replay.eligibility_id)
            if eligibility is None or eligibility.schedule_item_id != payload.schedule_item_id:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho mục lịch khác."
                )
            allocation = db.scalar(
                select(WellnessPointAllocation).where(
                    WellnessPointAllocation.source_type == "schedule_reward",
                    WellnessPointAllocation.source_id == replay.id,
                )
            )
            return {
                "reward_status": "reversed",
                "points_delta": -allocation.original_points if allocation else 0,
                "idempotent_replay": True,
            }
        attempt = db.scalar(
            select(ScheduleCompletionAttempt)
            .join(
                ScheduleRewardEligibility,
                ScheduleRewardEligibility.id == ScheduleCompletionAttempt.eligibility_id,
            )
            .where(
                ScheduleCompletionAttempt.user_id == user.id,
                ScheduleRewardEligibility.schedule_item_id == payload.schedule_item_id,
                ScheduleCompletionAttempt.status == "finalized",
            )
            .with_for_update()
        )
        if attempt is None:
            raise ApiError(404, "COMPLETION_ATTEMPT_NOT_FOUND", "Không tìm thấy lượt hoàn thành.")
        eligibility = db.get(ScheduleRewardEligibility, attempt.eligibility_id)
        if eligibility is None:
            raise ApiError(404, "ELIGIBILITY_NOT_FOUND", "Không tìm thấy mục lịch.")
        if attempt.undo_idempotency_key:
            if attempt.undo_idempotency_key != payload.idempotency_key:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho yêu cầu khác.")
            return {
                "reward_status": "reversed",
                "points_delta": -_program(db)["reward_points"],
                "idempotent_replay": True,
            }
        if now > eligibility.window_end:
            raise ApiError(409, "UNDO_WINDOW_LOCKED", "Đã hết thời gian hoàn tác.")
        allocation = db.scalar(
            select(WellnessPointAllocation)
            .where(
                WellnessPointAllocation.source_type == "schedule_reward",
                WellnessPointAllocation.source_id == attempt.id,
            )
            .with_for_update()
        )
        if (
            allocation is None
            or allocation.status != "pending"
            or allocation.remaining_points != allocation.original_points
        ):
            raise ApiError(
                409, "REWARD_CANNOT_BE_UNDONE", "Điểm đã được sử dụng hoặc không còn chờ xác nhận."
            )
        wallet = _get_or_create_wallet(db, user.id, lock=True)
        db.add(
            WellnessPointLedger(
                user_id=user.id,
                subject_id=eligibility.subject_id,
                source_type="schedule_completion",
                source_id=attempt.id,
                schedule_date=eligibility.schedule_date,
                points_delta=-allocation.original_points,
                program_code="wellness_rewards_v2",
                idempotency_key=f"schedule_completion_undo:{attempt.id}",
                event_type="schedule_reversal",
                status="reversed",
                title=f"Hoàn tác nhiệm vụ: {eligibility.title_snapshot}",
                is_redeemable=False,
                available_at=allocation.available_at,
                expires_at=allocation.expires_at,
                eligibility_id=eligibility.id,
                metadata_json={"evidence_kind": "photo_proof"},
            )
        )
        allocation.remaining_points = 0
        allocation.status = "reversed"
        allocation.updated_at = now
        wallet.pending_points = max(0, wallet.pending_points - allocation.original_points)
        wallet.lifetime_earned_points = max(
            0, wallet.lifetime_earned_points - allocation.original_points
        )
        wallet.lock_version += 1
        wallet.updated_at = now
        eligibility.status = "undone"
        eligibility.updated_at = now
        attempt.status = "undone"
        attempt.undo_idempotency_key = payload.idempotency_key
        attempt.updated_at = now
        proof = db.scalar(
            select(ScheduleCompletionProof).where(ScheduleCompletionProof.attempt_id == attempt.id)
        )
        if proof:
            proof.status = "reversed"
            proof.reversed_at = now
            proof.undo_idempotency_key = payload.idempotency_key
            proof.updated_at = now
        _set_snapshot_schedule_completed(db, user.id, eligibility.schedule_item_id, completed=False)
        return {
            "reward_status": "reversed",
            "points_delta": -allocation.original_points,
            "idempotent_replay": False,
        }


def finalize_health_checkin(
    db: Session, user: User, payload: HealthCheckinRequest
) -> dict[str, Any]:
    now = now_utc()
    item = payload.item
    try:
        item_id = UUID(str(item.get("schedule_item_id", "")))
        schedule_date = _date(item.get("schedule_date"))
        start_time = _time(item.get("start_time"))
    except (ValueError, TypeError) as exc:
        raise ApiError(422, "SCHEDULE_ITEM_ID_INVALID", "Mục lịch chưa hợp lệ.") from exc
    action = payload.action_type.strip()
    points = {
        "hydration": 4,
        "mood_stress": 5,
        "sleep_checkin": 6,
        "weight_checkin": 4,
        "quick_complete": 5,
    }.get(action, 0)
    if not points:
        raise ApiError(422, "HEALTH_ACTION_NOT_REWARDABLE", "Thao tác chưa đủ điều kiện nhận điểm.")
    source_type = str(item.get("source_type", ""))
    source_id = str(item.get("source_id") or "") or None
    category = str(item.get("category", ""))
    start_at = datetime.combine(schedule_date, start_time, LOCAL_TZ).astimezone(UTC)
    window_end = start_at + timedelta(minutes=30)
    if now < start_at:
        raise ApiError(409, "SCHEDULE_WINDOW_NOT_OPEN", "Nhiệm vụ chưa đến giờ thực hiện.")
    if now > window_end:
        raise ApiError(409, "SCHEDULE_WINDOW_LOCKED", "Đã hết cửa sổ nhận thưởng.")
    _validate_checkin(action, payload.checkin)
    if source_type == "manual_health_task":
        match = MANUAL_SOURCE.fullmatch(source_id or "")
        if match is None or match.group(1) != action:
            raise ApiError(422, "MANUAL_HEALTH_TASK_INVALID", "Nhiệm vụ tự tạo chưa hợp lệ.")
        if category not in {"routine", "water", "body", "mind", "brain", "sleep", "metric"}:
            raise ApiError(422, "MANUAL_HEALTH_TASK_INVALID", "Nhiệm vụ tự tạo chưa hợp lệ.")
    else:
        if source_type in {"meal_plan", "exercise_task"}:
            raise ApiError(422, "PHOTO_PROOF_REQUIRED", "Nhiệm vụ này yêu cầu ảnh minh chứng.")
        if (
            (action == "hydration" and category != "water")
            or (action not in {"hydration", "quick_complete"})
            or (
                action == "quick_complete"
                and category not in {"routine", "mind", "brain", "body", "sleep"}
            )
        ):
            raise ApiError(422, "HEALTH_ACTION_MISMATCH", "Thao tác không khớp với nhiệm vụ.")
    with atomic(db):
        existing = db.scalar(
            select(ScheduleHealthCheckin)
            .where(
                ScheduleHealthCheckin.user_id == user.id,
                ScheduleHealthCheckin.idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if existing:
            if existing.schedule_item_id != item_id or existing.action_type != action:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho mục lịch khác."
                )
            return _checkin_result(existing, replay=True)
        if db.scalar(
            select(ScheduleHealthCheckin.id).where(
                ScheduleHealthCheckin.user_id == user.id,
                ScheduleHealthCheckin.schedule_item_id == item_id,
                ScheduleHealthCheckin.status == "active",
            )
        ):
            raise ApiError(409, "HEALTH_CHECKIN_ALREADY_RECORDED", "Nhiệm vụ đã được ghi nhận.")
        eligibility = (
            db.scalar(
                select(ScheduleRewardEligibility)
                .where(
                    ScheduleRewardEligibility.user_id == user.id,
                    ScheduleRewardEligibility.schedule_item_id == item_id,
                )
                .with_for_update()
            )
            if source_type != "manual_health_task"
            else None
        )
        if source_type != "manual_health_task" and eligibility is None:
            raise ApiError(404, "ELIGIBILITY_NOT_FOUND", "Mục lịch chưa được đăng ký nhận thưởng.")
        if eligibility and eligibility.status != "eligible":
            raise ApiError(409, "ELIGIBILITY_NOT_AVAILABLE", "Mục lịch không còn đủ điều kiện.")
        if source_type == "manual_health_task":
            count = (
                db.scalar(
                    select(func.count())
                    .select_from(ScheduleHealthCheckin)
                    .where(
                        ScheduleHealthCheckin.user_id == user.id,
                        ScheduleHealthCheckin.source_type_snapshot == "manual_health_task",
                        ScheduleHealthCheckin.schedule_date == schedule_date,
                        ScheduleHealthCheckin.status == "active",
                    )
                )
                or 0
            )
            if count >= 4:
                raise ApiError(
                    409, "MANUAL_REWARD_DAILY_LIMIT", "Đã đạt giới hạn nhiệm vụ tự tạo trong ngày."
                )
        subject = _self_subject(db, user.id)
        checkin = ScheduleHealthCheckin(
            eligibility_id=eligibility.id if eligibility else None,
            user_id=user.id,
            subject_id=subject.id,
            schedule_item_id=item_id,
            action_type=action,
            checkin_payload=payload.checkin,
            reward_points=points,
            schedule_date=schedule_date,
            start_time=start_time,
            window_end=window_end,
            title_snapshot=str(item.get("title", "Nhiệm vụ chăm sóc"))[:240],
            category_snapshot=category[:80],
            source_type_snapshot=source_type[:80],
            source_id_snapshot=source_id[:240] if source_id else None,
            idempotency_key=payload.idempotency_key,
            status="active",
        )
        db.add(checkin)
        db.flush()
        program = _program(db)
        available_at = window_end
        expires_at = available_at + timedelta(days=program["expiry_days"])
        reward_status = "pending" if now < available_at else "available"
        ledger = WellnessPointLedger(
            user_id=user.id,
            subject_id=subject.id,
            source_type="schedule_health_checkin",
            source_id=checkin.id,
            schedule_date=schedule_date,
            points_delta=points,
            program_code=program["contract_version"],
            idempotency_key=f"schedule_health_checkin:{checkin.id}",
            event_type="schedule_award",
            status=reward_status,
            title=f"Hoàn thành nhiệm vụ: {checkin.title_snapshot}",
            is_redeemable=True,
            available_at=available_at,
            expires_at=expires_at,
            eligibility_id=eligibility.id if eligibility else None,
            metadata_json={
                "evidence_kind": "health_checkin",
                "action_type": action,
                "manual_task": eligibility is None,
            },
        )
        db.add(ledger)
        db.flush()
        db.add(
            WellnessPointAllocation(
                user_id=user.id,
                subject_id=subject.id,
                ledger_id=ledger.id,
                eligibility_id=eligibility.id if eligibility else None,
                source_type="schedule_reward",
                source_id=checkin.id,
                original_points=points,
                remaining_points=points,
                status=reward_status,
                available_at=available_at,
                expires_at=expires_at,
                program_config_id=program["id"],
            )
        )
        wallet = _get_or_create_wallet(db, user.id, lock=True)
        if reward_status == "pending":
            wallet.pending_points += points
        else:
            wallet.available_points += points
        wallet.lifetime_earned_points += points
        wallet.lock_version += 1
        wallet.updated_at = now
        if eligibility:
            eligibility.status = "completed"
            eligibility.updated_at = now
        _set_snapshot_schedule_completed(db, user.id, item_id, completed=True, item_data=item)
        return _checkin_result(checkin, replay=False)


def undo_health_checkin(
    db: Session, user: User, payload: UndoHealthCheckinRequest
) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        replay = db.scalar(
            select(ScheduleHealthCheckin)
            .where(
                ScheduleHealthCheckin.user_id == user.id,
                ScheduleHealthCheckin.undo_idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if replay:
            if replay.schedule_item_id != payload.schedule_item_id:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho mục lịch khác."
                )
            return _checkin_result(replay, replay=True, points_delta=-replay.reward_points)
        checkin = db.scalar(
            select(ScheduleHealthCheckin)
            .where(
                ScheduleHealthCheckin.user_id == user.id,
                ScheduleHealthCheckin.schedule_item_id == payload.schedule_item_id,
                ScheduleHealthCheckin.status == "active",
            )
            .with_for_update()
        )
        if checkin is None:
            raise ApiError(404, "HEALTH_CHECKIN_NOT_FOUND", "Không tìm thấy dữ liệu cần hoàn tác.")
        if checkin.undo_idempotency_key:
            if checkin.undo_idempotency_key != payload.idempotency_key:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã dùng cho yêu cầu khác.")
            return _checkin_result(checkin, replay=True, points_delta=-checkin.reward_points)
        if now > checkin.window_end:
            raise ApiError(409, "UNDO_WINDOW_LOCKED", "Đã hết thời gian hoàn tác.")
        allocation = db.scalar(
            select(WellnessPointAllocation)
            .where(
                WellnessPointAllocation.source_type == "schedule_reward",
                WellnessPointAllocation.source_id == checkin.id,
            )
            .with_for_update()
        )
        if (
            allocation is None
            or allocation.status != "pending"
            or allocation.remaining_points != allocation.original_points
        ):
            raise ApiError(
                409, "REWARD_CANNOT_BE_UNDONE", "Điểm đã được sử dụng hoặc không còn chờ xác nhận."
            )
        wallet = _get_or_create_wallet(db, user.id, lock=True)
        db.add(
            WellnessPointLedger(
                user_id=user.id,
                subject_id=checkin.subject_id,
                source_type="schedule_health_checkin",
                source_id=checkin.id,
                schedule_date=checkin.schedule_date,
                points_delta=-allocation.original_points,
                program_code="wellness_rewards_v2",
                idempotency_key=f"schedule_health_checkin_undo:{checkin.id}",
                event_type="schedule_reversal",
                status="reversed",
                title=f"Hoàn tác nhiệm vụ: {checkin.title_snapshot}",
                is_redeemable=False,
                available_at=allocation.available_at,
                expires_at=allocation.expires_at,
                eligibility_id=checkin.eligibility_id,
                metadata_json={"evidence_kind": "health_checkin"},
            )
        )
        allocation.remaining_points = 0
        allocation.status = "reversed"
        allocation.updated_at = now
        wallet.pending_points = max(0, wallet.pending_points - allocation.original_points)
        wallet.lifetime_earned_points = max(
            0, wallet.lifetime_earned_points - allocation.original_points
        )
        wallet.lock_version += 1
        wallet.updated_at = now
        checkin.status = "reversed"
        checkin.reversed_at = now
        checkin.undo_idempotency_key = payload.idempotency_key
        checkin.updated_at = now
        if checkin.eligibility_id:
            eligibility = db.get(ScheduleRewardEligibility, checkin.eligibility_id)
            if eligibility:
                eligibility.status = "undone"
                eligibility.updated_at = now
        _set_snapshot_schedule_completed(db, user.id, checkin.schedule_item_id, completed=False)
        return _checkin_result(checkin, replay=False, points_delta=-allocation.original_points)


def _checkin_result(
    row: ScheduleHealthCheckin, *, replay: bool, points_delta: int | None = None
) -> dict[str, Any]:
    delta = (
        points_delta
        if points_delta is not None
        else row.reward_points
        if row.status == "active"
        else 0
    )
    return {
        "checkin_id": str(row.id),
        "schedule_item_id": str(row.schedule_item_id),
        "points_delta": delta,
        "reward_status": "reversed" if row.status == "reversed" else "pending",
        "idempotent_replay": replay,
    }


def _registration_result(
    request_id: str,
    items: list[ScheduleRewardEligibility],
    *,
    replay: bool,
) -> dict[str, Any]:
    return {
        "request_id": request_id,
        "registered_count": len(items),
        "existing_count": len(items) if replay else 0,
        "eligibilities": [
            {
                "eligibility_id": str(row.id),
                "schedule_item_id": str(row.schedule_item_id),
                "schedule_date": row.schedule_date.isoformat(),
                "window_start": _iso(row.window_start),
                "window_end": _iso(row.window_end),
                "status": row.status,
            }
            for row in items
        ],
        "idempotent_replay": replay,
    }


def _attempt_result(
    attempt: ScheduleCompletionAttempt,
    eligibility: ScheduleRewardEligibility,
    *,
    replay: bool,
) -> dict[str, Any]:
    return {
        "attempt_id": str(attempt.id),
        "eligibility_id": str(eligibility.id),
        "bucket_id": PROOF_BUCKET,
        "storage_path": attempt.object_path,
        "object_path": attempt.object_path,
        "content_type": "image/jpeg",
        "max_bytes": MAX_PROOF_BYTES,
        "window_end": _iso(eligibility.window_end),
        "upload_deadline": _iso(eligibility.window_end),
        "status": attempt.status,
        "idempotent_replay": replay,
    }


def _snapshot_tables(snapshot: CloudSnapshot | None) -> dict[str, list[dict[str, Any]]]:
    if snapshot is None or not isinstance(snapshot.payload, dict):
        return {}
    tables = snapshot.payload.get("tables")
    if not isinstance(tables, dict):
        return {}
    return {str(key): value for key, value in tables.items() if isinstance(value, list)}


def _set_snapshot_schedule_completed(
    db: Session,
    user_id: UUID,
    item_id: UUID,
    *,
    completed: bool,
    proof_path: str | None = None,
    item_data: dict[str, Any] | None = None,
) -> None:
    snapshot = db.scalar(
        select(CloudSnapshot).where(
            CloudSnapshot.user_id == user_id, CloudSnapshot.snapshot_type == "mobile-v1"
        )
    )
    if snapshot is None or not isinstance(snapshot.payload, dict):
        return
    payload = dict(snapshot.payload)
    tables = dict(payload.get("tables") or {})
    schedule_rows = [
        dict(row) for row in tables.get("lifestyle_schedule_items", []) if isinstance(row, dict)
    ]
    found = False
    for row in schedule_rows:
        if str(row.get("id")) == str(item_id):
            row["is_completed"] = completed
            if proof_path:
                row["completion_proof_path"] = proof_path
                row["completed_at"] = now_utc().isoformat()
            found = True
            break
    if not found and item_data is not None:
        schedule_rows.append(
            {
                "id": str(item_id),
                "schedule_date": item_data.get("schedule_date"),
                "start_time": item_data.get("start_time"),
                "end_time": item_data.get("end_time"),
                "title": str(item_data.get("title", "Nhiệm vụ chăm sóc"))[:120],
                "description": str(item_data.get("description", ""))[:500],
                "category": item_data.get("category"),
                "source_type": item_data.get("source_type"),
                "source_id": item_data.get("source_id"),
                "target_value": item_data.get("target_value", 1),
                "current_value": item_data.get("target_value", 1) if completed else 0,
                "unit": item_data.get("unit", "lần"),
                "is_completed": completed,
                "sort_order": 900,
                "ai_generated": False,
                "encouragement": "",
            }
        )
        found = True
    if found:
        tables["lifestyle_schedule_items"] = schedule_rows
        payload["tables"] = tables
        snapshot.payload = payload
        snapshot.revision += 1
        snapshot.updated_at = now_utc()


def _self_subject(db: Session, user_id: UUID) -> HealthSubject:
    subject = db.scalar(
        select(HealthSubject).where(
            HealthSubject.owner_user_id == user_id,
            HealthSubject.subject_type == "self",
            HealthSubject.is_active.is_(True),
        )
    )
    if subject is None:
        raise ApiError(
            409, "HEALTH_SUBJECT_REQUIRED", "Chưa tìm thấy hồ sơ sức khỏe của tài khoản."
        )
    return subject


def _assert_window(eligibility: ScheduleRewardEligibility, now: datetime) -> None:
    if eligibility.status == "completed":
        raise ApiError(409, "SCHEDULE_ALREADY_COMPLETED", "Nhiệm vụ đã được xác nhận hoàn thành.")
    if eligibility.status != "eligible":
        raise ApiError(409, "ELIGIBILITY_NOT_AVAILABLE", "Nhiệm vụ không còn đủ điều kiện.")
    if now < eligibility.window_start:
        raise ApiError(409, "SCHEDULE_WINDOW_NOT_OPEN", "Nhiệm vụ chưa đến giờ thực hiện.")
    if now > eligibility.window_end:
        raise ApiError(409, "SCHEDULE_WINDOW_LOCKED", "Đã hết cửa sổ nhận thưởng.")


def _program(db: Session) -> dict[str, Any]:
    rollout = db.scalar(
        select(SystemConfigVersion)
        .where(
            SystemConfigVersion.config_key == "wellness_rewards_rollout",
            SystemConfigVersion.status == "active",
        )
        .order_by(SystemConfigVersion.created_at.desc())
        .limit(1)
    )
    if not rollout or rollout.config_value.get("enabled") not in {True, "1", "true"}:
        raise ApiError(
            503, "WELLNESS_REWARDS_DISABLED", "Chương trình điểm chăm sóc hiện chưa hoạt động."
        )
    row = db.scalar(
        select(SystemConfigVersion)
        .where(
            SystemConfigVersion.config_key == "wellness_reward_program",
            SystemConfigVersion.status == "active",
        )
        .order_by(SystemConfigVersion.created_at.desc())
        .limit(1)
    )
    if row is None:
        raise ApiError(
            503, "REWARD_PROGRAM_NOT_CONFIGURED", "Chương trình điểm chưa được cấu hình."
        )
    try:
        points = int(str(row.config_value.get("reward_points")))
        expiry_days = int(str(row.config_value.get("expiry_days")))
        version = str(row.config_value.get("contract_version", "wellness_rewards_v2"))
    except (TypeError, ValueError) as exc:
        raise ApiError(
            503, "REWARD_PROGRAM_INVALID", "Cấu hình chương trình điểm chưa hợp lệ."
        ) from exc
    if not 1 <= points <= 10 or not 1 <= expiry_days <= 3650:
        raise ApiError(503, "REWARD_PROGRAM_INVALID", "Cấu hình chương trình điểm chưa hợp lệ.")
    return {
        "id": row.id,
        "reward_points": points,
        "expiry_days": expiry_days,
        "contract_version": version,
    }


def _validate_checkin(action: str, checkin: dict[str, Any]) -> None:
    bounds: dict[str, tuple[str, float, float]] = {
        "hydration": ("amount_ml", 50, 2000),
        "sleep_checkin": ("sleep_hours", 0, 24),
        "weight_checkin": ("weight_kg", 20, 500),
    }
    if action in bounds:
        key, minimum, maximum = bounds[action]
        value = checkin.get(key)
        if (
            isinstance(value, bool)
            or not isinstance(value, (int, float))
            or not minimum <= value <= maximum
        ):
            raise ApiError(
                422, "HEALTH_CHECKIN_INVALID", "Thông tin theo dõi sức khỏe chưa hợp lệ."
            )
    elif action == "mood_stress":
        if checkin.get("mood") not in {"very_good", "good", "neutral", "tired", "stressed"}:
            raise ApiError(422, "HEALTH_CHECKIN_INVALID", "Thông tin tâm trạng chưa hợp lệ.")
        stress = checkin.get("stress_level")
        if isinstance(stress, bool) or not isinstance(stress, (int, float)) or not 1 <= stress <= 5:
            raise ApiError(422, "HEALTH_CHECKIN_INVALID", "Mức căng thẳng chưa hợp lệ.")


def _date(value: object) -> date:
    return date.fromisoformat(str(value)[:10])


def _time(value: object) -> time:
    return time.fromisoformat(str(value))


def _schedule_start(row: dict[str, Any]) -> datetime:
    return datetime.combine(
        _date(row.get("schedule_date")), _time(row.get("start_time")), LOCAL_TZ
    ).astimezone(UTC)


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value else None
