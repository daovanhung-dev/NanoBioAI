import hashlib
import json
from datetime import date, datetime, time
from decimal import Decimal
from typing import Any
from urllib.parse import urlsplit, urlunsplit
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from nanobio_backend.db.business_models import (
    CommissionRecord,
    PaymentEvent,
    SalePayoutProfile,
    SalePointAdjustment,
    SalePointConversion,
    SaleProfile,
    ScheduleCompletionAttempt,
    ScheduleCompletionProof,
    ScheduleHealthCheckin,
    ScheduleRewardEligibility,
    ScheduleRewardRegistration,
    WellnessPointAllocation,
    WellnessPointLedger,
    WellnessRankAccount,
    WellnessRankExperienceLedger,
    WellnessRedemptionAllocationUsage,
    WellnessRewardRedemption,
    WellnessRewardWallet,
)
from nanobio_backend.db.models import (
    AdminAuditEvent,
    AdminUserRole,
    AiContentReport,
    CloudSnapshot,
    DomainRecord,
    EarlyAccessLead,
    FamilyGroup,
    FamilyMember,
    FileObject,
    GooglePlayPurchase,
    HealthSubject,
    IdempotencyRecord,
    ManualPaymentEvent,
    MembershipSubscription,
    PaymentRequest,
    ReferralCode,
    ReferralRelationship,
    RefreshSession,
    SleepSafetyContact,
    SleepSafetyDispatch,
    SleepSafetyEvent,
    SleepSafetyPreference,
    SleepSafetySession,
    SleepSafetyVerificationChallenge,
    UsageEvent,
    UsageQuotaCounter,
    User,
)


def payload_hash(payload: dict[str, Any]) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


def find_idempotency(
    db: Session, *, actor_id: UUID, operation: str, key: str
) -> IdempotencyRecord | None:
    return db.scalar(
        select(IdempotencyRecord).where(
            IdempotencyRecord.actor_id == actor_id,
            IdempotencyRecord.operation == operation,
            IdempotencyRecord.idempotency_key == key,
        )
    )


def add_idempotency(
    db: Session, *, actor_id: UUID, operation: str, key: str, digest: str, result: dict[str, Any]
) -> None:
    db.add(
        IdempotencyRecord(
            actor_id=actor_id,
            operation=operation,
            idempotency_key=key,
            request_hash=digest,
            response_data=result,
        )
    )


