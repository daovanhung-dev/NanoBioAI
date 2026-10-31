from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from nanobio_backend.db.base import Base


def now_utc() -> datetime:
    return datetime.now(UTC)


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    phone: Mapped[str | None] = mapped_column(String(16), unique=True, index=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(512))
    full_name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str | None] = mapped_column(String(320), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    gender: Mapped[str | None] = mapped_column(String(24), nullable=True)
    birth_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    onboarding_status: Mapped[str] = mapped_column(String(32), default="pending")
    onboarding_completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    app_access_mode: Mapped[str] = mapped_column(String(16), default="user")
    admin_status: Mapped[str] = mapped_column(String(24), default="active")
    force_password_change: Mapped[bool] = mapped_column(Boolean, default=False)
    membership_tier: Mapped[str] = mapped_column(String(32), default="free")
    sale_status: Mapped[str] = mapped_column(String(24), default="none")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )
    roles: Mapped[list[AdminUserRole]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    @property
    def is_admin(self) -> bool:
        return bool(self.roles)

    @property
    def admin_roles(self) -> set[str]:
        return {role.role_code for role in self.roles}


class AdminUserRole(Base):
    __tablename__ = "admin_user_roles"
    __table_args__ = (UniqueConstraint("user_id", "role_code", name="uq_admin_user_role"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    role_code: Mapped[str] = mapped_column(String(40))
    user: Mapped[User] = relationship(back_populates="roles")


class RefreshSession(Base):
    __tablename__ = "refresh_sessions"
    __table_args__ = (Index("ix_refresh_user_active", "user_id", "revoked_at"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    family_id: Mapped[UUID] = mapped_column(index=True, default=uuid4)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    replaced_by_id: Mapped[UUID | None] = mapped_column(nullable=True)


class RateLimitBucket(Base):
    __tablename__ = "rate_limit_buckets"
    __table_args__ = (
        UniqueConstraint("scope", "subject_hash", "window_start", name="uq_rate_limit_bucket"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    scope: Mapped[str] = mapped_column(String(80))
    subject_hash: Mapped[str] = mapped_column(String(64))
    window_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    hits: Mapped[int] = mapped_column(Integer, default=0)


class IdempotencyRecord(Base):
    __tablename__ = "idempotency_records"
    __table_args__ = (
        UniqueConstraint(
            "actor_id", "operation", "idempotency_key", name="uq_idempotency_operation"
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    actor_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    operation: Mapped[str] = mapped_column(String(120))
    idempotency_key: Mapped[str] = mapped_column(String(160))
    request_hash: Mapped[str] = mapped_column(String(64))
    response_data: Mapped[dict[str, Any] | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class MembershipSubscription(Base):
    __tablename__ = "membership_subscriptions"
    __table_args__ = (Index("ix_membership_user_status", "user_id", "status"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    plan_code: Mapped[str] = mapped_column(String(80))
    status: Mapped[str] = mapped_column(String(24), default="active")
    source: Mapped[str] = mapped_column(String(32), default="manual")
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    current_period_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    current_period_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    provider: Mapped[str | None] = mapped_column(String(40), nullable=True)
    provider_subscription_id: Mapped[str | None] = mapped_column(String(256), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class UsageQuotaRule(Base):
    __tablename__ = "usage_quota_rules"
    __table_args__ = (
        CheckConstraint(
            "period_unit in ('day', 'month', 'lifetime', 'none')",
            name="ck_usage_quota_period_unit",
        ),
        UniqueConstraint("plan_code", "feature_key", "period_unit", name="uq_usage_quota_rule"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    plan_code: Mapped[str] = mapped_column(String(32))
    feature_key: Mapped[str] = mapped_column(String(80))
    period_unit: Mapped[str] = mapped_column(String(16))
    max_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reset_timezone: Mapped[str] = mapped_column(String(64), default="Asia/Ho_Chi_Minh")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class UsageQuotaCounter(Base):
    __tablename__ = "usage_quota_counters"
    __table_args__ = (
        UniqueConstraint("user_id", "feature_key", "period_key", name="uq_usage_quota_counter"),
        CheckConstraint("used_count >= 0", name="ck_usage_quota_used_nonnegative"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    feature_key: Mapped[str] = mapped_column(String(80))
    period_key: Mapped[str] = mapped_column(String(32))
    plan_code: Mapped[str] = mapped_column(String(32))
    used_count: Mapped[int] = mapped_column(Integer, default=0)
    limit_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reset_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class UsageEvent(Base):
    __tablename__ = "usage_events"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "feature_key", "idempotency_key", name="uq_usage_event_request"
        ),
        CheckConstraint(
            "event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')",
            name="ck_usage_event_source",
        ),
        Index("ix_usage_events_user_feature_created", "user_id", "feature_key", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    feature_key: Mapped[str] = mapped_column(String(80))
    period_key: Mapped[str] = mapped_column(String(32))
    count_delta: Mapped[int] = mapped_column(Integer, default=1)
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    event_source: Mapped[str] = mapped_column(String(24), default="trusted_backend")
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class HealthSubject(Base):
    __tablename__ = "health_subjects"
    __table_args__ = (
        CheckConstraint("subject_type in ('self', 'family_member')", name="ck_health_subject_type"),
        CheckConstraint(
            "subject_type <> 'self' or owner_user_id = coalesce(linked_user_id, owner_user_id)",
            name="ck_health_subject_self_owner",
        ),
        Index(
            "uq_health_subject_self_owner",
            "owner_user_id",
            unique=True,
            postgresql_where=text("subject_type = 'self'"),
            sqlite_where=text("subject_type = 'self'"),
        ),
        Index("ix_health_subject_owner_active", "owner_user_id", "is_active"),
        Index("ix_health_subject_linked_user", "linked_user_id"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    owner_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    linked_user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    family_group_id: Mapped[UUID | None] = mapped_column(nullable=True)
    subject_type: Mapped[str] = mapped_column(String(24), default="self")
    display_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    relationship: Mapped[str | None] = mapped_column(String(60), nullable=True)
    gender: Mapped[str | None] = mapped_column(String(24), nullable=True)
    birth_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class FamilyGroup(Base):
    __tablename__ = "family_groups"
    __table_args__ = (
        CheckConstraint("status in ('active', 'paused', 'closed')", name="ck_family_group_status"),
        Index(
            "uq_family_group_active_owner",
            "owner_user_id",
            unique=True,
            postgresql_where=text("status = 'active'"),
            sqlite_where=text("status = 'active'"),
        ),
        Index("ix_family_group_owner_status", "owner_user_id", "status"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    owner_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    plan_subscription_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("membership_subscriptions.id", ondelete="SET NULL"), nullable=True
    )
    display_name: Mapped[str] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(24), default="active")
    last_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class FamilyMember(Base):
    __tablename__ = "family_members"
    __table_args__ = (
        CheckConstraint(
            "role in ('owner', 'adult', 'member', 'child', 'viewer')",
            name="ck_family_member_role",
        ),
        CheckConstraint(
            "status in ('invited', 'active', 'removed')", name="ck_family_member_status"
        ),
        UniqueConstraint("family_group_id", "subject_id", name="uq_family_member_subject"),
        Index(
            "uq_family_member_group_user",
            "family_group_id",
            "user_id",
            unique=True,
            postgresql_where=text("user_id is not null and status <> 'removed'"),
            sqlite_where=text("user_id is not null and status <> 'removed'"),
        ),
        Index("ix_family_member_subject", "subject_id"),
        Index("ix_family_member_user_status", "user_id", "status"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    family_group_id: Mapped[UUID] = mapped_column(
        ForeignKey("family_groups.id", ondelete="CASCADE")
    )
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("health_subjects.id", ondelete="CASCADE"))
    user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    invited_email: Mapped[str | None] = mapped_column(String(320), nullable=True)
    display_name: Mapped[str] = mapped_column(String(120))
    role: Mapped[str] = mapped_column(String(24), default="member")
    status: Mapped[str] = mapped_column(String(24), default="active")
    can_view: Mapped[bool] = mapped_column(Boolean, default=True)
    can_edit: Mapped[bool] = mapped_column(Boolean, default=False)
    last_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    joined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class AdminAuditEvent(Base):
    __tablename__ = "admin_audit_events"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    actor_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    action: Mapped[str] = mapped_column(String(100), index=True)
    target_user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, index=True
    )


class CloudSnapshot(Base):
    __tablename__ = "cloud_snapshots"
    __table_args__ = (UniqueConstraint("user_id", "snapshot_type", name="uq_cloud_snapshot_type"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    snapshot_type: Mapped[str] = mapped_column(String(60))
    payload: Mapped[dict[str, Any]] = mapped_column(JSON)
    revision: Mapped[int] = mapped_column(Integer, default=1)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class EarlyAccessLead(Base):
    __tablename__ = "early_access_leads"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    phone: Mapped[str] = mapped_column(String(16), unique=True)
    phone_hash: Mapped[str] = mapped_column(String(64), unique=True)
    full_name: Mapped[str] = mapped_column(String(120))
    age: Mapped[int] = mapped_column(Integer)
    gender: Mapped[str] = mapped_column(String(24))
    address: Mapped[str] = mapped_column(String(500))
    consent: Mapped[bool] = mapped_column(Boolean)
    status: Mapped[str] = mapped_column(String(24), default="new", index=True)
    promotion_code: Mapped[str] = mapped_column(String(64), default="EARLY_ACCESS_PLUS_30D")
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AiContentReport(Base):
    __tablename__ = "ai_content_reports"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    message_id: Mapped[str] = mapped_column(String(160))
    message_role: Mapped[str] = mapped_column(String(32))
    reason_code: Mapped[str] = mapped_column(String(32))
    message_snapshot: Mapped[str] = mapped_column(String(4000))
    app_version: Mapped[str] = mapped_column(String(64))
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)
    installation_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    status: Mapped[str] = mapped_column(String(24), default="open", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetyContact(Base):
    __tablename__ = "sleep_safety_contacts"
    __table_args__ = (UniqueConstraint("user_id", "phone", name="uq_sleep_contact_phone"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(16))
    relation: Mapped[str | None] = mapped_column(String(80), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    priority: Mapped[int] = mapped_column(Integer, default=1)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    verification_status: Mapped[str] = mapped_column(String(24), default="pending")
    allow_phone_fallback: Mapped[bool] = mapped_column(Boolean, default=True)
    allow_unverified_voice_alert: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetyVerificationChallenge(Base):
    __tablename__ = "sleep_safety_contact_verification_challenges"
    __table_args__ = (
        Index("ix_sleep_challenge_lookup", "user_id", "contact_id", "status", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    contact_id: Mapped[UUID] = mapped_column(
        ForeignKey("sleep_safety_contacts.id", ondelete="CASCADE"), index=True
    )
    code_hash: Mapped[str] = mapped_column(String(64))
    attempt_count: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(24), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetyPreference(Base):
    __tablename__ = "sleep_safety_preferences"
    __table_args__ = (
        CheckConstraint("sensitivity in ('low', 'balanced', 'high')"),
        CheckConstraint("schedule_start_minutes between 0 and 1439"),
        CheckConstraint("schedule_end_minutes between 0 and 1439"),
        CheckConstraint("cooldown_seconds between 30 and 900"),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    sensitivity: Mapped[str] = mapped_column(String(16), default="balanced")
    schedule_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    schedule_start_minutes: Mapped[int] = mapped_column(Integer, default=1350)
    schedule_end_minutes: Mapped[int] = mapped_column(Integer, default=390)
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Ho_Chi_Minh")
    selected_weekdays: Mapped[list[int]] = mapped_column(
        JSON, default=lambda: [1, 2, 3, 4, 5, 6, 7]
    )
    calibration_required: Mapped[bool] = mapped_column(Boolean, default=True)
    calibration_noise_floor: Mapped[float | None] = mapped_column(Float, nullable=True)
    calibration_updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    cooldown_seconds: Mapped[int] = mapped_column(Integer, default=120)
    consent_version: Mapped[str] = mapped_column(String(80), default="sleep-safety-v1")
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetySession(Base):
    __tablename__ = "sleep_safety_sessions"
    __table_args__ = (
        UniqueConstraint("id", "user_id", name="uq_sleep_session_id_user"),
        Index("ix_sleep_safety_sessions_user_started", "user_id", "started_at"),
    )

    id: Mapped[str] = mapped_column(String(160), primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    scheduled_window_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    scheduled_window_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    sensitivity: Mapped[str] = mapped_column(String(16))
    calibration_noise_floor: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(32))
    start_source: Mapped[str] = mapped_column(String(32))
    stop_reason: Mapped[str | None] = mapped_column(String(80), nullable=True)
    platform: Mapped[str] = mapped_column(String(40))
    app_version: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetyEvent(Base):
    __tablename__ = "sleep_safety_events"
    __table_args__ = (
        ForeignKeyConstraint(
            ["session_id", "user_id"],
            ["sleep_safety_sessions.id", "sleep_safety_sessions.user_id"],
            ondelete="CASCADE",
            name="fk_sleep_event_session_owner",
        ),
    )

    id: Mapped[str] = mapped_column(String(160), primary_key=True)
    session_id: Mapped[str | None] = mapped_column(String(160), nullable=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    detected_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    event_type: Mapped[str] = mapped_column(String(48), default="unknownHighEnergyEvent")
    severity: Mapped[str] = mapped_column(String(16), default="attention")
    confidence: Mapped[float] = mapped_column(Float, default=0)
    relative_energy: Mapped[float] = mapped_column(Float, default=0)
    baseline_delta: Mapped[float] = mapped_column(Float, default=0)
    repetition_count: Mapped[int] = mapped_column(Integer, default=1)
    state: Mapped[str] = mapped_column(String(40), default="detected")
    response: Mapped[str] = mapped_column(String(32), default="none")
    response_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    escalation_required: Mapped[bool] = mapped_column(Boolean, default=False)
    escalation_status: Mapped[str] = mapped_column(String(24), default="notRequired")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SleepSafetyDispatch(Base):
    __tablename__ = "sleep_safety_dispatches"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "idempotency_key", "contact_id", "channel", name="uq_sleep_dispatch_attempt"
        ),
        Index("ix_sleep_dispatch_provider_id", "provider_external_id"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    event_id: Mapped[str] = mapped_column(
        ForeignKey("sleep_safety_events.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    contact_id: Mapped[UUID] = mapped_column(
        ForeignKey("sleep_safety_contacts.id", ondelete="CASCADE"), index=True
    )
    priority: Mapped[int] = mapped_column(Integer)
    channel: Mapped[str] = mapped_column(String(16))
    provider: Mapped[str] = mapped_column(String(40), default="generic_http")
    provider_external_id: Mapped[str | None] = mapped_column(String(160), nullable=True)
    status: Mapped[str] = mapped_column(String(24))
    idempotency_key: Mapped[str] = mapped_column(String(160))
    failure_code: Mapped[str | None] = mapped_column(String(80), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class PaymentRequest(Base):
    __tablename__ = "payment_requests"
    __table_args__ = (Index("ix_payment_user_status", "user_id", "status"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    plan_code: Mapped[str] = mapped_column(String(80))
    amount_minor: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(24), default="pending", index=True)
    reference_code: Mapped[str] = mapped_column(String(64), unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class ManualPaymentEvent(Base):
    __tablename__ = "manual_payment_events"
    __table_args__ = (
        UniqueConstraint("user_id", "idempotency_key", name="uq_manual_payment_user_idempotency"),
        Index("ix_manual_payment_user_status", "user_id", "status"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    plan_code: Mapped[str] = mapped_column(String(32))
    billing_cycle: Mapped[str] = mapped_column(String(16))
    payer_full_name: Mapped[str] = mapped_column(String(120))
    amount_cents: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(24), default="awaiting_transfer", index=True)
    transfer_reference: Mapped[str] = mapped_column(String(32), unique=True)
    idempotency_key: Mapped[str] = mapped_column(String(160))
    bank_snapshot: Mapped[dict[str, str]] = mapped_column(JSON)
    transfer_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    review_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    reviewed_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    subscription_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("membership_subscriptions.id", ondelete="SET NULL"), nullable=True
    )
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class GooglePlayPurchase(Base):
    __tablename__ = "google_play_purchases"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    purchase_token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    package_name: Mapped[str] = mapped_column(String(160))
    product_id: Mapped[str] = mapped_column(String(160))
    order_id: Mapped[str | None] = mapped_column(String(256), nullable=True)
    purchase_state: Mapped[str] = mapped_column(String(24))
    purchase_started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    entitlement_ends_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class ReferralCode(Base):
    __tablename__ = "referral_codes"

    code: Mapped[str] = mapped_column(String(32), primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class ReferralRelationship(Base):
    __tablename__ = "referral_relationships"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    referrer_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    referred_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    device_fingerprint_hash: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(24), default="active")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class DomainRecord(Base):
    """Typed ownership-scoped payloads used by source-backed mobile sync contracts."""

    __tablename__ = "domain_records"
    __table_args__ = (
        UniqueConstraint("user_id", "record_type", "record_key", name="uq_domain_record_key"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    record_type: Mapped[str] = mapped_column(String(80))
    record_key: Mapped[str] = mapped_column(String(160))
    payload: Mapped[dict[str, Any]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class FileObject(Base):
    __tablename__ = "file_objects"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    owner_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    bucket: Mapped[str] = mapped_column(String(80), index=True)
    storage_name: Mapped[str] = mapped_column(String(100), unique=True)
    media_type: Mapped[str] = mapped_column(String(120))
    size_bytes: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


# Register the business-domain tables before Alembic reads Base.metadata.
from nanobio_backend.db import business_models as _business_models  # noqa: E402, F401
