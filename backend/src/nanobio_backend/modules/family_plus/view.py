from uuid import UUID

from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import FamilyGroup, FamilyMember, User, now_utc
from nanobio_backend.modules.family_plus import query


def _require_plan(db: Session, user: User) -> None:
    if query.current_subscription(db, user.id) is None:
        raise ApiError(
            403, "FAMILYPLUS_REQUIRED", "Tính năng này cần gói FamilyPlus đang hoạt động."
        )


def _context(db: Session, user: User) -> dict[str, object]:
    subscription = query.current_subscription(db, user.id)
    group = query.active_group(db, user.id)
    self_subject = query.self_subject(db, user.id)
    members = query.list_group_members(db, group.id) if group else []
    return {
        "actor_id": str(user.id),
        "self_subject_id": str(self_subject.id) if self_subject else None,
        "has_family_plus": subscription is not None,
        "group": (
            {
                "id": str(group.id),
                "owner_user_id": str(group.owner_user_id),
                "display_name": group.display_name,
                "status": group.status,
            }
            if group
            else None
        ),
        "members": [_member_view(member) for member in members],
        "selected_subject_id": str(self_subject.id) if self_subject else None,
    }


def _member_view(member: FamilyMember) -> dict[str, object]:
    return {
        "id": str(member.id),
        "family_group_id": str(member.family_group_id),
        "subject_id": str(member.subject_id),
        "user_id": str(member.user_id) if member.user_id else None,
        "display_name": member.display_name,
        "role": member.role,
        "status": member.status,
        "can_view": member.can_view,
        "can_edit": member.can_edit,
    }


def get_context(db: Session, user: User) -> dict[str, object]:
    _require_plan(db, user)
    return _context(db, user)


def upsert_group(
    db: Session, user: User, *, display_name: str, idempotency_key: str
) -> dict[str, object]:
    name = display_name.strip()
    key = idempotency_key.strip()
    if not name or not key:
        raise ApiError(422, "INVALID_FAMILYPLUS_GROUP", "Tên nhóm và mã thao tác là bắt buộc.")
    with atomic(db):
        _require_plan(db, user)
        if query.lock_user(db, user.id) is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        subscription = query.current_subscription(db, user.id)
        group = query.active_group(db, user.id, lock=True)
        if group is None:
            group = FamilyGroup(
                owner_user_id=user.id,
                plan_subscription_id=subscription.id if subscription else None,
                display_name=name,
                status="active",
                last_idempotency_key=key,
            )
            db.add(group)
        else:
            group.display_name = name
            group.plan_subscription_id = (
                subscription.id if subscription else group.plan_subscription_id
            )
            group.last_idempotency_key = key
            group.updated_at = now_utc()
        db.flush()
        return _context(db, user)


def upsert_member(
    db: Session,
    user: User,
    *,
    subject_id: UUID,
    display_name: str,
    role: str,
    can_view: bool,
    can_edit: bool,
    idempotency_key: str,
) -> dict[str, object]:
    name = display_name.strip()
    key = idempotency_key.strip()
    role_value = role.strip().casefold()
    if not name or not key:
        raise ApiError(
            422, "INVALID_FAMILYPLUS_MEMBER", "Tên thành viên và mã thao tác là bắt buộc."
        )
    if role_value not in {"adult", "member", "child", "viewer"}:
        raise ApiError(422, "INVALID_FAMILYPLUS_ROLE", "Vai trò FamilyPlus chưa hợp lệ.")
    with atomic(db):
        _require_plan(db, user)
        if query.lock_user(db, user.id) is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        subject = query.owned_active_subject(db, user.id, subject_id)
        if subject is None:
            raise ApiError(
                403, "FAMILYPLUS_SUBJECT_NOT_ALLOWED", "Hồ sơ sức khỏe này không thuộc tài khoản."
            )
        group = query.active_group(db, user.id, lock=True)
        if group is None:
            raise ApiError(409, "FAMILYPLUS_GROUP_REQUIRED", "Hãy tạo nhóm FamilyPlus trước.")
        member = query.member_by_subject(db, group.id, subject_id)
        if member is None and query.active_member_count(db, group.id) >= 5:
            raise ApiError(
                409, "FAMILYPLUS_MEMBER_LIMIT", "Nhóm FamilyPlus đã đạt giới hạn thành viên."
            )
        if member is None:
            member = FamilyMember(
                family_group_id=group.id,
                subject_id=subject.id,
                user_id=subject.linked_user_id,
                display_name=name,
                role=role_value,
                status="active",
                can_view=can_view,
                can_edit=can_edit,
                joined_at=now_utc(),
                last_idempotency_key=key,
            )
            db.add(member)
        else:
            member.user_id = subject.linked_user_id
            member.display_name = name
            member.role = role_value
            member.status = "active"
            member.can_view = can_view
            member.can_edit = can_edit
            member.joined_at = member.joined_at or now_utc()
            member.last_idempotency_key = key
            member.updated_at = now_utc()
        db.flush()
        return _context(db, user)


def remove_member(
    db: Session, user: User, *, member_id: UUID, idempotency_key: str
) -> dict[str, object]:
    key = idempotency_key.strip()
    if not key:
        raise ApiError(422, "INVALID_FAMILYPLUS_REMOVE", "Thiếu mã thao tác.")
    with atomic(db):
        _require_plan(db, user)
        if query.lock_user(db, user.id) is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        member = query.member_for_owner_update(db, user.id, member_id)
        if member is None:
            raise ApiError(404, "FAMILYPLUS_MEMBER_NOT_FOUND", "Không tìm thấy thành viên.")
        member.status = "removed"
        member.last_idempotency_key = key
        member.updated_at = now_utc()
        return _context(db, user)