def add_audit(
    db: Session,
    *,
    actor_id: UUID,
    action: str,
    target_user_id: UUID | None,
    reason: str,
    idempotency_key: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    db.add(
        AdminAuditEvent(
            actor_id=actor_id,
            action=action,
            target_user_id=target_user_id,
            reason=reason,
            idempotency_key=idempotency_key,
            metadata_json=metadata or {},
        )
    )


def current_membership(db: Session, user_id: UUID, now: datetime) -> MembershipSubscription | None:
    return db.scalar(
        select(MembershipSubscription)
        .where(
            MembershipSubscription.user_id == user_id,
            MembershipSubscription.status.in_(["trialing", "active", "past_due"]),
            MembershipSubscription.starts_at <= now,
            (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
        )
        .order_by(MembershipSubscription.created_at.desc())
        .with_for_update()
    )


def get_user_for_update(db: Session, user_id: UUID) -> User | None:
    return db.scalar(select(User).where(User.id == user_id).with_for_update())


def search_users(db: Session, term: str, limit: int) -> list[User]:
    statement = select(User)
    if term:
        pattern = f"%{term}%"
        statement = statement.where(
            or_(
                User.full_name.ilike(pattern),
                User.phone.ilike(pattern),
                User.email.ilike(pattern),
            )
        )
    return list(db.scalars(statement.order_by(User.created_at.desc()).limit(limit)).all())


USER_DATA_CLOUD_TABLES: dict[str, tuple[str, ...]] = {
    "profile": (),
    "health": (
        "health_profiles",
        "lifestyle_habits",
        "nutrition_profiles",
        "health_goals",
        "health_conditions",
        "food_allergies",
        "medical_treatments",
        "survey_answers",
        "health_tracking_logs",
        "health_score_ledgers",
        "nutrition_logs",
        "ai_insights",
        "ai_recommendations",
        "health_symptoms",
        "medication_records",
        "food_restrictions",
        "lab_results",
        "nutrition_goals",
        "nutrition_preference_rules",
    ),
    "schedule": (
        "meal_plans",
        "daily_health_tasks",
        "lifestyle_schedule_items",
        "notifications",
        "meal_schedule_preferences",
        "fitness_training_programs",
        "personal_schedule_ai_requests",
    ),
    "membership": (),
    "family": (),
    "sleep_safety": (),
    "sale_rewards": (),
    "activity": (),
    "related": (),
}

USER_DATA_MODELS: dict[str, tuple[tuple[type[Any], tuple[str, ...]], ...]] = {
    "profile": ((AdminUserRole, ("user_id",)),),
    "health": ((HealthSubject, ("owner_user_id", "linked_user_id")),),
    "schedule": (
        (ScheduleRewardEligibility, ("user_id",)),
        (ScheduleRewardRegistration, ("user_id", "guest_user_id")),
        (ScheduleCompletionAttempt, ("user_id",)),
        (ScheduleCompletionProof, ("user_id",)),
        (ScheduleHealthCheckin, ("user_id",)),
        (WellnessPointLedger, ("user_id",)),
        (WellnessPointAllocation, ("user_id",)),
        (WellnessRankAccount, ("user_id",)),
        (WellnessRankExperienceLedger, ("user_id",)),
    ),
    "membership": (
        (MembershipSubscription, ("user_id",)),
        (UsageQuotaCounter, ("user_id",)),
        (UsageEvent, ("user_id",)),
        (PaymentRequest, ("user_id",)),
        (ManualPaymentEvent, ("user_id",)),
        (PaymentEvent, ("payer_user_id",)),
        (GooglePlayPurchase, ("user_id",)),
    ),
    "family": (
        (FamilyGroup, ("owner_user_id",)),
        (FamilyMember, ("user_id",)),
    ),
    "sleep_safety": (
        (SleepSafetyContact, ("user_id",)),
        (SleepSafetyPreference, ("user_id",)),
        (SleepSafetySession, ("user_id",)),
        (SleepSafetyEvent, ("user_id",)),
        (SleepSafetyDispatch, ("user_id",)),
        (SleepSafetyVerificationChallenge, ("user_id",)),
    ),
    "sale_rewards": (
        (SaleProfile, ("user_id",)),
        (SalePayoutProfile, ("sale_user_id",)),
        (CommissionRecord, ("receiver_user_id", "payer_user_id")),
        (SalePointAdjustment, ("sale_user_id",)),
        (SalePointConversion, ("sale_user_id",)),
        (WellnessRewardWallet, ("user_id",)),
        (WellnessPointLedger, ("user_id",)),
        (WellnessPointAllocation, ("user_id",)),
        (WellnessRewardRedemption, ("user_id",)),
        (WellnessRedemptionAllocationUsage, ("redemption_id", "allocation_id")),
        (WellnessRankAccount, ("user_id",)),
        (WellnessRankExperienceLedger, ("user_id",)),
        (ReferralCode, ("user_id",)),
        (ReferralRelationship, ("referrer_id", "referred_id")),
    ),
    "activity": (
        (RefreshSession, ("user_id",)),
        (AdminAuditEvent, ("target_user_id",)),
    ),
    "related": (
        (DomainRecord, ("user_id",)),
        (AiContentReport, ("user_id",)),
        (FileObject, ("owner_id",)),
    ),
}

_PRIVATE_FIELD_NAMES = {
    "objectpath",
    "storagename",
    "providerexternalid",
    "providersubscriptionid",
}
_PRIVATE_FIELD_MARKERS = (
    "password",
    "token",
    "secret",
    "credential",
    "authorization",
    "signature",
    "hmac",
    "privatekey",
    "apikey",
    "accesskey",
    "codehash",
    "fingerprinthash",
)


def _safe_user_data(value: Any, field_name: str | None = None) -> Any:
    if isinstance(value, dict):
        return {
            str(key): _safe_user_data(child, str(key))
            for key, child in value.items()
            if not _private_user_data_field(str(key))
        }
    if isinstance(value, (list, tuple)):
        return [clean for item in value if (clean := _safe_user_data(item)) is not None]
    if isinstance(value, str) and field_name and field_name.casefold().endswith("url"):
        return sanitize_user_url(value)
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    if isinstance(value, (UUID, Decimal)):
        return str(value)
    return value


def sanitize_user_url(value: str | None) -> str | None:
    if value is None:
        return None
    parts = urlsplit(value)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, "", ""))


def _private_user_data_field(field_name: str) -> bool:
    field = "".join(character for character in field_name.casefold() if character.isalnum())
    return field in _PRIVATE_FIELD_NAMES or any(
        marker in field for marker in _PRIVATE_FIELD_MARKERS
    )


def _serialize_user_data_model(instance: Any) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for attribute in instance.__mapper__.column_attrs:
        if _private_user_data_field(attribute.key):
            continue
        value = getattr(instance, attribute.key)
        result[attribute.key] = _safe_user_data(value, attribute.key)
    return result


def _user_data_filters(model: type[Any], user_id: UUID, owners: tuple[str, ...]) -> Any:
    if model is FamilyGroup:
        memberships = select(FamilyMember.family_group_id).where(FamilyMember.user_id == user_id)
        return or_(FamilyGroup.owner_user_id == user_id, FamilyGroup.id.in_(memberships))
    if model is FamilyMember:
        owned_groups = select(FamilyGroup.id).where(FamilyGroup.owner_user_id == user_id)
        return or_(FamilyMember.user_id == user_id, FamilyMember.family_group_id.in_(owned_groups))
    if model is WellnessRedemptionAllocationUsage:
        redemptions = select(WellnessRewardRedemption.id).where(
            WellnessRewardRedemption.user_id == user_id
        )
        allocations = select(WellnessPointAllocation.id).where(
            WellnessPointAllocation.user_id == user_id
        )
        return or_(
            WellnessRedemptionAllocationUsage.redemption_id.in_(redemptions),
            WellnessRedemptionAllocationUsage.allocation_id.in_(allocations),
        )
    return or_(*(getattr(model, owner) == user_id for owner in owners))


def user_data_by_section(
    db: Session, *, user_id: UUID, section: str, page: int, page_size: int
) -> dict[str, Any]:
    tables: dict[str, dict[str, Any]] = {}
    snapshot = db.scalar(
        select(CloudSnapshot).where(
            CloudSnapshot.user_id == user_id,
            CloudSnapshot.snapshot_type == "mobile-v1",
        )
    )
    if section == "profile" and snapshot is not None:
        profile = snapshot.payload.get("user", {})
        rows = [profile] if isinstance(profile, dict) and profile else []
        start = (page - 1) * page_size
        total = len(rows)
        tables["mobile_profile"] = {
            "rows": [_safe_user_data(row) for row in rows[start : start + page_size]],
            "total": total,
            "page": page,
            "page_size": page_size,
            "pages": (total + page_size - 1) // page_size,
        }
    if snapshot is not None:
        cloud_tables = snapshot.payload.get("tables", {})
        if isinstance(cloud_tables, dict):
            for table_name in USER_DATA_CLOUD_TABLES.get(section, ()):
                source_rows = cloud_tables.get(table_name, [])
                if not isinstance(source_rows, list):
                    continue
                start = (page - 1) * page_size
                total = len(source_rows)
                tables[table_name] = {
                    "rows": [
                        _safe_user_data(row) for row in source_rows[start : start + page_size]
                    ],
                    "total": total,
                    "page": page,
                    "page_size": page_size,
                    "pages": (total + page_size - 1) // page_size,
                }
    for model, owners in USER_DATA_MODELS.get(section, ()):
        condition = _user_data_filters(model, user_id, owners)
        total = int(db.scalar(select(func.count()).select_from(model).where(condition)) or 0)
        if "created_at" in model.__table__.columns:
            ordering = model.__table__.columns["created_at"].desc()
        else:
            ordering = next(iter(model.__mapper__.primary_key)).asc()
        records: list[Any] = list(
            db.scalars(
                select(model)
                .where(condition)
                .order_by(ordering)
                .offset((page - 1) * page_size)
                .limit(page_size)
            ).all()
        )
        table_name = str(model.__tablename__)
        tables[table_name] = {
            "rows": [_serialize_user_data_model(row) for row in records],
            "total": total,
            "page": page,
            "page_size": page_size,
            "pages": (total + page_size - 1) // page_size,
        }
    return {"section": section, "page": page, "page_size": page_size, "tables": tables}


def search_current_memberships(
    db: Session, user_ids: list[UUID], now: datetime
) -> list[MembershipSubscription]:
    if not user_ids:
        return []
    return list(
        db.scalars(
            select(MembershipSubscription)
            .where(
                MembershipSubscription.user_id.in_(user_ids),
                MembershipSubscription.plan_code.in_(["plus", "family_plus"]),
                MembershipSubscription.status.in_(["trialing", "active"]),
                MembershipSubscription.starts_at <= now,
                (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
            )
            .order_by(
                MembershipSubscription.user_id,
                MembershipSubscription.plan_code.desc(),
                MembershipSubscription.starts_at.desc(),
            )
        ).all()
    )


def search_early_access_leads(
    db: Session, *, term: str, offset: int, limit: int
) -> tuple[int, list[EarlyAccessLead]]:
    pattern = f"%{term.strip()}%"
    where = or_(EarlyAccessLead.full_name.ilike(pattern), EarlyAccessLead.phone.ilike(pattern))
    total = int(db.scalar(select(func.count()).select_from(EarlyAccessLead).where(where)) or 0)
    rows = list(
        db.scalars(
            select(EarlyAccessLead)
            .where(where)
            .order_by(EarlyAccessLead.created_at.desc())
            .offset(offset)
            .limit(limit)
        ).all()
    )
    return total, rows


def payment_review_count(db: Session) -> int:
    return int(
        db.scalar(
            select(func.count())
            .select_from(ManualPaymentEvent)
            .where(ManualPaymentEvent.status == "pending_review")
        )
        or 0
    )
